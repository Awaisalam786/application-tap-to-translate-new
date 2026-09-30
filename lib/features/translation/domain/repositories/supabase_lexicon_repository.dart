// lib/features/translation/domain/repositories/supabase_lexicon_repository.dart

import '../models/translation_query.dart';
import '../models/translation_result.dart';
import '../models/translation_target_language.dart';

/// Contract for the shared Supabase Central Lexicon (Tier 3 fallback).
///
/// Invariants:
/// 1. Provides cross-user translation sharing for previously online-translated words.
/// 2. Saves are performed asynchronously without blocking the user.
/// 3. Failed network/database calls must never disrupt the local translation pipeline.
/// 4. Online machine-generated words are stored with status = MACHINE_GENERATED.
abstract class SupabaseLexiconRepository {
  /// Whether the Supabase central repository is configured and reachable.
  bool get isAvailable;

  /// Looks up a word in the central Supabase lexicon or central cache.
  /// Returns `null` if the word is not found or if the network is unreachable.
  Future<TranslationResult?> lookup({
    required String normalizedWord,
    required TranslationTargetLanguage targetLanguage,
    required TranslationQuery query,
  });

  /// Asynchronously saves an online-translated result to the central lexicon.
  ///
  /// Upserts the entry to prevent duplicates when multiple users look up the same word.
  /// Returns `true` if saved successfully, `false` otherwise.
  Future<bool> saveTranslation({
    required TranslationResult result,
    required String providerName,
  });

  /// Logs a translation request for analytics and vocabulary gap analysis.
  Future<void> logRequest({
    required TranslationQuery query,
    required String providerName,
    required String status,
    String? result,
  });
}
