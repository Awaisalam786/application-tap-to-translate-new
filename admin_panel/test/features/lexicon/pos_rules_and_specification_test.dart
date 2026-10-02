import 'package:flutter_test/flutter_test.dart';
import 'package:german_lexicon_admin/features/auth/domain/admin_user_model.dart';
import 'package:german_lexicon_admin/features/csv_export/domain/models/csv_export_entry.dart';
import 'package:german_lexicon_admin/features/csv_export/domain/services/csv_serializer.dart';
import 'package:german_lexicon_admin/features/csv_import/domain/services/csv_parser.dart';
import 'package:german_lexicon_admin/features/csv_import/domain/services/csv_validator.dart';
import 'package:german_lexicon_admin/features/lexicon/domain/models/lexicon_example.dart';
import 'package:german_lexicon_admin/features/lexicon/domain/models/lexicon_filter.dart';
import 'package:german_lexicon_admin/features/lexicon/domain/models/lexicon_sense.dart';
import 'package:german_lexicon_admin/features/lexicon/domain/models/lexicon_synonym.dart';
import 'package:german_lexicon_admin/features/lexicon/domain/models/lexicon_translation.dart';
import 'package:german_lexicon_admin/features/lexicon/domain/models/master_lexicon_entry.dart';
import 'package:german_lexicon_admin/features/lexicon/domain/services/pos_rules_validator.dart';

void main() {
  group('Phase 12C-1: Master Lexicon Specification Foundation Tests', () {
    // -------------------------------------------------------------
    // 1. Noun Validation
    // -------------------------------------------------------------
    test('1. Noun validation rejects leading articles in lemma and accepts clean lemma', () {
      // Disallow "der Tisch"
      final invalidNoun = PosRulesValidator.validateNoun(
        lemma: 'der Tisch',
        article: 'der',
      );
      expect(invalidNoun.isValid, isFalse);
      expect(invalidNoun.errors.any((e) => e.contains('must not include leading article')), isTrue);
      expect(invalidNoun.suggestedLemma, equals('Tisch'));
      expect(invalidNoun.suggestedArticle, equals('der'));

      // Also disallow "die Lampe", "das Haus", "ein Buch"
      expect(PosRulesValidator.validateNoun(lemma: 'die Lampe').isValid, isFalse);
      expect(PosRulesValidator.validateNoun(lemma: 'das Haus').isValid, isFalse);
      expect(PosRulesValidator.validateNoun(lemma: 'ein Buch').isValid, isFalse);

      // Clean lemma is accepted
      final validNoun = PosRulesValidator.validateNoun(
        lemma: 'Tisch',
        article: 'der',
        pluralForm: 'Tische',
      );
      expect(validNoun.isValid, isTrue);
      expect(validNoun.errors, isEmpty);
    });

    // -------------------------------------------------------------
    // 2. Article Validation
    // -------------------------------------------------------------
    test('2. Article validation only permits der, die, das', () {
      expect(PosRulesValidator.validateNoun(lemma: 'Tisch', article: 'der').isValid, isTrue);
      expect(PosRulesValidator.validateNoun(lemma: 'Lampe', article: 'die').isValid, isTrue);
      expect(PosRulesValidator.validateNoun(lemma: 'Buch', article: 'das').isValid, isTrue);

      // Invalid article like "den", "dem", "des", "foo"
      final invalidRes = PosRulesValidator.validateNoun(lemma: 'Tisch', article: 'den');
      expect(invalidRes.isValid, isFalse);
      expect(invalidRes.errors.first, contains('Invalid noun article'));

      final randomArticle = PosRulesValidator.validateNoun(lemma: 'Tisch', article: 'abc');
      expect(randomArticle.isValid, isFalse);
    });

    // -------------------------------------------------------------
    // 3. Plural Handling
    // -------------------------------------------------------------
    test('3. Plural form handling warns against storing articles in plural', () {
      final resWithArticleInPlural = PosRulesValidator.validateNoun(
        lemma: 'Tisch',
        article: 'der',
        pluralForm: 'die Tische',
      );
      expect(resWithArticleInPlural.isValid, isTrue);
      expect(resWithArticleInPlural.warnings.any((w) => w.contains('Plural form should not include leading article')), isTrue);

      final cleanPlural = PosRulesValidator.validateNoun(
        lemma: 'Tisch',
        article: 'der',
        pluralForm: 'Tische',
      );
      expect(cleanPlural.isValid, isTrue);
      expect(cleanPlural.warnings, isEmpty);
    });

    // -------------------------------------------------------------
    // 4. Verb Infinitive Rules
    // -------------------------------------------------------------
    test('4. Verb validation requires canonical infinitive and rejects conjugated forms', () {
      // Valid infinitives
      expect(PosRulesValidator.validateVerb(lemma: 'gehen').isValid, isTrue);
      expect(PosRulesValidator.validateVerb(lemma: 'sammeln').isValid, isTrue);
      expect(PosRulesValidator.validateVerb(lemma: 'wandern').isValid, isTrue);
      expect(PosRulesValidator.validateVerb(lemma: 'sein').isValid, isTrue);
      expect(PosRulesValidator.validateVerb(lemma: 'tun').isValid, isTrue);

      // Reflexive verbs
      final reflexive = PosRulesValidator.validateVerb(lemma: 'sich erinnern');
      expect(reflexive.isValid, isTrue);
      expect(PosRulesValidator.validateVerb(lemma: 'sich freuen').isValid, isTrue);

      // Reject conjugated forms: geht, ging, gingen, gegangen
      final gaat = PosRulesValidator.validateVerb(lemma: 'geht');
      expect(gaat.isValid, isFalse);
      expect(gaat.errors.first, contains('conjugated form'));

      final ging = PosRulesValidator.validateVerb(lemma: 'ging');
      expect(ging.isValid, isFalse);
      expect(ging.errors.first, contains('conjugated form'));

      final gegangen = PosRulesValidator.validateVerb(lemma: 'gegangen');
      expect(gegangen.isValid, isFalse);

      final macht = PosRulesValidator.validateVerb(lemma: 'macht');
      expect(macht.isValid, isFalse);

      // Verb with article mistakenly added
      expect(PosRulesValidator.validateVerb(lemma: 'das gehen').isValid, isFalse);
    });

    // -------------------------------------------------------------
    // 5. Adjective Base Form Rules
    // -------------------------------------------------------------
    test('5. Adjective validation requires canonical base form and rejects comparatives/superlatives', () {
      // Base positive form
      expect(PosRulesValidator.validateAdjective(lemma: 'schnell').isValid, isTrue);
      expect(PosRulesValidator.validateAdjective(lemma: 'groß').isValid, isTrue);
      expect(PosRulesValidator.validateAdjective(lemma: 'gut').isValid, isTrue);

      // Legitimate base adjectives ending in 'er'
      expect(PosRulesValidator.validateAdjective(lemma: 'teuer').isValid, isTrue);
      expect(PosRulesValidator.validateAdjective(lemma: 'sauer').isValid, isTrue);
      expect(PosRulesValidator.validateAdjective(lemma: 'sauber').isValid, isTrue);

      // Reject comparative
      final comparative = PosRulesValidator.validateAdjective(lemma: 'schneller');
      expect(comparative.isValid, isFalse);
      expect(comparative.errors.first, contains('comparative or superlative form'));

      expect(PosRulesValidator.validateAdjective(lemma: 'besser').isValid, isFalse);
      expect(PosRulesValidator.validateAdjective(lemma: 'größer').isValid, isFalse);

      // Reject superlative with "am ...sten"
      final superlative = PosRulesValidator.validateAdjective(lemma: 'am schnellsten');
      expect(superlative.isValid, isFalse);
      expect(superlative.errors.first, contains('superlative'));

      expect(PosRulesValidator.validateAdjective(lemma: 'am besten').isValid, isFalse);
    });

    // -------------------------------------------------------------
    // 6. CEFR Validation
    // -------------------------------------------------------------
    test('6. CEFR validation strictly enforces A1, A2, B1, B2, C1, C2, unclassified', () {
      expect(PosRulesValidator.validateCefr('A1').isValid, isTrue);
      expect(PosRulesValidator.validateCefr('A2').isValid, isTrue);
      expect(PosRulesValidator.validateCefr('B1').isValid, isTrue);
      expect(PosRulesValidator.validateCefr('B2').isValid, isTrue);
      expect(PosRulesValidator.validateCefr('unclassified').isValid, isTrue);

      expect(PosRulesValidator.validateCefr('X1').isValid, isFalse);
      expect(PosRulesValidator.validateCefr('A0').isValid, isFalse);
    });

    // -------------------------------------------------------------
    // 7. Translation Language Isolation
    // -------------------------------------------------------------
    test('7. Translation records support EN, UR, FA, AR independently and missing one does not invalidate others', () {
      final enOnly = LexiconTranslation(
        id: 't_1',
        entryId: 'e_1',
        targetLang: 'en',
        translation: 'table',
        status: 'verified',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final urOnly = LexiconTranslation(
        id: 't_2',
        entryId: 'e_1',
        targetLang: 'ur',
        translation: 'میز',
        status: 'draft',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Each language has its own independent status and text
      expect(enOnly.targetLang, equals('en'));
      expect(enOnly.status, equals('verified'));
      expect(urOnly.targetLang, equals('ur'));
      expect(urOnly.status, equals('draft'));
      expect(urOnly.status, isNot(equals(enOnly.status)));
    });

    // -------------------------------------------------------------
    // 8. Multiple Senses
    // -------------------------------------------------------------
    test('8. Supports multiple meanings (senses) per German lemma independently', () {
      final bankSense1 = LexiconSense(
        id: 's_1',
        entryId: 'e_bank',
        senseOrder: 1,
        definitionDe: 'Kreditinstitut, Geldinstitut',
        definitionEn: 'financial institution / bank',
        contextDomain: 'finance',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final bankSense2 = LexiconSense(
        id: 's_2',
        entryId: 'e_bank',
        senseOrder: 2,
        definitionDe: 'Sitzbank im Park',
        definitionEn: 'park bench',
        contextDomain: 'furniture/outdoor',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(bankSense1.entryId, equals(bankSense2.entryId));
      expect(bankSense1.senseOrder, equals(1));
      expect(bankSense2.senseOrder, equals(2));
      expect(bankSense1.contextDomain, equals('finance'));
      expect(bankSense2.contextDomain, equals('furniture/outdoor'));
    });

    // -------------------------------------------------------------
    // 9. Synonyms as Independent Records
    // -------------------------------------------------------------
    test('9. Synonyms remain separate records with status and source type', () {
      final syn = LexiconSynonym(
        id: 'syn_1',
        entryId: 'e_1',
        synonymWord: 'Speisetisch',
        nuanceNote: 'Specifically dining table',
        status: 'draft',
        sourceType: 'original_curated',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(syn.synonymWord, equals('Speisetisch'));
      expect(syn.nuanceNote, contains('dining table'));
      expect(syn.status, equals('draft'));
    });

    // -------------------------------------------------------------
    // 10. Examples with Original/Curated Source
    // -------------------------------------------------------------
    test('10. Examples support curated sentence with translation and CEFR', () {
      final example = LexiconExample(
        id: 'ex_1',
        entryId: 'e_1',
        sentenceDe: 'Der Tisch aus Holz steht in der Küche.',
        sentenceEn: 'The wooden table is in the kitchen.',
        sentenceUr: 'لکڑی کی میز باورچی خانے میں رکھی ہے۔',
        cefrLevel: 'A1',
        status: 'draft',
        sourceType: 'original_curated',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(example.sentenceDe, contains('Der Tisch'));
      expect(example.cefrLevel, equals('A1'));
      expect(example.sourceType, equals('original_curated'));
    });

    // -------------------------------------------------------------
    // 11. Normalization Preserves German Characters
    // -------------------------------------------------------------
    test('11. Normalization trims and lowercases while preserving ä, ö, ü, ß', () {
      expect(MasterLexiconEntry.normalizeLemma('  Häuser  '), equals('häuser'));
      expect(MasterLexiconEntry.normalizeLemma('Öffnen'), equals('öffnen'));
      expect(MasterLexiconEntry.normalizeLemma('ÜBERALL'), equals('überall'));
      expect(MasterLexiconEntry.normalizeLemma('Straße'), equals('straße'));
      expect(MasterLexiconEntry.normalizeLemma('  groß  '), equals('groß'));
      expect(MasterLexiconEntry.normalizeLemma('Fußball'), equals('fußball'));
    });

    // -------------------------------------------------------------
    // 12. Duplicate Detection Key
    // -------------------------------------------------------------
    test('12. Uniqueness key is normalized_lemma + part_of_speech', () {
      final entry1 = MasterLexiconEntry(
        id: '1',
        lemma: 'laufen',
        normalizedLemma: MasterLexiconEntry.normalizeLemma('laufen'),
        partOfSpeech: 'verb',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final entry2 = MasterLexiconEntry(
        id: '2',
        lemma: 'Laufen',
        normalizedLemma: MasterLexiconEntry.normalizeLemma('Laufen'),
        partOfSpeech: 'verb',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final entryNoun = MasterLexiconEntry(
        id: '3',
        lemma: 'Laufen',
        normalizedLemma: MasterLexiconEntry.normalizeLemma('Laufen'),
        partOfSpeech: 'noun', // Das Laufen
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(entry1.normalizedLemma, equals(entry2.normalizedLemma));
      // Same lemma + same POS is a duplicate
      expect(
        '${entry1.normalizedLemma}|${entry1.partOfSpeech}',
        equals('${entry2.normalizedLemma}|${entry2.partOfSpeech}'),
      );

      // Same lemma + different POS (verb vs noun) is distinct
      expect(
        '${entry1.normalizedLemma}|${entry1.partOfSpeech}',
        isNot(equals('${entryNoun.normalizedLemma}|${entryNoun.partOfSpeech}')),
      );
    });

    // -------------------------------------------------------------
    // 13. Workflow Statuses
    // -------------------------------------------------------------
    test('13. Workflow lifecycle supports draft, review, verified, rejected, archived', () {
      for (final st in ['draft', 'review', 'verified', 'rejected', 'archived']) {
        expect(
          PosRulesValidator.validateStatusAndProvenance(
            status: st,
            sourceType: 'original_curated',
          ).isValid,
          isTrue,
        );
      }

      expect(LexiconFilter.availableStatuses.contains('archived'), isTrue);
      expect(
        PosRulesValidator.validateStatusAndProvenance(
          status: 'unknown_status',
          sourceType: 'original_curated',
        ).isValid,
        isFalse,
      );
    });

    // -------------------------------------------------------------
    // 14. Provenance & Machine-Generated Security Policy
    // -------------------------------------------------------------
    test('14. Machine-generated content must NEVER automatically become VERIFIED', () {
      // Machine generated in draft is allowed
      final draftResult = PosRulesValidator.validateStatusAndProvenance(
        status: 'draft',
        sourceType: 'machine_generated',
      );
      expect(draftResult.isValid, isTrue);

      // Machine generated directly verified is strictly blocked
      final verifiedResult = PosRulesValidator.validateStatusAndProvenance(
        status: 'verified',
        sourceType: 'machine_generated',
      );
      expect(verifiedResult.isValid, isFalse);
      expect(verifiedResult.errors.first, contains('Security policy violation'));
    });

    // -------------------------------------------------------------
    // 15. German Unicode Characters
    // -------------------------------------------------------------
    test('15. German Unicode characters ä, ö, ü, ß are fully recognized and preserved', () {
      expect(PosRulesValidator.containsValidGermanCharacters('Grüße aus Köln'), isTrue);
      expect(PosRulesValidator.containsValidGermanCharacters('Äpfel und Überraschung'), isTrue);
      expect(PosRulesValidator.containsValidGermanCharacters('Straße'), isTrue);
    });

    // -------------------------------------------------------------
    // 16. RTL Unicode Characters (Urdu, Persian, Arabic)
    // -------------------------------------------------------------
    test('16. RTL Unicode characters for UR, FA, AR are recognized', () {
      expect(PosRulesValidator.hasRtlUnicodeCharacters('میز'), isTrue); // Urdu / Persian
      expect(PosRulesValidator.hasRtlUnicodeCharacters('طاولة'), isTrue); // Arabic
      expect(PosRulesValidator.hasRtlUnicodeCharacters('خانه'), isTrue); // Persian
      expect(PosRulesValidator.hasRtlUnicodeCharacters('table'), isFalse); // English
    });

    // -------------------------------------------------------------
    // 17. CSV Compatibility & Round-trip
    // -------------------------------------------------------------
    test('17. CSV Import & Export preserve all fields, quotes, and RTL Unicode', () {
      final exportEntry = CsvExportEntry(
        master: MasterLexiconEntry(
          id: 'test_1',
          lemma: 'Tisch',
          normalizedLemma: 'tisch',
          partOfSpeech: 'noun',
          gender: 'der',
          pluralForm: 'Tische',
          cefrLevel: 'A1',
          status: 'draft',
          sourceType: 'original_curated',
          provenance: 'Pilot Vocabulary',
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
        translations: [
          LexiconTranslation(
            id: 't_1',
            entryId: 'test_1',
            targetLang: 'en',
            translation: 'table',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          LexiconTranslation(
            id: 't_2',
            entryId: 'test_1',
            targetLang: 'ur',
            translation: 'میز',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          LexiconTranslation(
            id: 't_3',
            entryId: 'test_1',
            targetLang: 'ar',
            translation: 'طاولة',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
        senses: [
          LexiconSense(
            id: 's_1',
            entryId: 'test_1',
            definitionDe: 'Möbelstück mit Platte und Beinen',
            definitionEn: 'piece of furniture',
            contextDomain: 'furniture',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
        synonyms: [
          LexiconSynonym(
            id: 'syn_1',
            entryId: 'test_1',
            synonymWord: 'Esstisch',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
        examples: [
          LexiconExample(
            id: 'ex_1',
            entryId: 'test_1',
            sentenceDe: 'Der Tisch ist neu.',
            sentenceEn: 'The table is new.',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
      );

      final csvContent = CsvSerializer.serialize([exportEntry]);
      expect(csvContent.contains('\uFEFF'), isTrue); // BOM check
      expect(csvContent.contains('Tisch'), isTrue);
      expect(csvContent.contains('der'), isTrue);
      expect(csvContent.contains('noun'), isTrue);
      expect(csvContent.contains('Tische'), isTrue);
      expect(csvContent.contains('table'), isTrue);
      expect(csvContent.contains('میز'), isTrue);
      expect(csvContent.contains('طاولة'), isTrue);

      // Now parse and validate with CsvParser & CsvValidator
      final parsedRecords = CsvParser.parse(csvContent);
      expect(parsedRecords.length, equals(1));

      final validatedRows = CsvValidator.validate(parsedRecords);
      expect(validatedRows.length, equals(1));
      final row = validatedRows.first;
      expect(row.isValid, isTrue);
      expect(row.lemma, equals('Tisch'));
      expect(row.partOfSpeech, equals('noun'));
      expect(row.gender, equals('der'));
      expect(row.pluralForm, equals('Tische'));
      expect(row.translations['en'], equals('table'));
      expect(row.translations['ur'], equals('میز'));
      expect(row.translations['ar'], equals('طاولة'));
    });

    // -------------------------------------------------------------
    // 18. Existing Role and RLS Capability Model
    // -------------------------------------------------------------
    test('18. Role capabilities enforce Superadmin, Reviewer, and Editor boundaries', () {
      final draftEntry = MasterLexiconEntry(
        id: 'e_draft',
        lemma: 'Haus',
        normalizedLemma: 'haus',
        partOfSpeech: 'noun',
        status: 'draft',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final verifiedEntry = MasterLexiconEntry(
        id: 'e_verified',
        lemma: 'Buch',
        normalizedLemma: 'buch',
        partOfSpeech: 'noun',
        status: 'verified',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Superadmin: Full CRUD
      expect(draftEntry.canEdit(AdminRole.superadmin), isTrue);
      expect(verifiedEntry.canEdit(AdminRole.superadmin), isTrue);
      expect(draftEntry.canVerify(AdminRole.superadmin), isTrue);
      expect(draftEntry.canDelete(AdminRole.superadmin), isTrue);

      // Reviewer: Read, Edit, Verify, Reject; cannot Delete
      expect(draftEntry.canEdit(AdminRole.reviewer), isTrue);
      expect(verifiedEntry.canEdit(AdminRole.reviewer), isTrue);
      expect(draftEntry.canVerify(AdminRole.reviewer), isTrue);
      expect(draftEntry.canDelete(AdminRole.reviewer), isFalse);

      // Editor: Create & Edit Draft/Review; BLOCKED from editing Verified; cannot Verify; cannot Delete
      expect(draftEntry.canEdit(AdminRole.editor), isTrue);
      expect(verifiedEntry.canEdit(AdminRole.editor), isFalse);
      expect(draftEntry.canVerify(AdminRole.editor), isFalse);
      expect(draftEntry.canDelete(AdminRole.editor), isFalse);

      // Child records: Editor cannot edit child of verified parent
      final sense = LexiconSense(
        id: 's_1',
        entryId: 'e_verified',
        definitionDe: 'Gedrucktes Werk',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(sense.canEdit(AdminRole.editor, parentIsVerified: true), isFalse);
      expect(sense.canEdit(AdminRole.editor, parentIsVerified: false), isTrue);
      expect(sense.canEdit(AdminRole.reviewer, parentIsVerified: true), isTrue);
    });
  });
}
