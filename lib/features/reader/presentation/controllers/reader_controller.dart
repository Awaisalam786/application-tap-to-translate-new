import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../../../core/models/page_geometry.dart';
import '../../../../core/models/selection_result.dart';
import '../../../../core/models/word_occurrence.dart';
import '../../../ocr/data/repositories/google_ml_kit_ocr_adapter.dart';
import '../../../ocr/data/repositories/in_memory_ocr_cache.dart';
import '../../../ocr/data/repositories/mock_german_ocr_provider.dart';
import '../../../ocr/domain/repositories/ocr_cache.dart';
import '../../../ocr/domain/repositories/ocr_provider.dart';
import '../../../ocr/domain/services/ocr_service.dart';
import '../../data/pdf_repository.dart';
import '../../domain/exact_hit_tester.dart';
import '../../domain/selection_resolver.dart';
import '../../domain/text_extractor.dart';
import '../../domain/word_reconstructor.dart';
import '../../domain/word_spatial_index.dart';
import 'reader_state.dart';

final ocrCacheProvider = Provider<OcrCache>((ref) {
  return InMemoryOcrCache();
});

final ocrProvider = Provider<OcrProvider>((ref) {
  if (Platform.isAndroid || Platform.isIOS) {
    debugPrint('[ML_KIT_INIT] Real GoogleMlKitOcrAdapter instantiated (Platform: ${Platform.operatingSystem})');
    return const GoogleMlKitOcrAdapter(isAvailable: true);
  }
  return const MockGermanOcrProvider();
});

final ocrServiceProvider = Provider<OcrService>((ref) {
  return OcrService(
    provider: ref.watch(ocrProvider),
    cache: ref.watch(ocrCacheProvider),
  );
});

final readerControllerProvider =
    StateNotifierProvider<ReaderController, ReaderState>((ref) {
  return ReaderController(
    textExtractor: const PdfrxTextExtractor(),
    wordReconstructor: const GermanWordReconstructor(),
    selectionResolver: const SelectionResolver(
      hitTester: ProductionExactHitTester(),
    ),
    ocrService: ref.watch(ocrServiceProvider),
  );
});

class ReaderController extends StateNotifier<ReaderState> {
  final TextExtractor textExtractor;
  final WordReconstructor wordReconstructor;
  final SelectionResolver selectionResolver;
  final OcrService? ocrService;

  ReaderController({
    required this.textExtractor,
    required this.wordReconstructor,
    required this.selectionResolver,
    this.ocrService,
  }) : super(const ReaderState());

  /// Sets the active document.
  void setDocument(PdfDocumentDescriptor descriptor) {
    state = state.copyWith(
      document: descriptor,
      currentPage: 1,
      totalPages: 0,
      isReady: false,
      isLoading: true,
      pageGeometries: {},
      clearSelection: true,
      errorMessage: null,
    );
  }

  /// Called when the PDF document is ready.
  void onDocumentReady(PdfDocument document) {
    state = state.copyWith(
      totalPages: document.pages.length,
      isReady: true,
      isLoading: false,
    );
  }

  /// Toggles DEBUG visualization mode.
  ///
  /// In production, selection layer is completely invisible.
  /// In debug mode, word bounding boxes and tap coordinates are rendered visually.
  void toggleDebugMode() {
    state = state.copyWith(isDebugMode: !state.isDebugMode);
  }

  /// Updates current page number.
  void setPage(int pageNumber) {
    if (pageNumber < 1 || (state.totalPages > 0 && pageNumber > state.totalPages)) return;
    state = state.copyWith(currentPage: pageNumber);
  }

  /// Updates current zoom level.
  void setZoom(double zoom) {
    state = state.copyWith(currentZoom: zoom);
  }

  /// Clears active selection.
  void clearSelection() {
    state = state.copyWith(clearSelection: true);
  }

  /// Asynchronously extracts and caches page geometry and word spatial index.
  ///
  /// Handles both Digital PDFs (vector glyph streams) and Scanned PDFs (empty text streams,
  /// delegating to lazy OCR processing).
  Future<void> ensurePageGeometryLoaded(PdfPage page, {bool onlyIfDigital = false}) async {
    final pageNum = page.pageNumber;
    if (state.pageGeometries.containsKey(pageNum)) return;

    final structText = await textExtractor.extractStructuredText(page);
    List<WordOccurrence> words;
    String fullText;
    List<PdfRect> charRects;

    if (structText != null && structText.fullText.trim().isNotEmpty) {
      // 1. Digital PDF: vector glyph stream
      words = wordReconstructor.reconstructWords(structText);
      fullText = structText.fullText;
      charRects = structText.charRects;
    } else if (!onlyIfDigital && ocrService != null) {
      // 2. Scanned PDF: lazy OCR processing with offline cache
      String? imagePath;
      try {
        final renderWidth = (page.width * 2.0).round();
        final renderHeight = (page.height * 2.0).round();
        final pdfImage = await page.render(
          fullWidth: renderWidth.toDouble(),
          fullHeight: renderHeight.toDouble(),
        );
        if (pdfImage != null) {
          final completer = Completer<ui.Image>();
          ui.decodeImageFromPixels(
            pdfImage.pixels,
            pdfImage.width,
            pdfImage.height,
            ui.PixelFormat.bgra8888,
            completer.complete,
          );
          final uiImg = await completer.future;
          final byteData = await uiImg.toByteData(format: ui.ImageByteFormat.png);
          pdfImage.dispose();

          if (byteData != null) {
            final tempDir = await getTemporaryDirectory();
            final file = File(
              '${tempDir.path}/ocr_p${pageNum}_${DateTime.now().microsecondsSinceEpoch}.png',
            );
            await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
            imagePath = file.path;
          }
        }
      } catch (e) {
        debugPrint('OCR page rendering fallback: $e');
      }

      final ocrResult = await ocrService!.processPage(
        documentId: state.document?.path ?? 'scanned_doc',
        pageNumber: pageNum,
        pageWidth: page.width,
        pageHeight: page.height,
        imagePath: imagePath,
      );
      words = ocrResult.words;
      fullText = ocrResult.fullText;
      charRects = words.expand((w) => w.charRects).toList();
    } else {
      if (onlyIfDigital) {
        // Do not cache empty geometry for scanned pages during background preload;
        // leave it unloaded so lazy OCR processes it on-demand when viewed.
        return;
      }
      words = const [];
      fullText = '';
      charRects = const [];
    }

    final geometry = PageGeometry(
      pageNumber: pageNum,
      width: page.width,
      height: page.height,
      rotation: page.rotation,
      fullText: fullText,
      charRects: charRects,
      words: words,
    );

    final updatedGeometries = Map<int, PageGeometry>.from(state.pageGeometries);
    updatedGeometries[pageNum] = geometry;
    state = state.copyWith(pageGeometries: updatedGeometries);
  }

  /// Resolves an exact tap on the PDF viewer.
  SelectionResult? handleTap({
    required Offset localScreenOffset,
    required BuildContext context,
    required PdfViewerController controller,
  }) {
    final spatialIndices = <int, WordSpatialIndex>{};
    for (final entry in state.pageGeometries.entries) {
      spatialIndices[entry.key] = WordSpatialIndex(
        pageNumber: entry.key,
        words: entry.value.words,
      );
    }

    final result = selectionResolver.resolveTap(
      localTapOffset: localScreenOffset,
      context: context,
      controller: controller,
      pageIndices: spatialIndices,
    );

    if (result != null) {
      state = state.copyWith(lastSelection: result);
    }

    return result;
  }
}
