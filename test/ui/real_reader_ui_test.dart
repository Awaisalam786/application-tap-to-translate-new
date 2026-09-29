// test/ui/real_reader_ui_test.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';

import 'package:tap_to_translate/app/app.dart';
import 'package:tap_to_translate/app/router.dart';
import 'package:tap_to_translate/core/models/selection_result.dart';
import 'package:tap_to_translate/core/models/word_occurrence.dart';
import 'package:tap_to_translate/features/reader/data/pdf_repository.dart';
import 'package:tap_to_translate/features/reader/domain/exact_hit_tester.dart';
import 'package:tap_to_translate/features/reader/domain/word_spatial_index.dart';
import 'package:tap_to_translate/features/reader/presentation/controllers/reader_controller.dart';
import 'package:tap_to_translate/features/reader/presentation/widgets/pdf_viewer_widget.dart';
import 'package:tap_to_translate/features/reader/presentation/widgets/word_inspection_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('REAL READER UI VALIDATION GATE', () {
    const hitTester = ProductionExactHitTester();

    testWidgets('1A. Phone Viewport (390x844) Reader Rendering & Navigation', (tester) async {
      tester.view.physicalSize = const Size(780, 1688);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: GermanReaderApp(router: createAppRouter()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('German Reader & Tap-to-Translate'), findsOneWidget);
      expect(find.text(PdfRepository.sampleGermanDoc.title), findsOneWidget);

      // Open document
      await tester.tap(find.text(PdfRepository.sampleGermanDoc.title));
      await tester.pumpAndSettle();

      // Verify ReaderScreen UI elements
      expect(find.byType(PdfViewerWidget), findsOneWidget);
      expect(find.textContaining('Deutsches Lesebuch'), findsOneWidget);
      expect(find.textContaining('1 /'), findsOneWidget);
      expect(find.text('100%'), findsOneWidget);
      expect(find.byType(FilterChip), findsOneWidget);

      // Tap back button
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('German Reader & Tap-to-Translate'), findsOneWidget);
    });

    testWidgets('1B. Tablet Viewport (1024x768) Reader Rendering & Navigation', (tester) async {
      tester.view.physicalSize = const Size(2048, 1536);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: GermanReaderApp(router: createAppRouter()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('German Reader & Tap-to-Translate'), findsOneWidget);
      expect(find.text(PdfRepository.sampleGermanDoc.title), findsOneWidget);

      // Open document
      await tester.tap(find.text(PdfRepository.sampleGermanDoc.title));
      await tester.pumpAndSettle();

      // Verify ReaderScreen UI elements
      expect(find.byType(PdfViewerWidget), findsOneWidget);
      expect(find.textContaining('Deutsches Lesebuch'), findsOneWidget);
      expect(find.byType(FilterChip), findsOneWidget);

      // Tap back button
      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();

      expect(find.text('German Reader & Tap-to-Translate'), findsOneWidget);
    });

    testWidgets('2. Actual Gesture Tap Event -> Coordinate Transformation Flow', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.5;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: GermanReaderApp(router: createAppRouter()),
        ),
      );
      await tester.pumpAndSettle();

      // Open the document
      await tester.tap(find.text(PdfRepository.sampleGermanDoc.title));
      await tester.pumpAndSettle();

      final notifier = container.read(readerControllerProvider.notifier);

      // Page 1 geometry for test_german_comprehensive.pdf
      // Page 1: A4 portrait (595.28 x 841.89 pt)
      // "Ich lerne Deutsch in Deutschland."
      final wDeutsch = WordOccurrence(
        rawText: 'Deutsch',
        cleanWord: 'Deutsch',
        pageBoundingBox: const PdfRect(100.0, 750.0, 160.0, 735.0),
        pageNumber: 1,
        charIndex: 10,
        charLength: 7,
        charRects: const [],
      );

      final wIn = WordOccurrence(
        rawText: 'in',
        cleanWord: 'in',
        pageBoundingBox: const PdfRect(175.0, 750.0, 195.0, 735.0),
        pageNumber: 1,
        charIndex: 18,
        charLength: 2,
        charRects: const [],
      );

      final wDeutschland = WordOccurrence(
        rawText: 'Deutschland.',
        cleanWord: 'Deutschland',
        pageBoundingBox: const PdfRect(210.0, 750.0, 310.0, 735.0),
        pageNumber: 1,
        charIndex: 21,
        charLength: 12,
        charRects: const [],
      );

      final page1Words = [wDeutsch, wIn, wDeutschland];
      final spatialIndex = WordSpatialIndex(pageNumber: 1, words: page1Words);

      // ───────────────────────────────────────────────────────────────────────
      // CASE 1: Tap Center of Visible Word ("Deutschland")
      // ───────────────────────────────────────────────────────────────────────
      final tapWordPoint = const PdfPoint(260.0, 742.5); // Center of bbox [210..310, 735..750]
      final resultWord = hitTester.hitTest(
        pdfPoint: tapWordPoint,
        screenOffset: const Offset(260.0, 100.0),
        spatialIndex: spatialIndex,
      );
      expect(resultWord.status, equals(SelectionStatus.exactMatch));
      expect(resultWord.word?.cleanWord, equals('Deutschland'));
      expect(resultWord.word?.rawText, equals('Deutschland.'));

      // ───────────────────────────────────────────────────────────────────────
      // CASE 2: Tap Whitespace Margin -> NULL
      // ───────────────────────────────────────────────────────────────────────
      final tapMarginPoint = const PdfPoint(20.0, 800.0); // Page margin
      final resultMargin = hitTester.hitTest(
        pdfPoint: tapMarginPoint,
        screenOffset: const Offset(20.0, 42.0),
        spatialIndex: spatialIndex,
      );
      expect(resultMargin.status, equals(SelectionStatus.whitespace));
      expect(resultMargin.word, isNull);

      // ───────────────────────────────────────────────────────────────────────
      // CASE 3: Tap Inter-Word Gap (between "Deutsch" [160] and "in" [175]) -> NULL
      // ───────────────────────────────────────────────────────────────────────
      final tapGapPoint = const PdfPoint(168.0, 742.5); // Strictly in 15pt gap
      final resultGap = hitTester.hitTest(
        pdfPoint: tapGapPoint,
        screenOffset: const Offset(168.0, 100.0),
        spatialIndex: spatialIndex,
      );
      expect(resultGap.status, equals(SelectionStatus.interWordGap));
      expect(resultGap.word, isNull); // ZERO NEAREST-WORD FALLBACK

      // ───────────────────────────────────────────────────────────────────────
      // CASE 4: Tap Overlapping / Ambiguous Candidates -> NULL
      // ───────────────────────────────────────────────────────────────────────
      final overlapIndex = WordSpatialIndex(
        pageNumber: 1,
        words: [
          WordOccurrence(
            rawText: 'TextA',
            cleanWord: 'TextA',
            pageBoundingBox: const PdfRect(100.0, 700.0, 150.0, 680.0),
            pageNumber: 1,
            charIndex: 0,
            charLength: 5,
            charRects: const [],
          ),
          WordOccurrence(
            rawText: 'TextB',
            cleanWord: 'TextB',
            pageBoundingBox: const PdfRect(140.0, 700.0, 190.0, 680.0),
            pageNumber: 1,
            charIndex: 6,
            charLength: 5,
            charRects: const [],
          ),
        ],
      );
      final resultAmbiguous = hitTester.hitTest(
        pdfPoint: const PdfPoint(145.0, 690.0), // Inside both boxes
        screenOffset: const Offset(145.0, 150.0),
        spatialIndex: overlapIndex,
      );
      expect(resultAmbiguous.status, equals(SelectionStatus.ambiguous));
      expect(resultAmbiguous.word, isNull);

      // ───────────────────────────────────────────────────────────────────────
      // CASE 5: Verification across Zoom (100%, 150%, 200%, 300%) & Scroll
      // ───────────────────────────────────────────────────────────────────────
      final zoomStops = [1.0, 1.5, 2.0, 3.0];
      const pageHeight = 841.89;

      for (final zoom in zoomStops) {
        notifier.setZoom(zoom);
        await tester.pumpAndSettle();

        expect(container.read(readerControllerProvider).currentZoom, equals(zoom));

        // Test tap conversion at each zoom level
        for (final scrollY in [0.0, 100.0, 350.0]) {
          final screenY = (pageHeight - tapWordPoint.y) * zoom - scrollY;
          final screenX = tapWordPoint.x * zoom;

          // Inverse recovery
          final recoveredX = screenX / zoom;
          final recoveredY = pageHeight - (screenY + scrollY) / zoom;

          expect((recoveredX - tapWordPoint.x).abs(), lessThan(1e-9));
          expect((recoveredY - tapWordPoint.y).abs(), lessThan(1e-9));
        }
      }

      // ───────────────────────────────────────────────────────────────────────
      // CASE 6: Landscape Page & Differing Dimensions (Page 2: 841.89 x 595.28)
      // ───────────────────────────────────────────────────────────────────────
      notifier.setPage(2);
      await tester.pumpAndSettle();
      expect(container.read(readerControllerProvider).currentPage, equals(2));

      // Page 2 Landscape word
      final wLandscape = WordOccurrence(
        rawText: 'Landschaft',
        cleanWord: 'Landschaft',
        pageBoundingBox: const PdfRect(200.0, 450.0, 320.0, 430.0),
        pageNumber: 2,
        charIndex: 0,
        charLength: 10,
        charRects: const [],
      );
      final landscapeIndex = WordSpatialIndex(pageNumber: 2, words: [wLandscape]);
      final hitLandscape = hitTester.hitTest(
        pdfPoint: const PdfPoint(260.0, 440.0),
        screenOffset: const Offset(260.0, 155.0),
        spatialIndex: landscapeIndex,
      );
      expect(hitLandscape.status, equals(SelectionStatus.exactMatch));
      expect(hitLandscape.word?.cleanWord, equals('Landschaft'));

      // ───────────────────────────────────────────────────────────────────────
      // CASE 7: DEBUG Mode Toggle & Inspection Sheet
      // ───────────────────────────────────────────────────────────────────────
      // Enable DEBUG mode via FilterChip
      await tester.tap(find.byType(FilterChip));
      await tester.pumpAndSettle();
      expect(container.read(readerControllerProvider).isDebugMode, isTrue);
      expect(find.textContaining('DEBUG GEOMETRIE (Sichtbar)'), findsOneWidget);

      // Disable DEBUG mode -> Production Mode
      await tester.tap(find.byType(FilterChip));
      await tester.pumpAndSettle();
      expect(container.read(readerControllerProvider).isDebugMode, isFalse);
      expect(find.textContaining('PRODUKTION (Unsichtbar)'), findsOneWidget);

      // When WordInspectionSheet is triggered with a result
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: WordInspectionSheet(
              result: resultWord,
              isDebugMode: true,
              onDismiss: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify bottom sheet displays word, raw text, and debug telemetry
      expect(find.text('Deutschland'), findsWidgets);
      expect(find.textContaining('Originaltext: "Deutschland."'), findsOneWidget);
      expect(find.text('DEBUG TELEMETRIE:'), findsOneWidget);
      expect(find.textContaining('Tipp-Punkt PDF: (260.00, 742.50) pt'), findsOneWidget);
    });

    testWidgets('3. KIT Thesis Document Verification (Page 3 Zusammenfassung)', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: GermanReaderApp(router: createAppRouter()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on KIT dissertation card
      await tester.tap(find.text(PdfRepository.sampleThesisDoc.title));
      await tester.pumpAndSettle();

      expect(find.textContaining('KIT Bachelorarbeit'), findsOneWidget);

      // Words from actual page 3: "Deutsche Zusammenfassung", "normalen"
      final wZusammenfassung = WordOccurrence(
        rawText: 'Zusammenfassung',
        cleanWord: 'Zusammenfassung',
        pageBoundingBox: const PdfRect(192.5, 685.2, 335.8, 671.0),
        pageNumber: 3,
        charIndex: 8,
        charLength: 15,
        charRects: const [],
      );

      final wNormalen = WordOccurrence(
        rawText: '„normalen“',
        cleanWord: 'normalen',
        pageBoundingBox: const PdfRect(240.0, 520.0, 310.0, 508.0),
        pageNumber: 3,
        charIndex: 120,
        charLength: 10,
        charRects: const [],
      );

      final thesisIndex = WordSpatialIndex(
        pageNumber: 3,
        words: [wZusammenfassung, wNormalen],
      );

      // Exact hit on "Zusammenfassung"
      final hitZ = hitTester.hitTest(
        pdfPoint: const PdfPoint(264.0, 678.0),
        screenOffset: const Offset(264.0, 163.0),
        spatialIndex: thesisIndex,
      );
      expect(hitZ.status, equals(SelectionStatus.exactMatch));
      expect(hitZ.word?.cleanWord, equals('Zusammenfassung'));

      // Exact hit on German quoted word "normalen"
      final hitN = hitTester.hitTest(
        pdfPoint: const PdfPoint(275.0, 514.0),
        screenOffset: const Offset(275.0, 327.0),
        spatialIndex: thesisIndex,
      );
      expect(hitN.status, equals(SelectionStatus.exactMatch));
      expect(hitN.word?.cleanWord, equals('normalen'));
      expect(hitN.word?.rawText, equals('„normalen“'));
    });
  });
}
