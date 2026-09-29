// lib/features/ocr/domain/models/ocr_page_result.dart

import '../../../../core/models/word_occurrence.dart';

/// Represents the complete optical character recognition result for a single PDF page.
class OcrPageResult {
  /// 1-based page number.
  final int pageNumber;

  /// Width of the PDF page in PDF points (72 points/inch).
  final double pageWidth;

  /// Height of the PDF page in PDF points.
  final double pageHeight;

  /// Width of the rendered raster bitmap in pixels used for OCR.
  final int imageWidth;

  /// Height of the rendered raster bitmap in pixels used for OCR.
  final int imageHeight;

  /// All identified word occurrences, already mapped to PDF page coordinates.
  final List<WordOccurrence> words;

  /// Full concatenated text recognized on this page.
  final String fullText;

  /// The name of the OCR engine that produced this result (e.g. "Google ML Kit", "MockEngine").
  final String engineName;

  /// The version of the OCR provider / engine.
  final String engineVersion;

  /// Overall or mean confidence score between 0.0 and 1.0 reported by the engine.
  /// Null if the engine does not report confidence.
  final double? confidence;

  /// Timestamp when OCR was performed.
  final DateTime recognizedAt;

  const OcrPageResult({
    required this.pageNumber,
    required this.pageWidth,
    required this.pageHeight,
    required this.imageWidth,
    required this.imageHeight,
    required this.words,
    required this.fullText,
    required this.engineName,
    required this.engineVersion,
    this.confidence,
    required this.recognizedAt,
  });

  /// Scale factor between image pixels and PDF points (X axis).
  double get scaleX => pageWidth / imageWidth;

  /// Scale factor between image pixels and PDF points (Y axis).
  double get scaleY => pageHeight / imageHeight;

  /// True if any text was recognized on this page.
  bool get hasContent => words.isNotEmpty;
}
