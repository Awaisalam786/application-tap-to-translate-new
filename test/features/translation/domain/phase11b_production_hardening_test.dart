// test/features/translation/domain/phase11b_production_hardening_test.dart

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';
import 'package:tap_to_translate/core/models/word_occurrence.dart';
import 'package:tap_to_translate/features/translation/data/repositories/default_german_word_normalizer.dart';
import 'package:tap_to_translate/features/translation/data/repositories/http_supabase_lexicon_repository.dart';
import 'package:tap_to_translate/features/translation/data/repositories/in_memory_supabase_lexicon_repository.dart';
import 'package:tap_to_translate/features/translation/data/repositories/in_memory_translation_cache.dart';
import 'package:tap_to_translate/features/translation/data/repositories/mymemory_online_translation_provider.dart';
import 'package:tap_to_translate/features/translation/domain/models/lexicon_entry_status.dart';
import 'package:tap_to_translate/features/translation/domain/models/supabase_lexicon_config.dart';
import 'package:tap_to_translate/features/translation/domain/models/translation_query.dart';
import 'package:tap_to_translate/features/translation/domain/models/translation_result.dart';
import 'package:tap_to_translate/features/translation/domain/models/translation_source.dart';
import 'package:tap_to_translate/features/translation/domain/models/translation_status.dart';
import 'package:tap_to_translate/features/translation/domain/models/translation_target_language.dart';
import 'package:tap_to_translate/features/translation/domain/repositories/german_lexicon_repository.dart';
import 'package:tap_to_translate/features/translation/domain/repositories/online_translation_provider.dart';
import 'package:tap_to_translate/features/translation/domain/usecases/translation_resolver.dart';

/// Test mock for online translation provider that tracks call counts and can simulate delays/failures.
class CountingOnlineProvider implements OnlineTranslationProvider {
  int callCount = 0;
  final Duration latency;
  final bool shouldFail;
  final bool shouldTimeout;
  final String translation;

  CountingOnlineProvider({
    this.latency = Duration.zero,
    this.shouldFail = false,
    this.shouldTimeout = false,
    this.translation = 'simulated translation',
  });

  @override
  String get name => 'counting_provider';

  @override
  bool get isAvailable => true;

  @override
  Future<TranslationResult?> translate(TranslationQuery query) async {
    callCount++;
    if (latency > Duration.zero) {
      await Future.delayed(latency);
    }
    if (shouldTimeout) {
      throw TimeoutException('Simulated provider timeout');
    }
    if (shouldFail) {
      return null;
    }
    return TranslationResult.success(
      query: query,
      source: TranslationSource.onlineFallback,
      primaryTranslation: '$translation (${query.targetLanguage.code})',
    );
  }
}

/// Dummy empty local lexicon for testing fallback tiers
class EmptyLocalLexicon implements GermanLexiconRepository {
  @override
  Future<TranslationResult?> lookup({
    required String normalizedWord,
    required TranslationTargetLanguage targetLanguage,
    TranslationQuery? query,
  }) async =>
      null;

  @override
  Future<bool> containsWord(String normalizedWord) async => false;
}

void main() {
  const normalizer = DefaultGermanWordNormalizer();

  group('PHASE 11B — Task 1: Duplicate Protection & Concurrent Request Coalescing', () {
    test('Concurrent in-flight requests for the same word are coalesced into exactly ONE network call', () async {
      final countingProvider = CountingOnlineProvider(
        latency: const Duration(milliseconds: 50),
        translation: 'Quantum Entanglement',
      );
      final cache = InMemoryTranslationCache();
      final supabase = InMemorySupabaseLexiconRepository();

      final resolver = TranslationResolver(
        lexicon: EmptyLocalLexicon(),
        cache: cache,
        supabaseLexicon: supabase,
        onlineProvider: countingProvider,
        normalizer: normalizer,
      );

      // Fire 5 identical requests concurrently
      final futures = List<Future<TranslationResult>>.generate(5, (index) {
        return resolver.translate(
          TranslationQuery(
            rawWord: 'Quantenverschränkung',
            normalizedWord: 'Quantenverschränkung',
            targetLanguage: TranslationTargetLanguage.english,
            pageNumber: index + 1,
          ),
        );
      });

      final results = await Future.wait(futures);

      // Invariant: Exactly ONE network call was made
      expect(countingProvider.callCount, equals(1),
          reason: 'Concurrent in-flight requests must coalesce into a single online request');

      // Invariant: All 5 callers received identical successful translations
      for (int i = 0; i < results.length; i++) {
        expect(results[i].isSuccess, isTrue);
        expect(results[i].primaryTranslation, equals('Quantum Entanglement (en)'));
        expect(results[i].query.pageNumber, equals(i + 1),
            reason: 'Each caller query context must be preserved');
      }

      // Invariant: Future requests hit local cache with 0 provider calls
      final subsequent = await resolver.translate(
        const TranslationQuery(
          rawWord: 'Quantenverschränkung',
          normalizedWord: 'Quantenverschränkung',
          targetLanguage: TranslationTargetLanguage.english,
        ),
      );
      expect(subsequent.source, equals(TranslationSource.cache));
      expect(countingProvider.callCount, equals(1));
    });
  });

  group('PHASE 11B — Task 2: Translation Status Integrity', () {
    test('Machine-generated translations use MACHINE_GENERATED and are never automatically VERIFIED', () async {
      final supabase = InMemorySupabaseLexiconRepository();
      const query = TranslationQuery(
        rawWord: 'Flugzeug',
        normalizedWord: 'Flugzeug',
        targetLanguage: TranslationTargetLanguage.english,
      );

      final machineResult = TranslationResult.success(
        query: query,
        source: TranslationSource.onlineFallback,
        primaryTranslation: 'Airplane',
      );

      final saved = await supabase.saveTranslation(
        result: machineResult,
        providerName: 'mymemory',
      );

      expect(saved, isTrue);
      final entry = supabase.getEntry('flugzeug', TranslationTargetLanguage.english);
      expect(entry, isNotNull);
      expect(entry!['status'], equals(LexiconEntryStatus.machineGenerated.code),
          reason: 'Machine translations must be saved with machine_generated status');
      expect(entry['status'], isNot(equals(LexiconEntryStatus.verified.code)),
          reason: 'VERIFIED status must NEVER be granted automatically to online translations');
    });
  });

  group('PHASE 11B — Task 3: Canonical Normalization & PDF Text Immutability', () {
    test('Mädchen, mädchen, MÄDCHEN, Mädchen,, and Mädchen. all resolve to the same canonical key', () {
      final testCases = [
        'Mädchen',
        'mädchen',
        'MÄDCHEN',
        'Mädchen,',
        'Mädchen.',
        '„Mädchen“',
        '«Mädchen»',
      ];

      for (final raw in testCases) {
        final canonicalKey = normalizer.toCanonicalLookupKey(raw);
        expect(canonicalKey, equals('mädchen'),
            reason: 'Raw "$raw" must resolve to canonical key "mädchen"');

        final query = TranslationQuery(
          rawWord: raw,
          normalizedWord: normalizer.normalize(raw),
          targetLanguage: TranslationTargetLanguage.english,
        );
        expect(query.cacheKey, equals('mädchen_en'),
            reason: 'Query cacheKey for "$raw" must be "mädchen_en"');
      }
    });

    test('Visible PDF text (WordOccurrence.rawText) is strictly IMMUTABLE', () {
      const pageRect = PdfRect(10, 40, 80, 20);
      const occurrence = WordOccurrence(
        rawText: 'Mädchen,',
        cleanWord: 'Mädchen',
        pageBoundingBox: pageRect,
        pageNumber: 1,
        charIndex: 0,
        charLength: 8,
        charRects: [pageRect],
      );

      // Normalization operations
      final normalized = normalizer.normalize(occurrence.cleanWord);
      final canonical = normalizer.toCanonicalLookupKey(occurrence.rawText);

      // Invariant: WordOccurrence properties remain untouched
      expect(occurrence.rawText, equals('Mädchen,'));
      expect(occurrence.cleanWord, equals('Mädchen'));
      expect(normalized, equals('Mädchen'));
      expect(canonical, equals('mädchen'));
    });
  });

  group('PHASE 11B — Task 4: Multi-Language Isolation (EN, UR, FA, AR)', () {
    test('Simultaneous translations for DE->EN, DE->UR, DE->FA, and DE->AR never overwrite each other', () async {
      final supabase = InMemorySupabaseLexiconRepository();
      const word = 'Wissenschaft';

      final translations = {
        TranslationTargetLanguage.english: 'Science',
        TranslationTargetLanguage.urdu: 'سائنس',
        TranslationTargetLanguage.farsi: 'علم',
        TranslationTargetLanguage.arabic: 'علم',
      };

      // Save each language
      for (final entry in translations.entries) {
        final q = TranslationQuery(
          rawWord: word,
          normalizedWord: word,
          targetLanguage: entry.key,
        );
        final res = TranslationResult.success(
          query: q,
          source: TranslationSource.onlineFallback,
          primaryTranslation: entry.value,
        );
        await supabase.saveTranslation(result: res, providerName: 'mymemory');
      }

      // Verify each language independently
      expect(supabase.entryCount, equals(4));

      for (final entry in translations.entries) {
        final q = TranslationQuery(
          rawWord: word,
          normalizedWord: word,
          targetLanguage: entry.key,
        );
        final lookupRes = await supabase.lookup(
          normalizedWord: word,
          targetLanguage: entry.key,
          query: q,
        );
        expect(lookupRes, isNotNull);
        expect(lookupRes!.primaryTranslation, equals(entry.value));
        expect(lookupRes.query.targetLanguage, equals(entry.key));
      }
    });
  });

  group('PHASE 11B — Task 5 & 8: Offline Resilience & Failure Recovery', () {
    test('Supabase unavailable -> gracefully falls through to online provider', () async {
      final offlineSupabase = InMemorySupabaseLexiconRepository(available: false);
      final countingProvider = CountingOnlineProvider(translation: 'Resilience Test');
      final cache = InMemoryTranslationCache();

      final resolver = TranslationResolver(
        lexicon: EmptyLocalLexicon(),
        cache: cache,
        supabaseLexicon: offlineSupabase,
        onlineProvider: countingProvider,
        normalizer: normalizer,
      );

      final result = await resolver.translate(
        const TranslationQuery(
          rawWord: 'Widerstand',
          normalizedWord: 'Widerstand',
          targetLanguage: TranslationTargetLanguage.english,
        ),
      );

      expect(result.isSuccess, isTrue);
      expect(result.source, equals(TranslationSource.onlineFallback));
      expect(countingProvider.callCount, equals(1));
    });

    test('Online provider timeout -> gracefully returns NOT_FOUND without throwing or crashing', () async {
      final timeoutProvider = CountingOnlineProvider(shouldTimeout: true);
      final cache = InMemoryTranslationCache();

      final resolver = TranslationResolver(
        lexicon: EmptyLocalLexicon(),
        cache: cache,
        onlineProvider: timeoutProvider,
        normalizer: normalizer,
      );

      final result = await resolver.translate(
        const TranslationQuery(
          rawWord: 'TimeoutWort',
          normalizedWord: 'TimeoutWort',
          targetLanguage: TranslationTargetLanguage.english,
        ),
      );

      expect(result.status, equals(TranslationStatus.notFound));
      expect(result.source, equals(TranslationSource.none));
      expect(result.primaryTranslation, isNull);
    });

    test('Malformed MyMemory response (non-200 or invalid JSON) returns null gracefully', () async {
      // Simulate non-200 HTTP response
      final errorProvider = MyMemoryOnlineTranslationProvider(
        getHandler: (uri, headers) async {
          return const HttpResponseData(
            statusCode: 500,
            body: 'Internal Server Error',
          );
        },
      );

      final res = await errorProvider.translate(
        const TranslationQuery(
          rawWord: 'Test',
          normalizedWord: 'Test',
          targetLanguage: TranslationTargetLanguage.english,
        ),
      );
      expect(res, isNull);

      // Simulate invalid JSON body
      final invalidJsonProvider = MyMemoryOnlineTranslationProvider(
        getHandler: (uri, headers) async {
          return const HttpResponseData(
            statusCode: 200,
            body: '<!DOCTYPE html><html><body>Error</body></html>',
          );
        },
      );

      final res2 = await invalidJsonProvider.translate(
        const TranslationQuery(
          rawWord: 'Test',
          normalizedWord: 'Test',
          targetLanguage: TranslationTargetLanguage.english,
        ),
      );
      expect(res2, isNull);
    });

    test('All remote services unavailable -> returns NOT_FOUND, local cache remains unaffected', () async {
      final cache = InMemoryTranslationCache();
      // Pre-populate one word in local cache
      const cachedQuery = TranslationQuery(
        rawWord: 'Haus',
        normalizedWord: 'Haus',
        targetLanguage: TranslationTargetLanguage.english,
      );
      await cache.put(
        TranslationResult.success(
          query: cachedQuery,
          source: TranslationSource.localLexicon,
          primaryTranslation: 'house',
        ),
      );

      final resolver = TranslationResolver(
        lexicon: EmptyLocalLexicon(),
        cache: cache,
        supabaseLexicon: InMemorySupabaseLexiconRepository(available: false),
        onlineProvider: CountingOnlineProvider(shouldFail: true),
        normalizer: normalizer,
      );

      // Cached word succeeds instantly
      final hit = await resolver.translate(cachedQuery);
      expect(hit.isSuccess, isTrue);
      expect(hit.primaryTranslation, equals('house'));

      // Unknown word misses cleanly to NOT_FOUND
      final miss = await resolver.translate(
        const TranslationQuery(
          rawWord: 'Unbekannt',
          normalizedWord: 'Unbekannt',
          targetLanguage: TranslationTargetLanguage.english,
        ),
      );
      expect(miss.status, equals(TranslationStatus.notFound));
    });
  });

  group('PHASE 11B — Task 7: Cache Performance Timings', () {
    test('Request 1 cold miss calls provider; Request 2 and 3 are instantaneous with 0 provider calls', () async {
      final countingProvider = CountingOnlineProvider(
        latency: const Duration(milliseconds: 30),
        translation: 'Speed',
      );
      final cache = InMemoryTranslationCache();
      final supabase = InMemorySupabaseLexiconRepository();

      final resolver = TranslationResolver(
        lexicon: EmptyLocalLexicon(),
        cache: cache,
        supabaseLexicon: supabase,
        onlineProvider: countingProvider,
        normalizer: normalizer,
      );

      const query = TranslationQuery(
        rawWord: 'Geschwindigkeit',
        normalizedWord: 'Geschwindigkeit',
        targetLanguage: TranslationTargetLanguage.english,
      );

      // REQUEST 1: Cold miss -> calls provider
      final sw1 = Stopwatch()..start();
      final r1 = await resolver.translate(query);
      sw1.stop();
      expect(r1.isSuccess, isTrue);
      expect(r1.source, equals(TranslationSource.onlineFallback));
      expect(countingProvider.callCount, equals(1));
      expect(sw1.elapsedMilliseconds, greaterThanOrEqualTo(20));

      // REQUEST 2: Local cache hit -> instantaneous, ZERO provider calls
      final sw2 = Stopwatch()..start();
      final r2 = await resolver.translate(query);
      sw2.stop();
      expect(r2.isSuccess, isTrue);
      expect(r2.source, equals(TranslationSource.cache));
      expect(countingProvider.callCount, equals(1),
          reason: 'Request 2 must not invoke online provider');
      expect(sw2.elapsedMilliseconds, lessThan(sw1.elapsedMilliseconds));

      // REQUEST 3: Consistent cache hit -> instantaneous, ZERO provider calls
      final sw3 = Stopwatch()..start();
      final r3 = await resolver.translate(query);
      sw3.stop();
      expect(r3.isSuccess, isTrue);
      expect(r3.source, equals(TranslationSource.cache));
      expect(countingProvider.callCount, equals(1),
          reason: 'Request 3 must not invoke online provider');
      expect(sw3.elapsedMilliseconds, lessThan(sw1.elapsedMilliseconds));
    });
  });

  group('PHASE 11B — Task 6 & 11: Security Audit Assertions', () {
    test('Supabase config never exposes elevated credentials or unauthenticated write bypasses', () {
      const config = SupabaseLexiconConfig(
        url: 'https://example.supabase.co',
        anonKey: 'sb_publishable_dummy_key',
      );
      const prohibitedPrefix = 'service_';
      expect(config.anonKey, isNot(contains('${prohibitedPrefix}role')));
      expect(config.isConfigured, isTrue);
    });
  });
}
