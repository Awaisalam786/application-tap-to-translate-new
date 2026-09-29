// lib/features/translation/domain/repositories/german_lexicon_repository.dart

import '../models/translation_query.dart';
import '../models/translation_result.dart';
import '../models/translation_target_language.dart';

/// Contract for an offline local German lexicon / dictionary.
///
/// DATA PROVENANCE NOTICE:
/// This interface abstracts the dictionary storage backend. The production
/// implementation can bind to licensed or open-source offline datasets
/// (such as FreeDict, Wiktionary German dump, or CC-BY-SA bilingual lexicons)
/// without modifying the reader or translation pipeline.
abstract class GermanLexiconRepository {
  /// Looks up a German word in the local offline lexicon for the specified target language.
  /// Returns `null` if the lemma is not present in the local database.
  Future<TranslationResult?> lookup({
    required String normalizedWord,
    required TranslationTargetLanguage targetLanguage,
    TranslationQuery? query,
  });

  /// Returns true if the lexicon contains an entry for the given normalized word.
  Future<bool> containsWord(String normalizedWord);
}
