import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../core/models/word_occurrence.dart';
import '../../domain/models/ocr_page_result.dart';
import '../../domain/repositories/ocr_provider.dart';
import '../ocr_coordinate_mapper.dart';

/// Production adapter for Google ML Kit Text Recognition (On-Device Mobile Vision).
///
/// PLATFORM SPECIFICATION:
/// - Runtime: Android (minSdkVersion 21+) and iOS (iOS 15.5+).
/// - License: Apache 2.0 (google_mlkit_text_recognition).
/// - Privacy: 100% on-device local execution; zero network transmission; zero paid API keys.
/// - Language: Latin script recognizing standard German orthography (ä, ö, ü, Ä, Ö, Ü, ß).
///
/// NOTE ON DESKTOP & TESTING:
/// Google ML Kit is a mobile-only native binary (Android C++ / iOS Framework).
/// This adapter executes native ML Kit channels when running on physical Android/iOS devices,
/// and throws [UnsupportedError] when invoked on desktop Windows or CI test environments.
class GoogleMlKitOcrAdapter implements OcrProvider {
  final OcrCoordinateMapper coordinateMapper;
  @override
  final bool isAvailable;

  const GoogleMlKitOcrAdapter({
    this.coordinateMapper = const OcrCoordinateMapper(),
    this.isAvailable = true,
  });

  @override
  String get name => 'Google ML Kit On-Device Text Recognition';

  @override
  String get version => '0.17.1-latin';

  @override
  Future<OcrPageResult> recognizePageImage({
    required int pageNumber,
    required double pageWidth,
    required double pageHeight,
    required String imagePath,
    String? languageHint,
  }) async {
    if (!isAvailable || (!Platform.isAndroid && !Platform.isIOS)) {
      throw UnsupportedError(
        'Google ML Kit is only available on physical Android or iOS devices. '
        'Use MockGermanOcrProvider for Windows desktop execution and CI unit testing.',
      );
    }

    final file = File(imagePath);
    if (!await file.exists()) {
      throw ArgumentError('Image file does not exist at path: $imagePath');
    }

    // Decode image dimensions to accurately map pixels to PDF coordinates
    final bytes = await file.readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frameInfo = await codec.getNextFrame();
    final imageWidth = frameInfo.image.width;
    final imageHeight = frameInfo.image.height;
    frameInfo.image.dispose();

    final inputImage = InputImage.fromFilePath(imagePath);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    debugPrint('[ML_KIT_EXEC] Google ML Kit processImage() starting for Page $pageNumber ($imageWidth x $imageHeight px), file: $imagePath');
    final stopwatch = Stopwatch()..start();

    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      stopwatch.stop();
      debugPrint('[ML_KIT_EXEC] Google ML Kit processImage() executed successfully in ${stopwatch.elapsedMilliseconds}ms');
      return _convertMlKitResult(
        recognizedText: recognizedText,
        pageNumber: pageNumber,
        pageWidth: pageWidth,
        pageHeight: pageHeight,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
      );
    } finally {
      await textRecognizer.close();
    }
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
    final tempDir = await getTemporaryDirectory();
    final tempFile = File(
      '${tempDir.path}/ocr_bytes_${pageNumber}_${DateTime.now().microsecondsSinceEpoch}.png',
    );
    await tempFile.writeAsBytes(imageBytes, flush: true);
    try {
      return await recognizePageImage(
        pageNumber: pageNumber,
        pageWidth: pageWidth,
        pageHeight: pageHeight,
        imagePath: tempFile.path,
        languageHint: languageHint,
      );
    } finally {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  OcrPageResult _convertMlKitResult({
    required RecognizedText recognizedText,
    required int pageNumber,
    required double pageWidth,
    required double pageHeight,
    required int imageWidth,
    required int imageHeight,
  }) {
    final words = <WordOccurrence>[];
    int charIndex = 0;
    double totalConfidence = 0.0;
    int confidenceCount = 0;

    int blockIndex = 0;
    for (final block in recognizedText.blocks) {
      final blockId = 'block_$blockIndex';
      blockIndex++;

      int lineIndex = 0;
      for (int i = 0; i < block.lines.length; i++) {
        final line = block.lines[i];
        final lineId = '${blockId}_line_$lineIndex';
        lineIndex++;

        // De-hyphenation detection between lines
        String? dehyphenatedPrefix;
        if (line.text.trim().endsWith('-') && i + 1 < block.lines.length) {
          final nextLine = block.lines[i + 1];
          final nextFirstWord = nextLine.elements.isNotEmpty ? nextLine.elements.first.text : '';
          final lineTrimmed = line.text.trim();
          final prefix = lineTrimmed.substring(0, lineTrimmed.length - 1).split(' ').last;
          if (prefix.isNotEmpty && nextFirstWord.isNotEmpty) {
            dehyphenatedPrefix = prefix + nextFirstWord;
          }
        }

        for (int elIdx = 0; elIdx < line.elements.length; elIdx++) {
          final element = line.elements[elIdx];
          final rawText = element.text;
          if (rawText.trim().isEmpty) continue;

          final pixelRect = element.boundingBox;
          final pdfBox = coordinateMapper.mapPixelToPdfRect(
            pixelRect: pixelRect,
            imageWidth: imageWidth,
            imageHeight: imageHeight,
            pageWidth: pageWidth,
            pageHeight: pageHeight,
          );

          final cleanWord = rawText.replaceAll(
            RegExp(r'^[„“"«»›‹.,;:!?\(\)\[\]]+|[„“"«»›‹.,;:!?\(\)\[\]]+$'),
            '',
          );

          final confidence = line.confidence ?? 0.95;
          totalConfidence += confidence;
          confidenceCount++;

          String? dehyphenated;
          if (elIdx == line.elements.length - 1 && dehyphenatedPrefix != null) {
            dehyphenated = dehyphenatedPrefix;
          }

          words.add(
            WordOccurrence.ocr(
              rawText: rawText,
              cleanWord: cleanWord,
              pageBoundingBox: pdfBox,
              pageNumber: pageNumber,
              charIndex: charIndex,
              charLength: rawText.length,
              confidence: confidence,
              blockId: blockId,
              lineId: lineId,
              dehyphenatedCompound: dehyphenated,
              recognizedLanguage: 'de',
            ),
          );

          charIndex += rawText.length + 1;
        }
      }
    }

    final avgConfidence = confidenceCount > 0 ? (totalConfidence / confidenceCount) : 0.90;

    int totalLines = 0;
    int totalElements = 0;
    for (final b in recognizedText.blocks) {
      totalLines += b.lines.length;
      for (final l in b.lines) {
        totalElements += l.elements.length;
      }
    }

    debugPrint('==================== [REAL GOOGLE ML KIT OCR DATA] ====================');
    debugPrint('[ML_KIT_PAGE] Page: $pageNumber');
    debugPrint('[ML_KIT_DIMS] Image Dimensions: ${imageWidth}x$imageHeight px | PDF Page: ${pageWidth.toStringAsFixed(1)}x${pageHeight.toStringAsFixed(1)} pt');
    debugPrint('[ML_KIT_COUNTS] Blocks: ${recognizedText.blocks.length} | Lines: $totalLines | Elements: $totalElements | Words: ${words.length}');
    debugPrint('[ML_KIT_CONFIDENCE] Average Confidence: ${(avgConfidence * 100).toStringAsFixed(1)}%');
    final wordTokens = words.map((w) => w.cleanWord).where((w) => w.isNotEmpty).toList();
    debugPrint('[ML_KIT_WORDS] Total recognized: ${wordTokens.length}');
    debugPrint('[ML_KIT_WORDS_SAMPLE] First 20: ${wordTokens.take(20).join(", ")}');

    // Diagnostic log for target words specified in task 7
    final targetWords = ['Deutsches', 'Deutschland', 'Möglichkeiten', 'Fußball', 'Mädchen', 'groß', 'Bundes'];
    for (final target in targetWords) {
      final matches = words.where((w) => w.cleanWord == target || w.rawText.contains(target));
      for (final m in matches) {
        debugPrint('[ML_KIT_TARGET_WORD] "${m.cleanWord}" (Raw: "${m.rawText}") -> PDF BBox: (${m.pageBoundingBox.left.toStringAsFixed(1)}, ${m.pageBoundingBox.top.toStringAsFixed(1)}, ${m.pageBoundingBox.width.toStringAsFixed(1)}, ${m.pageBoundingBox.height.toStringAsFixed(1)}) | Confidence: ${m.confidence?.toStringAsFixed(2) ?? "N/A"}');
      }
    }
    debugPrint('========================================================================');

    return OcrPageResult(
      pageNumber: pageNumber,
      pageWidth: pageWidth,
      pageHeight: pageHeight,
      imageWidth: imageWidth,
      imageHeight: imageHeight,
      words: words,
      fullText: recognizedText.text,
      engineName: name,
      engineVersion: version,
      confidence: avgConfidence,
      recognizedAt: DateTime.now(),
    );
  }
}
