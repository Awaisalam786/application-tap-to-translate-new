// lib/features/translation/domain/models/translation_source.dart

/// Provenance of the resolved translation.
enum TranslationSource {
  /// Deterministic local offline German lexicon/dictionary.
  localLexicon,

  /// Local on-device persistent or in-memory cache.
  cache,

  /// Central Supabase lexicon shared across all users.
  supabaseCentralLexicon,

  /// Optional network fallback provider (e.g. libretranslate/mymemory/external).
  onlineFallback,

  /// No translation provider had a match.
  none;

  String get displayName {
    switch (this) {
      case TranslationSource.localLexicon:
        return 'Lokales Lexikon (Offline)';
      case TranslationSource.cache:
        return 'Lokaler Cache';
      case TranslationSource.supabaseCentralLexicon:
        return 'Zentrales Lexikon (Supabase)';
      case TranslationSource.onlineFallback:
        return 'Online-Fallback';
      case TranslationSource.none:
        return 'Nicht gefunden';
    }
  }
}
