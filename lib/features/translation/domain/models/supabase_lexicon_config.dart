// lib/features/translation/domain/models/supabase_lexicon_config.dart

/// Configuration for connecting to the Supabase central lexicon.
class SupabaseLexiconConfig {
  final String url;
  final String anonKey;
  final Duration timeout;

  const SupabaseLexiconConfig({
    required this.url,
    required this.anonKey,
    this.timeout = const Duration(seconds: 3),
  });

  /// Offline configuration when no Supabase backend is configured.
  const SupabaseLexiconConfig.offline()
      : url = '',
        anonKey = '',
        timeout = const Duration(seconds: 1);

  bool get isConfigured => url.trim().isNotEmpty && anonKey.trim().isNotEmpty;
}
