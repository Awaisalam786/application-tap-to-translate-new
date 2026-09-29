// lib/features/translation/domain/repositories/translation_cache.dart

import '../models/translation_query.dart';
import '../models/translation_result.dart';

/// Contract for caching resolved translations locally on device.
abstract class TranslationCache {
  /// Fetches a cached translation for the query, or returns `null` on cache miss.
  Future<TranslationResult?> get(TranslationQuery query);

  /// Stores a resolved translation in the cache.
  Future<void> put(TranslationResult result);

  /// Evicts all cached entries.
  Future<void> clear();

  /// Total count of cached entries.
  int get size;
}
