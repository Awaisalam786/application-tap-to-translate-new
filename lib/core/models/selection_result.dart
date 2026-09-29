// lib/core/models/selection_result.dart

import 'package:flutter/widgets.dart';
import 'package:pdfrx/pdfrx.dart';
import 'word_occurrence.dart';

/// The status classification of an exact tap interaction.
enum SelectionStatus {
  /// Exactly one candidate was hit. Word successfully identified.
  exactMatch,

  /// Tap fell in whitespace, page margin, or empty area.
  whitespace,

  /// Tap fell in the gap between adjacent words or lines.
  /// Strictly null per the zero-nearest-word policy.
  interWordGap,

  /// Tap fell in a region where multiple word bounding boxes collide.
  /// Strictly null to avoid ambiguous selection.
  ambiguous,

  /// Tap fell on an OCR word that is below the confidence threshold.
  /// Strictly null to avoid unreliable lookups.
  lowConfidence,
}

/// The immutable result of a hit-test operation.
class SelectionResult {
  /// The resolved word occurrence, or null if ambiguous, gap, or whitespace.
  final WordOccurrence? word;

  /// The classification status of this selection attempt.
  final SelectionStatus status;

  /// The local screen offset where the user tapped.
  final Offset screenTapOffset;

  /// The mapped PDF point (bottom-left origin, 72 pt/inch) corresponding to the tap.
  final PdfPoint pdfTapPoint;

  /// 1-based page number where the hit-test was evaluated.
  final int pageNumber;

  /// All candidates that intersected the tap point (empty, 1, or >1).
  final List<WordOccurrence> candidateWords;

  const SelectionResult({
    required this.word,
    required this.status,
    required this.screenTapOffset,
    required this.pdfTapPoint,
    required this.pageNumber,
    this.candidateWords = const [],
  });

  /// Factory for a successful, unambiguous exact word hit.
  factory SelectionResult.exact({
    required WordOccurrence word,
    required Offset screenTapOffset,
    required PdfPoint pdfTapPoint,
    required int pageNumber,
  }) {
    return SelectionResult(
      word: word,
      status: SelectionStatus.exactMatch,
      screenTapOffset: screenTapOffset,
      pdfTapPoint: pdfTapPoint,
      pageNumber: pageNumber,
      candidateWords: [word],
    );
  }

  /// Factory for an inter-word gap tap (strictly null).
  factory SelectionResult.gap({
    required Offset screenTapOffset,
    required PdfPoint pdfTapPoint,
    required int pageNumber,
  }) {
    return SelectionResult(
      word: null,
      status: SelectionStatus.interWordGap,
      screenTapOffset: screenTapOffset,
      pdfTapPoint: pdfTapPoint,
      pageNumber: pageNumber,
    );
  }

  /// Factory for a whitespace margin tap (strictly null).
  factory SelectionResult.whitespace({
    required Offset screenTapOffset,
    required PdfPoint pdfTapPoint,
    required int pageNumber,
  }) {
    return SelectionResult(
      word: null,
      status: SelectionStatus.whitespace,
      screenTapOffset: screenTapOffset,
      pdfTapPoint: pdfTapPoint,
      pageNumber: pageNumber,
    );
  }

  /// Factory for ambiguous overlapping candidates (strictly null).
  factory SelectionResult.ambiguous({
    required Offset screenTapOffset,
    required PdfPoint pdfTapPoint,
    required int pageNumber,
    required List<WordOccurrence> candidates,
  }) {
    return SelectionResult(
      word: null,
      status: SelectionStatus.ambiguous,
      screenTapOffset: screenTapOffset,
      pdfTapPoint: pdfTapPoint,
      pageNumber: pageNumber,
      candidateWords: candidates,
    );
  }

  /// Factory for low-confidence OCR word taps (strictly null).
  factory SelectionResult.lowConfidence({
    required Offset screenTapOffset,
    required PdfPoint pdfTapPoint,
    required int pageNumber,
    required WordOccurrence candidate,
  }) {
    return SelectionResult(
      word: null,
      status: SelectionStatus.lowConfidence,
      screenTapOffset: screenTapOffset,
      pdfTapPoint: pdfTapPoint,
      pageNumber: pageNumber,
      candidateWords: [candidate],
    );
  }
}
