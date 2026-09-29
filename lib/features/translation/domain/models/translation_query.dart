// lib/features/translation/domain/models/translation_query.dart

import 'translation_target_language.dart';

/// Encapsulates the request to translate a German word occurrence.
class TranslationQuery {
  /// The raw word as tapped in the document (including surrounding punctuation if uncleaned).
  final String rawWord;

  /// The normalized lemma form (punctuation stripped, quotes removed, correct capitalization).
  final String normalizedWord;

  /// Target output language.
  final TranslationTargetLanguage targetLanguage;

  /// Optional contextual sentence or phrase where the word appeared.
  final String? contextSentence;

  /// 1-based page number where the word was selected.
  final int? pageNumber;

  const TranslationQuery({
    required this.rawWord,
    required this.normalizedWord,
    required this.targetLanguage,
    this.contextSentence,
    this.pageNumber,
  });

  TranslationQuery copyWith({
    String? rawWord,
    String? normalizedWord,
    TranslationTargetLanguage? targetLanguage,
    String? contextSentence,
    int? pageNumber,
  }) {
    return TranslationQuery(
      rawWord: rawWord ?? this.rawWord,
      normalizedWord: normalizedWord ?? this.normalizedWord,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      contextSentence: contextSentence ?? this.contextSentence,
      pageNumber: pageNumber ?? this.pageNumber,
    );
  }

  /// Cache key uniquely identifying this query by normalized word and language code.
  String get cacheKey => '${normalizedWord.toLowerCase().trim()}_${targetLanguage.code}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TranslationQuery &&
          runtimeType == other.runtimeType &&
          normalizedWord.toLowerCase().trim() ==
              other.normalizedWord.toLowerCase().trim() &&
          targetLanguage == other.targetLanguage;

  @override
  int get hashCode =>
      normalizedWord.toLowerCase().trim().hashCode ^ targetLanguage.hashCode;

  @override
  String toString() =>
      'TranslationQuery(raw: "$rawWord", norm: "$normalizedWord", target: ${targetLanguage.code})';
}
