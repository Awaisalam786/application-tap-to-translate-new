// lib/features/ocr/domain/repositories/ocr_provider.dart

import 'dart:typed_data';
import '../models/ocr_page_result.dart';

/// Contract for optical character recognition providers.
///
/// Designed to decouple the PDF reader interaction layer from any specific
/// OCR vendor (e.g. Google ML Kit, Apple Vision, Tesseract, or on-device neural engines).
abstract class OcrProvider {
  /// Identifying name of this OCR engine (e.g., "Google ML Kit", "Apple Vision", "Offline Mock").
  String get name;

  /// Semantic version or build identifier of this OCR provider.
  String get version;

  /// Whether this OCR engine is initialized and available on the current platform.
  bool get isAvailable;

  /// Performs optical character recognition on a page raster image file on disk.
  ///
  /// Takes the original PDF page dimensions in PDF points ([pageWidth], [pageHeight])
  /// and maps all detected word bounding boxes directly into the PDF coordinate system.
  Future<OcrPageResult> recognizePageImage({
    required int pageNumber,
    required double pageWidth,
    required double pageHeight,
    required String imagePath,
    String? languageHint,
  });

  /// Performs optical character recognition on raw in-memory image bytes.
  Future<OcrPageResult> recognizeImageBytes({
    required int pageNumber,
    required double pageWidth,
    required double pageHeight,
    required Uint8List imageBytes,
    required int imageWidth,
    required int imageHeight,
    String? languageHint,
  });
}
