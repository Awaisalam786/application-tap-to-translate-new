// lib/core/models/word_occurrence.dart

import 'package:pdfrx/pdfrx.dart';

/// The provenance of the word occurrence.
///
/// Both Digital PDF text extraction and OCR engines share this
/// common [WordOccurrence] data contract, ensuring reader decoupling.
enum WordSource {
  /// Extracted directly from PDFium glyph and character vector streams.
  digitalPdf,

  /// Extracted from computer vision OCR (optical character recognition).
  ocr,
}

/// Represents an identified word occurrence on a specific PDF page.
///
/// Stores both the exact character bounding boxes in PDF coordinates
/// (72 points/inch, bottom-left origin) and the normalized clean lemma
/// for translation and dictionary lookup.
class WordOccurrence {
  /// The raw token extracted from the text stream, including punctuation/quotes
  /// (e.g., '"Deutschland,"' or 'Fußball!').
  final String rawText;

  /// The cleaned, normalized German lemma with quotes and outer punctuation stripped
  /// (e.g., 'Deutschland' or 'Fußball').
  final String cleanWord;

  /// The overall bounding box encompassing the word in PDF page coordinates
  /// (origin: bottom-left, Y pointing upward, 72 pt/inch).
  final PdfRect pageBoundingBox;

  /// The 1-based page number where this word occurrence resides.
  final int pageNumber;

  /// Starting character index in the full page text stream.
  final int charIndex;

  /// Number of characters comprising this token in the page text stream.
  final int charLength;

  /// Individual bounding box for every constituent character glyph.
  final List<PdfRect> charRects;

  /// The extraction origin of this word occurrence.
  final WordSource source;

  /// If this word was hyphenated across lines (e.g., 'Bundes-' / 'republik'),
  /// stores the full de-hyphenated compound word ('Bundesrepublik').
  final String? dehyphenatedCompound;

  // ───────────────────────────────────────────────────────────────────────────
  // OCR METADATA (Null/unspecified for Digital PDF)
  // ─────────────────────────────────────────────────────────────────────────

  /// Confidence score between 0.0 and 1.0 reported by the OCR engine.
  /// Null if the engine does not provide confidence values.
  ///
  /// INVARIANT: Never invent or fake confidence values.
  final double? confidence;

  /// Optional OCR structural block identifier.
  final String? blockId;

  /// Optional OCR line identifier.
  final String? lineId;

  /// Optional language recognized by the OCR engine for this word (e.g. 'de').
  final String? recognizedLanguage;

  /// Optional vendor-specific engine telemetry / raw response attributes.
  final Map<String, dynamic>? engineMetadata;

  const WordOccurrence({
    required this.rawText,
    required this.cleanWord,
    required this.pageBoundingBox,
    required this.pageNumber,
    required this.charIndex,
    required this.charLength,
    required this.charRects,
    this.source = WordSource.digitalPdf,
    this.dehyphenatedCompound,
    this.confidence,
    this.blockId,
    this.lineId,
    this.recognizedLanguage,
    this.engineMetadata,
  });

  /// Factory constructor for words identified through OCR.
  factory WordOccurrence.ocr({
    required String rawText,
    required String cleanWord,
    required PdfRect pageBoundingBox,
    required int pageNumber,
    required int charIndex,
    required int charLength,
    List<PdfRect> charRects = const [],
    String? dehyphenatedCompound,
    double? confidence,
    String? blockId,
    String? lineId,
    String? recognizedLanguage,
    Map<String, dynamic>? engineMetadata,
  }) {
    return WordOccurrence(
      rawText: rawText,
      cleanWord: cleanWord,
      pageBoundingBox: pageBoundingBox,
      pageNumber: pageNumber,
      charIndex: charIndex,
      charLength: charLength,
      charRects: charRects,
      source: WordSource.ocr,
      dehyphenatedCompound: dehyphenatedCompound,
      confidence: confidence,
      blockId: blockId,
      lineId: lineId,
      recognizedLanguage: recognizedLanguage,
      engineMetadata: engineMetadata,
    );
  }

  /// The primary word string to present for translation or dictionary lookup.
  String get lookupTerm => dehyphenatedCompound ?? cleanWord;

  /// True if this word was recognized by an OCR engine.
  bool get isOcr => source == WordSource.ocr;

  @override
  String toString() =>
      'WordOccurrence("$cleanWord", source: ${source.name}, conf: ${confidence?.toStringAsFixed(2) ?? "none"}, page: $pageNumber, bbox: [l=${pageBoundingBox.left.toStringAsFixed(1)}, b=${pageBoundingBox.bottom.toStringAsFixed(1)}, r=${pageBoundingBox.right.toStringAsFixed(1)}, t=${pageBoundingBox.top.toStringAsFixed(1)}])';
}
