// lib/features/ocr/data/repositories/mock_german_ocr_provider.dart

import 'dart:typed_data';
import 'dart:ui';
import 'package:pdfrx/pdfrx.dart';

import '../../../../core/models/word_occurrence.dart';
import '../../domain/models/ocr_page_result.dart';
import '../../domain/repositories/ocr_provider.dart';
import '../ocr_coordinate_mapper.dart';

/// Offline deterministic German OCR provider for testing and validation.
///
/// Implements [OcrProvider] with realistic scanned German document layouts:
/// - Multi-column formatting (Column 1 and Column 2)
/// - Authentic German orthography (ä, ö, ü, Ä, Ö, Ü, ß)
/// - Dehyphenated compound words across lines ("Bundes-" / "republik")
/// - Varying font sizes
/// - Punctuation and quotes
/// - Realistic confidence scores
class MockGermanOcrProvider implements OcrProvider {
  final OcrCoordinateMapper coordinateMapper;

  const MockGermanOcrProvider({
    this.coordinateMapper = const OcrCoordinateMapper(),
  });

  @override
  String get name => 'Offline German OCR Mock';

  @override
  String get version => '1.0.0-phase7';

  @override
  bool get isAvailable => true;

  @override
  Future<OcrPageResult> recognizePageImage({
    required int pageNumber,
    required double pageWidth,
    required double pageHeight,
    required String imagePath,
    String? languageHint,
  }) async {
    // Standard mock image dimensions (e.g. 1190 x 1684 at 2.0x A4 scale)
    final imageWidth = (pageWidth * 2.0).round();
    final imageHeight = (pageHeight * 2.0).round();

    return _generateOcrResult(
      pageNumber: pageNumber,
      pageWidth: pageWidth,
      pageHeight: pageHeight,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );
  }

  @override
  Future<OcrPageResult> recognizeImageBytes({
    required int pageNumber,
    required double pageWidth,
    required double pageHeight,
    required Uint8List imageBytes,
    required int imageWidth,
    required int imageHeight,
    String? languageHint,
  }) async {
    return _generateOcrResult(
      pageNumber: pageNumber,
      pageWidth: pageWidth,
      pageHeight: pageHeight,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );
  }

  OcrPageResult _generateOcrResult({
    required int pageNumber,
    required double pageWidth,
    required double pageHeight,
    required int imageWidth,
    required int imageHeight,
  }) {
    // Generate layout based on page number
    if (pageNumber == 2) {
      return _buildMultiColumnPage(
        pageNumber: pageNumber,
        pageWidth: pageWidth,
        pageHeight: pageHeight,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
      );
    }

    return _buildStandardGermanPage(
      pageNumber: pageNumber,
      pageWidth: pageWidth,
      pageHeight: pageHeight,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
    );
  }

  /// Page 1: Standard German scanned page with Umlauts, ß, Quotes, and Hyphenation
  OcrPageResult _buildStandardGermanPage({
    required int pageNumber,
    required double pageWidth,
    required double pageHeight,
    required int imageWidth,
    required int imageHeight,
  }) {
    final words = <WordOccurrence>[];

    void addWord({
      required String rawText,
      required String cleanWord,
      required Rect pixelRect,
      required int charIndex,
      String? dehyphenatedCompound,
      double? confidence = 0.98,
      String? blockId = 'block_1',
      String? lineId = 'line_1',
    }) {
      final pdfBox = coordinateMapper.mapPixelToPdfRect(
        pixelRect: pixelRect,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
        pageWidth: pageWidth,
        pageHeight: pageHeight,
      );

      // Synthesize individual glyph charRects inside word
      final charWidth = (pdfBox.right - pdfBox.left) / rawText.length;
      final charRects = List.generate(
        rawText.length,
        (i) => PdfRect(
          pdfBox.left + i * charWidth,
          pdfBox.top,
          pdfBox.left + (i + 1) * charWidth,
          pdfBox.bottom,
        ),
      );

      words.add(
        WordOccurrence.ocr(
          rawText: rawText,
          cleanWord: cleanWord,
          pageBoundingBox: pdfBox,
          pageNumber: pageNumber,
          charIndex: charIndex,
          charLength: rawText.length,
          charRects: charRects,
          dehyphenatedCompound: dehyphenatedCompound,
          confidence: confidence,
          blockId: blockId,
          lineId: lineId,
          recognizedLanguage: 'de',
        ),
      );
    }

    // Line 1: "Ich lerne Deutsch in Deutschland."
    addWord(rawText: 'Ich', cleanWord: 'Ich', pixelRect: const Rect.fromLTWH(100, 150, 60, 40), charIndex: 0);
    addWord(rawText: 'lerne', cleanWord: 'lerne', pixelRect: const Rect.fromLTWH(180, 150, 90, 40), charIndex: 4);
    addWord(rawText: 'Deutsch', cleanWord: 'Deutsch', pixelRect: const Rect.fromLTWH(290, 150, 130, 40), charIndex: 10);
    addWord(rawText: 'in', cleanWord: 'in', pixelRect: const Rect.fromLTWH(440, 150, 40, 40), charIndex: 18);
    addWord(rawText: 'Deutschland.', cleanWord: 'Deutschland', pixelRect: const Rect.fromLTWH(500, 150, 200, 40), charIndex: 21);

    // Line 2: "Wir haben viele neue „Möglichkeiten“."
    addWord(rawText: 'Wir', cleanWord: 'Wir', pixelRect: const Rect.fromLTWH(100, 230, 60, 40), charIndex: 34);
    addWord(rawText: 'haben', cleanWord: 'haben', pixelRect: const Rect.fromLTWH(180, 230, 90, 40), charIndex: 38);
    addWord(rawText: 'viele', cleanWord: 'viele', pixelRect: const Rect.fromLTWH(290, 230, 80, 40), charIndex: 44);
    addWord(rawText: 'neue', cleanWord: 'neue', pixelRect: const Rect.fromLTWH(390, 230, 70, 40), charIndex: 50);
    addWord(rawText: '„Möglichkeiten“.', cleanWord: 'Möglichkeit', pixelRect: const Rect.fromLTWH(480, 230, 240, 40), charIndex: 55);

    // Line 3: "Er »arbeitete!« den ganzen Tag."
    addWord(rawText: 'Er', cleanWord: 'Er', pixelRect: const Rect.fromLTWH(100, 310, 50, 40), charIndex: 72);
    addWord(rawText: '»arbeitete!«', cleanWord: 'arbeiten', pixelRect: const Rect.fromLTWH(170, 310, 190, 40), charIndex: 75);
    addWord(rawText: 'den', cleanWord: 'den', pixelRect: const Rect.fromLTWH(380, 310, 60, 40), charIndex: 88);
    addWord(rawText: 'ganzen', cleanWord: 'ganzen', pixelRect: const Rect.fromLTWH(460, 310, 110, 40), charIndex: 92);
    addWord(rawText: 'Tag.', cleanWord: 'Tag', pixelRect: const Rect.fromLTWH(590, 310, 70, 40), charIndex: 99);

    // Line 4: "Am Samstag spielen wir Fußball,"
    addWord(rawText: 'Am', cleanWord: 'Am', pixelRect: const Rect.fromLTWH(100, 390, 50, 40), charIndex: 104);
    addWord(rawText: 'Samstag', cleanWord: 'Samstag', pixelRect: const Rect.fromLTWH(170, 390, 120, 40), charIndex: 107);
    addWord(rawText: 'spielen', cleanWord: 'spielen', pixelRect: const Rect.fromLTWH(310, 390, 110, 40), charIndex: 115);
    addWord(rawText: 'wir', cleanWord: 'wir', pixelRect: const Rect.fromLTWH(440, 390, 60, 40), charIndex: 123);
    addWord(rawText: 'Fußball,', cleanWord: 'Fußball', pixelRect: const Rect.fromLTWH(520, 390, 130, 40), charIndex: 127);

    // Line 5: "und das Zimmer ist viel größer?"
    addWord(rawText: 'und', cleanWord: 'und', pixelRect: const Rect.fromLTWH(100, 470, 60, 40), charIndex: 136);
    addWord(rawText: 'das', cleanWord: 'das', pixelRect: const Rect.fromLTWH(180, 470, 60, 40), charIndex: 140);
    addWord(rawText: 'Zimmer', cleanWord: 'Zimmer', pixelRect: const Rect.fromLTWH(260, 470, 110, 40), charIndex: 144);
    addWord(rawText: 'ist', cleanWord: 'ist', pixelRect: const Rect.fromLTWH(390, 470, 50, 40), charIndex: 151);
    addWord(rawText: 'viel', cleanWord: 'viel', pixelRect: const Rect.fromLTWH(460, 470, 60, 40), charIndex: 155);
    addWord(rawText: 'größer?', cleanWord: 'größer', pixelRect: const Rect.fromLTWH(540, 470, 110, 40), charIndex: 160);

    // Line 6: "Das Mädchen liest Bücher."
    addWord(rawText: 'Das', cleanWord: 'Das', pixelRect: const Rect.fromLTWH(100, 550, 60, 40), charIndex: 168);
    addWord(rawText: 'Mädchen', cleanWord: 'Mädchen', pixelRect: const Rect.fromLTWH(180, 550, 130, 40), charIndex: 172);
    addWord(rawText: 'liest', cleanWord: 'liest', pixelRect: const Rect.fromLTWH(330, 550, 80, 40), charIndex: 180);
    addWord(rawText: 'Bücher.', cleanWord: 'Bücher', pixelRect: const Rect.fromLTWH(430, 550, 110, 40), charIndex: 186);

    // Line 7 & 8: Hyphenated compound word across line break: "Bundes-" on Line 7, "republik" on Line 8
    addWord(
      rawText: 'Bundes-',
      cleanWord: 'Bundes',
      pixelRect: const Rect.fromLTWH(100, 630, 120, 40),
      charIndex: 194,
      dehyphenatedCompound: 'Bundesrepublik',
      lineId: 'line_hyphen_1',
    );
    addWord(
      rawText: 'republik',
      cleanWord: 'republik',
      pixelRect: const Rect.fromLTWH(100, 690, 130, 40),
      charIndex: 202,
      dehyphenatedCompound: 'Bundesrepublik',
      lineId: 'line_hyphen_2',
    );

    // Line 9: Intentionally degraded low-confidence word for invariant test
    addWord(
      rawText: 'UnklarText',
      cleanWord: 'UnklarText',
      pixelRect: const Rect.fromLTWH(100, 770, 140, 40),
      charIndex: 211,
      confidence: 0.35, // Very low confidence
    );

    final fullText = words.map((w) => w.rawText).join(' ');

    return OcrPageResult(
      pageNumber: pageNumber,
      pageWidth: pageWidth,
      pageHeight: pageHeight,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      words: words,
      fullText: fullText,
      engineName: name,
      engineVersion: version,
      confidence: 0.94,
      recognizedAt: DateTime.now(),
    );
  }

  /// Page 2: Multi-Column Scanned Academic Page (Column A: Left, Column B: Right)
  OcrPageResult _buildMultiColumnPage({
    required int pageNumber,
    required double pageWidth,
    required double pageHeight,
    required int imageWidth,
    required int imageHeight,
  }) {
    final words = <WordOccurrence>[];

    void addWord({
      required String rawText,
      required String cleanWord,
      required Rect pixelRect,
      required int charIndex,
      String? dehyphenatedCompound,
      double? confidence = 0.96,
      String? blockId = 'col_left',
      String? lineId = 'line_1',
    }) {
      final pdfBox = coordinateMapper.mapPixelToPdfRect(
        pixelRect: pixelRect,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
        pageWidth: pageWidth,
        pageHeight: pageHeight,
      );

      final charWidth = (pdfBox.right - pdfBox.left) / rawText.length;
      final charRects = List.generate(
        rawText.length,
        (i) => PdfRect(
          pdfBox.left + i * charWidth,
          pdfBox.top,
          pdfBox.left + (i + 1) * charWidth,
          pdfBox.bottom,
        ),
      );

      words.add(
        WordOccurrence.ocr(
          rawText: rawText,
          cleanWord: cleanWord,
          pageBoundingBox: pdfBox,
          pageNumber: pageNumber,
          charIndex: charIndex,
          charLength: rawText.length,
          charRects: charRects,
          dehyphenatedCompound: dehyphenatedCompound,
          confidence: confidence,
          blockId: blockId,
          lineId: lineId,
          recognizedLanguage: 'de',
        ),
      );
    }

    // Column A (Left): X = 100 .. 450
    // Header: "Deutsche Zusammenfassung"
    addWord(rawText: 'Deutsche', cleanWord: 'Deutsche', pixelRect: const Rect.fromLTWH(100, 120, 140, 50), charIndex: 0, blockId: 'col_left');
    addWord(rawText: 'Zusammenfassung', cleanWord: 'Zusammenfassung', pixelRect: const Rect.fromLTWH(260, 120, 240, 50), charIndex: 9, blockId: 'col_left');

    // Body Left: "In dieser Arbeit untersuchen wir..."
    addWord(rawText: 'In', cleanWord: 'In', pixelRect: const Rect.fromLTWH(100, 200, 40, 35), charIndex: 25, blockId: 'col_left');
    addWord(rawText: 'dieser', cleanWord: 'dieser', pixelRect: const Rect.fromLTWH(150, 200, 90, 35), charIndex: 28, blockId: 'col_left');
    addWord(rawText: 'Arbeit', cleanWord: 'Arbeit', pixelRect: const Rect.fromLTWH(250, 200, 90, 35), charIndex: 35, blockId: 'col_left');
    addWord(rawText: 'untersuchen', cleanWord: 'untersuchen', pixelRect: const Rect.fromLTWH(350, 200, 150, 35), charIndex: 42, blockId: 'col_left');

    // Column B (Right): X = 600 .. 1000
    // Header: "Wissenschaftliche Methoden"
    addWord(rawText: 'Wissenschaftliche', cleanWord: 'Wissenschaftliche', pixelRect: const Rect.fromLTWH(620, 120, 230, 50), charIndex: 54, blockId: 'col_right');
    addWord(rawText: 'Methoden', cleanWord: 'Methoden', pixelRect: const Rect.fromLTWH(870, 120, 140, 50), charIndex: 72, blockId: 'col_right');

    // Body Right: "Experimentelle Analyse der Ergebnisse..."
    addWord(rawText: 'Experimentelle', cleanWord: 'Experimentelle', pixelRect: const Rect.fromLTWH(620, 200, 180, 35), charIndex: 81, blockId: 'col_right');
    addWord(rawText: 'Analyse', cleanWord: 'Analyse', pixelRect: const Rect.fromLTWH(820, 200, 100, 35), charIndex: 96, blockId: 'col_right');

    final fullText = words.map((w) => w.rawText).join(' ');

    return OcrPageResult(
      pageNumber: pageNumber,
      pageWidth: pageWidth,
      pageHeight: pageHeight,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      words: words,
      fullText: fullText,
      engineName: name,
      engineVersion: version,
      confidence: 0.95,
      recognizedAt: DateTime.now(),
    );
  }
}
