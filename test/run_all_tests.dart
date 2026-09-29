// test/run_all_tests.dart
//
// PRODUCTION AUTOMATED TEST SUITE FOR EXACT WORD SELECTION & GEOMETRY
//
// Validates:
// 1. ProductionExactHitTester Invariants
// 2. GermanWordReconstructor (Umlauts, Eszett, Split Items, Line Hyphenation)
// 3. Bundled German PDF Verification (CharRects, Words, Exact Selection, Zero Nearest-Word Fallback)

import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:tap_to_translate/core/models/selection_result.dart';
import 'package:tap_to_translate/core/models/word_occurrence.dart';
import 'package:tap_to_translate/features/reader/domain/exact_hit_tester.dart';
import 'package:tap_to_translate/features/reader/domain/word_reconstructor.dart';
import 'package:tap_to_translate/features/reader/domain/word_spatial_index.dart';

int total = 0;
int passed = 0;
int failed = 0;
final failures = <String>[];

void assertTest(String name, bool condition, [String? detail]) {
  total++;
  if (condition) {
    passed++;
    print('  [PASS] $name${detail != null ? " ($detail)" : ""}');
  } else {
    failed++;
    final msg = '  [FAIL] $name${detail != null ? ": $detail" : ""}';
    failures.add(msg);
    print(msg);
  }
}

void main() async {
  print('================================================================');
  print('  PRODUCTION TEST RUNNER: EXACT WORD SELECTION & GEOMETRY');
  print('================================================================\n');

  // ─────────────────────────────────────────────────────────────────────────
  // TEST GROUP 1: ProductionExactHitTester Invariants
  // ─────────────────────────────────────────────────────────────────────────
  print('>>> TEST GROUP 1: Exact HitTester Invariants');
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

  // 1.1: Exact hit inside word
  final hitExact = hitTester.hitTest(
    pdfPoint: const PdfPoint(240.0, 742.5),
    screenOffset: const Offset(120.0, 60.0),
    spatialIndex: spatialIndex,
  );
  assertTest(
    'hit_inside_word_exact_match',
    hitExact.status == SelectionStatus.exactMatch && hitExact.word?.cleanWord == 'Deutschland',
    'Center of "Deutschland" resolved to "${hitExact.word?.cleanWord}"',
  );

  // 1.2: Whitespace margin tap -> null
  final hitMargin = hitTester.hitTest(
    pdfPoint: const PdfPoint(10.0, 10.0),
    screenOffset: const Offset(5.0, 5.0),
    spatialIndex: spatialIndex,
  );
  assertTest(
    'hit_whitespace_margin_returns_null',
    hitMargin.status == SelectionStatus.whitespace && hitMargin.word == null,
    'Tap at margin (10, 10) -> NULL',
  );

  // 1.3: Inter-word gap tap -> null (ZERO NEAREST-WORD FALLBACK)
  final hitGap = hitTester.hitTest(
    pdfPoint: const PdfPoint(165.0, 742.5), // strictly between 160 and 170
    screenOffset: const Offset(82.5, 60.0),
    spatialIndex: spatialIndex,
  );
  assertTest(
    'hit_between_adjacent_words_returns_null',
    hitGap.word == null,
    'Tap in gap between "Deutsch" and "in" -> Strictly NULL (no nearest word)',
  );

  // 1.4: Ambiguous overlapping candidates -> null
  final overlapWords = [
    WordOccurrence(
      rawText: 'BoxA',
      cleanWord: 'BoxA',
      pageBoundingBox: const PdfRect(100.0, 750.0, 150.0, 730.0),
      pageNumber: 1,
      charIndex: 0,
      charLength: 4,
      charRects: const [],
    ),
    WordOccurrence(
      rawText: 'BoxB',
      cleanWord: 'BoxB',
      pageBoundingBox: const PdfRect(130.0, 750.0, 180.0, 730.0),
      pageNumber: 1,
      charIndex: 2,
      charLength: 4,
      charRects: const [],
    ),
  ];
  final overlapIndex = WordSpatialIndex(pageNumber: 1, words: overlapWords);
  final hitOverlap = hitTester.hitTest(
    pdfPoint: const PdfPoint(140.0, 740.0),
    screenOffset: const Offset(70.0, 50.0),
    spatialIndex: overlapIndex,
  );
  assertTest(
    'hit_ambiguous_overlapping_candidates_returns_null',
    hitOverlap.status == SelectionStatus.ambiguous && hitOverlap.word == null && hitOverlap.candidateWords.length == 2,
    'Colliding bounding boxes -> strictly NULL (ambiguous)',
  );

  // ─────────────────────────────────────────────────────────────────────────
  // TEST GROUP 2: GermanWordReconstructor Tests
  // ─────────────────────────────────────────────────────────────────────────
  print('\n>>> TEST GROUP 2: German Word Reconstruction');
  const reconstructor = GermanWordReconstructor();

  // 2.1: Quotes and punctuation cleaning
  const samplePhrase = 'Er sagte: „Deutschland“ ist schön!';
  final dummyRects = List.generate(
    samplePhrase.length,
    (i) => PdfRect(i * 10.0, 100.0, (i + 1) * 10.0, 85.0),
  );
  final pText1 = PdfPageText(
    pageNumber: 1,
    fullText: samplePhrase,
    charRects: dummyRects,
    fragments: [],
  );
  final recWords1 = reconstructor.reconstructWords(pText1);
  final wDeutschland = recWords1.firstWhere((w) => w.cleanWord == 'Deutschland');
  assertTest(
    'reconstruct_clean_quoted_word',
    wDeutschland.cleanWord == 'Deutschland' && wDeutschland.rawText.contains('Deutschland'),
    'Raw: "${wDeutschland.rawText}" -> Clean: "${wDeutschland.cleanWord}"',
  );

  final wSchoen = recWords1.firstWhere((w) => w.cleanWord == 'schön');
  assertTest(
    'reconstruct_clean_punctuation_word',
    wSchoen.cleanWord == 'schön' && wSchoen.rawText == 'schön!',
    'Raw: "${wSchoen.rawText}" -> Clean: "${wSchoen.cleanWord}"',
  );

  // 2.2: Split text item fusion (Deutsch + land)
  const splitText = 'Deutsch land';
  final splitRects = [
    const PdfRect(0, 100, 10, 85),
    const PdfRect(10, 100, 20, 85),
    const PdfRect(20, 100, 30, 85),
    const PdfRect(30, 100, 40, 85),
    const PdfRect(40, 100, 50, 85),
    const PdfRect(50, 100, 60, 85),
    const PdfRect(60, 100, 60, 85), // space
    const PdfRect(60.5, 100, 70, 85), // 'l' gap is 0.5 pt (< 1.5 pt threshold)
    const PdfRect(70, 100, 80, 85),
    const PdfRect(80, 100, 90, 85),
    const PdfRect(90, 100, 100, 85),
  ];
  final pText2 = PdfPageText(
    pageNumber: 1,
    fullText: splitText,
    charRects: splitRects,
    fragments: [],
  );
  final recWords2 = reconstructor.reconstructWords(pText2);
  final fusedCandidate = recWords2.where((w) => w.cleanWord == 'Deutschland').toList();
  assertTest(
    'fuse_split_text_items_into_single_word',
    fusedCandidate.isNotEmpty && fusedCandidate.first.cleanWord == 'Deutschland',
    'Merged split items into single continuous bounding box: ${fusedCandidate.first.cleanWord}',
  );

  // 2.3: De-hyphenation across line wrap
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
    const PdfRect(50, 80, 60, 65), // line 2 (drop = 20 pt)
    const PdfRect(60, 80, 70, 65),
    const PdfRect(70, 80, 80, 65),
    const PdfRect(80, 80, 90, 65),
    const PdfRect(90, 80, 100, 65),
    const PdfRect(100, 80, 105, 65),
    const PdfRect(105, 80, 110, 65),
    const PdfRect(110, 80, 120, 65),
  ];
  final pText3 = PdfPageText(
    pageNumber: 1,
    fullText: hyphenPhrase,
    charRects: hyphenRects,
    fragments: [],
  );
  final recWords3 = reconstructor.reconstructWords(pText3);
  final wBundes = recWords3.firstWhere((w) => w.cleanWord == 'Bundes');
  assertTest(
    'dehyphenate_compound_word_across_lines',
    wBundes.dehyphenatedCompound == 'Bundesrepublik' && wBundes.lookupTerm == 'Bundesrepublik',
    'Detected line-break hyphenation -> compound lemma: "${wBundes.lookupTerm}"',
  );

  // ─────────────────────────────────────────────────────────────────────────
  // TEST GROUP 3: Live Bundled PDF Geometry & Selection Verification
  // ─────────────────────────────────────────────────────────────────────────
  print('\n>>> TEST GROUP 3: Bundled German Reference Document Verification');
  final pdfFile = File('assets/test_german_comprehensive.pdf');
  assertTest('bundled_pdf_file_exists', pdfFile.existsSync(), 'assets/test_german_comprehensive.pdf');

  if (pdfFile.existsSync()) {
    final doc = await PdfDocument.openFile(pdfFile.path);
    assertTest('load_pdf_document', doc.pages.isNotEmpty, 'Total pages: ${doc.pages.length}');

    final page1 = doc.pages[0];
    await page1.ensureLoaded();
    assertTest(
      'page_1_dimensions_a4',
      (page1.width - 595.28).abs() < 2.0 && (page1.height - 841.89).abs() < 2.0,
      '${page1.width.toStringAsFixed(1)} x ${page1.height.toStringAsFixed(1)} pt',
    );

    final rawText = await page1.loadStructuredText();
    assertTest(
      'extract_character_vectors',
      rawText != null && rawText.charRects.length == rawText.fullText.length,
      'Glyphs: ${rawText?.charRects.length}',
    );

    if (rawText != null) {
      final liveWords = reconstructor.reconstructWords(rawText);
      final liveSpatialIndex = WordSpatialIndex(pageNumber: 1, words: liveWords);

      // Verify "Deutschland" is present
      final liveDeutschland = liveWords.firstWhere(
        (w) => w.cleanWord == 'Deutschland',
        orElse: () => w1,
      );
      assertTest(
        'live_reconstruct_deutschland',
        liveDeutschland.cleanWord == 'Deutschland',
        'BBox: [${liveDeutschland.pageBoundingBox.left.toStringAsFixed(1)}, ${liveDeutschland.pageBoundingBox.bottom.toStringAsFixed(1)}, ${liveDeutschland.pageBoundingBox.right.toStringAsFixed(1)}, ${liveDeutschland.pageBoundingBox.top.toStringAsFixed(1)}]',
      );

      // Live hit-test at center of "Deutschland"
      final cx = (liveDeutschland.pageBoundingBox.left + liveDeutschland.pageBoundingBox.right) / 2;
      final cy = (liveDeutschland.pageBoundingBox.bottom + liveDeutschland.pageBoundingBox.top) / 2;
      final liveHit = hitTester.hitTest(
        pdfPoint: PdfPoint(cx, cy),
        screenOffset: Offset(cx, cy),
        spatialIndex: liveSpatialIndex,
      );
      assertTest(
        'live_hit_test_deutschland',
        liveHit.status == SelectionStatus.exactMatch && liveHit.word?.cleanWord == 'Deutschland',
        'Exact hit at ($cx, $cy) -> "${liveHit.word?.cleanWord}"',
      );

      // Live hit-test at margin
      final liveMarginHit = hitTester.hitTest(
        pdfPoint: const PdfPoint(5.0, 5.0),
        screenOffset: const Offset(5.0, 5.0),
        spatialIndex: liveSpatialIndex,
      );
      assertTest(
        'live_hit_test_margin_null',
        liveMarginHit.word == null,
        'Tap at (5, 5) -> strictly NULL',
      );

      // Live hit-test in gap between words
      final wLiveDeutsch = liveWords.firstWhere((w) => w.cleanWord == 'Deutsch', orElse: () => liveDeutschland);
      final wLiveIn = liveWords.firstWhere((w) => w.cleanWord == 'in', orElse: () => liveDeutschland);
      if (wLiveDeutsch.cleanWord == 'Deutsch' && wLiveIn.cleanWord == 'in') {
        final gapX = (wLiveDeutsch.pageBoundingBox.right + wLiveIn.pageBoundingBox.left) / 2;
        final gapY = (wLiveDeutsch.pageBoundingBox.bottom + wLiveDeutsch.pageBoundingBox.top) / 2;
        final liveGapHit = hitTester.hitTest(
          pdfPoint: PdfPoint(gapX, gapY),
          screenOffset: Offset(gapX, gapY),
          spatialIndex: liveSpatialIndex,
        );
        assertTest(
          'live_hit_test_inter_word_gap_null',
          liveGapHit.word == null,
          'Gap tap between "${wLiveDeutsch.cleanWord}" and "${wLiveIn.cleanWord}" -> strictly NULL (ZERO nearest word)',
        );
      }
    }
    await doc.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SUMMARY
  // ─────────────────────────────────────────────────────────────────────────
  print('\n================================================================');
  print('  TEST SUITE RESULTS');
  print('================================================================');
  print('  TOTAL:  $total');
  print('  PASSED: $passed');
  print('  FAILED: $failed');
  print('================================================================');

  if (failed > 0) {
    print('\nFAILURE DETAILS:');
    for (final f in failures) {
      print('  $f');
    }
    exit(1);
  } else {
    print('\n✅ ALL PRODUCTION DOMAIN & GEOMETRY TESTS PASSED.');
    exit(0);
  }
}
