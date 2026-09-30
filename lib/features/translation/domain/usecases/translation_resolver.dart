import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/history_entry.dart';
import '../models/translation_query.dart';
import '../models/translation_result.dart';
import '../models/translation_source.dart';
import '../repositories/german_lexicon_repository.dart';
import '../repositories/german_word_normalizer.dart';
import '../repositories/history_repository.dart';
import '../repositories/online_translation_provider.dart';
import '../repositories/supabase_lexicon_repository.dart';
import '../repositories/translation_cache.dart';
import '../repositories/translation_repository.dart';

/// Production implementation of [TranslationRepository].
///
/// Implements the strict 5-tier resolution hierarchy:
/// 1. Local German Lexicon (Deterministic Offline Source)
///    ↓ (if miss)
/// 2. Local Translation Cache (On-Device Cache)
///    ↓ (if miss)
/// 3. Supabase Central Lexicon (Shared Cloud Lexicon)
///    ↓ (if miss)
/// 4. Online Translation Provider (Network Fallback)
///    ↓ (if hit in Tier 4: asynchronously auto-cached to Supabase & local cache)
/// 5. Explicit NOT_FOUND State (NEVER invent translations).
class TranslationResolver implements TranslationRepository {
  final GermanLexiconRepository lexicon;
  final TranslationCache cache;
  final SupabaseLexiconRepository? supabaseLexicon;
  final OnlineTranslationProvider? onlineProvider;
  final GermanWordNormalizer normalizer;
  final HistoryRepository? historyRepository;

  final Map<String, Future<TranslationResult>> _inFlightTranslations = {};

  TranslationResolver({
    required this.lexicon,
    required this.cache,
    this.supabaseLexicon,
    this.onlineProvider,
    required this.normalizer,
    this.historyRepository,
  });

  @override
  Future<TranslationResult> translate(TranslationQuery query) async {
    // Generate normalized lookup candidates (e.g. "Deutschland", "deutschland")
    final candidates = normalizer.generateLookupCandidates(query.rawWord);
    final effectiveNormalized = candidates.isNotEmpty
        ? candidates.first
        : normalizer.normalize(query.rawWord);

    final normalizedQuery = TranslationQuery(
      rawWord: query.rawWord,
      normalizedWord: effectiveNormalized,
      targetLanguage: query.targetLanguage,
      contextSentence: query.contextSentence,
      pageNumber: query.pageNumber,
    );

    // Canonical key for in-flight deduplication across casing and punctuation
    final canonicalKey = normalizedQuery.cacheKey;

    // In-flight request coalescing: deduplicate concurrent identical requests
    final inFlight = _inFlightTranslations[canonicalKey];
    if (inFlight != null) {
      final res = await inFlight;
      return res.copyWith(query: normalizedQuery);
    }

    final future = _executeResolution(normalizedQuery, candidates);
    _inFlightTranslations[canonicalKey] = future;
    try {
      final result = await future;
      return result;
    } finally {
      _inFlightTranslations.remove(canonicalKey);
    }
  }

  Future<TranslationResult> _executeResolution(
    TranslationQuery normalizedQuery,
    List<String> candidates,
  ) async {
    // ─────────────────────────────────────────────────────────────────────────
    // TIER 1: Local German Lexicon (Offline Primary Source)
    // ─────────────────────────────────────────────────────────────────────────
    for (final candidate in candidates) {
      final lexiconHit = await lexicon.lookup(
        normalizedWord: candidate,
        targetLanguage: normalizedQuery.targetLanguage,
        query: normalizedQuery,
      );

      if (lexiconHit != null && lexiconHit.isSuccess) {
        // Cache the successful local hit for rapid subsequent access
        await cache.put(lexiconHit);
        await _recordHistory(lexiconHit);
        return lexiconHit;
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TIER 2: Local Translation Cache
    // ─────────────────────────────────────────────────────────────────────────
    final cachedHit = await cache.get(normalizedQuery);
    if (cachedHit != null && cachedHit.isSuccess) {
      final cacheResult = cachedHit.copyWithSource(TranslationSource.cache);
      await _recordHistory(cacheResult);
      return cacheResult;
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TIER 3: Supabase Central Lexicon (Shared Cloud Lexicon)
    // ─────────────────────────────────────────────────────────────────────────
    final supabase = supabaseLexicon;
    if (supabase != null && supabase.isAvailable) {
      try {
        for (final candidate in candidates) {
          final supabaseHit = await supabase.lookup(
            normalizedWord: candidate,
            targetLanguage: normalizedQuery.targetLanguage,
            query: normalizedQuery,
          );

          if (supabaseHit != null && supabaseHit.isSuccess) {
            // Cache the central cloud result into local on-device cache for instant subsequent hits
            await cache.put(supabaseHit);
            await _recordHistory(supabaseHit);
            return supabaseHit;
          }
        }
      } catch (e) {
        debugPrint('[TRANSLATION_RESOLVER] Supabase lookup error (falling through): $e');
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TIER 4: Online Translation Provider (Network Fallback)
    // ─────────────────────────────────────────────────────────────────────────
    final provider = onlineProvider;
    if (provider != null && provider.isAvailable) {
      try {
        final onlineHit = await provider.translate(normalizedQuery);
        if (onlineHit != null && onlineHit.isSuccess) {
          // 1. Immediately cache in local cache for subsequent instant taps
          await cache.put(onlineHit);
          await _recordHistory(onlineHit);

          // 2. Asynchronously save to Supabase central lexicon (do NOT make user wait)
          if (supabase != null && supabase.isAvailable) {
            unawaited(
              supabase.saveTranslation(
                result: onlineHit,
                providerName: provider.name,
              ).catchError((err) {
                debugPrint('[TRANSLATION_RESOLVER] Asynchronous Supabase save failed: $err');
                return false;
              }),
            );

            unawaited(
              supabase.logRequest(
                query: normalizedQuery,
                providerName: provider.name,
                status: 'SUCCESS',
                result: onlineHit.primaryTranslation,
              ).catchError((err) {
                debugPrint('[TRANSLATION_RESOLVER] Asynchronous Supabase logRequest failed: $err');
              }),
            );
          }

          // Return immediately to user without waiting for cloud write
          return onlineHit;
        } else if (supabase != null && supabase.isAvailable) {
          // Log failed/empty online attempt
          unawaited(
            supabase.logRequest(
              query: normalizedQuery,
              providerName: provider.name,
              status: 'NOT_FOUND',
            ).catchError((_) {}),
          );
        }
      } catch (e) {
        debugPrint('[TRANSLATION_RESOLVER] Online provider error (falling through): $e');
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TIER 5: Explicit NOT_FOUND State
    // (Invariant: Never silently invent or hallucinate translations)
    // ─────────────────────────────────────────────────────────────────────────
    final notFoundResult = TranslationResult.notFound(query: normalizedQuery);
    await _recordHistory(notFoundResult);
    return notFoundResult;
  }

  Future<void> _recordHistory(TranslationResult result) async {
    final hist = historyRepository;
    if (hist == null) return;

    try {
      await hist.recordLookup(
        HistoryEntry(
          id: '${DateTime.now().microsecondsSinceEpoch}_${result.query.normalizedWord}',
          rawWord: result.query.rawWord,
          normalizedWord: result.query.normalizedWord,
          targetLanguage: result.query.targetLanguage,
          status: result.status,
          source: result.source,
          translation: result.primaryTranslation,
          lookedUpAt: DateTime.now(),
        ),
      );
    } catch (_) {
      // History logging failure should never crash the reader translation pipeline
    }
  }
}
