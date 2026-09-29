// test/features/reader/domain/word_reconstructor_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:tap_to_translate/features/reader/domain/word_reconstructor.dart';

void main() {
  group('GermanWordReconstructor Tests', () {
    const reconstructor = GermanWordReconstructor();

    test('Reconstructs words and cleans outer punctuation and quotes', () {
      const fullText = 'Er sagte: „Deutschland“ ist schön!';
      // Create non-empty dummy rects
      final rects = List.generate(
        fullText.length,
        (i) => PdfRect(i * 10.0, 100.0, (i + 1) * 10.0, 85.0),
      );

      final pageText = PdfPageText(
        pageNumber: 1,
        fullText: fullText,
        charRects: rects,
        fragments: [],
      );

      final words = reconstructor.reconstructWords(pageText);

      final deutschlandWord = words.firstWhere((w) => w.cleanWord == 'Deutschland');
      expect(deutschlandWord.cleanWord, equals('Deutschland'));
      expect(deutschlandWord.rawText, contains('Deutschland'));

      final schoenWord = words.firstWhere((w) => w.cleanWord == 'schön');
      expect(schoenWord.cleanWord, equals('schön'));
      expect(schoenWord.rawText, equals('schön!'));
    });

    test('Fuses adjacent split text items with zero gap', () {
      // Simulate "Deutsch" and "land" split across two adjacent items
      const fullText = 'Deutsch land';
      // "Deutsch" (7 chars 0..6): x = 0..70
      // space (char 7): x = 70..70
      // "land" (4 chars 8..11): x = 70.5..110.5 (gap = 0.5 pt < 1.5 pt threshold)
      final rects = [
        const PdfRect(0, 100, 10, 85), // D
        const PdfRect(10, 100, 20, 85), // e
        const PdfRect(20, 100, 30, 85), // u
        const PdfRect(30, 100, 40, 85), // t
        const PdfRect(40, 100, 50, 85), // s
        const PdfRect(50, 100, 60, 85), // c
        const PdfRect(60, 100, 70, 85), // h
        const PdfRect(70, 100, 70, 85), // space
        const PdfRect(70.5, 100, 80.5, 85), // l (gap = 0.5 pt)
        const PdfRect(80.5, 100, 90.5, 85), // a
        const PdfRect(90.5, 100, 100.5, 85), // n
        const PdfRect(100.5, 100, 110.5, 85), // d
      ];

      final pageText = PdfPageText(
        pageNumber: 1,
        fullText: fullText,
        charRects: rects,
        fragments: [],
      );

      final words = reconstructor.reconstructWords(pageText);
      final fused = words.where((w) => w.cleanWord == 'Deutschland').toList();

      expect(fused.isNotEmpty, isTrue);
      expect(fused.first.cleanWord, equals('Deutschland'));
    });

    test('Detects hyphenated line-break compound words', () {
      const fullText = 'Bundes- republik';
      // "Bundes-" on line 1 at y = 100
      // "republik" on line 2 at y = 80 (vertical drop = 20 pt)
      final rects = [
        const PdfRect(50, 100, 60, 85), // B
        const PdfRect(60, 100, 70, 85), // u
        const PdfRect(70, 100, 80, 85), // n
        const PdfRect(80, 100, 90, 85), // d
        const PdfRect(90, 100, 100, 85), // e
        const PdfRect(100, 100, 110, 85), // s
        const PdfRect(110, 100, 115, 85), // -
        const PdfRect(115, 100, 115, 85), // space / line break
        const PdfRect(50, 80, 60, 65), // r
        const PdfRect(60, 80, 70, 65), // e
        const PdfRect(70, 80, 80, 65), // p
        const PdfRect(80, 80, 90, 65), // u
        const PdfRect(90, 80, 100, 65), // b
        const PdfRect(100, 80, 105, 65), // l
        const PdfRect(105, 80, 110, 65), // i
        const PdfRect(110, 80, 120, 65), // k
      ];

      final pageText = PdfPageText(
        pageNumber: 1,
        fullText: fullText,
        charRects: rects,
        fragments: [],
      );

      final words = reconstructor.reconstructWords(pageText);
      final bundesWord = words.firstWhere((w) => w.cleanWord == 'Bundes');

      expect(bundesWord.cleanWord, equals('Bundes'));
      expect(bundesWord.dehyphenatedCompound, equals('Bundesrepublik'));
      expect(bundesWord.lookupTerm, equals('Bundesrepublik'));
    });
  });
}
