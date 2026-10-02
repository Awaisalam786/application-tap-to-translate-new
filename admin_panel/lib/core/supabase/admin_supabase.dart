import 'package:supabase_flutter/supabase_flutter.dart';
import '../config/app_config.dart';

class AdminSupabase {
  static SupabaseClient? _client;

  /// Retrieve the active Supabase client instance
  static SupabaseClient get client {
    if (_client != null) return _client!;
    try {
      return Supabase.instance.client;
    } catch (_) {
      throw StateError(
        'Supabase has not been initialized. Call AdminSupabase.initialize() '
        'or inject credentials via --dart-define.',
      );
    }
  }

  /// Initialize Supabase Flutter SDK
  static Future<void> initialize({String? url, String? anonKey}) async {
    final targetUrl = url ?? AppConfig.supabaseUrl;
    final targetKey = anonKey ?? AppConfig.supabaseAnonKey;

    if (targetUrl.isEmpty || targetKey.isEmpty) {
      throw ArgumentError(
        'SUPABASE_URL and SUPABASE_ANON_KEY must be provided via environment '
        'or initialize() parameters.',
      );
    }

    await Supabase.initialize(
      url: targetUrl,
      publishableKey: targetKey,
      authOptions: const FlutterAuthClientOptions(
        autoRefreshToken: true,
      ),
    );
    _client = Supabase.instance.client;
  }

  /// For testing and custom client injection
  static void setMockClient(SupabaseClient client) {
    _client = client;
  }

  static void reset() {
    _client = null;
  }
}
