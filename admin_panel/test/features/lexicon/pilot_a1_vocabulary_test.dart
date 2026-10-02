import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:german_lexicon_admin/features/csv_export/domain/models/csv_export_entry.dart';
import 'package:german_lexicon_admin/features/csv_export/domain/services/csv_serializer.dart';
import 'package:german_lexicon_admin/features/csv_import/domain/models/csv_import_row.dart';
import 'package:german_lexicon_admin/features/csv_import/domain/services/csv_parser.dart';
import 'package:german_lexicon_admin/features/csv_import/domain/services/csv_validator.dart';
import 'package:german_lexicon_admin/features/lexicon/domain/models/lexicon_example.dart';
import 'package:german_lexicon_admin/features/lexicon/domain/models/lexicon_sense.dart';
import 'package:german_lexicon_admin/features/lexicon/domain/models/lexicon_synonym.dart';
import 'package:german_lexicon_admin/features/lexicon/domain/models/lexicon_translation.dart';
import 'package:german_lexicon_admin/features/lexicon/domain/models/master_lexicon_entry.dart';
import 'package:german_lexicon_admin/features/lexicon/domain/services/pos_rules_validator.dart';
import 'package:german_lexicon_admin/features/quality/domain/models/word_quality.dart';

void main() {
  group('Phase 12C-2: A1 Pilot Vocabulary (100 Entries) Validation', () {
    late String csvContent;
    late List<CsvParsedRecord> parsedRecords;
    late List<CsvImportRow> validatedRows;

    setUpAll(() {
      final file = File('data/pilot_a1_100.csv');
      expect(file.existsSync(), isTrue, reason: 'pilot_a1_100.csv must exist in admin_panel/data/');
      csvContent = file.readAsStringSync();
      expect(csvContent.isNotEmpty, isTrue);

      parsedRecords = CsvParser.parse(csvContent);
      validatedRows = CsvValidator.validate(parsedRecords);
    });

    test('1. Exact entry count: exactly 100 entries', () {
      expect(parsedRecords.length, equals(100));
      expect(validatedRows.length, equals(100));
    });

    test('2. POS distribution: 40 nouns, 25 verbs, 20 adjectives, 10 adverbs, 5 other', () {
      final nouns = validatedRows.where((r) => r.partOfSpeech == 'noun').toList();
      final verbs = validatedRows.where((r) => r.partOfSpeech == 'verb').toList();
      final adjectives = validatedRows.where((r) => r.partOfSpeech == 'adjective').toList();
      final adverbs = validatedRows.where((r) => r.partOfSpeech == 'adverb').toList();
      final others = validatedRows.where((r) => !['noun', 'verb', 'adjective', 'adverb'].contains(r.partOfSpeech)).toList();

      expect(nouns.length, equals(40), reason: 'Expected exactly 40 nouns');
      expect(verbs.length, equals(25), reason: 'Expected exactly 25 verbs');
      expect(adjectives.length, equals(20), reason: 'Expected exactly 20 adjectives');
      expect(adverbs.length, equals(10), reason: 'Expected exactly 10 adverbs');
      expect(others.length, equals(5), reason: 'Expected exactly 5 other high-frequency lexical items');

      // Total must be 100
      expect(nouns.length + verbs.length + adjectives.length + adverbs.length + others.length, equals(100));
    });

    test('3. Zero validation errors across all 100 entries', () {
      final invalidRows = validatedRows.where((r) => !r.isValid).toList();
      if (invalidRows.isNotEmpty) {
        final errorLog = invalidRows
            .map((r) => 'Row ${r.rowIndex} (${r.lemma}): ${r.validationErrors.join(', ')}')
            .join('\n');
        fail('Found invalid rows:\n$errorLog');
      }
      expect(invalidRows, isEmpty);
      for (final row in validatedRows) {
        expect(row.isValid, isTrue);
        expect(row.validationErrors, isEmpty);
      }
    });

    test('4. Noun rules: clean lemma, valid article, valid plural', () {
      final nouns = validatedRows.where((r) => r.partOfSpeech == 'noun').toList();
      for (final noun in nouns) {
        expect(noun.lemma, isNotEmpty);
        expect(
          noun.lemma.startsWith(RegExp(r'^(der|die|das)\s+', caseSensitive: false)),
          isFalse,
          reason: 'Noun lemma "${noun.lemma}" must not include leading article',
        );
        expect(
          ['der', 'die', 'das'].contains(noun.gender?.toLowerCase()),
          isTrue,
          reason: 'Noun "${noun.lemma}" has invalid article "${noun.gender}"',
        );
        expect(
          noun.pluralForm,
          isNotNull,
          reason: 'Noun "${noun.lemma}" must have plural form defined',
        );
        expect(
          noun.pluralForm!.trim().isNotEmpty,
          isTrue,
          reason: 'Noun "${noun.lemma}" plural must not be empty',
        );
      }
    });

    test('5. Verb rules: canonical infinitive form', () {
      final verbs = validatedRows.where((r) => r.partOfSpeech == 'verb').toList();
      for (final verb in verbs) {
        final res = PosRulesValidator.validateVerb(lemma: verb.lemma);
        expect(
          res.isValid,
          isTrue,
          reason: 'Verb "${verb.lemma}" failed canonical validation: ${res.errors}',
        );
      }
    });

    test('6. Adjective rules: base/positive form', () {
      final adjectives = validatedRows.where((r) => r.partOfSpeech == 'adjective').toList();
      for (final adj in adjectives) {
        final res = PosRulesValidator.validateAdjective(lemma: adj.lemma);
        expect(
          res.isValid,
          isTrue,
          reason: 'Adjective "${adj.lemma}" failed base-form validation: ${res.errors}',
        );
      }
    });

    test('7. Complete multilingual translations (EN, UR, FA, AR)', () {
      for (final row in validatedRows) {
        expect(row.translations['en']?.trim().isNotEmpty, isTrue,
            reason: 'Word "${row.lemma}" missing English');
        expect(row.translations['ur']?.trim().isNotEmpty, isTrue,
            reason: 'Word "${row.lemma}" missing Urdu');
        expect(row.translations['fa']?.trim().isNotEmpty, isTrue,
            reason: 'Word "${row.lemma}" missing Farsi');
        expect(row.translations['ar']?.trim().isNotEmpty, isTrue,
            reason: 'Word "${row.lemma}" missing Arabic');

        // Verify non-placeholder
        for (final text in [
          row.translations['en']!,
          row.translations['ur']!,
          row.translations['fa']!,
          row.translations['ar']!,
        ]) {
          expect(text.toLowerCase().contains('todo'), isFalse);
          expect(text.toLowerCase().contains('tbd'), isFalse);
          expect(text.toLowerCase().contains('placeholder'), isFalse);
        }
      }
    });

    test('8. German and English example sentences present and non-trivial', () {
      for (final row in validatedRows) {
        expect(row.exampleDe?.trim().isNotEmpty, isTrue,
            reason: 'Word "${row.lemma}" missing German example');
        expect(row.exampleEn?.trim().isNotEmpty, isTrue,
            reason: 'Word "${row.lemma}" missing English example translation');

        // Example contains substantial length
        expect(row.exampleDe!.length, greaterThan(5));
        expect(row.exampleEn!.length, greaterThan(5));
      }
    });

    test('9. Polysemous words: "Bank" contains multiple distinct senses', () {
      final bank = validatedRows.firstWhere((r) => r.lemma == 'Bank');
      expect(bank.senseDe, isNotNull);
      final senses = bank.senseDe!.split(';').map((s) => s.trim()).toList();
      expect(senses.length, greaterThanOrEqualTo(2),
          reason: 'Polysemous word "Bank" must have at least 2 distinct senses');
      expect(senses.any((s) => s.toLowerCase().contains('finanz') || s.toLowerCase().contains('geld')), isTrue);
      expect(senses.any((s) => s.toLowerCase().contains('sitz') || s.toLowerCase().contains('park')), isTrue);
    });

    test('10. No duplicates within the pilot dataset (normalizedLemma + POS)', () {
      final seen = <String>{};
      for (final row in validatedRows) {
        final key = '${row.normalizedLemma}#${row.partOfSpeech}';
        expect(seen.contains(key), isFalse,
            reason: 'Duplicate detected within pilot: $key');
        seen.add(key);
      }
    });

    test('11. WordQualityReport marks pilot entries with 100% complete quality status', () {
      for (final row in validatedRows) {
        final entry = MasterLexiconEntry(
          id: 'test-${row.rowIndex}',
          lemma: row.lemma,
          normalizedLemma: row.normalizedLemma,
          partOfSpeech: row.partOfSpeech,
          gender: row.gender,
          pluralForm: row.pluralForm,
          cefrLevel: row.cefrLevel,
          status: 'draft',
          provenance: 'a1_pilot',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        final translations = [
          LexiconTranslation(
            id: 't-en',
            entryId: entry.id,
            targetLang: 'en',
            translation: row.translations['en']!,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          LexiconTranslation(
            id: 't-ur',
            entryId: entry.id,
            targetLang: 'ur',
            translation: row.translations['ur']!,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          LexiconTranslation(
            id: 't-fa',
            entryId: entry.id,
            targetLang: 'fa',
            translation: row.translations['fa']!,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          LexiconTranslation(
            id: 't-ar',
            entryId: entry.id,
            targetLang: 'ar',
            translation: row.translations['ar']!,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ];

        final senses = (row.senseDe ?? 'General meaning')
            .split(';')
            .map((s) => LexiconSense(
                  id: 's-1',
                  entryId: entry.id,
                  definitionDe: s.trim(),
                  createdAt: DateTime.now(),
                  updatedAt: DateTime.now(),
                ))
            .toList();

        final examples = [
          LexiconExample(
            id: 'e-1',
            entryId: entry.id,
            sentenceDe: row.exampleDe!,
            sentenceEn: row.exampleEn!,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          )
        ];

        final report = WordQualityReport.evaluate(
          entry: entry,
          translations: translations,
          senses: senses,
          examples: examples,
        );

        expect(report.status, WordQualityStatus.complete,
            reason: 'Entry "${row.lemma}" must be complete, but got issues: ${report.issues}');
        expect(report.issues, isEmpty);
        expect(report.score, equals(100));
      }
    });

    test('12. Round-trip CSV serialization preserves all characters, umlauts, and RTL scripts', () {
      final exportEntries = validatedRows.map((r) {
        final entry = MasterLexiconEntry(
          id: 'export-${r.rowIndex}',
          lemma: r.lemma,
          normalizedLemma: r.normalizedLemma,
          partOfSpeech: r.partOfSpeech,
          gender: r.gender,
          pluralForm: r.pluralForm,
          cefrLevel: r.cefrLevel,
          status: 'draft',
          provenance: 'a1_pilot',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        return CsvExportEntry(
          master: entry,
          translations: [
            LexiconTranslation(
              id: 't-en',
              entryId: entry.id,
              targetLang: 'en',
              translation: r.translations['en']!,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            LexiconTranslation(
              id: 't-ur',
              entryId: entry.id,
              targetLang: 'ur',
              translation: r.translations['ur']!,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            LexiconTranslation(
              id: 't-fa',
              entryId: entry.id,
              targetLang: 'fa',
              translation: r.translations['fa']!,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
            LexiconTranslation(
              id: 't-ar',
              entryId: entry.id,
              targetLang: 'ar',
              translation: r.translations['ar']!,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ],
          senses: (r.senseDe ?? '')
              .split(';')
              .where((s) => s.trim().isNotEmpty)
              .map((s) => LexiconSense(
                    id: 's',
                    entryId: entry.id,
                    definitionDe: s.trim(),
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ))
              .toList(),
          synonyms: r.synonyms
              .map((syn) => LexiconSynonym(
                    id: 'syn',
                    entryId: entry.id,
                    synonymWord: syn,
                    createdAt: DateTime.now(),
                    updatedAt: DateTime.now(),
                  ))
              .toList(),
          examples: [
            LexiconExample(
              id: 'ex',
              entryId: entry.id,
              sentenceDe: r.exampleDe!,
              sentenceEn: r.exampleEn!,
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            )
          ],
        );
      }).toList();

      final serializedCsv = CsvSerializer.serialize(exportEntries);
      expect(serializedCsv.startsWith('\uFEFF'), isTrue, reason: 'Must contain UTF-8 BOM');

      // Re-parse
      final reParsedRecords = CsvParser.parse(serializedCsv);
      expect(reParsedRecords.length, equals(100));

      final reValidatedRows = CsvValidator.validate(reParsedRecords);
      expect(reValidatedRows.every((r) => r.isValid), isTrue);

      // Verify exact lemma, translations, examples preserved
      for (int i = 0; i < 100; i++) {
        final orig = validatedRows[i];
        final re = reValidatedRows[i];

        expect(re.lemma, equals(orig.lemma));
        expect(re.partOfSpeech, equals(orig.partOfSpeech));
        expect(re.gender, equals(orig.gender));
        expect(re.pluralForm, equals(orig.pluralForm));
        expect(re.translations['en'], equals(orig.translations['en']));
        expect(re.translations['ur'], equals(orig.translations['ur']));
        expect(re.translations['fa'], equals(orig.translations['fa']));
        expect(re.translations['ar'], equals(orig.translations['ar']));
        expect(re.exampleDe, equals(orig.exampleDe));
        expect(re.exampleEn, equals(orig.exampleEn));
      }
    });
  });
}
