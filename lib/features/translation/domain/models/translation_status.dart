// lib/features/translation/domain/models/translation_status.dart

/// Status outcome of a translation query.
enum TranslationStatus {
  /// Lookup is currently executing.
  loading,

  /// Translation was successfully resolved.
  success,

  /// Word was not found in local lexicon, cache, or online fallback.
  /// (Explicit NOT_FOUND state; the app never silently hallucinates translations).
  notFound,

  /// A technical or network error occurred during lookup.
  error;

  bool get isSuccess => this == TranslationStatus.success;
  bool get isNotFound => this == TranslationStatus.notFound;
  bool get isLoading => this == TranslationStatus.loading;
  bool get isError => this == TranslationStatus.error;
}
