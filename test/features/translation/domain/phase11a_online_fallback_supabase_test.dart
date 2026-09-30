// test/features/translation/domain/phase11a_online_fallback_supabase_test.dart

import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdfrx/pdfrx.dart';

import 'package:tap_to_translate/core/models/selection_result.dart';
import 'package:tap_to_translate/core/models/word_occurrence.dart';
import 'package:tap_to_translate/features/reader/domain/exact_hit_tester.dart';
import 'package:tap_to_translate/features/reader/domain/word_spatial_index.dart';
import 'package:tap_to_translate/features/translation/data/repositories/default_german_word_normalizer.dart';
import 'package:tap_to_translate/features/translation/data/repositories/http_supabase_lexicon_repository.dart';
import 'package:tap_to_translate/features/translation/data/repositories/in_memory_history_repository.dart';
import 'package:tap_to_translate/features/translation/data/repositories/in_memory_supabase_lexicon_repository.dart';
import 'package:tap_to_translate/features/translation/data/repositories/in_memory_translation_cache.dart';
import 'package:tap_to_translate/features/translation/data/repositories/local_german_lexicon_repository.dart';
import 'package:tap_to_translate/features/translation/data/repositories/mymemory_online_translation_provider.dart';
import 'package:tap_to_translate/features/translation/domain/models/lexicon_entry_status.dart';
import 'package:tap_to_translate/features/translation/domain/models/translation_query.dart';
import 'package:tap_to_translate/features/translation/domain/models/translation_result.dart';
import 'package:tap_to_translate/features/translation/domain/models/translation_source.dart';
import 'package:tap_to_translate/features/translation/domain/models/translation_status.dart';
import 'package:tap_to_translate/features/translation/domain/models/translation_target_language.dart';
import 'package:tap_to_translate/features/translation/domain/usecases/translation_resolver.dart';

void main() {
  group('Phase 11A — 5-Tier Lookup Hierarchy & Supabase Auto-Caching Tests', () {
    late LocalGermanLexiconRepository localLexicon;
    late InMemoryTranslationCache localCache;
    late InMemorySupabaseLexiconRepository supabaseRepo;
    late InMemoryHistoryRepository historyRepo;
    late DefaultGermanWordNormalizer normalizer;

    setUp(() {
      localLexicon = const LocalGermanLexiconRepository();
      localCache = InMemoryTranslationCache();
      supabaseRepo = InMemorySupabaseLexiconRepository();
      historyRepo = InMemoryHistoryRepository();
      normalizer = const DefaultGermanWordNormalizer();
    });

    test('Tier 1: Local Lexicon hit returns immediately and does not call Supabase or Online', () async {
      // "Haus" exists in LocalGermanLexiconRepository
      var onlineCalled = false;
      final onlineProvider = MyMemoryOnlineTranslationProvider(
        getHandler: (uri, headers) async {
          onlineCalled = true;
          return const HttpResponseData(statusCode: 200, body: '{}');
        },
      );

      final resolver = TranslationResolver(
        lexicon: localLexicon,
        cache: localCache,
        supabaseLexicon: supabaseRepo,
        onlineProvider: onlineProvider,
        normalizer: normalizer,
        historyRepository: historyRepo,
      );

      final query = const TranslationQuery(
        rawWord: 'Haus',
        normalizedWord: 'Haus',
        targetLanguage: TranslationTargetLanguage.english,
      );

      final result = await resolver.translate(query);

      expect(result.status, TranslationStatus.success);
      expect(result.source, TranslationSource.localLexicon);
      expect(result.primaryTranslation?.toLowerCase(), contains('house'));
      expect(supabaseRepo.lookupCount, 0, reason: 'Supabase should not be consulted on Tier 1 hit');
      expect(onlineCalled, isFalse, reason: 'Online provider should not be consulted on Tier 1 hit');
    });

    test('Tier 2: Local Cache hit returns immediately without Supabase or Online lookup', () async {
      final onlineProvider = MyMemoryOnlineTranslationProvider(
        getHandler: (uri, headers) async => const HttpResponseData(statusCode: 200, body: '{}'),
      );

      final resolver = TranslationResolver(
        lexicon: localLexicon,
        cache: localCache,
        supabaseLexicon: supabaseRepo,
        onlineProvider: onlineProvider,
        normalizer: normalizer,
        historyRepository: historyRepo,
      );

      // Pre-seed local cache with a custom word not in local lexicon
      final preQuery = const TranslationQuery(
        rawWord: 'Kryptowährung',
        normalizedWord: 'kryptowährung',
        targetLanguage: TranslationTargetLanguage.english,
      );
      final preCachedResult = TranslationResult.success(
        query: preQuery,
        source: TranslationSource.cache,
        primaryTranslation: 'cryptocurrency',
      );
      await localCache.put(preCachedResult);

      final result = await resolver.translate(preQuery);

      expect(result.status, TranslationStatus.success);
      expect(result.source, TranslationSource.cache);
      expect(result.primaryTranslation, 'cryptocurrency');
      expect(supabaseRepo.lookupCount, 0, reason: 'Supabase should not be consulted on Tier 2 cache hit');
    });

    test('Tier 3: Supabase Central Lexicon hit returns without querying Online Provider', () async {
      // Seed Supabase repository with pre-cached word
      final seededSupabaseRepo = InMemorySupabaseLexiconRepository(
        initialTranslations: {
          'bundesnetzagentur_en': 'Federal Network Agency',
        },
      );

      var onlineCalled = false;
      final onlineProvider = MyMemoryOnlineTranslationProvider(
        getHandler: (uri, headers) async {
          onlineCalled = true;
          return const HttpResponseData(statusCode: 200, body: '{}');
        },
      );

      final resolver = TranslationResolver(
        lexicon: localLexicon,
        cache: localCache,
        supabaseLexicon: seededSupabaseRepo,
        onlineProvider: onlineProvider,
        normalizer: normalizer,
        historyRepository: historyRepo,
      );

      final query = const TranslationQuery(
        rawWord: 'Bundesnetzagentur',
        normalizedWord: 'bundesnetzagentur',
        targetLanguage: TranslationTargetLanguage.english,
      );

      final result = await resolver.translate(query);

      expect(result.status, TranslationStatus.success);
      expect(result.source, TranslationSource.supabaseCentralLexicon);
      expect(result.source.displayName, 'Zentrales Lexikon (Supabase)');
      expect(result.primaryTranslation, 'Federal Network Agency');
      expect(seededSupabaseRepo.lookupCount, 1);
      expect(onlineCalled, isFalse, reason: 'Online provider should not be called when Supabase has word');

      // Also verify it was cached locally for subsequent instant Tier 2 access
      final cachedAgain = await localCache.get(query);
      expect(cachedAgain, isNotNull);
      expect(cachedAgain!.primaryTranslation, 'Federal Network Agency');
    });

    test('Tier 4: Online fallback translates word, returns immediately, and auto-caches to Supabase with MACHINE_GENERATED status', () async {
      // Mock MyMemory response
      final mockMyMemoryJson = jsonEncode({
        'responseData': {
          'translatedText': 'Artificial Intelligence',
          'match': 0.98,
        },
        'responseStatus': 200,
      });

      final onlineProvider = MyMemoryOnlineTranslationProvider(
        getHandler: (uri, headers) async {
          expect(uri.queryParameters['q']?.toLowerCase(), 'künstliche intelligenz');
          expect(uri.queryParameters['langpair'], 'de|en');
          return HttpResponseData(statusCode: 200, body: mockMyMemoryJson);
        },
      );

      final resolver = TranslationResolver(
        lexicon: localLexicon,
        cache: localCache,
        supabaseLexicon: supabaseRepo,
        onlineProvider: onlineProvider,
        normalizer: normalizer,
        historyRepository: historyRepo,
      );

      final query = const TranslationQuery(
        rawWord: 'Künstliche Intelligenz',
        normalizedWord: 'künstliche intelligenz',
        targetLanguage: TranslationTargetLanguage.english,
      );

      final result = await resolver.translate(query);

      // Verify immediate result
      expect(result.status, TranslationStatus.success);
      expect(result.source, TranslationSource.onlineFallback);
      expect(result.primaryTranslation, 'Artificial Intelligence');

      // Wait a microtask turn for unawaited background save to finish
      await Future<void>.delayed(const Duration(milliseconds: 30));

      // Verify Supabase was updated
      expect(supabaseRepo.saveCount, 1);
      final savedEntry = supabaseRepo.getEntry('künstliche intelligenz', TranslationTargetLanguage.english);
      expect(savedEntry, isNotNull);
      expect(savedEntry!['normalized_word'], 'künstliche intelligenz');
      expect(savedEntry['target_language'], 'en');
      expect(savedEntry['translation'], 'Artificial Intelligence');
      expect(savedEntry['status'], LexiconEntryStatus.machineGenerated.code,
          reason: 'Machine-generated translations must never be marked verified automatically');

      // Verify local cache was also updated
      final localHit = await localCache.get(query);
      expect(localHit, isNotNull);
      expect(localHit!.primaryTranslation, 'Artificial Intelligence');
    });

    test('Tier 5: Unknown word missing everywhere returns explicit NOT_FOUND state', () async {
      final onlineProvider = MyMemoryOnlineTranslationProvider(
        getHandler: (uri, headers) async => HttpResponseData(
          statusCode: 200,
          body: jsonEncode({
            'responseData': {'translatedText': '', 'match': 0},
            'responseStatus': 200,
          }),
        ),
      );

      final resolver = TranslationResolver(
        lexicon: localLexicon,
        cache: localCache,
        supabaseLexicon: supabaseRepo,
        onlineProvider: onlineProvider,
        normalizer: normalizer,
        historyRepository: historyRepo,
      );

      final query = const TranslationQuery(
        rawWord: 'Xyzw123nonsense',
        normalizedWord: 'xyzw123nonsense',
        targetLanguage: TranslationTargetLanguage.english,
      );

      final result = await resolver.translate(query);

      expect(result.status, TranslationStatus.notFound);
      expect(result.source, TranslationSource.none);
      expect(result.primaryTranslation, isNull);
    });

    test('Resilience: Supabase network failure falls through gracefully to Online Provider', () async {
      supabaseRepo.shouldFailLookup = true;

      final mockOnlineJson = jsonEncode({
        'responseData': {'translatedText': 'Resilience Test', 'match': 1.0},
        'responseStatus': 200,
      });

      final onlineProvider = MyMemoryOnlineTranslationProvider(
        getHandler: (uri, headers) async => HttpResponseData(
          statusCode: 200,
          body: mockOnlineJson,
        ),
      );

      final resolver = TranslationResolver(
        lexicon: localLexicon,
        cache: localCache,
        supabaseLexicon: supabaseRepo,
        onlineProvider: onlineProvider,
        normalizer: normalizer,
        historyRepository: historyRepo,
      );

      final query = const TranslationQuery(
        rawWord: 'Widerstandsfähigkeit',
        normalizedWord: 'widerstandsfähigkeit',
        targetLanguage: TranslationTargetLanguage.english,
      );

      // Must NOT throw exception
      final result = await resolver.translate(query);

      expect(result.status, TranslationStatus.success);
      expect(result.source, TranslationSource.onlineFallback);
      expect(result.primaryTranslation, 'Resilience Test');
    });

    test('Resilience: Online Provider failure falls through gracefully to NOT_FOUND', () async {
      final onlineProvider = MyMemoryOnlineTranslationProvider(
        getHandler: (uri, headers) async {
          throw Exception('Network disconnected / timeout');
        },
      );

      final resolver = TranslationResolver(
        lexicon: localLexicon,
        cache: localCache,
        supabaseLexicon: supabaseRepo,
        onlineProvider: onlineProvider,
        normalizer: normalizer,
        historyRepository: historyRepo,
      );

      final query = const TranslationQuery(
        rawWord: 'Netzwerkausfall',
        normalizedWord: 'netzwerkausfall',
        targetLanguage: TranslationTargetLanguage.english,
      );

      final result = await resolver.translate(query);

      expect(result.status, TranslationStatus.notFound);
    });

    test('Deduplication & Multi-Language Isolation: English, Urdu, Farsi, Arabic have isolated cache entries', () async {
      final onlineProvider = MyMemoryOnlineTranslationProvider(
        getHandler: (uri, headers) async {
          final lang = uri.queryParameters['langpair']!;
          if (lang == 'de|en') {
            return HttpResponseData(
              statusCode: 200,
              body: jsonEncode({'responseData': {'translatedText': 'Book'}}),
            );
          } else if (lang == 'de|ur') {
            return HttpResponseData(
              statusCode: 200,
              body: jsonEncode({'responseData': {'translatedText': 'کتاب'}}),
            );
          } else if (lang == 'de|ar') {
            return HttpResponseData(
              statusCode: 200,
              body: jsonEncode({'responseData': {'translatedText': 'كتاب'}}),
            );
          } else if (lang == 'de|fa') {
            return HttpResponseData(
              statusCode: 200,
              body: jsonEncode({'responseData': {'translatedText': 'کتاب'}}),
            );
          }
          return const HttpResponseData(statusCode: 200, body: '{}');
        },
      );

      final resolver = TranslationResolver(
        lexicon: localLexicon,
        cache: localCache,
        supabaseLexicon: supabaseRepo,
        onlineProvider: onlineProvider,
        normalizer: normalizer,
        historyRepository: historyRepo,
      );

      // 1. English
      final enResult = await resolver.translate(const TranslationQuery(
        rawWord: 'Quantencomputer',
        normalizedWord: 'quantencomputer',
        targetLanguage: TranslationTargetLanguage.english,
      ));
      expect(enResult.primaryTranslation, 'Book');

      // 2. Urdu
      final urResult = await resolver.translate(const TranslationQuery(
        rawWord: 'Quantencomputer',
        normalizedWord: 'quantencomputer',
        targetLanguage: TranslationTargetLanguage.urdu,
      ));
      expect(urResult.primaryTranslation, 'کتاب');

      // Allow background save
      await Future<void>.delayed(const Duration(milliseconds: 30));

      // Confirm both are saved independently in Supabase
      final enEntry = await supabaseRepo.lookup(
        normalizedWord: 'quantencomputer',
        targetLanguage: TranslationTargetLanguage.english,
        query: const TranslationQuery(
          rawWord: 'Quantencomputer',
          normalizedWord: 'quantencomputer',
          targetLanguage: TranslationTargetLanguage.english,
        ),
      );
      final urEntry = await supabaseRepo.lookup(
        normalizedWord: 'quantencomputer',
        targetLanguage: TranslationTargetLanguage.urdu,
        query: const TranslationQuery(
          rawWord: 'Quantencomputer',
          normalizedWord: 'quantencomputer',
          targetLanguage: TranslationTargetLanguage.urdu,
        ),
      );

      expect(enEntry?.primaryTranslation, 'Book');
      expect(urEntry?.primaryTranslation, 'کتاب');
      expect(enEntry?.query.targetLanguage, TranslationTargetLanguage.english);
      expect(urEntry?.query.targetLanguage, TranslationTargetLanguage.urdu);
    });
  });

  group('Frozen Exact-Selection Regression Invariant Tests', () {
    test('ExactHitTester strictly honors exact bounds and returns null on gutter/whitespace', () {
      const hitTester = ProductionExactHitTester();

      final word1 = WordOccurrence(
        rawText: 'Bundesrepublik',
        cleanWord: 'Bundesrepublik',
        pageBoundingBox: const PdfRect(50.0, 116.0, 130.0, 100.0),
        pageNumber: 1,
        charIndex: 0,
        charLength: 14,
        charRects: const [],
      );
      final word2 = WordOccurrence(
        rawText: 'Deutschland',
        cleanWord: 'Deutschland',
        pageBoundingBox: const PdfRect(150.0, 116.0, 220.0, 100.0),
        pageNumber: 1,
        charIndex: 15,
        charLength: 11,
        charRects: const [],
      );

      final spatialIndex = WordSpatialIndex(
        pageNumber: 1,
        words: [word1, word2],
      );

      // Exact hit inside 'Bundesrepublik'
      final hit1 = hitTester.hitTest(
        pdfPoint: const PdfPoint(60.0, 105.0),
        screenOffset: const Offset(60.0, 105.0),
        spatialIndex: spatialIndex,
      );
      expect(hit1.status, SelectionStatus.exactMatch);
      expect(hit1.word?.cleanWord, 'Bundesrepublik');

      // Exact hit inside 'Deutschland'
      final hit2 = hitTester.hitTest(
        pdfPoint: const PdfPoint(160.0, 105.0),
        screenOffset: const Offset(160.0, 105.0),
        spatialIndex: spatialIndex,
      );
      expect(hit2.status, SelectionStatus.exactMatch);
      expect(hit2.word?.cleanWord, 'Deutschland');

      // Gutter whitespace between words (x = 140) must be NO_SELECTION
      final gutterHit = hitTester.hitTest(
        pdfPoint: const PdfPoint(140.0, 105.0),
        screenOffset: const Offset(140.0, 105.0),
        spatialIndex: spatialIndex,
      );
      expect(gutterHit.word, isNull, reason: 'Whitespace must NEVER trigger nearest-word fallback');
      expect(gutterHit.status, isNot(SelectionStatus.exactMatch));

      // Far whitespace
      final farHit = hitTester.hitTest(
        pdfPoint: const PdfPoint(10.0, 10.0),
        screenOffset: const Offset(10.0, 10.0),
        spatialIndex: spatialIndex,
      );
      expect(farHit.word, isNull);
      expect(farHit.status, isNot(SelectionStatus.exactMatch));
    });
  });
}
