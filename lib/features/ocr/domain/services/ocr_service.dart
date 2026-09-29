// lib/features/ocr/domain/services/ocr_service.dart

import 'dart:typed_data';
import '../models/ocr_page_result.dart';
import '../repositories/ocr_cache.dart';
import '../repositories/ocr_provider.dart';

/// Orchestrates lazy page-by-page OCR execution with offline caching.
///
/// PERFORMANCE & OFFLINE INVARIANT:
/// 1. Lazy evaluation: Never processes entire 500-page books upfront. Only processes
///    the active/viewed page when requested.
/// 2. Cache check first: If an OCR result exists in [OcrCache], returns immediately
///    without invoking the CPU/GPU recognition engine.
/// 3. Zero network requirement: All processing is local and deterministic.
class OcrService {
  final OcrProvider provider;
  final OcrCache cache;

  const OcrService({
    required this.provider,
    required this.cache,
  });

  /// Processes OCR for a single page, querying cache first.
  Future<OcrPageResult> processPage({
    required String documentId,
    required int pageNumber,
    required double pageWidth,
    required double pageHeight,
    String? imagePath,
    Uint8List? imageBytes,
    int? imageWidth,
    int? imageHeight,
    String? languageHint = 'de',
  }) async {
    // 1. Check persistent/in-memory cache
    final cached = await cache.get(
      documentId: documentId,
      pageNumber: pageNumber,
      providerName: provider.name,
      providerVersion: provider.version,
    );

    if (cached != null) {
      return cached;
    }

    // 2. Perform OCR on demand
    OcrPageResult result;
    if (imageBytes != null && imageWidth != null && imageHeight != null) {
      result = await provider.recognizeImageBytes(
        pageNumber: pageNumber,
        pageWidth: pageWidth,
        pageHeight: pageHeight,
        imageBytes: imageBytes,
        imageWidth: imageWidth,
        imageHeight: imageHeight,
        languageHint: languageHint,
      );
    } else {
      result = await provider.recognizePageImage(
        pageNumber: pageNumber,
        pageWidth: pageWidth,
        pageHeight: pageHeight,
        imagePath: imagePath ?? '',
        languageHint: languageHint,
      );
    }

    // 3. Cache the result for subsequent instant offline access
    await cache.put(documentId: documentId, result: result);
    return result;
  }
}
