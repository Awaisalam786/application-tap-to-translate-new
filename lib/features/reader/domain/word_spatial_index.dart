// lib/features/reader/domain/word_spatial_index.dart

import 'package:pdfrx/pdfrx.dart';
import '../../../core/models/word_occurrence.dart';

/// In-memory spatial index of reconstructed words for a single PDF page.
class WordSpatialIndex {
  final int pageNumber;
  final List<WordOccurrence> words;

  const WordSpatialIndex({
    required this.pageNumber,
    required this.words,
  });

  /// Finds all word occurrences whose bounding box strictly encloses the given [point]
  /// in PDF page coordinates.
  List<WordOccurrence> queryPoint(PdfPoint point) {
    final matches = <WordOccurrence>[];
    for (final word in words) {
      if (word.pageBoundingBox.containsPoint(point)) {
        matches.add(word);
      }
    }
    return matches;
  }

  /// Finds all word occurrences overlapping a given PDF rectangle.
  List<WordOccurrence> queryRect(PdfRect rect) {
    final matches = <WordOccurrence>[];
    for (final word in words) {
      if (word.pageBoundingBox.overlaps(rect)) {
        matches.add(word);
      }
    }
    return matches;
  }
}
