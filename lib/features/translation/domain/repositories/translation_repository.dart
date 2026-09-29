// lib/features/translation/domain/repositories/translation_repository.dart

import '../models/translation_query.dart';
import '../models/translation_result.dart';

/// Top-level contract for resolving translations.
abstract class TranslationRepository {
  /// Resolves a translation query through the defined lookup hierarchy:
  /// 1. Local German Lexicon
  /// 2. Local Translation Cache
  /// 3. Optional Online Provider
  /// 4. Cache successful result
  ///
  /// If no result exists in any tier:
  /// Returns explicit [TranslationStatus.notFound] (never invents translations).
  Future<TranslationResult> translate(TranslationQuery query);
}
