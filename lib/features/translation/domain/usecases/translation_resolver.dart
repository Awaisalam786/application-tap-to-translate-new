// lib/features/translation/domain/usecases/translation_resolver.dart

import '../models/history_entry.dart';
import '../models/translation_query.dart';
import '../models/translation_result.dart';
import '../models/translation_source.dart';
import '../repositories/german_lexicon_repository.dart';
import '../repositories/german_word_normalizer.dart';
import '../repositories/history_repository.dart';
import '../repositories/online_translation_provider.dart';
import '../repositories/translation_cache.dart';
import '../repositories/translation_repository.dart';

/// Production implementation of [TranslationRepository].
///
/// Implements the strict local-first resolution hierarchy:
/// 1. Local German Lexicon
///    ↓ (if miss)
/// 2. Local Translation Cache
///    ↓ (if miss)
/// 3. Optional Online Provider
///    ↓ (if hit in any tier)
/// 4. Store in Local Translation Cache
///    ↓ (if all tiers miss)
/// Return explicit NOT_FOUND state (NEVER invent translations).
class TranslationResolver implements TranslationRepository {
  final GermanLexiconRepository lexicon;
  final TranslationCache cache;
  final OnlineTranslationProvider? onlineProvider;
  final GermanWordNormalizer normalizer;
  final HistoryRepository? historyRepository;

  const TranslationResolver({
    required this.lexicon,
    required this.cache,
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

    // ─────────────────────────────────────────────────────────────────────────
    // TIER 1: Local German Lexicon (Offline Primary Source)
    // ─────────────────────────────────────────────────────────────────────────
    for (final candidate in candidates) {
      final lexiconHit = await lexicon.lookup(
        normalizedWord: candidate,
        targetLanguage: query.targetLanguage,
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
    // TIER 3: Optional Online Provider (Network Fallback)
    // ─────────────────────────────────────────────────────────────────────────
    final provider = onlineProvider;
    if (provider != null && provider.isAvailable) {
      try {
        final onlineHit = await provider.translate(normalizedQuery);
        if (onlineHit != null && onlineHit.isSuccess) {
          // Store online result into local cache
          await cache.put(onlineHit);
          await _recordHistory(onlineHit);
          return onlineHit;
        }
      } catch (_) {
        // Network or provider error; gracefully fall through to notFound
      }
    }

    // ─────────────────────────────────────────────────────────────────────────
    // TIER 4: Explicit NOT_FOUND State
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
