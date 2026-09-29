// lib/features/reader/domain/selection_resolver.dart

import 'package:flutter/widgets.dart';
import 'package:pdfrx/pdfrx.dart';
import '../../../core/coordinates/coordinate_mapper.dart';
import '../../../core/models/selection_result.dart';
import 'exact_hit_tester.dart';
import 'word_spatial_index.dart';

/// Top-level coordinator that accepts raw Flutter viewport tap events
/// and resolves them through the exact selection pipeline.
class SelectionResolver {
  final CoordinateMapper coordinateMapper;
  final ExactHitTester hitTester;

  const SelectionResolver({
    this.coordinateMapper = const PdfrxCoordinateMapper(),
    this.hitTester = const ProductionExactHitTester(),
  });

  /// Resolves a screen tap event at [localTapOffset] into a [SelectionResult].
  ///
  /// Requires the [pageIndices] map holding pre-extracted [WordSpatialIndex] per page.
  SelectionResult? resolveTap({
    required Offset localTapOffset,
    required BuildContext context,
    required PdfViewerController controller,
    required Map<int, WordSpatialIndex> pageIndices,
  }) {
    // Step 1: Map screen tap to PDF page coordinates
    final hitTestResult = coordinateMapper.screenToPage(
      localScreenOffset: localTapOffset,
      context: context,
      controller: controller,
    );

    if (hitTestResult == null) {
      debugPrint('[TAP_PIPELINE] physical tap at viewport: $localTapOffset -> outside PDF page');
      return null;
    }

    final pageNumber = hitTestResult.page.pageNumber;
    final pdfPoint = hitTestResult.offset;
    debugPrint('[TAP_PIPELINE] 1. Physical tap viewport coordinate: $localTapOffset');
    debugPrint('[TAP_PIPELINE] 2. Mapped to PDF coordinate: (${pdfPoint.x.toStringAsFixed(2)}, ${pdfPoint.y.toStringAsFixed(2)}) on Page $pageNumber');

    // Step 2: Retrieve the spatial index for this page
    final spatialIndex = pageIndices[pageNumber];
    if (spatialIndex == null) {
      debugPrint('[TAP_PIPELINE] 3. Spatial index missing for page $pageNumber');
      return SelectionResult.whitespace(
        screenTapOffset: localTapOffset,
        pdfTapPoint: pdfPoint,
        pageNumber: pageNumber,
      );
    }
    debugPrint('[TAP_PIPELINE] 3. Spatial index retrieved: ${spatialIndex.words.length} WordOccurrences on page $pageNumber');

    // Step 3: Run exact hit-testing
    final hitResult = hitTester.hitTest(
      pdfPoint: pdfPoint,
      screenOffset: localTapOffset,
      spatialIndex: spatialIndex,
    );

    if (hitResult.status == SelectionStatus.exactMatch && hitResult.word != null) {
      final w = hitResult.word!;
      debugPrint('[TAP_PIPELINE] 4. OCR WordOccurrence matched: "${w.cleanWord}" (isOcr: ${w.isOcr}, BBox: ${w.pageBoundingBox}, conf: ${w.confidence?.toStringAsFixed(2) ?? "N/A"})');
      debugPrint('[TAP_PIPELINE] 5. ExactHitTester -> SelectionResult: status=${hitResult.status}, word="${w.cleanWord}"');
    } else {
      debugPrint('[TAP_PIPELINE] 4. ExactHitTester evaluated -> SelectionResult: status=${hitResult.status} (ZERO nearest-word fallback)');
    }

    return hitResult;
  }
}
