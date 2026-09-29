// lib/features/translation/domain/repositories/online_translation_provider.dart

import '../models/translation_query.dart';
import '../models/translation_result.dart';

/// Contract for an optional online translation fallback provider.
///
/// ARCHITECTURAL INVARIANT:
/// 1. The core application must NEVER depend on a mandatory or paid online API.
/// 2. If the user is offline, or if no online provider is configured, the application
///    operates completely autonomously using the local offline lexicon.
abstract class OnlineTranslationProvider {
  /// Whether the online provider is enabled, configured, and network-reachable.
  bool get isAvailable;

  /// Translates a query using an online service (e.g. self-hosted LibreTranslate,
  /// open dictionary APIs, etc.).
  /// Returns `null` if unable to resolve or network fails.
  Future<TranslationResult?> translate(TranslationQuery query);
}
