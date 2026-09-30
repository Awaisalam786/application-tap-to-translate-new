// test/features/translation/domain/translation_resolver_test.dart

import 'package:flutter_test/flutter_test.dart';
import 'package:tap_to_translate/features/translation/data/repositories/default_german_word_normalizer.dart';
import 'package:tap_to_translate/features/translation/data/repositories/in_memory_history_repository.dart';
import 'package:tap_to_translate/features/translation/data/repositories/in_memory_translation_cache.dart';
import 'package:tap_to_translate/features/translation/data/repositories/in_memory_user_words_repository.dart';
import 'package:tap_to_translate/features/translation/data/repositories/local_german_lexicon_repository.dart';
import 'package:tap_to_translate/features/translation/domain/models/translation_query.dart';
import 'package:tap_to_translate/features/translation/domain/models/translation_result.dart';
import 'package:tap_to_translate/features/translation/domain/models/translation_source.dart';
import 'package:tap_to_translate/features/translation/domain/models/translation_status.dart';
import 'package:tap_to_translate/features/translation/domain/models/translation_target_language.dart';
import 'package:tap_to_translate/features/translation/domain/models/user_saved_word.dart';
import 'package:tap_to_translate/features/translation/domain/repositories/online_translation_provider.dart';
import 'package:tap_to_translate/features/translation/domain/usecases/translation_resolver.dart';

/// Mock online provider for testing Tier 3 fallback
class MockOnlineTranslationProvider implements OnlineTranslationProvider {
  final Map<String, String> onlineTranslations;
  bool isOnlineAvailable;
  int callCount = 0;

  MockOnlineTranslationProvider({
    this.onlineTranslations = const {},
    this.isOnlineAvailable = true,
  });

  @override
  String get name => 'mock';

  @override
  bool get isAvailable => isOnlineAvailable;

  @override
  Future<TranslationResult?> translate(TranslationQuery query) async {
    callCount++;
    final match = onlineTranslations[query.normalizedWord.toLowerCase()];
    if (match != null) {
      return TranslationResult.success(
        query: query,
        source: TranslationSource.onlineFallback,
        primaryTranslation: match,
      );
    }
    return null;
  }
}

void main() {
  group('TranslationResolver Local-First Hierarchy Tests', () {
    late LocalGermanLexiconRepository lexiconRepo;
    late InMemoryTranslationCache cache;
    late DefaultGermanWordNormalizer normalizer;
    late InMemoryHistoryRepository historyRepo;
    late InMemoryUserWordsRepository userWordsRepo;
    late MockOnlineTranslationProvider mockOnline;
    late TranslationResolver resolver;

    setUp(() {
      lexiconRepo = const LocalGermanLexiconRepository();
      cache = InMemoryTranslationCache();
      normalizer = const DefaultGermanWordNormalizer();
      historyRepo = InMemoryHistoryRepository();
      userWordsRepo = InMemoryUserWordsRepository();
      mockOnline = MockOnlineTranslationProvider(
        onlineTranslations: {'internetwort': 'internet word'},
      );

      resolver = TranslationResolver(
        lexicon: lexiconRepo,
        cache: cache,
        onlineProvider: mockOnline,
        normalizer: normalizer,
        historyRepository: historyRepo,
      );
    });

    test('1. Exact word -> local translation (Tier 1: Local Lexicon Hit)', () async {
      final query = const TranslationQuery(
        rawWord: 'Deutschland.',
        normalizedWord: 'Deutschland',
        targetLanguage: TranslationTargetLanguage.english,
      );

      final result = await resolver.translate(query);

      expect(result.status, equals(TranslationStatus.success));
      expect(result.source, equals(TranslationSource.localLexicon));
      expect(result.primaryTranslation, equals('Germany'));
      expect(result.gender, equals('das'));
      expect(result.partOfSpeech, contains('Substantiv'));

      // Invariant: Hit must be automatically cached
      expect(cache.size, equals(1));
      expect(cache.containsKey(query.cacheKey), isTrue);
    });

    test('2. Cache Hit (Tier 2: Cache)', () async {
      // Manually pre-populate cache with a custom translation
      const cachedQuery = TranslationQuery(
        rawWord: 'seltenesWort',
        normalizedWord: 'seltenesWort',
        targetLanguage: TranslationTargetLanguage.english,
      );

      await cache.put(
        TranslationResult.success(
          query: cachedQuery,
          source: TranslationSource.localLexicon,
          primaryTranslation: 'rare word from cache',
        ),
      );

      // Lookup word that is NOT in local lexicon, but in cache
      final result = await resolver.translate(cachedQuery);

      expect(result.status, equals(TranslationStatus.success));
      expect(result.source, equals(TranslationSource.cache));
      expect(result.primaryTranslation, equals('rare word from cache'));
      expect(mockOnline.callCount, equals(0)); // Online provider never called on cache hit
    });

    test('3. Cache Miss falls through to next tier', () async {
      expect(cache.size, equals(0));

      const query = TranslationQuery(
        rawWord: 'arbeiten',
        normalizedWord: 'arbeiten',
        targetLanguage: TranslationTargetLanguage.english,
      );

      final result = await resolver.translate(query);
      expect(result.status, equals(TranslationStatus.success));
      expect(result.source, equals(TranslationSource.localLexicon));
      expect(result.primaryTranslation, equals('to work'));
    });

    test('4. Optional Online Fallback (Tier 3: Online Provider)', () async {
      const query = TranslationQuery(
        rawWord: 'internetwort',
        normalizedWord: 'internetwort',
        targetLanguage: TranslationTargetLanguage.english,
      );

      final result = await resolver.translate(query);

      expect(result.status, equals(TranslationStatus.success));
      expect(result.source, equals(TranslationSource.onlineFallback));
      expect(result.primaryTranslation, equals('internet word'));
      expect(mockOnline.callCount, equals(1));

      // Invariant: Successful online result is now cached locally
      expect(cache.containsKey(query.cacheKey), isTrue);

      // Subsequent query hits Tier 2 cache, not online provider again
      final cachedResult = await resolver.translate(query);
      expect(cachedResult.source, equals(TranslationSource.cache));
      expect(mockOnline.callCount, equals(1)); // No additional network call
    });

    test('5. Explicit NOT_FOUND (Tier 4: No Hallucination)', () async {
      const query = TranslationQuery(
        rawWord: 'unbekanntesxyz',
        normalizedWord: 'unbekanntesxyz',
        targetLanguage: TranslationTargetLanguage.english,
      );

      final result = await resolver.translate(query);

      expect(result.status, equals(TranslationStatus.notFound));
      expect(result.source, equals(TranslationSource.none));
      expect(result.primaryTranslation, isNull);
      expect(result.isNotFound, isTrue);
    });

    test('6. Target Language Switching across English, Urdu, Farsi, and Arabic', () async {
      // Test "Möglichkeit" across all 4 target languages
      const languages = [
        TranslationTargetLanguage.english,
        TranslationTargetLanguage.urdu,
        TranslationTargetLanguage.farsi,
        TranslationTargetLanguage.arabic,
      ];

      for (final lang in languages) {
        final query = TranslationQuery(
          rawWord: 'Möglichkeit',
          normalizedWord: 'Möglichkeit',
          targetLanguage: lang,
        );

        final result = await resolver.translate(query);
        expect(result.status, equals(TranslationStatus.success));
        expect(result.primaryTranslation, isNotNull);
        expect(result.primaryTranslation!.isNotEmpty, isTrue);
      }

      // Verify specific translations from fixture
      final urResult = await resolver.translate(
        const TranslationQuery(
          rawWord: 'Buch',
          normalizedWord: 'Buch',
          targetLanguage: TranslationTargetLanguage.urdu,
        ),
      );
      expect(urResult.primaryTranslation, equals('کتاب'));

      final faResult = await resolver.translate(
        const TranslationQuery(
          rawWord: 'Haus',
          normalizedWord: 'Haus',
          targetLanguage: TranslationTargetLanguage.farsi,
        ),
      );
      expect(faResult.primaryTranslation, contains('خانه'));

      final arResult = await resolver.translate(
        const TranslationQuery(
          rawWord: 'Deutschland',
          normalizedWord: 'Deutschland',
          targetLanguage: TranslationTargetLanguage.arabic,
        ),
      );
      expect(arResult.primaryTranslation, equals('ألمانيا'));
    });

    test('7. History vs. My Words Separation Invariant', () async {
      // Initial state: Both repos empty
      expect(historyRepo.count, equals(0));
      expect(userWordsRepo.count, equals(0));

      // 1. Perform automatic lookups (one hit, one notFound)
      await resolver.translate(
        const TranslationQuery(
          rawWord: 'lernen',
          normalizedWord: 'lernen',
          targetLanguage: TranslationTargetLanguage.english,
        ),
      );

      await resolver.translate(
        const TranslationQuery(
          rawWord: 'nichtda',
          normalizedWord: 'nichtda',
          targetLanguage: TranslationTargetLanguage.english,
        ),
      );

      // Invariant: History automatically records both lookups
      expect(historyRepo.count, equals(2));
      final history = await historyRepo.getRecentHistory();
      expect(history[0].rawWord, equals('nichtda'));
      expect(history[0].status, equals(TranslationStatus.notFound));
      expect(history[1].rawWord, equals('lernen'));
      expect(history[1].status, equals(TranslationStatus.success));

      // Invariant: My Words remains COMPLETELY EMPTY until user explicitly saves
      expect(userWordsRepo.count, equals(0));
      expect(await userWordsRepo.isWordSaved('lernen'), isFalse);

      // 2. User explicitly saves "lernen"
      await userWordsRepo.saveWord(
        UserSavedWord(
          id: 'saved_1',
          word: 'lernen',
          normalizedWord: 'lernen',
          targetLanguage: TranslationTargetLanguage.english,
          primaryTranslation: 'to learn, to study',
          savedAt: DateTime.now(),
        ),
      );

      // Invariant: My Words now has 1 entry; History is unaffected
      expect(userWordsRepo.count, equals(1));
      expect(await userWordsRepo.isWordSaved('lernen'), isTrue);
      expect(historyRepo.count, equals(2));
    });
  });
}
