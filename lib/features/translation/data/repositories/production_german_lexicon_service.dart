// lib/features/translation/data/repositories/production_german_lexicon_service.dart

import '../../domain/models/lexicon_entry.dart';
import '../../domain/models/translation_query.dart';
import '../../domain/models/translation_result.dart';
import '../../domain/models/translation_source.dart';
import '../../domain/models/translation_target_language.dart';
import '../../domain/repositories/german_inflection_resolver.dart';
import '../../domain/repositories/german_lexicon_repository.dart';
import '../fixtures/production_lexicon_sample.dart';

/// Production-ready German Lexicon Service.
///
/// Implements [GermanLexiconRepository] and [GermanInflectionResolver].
///
/// ARCHITECTURAL PRINCIPLES:
/// 1. Strict separation between surface cleaning and morphological resolution.
/// 2. NO fake/heuristic suffix stripping for German lemmatization. Inflections
///    must be backed by verified lexical entries and index tables.
/// 3. Transparent source provenance: every entry carries its source, license,
///    and curation status.
/// 4. Multilingual support: entries contain senses for EN, UR, FA, AR.
class ProductionGermanLexiconService
    implements GermanLexiconRepository, GermanInflectionResolver {
  final List<LexiconEntry> _entries;

  /// Fast lookup index: primary headwords / lemmas (lowercase -> LexiconEntry)
  final Map<String, LexiconEntry> _headwordIndex = {};

  /// Morphological inflection index: inflected surface form -> canonical lemma
  final Map<String, String> _inflectionIndex = {};

  ProductionGermanLexiconService({
    List<LexiconEntry>? entries,
  }) : _entries = entries ?? kProductionSampleLexicon {
    _buildIndices();
  }

  void _buildIndices() {
    for (final entry in _entries) {
      final wordLower = entry.word.toLowerCase();
      final lemmaLower = entry.lemma.toLowerCase();

      _headwordIndex[wordLower] = entry;
      _headwordIndex[lemmaLower] = entry;

      // Register plural if noun
      if (entry.plural != null && entry.plural!.isNotEmpty) {
        _inflectionIndex[entry.plural!.toLowerCase()] = entry.lemma;
      }

      // Register all verified inflected forms
      for (final form in entry.inflectedForms) {
        final formLower = form.toLowerCase();
        _inflectionIndex[formLower] = entry.lemma;
      }
    }
  }

  // ===========================================================================
  // GERMAN INFLECTION RESOLVER CONTRACT
  // ===========================================================================

  static const String _punctuationChars =
      '„“"\'«»›‹()[]{}<>—–-_.,;:!?\r\n\t ';

  @override
  String normalizeSurface(String rawWord) {
    if (rawWord.isEmpty) return '';

    int start = 0;
    while (start < rawWord.length && _punctuationChars.contains(rawWord[start])) {
      start++;
    }

    int end = rawWord.length;
    while (end > start && _punctuationChars.contains(rawWord[end - 1])) {
      end--;
    }

    if (start >= end) return '';
    return rawWord.substring(start, end).trim();
  }

  @override
  String? resolveToLemma(String surfaceWord) {
    final cleaned = normalizeSurface(surfaceWord).toLowerCase();
    if (cleaned.isEmpty) return null;

    // If it's already a direct headword/lemma, return null (it is already canonical)
    if (_headwordIndex.containsKey(cleaned)) {
      final canonical = _headwordIndex[cleaned]!.lemma;
      if (canonical.toLowerCase() == cleaned) {
        return null;
      }
    }

    // Check morphological inflection index
    return _inflectionIndex[cleaned];
  }

  @override
  List<String> generateSearchVariants(String normalizedWord) {
    final cleaned = normalizeSurface(normalizedWord);
    if (cleaned.isEmpty) return const [];

    final variants = <String>{};

    // 1. As-is
    variants.add(cleaned);

    // 2. Capitalized variant (Standard German noun casing: e.g. "deutschland" -> "Deutschland")
    final capitalized =
        cleaned[0].toUpperCase() + cleaned.substring(1).toLowerCase();
    variants.add(capitalized);

    // 3. Lowercase variant (Standard German verb/adjective casing: e.g. "Arbeiten" -> "arbeiten")
    final lower = cleaned.toLowerCase();
    variants.add(lower);

    // 4. Eszett / double-s orthographic variants
    if (cleaned.contains('ß')) {
      variants.add(cleaned.replaceAll('ß', 'ss'));
      variants.add(capitalized.replaceAll('ß', 'ss'));
      variants.add(lower.replaceAll('ß', 'ss'));
    }
    if (cleaned.toLowerCase().contains('ss')) {
      variants.add(cleaned.replaceAll('ss', 'ß'));
      variants.add(capitalized.replaceAll('ss', 'ß'));
      variants.add(lower.replaceAll('ss', 'ß'));
    }

    // 5. German Umlaut ASCII transcription aliases (ä -> ae, ö -> oe, ü -> ue)
    if (cleaned.contains('ä') || cleaned.contains('ö') || cleaned.contains('ü') ||
        cleaned.contains('Ä') || cleaned.contains('Ö') || cleaned.contains('Ü')) {
      final folded = cleaned
          .replaceAll('ä', 'ae')
          .replaceAll('ö', 'oe')
          .replaceAll('ü', 'ue')
          .replaceAll('Ä', 'Ae')
          .replaceAll('Ö', 'Oe')
          .replaceAll('Ü', 'Ue');
      variants.add(folded);
      variants.add(folded.toLowerCase());
    }

    // Reverse transcription aliases (ae -> ä, oe -> ö, ue -> ü)
    if (cleaned.toLowerCase().contains('ae') ||
        cleaned.toLowerCase().contains('oe') ||
        cleaned.toLowerCase().contains('ue')) {
      final umlauted = cleaned
          .replaceAll('ae', 'ä')
          .replaceAll('oe', 'ö')
          .replaceAll('ue', 'ü')
          .replaceAll('Ae', 'Ä')
          .replaceAll('Oe', 'Ö')
          .replaceAll('Ue', 'Ü');
      variants.add(umlauted);
      variants.add(umlauted.toLowerCase());
    }

    return variants.toList();
  }

  // ===========================================================================
  // PRODUCTION LEXICON QUERY API
  // ===========================================================================

  /// Looks up the rich [LexiconEntry] for a given query word.
  ///
  /// Searches:
  /// 1. Exact match
  /// 2. Cleaned surface form
  /// 3. Morphological inflection index (resolving inflections to canonical lemma)
  /// 4. Orthographic search variants (casing, ß <-> ss, umlauts)
  LexiconEntry? lookupEntry(String queryWord) {
    if (queryWord.isEmpty) return null;

    final cleaned = normalizeSurface(queryWord);
    if (cleaned.isEmpty) return null;

    // 1. Direct lowercase match in headwords
    final lower = cleaned.toLowerCase();
    if (_headwordIndex.containsKey(lower)) {
      return _headwordIndex[lower];
    }

    // 2. Morphological resolution via inflection index
    final lemma = resolveToLemma(cleaned);
    if (lemma != null) {
      final lemmaLower = lemma.toLowerCase();
      if (_headwordIndex.containsKey(lemmaLower)) {
        return _headwordIndex[lemmaLower];
      }
    }

    // 3. Search variants (orthography & casing)
    final variants = generateSearchVariants(cleaned);
    for (final variant in variants) {
      final vLower = variant.toLowerCase();
      if (_headwordIndex.containsKey(vLower)) {
        return _headwordIndex[vLower];
      }
      if (_inflectionIndex.containsKey(vLower)) {
        final targetLemma = _inflectionIndex[vLower]!.toLowerCase();
        if (_headwordIndex.containsKey(targetLemma)) {
          return _headwordIndex[targetLemma];
        }
      }
    }

    return null;
  }

  // ===========================================================================
  // GERMAN LEXICON REPOSITORY CONTRACT IMPLEMENTATION
  // ===========================================================================

  @override
  Future<TranslationResult?> lookup({
    required String normalizedWord,
    required TranslationTargetLanguage targetLanguage,
    TranslationQuery? query,
  }) async {
    final entry = lookupEntry(normalizedWord);
    if (entry == null) return null;

    final translation = entry.translationFor(targetLanguage.code);
    if (translation == null || translation.meanings.isEmpty) return null;

    final primary = translation.meanings.first;
    final secondaries = translation.meanings.length > 1
        ? translation.meanings.sublist(1)
        : const <String>[];

    final exampleDe = entry.examples.isNotEmpty ? entry.examples.first : null;
    final exampleTr = translation.exampleTranslation;

    final effectiveQuery = query != null
        ? query.copyWith(normalizedWord: entry.lemma)
        : TranslationQuery(
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
    return lookupEntry(normalizedWord) != null;
  }
}
