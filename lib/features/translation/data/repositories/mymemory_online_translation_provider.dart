// lib/features/translation/data/repositories/mymemory_online_translation_provider.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../domain/models/translation_query.dart';
import '../../domain/models/translation_result.dart';
import '../../domain/models/translation_source.dart';
import '../../domain/models/translation_target_language.dart';
import '../../domain/repositories/online_translation_provider.dart';
import 'http_supabase_lexicon_repository.dart';

/// Free, open-source-compatible implementation of [OnlineTranslationProvider]
/// using the MyMemory Translated REST API.
///
/// Features:
/// 1. Requires no paid API keys or secret credentials.
/// 2. Translates German into English, Urdu, Farsi, and Arabic.
/// 3. Resilient timeout protection (default 4 seconds).
/// 4. Graceful offline handling: returns `null` on network errors or timeouts.
class MyMemoryOnlineTranslationProvider implements OnlineTranslationProvider {
  final Duration timeout;
  final HttpGetHandler? getHandler;
  final bool enabled;

  const MyMemoryOnlineTranslationProvider({
    this.timeout = const Duration(seconds: 4),
    this.getHandler,
    this.enabled = true,
  });

  @override
  String get name => 'mymemory';

  @override
  bool get isAvailable => enabled;

  @override
  Future<TranslationResult?> translate(TranslationQuery query) async {
    if (!isAvailable) return null;

    final word = query.normalizedWord.trim();
    if (word.isEmpty) return null;

    final langPair = _getLangPair(query.targetLanguage);
    final uri = Uri.parse(
      'https://api.mymemory.translated.net/get?q=${Uri.encodeComponent(word)}&langpair=$langPair',
    );

    try {
      final response = await _executeGet(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final responseData = data['responseData'] as Map<String, dynamic>?;
        final translatedText = responseData?['translatedText'] as String?;

        if (translatedText != null &&
            translatedText.trim().isNotEmpty &&
            !translatedText.toUpperCase().startsWith('MYMEMORY WARNING')) {
          return TranslationResult.success(
            query: query,
            source: TranslationSource.onlineFallback,
            primaryTranslation: translatedText.trim(),
          );
        }
      }
    } catch (e) {
      debugPrint('[MYMEMORY_TRANSLATOR] Online translation failed or timed out: $e');
    }

    return null;
  }

  String _getLangPair(TranslationTargetLanguage target) {
    switch (target) {
      case TranslationTargetLanguage.english:
        return 'de|en';
      case TranslationTargetLanguage.urdu:
        return 'de|ur';
      case TranslationTargetLanguage.farsi:
        return 'de|fa';
      case TranslationTargetLanguage.arabic:
        return 'de|ar';
    }
  }

  Future<HttpResponseData> _executeGet(Uri uri) async {
    if (getHandler != null) {
      return getHandler!(uri, {});
    }

    final client = HttpClient()..connectionTimeout = timeout;
    try {
      final request = await client.getUrl(uri).timeout(timeout);
      final response = await request.close().timeout(timeout);
      final body = await response.transform(utf8.decoder).join().timeout(timeout);
      return HttpResponseData(statusCode: response.statusCode, body: body);
    } finally {
      client.close();
    }
  }
}
