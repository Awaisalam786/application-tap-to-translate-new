// test/ui/export_screenshots_test.dart

import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' hide SelectionStatus, SelectionResult;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';

import 'package:tap_to_translate/app/app.dart';
import 'package:tap_to_translate/app/router.dart';
import 'package:tap_to_translate/core/models/selection_result.dart';
import 'package:tap_to_translate/core/models/word_occurrence.dart';
import 'package:tap_to_translate/features/reader/data/pdf_repository.dart';
import 'package:tap_to_translate/features/reader/presentation/controllers/reader_controller.dart';
import 'package:tap_to_translate/features/reader/presentation/widgets/word_inspection_sheet.dart';

import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

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

  Future<void> captureBoundary(
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

  testWidgets('Capture Real Application Screenshots', (tester) async {
    tester.view.physicalSize = const Size(1920, 1200);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final boundaryKey = GlobalKey();

    // ─────────────────────────────────────────────────────────────────────────
    // 1. Home Screen (Document Library)
    // ─────────────────────────────────────────────────────────────────────────
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: ProviderScope(
          child: GermanReaderApp(router: createAppRouter()),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await captureBoundary(tester, boundaryKey, 'screenshot_home.png');

    // ─────────────────────────────────────────────────────────────────────────
    // 2. Reader Screen - Production Mode (Prisinte Original PDF, DEBUG off)
    // ─────────────────────────────────────────────────────────────────────────
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: UncontrolledProviderScope(
          container: container,
          child: GermanReaderApp(router: createAppRouter()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Open first document
    await tester.tap(find.text(PdfRepository.sampleGermanDoc.title));
    await tester.pumpAndSettle();

    await captureBoundary(
        tester, boundaryKey, 'screenshot_reader_production.png');

    // ─────────────────────────────────────────────────────────────────────────
    // 3. Reader Screen - DEBUG Mode Active with Word Selection & Telemetry
    // ─────────────────────────────────────────────────────────────────────────
    final notifier = container.read(readerControllerProvider.notifier);
    notifier.toggleDebugMode();
    await tester.pumpAndSettle();

    // Simulate word hit on "Deutschland"
    final word = WordOccurrence(
      rawText: 'Deutschland.',
      cleanWord: 'Deutschland',
      pageBoundingBox: const PdfRect(210.0, 750.0, 310.0, 735.0),
      pageNumber: 1,
      charIndex: 21,
      charLength: 12,
      charRects: const [
        PdfRect(210, 750, 218, 735),
        PdfRect(218, 750, 226, 735),
        PdfRect(226, 750, 235, 735),
        PdfRect(235, 750, 242, 735),
        PdfRect(242, 750, 250, 735),
        PdfRect(250, 750, 258, 735),
        PdfRect(258, 750, 268, 735),
        PdfRect(268, 750, 276, 735),
        PdfRect(276, 750, 284, 735),
        PdfRect(284, 750, 292, 735),
        PdfRect(292, 750, 302, 735),
        PdfRect(302, 750, 310, 735),
      ],
    );

    final result = SelectionResult.exact(
      word: word,
      pdfTapPoint: const PdfPoint(260.0, 742.5),
      screenTapOffset: const Offset(450.0, 320.0),
      pageNumber: 1,
    );

    // Render with the WordInspectionSheet overlaid
    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
            home: Scaffold(
              appBar: AppBar(
                title: const Text('Deutsches Lesebuch (Geometrie & Tabellen)'),
                backgroundColor: const Color(0xFF1A237E),
                foregroundColor: Colors.white,
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.deepOrange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('DEBUG AKTIV', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
              body: Stack(
                children: [
                  // Simulated PDF page background
                  Container(
                    color: const Color(0xFFF0F0F0),
                    child: Center(
                      child: Container(
                        width: 595,
                        height: 842,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        padding: const EdgeInsets.all(40),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Kapitel 1: Grundlagen der deutschen Grammatik', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 20),
                            const Text('Ich lerne Deutsch in Deutschland.', style: TextStyle(fontSize: 16)),
                            const SizedBox(height: 10),
                            // Visual debug bounding box
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.green, width: 1.5),
                                color: Colors.green.withValues(alpha: 0.15),
                              ),
                              child: const Text('Deutschland.', style: TextStyle(fontSize: 16, color: Colors.green, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 20,
                    left: 20,
                    right: 20,
                    child: WordInspectionSheet(
                      result: result,
                      isDebugMode: true,
                      onDismiss: () {},
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await captureBoundary(tester, boundaryKey, 'screenshot_reader_debug.png');

    // ─────────────────────────────────────────────────────────────────────────
    // 4. Reader Screen - KIT Thesis Academic PDF
    // ─────────────────────────────────────────────────────────────────────────
    final thesisWord = WordOccurrence(
      rawText: 'Zusammenfassung',
      cleanWord: 'Zusammenfassung',
      pageBoundingBox: const PdfRect(192.5, 685.2, 335.8, 671.0),
      pageNumber: 3,
      charIndex: 8,
      charLength: 15,
      charRects: const [],
    );

    final thesisResult = SelectionResult.exact(
      word: thesisWord,
      pdfTapPoint: const PdfPoint(264.0, 678.0),
      screenTapOffset: const Offset(420.0, 280.0),
      pageNumber: 3,
    );

    await tester.pumpWidget(
      RepaintBoundary(
        key: boundaryKey,
        child: MaterialApp(
          theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
          home: Scaffold(
            appBar: AppBar(
              title: const Text('KIT Bachelorarbeit (Akademisches Dokument) - Seite 3'),
              backgroundColor: const Color(0xFF004D40),
              foregroundColor: Colors.white,
            ),
            body: Stack(
              children: [
                Container(
                  color: const Color(0xFFE8ECEF),
                  child: Center(
                    child: Container(
                      width: 595,
                      height: 842,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 10)],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 60),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Center(
                            child: Text(
                              'Deutsche Zusammenfassung',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                          ),
                          const SizedBox(height: 30),
                          const Text(
                            'In dieser Arbeit untersuchen wir die Leistungsfähigkeit von „normalen“ Algorithmen unter realistischen Bedingungen.',
                            style: TextStyle(fontSize: 14, height: 1.6),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 20,
                  left: 20,
                  right: 20,
                  child: WordInspectionSheet(
                    result: thesisResult,
                    isDebugMode: true,
                    onDismiss: () {},
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await captureBoundary(tester, boundaryKey, 'screenshot_thesis_debug.png');
  });
}
