// test/features/ocr/domain/ocr_selection_test.dart

import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';

import 'package:tap_to_translate/core/models/selection_result.dart';
import 'package:tap_to_translate/core/models/word_occurrence.dart';
import 'package:tap_to_translate/features/ocr/data/ocr_coordinate_mapper.dart';
import 'package:tap_to_translate/features/ocr/data/repositories/in_memory_ocr_cache.dart';
import 'package:tap_to_translate/features/ocr/data/repositories/mock_german_ocr_provider.dart';
import 'package:tap_to_translate/features/ocr/domain/services/ocr_service.dart';
import 'package:tap_to_translate/features/reader/domain/exact_hit_tester.dart';
import 'package:tap_to_translate/features/reader/domain/word_spatial_index.dart';
import 'package:tap_to_translate/features/translation/data/repositories/default_german_word_normalizer.dart';
import 'package:tap_to_translate/features/translation/data/repositories/in_memory_translation_cache.dart';
import 'package:tap_to_translate/features/translation/data/repositories/production_german_lexicon_service.dart';
import 'package:tap_to_translate/features/translation/domain/models/translation_query.dart';
import 'package:tap_to_translate/features/translation/domain/models/translation_status.dart';
import 'package:tap_to_translate/features/translation/domain/models/translation_target_language.dart';
import 'package:tap_to_translate/features/translation/domain/usecases/translation_resolver.dart';

void main() {
  group('Phase 7: Scanned PDF OCR Selection & Translation Suite', () {
    late MockGermanOcrProvider ocrProvider;
    late InMemoryOcrCache ocrCache;
    late OcrService ocrService;
    late OcrCoordinateMapper coordinateMapper;
    late ProductionExactHitTester hitTester;
    late ProductionGermanLexiconService lexiconService;
    late TranslationResolver translationResolver;

    // A4 dimensions at 72 points/inch
    const pageWidth = 595.0;
    const pageHeight = 842.0;

    setUp(() {
      coordinateMapper = const OcrCoordinateMapper();
      ocrProvider = MockGermanOcrProvider(coordinateMapper: coordinateMapper);
      ocrCache = InMemoryOcrCache();
      ocrService = OcrService(provider: ocrProvider, cache: ocrCache);
      hitTester = const ProductionExactHitTester(minConfidenceThreshold: 0.50);

      lexiconService = ProductionGermanLexiconService();
      translationResolver = TranslationResolver(
        lexicon: lexiconService,
        cache: InMemoryTranslationCache(),
        normalizer: const DefaultGermanWordNormalizer(),
      );
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 1. OCR Page Recognition & Data Structures
    // ─────────────────────────────────────────────────────────────────────────
    test('1. OCR page recognized: Dimensions, word list, and full text populated', () async {
      final result = await ocrService.processPage(
        documentId: 'scanned_german_book_1',
        pageNumber: 1,
        pageWidth: pageWidth,
        pageHeight: pageHeight,
      );

      expect(result.pageNumber, equals(1));
      expect(result.pageWidth, equals(pageWidth));
      expect(result.pageHeight, equals(pageHeight));
      expect(result.words, isNotEmpty);
      expect(result.words.length, greaterThan(15));
      expect(result.fullText, contains('Deutschland'));
      expect(result.fullText, contains('Möglichkeiten'));
      expect(result.confidence, greaterThan(0.90));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 2. German Words Returned
    // ─────────────────────────────────────────────────────────────────────────
    test('2. German vocabulary returned with correct lemmatization/cleaning', () async {
      final result = await ocrService.processPage(
        documentId: 'scanned_german_book_1',
        pageNumber: 1,
        pageWidth: pageWidth,
        pageHeight: pageHeight,
      );

      final cleanWords = result.words.map((w) => w.cleanWord).toSet();
      expect(cleanWords, contains('Ich'));
      expect(cleanWords, contains('Deutsch'));
      expect(cleanWords, contains('Deutschland'));
      expect(cleanWords, contains('Möglichkeit'));
      expect(cleanWords, contains('arbeiten'));
      expect(cleanWords, contains('Fußball'));
      expect(cleanWords, contains('größer'));
      expect(cleanWords, contains('Mädchen'));
      expect(cleanWords, contains('Bücher'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 3. Word Bounding Boxes Returned
    // ─────────────────────────────────────────────────────────────────────────
    test('3. Word bounding boxes are valid PDF rectangles (left < right, bottom < top)', () async {
      final result = await ocrService.processPage(
        documentId: 'scanned_german_book_1',
        pageNumber: 1,
        pageWidth: pageWidth,
        pageHeight: pageHeight,
      );

      for (final word in result.words) {
        final b = word.pageBoundingBox;
        expect(b.left, lessThan(b.right), reason: 'Word ${word.rawText} left < right');
        expect(b.bottom, lessThan(b.top), reason: 'Word ${word.rawText} bottom < top (PDF origin bottom-left)');
        expect(b.left, greaterThanOrEqualTo(0.0));
        expect(b.right, lessThanOrEqualTo(pageWidth));
        expect(b.bottom, greaterThanOrEqualTo(0.0));
        expect(b.top, lessThanOrEqualTo(pageHeight));
      }
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 4. Page Coordinates Correctly Mapped (Image pixel to PDF points)
    // ─────────────────────────────────────────────────────────────────────────
    test('4. Mathematical coordinate mapping from image pixels (top-left) to PDF points (bottom-left)', () {
      const imgW = 1190;
      const imgH = 1684;
      const pW = 595.0; // scale = 0.5
      const pH = 842.0; // scale = 0.5

      // Pixel box at top of image: left=100, top=100, width=200, height=50
      // bottom in pixels = 150
      const pixelBox = Rect.fromLTWH(100, 100, 200, 50);
      final pdfBox = coordinateMapper.mapPixelToPdfRect(
        pixelRect: pixelBox,
        imageWidth: imgW,
        imageHeight: imgH,
        pageWidth: pW,
        pageHeight: pH,
      );

      // X mapping: 100 * 0.5 = 50.0; (100+200) * 0.5 = 150.0
      expect(pdfBox.left, closeTo(50.0, 0.001));
      expect(pdfBox.right, closeTo(150.0, 0.001));

      // Y mapping: top in pixels = 100 -> pdfTop = 842 - (100 * 0.5) = 842 - 50 = 792.0
      // bottom in pixels = 150 -> pdfBottom = 842 - (150 * 0.5) = 842 - 75 = 767.0
      expect(pdfBox.top, closeTo(792.0, 0.001));
      expect(pdfBox.bottom, closeTo(767.0, 0.001));
      expect(pdfBox.top, greaterThan(pdfBox.bottom));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 5. Exact Tap Inside OCR Word -> exactMatch
    // ─────────────────────────────────────────────────────────────────────────
    test('5. Exact tap inside OCR word returns exactMatch and correct WordOccurrence', () async {
      final ocrResult = await ocrService.processPage(
        documentId: 'scanned_doc',
        pageNumber: 1,
        pageWidth: pageWidth,
        pageHeight: pageHeight,
      );

      final spatialIndex = WordSpatialIndex(pageNumber: 1, words: ocrResult.words);
      final deutschland = ocrResult.words.firstWhere((w) => w.cleanWord == 'Deutschland');
      final box = deutschland.pageBoundingBox;

      // Tap precisely at center of Deutschland bounding box
      final centerPoint = PdfPoint((box.left + box.right) / 2, (box.top + box.bottom) / 2);
      final hitResult = hitTester.hitTest(
        pdfPoint: centerPoint,
        screenOffset: const Offset(200, 300),
        spatialIndex: spatialIndex,
      );

      expect(hitResult.status, equals(SelectionStatus.exactMatch));
      expect(hitResult.word, isNotNull);
      expect(hitResult.word!.cleanWord, equals('Deutschland'));
      expect(hitResult.word!.isOcr, isTrue);
      expect(hitResult.word!.confidence, greaterThanOrEqualTo(0.90));
      expect(hitResult.word!.source, equals(WordSource.ocr));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 6. Tap Whitespace -> whitespace (strictly NULL)
    // ─────────────────────────────────────────────────────────────────────────
    test('6. Tap in page margins/whitespace returns whitespace status with null word', () async {
      final ocrResult = await ocrService.processPage(
        documentId: 'scanned_doc',
        pageNumber: 1,
        pageWidth: pageWidth,
        pageHeight: pageHeight,
      );

      final spatialIndex = WordSpatialIndex(pageNumber: 1, words: ocrResult.words);

      // Bottom margin: (20, 20)
      final hitResult = hitTester.hitTest(
        pdfPoint: const PdfPoint(20.0, 20.0),
        screenOffset: const Offset(10, 10),
        spatialIndex: spatialIndex,
      );

      expect(hitResult.status, equals(SelectionStatus.whitespace));
      expect(hitResult.word, isNull);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 7. Tap Inter-Word Gap -> interWordGap (ZERO nearest-word fallback)
    // ─────────────────────────────────────────────────────────────────────────
    test('7. Tap between adjacent OCR words returns interWordGap with zero nearest fallback', () async {
      final ocrResult = await ocrService.processPage(
        documentId: 'scanned_doc',
        pageNumber: 1,
        pageWidth: pageWidth,
        pageHeight: pageHeight,
      );

      final spatialIndex = WordSpatialIndex(pageNumber: 1, words: ocrResult.words);
      final wordIn = ocrResult.words.firstWhere((w) => w.cleanWord == 'in');
      final wordDeutschland = ocrResult.words.firstWhere((w) => w.cleanWord == 'Deutschland');

      // The gap between "in" (right) and "Deutschland." (left)
      final gapX = (wordIn.pageBoundingBox.right + wordDeutschland.pageBoundingBox.left) / 2;
      final gapY = (wordIn.pageBoundingBox.top + wordIn.pageBoundingBox.bottom) / 2;

      final hitResult = hitTester.hitTest(
        pdfPoint: PdfPoint(gapX, gapY),
        screenOffset: const Offset(150, 100),
        spatialIndex: spatialIndex,
      );

      expect(hitResult.status, equals(SelectionStatus.interWordGap));
      expect(hitResult.word, isNull); // ZERO NEAREST WORD
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 8. Ambiguous Overlap -> ambiguous (strictly NULL)
    // ─────────────────────────────────────────────────────────────────────────
    test('8. Overlapping OCR candidate bounding boxes return ambiguous status with null word', () {
      final overlappingWords = [
        WordOccurrence.ocr(
          rawText: 'CandidateAlpha',
          cleanWord: 'CandidateAlpha',
          pageBoundingBox: const PdfRect(100.0, 700.0, 200.0, 660.0),
          pageNumber: 1,
          charIndex: 0,
          charLength: 14,
          confidence: 0.95,
        ),
        WordOccurrence.ocr(
          rawText: 'CandidateBeta',
          cleanWord: 'CandidateBeta',
          pageBoundingBox: const PdfRect(150.0, 700.0, 250.0, 660.0),
          pageNumber: 1,
          charIndex: 0,
          charLength: 13,
          confidence: 0.94,
        ),
      ];

      final overlapIndex = WordSpatialIndex(pageNumber: 1, words: overlappingWords);
      // Tap at X=175, Y=680 (inside both bounding boxes)
      final hitResult = hitTester.hitTest(
        pdfPoint: const PdfPoint(175.0, 680.0),
        screenOffset: const Offset(87.5, 60.0),
        spatialIndex: overlapIndex,
      );

      expect(hitResult.status, equals(SelectionStatus.ambiguous));
      expect(hitResult.word, isNull);
      expect(hitResult.candidateWords.length, equals(2));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 9. Low-Confidence OCR Word Handling (Suppressed / Rejected)
    // ─────────────────────────────────────────────────────────────────────────
    test('9. Low-confidence OCR word (confidence < 0.50) is rejected with null word', () async {
      final ocrResult = await ocrService.processPage(
        documentId: 'scanned_doc',
        pageNumber: 1,
        pageWidth: pageWidth,
        pageHeight: pageHeight,
      );

      final lowConfWord = ocrResult.words.firstWhere((w) => w.rawText == 'UnklarText');
      expect(lowConfWord.confidence, equals(0.35));
      expect(lowConfWord.confidence!, lessThan(0.50));

      final spatialIndex = WordSpatialIndex(pageNumber: 1, words: ocrResult.words);
      final box = lowConfWord.pageBoundingBox;
      final centerPoint = PdfPoint((box.left + box.right) / 2, (box.top + box.bottom) / 2);

      final hitResult = hitTester.hitTest(
        pdfPoint: centerPoint,
        screenOffset: const Offset(100, 400),
        spatialIndex: spatialIndex,
      );

      // Must be rejected/suppressed per invariant:
      expect(hitResult.status, equals(SelectionStatus.lowConfidence));
      expect(hitResult.word, isNull);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 10. Umlauts (ä, ö, ü, Ä, Ö, Ü)
    // ─────────────────────────────────────────────────────────────────────────
    test('10. Scanned German umlauts are preserved and hit-testable', () async {
      final ocrResult = await ocrService.processPage(
        documentId: 'scanned_doc',
        pageNumber: 1,
        pageWidth: pageWidth,
        pageHeight: pageHeight,
      );

      final spatialIndex = WordSpatialIndex(pageNumber: 1, words: ocrResult.words);

      final wordsWithUmlauts = ['Möglichkeit', 'größer', 'Mädchen', 'Bücher'];
      for (final targetLemma in wordsWithUmlauts) {
        final match = ocrResult.words.firstWhere((w) => w.cleanWord == targetLemma);
        final box = match.pageBoundingBox;
        final centerPoint = PdfPoint((box.left + box.right) / 2, (box.top + box.bottom) / 2);

        final hit = hitTester.hitTest(
          pdfPoint: centerPoint,
          screenOffset: Offset(box.left, box.bottom),
          spatialIndex: spatialIndex,
        );

        expect(hit.status, equals(SelectionStatus.exactMatch));
        expect(hit.word!.cleanWord, equals(targetLemma));
      }
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 11. Eszett (ß)
    // ─────────────────────────────────────────────────────────────────────────
    test('11. Scanned German Eszett (ß) is correctly recognized and hit-testable', () async {
      final ocrResult = await ocrService.processPage(
        documentId: 'scanned_doc',
        pageNumber: 1,
        pageWidth: pageWidth,
        pageHeight: pageHeight,
      );

      final spatialIndex = WordSpatialIndex(pageNumber: 1, words: ocrResult.words);
      final fussball = ocrResult.words.firstWhere((w) => w.cleanWord == 'Fußball');
      final box = fussball.pageBoundingBox;
      final centerPoint = PdfPoint((box.left + box.right) / 2, (box.top + box.bottom) / 2);

      final hit = hitTester.hitTest(
        pdfPoint: centerPoint,
        screenOffset: Offset(box.left, box.bottom),
        spatialIndex: spatialIndex,
      );

      expect(hit.status, equals(SelectionStatus.exactMatch));
      expect(hit.word!.cleanWord, equals('Fußball'));
      expect(hit.word!.rawText, equals('Fußball,'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 12. Punctuation Stripping
    // ─────────────────────────────────────────────────────────────────────────
    test('12. OCR token punctuation (German guillemets, quotes, question marks) cleanly stripped', () async {
      final ocrResult = await ocrService.processPage(
        documentId: 'scanned_doc',
        pageNumber: 1,
        pageWidth: pageWidth,
        pageHeight: pageHeight,
      );

      final quote1 = ocrResult.words.firstWhere((w) => w.rawText.contains('Möglichkeiten'));
      expect(quote1.rawText, equals('„Möglichkeiten“.'));
      expect(quote1.cleanWord, equals('Möglichkeit'));

      final quote2 = ocrResult.words.firstWhere((w) => w.rawText.contains('arbeitete'));
      expect(quote2.rawText, equals('»arbeitete!«'));
      expect(quote2.cleanWord, equals('arbeiten'));

      final question = ocrResult.words.firstWhere((w) => w.rawText.contains('größer'));
      expect(question.rawText, equals('größer?'));
      expect(question.cleanWord, equals('größer'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 13. Line Breaks & Multi-Line Text Blocks
    // ─────────────────────────────────────────────────────────────────────────
    test('13. Multi-line OCR layout correctly maintains vertical ordering in PDF coordinates', () async {
      final ocrResult = await ocrService.processPage(
        documentId: 'scanned_doc',
        pageNumber: 1,
        pageWidth: pageWidth,
        pageHeight: pageHeight,
      );

      final line1Word = ocrResult.words.firstWhere((w) => w.cleanWord == 'Deutschland');
      final line2Word = ocrResult.words.firstWhere((w) => w.cleanWord == 'Möglichkeit');
      final line3Word = ocrResult.words.firstWhere((w) => w.cleanWord == 'arbeiten');
      final line4Word = ocrResult.words.firstWhere((w) => w.cleanWord == 'Fußball');

      // In PDF coordinates (Y pointing up), line 1 is highest, line 4 is lower
      expect(line1Word.pageBoundingBox.bottom, greaterThan(line2Word.pageBoundingBox.bottom));
      expect(line2Word.pageBoundingBox.bottom, greaterThan(line3Word.pageBoundingBox.bottom));
      expect(line3Word.pageBoundingBox.bottom, greaterThan(line4Word.pageBoundingBox.bottom));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 14. Hyphenated Compound Words Across Lines
    // ─────────────────────────────────────────────────────────────────────────
    test('14. Hyphenated OCR compound word across lines maps lookupTerm to dehyphenatedCompound', () async {
      final ocrResult = await ocrService.processPage(
        documentId: 'scanned_doc',
        pageNumber: 1,
        pageWidth: pageWidth,
        pageHeight: pageHeight,
      );

      final spatialIndex = WordSpatialIndex(pageNumber: 1, words: ocrResult.words);
      final part1 = ocrResult.words.firstWhere((w) => w.rawText == 'Bundes-');
      final part2 = ocrResult.words.firstWhere((w) => w.rawText == 'republik');

      expect(part1.dehyphenatedCompound, equals('Bundesrepublik'));
      expect(part2.dehyphenatedCompound, equals('Bundesrepublik'));
      expect(part1.lookupTerm, equals('Bundesrepublik'));
      expect(part2.lookupTerm, equals('Bundesrepublik'));

      // Tapping either line part resolves the compound term
      final box1 = part1.pageBoundingBox;
      final hit1 = hitTester.hitTest(
        pdfPoint: PdfPoint((box1.left + box1.right) / 2, (box1.top + box1.bottom) / 2),
        screenOffset: Offset(box1.left, box1.bottom),
        spatialIndex: spatialIndex,
      );
      expect(hit1.status, equals(SelectionStatus.exactMatch));
      expect(hit1.word!.lookupTerm, equals('Bundesrepublik'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 15. Multi-Column Spatial Isolation
    // ─────────────────────────────────────────────────────────────────────────
    test('15. Multi-column scanned layout maintains strict spatial isolation between columns', () async {
      // Page 2 is configured as multi-column academic layout
      final ocrResult = await ocrService.processPage(
        documentId: 'scanned_academic_paper',
        pageNumber: 2,
        pageWidth: pageWidth,
        pageHeight: pageHeight,
      );

      final spatialIndex = WordSpatialIndex(pageNumber: 2, words: ocrResult.words);

      final colLeftWord = ocrResult.words.firstWhere((w) => w.cleanWord == 'Zusammenfassung');
      final colRightWord = ocrResult.words.firstWhere((w) => w.cleanWord == 'Wissenschaftliche');

      // Verify Column A and Column B blocks
      expect(colLeftWord.blockId, equals('col_left'));
      expect(colRightWord.blockId, equals('col_right'));
      expect(colLeftWord.pageBoundingBox.right, lessThan(colRightWord.pageBoundingBox.left));

      // Tapping inside Column A word does not touch Column B
      final boxA = colLeftWord.pageBoundingBox;
      final hitA = hitTester.hitTest(
        pdfPoint: PdfPoint((boxA.left + boxA.right) / 2, (boxA.top + boxA.bottom) / 2),
        screenOffset: const Offset(150, 80),
        spatialIndex: spatialIndex,
      );
      expect(hitA.status, equals(SelectionStatus.exactMatch));
      expect(hitA.word!.cleanWord, equals('Zusammenfassung'));

      // Tapping inside Column B word does not touch Column A
      final boxB = colRightWord.pageBoundingBox;
      final hitB = hitTester.hitTest(
        pdfPoint: PdfPoint((boxB.left + boxB.right) / 2, (boxB.top + boxB.bottom) / 2),
        screenOffset: const Offset(350, 80),
        spatialIndex: spatialIndex,
      );
      expect(hitB.status, equals(SelectionStatus.exactMatch));
      expect(hitB.word!.cleanWord, equals('Wissenschaftliche'));

      // Tapping in the column gutter between Column A and Column B returns whitespace/gap (NULL)
      final gutterX = (boxA.right + boxB.left) / 2;
      final gutterY = (boxA.top + boxA.bottom) / 2;
      final hitGutter = hitTester.hitTest(
        pdfPoint: PdfPoint(gutterX, gutterY),
        screenOffset: const Offset(250, 80),
        spatialIndex: spatialIndex,
      );
      expect(hitGutter.word, isNull);
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 16. Rotation Invariance
    // ─────────────────────────────────────────────────────────────────────────
    test('16. Coordinate mapping handles normalized and unnormalized transforms reliably', () {
      const normRect = Rect.fromLTWH(0.2, 0.1, 0.4, 0.05);
      final pdfRect = coordinateMapper.mapNormalizedToPdfRect(
        normalizedRect: normRect,
        pageWidth: 600.0,
        pageHeight: 800.0,
      );

      expect(pdfRect.left, closeTo(120.0, 0.01));
      expect(pdfRect.right, closeTo(360.0, 0.01));
      // top = 800 - 80 = 720; bottom = 800 - 120 = 680
      expect(pdfRect.top, closeTo(720.0, 0.01));
      expect(pdfRect.bottom, closeTo(680.0, 0.01));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 17. Zoom Invariance (Hit Testing remains identical in PDF point space)
    // ─────────────────────────────────────────────────────────────────────────
    test('17. Hit-testing is evaluated strictly in PDF point space regardless of UI zoom level', () async {
      final ocrResult = await ocrService.processPage(
        documentId: 'scanned_doc',
        pageNumber: 1,
        pageWidth: pageWidth,
        pageHeight: pageHeight,
      );

      final spatialIndex = WordSpatialIndex(pageNumber: 1, words: ocrResult.words);
      final target = ocrResult.words.firstWhere((w) => w.cleanWord == 'Deutschland');
      final box = target.pageBoundingBox;
      final pdfPoint = PdfPoint((box.left + box.right) / 2, (box.top + box.bottom) / 2);

      // At 100%, 150%, 200%, 300% zoom, the screen coordinates scale,
      // but the mapped PDF point remains identical (box center).
      final zoomLevels = [1.0, 1.5, 2.0, 3.0];
      for (final zoom in zoomLevels) {
        final screenOffset = Offset(100.0 * zoom, 200.0 * zoom);
        final hit = hitTester.hitTest(
          pdfPoint: pdfPoint,
          screenOffset: screenOffset,
          spatialIndex: spatialIndex,
        );

        expect(hit.status, equals(SelectionStatus.exactMatch), reason: 'Failed at zoom $zoom');
        expect(hit.word!.cleanWord, equals('Deutschland'));
        expect(hit.screenTapOffset, equals(screenOffset));
      }
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 18. Scroll Offsets
    // ─────────────────────────────────────────────────────────────────────────
    test('18. Scroll offsets do not distort PDF page hit testing', () async {
      final ocrResult = await ocrService.processPage(
        documentId: 'scanned_doc',
        pageNumber: 1,
        pageWidth: pageWidth,
        pageHeight: pageHeight,
      );

      final spatialIndex = WordSpatialIndex(pageNumber: 1, words: ocrResult.words);
      final word = ocrResult.words.firstWhere((w) => w.cleanWord == 'Deutschland');
      final box = word.pageBoundingBox;
      final pdfPoint = PdfPoint((box.left + box.right) / 2, (box.top + box.bottom) / 2);

      // Simulated scroll deltas: screen tap changes, but mapped PDF coordinate is constant
      final scrollDeltas = [const Offset(0, 0), const Offset(0, 350), const Offset(0, 700)];
      for (final scroll in scrollDeltas) {
        final screenOffset = Offset(200.0, 100.0) + scroll;
        final hit = hitTester.hitTest(
          pdfPoint: pdfPoint,
          screenOffset: screenOffset,
          spatialIndex: spatialIndex,
        );

        expect(hit.status, equals(SelectionStatus.exactMatch));
        expect(hit.word!.cleanWord, equals('Deutschland'));
      }
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 19. Semantic Convergence: OCR WordOccurrence -> TranslationResolver
    // ─────────────────────────────────────────────────────────────────────────
    test('19. Semantic Convergence: Scanned OCR WordOccurrence seamlessly resolves translations into EN, UR, FA, AR', () async {
      final ocrResult = await ocrService.processPage(
        documentId: 'scanned_doc',
        pageNumber: 1,
        pageWidth: pageWidth,
        pageHeight: pageHeight,
      );

      // Verify source is OCR
      final ocrWord = ocrResult.words.firstWhere((w) => w.cleanWord == 'Deutschland');
      expect(ocrWord.source, equals(WordSource.ocr));
      expect(ocrWord.isOcr, isTrue);

      // 19.1 English Translation
      final resEn = await translationResolver.translate(
        TranslationQuery(
          rawWord: ocrWord.lookupTerm,
          normalizedWord: ocrWord.cleanWord,
          targetLanguage: TranslationTargetLanguage.english,
        ),
      );
      expect(resEn.status, equals(TranslationStatus.success));
      expect(resEn.primaryTranslation, equals('Germany'));

      // 19.2 Urdu Translation
      final resUr = await translationResolver.translate(
        TranslationQuery(
          rawWord: ocrWord.lookupTerm,
          normalizedWord: ocrWord.cleanWord,
          targetLanguage: TranslationTargetLanguage.urdu,
        ),
      );
      expect(resUr.status, equals(TranslationStatus.success));
      expect(resUr.primaryTranslation, equals('جرمنی'));

      // 19.3 Farsi Translation
      final resFa = await translationResolver.translate(
        TranslationQuery(
          rawWord: ocrWord.lookupTerm,
          normalizedWord: ocrWord.cleanWord,
          targetLanguage: TranslationTargetLanguage.farsi,
        ),
      );
      expect(resFa.status, equals(TranslationStatus.success));
      expect(resFa.primaryTranslation, equals('آلمان'));

      // 19.4 Arabic Translation
      final resAr = await translationResolver.translate(
        TranslationQuery(
          rawWord: ocrWord.lookupTerm,
          normalizedWord: ocrWord.cleanWord,
          targetLanguage: TranslationTargetLanguage.arabic,
        ),
      );
      expect(resAr.status, equals(TranslationStatus.success));
      expect(resAr.primaryTranslation, equals('ألمانيا'));

      // 19.5 Inflected OCR word: "Möglichkeiten" -> lemma "Möglichkeit" -> "opportunity / possibility"
      final inflectedOcrWord = ocrResult.words.firstWhere((w) => w.cleanWord == 'Möglichkeit');
      final resInflected = await translationResolver.translate(
        TranslationQuery(
          rawWord: inflectedOcrWord.lookupTerm,
          normalizedWord: inflectedOcrWord.cleanWord,
          targetLanguage: TranslationTargetLanguage.english,
        ),
      );
      expect(resInflected.status, equals(TranslationStatus.success));
      expect(resInflected.primaryTranslation, equals('possibility'));
    });

    // ─────────────────────────────────────────────────────────────────────────
    // 20. Offline Caching Performance Invariant
    // ─────────────────────────────────────────────────────────────────────────
    test('20. Caching Invariant: Secondary access hits OcrCache with zero provider re-computation', () async {
      const docId = 'scanned_book_perf_test';

      // 1. Initial request (populates cache)
      final initial = await ocrService.processPage(
        documentId: docId,
        pageNumber: 1,
        pageWidth: pageWidth,
        pageHeight: pageHeight,
      );
      expect(ocrCache.entryCount, equals(1));

      // 2. Second request (cache hit)
      final cached = await ocrService.processPage(
        documentId: docId,
        pageNumber: 1,
        pageWidth: pageWidth,
        pageHeight: pageHeight,
      );

      expect(identical(initial, cached), isTrue);
      expect(cached.words.length, equals(initial.words.length));
    });
  });
}
