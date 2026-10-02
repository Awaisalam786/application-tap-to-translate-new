import 'package:german_lexicon_admin/features/lexicon/domain/models/lexicon_example.dart';
import 'package:german_lexicon_admin/features/lexicon/domain/models/lexicon_sense.dart';
import 'package:german_lexicon_admin/features/lexicon/domain/models/lexicon_synonym.dart';
import 'package:german_lexicon_admin/features/lexicon/domain/models/lexicon_translation.dart';
import 'package:german_lexicon_admin/features/lexicon/domain/models/master_lexicon_entry.dart';

enum ReviewCategory {
  masterWords,
  translations,
  senses,
  synonyms,
  examples;

  String get label {
    switch (this) {
      case ReviewCategory.masterWords:
        return 'Master Words';
      case ReviewCategory.translations:
        return 'Translations';
      case ReviewCategory.senses:
        return 'Senses';
      case ReviewCategory.synonyms:
        return 'Synonyms';
      case ReviewCategory.examples:
        return 'Examples';
    }
  }
}

class ReviewQueueItem {
  final String id;
  final String entryId;
  final String parentLemma;
  final ReviewCategory category;
  final String title;
  final String? subtitle;
  final String? details;
  final String? partOfSpeech;
  final String? cefrLevel;
  final String status;
  final DateTime updatedAt;

  // Underlying data objects for editing/inspecting
  final MasterLexiconEntry? rawMasterEntry;
  final LexiconTranslation? rawTranslation;
  final LexiconSense? rawSense;
  final LexiconSynonym? rawSynonym;
  final LexiconExample? rawExample;

  const ReviewQueueItem({
    required this.id,
    required this.entryId,
    required this.parentLemma,
    required this.category,
    required this.title,
    this.subtitle,
    this.details,
    this.partOfSpeech,
    this.cefrLevel,
    this.status = 'review',
    required this.updatedAt,
    this.rawMasterEntry,
    this.rawTranslation,
    this.rawSense,
    this.rawSynonym,
    this.rawExample,
  });

  factory ReviewQueueItem.fromMasterEntry(MasterLexiconEntry entry) {
    return ReviewQueueItem(
      id: entry.id,
      entryId: entry.id,
      parentLemma: entry.lemma,
      category: ReviewCategory.masterWords,
      title: entry.lemma,
      subtitle: '${entry.partOfSpeech}${entry.gender != null && entry.gender != 'none' ? ' (${entry.gender})' : ''}',
      details: entry.provenance,
      partOfSpeech: entry.partOfSpeech,
      cefrLevel: entry.cefrLevel,
      status: entry.status,
      updatedAt: entry.updatedAt,
      rawMasterEntry: entry,
    );
  }

  factory ReviewQueueItem.fromTranslation({
    required LexiconTranslation translation,
    required String parentLemma,
    String? partOfSpeech,
    String? cefrLevel,
  }) {
    return ReviewQueueItem(
      id: translation.id,
      entryId: translation.entryId,
      parentLemma: parentLemma,
      category: ReviewCategory.translations,
      title: translation.translation,
      subtitle: '${LexiconTranslation.languageName(translation.targetLang)} [${translation.targetLang.toUpperCase()}]',
      details: translation.contextNotes,
      partOfSpeech: partOfSpeech,
      cefrLevel: cefrLevel,
      status: translation.status,
      updatedAt: translation.updatedAt,
      rawTranslation: translation,
    );
  }

  factory ReviewQueueItem.fromSense({
    required LexiconSense sense,
    required String parentLemma,
    String? partOfSpeech,
    String? cefrLevel,
    String parentStatus = 'review',
  }) {
    return ReviewQueueItem(
      id: sense.id,
      entryId: sense.entryId,
      parentLemma: parentLemma,
      category: ReviewCategory.senses,
      title: 'Sense #${sense.senseOrder}: ${sense.definitionDe}',
      subtitle: sense.contextDomain,
      details: sense.definitionEn,
      partOfSpeech: partOfSpeech,
      cefrLevel: cefrLevel,
      status: parentStatus,
      updatedAt: sense.updatedAt,
      rawSense: sense,
    );
  }

  factory ReviewQueueItem.fromSynonym({
    required LexiconSynonym synonym,
    required String parentLemma,
    String? partOfSpeech,
    String? cefrLevel,
  }) {
    return ReviewQueueItem(
      id: synonym.id,
      entryId: synonym.entryId,
      parentLemma: parentLemma,
      category: ReviewCategory.synonyms,
      title: synonym.synonymWord,
      subtitle: 'Synonym of $parentLemma',
      details: synonym.nuanceNote,
      partOfSpeech: partOfSpeech,
      cefrLevel: cefrLevel,
      status: synonym.status,
      updatedAt: synonym.updatedAt,
      rawSynonym: synonym,
    );
  }

  factory ReviewQueueItem.fromExample({
    required LexiconExample example,
    required String parentLemma,
    String? partOfSpeech,
  }) {
    return ReviewQueueItem(
      id: example.id,
      entryId: example.entryId,
      parentLemma: parentLemma,
      category: ReviewCategory.examples,
      title: example.sentenceDe,
      subtitle: example.sentenceEn,
      details: example.sentenceUr,
      partOfSpeech: partOfSpeech,
      cefrLevel: example.cefrLevel,
      status: example.status,
      updatedAt: example.updatedAt,
      rawExample: example,
    );
  }
}
