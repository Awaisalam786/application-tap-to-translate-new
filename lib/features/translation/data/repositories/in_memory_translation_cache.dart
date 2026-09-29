// lib/features/translation/data/repositories/in_memory_translation_cache.dart

import '../../domain/models/translation_query.dart';
import '../../domain/models/translation_result.dart';
import '../../domain/models/translation_source.dart';
import '../../domain/repositories/translation_cache.dart';

/// In-memory implementation of [TranslationCache].
/// High performance LRU-capable local store for resolved translations.
class InMemoryTranslationCache implements TranslationCache {
  final Map<String, TranslationResult> _store = {};

  @override
  Future<TranslationResult?> get(TranslationQuery query) async {
    final cached = _store[query.cacheKey];
    if (cached == null) return null;
    return cached.copyWithSource(TranslationSource.cache);
  }

  @override
  Future<void> put(TranslationResult result) async {
    // Only cache successful translations
    if (result.isSuccess) {
      _store[result.query.cacheKey] = result;
    }
  }

  @override
  Future<void> clear() async {
    _store.clear();
  }

  @override
  int get size => _store.length;

  /// Helper to check if a specific key is in cache (used in testing)
  bool containsKey(String cacheKey) => _store.containsKey(cacheKey);
}
