// lib/features/reader/presentation/widgets/pdf_viewer_widget.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../data/pdf_repository.dart';
import 'package:tap_to_translate/core/models/selection_result.dart';
import 'package:tap_to_translate/features/translation/presentation/controllers/translation_controller.dart';
import '../controllers/reader_controller.dart';
import 'debug_overlay_painter.dart';

class PdfViewerWidget extends ConsumerStatefulWidget {
  final PdfDocumentDescriptor document;
  final PdfViewerController controller;

  const PdfViewerWidget({
    super.key,
    required this.document,
    required this.controller,
  });

  @override
  ConsumerState<PdfViewerWidget> createState() => _PdfViewerWidgetState();
}

class _PdfViewerWidgetState extends ConsumerState<PdfViewerWidget> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onViewerControllerUpdate);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onViewerControllerUpdate);
    super.dispose();
  }

  void _onViewerControllerUpdate() {
    if (!mounted || !widget.controller.isReady) return;
    final notifier = ref.read(readerControllerProvider.notifier);
    notifier.setPage(widget.controller.pageNumber ?? 1);
    notifier.setZoom(widget.controller.currentZoom);
  }

  void _handleTapOffset(Offset localPosition) {
    debugPrint('[TAP_PIPELINE] >>> START TAP RESOLUTION PIPELINE >>>');
    final notifier = ref.read(readerControllerProvider.notifier);
    final result = notifier.handleTap(
      localScreenOffset: localPosition,
      context: context,
      controller: widget.controller,
    );

    final translationNotifier = ref.read(translationControllerProvider.notifier);
    if (result != null && result.status == SelectionStatus.exactMatch && result.word != null) {
      debugPrint('[TAP_PIPELINE] 6. ExactHitTester produced exactMatch -> invoking TranslationResolver for "${result.word!.cleanWord}"');
      translationNotifier.translateWord(result.word!);
      debugPrint('[TAP_PIPELINE] 7. TranslationPopup triggered and displayed on screen');
    } else {
      debugPrint('[TAP_PIPELINE] 5. Selection rejected (status: ${result?.status}) -> dismissPopup (ZERO nearest-word fallback)');
      translationNotifier.dismissPopup();
    }
    debugPrint('[TAP_PIPELINE] <<< END TAP RESOLUTION PIPELINE <<<');
  }

  void _handleTapUp(TapUpDetails details) {
    _handleTapOffset(details.localPosition);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(readerControllerProvider);

    Widget viewerWidget;
    switch (widget.document.type) {
      case PdfDocumentSourceType.asset:
        viewerWidget = PdfViewer.asset(
          widget.document.path,
          controller: widget.controller,
          params: _buildViewerParams(),
        );
        break;
      case PdfDocumentSourceType.file:
        viewerWidget = PdfViewer.file(
          widget.document.path,
          controller: widget.controller,
          params: _buildViewerParams(),
        );
        break;
    }

    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onTapUp: _handleTapUp,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Original PDF rendering is the visual source of truth
          viewerWidget,

          // Invisible in production; renders bounding boxes only if DEBUG mode is enabled
          if (state.isDebugMode)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: DebugOverlayPainter(
                    state: state,
                    controller: widget.controller,
                    context: context,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  PdfViewerParams _buildViewerParams() {
    final state = ref.watch(readerControllerProvider);
    return PdfViewerParams(
      // Keep background neutral dark/light per material design
      backgroundColor: const Color(0xFFF2F4F7),
      onViewerReady: (document, controller) {
        final notifier = ref.read(readerControllerProvider.notifier);
        notifier.onDocumentReady(document);

        // Preload geometries for all pages
        for (final page in document.pages) {
          notifier.ensurePageGeometryLoaded(page);
        }
      },
      onPageChanged: (pageNumber) {
        if (pageNumber != null) {
          ref.read(readerControllerProvider.notifier).setPage(pageNumber);
        }
      },
      onGeneralTap: (context, controller, details) {
        if (details.type == PdfViewerGeneralTapType.tap) {
          _handleTapOffset(details.localPosition);
          return true;
        }
        return false;
      },
      pagePaintCallbacks: [
        (canvas, pageRect, page) {
          if (!state.isDebugMode) return;
          final activeGeometry = state.pageGeometries[page.pageNumber];
          if (activeGeometry == null) return;

          final wordBoxPaint = Paint()
            ..color = const Color(0x334CAF50)
            ..style = PaintingStyle.fill;

          final wordBorderPaint = Paint()
            ..color = const Color(0x994CAF50)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0;

          final selectedBoxPaint = Paint()
            ..color = const Color(0x5500E5FF)
            ..style = PaintingStyle.fill;

          final selectedBorderPaint = Paint()
            ..color = const Color(0xFF00E5FF)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0;

          for (final word in activeGeometry.words) {
            final isSelected = state.selectedWord?.cleanWord == word.cleanWord &&
                state.selectedWord?.charIndex == word.charIndex &&
                state.selectedWord?.pageNumber == word.pageNumber;

            final rect = word.pageBoundingBox
                .toRect(page: page, scaledPageSize: pageRect.size)
                .translate(pageRect.left, pageRect.top);

            canvas.drawRect(rect, isSelected ? selectedBoxPaint : wordBoxPaint);
            canvas.drawRect(rect, isSelected ? selectedBorderPaint : wordBorderPaint);
          }
        },
      ],
    );
  }
}
