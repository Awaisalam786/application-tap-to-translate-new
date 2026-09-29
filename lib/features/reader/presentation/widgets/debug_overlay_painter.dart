// lib/features/reader/presentation/widgets/debug_overlay_painter.dart

import 'package:flutter/material.dart';
import '../../../../core/coordinates/coordinate_mapper.dart';
import '../controllers/reader_state.dart';
import 'package:pdfrx/pdfrx.dart';

/// Custom painter for rendering debug geometry overlays directly on top
/// of the PDF view when DEBUG mode is active.
///
/// In production mode, this painter renders absolutely nothing,
/// ensuring the original PDF remains the sole visual source of truth.
class DebugOverlayPainter extends CustomPainter {
  final ReaderState state;
  final PdfViewerController controller;
  final BuildContext context;
  final CoordinateMapper mapper;

  DebugOverlayPainter({
    required this.state,
    required this.controller,
    required this.context,
    this.mapper = const PdfrxCoordinateMapper(),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!state.isDebugMode || !controller.isReady) return;

    final crosshairPaint = Paint()
      ..color = const Color(0xFFFF1744) // Bright red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw tap coordinate crosshair and telemetry
    final lastSelection = state.lastSelection;
    if (lastSelection != null) {
      final tapPos = lastSelection.screenTapOffset;

      // Draw crosshair
      canvas.drawLine(
        Offset(tapPos.dx - 12, tapPos.dy),
        Offset(tapPos.dx + 12, tapPos.dy),
        crosshairPaint,
      );
      canvas.drawLine(
        Offset(tapPos.dx, tapPos.dy - 12),
        Offset(tapPos.dx, tapPos.dy + 12),
        crosshairPaint,
      );

      // Draw coordinate label badge
      final textSpan = TextSpan(
        text: 'PDF: (${lastSelection.pdfTapPoint.x.toStringAsFixed(1)}, ${lastSelection.pdfTapPoint.y.toStringAsFixed(1)})\n'
            'Status: ${lastSelection.status.name}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          backgroundColor: Color(0xCC000000),
        ),
      );

      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(canvas, Offset(tapPos.dx + 6, tapPos.dy + 6));
    }
  }

  @override
  bool shouldRepaint(covariant DebugOverlayPainter oldDelegate) {
    return state.isDebugMode != oldDelegate.state.isDebugMode ||
        state.lastSelection != oldDelegate.state.lastSelection ||
        state.currentPage != oldDelegate.state.currentPage ||
        state.currentZoom != oldDelegate.state.currentZoom;
  }
}
