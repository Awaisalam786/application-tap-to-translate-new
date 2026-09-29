// lib/features/ocr/data/repositories/in_memory_ocr_cache.dart

import '../../domain/models/ocr_page_result.dart';
import '../../domain/repositories/ocr_cache.dart';

/// Fast in-memory implementation of [OcrCache].
class InMemoryOcrCache implements OcrCache {
  final Map<String, OcrPageResult> _cache = {};

  String _buildKey(String documentId, int pageNumber, String provider, String version) {
    return '$documentId:p$pageNumber:$provider:$version';
  }

  @override
  Future<OcrPageResult?> get({
    required String documentId,
    required int pageNumber,
    required String providerName,
    required String providerVersion,
  }) async {
    final key = _buildKey(documentId, pageNumber, providerName, providerVersion);
    return _cache[key];
  }

  @override
  Future<void> put({
    required String documentId,
    required OcrPageResult result,
  }) async {
    final key = _buildKey(
      documentId,
      result.pageNumber,
      result.engineName,
      result.engineVersion,
    );
    _cache[key] = result;
  }

  @override
  Future<bool> contains({
    required String documentId,
    required int pageNumber,
    required String providerName,
    required String providerVersion,
  }) async {
    final key = _buildKey(documentId, pageNumber, providerName, providerVersion);
    return _cache.containsKey(key);
  }

  @override
  Future<void> invalidateDocument(String documentId) async {
    final prefix = '$documentId:';
    _cache.removeWhere((k, _) => k.startsWith(prefix));
  }

  @override
  Future<void> clear() async {
    _cache.clear();
  }

  /// The number of page results currently cached.
  int get entryCount => _cache.length;
}
