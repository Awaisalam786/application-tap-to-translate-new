// lib/features/reader/domain/word_reconstructor.dart

import 'package:pdfrx/pdfrx.dart';
import '../../../core/models/word_occurrence.dart';

/// Contract for reconstructing semantic German words and bounding boxes
/// from raw page text and character vectors.
abstract class WordReconstructor {
  List<WordOccurrence> reconstructWords(PdfPageText pageText);
}

/// Production implementation of [WordReconstructor].
///
/// Features proven in the geometry gate:
/// 1. Per-character glyph box union.
/// 2. Merging split text items with contiguous bounding boxes.
/// 3. Isolating clean German lemmas from punctuation and quotes.
/// 4. Line-break de-hyphenation for compound German words.
class GermanWordReconstructor implements WordReconstructor {
  const GermanWordReconstructor();

  @override
  List<WordOccurrence> reconstructWords(PdfPageText pageText) {
    final rawWords = <WordOccurrence>[];
    final text = pageText.fullText;
    final rects = pageText.charRects;

    int i = 0;
    while (i < text.length) {
      if (_isWhitespace(text[i])) {
        i++;
        continue;
      }

      final startIdx = i;
      final charBoxes = <PdfRect>[];

      while (i < text.length && !_isWhitespace(text[i])) {
        if (i < rects.length && rects[i].isNotEmpty) {
          charBoxes.add(rects[i]);
        }
        i++;
      }

      final rawToken = text.substring(startIdx, i);
      final cleanWord = extractCleanWord(rawToken);

      if (charBoxes.isNotEmpty) {
        PdfRect unionBox = charBoxes.first;
        for (int k = 1; k < charBoxes.length; k++) {
          unionBox = unionBox.merge(charBoxes[k]);
        }

        rawWords.add(WordOccurrence(
          rawText: rawToken,
          cleanWord: cleanWord.isNotEmpty ? cleanWord : rawToken,
          pageBoundingBox: unionBox,
          pageNumber: pageText.pageNumber,
          charIndex: startIdx,
          charLength: i - startIdx,
          charRects: charBoxes,
          source: WordSource.digitalPdf,
        ));
      }
    }

    // Step 2: Merge split text items (e.g. "Deutsch" + "land" on same baseline with 0 gap)
    final mergedWords = <WordOccurrence>[];
    int j = 0;
    while (j < rawWords.length) {
      if (j < rawWords.length - 1) {
        final w1 = rawWords[j];
        final w2 = rawWords[j + 1];

        // Same horizontal line and gap is virtually zero (< 1.5 pt)
        final yDiff = (w1.pageBoundingBox.bottom - w2.pageBoundingBox.bottom).abs();
        final gap = w2.pageBoundingBox.left - w1.pageBoundingBox.right;

        if (yDiff < 2.0 && gap >= -0.5 && gap < 1.5) {
          final combinedRaw = w1.rawText + w2.rawText;
          final combinedClean = w1.cleanWord + w2.cleanWord;
          final combinedBox = w1.pageBoundingBox.merge(w2.pageBoundingBox);
          final combinedChars = [...w1.charRects, ...w2.charRects];

          mergedWords.add(WordOccurrence(
            rawText: combinedRaw,
            cleanWord: combinedClean,
            pageBoundingBox: combinedBox,
            pageNumber: w1.pageNumber,
            charIndex: w1.charIndex,
            charLength: w1.charLength + w2.charLength,
            charRects: combinedChars,
            source: WordSource.digitalPdf,
          ));
          j += 2;
          continue;
        }
      }
      mergedWords.add(rawWords[j]);
      j++;
    }

    // Step 3: Handle hyphenated line wraps (e.g. "Bundes-" on line 1, "republik" on line 2)
    final finalizedWords = <WordOccurrence>[];
    for (int k = 0; k < mergedWords.length; k++) {
      final current = mergedWords[k];
      String? compoundLemma;

      if (current.rawText.endsWith('-') && k < mergedWords.length - 1) {
        final next = mergedWords[k + 1];
        // Vertical drop indicates a line wrap
        final isNextLine = (current.pageBoundingBox.bottom - next.pageBoundingBox.bottom) > 8.0;
        if (isNextLine) {
          final basePart = current.cleanWord;
          final nextPart = next.cleanWord;
          compoundLemma = basePart + nextPart;
        }
      }

      if (compoundLemma != null) {
        finalizedWords.add(WordOccurrence(
          rawText: current.rawText,
          cleanWord: current.cleanWord,
          pageBoundingBox: current.pageBoundingBox,
          pageNumber: current.pageNumber,
          charIndex: current.charIndex,
          charLength: current.charLength,
          charRects: current.charRects,
          source: current.source,
          dehyphenatedCompound: compoundLemma,
        ));
      } else {
        finalizedWords.add(current);
      }
    }

    return finalizedWords;
  }

  /// Treats ASCII control codes <= 32 (including \x02 PDFium soft-hyphen, \n, \r, \t, space)
  /// as whitespace delimiters.
  static bool _isWhitespace(String ch) => ch.codeUnitAt(0) <= 32;

  static final _trimRegex = RegExp(
    r'^[\s\.,;:!?\(\)\[\]\{\}„“‚‘”»«›‹\x22\x27—\-_/\\+]+|[\s\.,;:!?\(\)\[\]\{\}„“‚‘”»«›‹\x22\x27—\-_/\\+]+$',
  );

  static String extractCleanWord(String text) {
    return text.replaceAll(_trimRegex, '');
  }
}
