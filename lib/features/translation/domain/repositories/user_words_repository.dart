// lib/features/translation/domain/repositories/user_words_repository.dart

import '../models/user_saved_word.dart';

/// Contract for managing the user's explicitly saved vocabulary ("My Words").
/// Strictly separated from automatic lookup history.
abstract class UserWordsRepository {
  /// Returns all words explicitly saved by the user.
  Future<List<UserSavedWord>> getSavedWords();

  /// Saves a word to the user's collection.
  Future<void> saveWord(UserSavedWord word);

  /// Removes a word from the user's collection by its identifier.
  Future<void> removeWord(String id);

  /// Checks if a normalized word is already in the user's saved collection.
  Future<bool> isWordSaved(String normalizedWord);
}
