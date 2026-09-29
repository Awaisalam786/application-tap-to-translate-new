// lib/features/ocr/domain/repositories/ocr_cache.dart

import '../models/ocr_page_result.dart';

/// Contract for persistent and in-memory caching of OCR results.
///
/// Ensures that once a scanned PDF page is recognized, subsequent page opens
/// are instant and completely offline without re-running CPU/GPU-intensive OCR.
abstract class OcrCache {
  /// Retrieves a previously cached OCR page result.
  ///
  /// Returns `null` if no matching cached result exists for this document,
  /// page number, and engine version.
  Future<OcrPageResult?> get({
    required String documentId,
    required int pageNumber,
    required String providerName,
    required String providerVersion,
  });

  /// Stores an OCR page result into the cache.
  Future<void> put({
    required String documentId,
    required OcrPageResult result,
  });

  /// Checks if a valid cached OCR result exists for the specified page.
  Future<bool> contains({
    required String documentId,
    required int pageNumber,
    required String providerName,
    required String providerVersion,
  });

  /// Invalidates cached OCR results for a specific document.
  Future<void> invalidateDocument(String documentId);

  /// Clears all cached OCR results.
  Future<void> clear();
}
