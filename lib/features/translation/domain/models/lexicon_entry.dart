// lib/features/translation/domain/models/lexicon_entry.dart

import 'lexicon_entry_status.dart';
import 'lexicon_translation.dart';
import 'source_provenance.dart';

/// Production-ready German lexical database entry.
///
/// Fully extensible entity supporting grammatical metadata, multilingual translations,
/// inflection mappings, and rigorous source provenance.
class LexiconEntry {
  /// The headword / surface lemma (e.g. "Deutschland", "arbeiten", "Möglichkeit").
  final String word;

  /// Canonical dictionary lemma form (e.g. "arbeiten", "Möglichkeit").
  final String lemma;

  /// Grammatical definite article for German nouns ("der", "die", "das", or null).
  final String? article;

  /// Part of speech category (e.g. "Substantiv", "Verb", "Adjektiv", "Adverb").
  final String partOfSpeech;

  /// Grammatical gender for nouns ("Maskulinum", "Femininum", "Neutrum", or null).
  final String? gender;

  /// Nominative plural form for German nouns (e.g. "Möglichkeiten", "Bücher", "Häuser").
  final String? plural;

  /// Monolingual German definitions and sense glosses.
  final List<String> meanings;

  /// Monolingual German synonyms (e.g. from OpenThesaurus).
  final List<String> synonyms;

  /// Authentic German contextual example sentences (e.g. from Tatoeba / Wiktionary).
  final List<String> examples;

  /// International Phonetic Alphabet (IPA) pronunciation (e.g. "/ˈdɔɪ̯t͡ʃlant/").
  final String? pronunciation;

  /// Primary headword language code (default 'de').
  final String language;

  /// Ingestion / editorial verification status.
  final LexiconEntryStatus status;

  /// Confidence score between 0.0 and 1.0 (1.0 = curated/verified).
  final double confidence;

  /// Last modification timestamp.
  final DateTime updatedAt;

  /// Source provenance and attribution metadata.
  final SourceProvenance provenance;

  /// Extensible multilingual translations list (en, ur, fa, ar, etc.).
  final List<LexiconTranslation> translations;

  /// Inflected surface forms that point to this lemma
  /// (e.g. "arbeitet", "arbeitete", "gearbeitet" -> "arbeiten").
  final List<String> inflectedForms;

  const LexiconEntry({
    required this.word,
    required this.lemma,
    this.article,
    required this.partOfSpeech,
    this.gender,
    this.plural,
    this.meanings = const [],
    this.synonyms = const [],
    this.examples = const [],
    this.pronunciation,
    this.language = 'de',
    this.status = LexiconEntryStatus.verified,
    this.confidence = 1.0,
    required this.updatedAt,
    required this.provenance,
    this.translations = const [],
    this.inflectedForms = const [],
  });

  /// Convenience getters delegating to provenance for top-level access
  String get source => provenance.source;
  String get sourceId => provenance.sourceId;
  String get license => provenance.license;

  /// Retrieves the translation for a specific target language code (e.g. "en", "ur").
  LexiconTranslation? translationFor(String langCode) {
    final lower = langCode.toLowerCase().trim();
    for (final tr in translations) {
      if (tr.language.toLowerCase() == lower) return tr;
    }
    return null;
  }

  /// Checks if this entry matches a query word (by surface, lemma, or inflected form).
  bool matches(String query) {
    final q = query.toLowerCase().trim();
    if (word.toLowerCase() == q) return true;
    if (lemma.toLowerCase() == q) return true;
    return inflectedForms.any((f) => f.toLowerCase() == q);
  }
}
