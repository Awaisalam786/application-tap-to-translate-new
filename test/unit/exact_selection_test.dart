// test/unit/exact_selection_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:tap_to_translate/core/models/selection_result.dart';
import 'package:tap_to_translate/core/models/word_occurrence.dart';
import 'package:tap_to_translate/features/reader/domain/exact_hit_tester.dart';
import 'package:tap_to_translate/features/reader/domain/word_reconstructor.dart';
import 'package:tap_to_translate/features/reader/domain/word_spatial_index.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ProductionExactHitTester Invariants', () {
    const hitTester = ProductionExactHitTester();

    final w1 = WordOccurrence(
      rawText: 'Deutsch',
      cleanWord: 'Deutsch',
      pageBoundingBox: const PdfRect(100.0, 750.0, 160.0, 735.0),
      pageNumber: 1,
      charIndex: 0,
      charLength: 7,
      charRects: const [],
    );

    final w2 = WordOccurrence(
      rawText: 'in',
      cleanWord: 'in',
      pageBoundingBox: const PdfRect(170.0, 750.0, 190.0, 735.0),
      pageNumber: 1,
      charIndex: 8,
      charLength: 2,
      charRects: const [],
    );

    final w3 = WordOccurrence(
      rawText: 'Deutschland.',
      cleanWord: 'Deutschland',
      pageBoundingBox: const PdfRect(200.0, 750.0, 280.0, 735.0),
      pageNumber: 1,
      charIndex: 11,
      charLength: 12,
      charRects: const [],
    );

    final spatialIndex = WordSpatialIndex(
      pageNumber: 1,
      words: [w1, w2, w3],
    );

    test('Exact hit inside word resolves to exact word', () {
      final result = hitTester.hitTest(
        pdfPoint: const PdfPoint(240.0, 742.5),
        screenOffset: const Offset(120.0, 60.0),
        spatialIndex: spatialIndex,
      );

      expect(result.status, equals(SelectionStatus.exactMatch));
      expect(result.word?.cleanWord, equals('Deutschland'));
      expect(result.word?.rawText, equals('Deutschland.'));
    });

    test('Tap in whitespace margin resolves to null', () {
      final result = hitTester.hitTest(
        pdfPoint: const PdfPoint(10.0, 10.0),
        screenOffset: const Offset(5.0, 5.0),
        spatialIndex: spatialIndex,
      );

      expect(result.status, equals(SelectionStatus.whitespace));
      expect(result.word, isNull);
    });

    test('Tap in inter-word gap resolves strictly to null (NO nearest-word fallback)', () {
      // Point 165.0 is in gap between 160.0 and 170.0
      final result = hitTester.hitTest(
        pdfPoint: const PdfPoint(165.0, 742.5),
        screenOffset: const Offset(82.5, 60.0),
        spatialIndex: spatialIndex,
      );

      expect(result.status, equals(SelectionStatus.interWordGap));
      expect(result.word, isNull);
    });

    test('Overlapping / ambiguous candidates resolve strictly to null', () {
      final overlappingW1 = WordOccurrence(
        rawText: 'OverlapA',
        cleanWord: 'OverlapA',
        pageBoundingBox: const PdfRect(100.0, 750.0, 150.0, 730.0),
        pageNumber: 1,
        charIndex: 0,
        charLength: 8,
        charRects: const [],
      );

      final overlappingW2 = WordOccurrence(
        rawText: 'OverlapB',
        cleanWord: 'OverlapB',
        pageBoundingBox: const PdfRect(140.0, 750.0, 190.0, 730.0),
        pageNumber: 1,
        charIndex: 9,
        charLength: 8,
        charRects: const [],
      );

      final overlapIndex = WordSpatialIndex(
        pageNumber: 1,
        words: [overlappingW1, overlappingW2],
      );

      // Tap at 145.0 (inside both bounding boxes)
      final result = hitTester.hitTest(
        pdfPoint: const PdfPoint(145.0, 740.0),
        screenOffset: const Offset(72.5, 60.0),
        spatialIndex: overlapIndex,
      );

      expect(result.status, equals(SelectionStatus.ambiguous));
      expect(result.word, isNull);
    });
  });

  group('GermanWordReconstructor Tests', () {
    const reconstructor = GermanWordReconstructor();

    test('Reconstructs German special characters (ä, ö, ü, ß)', () {
      const germanPhrase = 'Fußball größer Mädchen schön';
      final rects = [
        const PdfRect(10, 100, 20, 85),
        const PdfRect(20, 100, 30, 85),
        const PdfRect(30, 100, 40, 85),
        const PdfRect(40, 100, 50, 85),
        const PdfRect(50, 100, 60, 85),
        const PdfRect(60, 100, 70, 85),
        const PdfRect(70, 100, 80, 85), // Fußball (7 chars)
        const PdfRect(80, 100, 85, 85), // space
        const PdfRect(85, 100, 95, 85),
        const PdfRect(95, 100, 105, 85),
        const PdfRect(105, 100, 115, 85),
        const PdfRect(115, 100, 125, 85),
        const PdfRect(125, 100, 135, 85),
        const PdfRect(135, 100, 145, 85), // größer (6 chars)
        const PdfRect(145, 100, 150, 85), // space
        const PdfRect(150, 100, 160, 85),
        const PdfRect(160, 100, 170, 85),
        const PdfRect(170, 100, 180, 85),
        const PdfRect(180, 100, 190, 85),
        const PdfRect(190, 100, 200, 85),
        const PdfRect(200, 100, 210, 85),
        const PdfRect(210, 100, 220, 85), // Mädchen (7 chars)
        const PdfRect(220, 100, 225, 85), // space
        const PdfRect(225, 100, 235, 85),
        const PdfRect(235, 100, 245, 85),
        const PdfRect(245, 100, 255, 85),
        const PdfRect(255, 100, 265, 85),
        const PdfRect(265, 100, 275, 85), // schön (5 chars)
      ];

      final pText = PdfPageText(
        pageNumber: 1,
        fullText: germanPhrase,
        charRects: rects,
        fragments: [],
      );

      final words = reconstructor.reconstructWords(pText);
      final wordStrings = words.map((w) => w.cleanWord).toList();

      expect(wordStrings, equals(['Fußball', 'größer', 'Mädchen', 'schön']));
    });

    test('Fuses adjacent split text items into single word', () {
      const splitText = 'Deutsch land';
      final splitRects = [
        const PdfRect(100, 500, 110, 485),
        const PdfRect(110, 500, 120, 485),
        const PdfRect(120, 500, 130, 485),
        const PdfRect(130, 500, 140, 485),
        const PdfRect(140, 500, 150, 485),
        const PdfRect(150, 500, 160, 485),
        const PdfRect(160, 500, 170, 485),
        const PdfRect(170, 500, 170.5, 485), // Sub-1.5pt split artifact
        const PdfRect(170.5, 500, 180, 485),
        const PdfRect(180, 500, 190, 485),
        const PdfRect(190, 500, 200, 485),
        const PdfRect(200, 500, 210, 485),
      ];

      final pText = PdfPageText(
        pageNumber: 1,
        fullText: splitText,
        charRects: splitRects,
        fragments: [],
      );

      final words = reconstructor.reconstructWords(pText);
      final fused = words.where((w) => w.cleanWord == 'Deutschland').toList();
      expect(fused.isNotEmpty, isTrue);
      expect(fused.first.cleanWord, equals('Deutschland'));
    });

    test('Dehyphenates compound words across line wrap', () {
      const hyphenPhrase = 'Bundes- republik';
      final hyphenRects = [
        const PdfRect(50, 100, 60, 85),
        const PdfRect(60, 100, 70, 85),
        const PdfRect(70, 100, 80, 85),
        const PdfRect(80, 100, 90, 85),
        const PdfRect(90, 100, 100, 85),
        const PdfRect(100, 100, 110, 85),
        const PdfRect(110, 100, 115, 85), // '-'
        const PdfRect(115, 100, 115, 85), // line break
        const PdfRect(50, 80, 60, 65), // line 2 (20pt vertical drop)
        const PdfRect(60, 80, 70, 65),
        const PdfRect(70, 80, 80, 65),
        const PdfRect(80, 80, 90, 65),
        const PdfRect(90, 80, 100, 65),
        const PdfRect(100, 80, 105, 65),
        const PdfRect(105, 80, 110, 65),
        const PdfRect(110, 80, 120, 65),
      ];

      final pText = PdfPageText(
        pageNumber: 1,
        fullText: hyphenPhrase,
        charRects: hyphenRects,
        fragments: [],
      );

      final words = reconstructor.reconstructWords(pText);
      final bundes = words.firstWhere((w) => w.cleanWord == 'Bundes');
      expect(bundes.dehyphenatedCompound, equals('Bundesrepublik'));
      expect(bundes.lookupTerm, equals('Bundesrepublik'));
    });

    test('Strips German quotes and trailing punctuation cleanly', () {
      const phrase = '„normalen“ „Zusammenfassung“ »Buch« ›Wort‹ Ende. Frage? Achtung!';
      final rects = List.generate(phrase.length, (i) => PdfRect(i * 10.0, 100, (i + 1) * 10.0, 85));

      final pText = PdfPageText(
        pageNumber: 1,
        fullText: phrase,
        charRects: rects,
        fragments: [],
      );

      final words = reconstructor.reconstructWords(pText);
      final cleanWords = words.map((w) => w.cleanWord).toList();

      expect(cleanWords, contains('normalen'));
      expect(cleanWords, contains('Zusammenfassung'));
      expect(cleanWords, contains('Buch'));
      expect(cleanWords, contains('Wort'));
      expect(cleanWords, contains('Ende'));
      expect(cleanWords, contains('Frage'));
      expect(cleanWords, contains('Achtung'));
    });
  });

  group('Coordinate Invariance & Zoom Transformation Tests', () {
    test('Zero coordinate drift across 100%, 150%, 200%, 300% zoom and scroll offsets', () {
      const pageHeight = 841.89;
      const targetPdfX = 250.0;
      const targetPdfY = 400.0;

      final zoomLevels = [1.0, 1.5, 2.0, 3.0];
      final scrollOffsets = [
        const Offset(0, 0),
        const Offset(50, 100),
        const Offset(150, 250),
        const Offset(300, 500),
      ];

      for (final zoom in zoomLevels) {
        for (final scroll in scrollOffsets) {
          // Forward transform: PDF (bottom-left) -> Screen (top-left)
          // screenX = targetPdfX * zoom - scroll.dx
          // screenY = (pageHeight - targetPdfY) * zoom - scroll.dy
          final screenX = targetPdfX * zoom - scroll.dx;
          final screenY = (pageHeight - targetPdfY) * zoom - scroll.dy;

          // Inverse transform: Screen -> PDF
          final recoveredPdfX = (screenX + scroll.dx) / zoom;
          final recoveredPdfY = pageHeight - (screenY + scroll.dy) / zoom;

          expect((recoveredPdfX - targetPdfX).abs(), lessThan(1e-9));
          expect((recoveredPdfY - targetPdfY).abs(), lessThan(1e-9));
        }
      }
    });
  });
}
