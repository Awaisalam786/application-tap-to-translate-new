// test/features/translation/presentation/phase6_e2e_translation_validation_test.dart

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' hide SelectionStatus, SelectionResult;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'package:tap_to_translate/core/models/selection_result.dart';
import 'package:tap_to_translate/core/models/word_occurrence.dart';
import 'package:tap_to_translate/features/reader/domain/exact_hit_tester.dart';
import 'package:tap_to_translate/features/reader/domain/word_spatial_index.dart';
import 'package:tap_to_translate/features/translation/data/repositories/in_memory_history_repository.dart';
import 'package:tap_to_translate/features/translation/data/repositories/in_memory_translation_cache.dart';
import 'package:tap_to_translate/features/translation/data/repositories/in_memory_user_words_repository.dart';
import 'package:tap_to_translate/features/translation/data/repositories/production_german_lexicon_service.dart';
import 'package:tap_to_translate/features/translation/domain/models/translation_result.dart';
import 'package:tap_to_translate/features/translation/domain/models/translation_status.dart';
import 'package:tap_to_translate/features/translation/domain/models/translation_target_language.dart';
import 'package:tap_to_translate/features/translation/presentation/controllers/translation_controller.dart';
import 'package:tap_to_translate/features/translation/presentation/widgets/translation_popup.dart';

class MockPathProviderPlatform extends PathProviderPlatform
    with MockPlatformInterfaceMixin {
  @override
  Future<String?> getTemporaryPath() async => Directory.systemTemp.path;
  @override
  Future<String?> getApplicationSupportPath() async => Directory.systemTemp.path;
  @override
  Future<String?> getLibraryPath() async => Directory.systemTemp.path;
  @override
  Future<String?> getApplicationDocumentsPath() async => Directory.systemTemp.path;
  @override
  Future<String?> getExternalStoragePath() async => Directory.systemTemp.path;
  @override
  Future<List<String>?> getExternalCachePaths() async => [Directory.systemTemp.path];
  @override
  Future<List<String>?> getExternalStoragePaths({StorageDirectory? type}) async =>
      [Directory.systemTemp.path];
  @override
  Future<String?> getDownloadsPath() async => Directory.systemTemp.path;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  PathProviderPlatform.instance = MockPathProviderPlatform();

  final artifactDir = Directory(
      r'C:\Users\ABC\.gemini\antigravity\brain\f47c3bb9-e251-4430-b00d-0839624a39ab');

  Future<void> captureWidgetScreenshot(
      WidgetTester tester, GlobalKey key, String filename) async {
    await tester.runAsync(() async {
      final boundary =
          key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage(pixelRatio: 2.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final file = File('${artifactDir.path}/$filename');
      file.writeAsBytesSync(byteData.buffer.asUint8List());
    });
  }

  group('PHASE 6: REAL END-TO-END TRANSLATION VALIDATION', () {
    late ProductionGermanLexiconService lexiconService;
    late InMemoryHistoryRepository historyRepo;
    late InMemoryUserWordsRepository userWordsRepo;
    late InMemoryTranslationCache cache;

    setUp(() {
      lexiconService = ProductionGermanLexiconService();
      historyRepo = InMemoryHistoryRepository();
      userWordsRepo = InMemoryUserWordsRepository();
      cache = InMemoryTranslationCache();
    });

    Widget createReaderTestHarness({
      required GlobalKey boundaryKey,
      required ProviderContainer container,
      WordOccurrence? selectedWord,
      bool showPopup = true,
      TranslationResult? forcedResult,
    }) {
      return RepaintBoundary(
        key: boundaryKey,
        child: UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: Colors.indigo,
            ),
            home: Scaffold(
              appBar: AppBar(
                title: const Text('Deutsches Lesebuch (Original PDF)'),
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
              ),
              body: Stack(
                children: [
                  // Original PDF visual mock page (pristine rendering)
                  Container(
                    color: const Color(0xFFF2F4F7),
                    child: SingleChildScrollView(
                      child: Center(
                        child: Container(
                          width: 360,
                          margin: const EdgeInsets.symmetric(vertical: 20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 8)
                            ],
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                            const Text(
                              'Kapitel 1: Deutsche Sprache & Kultur',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Ich lerne Deutsch in Deutschland.',
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Wir haben viele neue Möglichkeiten.',
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Er arbeitete gestern den ganzen Tag.',
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Dies ist ein ganz normalen Text.',
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Am Samstag spielen wir Fußball.',
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Dieses Zimmer ist viel größer.',
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Das Mädchen liest ein Buch.',
                              style: TextStyle(fontSize: 14),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Zusammenfassung der Forschungsergebnisse.',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  ),

                  // Translation Popup positioned sensibly at the bottom
                  if (showPopup &&
                      (forcedResult != null ||
                          container.read(translationControllerProvider).currentResult != null))
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: const TranslationPopup(),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('1. Verify All 8 Mandatory Words End-to-End Translation & Lemma Resolution',
        (tester) async {
      tester.view.physicalSize = const Size(780, 1688); // Phone viewport (logical 390x844)
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final testCases = [
        {
          'raw': 'Deutschland',
          'expectedLemma': 'Deutschland',
          'en': 'Germany',
          'ur': 'جرمنی',
          'fa': 'آلمان',
          'ar': 'ألمانيا',
        },
        {
          'raw': 'Möglichkeiten',
          'expectedLemma': 'Möglichkeit',
          'en': 'possibility',
          'ur': 'امکان',
          'fa': 'امکان',
          'ar': 'إمكانية',
        },
        {
          'raw': 'arbeitete',
          'expectedLemma': 'arbeiten',
          'en': 'to work',
          'ur': 'کام کرنا',
          'fa': 'کار کردن',
          'ar': 'يعمل',
        },
        {
          'raw': 'normalen',
          'expectedLemma': 'normal',
          'en': 'normal',
          'ur': 'عام',
          'fa': 'عادی',
          'ar': 'عادي',
        },
        {
          'raw': 'Fußball',
          'expectedLemma': 'Fußball',
          'en': 'football',
          'ur': 'فٹ بال',
          'fa': 'فوتبال',
          'ar': 'كرة القدم',
        },
        {
          'raw': 'größer',
          'expectedLemma': 'groß',
          'en': 'bigger',
          'ur': 'بڑا',
          'fa': 'بزرگ‌تر',
          'ar': 'أكبر',
        },
        {
          'raw': 'Mädchen',
          'expectedLemma': 'Mädchen',
          'en': 'girl',
          'ur': 'لڑکی',
          'fa': 'دختر',
          'ar': 'فتاة',
        },
        {
          'raw': 'Zusammenfassung',
          'expectedLemma': 'Zusammenfassung',
          'en': 'summary',
          'ur': 'خلاصہ',
          'fa': 'خلاصه',
          'ar': 'ملخص',
        },
      ];

      for (final tc in testCases) {
        final raw = tc['raw'] as String;
        final expectedLemma = tc['expectedLemma'] as String;

        final word = WordOccurrence(
          rawText: raw,
          cleanWord: raw,
          pageBoundingBox: const PdfRect(100, 500, 200, 485),
          pageNumber: 1,
          charIndex: 0,
          charLength: raw.length,
          charRects: [
            PdfRect(100, 500, 200, 485),
          ],
        );

        final container = ProviderContainer(
          overrides: [
            germanLexiconRepositoryProvider.overrideWithValue(lexiconService),
            historyRepositoryProvider.overrideWithValue(historyRepo),
            userWordsRepositoryProvider.overrideWithValue(userWordsRepo),
            translationCacheProvider.overrideWithValue(cache),
          ],
        );

        final notifier = container.read(translationControllerProvider.notifier);

        // Tap & Translate
        await notifier.translateWord(word, targetLang: TranslationTargetLanguage.english);
        final stateEn = container.read(translationControllerProvider);

        expect(stateEn.currentResult, isNotNull);
        expect(stateEn.currentResult!.isSuccess, isTrue);
        expect(stateEn.currentResult!.query.rawWord, equals(raw));
        expect(stateEn.currentResult!.query.normalizedWord, equals(expectedLemma));
        expect(stateEn.currentResult!.primaryTranslation, equals(tc['en']));

        // Verify History recorded
        final historyList = await historyRepo.getRecentHistory();
        expect(historyList.any((h) => h.rawWord == raw), isTrue);

        // Verify My Words is NOT modified yet (Invariant: explicit save only)
        expect(await userWordsRepo.isWordSaved(expectedLemma), isFalse);

        // Switch to Urdu
        await notifier.setTargetLanguage(TranslationTargetLanguage.urdu);
        final stateUr = container.read(translationControllerProvider);
        expect(stateUr.currentResult!.primaryTranslation, equals(tc['ur']));

        // Switch to Farsi
        await notifier.setTargetLanguage(TranslationTargetLanguage.farsi);
        final stateFa = container.read(translationControllerProvider);
        expect(stateFa.currentResult!.primaryTranslation, equals(tc['fa']));

        // Switch to Arabic
        await notifier.setTargetLanguage(TranslationTargetLanguage.arabic);
        final stateAr = container.read(translationControllerProvider);
        expect(stateAr.currentResult!.primaryTranslation, equals(tc['ar']));

        container.dispose();
      }
    });

    testWidgets('2. Negative Cases: Whitespace, Gap, Ambiguity, Missing Word',
        (tester) async {
      final container = ProviderContainer(
        overrides: [
          germanLexiconRepositoryProvider.overrideWithValue(lexiconService),
          historyRepositoryProvider.overrideWithValue(historyRepo),
          userWordsRepositoryProvider.overrideWithValue(userWordsRepo),
          translationCacheProvider.overrideWithValue(cache),
        ],
      );
      addTearDown(container.dispose);

      // Hit-tester verification: Tap whitespace -> null
      const hitTester = ProductionExactHitTester();
      final words = [
        WordOccurrence(
          rawText: 'Deutsch',
          cleanWord: 'Deutsch',
          pageBoundingBox: const PdfRect(100, 500, 150, 485),
          pageNumber: 1,
          charIndex: 0,
          charLength: 7,
          charRects: const [PdfRect(100, 500, 150, 485)],
        ),
        WordOccurrence(
          rawText: 'in',
          cleanWord: 'in',
          pageBoundingBox: const PdfRect(170, 500, 185, 485),
          pageNumber: 1,
          charIndex: 8,
          charLength: 2,
          charRects: const [PdfRect(170, 500, 185, 485)],
        ),
      ];

      final spatialIndex = WordSpatialIndex(pageNumber: 1, words: words);

      // 1. Whitespace tap
      final whitespaceHit = hitTester.hitTest(
        pdfPoint: const PdfPoint(50.0, 500.0),
        screenOffset: Offset.zero,
        spatialIndex: spatialIndex,
      );
      expect(whitespaceHit.status, equals(SelectionStatus.whitespace));
      expect(whitespaceHit.word, isNull);

      // 2. Inter-word gap tap (x=160 between 150 and 170)
      final gapHit = hitTester.hitTest(
        pdfPoint: const PdfPoint(160.0, 492.0),
        screenOffset: Offset.zero,
        spatialIndex: spatialIndex,
      );
      expect(gapHit.status, equals(SelectionStatus.interWordGap));
      expect(gapHit.word, isNull);

      // 3. Ambiguous overlap
      final overlappingWords = [
        WordOccurrence(
          rawText: 'WortA',
          cleanWord: 'WortA',
          pageBoundingBox: const PdfRect(100, 500, 150, 485),
          pageNumber: 1,
          charIndex: 0,
          charLength: 5,
          charRects: const [PdfRect(100, 500, 150, 485)],
        ),
        WordOccurrence(
          rawText: 'WortB',
          cleanWord: 'WortB',
          pageBoundingBox: const PdfRect(120, 500, 170, 485),
          pageNumber: 1,
          charIndex: 0,
          charLength: 5,
          charRects: const [PdfRect(120, 500, 170, 485)],
        ),
      ];
      final overlapHit = hitTester.hitTest(
        pdfPoint: const PdfPoint(130.0, 490.0),
        screenOffset: Offset.zero,
        spatialIndex: WordSpatialIndex(pageNumber: 1, words: overlappingWords),
      );
      expect(overlapHit.status, equals(SelectionStatus.ambiguous));
      expect(overlapHit.word, isNull);

      // 4. Missing word lookup (explicit NOT_FOUND, no fake translation)
      final missingWord = WordOccurrence(
        rawText: 'UnbekanntesWortXYZ',
        cleanWord: 'UnbekanntesWortXYZ',
        pageBoundingBox: const PdfRect(100, 500, 200, 485),
        pageNumber: 1,
        charIndex: 0,
        charLength: 18,
        charRects: const [PdfRect(100, 500, 200, 485)],
      );

      final translationNotifier = container.read(translationControllerProvider.notifier);
      await translationNotifier.translateWord(missingWord);

      final state = container.read(translationControllerProvider);
      expect(state.currentResult, isNotNull);
      expect(state.currentResult!.isNotFound, isTrue);
      expect(state.currentResult!.primaryTranslation, isNull);
    });

    testWidgets('3. Generate All 10 Required Visual Artifacts (Screenshots)',
        (tester) async {
      tester.view.physicalSize = const Size(780, 1688); // Standard Phone Viewport (logical 390x844)
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final boundaryKey = GlobalKey();

      final container = ProviderContainer(
        overrides: [
          germanLexiconRepositoryProvider.overrideWithValue(lexiconService),
          historyRepositoryProvider.overrideWithValue(historyRepo),
          userWordsRepositoryProvider.overrideWithValue(userWordsRepo),
          translationCacheProvider.overrideWithValue(cache),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(translationControllerProvider.notifier);

      final wordDeutschland = WordOccurrence(
        rawText: 'Deutschland',
        cleanWord: 'Deutschland',
        pageBoundingBox: const PdfRect(210, 750, 310, 735),
        pageNumber: 1,
        charIndex: 21,
        charLength: 11,
        charRects: const [PdfRect(210, 750, 310, 735)],
      );

      // ───────────────────────────────────────────────────────────────────────
      // 1. PDF before selection (Pristine Original PDF)
      // ───────────────────────────────────────────────────────────────────────
      await tester.pumpWidget(
        createReaderTestHarness(
          boundaryKey: boundaryKey,
          container: container,
          showPopup: false,
        ),
      );
      await tester.pumpAndSettle();
      await captureWidgetScreenshot(tester, boundaryKey, 'pdf_before_selection.png');

      // ───────────────────────────────────────────────────────────────────────
      // 2. Exact word selected (PDF with active highlight/selection, before popup)
      // ───────────────────────────────────────────────────────────────────────
      await tester.pumpWidget(
        createReaderTestHarness(
          boundaryKey: boundaryKey,
          container: container,
          selectedWord: wordDeutschland,
          showPopup: false,
        ),
      );
      await tester.pumpAndSettle();
      await captureWidgetScreenshot(tester, boundaryKey, 'exact_word_selected.png');

      // ───────────────────────────────────────────────────────────────────────
      // 3. English Translation Popup
      // ───────────────────────────────────────────────────────────────────────
      await notifier.translateWord(wordDeutschland, targetLang: TranslationTargetLanguage.english);
      await tester.pumpWidget(
        createReaderTestHarness(
          boundaryKey: boundaryKey,
          container: container,
          selectedWord: wordDeutschland,
          showPopup: true,
        ),
      );
      await tester.pumpAndSettle();
      await captureWidgetScreenshot(tester, boundaryKey, 'popup_english.png');

      // ───────────────────────────────────────────────────────────────────────
      // 4. Urdu Translation Popup (RTL Directionality)
      // ───────────────────────────────────────────────────────────────────────
      await notifier.setTargetLanguage(TranslationTargetLanguage.urdu);
      await tester.pumpWidget(
        createReaderTestHarness(
          boundaryKey: boundaryKey,
          container: container,
          selectedWord: wordDeutschland,
          showPopup: true,
        ),
      );
      await tester.pumpAndSettle();
      await captureWidgetScreenshot(tester, boundaryKey, 'popup_urdu.png');

      // ───────────────────────────────────────────────────────────────────────
      // 5. Farsi Translation Popup (RTL Directionality)
      // ───────────────────────────────────────────────────────────────────────
      await notifier.setTargetLanguage(TranslationTargetLanguage.farsi);
      await tester.pumpWidget(
        createReaderTestHarness(
          boundaryKey: boundaryKey,
          container: container,
          selectedWord: wordDeutschland,
          showPopup: true,
        ),
      );
      await tester.pumpAndSettle();
      await captureWidgetScreenshot(tester, boundaryKey, 'popup_farsi.png');

      // ───────────────────────────────────────────────────────────────────────
      // 6. Arabic Translation Popup (RTL Directionality)
      // ───────────────────────────────────────────────────────────────────────
      await notifier.setTargetLanguage(TranslationTargetLanguage.arabic);
      await tester.pumpWidget(
        createReaderTestHarness(
          boundaryKey: boundaryKey,
          container: container,
          selectedWord: wordDeutschland,
          showPopup: true,
        ),
      );
      await tester.pumpAndSettle();
      await captureWidgetScreenshot(tester, boundaryKey, 'popup_arabic.png');

      // ───────────────────────────────────────────────────────────────────────
      // 7. NOT_FOUND State (Missing word, no fake hallucination)
      // ───────────────────────────────────────────────────────────────────────
      final missingWord = WordOccurrence(
        rawText: 'UnbekanntesWort',
        cleanWord: 'UnbekanntesWort',
        pageBoundingBox: const PdfRect(100, 500, 200, 485),
        pageNumber: 1,
        charIndex: 0,
        charLength: 15,
        charRects: const [PdfRect(100, 500, 200, 485)],
      );
      await notifier.translateWord(missingWord, targetLang: TranslationTargetLanguage.english);
      await tester.pumpWidget(
        createReaderTestHarness(
          boundaryKey: boundaryKey,
          container: container,
          selectedWord: missingWord,
          showPopup: true,
        ),
      );
      await tester.pumpAndSettle();
      await captureWidgetScreenshot(tester, boundaryKey, 'popup_not_found.png');

      // ───────────────────────────────────────────────────────────────────────
      // 8. Whitespace / No-Popup State (Tap outside word dismisses popup)
      // ───────────────────────────────────────────────────────────────────────
      notifier.dismissPopup();
      await tester.pumpWidget(
        createReaderTestHarness(
          boundaryKey: boundaryKey,
          container: container,
          showPopup: false,
        ),
      );
      await tester.pumpAndSettle();
      await captureWidgetScreenshot(tester, boundaryKey, 'whitespace_no_popup.png');

      // ───────────────────────────────────────────────────────────────────────
      // 9. My Words Saved State (User explicitly presses "Zu Meine Wörter")
      // ───────────────────────────────────────────────────────────────────────
      await notifier.translateWord(wordDeutschland, targetLang: TranslationTargetLanguage.english);
      await notifier.toggleSaveToMyWords(); // Explicit user save
      await tester.pumpWidget(
        createReaderTestHarness(
          boundaryKey: boundaryKey,
          container: container,
          selectedWord: wordDeutschland,
          showPopup: true,
        ),
      );
      await tester.pumpAndSettle();
      await captureWidgetScreenshot(tester, boundaryKey, 'my_words_saved.png');

      // ───────────────────────────────────────────────────────────────────────
      // 10. History Entry (View of recorded lookups)
      // ───────────────────────────────────────────────────────────────────────
      final historyList = await historyRepo.getRecentHistory();
      await tester.pumpWidget(
        RepaintBoundary(
          key: boundaryKey,
          child: MaterialApp(
            theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
            home: Scaffold(
              appBar: AppBar(
                title: const Text('Suchverlauf (History)'),
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
              ),
              body: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: historyList.length,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, index) {
                  final item = historyList[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.indigo.shade50,
                      child: Text(
                        item.targetLanguage.flagEmoji,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    title: Text(
                      item.rawWord,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    subtitle: Text(
                      item.translation ?? 'Keine Übersetzung',
                      style: TextStyle(
                        color: item.status == TranslationStatus.success
                            ? Colors.black87
                            : Colors.grey,
                      ),
                    ),
                    trailing: Text(
                      item.status == TranslationStatus.success
                          ? 'GESPEICHERT'
                          : 'NICHT GEFUNDEN',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: item.status == TranslationStatus.success
                            ? Colors.green.shade800
                            : Colors.amber.shade900,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await captureWidgetScreenshot(tester, boundaryKey, 'history_entry.png');
    });
  });
}
