// lib/features/translation/presentation/controllers/translation_controller.dart

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/models/word_occurrence.dart';
import '../../data/repositories/default_german_word_normalizer.dart';
import '../../data/repositories/in_memory_history_repository.dart';
import '../../data/repositories/in_memory_translation_cache.dart';
import '../../data/repositories/in_memory_user_words_repository.dart';
import '../../data/repositories/production_german_lexicon_service.dart';
import '../../domain/models/translation_query.dart';
import '../../domain/models/translation_result.dart';
import '../../domain/models/translation_target_language.dart';
import '../../domain/models/user_saved_word.dart';
import '../../domain/repositories/german_lexicon_repository.dart';
import '../../domain/repositories/german_word_normalizer.dart';
import '../../domain/repositories/history_repository.dart';
import '../../domain/repositories/online_translation_provider.dart';
import '../../domain/repositories/translation_cache.dart';
import '../../domain/repositories/user_words_repository.dart';
import '../../domain/usecases/translation_resolver.dart';

import '../../data/repositories/http_supabase_lexicon_repository.dart';
import '../../data/repositories/mymemory_online_translation_provider.dart';
import '../../domain/models/supabase_lexicon_config.dart';
import '../../domain/repositories/supabase_lexicon_repository.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Dependency Providers
// ─────────────────────────────────────────────────────────────────────────────

final germanWordNormalizerProvider = Provider<GermanWordNormalizer>((ref) {
  return const DefaultGermanWordNormalizer();
});

final germanLexiconRepositoryProvider = Provider<GermanLexiconRepository>((ref) {
  return ProductionGermanLexiconService();
});

final translationCacheProvider = Provider<TranslationCache>((ref) {
  return InMemoryTranslationCache();
});

final onlineTranslationProvider = Provider<OnlineTranslationProvider?>((ref) {
  return const MyMemoryOnlineTranslationProvider();
});

final supabaseLexiconRepositoryProvider = Provider<SupabaseLexiconRepository?>((ref) {
  const url = String.fromEnvironment('SUPABASE_URL');
  const anonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

  if (url.isNotEmpty && anonKey.isNotEmpty) {
    return HttpSupabaseLexiconRepository(
      config: const SupabaseLexiconConfig(
        url: url,
        anonKey: anonKey,
      ),
    );
  }
  return null; // Graceful offline/local-first default when unconfigured
});

final userWordsRepositoryProvider = Provider<UserWordsRepository>((ref) {
  return InMemoryUserWordsRepository();
});

final historyRepositoryProvider = Provider<HistoryRepository>((ref) {
  return InMemoryHistoryRepository();
});

final translationResolverProvider = Provider<TranslationResolver>((ref) {
  return TranslationResolver(
    lexicon: ref.watch(germanLexiconRepositoryProvider),
    cache: ref.watch(translationCacheProvider),
    supabaseLexicon: ref.watch(supabaseLexiconRepositoryProvider),
    onlineProvider: ref.watch(onlineTranslationProvider),
    normalizer: ref.watch(germanWordNormalizerProvider),
    historyRepository: ref.watch(historyRepositoryProvider),
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// State & Notifier
// ─────────────────────────────────────────────────────────────────────────────

class TranslationState {
  final TranslationResult? currentResult;
  final TranslationTargetLanguage targetLanguage;
  final bool isLoading;
  final bool isSavedToMyWords;
  final String? lastPronouncedWord;

  const TranslationState({
    this.currentResult,
    this.targetLanguage = TranslationTargetLanguage.english,
    this.isLoading = false,
    this.isSavedToMyWords = false,
    this.lastPronouncedWord,
  });

  TranslationState copyWith({
    TranslationResult? currentResult,
    bool clearResult = false,
    TranslationTargetLanguage? targetLanguage,
    bool? isLoading,
    bool? isSavedToMyWords,
    String? lastPronouncedWord,
  }) {
    return TranslationState(
      currentResult: clearResult ? null : (currentResult ?? this.currentResult),
      targetLanguage: targetLanguage ?? this.targetLanguage,
      isLoading: isLoading ?? this.isLoading,
      isSavedToMyWords: isSavedToMyWords ?? this.isSavedToMyWords,
      lastPronouncedWord: lastPronouncedWord ?? this.lastPronouncedWord,
    );
  }
}

class TranslationNotifier extends StateNotifier<TranslationState> {
  final TranslationResolver _resolver;
  final UserWordsRepository _userWordsRepo;
  final GermanWordNormalizer _normalizer;

  TranslationNotifier({
    required this._resolver,
    required this._userWordsRepo,
    required this._normalizer,
  }) : super(const TranslationState());

  /// Translates an exact selected word occurrence.
  Future<void> translateWord(
    WordOccurrence word, {
    TranslationTargetLanguage? targetLang,
  }) async {
    final lang = targetLang ?? state.targetLanguage;
    final normalized = _normalizer.normalize(word.cleanWord.isNotEmpty ? word.cleanWord : word.rawText);

    debugPrint('[TRANSLATION_RESOLVER] Input WordOccurrence: cleanWord="${word.cleanWord}", rawText="${word.rawText}", isOcr=${word.isOcr}');
    debugPrint('[TRANSLATION_RESOLVER] Normalized lemma query: "$normalized" (Target Language: ${lang.name})');

    final query = TranslationQuery(
      rawWord: word.rawText,
      normalizedWord: normalized,
      targetLanguage: lang,
      pageNumber: word.pageNumber,
    );

    state = state.copyWith(
      targetLanguage: lang,
      isLoading: true,
      currentResult: TranslationResult.loading(query: query),
    );

    final result = await _resolver.translate(query);
    final isSaved = await _userWordsRepo.isWordSaved(result.query.normalizedWord);

    debugPrint('[TRANSLATION_RESOLVER] Lookup Result: raw="${result.query.rawWord}", normalized="${result.query.normalizedWord}", translation="${result.primaryTranslation}", status=${result.status}, source=${result.source.name}');
    debugPrint('[HISTORY] Word "${result.query.normalizedWord}" recorded in History.');

    state = state.copyWith(
      currentResult: result,
      isLoading: false,
      isSavedToMyWords: isSaved,
    );
  }

  /// Changes the target language and automatically re-translates the active word.
  Future<void> setTargetLanguage(TranslationTargetLanguage lang) async {
    if (state.targetLanguage == lang) return;

    final current = state.currentResult;
    state = state.copyWith(targetLanguage: lang);

    if (current != null) {
      final query = TranslationQuery(
        rawWord: current.query.rawWord,
        normalizedWord: current.query.normalizedWord,
        targetLanguage: lang,
        pageNumber: current.query.pageNumber,
      );

      state = state.copyWith(
        isLoading: true,
        currentResult: TranslationResult.loading(query: query),
      );

      final result = await _resolver.translate(query);
      final isSaved = await _userWordsRepo.isWordSaved(result.query.normalizedWord);

      state = state.copyWith(
        currentResult: result,
        isLoading: false,
        isSavedToMyWords: isSaved,
      );
    }
  }

  /// Toggles saving the current word to "My Words" (explicit user action only).
  Future<void> toggleSaveToMyWords() async {
    final result = state.currentResult;
    if (result == null || !result.isSuccess) return;

    final word = result.query.normalizedWord;
    final isCurrentlySaved = state.isSavedToMyWords;

    if (isCurrentlySaved) {
      await _userWordsRepo.removeWord(word);
      state = state.copyWith(isSavedToMyWords: false);
    } else {
      await _userWordsRepo.saveWord(
        UserSavedWord(
          id: '${DateTime.now().millisecondsSinceEpoch}_$word',
          word: result.query.rawWord,
          normalizedWord: word,
          targetLanguage: result.query.targetLanguage,
          primaryTranslation: result.primaryTranslation ?? '',
          partOfSpeech: result.partOfSpeech,
          gender: result.gender,
          savedAt: DateTime.now(),
        ),
      );
      debugPrint('[MY_WORDS] Saved word "$word" to My Words repository.');
      state = state.copyWith(isSavedToMyWords: true);
    }
  }

  /// Pronunciation interface placeholder for TTS integration.
  void playPronunciation() {
    final result = state.currentResult;
    if (result != null) {
      state = state.copyWith(
        lastPronouncedWord: result.query.normalizedWord,
      );
    }
  }

  /// Dismisses the popup.
  void dismissPopup() {
    state = state.copyWith(clearResult: true, isLoading: false);
  }
}

final translationControllerProvider =
    StateNotifierProvider<TranslationNotifier, TranslationState>((ref) {
  return TranslationNotifier(
    resolver: ref.watch(translationResolverProvider),
    userWordsRepo: ref.watch(userWordsRepositoryProvider),
    normalizer: ref.watch(germanWordNormalizerProvider),
  );
});
