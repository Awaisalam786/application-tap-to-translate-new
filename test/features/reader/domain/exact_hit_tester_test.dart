// test/features/reader/domain/exact_hit_tester_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:tap_to_translate/core/models/selection_result.dart';
import 'package:tap_to_translate/core/models/word_occurrence.dart';
import 'package:tap_to_translate/features/reader/domain/exact_hit_tester.dart';
import 'package:tap_to_translate/features/reader/domain/word_spatial_index.dart';

void main() {
  group('ProductionExactHitTester Invariant Tests', () {
    const hitTester = ProductionExactHitTester();

    final word1 = WordOccurrence(
      rawText: 'Deutsch',
      cleanWord: 'Deutsch',
      pageBoundingBox: const PdfRect(100.0, 750.0, 160.0, 735.0),
      pageNumber: 1,
      charIndex: 0,
      charLength: 7,
      charRects: const [],
    );

    final word2 = WordOccurrence(
      rawText: 'in',
      cleanWord: 'in',
      pageBoundingBox: const PdfRect(170.0, 750.0, 190.0, 735.0),
      pageNumber: 1,
      charIndex: 8,
      charLength: 2,
      charRects: const [],
    );

    final word3 = WordOccurrence(
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
      words: [word1, word2, word3],
    );

    test('Tap strictly inside bounding box returns exact word occurrence', () {
      // Center of "Deutschland" is (240, 742.5)
      final result = hitTester.hitTest(
        pdfPoint: const PdfPoint(240.0, 742.5),
        screenOffset: const Offset(120.0, 60.0),
        spatialIndex: spatialIndex,
      );

      expect(result.status, equals(SelectionStatus.exactMatch));
      expect(result.word, isNotNull);
      expect(result.word!.cleanWord, equals('Deutschland'));
      expect(result.word!.rawText, equals('Deutschland.'));
    });

    test('Tap in whitespace margin returns NULL', () {
      final result = hitTester.hitTest(
        pdfPoint: const PdfPoint(10.0, 10.0),
        screenOffset: const Offset(5.0, 5.0),
        spatialIndex: spatialIndex,
      );

      expect(result.status, equals(SelectionStatus.whitespace));
      expect(result.word, isNull);
    });

    test('Tap in inter-word gap between "Deutsch" and "in" returns NULL (ZERO nearest word)', () {
      // Gap is between right=160.0 and left=170.0 -> point 165.0
      final result = hitTester.hitTest(
        pdfPoint: const PdfPoint(165.0, 742.5),
        screenOffset: const Offset(82.5, 60.0),
        spatialIndex: spatialIndex,
      );

      // Must be null: zero nearest-word fallback
      expect(result.word, isNull);
      expect(result.status, equals(SelectionStatus.interWordGap));
    });

    test('Tap on ambiguous overlapping candidates returns NULL', () {
      final overlappingWords = [
        WordOccurrence(
          rawText: 'RunA',
          cleanWord: 'RunA',
          pageBoundingBox: const PdfRect(100.0, 750.0, 150.0, 730.0),
          pageNumber: 1,
          charIndex: 0,
          charLength: 4,
          charRects: const [],
        ),
        WordOccurrence(
          rawText: 'RunB',
          cleanWord: 'RunB',
          pageBoundingBox: const PdfRect(130.0, 750.0, 180.0, 730.0),
          pageNumber: 1,
          charIndex: 2,
          charLength: 4,
          charRects: const [],
        ),
      ];

      final overlapIndex = WordSpatialIndex(
        pageNumber: 1,
        words: overlappingWords,
      );

      // Point (140, 740) is inside BOTH RunA and RunB
      final result = hitTester.hitTest(
        pdfPoint: const PdfPoint(140.0, 740.0),
        screenOffset: const Offset(70.0, 50.0),
        spatialIndex: overlapIndex,
      );

      expect(result.status, equals(SelectionStatus.ambiguous));
      expect(result.word, isNull);
      expect(result.candidateWords.length, equals(2));
    });
  });
}
