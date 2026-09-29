// lib/features/translation/domain/models/lexicon_translation.dart

import 'lexicon_entry_status.dart';
import 'source_provenance.dart';

/// Represents a targeted translation sense in a specific language.
///
/// Designed to scale to arbitrary languages (en, ur, fa, ar, etc.)
/// without requiring relational schema migrations or field additions.
class LexiconTranslation {
  /// ISO 639-1 two-letter language code (e.g. 'en', 'ur', 'fa', 'ar').
  final String language;

  /// Ordered list of targeted meanings and definitions in this language.
  final List<String> meanings;

  /// Optional contextual synonyms in this target language.
  final List<String> synonyms;

  /// Optional example translation matching the primary German example.
  final String? exampleTranslation;

  /// Quality/curation status for this specific language pair.
  final LexiconEntryStatus status;

  /// Provenance tracking specifically for this language sense.
  final SourceProvenance provenance;

  const LexiconTranslation({
    required this.language,
    required this.meanings,
    this.synonyms = const [],
    this.exampleTranslation,
    this.status = LexiconEntryStatus.verified,
    required this.provenance,
  });

  /// The primary (first) translation meaning.
  String get primaryMeaning =>
      meanings.isNotEmpty ? meanings.first : '';

  Map<String, dynamic> toJson() => {
        'language': language,
        'meanings': meanings,
        'synonyms': synonyms,
        'exampleTranslation': exampleTranslation,
        'status': status.code,
        'provenance': provenance.toJson(),
      };

  factory LexiconTranslation.fromJson(Map<String, dynamic> json) =>
      LexiconTranslation(
        language: json['language'] as String,
        meanings: List<String>.from(json['meanings'] as List),
        synonyms: json['synonyms'] != null
            ? List<String>.from(json['synonyms'] as List)
            : const [],
        exampleTranslation: json['exampleTranslation'] as String?,
        status: LexiconEntryStatus.fromCode(json['status'] as String? ?? 'VERIFIED'),
        provenance: SourceProvenance.fromJson(
            json['provenance'] as Map<String, dynamic>),
      );
}
