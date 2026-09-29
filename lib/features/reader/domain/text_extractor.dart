// lib/features/reader/domain/text_extractor.dart

import 'package:pdfrx/pdfrx.dart';

/// Contract for extracting raw text and glyph bounding boxes from a PDF page.
abstract class TextExtractor {
  Future<PdfPageText?> extractStructuredText(PdfPage page);
}

/// Production implementation of [TextExtractor] using pdfrx's PDFium engine.
class PdfrxTextExtractor implements TextExtractor {
  const PdfrxTextExtractor();

  @override
  Future<PdfPageText?> extractStructuredText(PdfPage page) async {
    try {
      await page.ensureLoaded();
      return await page.loadStructuredText();
    } catch (_) {
      return null;
    }
  }
}
