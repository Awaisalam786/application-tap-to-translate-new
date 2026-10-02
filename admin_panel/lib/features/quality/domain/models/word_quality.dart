import '../../../lexicon/domain/models/lexicon_example.dart';
import '../../../lexicon/domain/models/lexicon_sense.dart';
import '../../../lexicon/domain/models/lexicon_synonym.dart';
import '../../../lexicon/domain/models/lexicon_translation.dart';
import '../../../lexicon/domain/models/master_lexicon_entry.dart';

enum WordQualityStatus {
  complete,
  incomplete,
  missingRequired,
  needsReview,
}

extension WordQualityStatusExt on WordQualityStatus {
  String get label {
    switch (this) {
      case WordQualityStatus.complete:
        return 'Complete';
      case WordQualityStatus.incomplete:
        return 'Incomplete';
      case WordQualityStatus.missingRequired:
        return 'Missing Required';
      case WordQualityStatus.needsReview:
        return 'Needs Review';
    }
  }
}

class WordQualityReport {
  final WordQualityStatus status;
  final int score; // 0 to 100
  final List<String> issues;

  const WordQualityReport({
    required this.status,
    required this.score,
    required this.issues,
  });

  /// Deterministically evaluate word quality based ONLY on fields actually present.
  static WordQualityReport evaluate({
    required MasterLexiconEntry entry,
    List<LexiconTranslation>? translations,
    List<LexiconSense>? senses,
    List<LexiconExample>? examples,
    List<LexiconSynonym>? synonyms,
  }) {
    final issues = <String>[];
    int score = 0;

    // 1. Core Lemma and POS check (up to 20 pts)
    if (entry.lemma.trim().isNotEmpty && entry.partOfSpeech.isNotEmpty) {
      score += 20;
    } else {
      issues.add('Missing lemma or part of speech');
    }

    // 2. Grammatical properties for Nouns vs other POS (up to 25 pts)
    final isNoun = entry.partOfSpeech.toLowerCase() == 'noun';
    if (isNoun) {
      final hasGender = entry.gender != null &&
          entry.gender != 'none' &&
          entry.gender!.isNotEmpty;
      final hasPlural = entry.pluralForm != null && entry.pluralForm!.trim().isNotEmpty;

      if (hasGender) {
        score += 15;
      } else {
        issues.add('Noun missing gender / article (der/die/das)');
      }

      if (hasPlural) {
        score += 10;
      } else {
        issues.add('Noun missing plural form');
      }
    } else {
      // Non-nouns get full grammatical points automatically
      score += 25;
    }

    // 3. Translations check (up to 25 pts)
    final transList = translations ?? [];
    final hasEn = transList.any((t) => t.targetLang == 'en' && t.translation.trim().isNotEmpty);
    final hasUr = transList.any((t) => t.targetLang == 'ur' && t.translation.trim().isNotEmpty);
    final hasFa = transList.any((t) => t.targetLang == 'fa' && t.translation.trim().isNotEmpty);
    final hasAr = transList.any((t) => t.targetLang == 'ar' && t.translation.trim().isNotEmpty);

    if (hasEn) {
      score += 15;
    } else {
      issues.add('Missing English translation');
    }

    if (hasUr || hasFa || hasAr) {
      score += 10;
    } else {
      issues.add('Missing additional language translation (UR/FA/AR)');
    }

    // 4. Senses / Definitions (up to 10 pts)
    final senseList = senses ?? [];
    if (senseList.isNotEmpty) {
      score += 10;
    } else {
      issues.add('Missing sense / definition');
    }

    // 5. Context Examples (up to 10 pts)
    final exampleList = examples ?? [];
    if (exampleList.isNotEmpty) {
      score += 10;
    } else {
      issues.add('Missing contextual example');
    }

    // 6. CEFR Level assigned (up to 10 pts)
    if (entry.cefrLevel.isNotEmpty && entry.cefrLevel != 'unclassified') {
      score += 10;
    } else {
      issues.add('CEFR level unclassified');
    }

    score = score.clamp(0, 100);

    // Determine Status
    final WordQualityStatus status;
    final bool missingRequiredField = entry.lemma.trim().isEmpty ||
        (isNoun && (entry.gender == null || entry.gender == 'none' || entry.gender!.isEmpty)) ||
        (!hasEn && transList.isEmpty);

    if (missingRequiredField) {
      status = WordQualityStatus.missingRequired;
    } else if (entry.status == 'review') {
      status = WordQualityStatus.needsReview;
    } else if (score >= 90 && issues.isEmpty) {
      status = WordQualityStatus.complete;
    } else {
      status = WordQualityStatus.incomplete;
    }

    return WordQualityReport(
      status: status,
      score: score,
      issues: issues,
    );
  }
}
