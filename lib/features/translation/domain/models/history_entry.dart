// lib/features/translation/domain/models/history_entry.dart

import 'translation_source.dart';
import 'translation_status.dart';
import 'translation_target_language.dart';

/// Represents an automatic chronological lookup audit entry.
/// Kept strictly separated from explicit "My Words" saves.
class HistoryEntry {
  final String id;
  final String rawWord;
  final String normalizedWord;
  final TranslationTargetLanguage targetLanguage;
  final TranslationStatus status;
  final TranslationSource source;
  final String? translation;
  final DateTime lookedUpAt;

  const HistoryEntry({
    required this.id,
    required this.rawWord,
    required this.normalizedWord,
    required this.targetLanguage,
    required this.status,
    required this.source,
    this.translation,
    required this.lookedUpAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HistoryEntry &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
