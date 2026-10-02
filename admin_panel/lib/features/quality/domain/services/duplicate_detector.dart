import '../../../lexicon/domain/models/lexicon_synonym.dart';
import '../../../lexicon/domain/models/lexicon_translation.dart';
import '../../../lexicon/domain/models/master_lexicon_entry.dart';

enum DuplicateType {
  lemmaPosExact,
  spellingVariant,
  caseOrPunctuationVariant,
  duplicateTranslation,
  duplicateSynonym,
}

extension DuplicateTypeExt on DuplicateType {
  String get label {
    switch (this) {
      case DuplicateType.lemmaPosExact:
        return 'Exact Lemma + POS Match';
      case DuplicateType.spellingVariant:
        return 'German Spelling / Umlaut Variant';
      case DuplicateType.caseOrPunctuationVariant:
        return 'Case / Punctuation Variant';
      case DuplicateType.duplicateTranslation:
        return 'Duplicate Translation';
      case DuplicateType.duplicateSynonym:
        return 'Duplicate Synonym';
    }
  }
}

class DuplicateCandidate {
  final DuplicateType type;
  final MasterLexiconEntry entryA;
  final MasterLexiconEntry? entryB;
  final String description;
  final double confidence; // 0.0 - 1.0
  final String? detail;

  const DuplicateCandidate({
    required this.type,
    required this.entryA,
    this.entryB,
    required this.description,
    this.confidence = 1.0,
    this.detail,
  });
}

class DuplicateDetector {
  /// Normalize umlauts and eszett into base 7-bit ASCII representation:
  /// ä -> ae, ö -> oe, ü -> ue, ß -> ss
  static String foldUmlauts(String text) {
    return text
        .toLowerCase()
        .replaceAll('ä', 'ae')
        .replaceAll('ö', 'oe')
        .replaceAll('ü', 'ue')
        .replaceAll('ß', 'ss')
        .replaceAll(RegExp(r'[^a-z0-9]'), '');
  }

  /// Strip all non-alphanumeric characters and lowercase
  static String foldPunctuation(String text) {
    return text.toLowerCase().replaceAll(RegExp(r'[\s\-_.,;!?"\x27]'), '');
  }

  /// Detect duplicate candidates across entries:
  /// 1. normalized lemma + POS duplicates
  /// 2. spelling / umlaut variants
  /// 3. case / punctuation variants
  static List<DuplicateCandidate> detectEntryDuplicates(
    List<MasterLexiconEntry> entries,
  ) {
    final duplicates = <DuplicateCandidate>[];
    final seenPairs = <String>{};

    for (int i = 0; i < entries.length; i++) {
      final a = entries[i];
      for (int j = i + 1; j < entries.length; j++) {
        final b = entries[j];
        if (a.id == b.id) continue;

        final pairKey = a.id.compareTo(b.id) < 0
            ? '${a.id}_${b.id}'
            : '${b.id}_${a.id}';
        if (seenPairs.contains(pairKey)) continue;

        // 1. Exact normalized lemma + POS duplicate
        if (a.normalizedLemma == b.normalizedLemma &&
            a.partOfSpeech.toLowerCase() == b.partOfSpeech.toLowerCase()) {
          seenPairs.add(pairKey);
          duplicates.add(DuplicateCandidate(
            type: DuplicateType.lemmaPosExact,
            entryA: a,
            entryB: b,
            confidence: 1.0,
            description:
                'Both entries share exact normalized lemma "${a.normalizedLemma}" and POS "${a.partOfSpeech}".',
          ));
          continue;
        }

        // 2. German Umlaut / spelling variant (e.g. Mädchen vs Maedchen, Fußball vs Fussball)
        final foldedA = foldUmlauts(a.lemma);
        final foldedB = foldUmlauts(b.lemma);
        if (foldedA == foldedB &&
            foldedA.isNotEmpty &&
            a.partOfSpeech.toLowerCase() == b.partOfSpeech.toLowerCase()) {
          seenPairs.add(pairKey);
          duplicates.add(DuplicateCandidate(
            type: DuplicateType.spellingVariant,
            entryA: a,
            entryB: b,
            confidence: 0.95,
            description:
                'Umlaut / spelling variation between "${a.lemma}" and "${b.lemma}".',
          ));
          continue;
        }

        // 3. Punctuation / casing variant
        final punctA = foldPunctuation(a.lemma);
        final punctB = foldPunctuation(b.lemma);
        if (punctA == punctB &&
            punctA.isNotEmpty &&
            a.partOfSpeech.toLowerCase() == b.partOfSpeech.toLowerCase()) {
          seenPairs.add(pairKey);
          duplicates.add(DuplicateCandidate(
            type: DuplicateType.caseOrPunctuationVariant,
            entryA: a,
            entryB: b,
            confidence: 0.9,
            description:
                'Casing or punctuation variation between "${a.lemma}" and "${b.lemma}".',
          ));
        }
      }
    }

    return duplicates;
  }

  /// Detect duplicate translations within an entry
  static List<DuplicateCandidate> detectDuplicateTranslations({
    required MasterLexiconEntry entry,
    required List<LexiconTranslation> translations,
  }) {
    final duplicates = <DuplicateCandidate>[];
    final seen = <String, LexiconTranslation>{};

    for (final t in translations) {
      final key = '${t.targetLang}_${t.translation.trim().toLowerCase()}';
      if (seen.containsKey(key)) {
        final original = seen[key]!;
        duplicates.add(DuplicateCandidate(
          type: DuplicateType.duplicateTranslation,
          entryA: entry,
          confidence: 1.0,
          description:
              'Translation "${t.translation}" in [${t.targetLang.toUpperCase()}] is duplicated.',
          detail: 'Matches ID: ${original.id}',
        ));
      } else {
        seen[key] = t;
      }
    }

    return duplicates;
  }

  /// Detect duplicate synonyms within an entry
  static List<DuplicateCandidate> detectDuplicateSynonyms({
    required MasterLexiconEntry entry,
    required List<LexiconSynonym> synonyms,
  }) {
    final duplicates = <DuplicateCandidate>[];
    final seen = <String, LexiconSynonym>{};

    for (final s in synonyms) {
      final key = s.synonymWord.trim().toLowerCase();
      if (seen.containsKey(key)) {
        final original = seen[key]!;
        duplicates.add(DuplicateCandidate(
          type: DuplicateType.duplicateSynonym,
          entryA: entry,
          confidence: 1.0,
          description: 'Synonym "${s.synonymWord}" is duplicated.',
          detail: 'Matches ID: ${original.id}',
        ));
      } else {
        seen[key] = s;
      }
    }

    return duplicates;
  }
}
