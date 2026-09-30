// lib/features/translation/data/repositories/http_supabase_lexicon_repository.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../../domain/models/lexicon_entry_status.dart';
import '../../domain/models/supabase_lexicon_config.dart';
import '../../domain/models/translation_query.dart';
import '../../domain/models/translation_result.dart';
import '../../domain/models/translation_source.dart';
import '../../domain/models/translation_target_language.dart';
import '../../domain/repositories/supabase_lexicon_repository.dart';

/// Transport abstraction to allow mock testing of HTTP requests without real network.
typedef HttpGetHandler = Future<HttpResponseData> Function(Uri uri, Map<String, String> headers);
typedef HttpPostHandler = Future<HttpResponseData> Function(Uri uri, Map<String, String> headers, String body);

class HttpResponseData {
  final int statusCode;
  final String body;

  const HttpResponseData({required this.statusCode, required this.body});
}

/// Production implementation of [SupabaseLexiconRepository] communicating via Supabase PostgREST REST API.
class HttpSupabaseLexiconRepository implements SupabaseLexiconRepository {
  final SupabaseLexiconConfig config;
  final HttpGetHandler? getHandler;
  final HttpPostHandler? postHandler;

  HttpSupabaseLexiconRepository({
    required this.config,
    this.getHandler,
    this.postHandler,
  });

  @override
  bool get isAvailable => config.isConfigured;

  Map<String, String> get _baseHeaders => {
        'apikey': config.anonKey,
        'Authorization': 'Bearer ${config.anonKey}',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };

  @override
  Future<TranslationResult?> lookup({
    required String normalizedWord,
    required TranslationTargetLanguage targetLanguage,
    required TranslationQuery query,
  }) async {
    if (!isAvailable) return null;

    final word = normalizedWord.toLowerCase().trim();
    final langCode = targetLanguage.code;
    final cacheKey = '${word}_$langCode';

    try {
      // 1. First check central_translation_cache table (rapid lookup)
      final cacheUri = Uri.parse(
        '${config.url}/rest/v1/central_translation_cache?'
        'cache_key=eq.${Uri.encodeComponent(cacheKey)}&select=*',
      );

      final cacheResponse = await _executeGet(cacheUri);
      if (cacheResponse.statusCode == 200) {
        final List list = jsonDecode(cacheResponse.body) as List;
        if (list.isNotEmpty) {
          final row = list.first as Map<String, dynamic>;
          final translation = row['translation'] as String?;
          if (translation != null && translation.trim().isNotEmpty) {
            return TranslationResult.success(
              query: query,
              source: TranslationSource.supabaseCentralLexicon,
              primaryTranslation: translation,
            );
          }
        }
      }

      // 2. Next check primary lexicon_entries table
      final lexiconUri = Uri.parse(
        '${config.url}/rest/v1/lexicon_entries?'
        'normalized_word=eq.${Uri.encodeComponent(word)}&'
        'target_language=eq.$langCode&select=*',
      );

      final lexResponse = await _executeGet(lexiconUri);
      if (lexResponse.statusCode == 200) {
        final List list = jsonDecode(lexResponse.body) as List;
        if (list.isNotEmpty) {
          final row = list.first as Map<String, dynamic>;
          final translation = row['translation'] as String?;
          if (translation != null && translation.trim().isNotEmpty) {
            return TranslationResult.success(
              query: query,
              source: TranslationSource.supabaseCentralLexicon,
              primaryTranslation: translation,
              partOfSpeech: row['part_of_speech'] as String?,
            );
          }
        }
      }
    } catch (e) {
      debugPrint('[SUPABASE_LEXICON] Lookup failed gracefully: $e');
    }

    return null;
  }

  @override
  Future<bool> saveTranslation({
    required TranslationResult result,
    required String providerName,
  }) async {
    if (!isAvailable || !result.isSuccess || result.primaryTranslation == null) {
      return false;
    }

    final word = result.query.normalizedWord.toLowerCase().trim();
    final langCode = result.query.targetLanguage.code;
    final cacheKey = '${word}_$langCode';

    try {
      // 1. Upsert into central_translation_cache
      final cacheUri = Uri.parse('${config.url}/rest/v1/central_translation_cache?on_conflict=cache_key');
      final cacheHeaders = Map<String, String>.from(_baseHeaders)
        ..['Prefer'] = 'resolution=merge-duplicates';

      final cachePayload = jsonEncode({
        'cache_key': cacheKey,
        'normalized_word': word,
        'source_language': 'de',
        'target_language': langCode,
        'translation': result.primaryTranslation!,
        'provider': providerName,
        'source': 'online_fallback',
        'status': LexiconEntryStatus.machineGenerated.code,
      });

      await _executePost(cacheUri, cacheHeaders, cachePayload);

      // 2. Upsert into lexicon_entries with MACHINE_GENERATED status
      final lexiconUri = Uri.parse('${config.url}/rest/v1/lexicon_entries?on_conflict=normalized_word,source_language,target_language');
      final lexiconHeaders = Map<String, String>.from(_baseHeaders)
        ..['Prefer'] = 'resolution=merge-duplicates';

      final lexiconPayload = jsonEncode({
        'normalized_word': word,
        'source_language': 'de',
        'target_language': langCode,
        'translation': result.primaryTranslation!,
        'source': 'online_fallback',
        'status': LexiconEntryStatus.machineGenerated.code,
      });

      await _executePost(lexiconUri, lexiconHeaders, lexiconPayload);
      return true;
    } catch (e) {
      debugPrint('[SUPABASE_LEXICON] Asynchronous save failed gracefully: $e');
      return false;
    }
  }

  @override
  Future<void> logRequest({
    required TranslationQuery query,
    required String providerName,
    required String status,
    String? result,
  }) async {
    if (!isAvailable) return;

    try {
      final uri = Uri.parse('${config.url}/rest/v1/translation_requests');
      final payload = jsonEncode({
        'raw_word': query.rawWord,
        'normalized_word': query.normalizedWord.toLowerCase().trim(),
        'source_language': 'de',
        'target_language': query.targetLanguage.code,
        'resolved': status == 'SUCCESS',
        'resolved_source': providerName,
      });

      final headers = Map<String, String>.from(_baseHeaders)
        ..['Prefer'] = 'return=minimal';

      await _executePost(uri, headers, payload);
    } catch (e) {
      debugPrint('[SUPABASE_LEXICON] Request logging failed gracefully: $e');
    }
  }

  Future<HttpResponseData> _executeGet(Uri uri) async {
    if (getHandler != null) {
      return getHandler!(uri, _baseHeaders);
    }

    final client = HttpClient()..connectionTimeout = config.timeout;
    try {
      final request = await client.getUrl(uri).timeout(config.timeout);
      _baseHeaders.forEach((k, v) => request.headers.set(k, v));
      final response = await request.close().timeout(config.timeout);
      final body = await response.transform(utf8.decoder).join().timeout(config.timeout);
      return HttpResponseData(statusCode: response.statusCode, body: body);
    } finally {
      client.close();
    }
  }

  Future<HttpResponseData> _executePost(Uri uri, Map<String, String> headers, String body) async {
    if (postHandler != null) {
      return postHandler!(uri, headers, body);
    }

    final client = HttpClient()..connectionTimeout = config.timeout;
    try {
      final request = await client.postUrl(uri).timeout(config.timeout);
      headers.forEach((k, v) => request.headers.set(k, v));
      final bytes = utf8.encode(body);
      request.headers.contentLength = bytes.length;
      request.add(bytes);
      final response = await request.close().timeout(config.timeout);
      final responseBody = await response.transform(utf8.decoder).join().timeout(config.timeout);
      return HttpResponseData(statusCode: response.statusCode, body: responseBody);
    } finally {
      client.close();
    }
  }
}
