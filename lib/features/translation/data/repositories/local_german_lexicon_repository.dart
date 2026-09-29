// lib/features/translation/data/repositories/local_german_lexicon_repository.dart

import '../../domain/models/translation_query.dart';
import '../../domain/models/translation_result.dart';
import '../../domain/models/translation_source.dart';
import '../../domain/models/translation_target_language.dart';
import '../../domain/repositories/german_lexicon_repository.dart';
import '../fixtures/dev_german_lexicon_fixture.dart';

/// Implementation of [GermanLexiconRepository] querying an offline German lexicon.
///
/// DATA PROVENANCE NOTICE:
/// In development and testing, this repository queries [kDevGermanLexiconFixture].
/// The storage mechanism is abstracted so that in production, it seamlessly binds
/// to an indexed SQLite / Isar / Hive database populated from licensed open-source
/// bilingual dictionary dumps (e.g. FreeDict, Wiktionary).
class LocalGermanLexiconRepository implements GermanLexiconRepository {
  final Map<String, DevLexiconEntry> _lexicon;

  const LocalGermanLexiconRepository({
    this._lexicon = kDevGermanLexiconFixture,
  });

  @override
  Future<TranslationResult?> lookup({
    required String normalizedWord,
    required TranslationTargetLanguage targetLanguage,
    TranslationQuery? query,
  }) async {
    if (normalizedWord.isEmpty) return null;

    // Direct lookup
    DevLexiconEntry? entry = _lexicon[normalizedWord];

    // Case-insensitive fallback if direct key not found
    if (entry == null) {
      final lower = normalizedWord.toLowerCase();
      for (final key in _lexicon.keys) {
        if (key.toLowerCase() == lower) {
          entry = _lexicon[key];
          break;
        }
      }
    }

    if (entry == null) return null;

    final primary = entry.translations[targetLanguage];
    if (primary == null) return null;

    final secondaries = entry.secondaryTranslations[targetLanguage] ?? const [];
    final exampleDe = entry.exampleSentenceDe;
    final exampleTr = entry.exampleTranslations[targetLanguage];

    final effectiveQuery = query ??
        TranslationQuery(
          rawWord: normalizedWord,
          normalizedWord: entry.lemma,
          targetLanguage: targetLanguage,
        );

    return TranslationResult.success(
      query: effectiveQuery,
      source: TranslationSource.localLexicon,
      primaryTranslation: primary,
      secondaryTranslations: secondaries,
      partOfSpeech: entry.partOfSpeech,
      gender: entry.gender,
      exampleSentenceDe: exampleDe,
      exampleSentenceTranslation: exampleTr,
    );
  }

  @override
  Future<bool> containsWord(String normalizedWord) async {
    if (_lexicon.containsKey(normalizedWord)) return true;
    final lower = normalizedWord.toLowerCase();
    return _lexicon.keys.any((k) => k.toLowerCase() == lower);
  }
}
