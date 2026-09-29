// lib/features/reader/domain/exact_hit_tester.dart

import 'package:flutter/widgets.dart';
import 'package:pdfrx/pdfrx.dart';
import '../../../core/models/selection_result.dart';
import 'word_spatial_index.dart';

/// Contract for exact hit-testing against a page spatial index.
abstract class ExactHitTester {
  SelectionResult hitTest({
    required PdfPoint pdfPoint,
    required Offset screenOffset,
    required WordSpatialIndex spatialIndex,
  });
}

/// Production implementation of [ExactHitTester].
///
/// Invariant:
/// - Exactly 1 candidate -> exact match (if confidence >= minConfidenceThreshold).
/// - 0 candidates -> null (whitespace or inter-word gap).
/// - >1 candidates -> null (ambiguous).
/// - Confidence < minConfidenceThreshold -> null (low confidence rejected).
/// - ZERO nearest-word fallback.
class ProductionExactHitTester implements ExactHitTester {
  final double minConfidenceThreshold;

  const ProductionExactHitTester({
    this.minConfidenceThreshold = 0.50,
  });

  @override
  SelectionResult hitTest({
    required PdfPoint pdfPoint,
    required Offset screenOffset,
    required WordSpatialIndex spatialIndex,
  }) {
    final matches = spatialIndex.queryPoint(pdfPoint);

    if (matches.length == 1) {
      final candidate = matches.first;
      if (candidate.confidence != null && candidate.confidence! < minConfidenceThreshold) {
        return SelectionResult.lowConfidence(
          screenTapOffset: screenOffset,
          pdfTapPoint: pdfPoint,
          pageNumber: spatialIndex.pageNumber,
          candidate: candidate,
        );
      }

      return SelectionResult.exact(
        word: candidate,
        screenTapOffset: screenOffset,
        pdfTapPoint: pdfPoint,
        pageNumber: spatialIndex.pageNumber,
      );
    }

    if (matches.length > 1) {
      // Multiple bounding boxes claim this point (e.g. overlapping runs).
      // Return null per the strict fail-safe specification.
      return SelectionResult.ambiguous(
        screenTapOffset: screenOffset,
        pdfTapPoint: pdfPoint,
        pageNumber: spatialIndex.pageNumber,
        candidates: matches,
      );
    }

    // Zero matches: determine whether the tap fell between words on a line
    // or in empty page whitespace / margins.
    final lineCandidates = spatialIndex.words.where(
      (w) => pdfPoint.y >= w.pageBoundingBox.bottom && pdfPoint.y <= w.pageBoundingBox.top,
    ).toList();

    if (lineCandidates.length >= 2) {
      lineCandidates.sort((a, b) => a.pageBoundingBox.left.compareTo(b.pageBoundingBox.left));
      for (var i = 0; i < lineCandidates.length - 1; i++) {
        final leftWord = lineCandidates[i];
        final rightWord = lineCandidates[i + 1];
        if (pdfPoint.x >= leftWord.pageBoundingBox.right && pdfPoint.x <= rightWord.pageBoundingBox.left) {
          return SelectionResult.gap(
            screenTapOffset: screenOffset,
            pdfTapPoint: pdfPoint,
            pageNumber: spatialIndex.pageNumber,
          );
        }
      }
    }

    return SelectionResult.whitespace(
      screenTapOffset: screenOffset,
      pdfTapPoint: pdfPoint,
      pageNumber: spatialIndex.pageNumber,
    );
  }
}
