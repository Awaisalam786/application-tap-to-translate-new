// lib/features/translation/domain/models/user_saved_word.dart

import 'translation_target_language.dart';

/// Represents a German word explicitly saved by the user to "My Words".
/// Kept strictly separated from automatic lookup history.
class UserSavedWord {
  final String id;
  final String word;
  final String normalizedWord;
  final TranslationTargetLanguage targetLanguage;
  final String primaryTranslation;
  final String? partOfSpeech;
  final String? gender;
  final String? contextSentence;
  final DateTime savedAt;

  const UserSavedWord({
    required this.id,
    required this.word,
    required this.normalizedWord,
    required this.targetLanguage,
    required this.primaryTranslation,
    this.partOfSpeech,
    this.gender,
    this.contextSentence,
    required this.savedAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSavedWord &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
