// lib/core/models/page_geometry.dart

import 'package:pdfrx/pdfrx.dart';
import 'word_occurrence.dart';

/// Cached geometry and word segmentation data for a single PDF page.
class PageGeometry {
  final int pageNumber;
  final double width;
  final double height;
  final PdfPageRotation rotation;
  final String fullText;
  final List<PdfRect> charRects;
  final List<WordOccurrence> words;

  const PageGeometry({
    required this.pageNumber,
    required this.width,
    required this.height,
    required this.rotation,
    required this.fullText,
    required this.charRects,
    required this.words,
  });

  bool get isEmpty => words.isEmpty;
  bool get isNotEmpty => words.isNotEmpty;
}
