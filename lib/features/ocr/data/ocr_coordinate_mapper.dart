// lib/features/ocr/data/ocr_coordinate_mapper.dart

import 'dart:ui';
import 'package:pdfrx/pdfrx.dart';

/// Accurate mathematical transformation between OCR image pixel space and PDF point space.
///
/// Coordinate system differences:
/// 1. OCR Engine Coordinates:
///    - Origin: TOP-LEFT (0, 0)
///    - X-axis: 0 -> imageWidth (points right)
///    - Y-axis: 0 -> imageHeight (points DOWN)
///
/// 2. PDF Document Coordinates (72 pt / inch):
///    - Origin: BOTTOM-LEFT (0, 0)
///    - X-axis: 0 -> pageWidth (points right)
///    - Y-axis: 0 -> pageHeight (points UP)
class OcrCoordinateMapper {
  const OcrCoordinateMapper();

  /// Converts a bounding box from image pixel coordinates to PDF page coordinates.
  PdfRect mapPixelToPdfRect({
    required Rect pixelRect,
    required int imageWidth,
    required int imageHeight,
    required double pageWidth,
    required double pageHeight,
  }) {
    assert(imageWidth > 0 && imageHeight > 0, 'Image dimensions must be positive');
    assert(pageWidth > 0 && pageHeight > 0, 'Page dimensions must be positive');

    final scaleX = pageWidth / imageWidth;
    final scaleY = pageHeight / imageHeight;

    final pdfLeft = pixelRect.left * scaleX;
    final pdfRight = pixelRect.right * scaleX;

    // Invert Y: pixelTop maps to higher PDF Y, pixelBottom maps to lower PDF Y
    final pdfTop = pageHeight - (pixelRect.top * scaleY);
    final pdfBottom = pageHeight - (pixelRect.bottom * scaleY);

    return PdfRect(pdfLeft, pdfTop, pdfRight, pdfBottom);
  }

  /// Converts a normalized bounding box (ratios between 0.0 and 1.0) to PDF page coordinates.
  PdfRect mapNormalizedToPdfRect({
    required Rect normalizedRect,
    required double pageWidth,
    required double pageHeight,
  }) {
    final pdfLeft = normalizedRect.left * pageWidth;
    final pdfRight = normalizedRect.right * pageWidth;

    final pdfTop = pageHeight - (normalizedRect.top * pageHeight);
    final pdfBottom = pageHeight - (normalizedRect.bottom * pageHeight);

    return PdfRect(pdfLeft, pdfTop, pdfRight, pdfBottom);
  }
}
