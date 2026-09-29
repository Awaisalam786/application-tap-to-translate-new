// lib/features/translation/domain/models/translation_result.dart

import 'translation_query.dart';
import 'translation_source.dart';
import 'translation_status.dart';

/// The immutable outcome of a translation resolution.
class TranslationResult {
  final TranslationQuery query;
  final TranslationStatus status;
  final TranslationSource source;
  final String? primaryTranslation;
  final List<String> secondaryTranslations;
  final String? partOfSpeech; // e.g. "Substantiv", "Verb", "Adjektiv"
  final String? gender; // "der", "die", "das" for German nouns
  final String? exampleSentenceDe;
  final String? exampleSentenceTranslation;
  final String? errorMessage;
  final DateTime resolvedAt;

  const TranslationResult({
    required this.query,
    required this.status,
    required this.source,
    this.primaryTranslation,
    this.secondaryTranslations = const [],
    this.partOfSpeech,
    this.gender,
    this.exampleSentenceDe,
    this.exampleSentenceTranslation,
    this.errorMessage,
    required this.resolvedAt,
  });

  /// Factory for a successful translation.
  factory TranslationResult.success({
    required TranslationQuery query,
    required TranslationSource source,
    required String primaryTranslation,
    List<String> secondaryTranslations = const [],
    String? partOfSpeech,
    String? gender,
    String? exampleSentenceDe,
    String? exampleSentenceTranslation,
  }) {
    return TranslationResult(
      query: query,
      status: TranslationStatus.success,
      source: source,
      primaryTranslation: primaryTranslation,
      secondaryTranslations: secondaryTranslations,
      partOfSpeech: partOfSpeech,
      gender: gender,
      exampleSentenceDe: exampleSentenceDe,
      exampleSentenceTranslation: exampleSentenceTranslation,
      resolvedAt: DateTime.now(),
    );
  }

  /// Factory for an explicit NOT_FOUND result.
  /// (Strict invariant: never silently invent translations).
  factory TranslationResult.notFound({
    required TranslationQuery query,
  }) {
    return TranslationResult(
      query: query,
      status: TranslationStatus.notFound,
      source: TranslationSource.none,
      resolvedAt: DateTime.now(),
    );
  }

  /// Factory for an error result.
  factory TranslationResult.error({
    required TranslationQuery query,
    required String message,
  }) {
    return TranslationResult(
      query: query,
      status: TranslationStatus.error,
      source: TranslationSource.none,
      errorMessage: message,
      resolvedAt: DateTime.now(),
    );
  }

  /// Factory for loading state.
  factory TranslationResult.loading({
    required TranslationQuery query,
  }) {
    return TranslationResult(
      query: query,
      status: TranslationStatus.loading,
      source: TranslationSource.none,
      resolvedAt: DateTime.now(),
    );
  }

  bool get isSuccess => status == TranslationStatus.success && primaryTranslation != null;
  bool get isNotFound => status == TranslationStatus.notFound;
  bool get isError => status == TranslationStatus.error;
  bool get isLoading => status == TranslationStatus.loading;

  /// Returns a copy of this result with a new source (e.g. when loaded from cache).
  TranslationResult copyWithSource(TranslationSource newSource) {
    return TranslationResult(
      query: query,
      status: status,
      source: newSource,
      primaryTranslation: primaryTranslation,
      secondaryTranslations: secondaryTranslations,
      partOfSpeech: partOfSpeech,
      gender: gender,
      exampleSentenceDe: exampleSentenceDe,
      exampleSentenceTranslation: exampleSentenceTranslation,
      errorMessage: errorMessage,
      resolvedAt: resolvedAt,
    );
  }
}
