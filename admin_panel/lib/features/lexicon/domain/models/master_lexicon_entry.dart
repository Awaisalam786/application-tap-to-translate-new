import '../../../auth/domain/admin_user_model.dart';
import '../../../quality/domain/models/word_quality.dart';
import 'lexicon_example.dart';
import 'lexicon_sense.dart';
import 'lexicon_synonym.dart';
import 'lexicon_translation.dart';

class MasterLexiconEntry {
  final String id;
  final String lemma;
  final String normalizedLemma;
  final String partOfSpeech;
  final String? gender;
  final String? pluralForm;
  final String cefrLevel;
  final String status;
  final int frequencyIndex;
  final String sourceType;
  final String? provenance;
  final String? createdBy;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Embedded relations (when loaded with relations)
  final List<LexiconTranslation>? translations;
  final List<LexiconSense>? senses;
  final List<LexiconExample>? examples;
  final List<LexiconSynonym>? synonyms;

  const MasterLexiconEntry({
    required this.id,
    required this.lemma,
    required this.normalizedLemma,
    required this.partOfSpeech,
    this.gender,
    this.pluralForm,
    this.cefrLevel = 'unclassified',
    this.status = 'draft',
    this.frequencyIndex = 0,
    this.sourceType = 'manual_entry',
    this.provenance,
    this.createdBy,
    this.reviewedBy,
    this.reviewedAt,
    required this.createdAt,
    required this.updatedAt,
    this.translations,
    this.senses,
    this.examples,
    this.synonyms,
  });

  /// Deterministic quality report for this entry
  WordQualityReport get quality => WordQualityReport.evaluate(
        entry: this,
        translations: translations,
        senses: senses,
        examples: examples,
        synonyms: synonyms,
      );

  /// Normalize German lemma for canonical uniqueness:
  /// trims whitespace, converts to lowercase, collapses internal whitespace.
  static String normalizeLemma(String input) {
    return input.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }

  factory MasterLexiconEntry.fromJson(Map<String, dynamic> json) {
    return MasterLexiconEntry(
      id: json['id'] as String,
      lemma: json['lemma'] as String? ?? '',
      normalizedLemma: json['normalized_lemma'] as String? ?? '',
      partOfSpeech: json['part_of_speech'] as String? ?? 'other',
      gender: json['gender'] as String?,
      pluralForm: json['plural_form'] as String?,
      cefrLevel: json['cefr_level'] as String? ?? 'unclassified',
      status: json['status'] as String? ?? 'draft',
      frequencyIndex: json['frequency_index'] as int? ?? 0,
      sourceType: json['source_type'] as String? ?? 'manual_entry',
      provenance: json['provenance'] as String?,
      createdBy: json['created_by'] as String?,
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.tryParse(json['reviewed_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      translations: json['lexicon_translations'] != null
          ? (json['lexicon_translations'] as List)
              .map((t) => LexiconTranslation.fromJson(t as Map<String, dynamic>))
              .toList()
          : null,
      senses: json['lexicon_senses'] != null
          ? (json['lexicon_senses'] as List)
              .map((s) => LexiconSense.fromJson(s as Map<String, dynamic>))
              .toList()
          : null,
      examples: json['lexicon_examples'] != null
          ? (json['lexicon_examples'] as List)
              .map((e) => LexiconExample.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      synonyms: json['lexicon_synonyms'] != null
          ? (json['lexicon_synonyms'] as List)
              .map((s) => LexiconSynonym.fromJson(s as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'lemma': lemma,
      'normalized_lemma': normalizedLemma,
      'part_of_speech': partOfSpeech,
      'gender': gender,
      'plural_form': pluralForm,
      'cefr_level': cefrLevel,
      'status': status,
      'frequency_index': frequencyIndex,
      'source_type': sourceType,
      'provenance': provenance,
      'created_by': createdBy,
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  MasterLexiconEntry copyWith({
    String? id,
    String? lemma,
    String? normalizedLemma,
    String? partOfSpeech,
    String? gender,
    String? pluralForm,
    String? cefrLevel,
    String? status,
    int? frequencyIndex,
    String? sourceType,
    String? provenance,
    String? createdBy,
    String? reviewedBy,
    DateTime? reviewedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<LexiconTranslation>? translations,
    List<LexiconSense>? senses,
    List<LexiconExample>? examples,
    List<LexiconSynonym>? synonyms,
  }) {
    return MasterLexiconEntry(
      id: id ?? this.id,
      lemma: lemma ?? this.lemma,
      normalizedLemma: normalizedLemma ?? this.normalizedLemma,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      gender: gender ?? this.gender,
      pluralForm: pluralForm ?? this.pluralForm,
      cefrLevel: cefrLevel ?? this.cefrLevel,
      status: status ?? this.status,
      frequencyIndex: frequencyIndex ?? this.frequencyIndex,
      sourceType: sourceType ?? this.sourceType,
      provenance: provenance ?? this.provenance,
      createdBy: createdBy ?? this.createdBy,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      translations: translations ?? this.translations,
      senses: senses ?? this.senses,
      examples: examples ?? this.examples,
      synonyms: synonyms ?? this.synonyms,
    );
  }

  // --- Role-Based Capabilities ---

  bool canEdit(AdminRole role) {
    if (role == AdminRole.superadmin || role == AdminRole.reviewer) return true;
    if (role == AdminRole.editor) return status != 'verified';
    return false;
  }

  bool canVerify(AdminRole role) {
    return role == AdminRole.superadmin || role == AdminRole.reviewer;
  }

  bool canDelete(AdminRole role) {
    return role == AdminRole.superadmin;
  }
}
