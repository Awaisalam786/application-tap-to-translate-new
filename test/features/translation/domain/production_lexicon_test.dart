// test/features/translation/domain/production_lexicon_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:tap_to_translate/features/translation/data/repositories/production_german_lexicon_service.dart';
import 'package:tap_to_translate/features/translation/domain/models/lexicon_entry_status.dart';
import 'package:tap_to_translate/features/translation/domain/models/translation_target_language.dart';

void main() {
  group('Production German Lexicon Service - Phase 5 Tests', () {
    late ProductionGermanLexiconService service;

    setUp(() {
      service = ProductionGermanLexiconService();
    });

    group('1. Exact Match Lookups', () {
      test('Exact match for Deutschland', () {
        final entry = service.lookupEntry('Deutschland');
        expect(entry, isNotNull);
        expect(entry!.word, equals('Deutschland'));
        expect(entry.lemma, equals('Deutschland'));
        expect(entry.article, equals('das'));
        expect(entry.gender, equals('Neutrum'));
      });

      test('Exact match for deutsch', () {
        final entry = service.lookupEntry('deutsch');
        expect(entry, isNotNull);
        expect(entry!.lemma, equals('deutsch'));
        expect(entry.partOfSpeech, equals('Adjektiv'));
      });

      test('Exact match for arbeiten', () {
        final entry = service.lookupEntry('arbeiten');
        expect(entry, isNotNull);
        expect(entry!.lemma, equals('arbeiten'));
        expect(entry.partOfSpeech, equals('Verb'));
      });

      test('Exact match for Möglichkeit', () {
        final entry = service.lookupEntry('Möglichkeit');
        expect(entry, isNotNull);
        expect(entry!.lemma, equals('Möglichkeit'));
        expect(entry.article, equals('die'));
        expect(entry.gender, equals('Femininum'));
      });

      test('Exact match for größer', () {
        final entry = service.lookupEntry('größer');
        expect(entry, isNotNull);
        expect(entry!.word, equals('größer'));
        expect(entry.lemma, equals('groß'));
      });

      test('Exact match for Fußball', () {
        final entry = service.lookupEntry('Fußball');
        expect(entry, isNotNull);
        expect(entry!.article, equals('der'));
        expect(entry.gender, equals('Maskulinum'));
      });

      test('Exact match for Mädchen', () {
        final entry = service.lookupEntry('Mädchen');
        expect(entry, isNotNull);
        expect(entry!.article, equals('das'));
        expect(entry.gender, equals('Neutrum'));
      });

      test('Exact match for Zusammenfassung', () {
        final entry = service.lookupEntry('Zusammenfassung');
        expect(entry, isNotNull);
        expect(entry!.article, equals('die'));
        expect(entry.gender, equals('Femininum'));
      });
    });

    group('2. Punctuation and Quote Stripping (Surface Normalization)', () {
      test('Punctuation attached: Deutschland.', () {
        final entry = service.lookupEntry('Deutschland.');
        expect(entry, isNotNull);
        expect(entry!.word, equals('Deutschland'));
      });

      test('German quotes attached: „Möglichkeiten“', () {
        final entry = service.lookupEntry('„Möglichkeiten“');
        expect(entry, isNotNull);
        expect(entry!.lemma, equals('Möglichkeit'));
      });

      test('Leading/trailing punctuation: »arbeiten!«', () {
        final entry = service.lookupEntry('»arbeiten!«');
        expect(entry, isNotNull);
        expect(entry!.lemma, equals('arbeiten'));
      });

      test('Surrounding question and comma: größer?', () {
        final entry = service.lookupEntry('größer?');
        expect(entry, isNotNull);
        expect(entry!.word, equals('größer'));
      });
    });

    group('3. Case Insensitive & Variant Handling', () {
      test('Lowercased noun: deutschland -> Deutschland', () {
        final entry = service.lookupEntry('deutschland');
        expect(entry, isNotNull);
        expect(entry!.word, equals('Deutschland'));
      });

      test('Capitalized verb: Arbeiten -> arbeiten', () {
        final entry = service.lookupEntry('Arbeiten');
        expect(entry, isNotNull);
        expect(entry!.lemma, equals('arbeiten'));
      });

      test('All-uppercase noun: DEUTSCHLAND -> Deutschland', () {
        final entry = service.lookupEntry('DEUTSCHLAND');
        expect(entry, isNotNull);
        expect(entry!.word, equals('Deutschland'));
      });
    });

    group('4. Umlauts & ASCII Transcription Aliases', () {
      test('Preserves Umlaut ä in Mädchen', () {
        final entry = service.lookupEntry('Mädchen');
        expect(entry, isNotNull);
        expect(entry!.word, equals('Mädchen'));
      });

      test('ASCII transcription alias: maedchen -> Mädchen', () {
        final entry = service.lookupEntry('maedchen');
        expect(entry, isNotNull);
        expect(entry!.word, equals('Mädchen'));
      });

      test('Preserves Umlaut ö in Möglichkeit', () {
        final entry = service.lookupEntry('Möglichkeit');
        expect(entry, isNotNull);
        expect(entry!.word, equals('Möglichkeit'));
      });

      test('ASCII transcription alias: Moeglichkeit -> Möglichkeit', () {
        final entry = service.lookupEntry('Moeglichkeit');
        expect(entry, isNotNull);
        expect(entry!.word, equals('Möglichkeit'));
      });

      test('ASCII transcription alias: groesser -> größer', () {
        final entry = service.lookupEntry('groesser');
        expect(entry, isNotNull);
        expect(entry!.word, equals('größer'));
      });
    });

    group('5. Eszett (ß) vs Swiss German (ss) Handling', () {
      test('Eszett original: Fußball', () {
        final entry = service.lookupEntry('Fußball');
        expect(entry, isNotNull);
        expect(entry!.word, equals('Fußball'));
      });

      test('Swiss German / ss transcription: Fussball -> Fußball', () {
        final entry = service.lookupEntry('Fussball');
        expect(entry, isNotNull);
        expect(entry!.word, equals('Fußball'));
      });
    });

    group('6. Morphological Inflection Resolution (Without Fake Lemmatizer)', () {
      test('Past tense: arbeitete -> resolves to lemma arbeiten', () {
        final lemma = service.resolveToLemma('arbeitete');
        expect(lemma, equals('arbeiten'));

        final entry = service.lookupEntry('arbeitete');
        expect(entry, isNotNull);
        expect(entry!.lemma, equals('arbeiten'));
      });

      test('Noun plural: Möglichkeiten -> resolves to lemma Möglichkeit', () {
        final lemma = service.resolveToLemma('Möglichkeiten');
        expect(lemma, equals('Möglichkeit'));

        final entry = service.lookupEntry('Möglichkeiten');
        expect(entry, isNotNull);
        expect(entry!.lemma, equals('Möglichkeit'));
      });

      test('Adjective declension: deutsche -> resolves to deutsch', () {
        final entry = service.lookupEntry('deutsche');
        expect(entry, isNotNull);
        expect(entry!.lemma, equals('deutsch'));
      });

      test('Academic noun plural: Zusammenfassungen -> resolves to Zusammenfassung', () {
        final lemma = service.resolveToLemma('Zusammenfassungen');
        expect(lemma, equals('Zusammenfassung'));

        final entry = service.lookupEntry('Zusammenfassungen');
        expect(entry, isNotNull);
        expect(entry!.lemma, equals('Zusammenfassung'));
      });

      test('Already a lemma returns null from resolveToLemma (no over-stemming)', () {
        expect(service.resolveToLemma('arbeiten'), isNull);
        expect(service.resolveToLemma('Deutschland'), isNull);
      });
    });

    group('7. Missing Word Handling', () {
      test('Non-existent word returns null from lookupEntry', () {
        expect(service.lookupEntry('UnbekanntesWortXYZ'), isNull);
        expect(service.lookupEntry('12345'), isNull);
        expect(service.lookupEntry(''), isNull);
      });

      test('containsWord returns false for non-existent word', () async {
        expect(await service.containsWord('UnbekanntesWortXYZ'), isFalse);
        expect(await service.containsWord('Deutschland'), isTrue);
      });
    });

    group('8. Source Provenance & Data Integrity', () {
      test('Every entry carries transparent provenance and legal license', () {
        final entry = service.lookupEntry('Deutschland');
        expect(entry, isNotNull);

        final prov = entry!.provenance;
        expect(prov.source, equals('Wiktionary'));
        expect(prov.sourceId, equals('de.wiktionary.org'));
        expect(prov.license, equals('CC-BY-SA-4.0'));
        expect(prov.version, isNotEmpty);
        expect(prov.updatedAt, isNotNull);

        // Verification status
        expect(entry.status, equals(LexiconEntryStatus.curated));
        expect(entry.confidence, equals(1.0));
      });
    });

    group('9. Multilingual Translation Coverage (EN, UR, FA, AR)', () {
      test('All 8 test headwords contain valid translations for all 4 target languages', () {
        final words = [
          'Deutschland',
          'deutsch',
          'arbeiten',
          'Möglichkeit',
          'größer',
          'Fußball',
          'Mädchen',
          'Zusammenfassung',
        ];

        for (final word in words) {
          final entry = service.lookupEntry(word);
          expect(entry, isNotNull, reason: 'Failed for word $word');

          // English
          final en = entry!.translationFor('en');
          expect(en, isNotNull, reason: 'Missing EN for $word');
          expect(en!.meanings, isNotEmpty);

          // Urdu
          final ur = entry.translationFor('ur');
          expect(ur, isNotNull, reason: 'Missing UR for $word');
          expect(ur!.meanings, isNotEmpty);

          // Farsi
          final fa = entry.translationFor('fa');
          expect(fa, isNotNull, reason: 'Missing FA for $word');
          expect(fa!.meanings, isNotEmpty);

          // Arabic
          final ar = entry.translationFor('ar');
          expect(ar, isNotNull, reason: 'Missing AR for $word');
          expect(ar!.meanings, isNotEmpty);
        }
      });

      test('Urdu translation for Deutschland is جرمنی', () {
        final entry = service.lookupEntry('Deutschland');
        final ur = entry!.translationFor('ur');
        expect(ur!.meanings.first, equals('جرمنی'));
      });

      test('Farsi translation for arbeiten is کار کردن', () {
        final entry = service.lookupEntry('arbeiten');
        final fa = entry!.translationFor('fa');
        expect(fa!.meanings.first, equals('کار کردن'));
      });

      test('Arabic translation for Mädchen is فتاة', () {
        final entry = service.lookupEntry('Mädchen');
        final ar = entry!.translationFor('ar');
        expect(ar!.meanings.first, equals('فتاة'));
      });
    });

    group('10. GermanLexiconRepository Async Lookup Contract', () {
      test('Resolves inflected word worked asynchronously to English', () async {
        final result = await service.lookup(
          normalizedWord: 'arbeitete',
          targetLanguage: TranslationTargetLanguage.english,
        );

        expect(result, isNotNull);
        expect(result!.primaryTranslation, equals('to work'));
        expect(result.partOfSpeech, equals('Verb'));
        expect(result.exampleSentenceDe, isNotNull);
      });

      test('Resolves plural to Urdu', () async {
        final result = await service.lookup(
          normalizedWord: 'Möglichkeiten',
          targetLanguage: TranslationTargetLanguage.urdu,
        );

        expect(result, isNotNull);
        expect(result!.primaryTranslation, equals('امکان'));
        expect(result.gender, equals('Femininum'));
      });
    });
  });
}
