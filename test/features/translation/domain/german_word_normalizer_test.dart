// test/features/translation/domain/german_word_normalizer_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:tap_to_translate/features/translation/data/repositories/default_german_word_normalizer.dart';

void main() {
  group('DefaultGermanWordNormalizer Tests', () {
    const normalizer = DefaultGermanWordNormalizer();

    test('Punctuation Normalization: Strips outer punctuation cleanly', () {
      expect(normalizer.normalize('Deutschland.'), equals('Deutschland'));
      expect(normalizer.normalize('Buch?'), equals('Buch'));
      expect(normalizer.normalize('lernen!'), equals('lernen'));
      expect(normalizer.normalize('Haus,'), equals('Haus'));
      expect(normalizer.normalize('(arbeiten)'), equals('arbeiten'));
      expect(normalizer.normalize('[Möglichkeit]'), equals('Möglichkeit'));
      expect(normalizer.normalize('{normal};'), equals('normal'));
      expect(normalizer.normalize('—Zusammenfassung—'), equals('Zusammenfassung'));
      expect(normalizer.normalize('Bundes-'), equals('Bundes'));
    });

    test('German Typographical Quotes: Strips „...“ and «...»', () {
      expect(normalizer.normalize('„normalen“'), equals('normalen'));
      expect(normalizer.normalize('„Deutschland“'), equals('Deutschland'));
      expect(normalizer.normalize('»Arbeit«'), equals('Arbeit'));
      expect(normalizer.normalize('«Möglichkeit»'), equals('Möglichkeit'));
      expect(normalizer.normalize('"Buch"'), equals('Buch'));
      expect(normalizer.normalize('\'Haus\''), equals('Haus'));
    });

    test('Umlauts Preservation: ä, ö, ü, Ä, Ö, Ü are strictly preserved (no lossy ASCII folding)', () {
      expect(normalizer.normalize('Möglichkeit'), equals('Möglichkeit'));
      expect(normalizer.normalize('Mädchen'), equals('Mädchen'));
      expect(normalizer.normalize('schön!'), equals('schön'));
      expect(normalizer.normalize('Übung?'), equals('Übung'));
      expect(normalizer.normalize('Äpfel,'), equals('Äpfel'));
      // Verify no lossy folding
      expect(normalizer.normalize('Möglichkeit'), isNot(equals('Moeglichkeit')));
      expect(normalizer.normalize('Mädchen'), isNot(equals('Maedchen')));
    });

    test('Eszett Preservation: ß is strictly preserved without ss-folding', () {
      expect(normalizer.normalize('Fußball.'), equals('Fußball'));
      expect(normalizer.normalize('größer!'), equals('größer'));
      expect(normalizer.normalize('„heiß“'), equals('heiß'));
      expect(normalizer.normalize('Straße'), equals('Straße'));
      // Verify no lossy ss folding
      expect(normalizer.normalize('Fußball'), isNot(equals('Fussball')));
      expect(normalizer.normalize('größer'), isNot(equals('groesser')));
    });

    test('Candidate Generation: Generates as-is, capitalized noun, and lowercase verb/adj', () {
      final candidatesDeutschland = normalizer.generateLookupCandidates('deutschland.');
      expect(candidatesDeutschland, contains('deutschland'));
      expect(candidatesDeutschland, contains('Deutschland'));

      final candidatesArbeiten = normalizer.generateLookupCandidates('Arbeiten,');
      expect(candidatesArbeiten, contains('Arbeiten'));
      expect(candidatesArbeiten, contains('arbeiten'));

      final candidatesGroesser = normalizer.generateLookupCandidates('„größer“');
      expect(candidatesGroesser, contains('größer'));
      expect(candidatesGroesser, contains('Größer'));
    });
  });
}
