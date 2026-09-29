// lib/core/coordinates/coordinate_mapper.dart

import 'package:flutter/widgets.dart';
import 'package:pdfrx/pdfrx.dart';

/// Contract for transforming coordinates between Flutter's screen viewport
/// (logical pixels, top-left origin, Y downwards) and PDF Page space
/// (points 1/72 inch, bottom-left origin, Y upwards).
abstract class CoordinateMapper {
  /// Maps a local screen tap offset to a PDF page point and page number.
  ///
  /// Returns null if the tap fell outside any rendered PDF page.
  PdfPageHitTestResult? screenToPage({
    required Offset localScreenOffset,
    required BuildContext context,
    required PdfViewerController controller,
  });

  /// Maps a PDF page-space rectangle to Flutter screen local coordinates.
  ///
  /// Used in DEBUG mode to render bounding box overlays directly over the rendered page.
  Rect? pageRectToScreenRect({
    required int pageNumber,
    required PdfRect pageRect,
    required BuildContext context,
    required PdfViewerController controller,
  });
}

/// Production implementation of [CoordinateMapper] leveraging pdfrx's
/// exact matrix transformations.
class PdfrxCoordinateMapper implements CoordinateMapper {
  const PdfrxCoordinateMapper();

  @override
  PdfPageHitTestResult? screenToPage({
    required Offset localScreenOffset,
    required BuildContext context,
    required PdfViewerController controller,
  }) {
    if (!controller.isReady) return null;

    // controller.getPdfPageHitTestResult computes the exact viewport matrix
    // inversion taking current zoom, pan, and page layout coordinates into account.
    return controller.getPdfPageHitTestResult(
      localScreenOffset,
      useDocumentLayoutCoordinates: false,
    );
  }

  @override
  Rect? pageRectToScreenRect({
    required int pageNumber,
    required PdfRect pageRect,
    required BuildContext context,
    required PdfViewerController controller,
  }) {
    if (!controller.isReady) return null;

    final docRect = controller.calcRectForRectInsidePage(
      pageNumber: pageNumber,
      rect: pageRect,
    );
    return controller.doc2local.rectToLocal(context, docRect);
  }
}
