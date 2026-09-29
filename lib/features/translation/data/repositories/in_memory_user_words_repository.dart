// lib/features/translation/data/repositories/in_memory_user_words_repository.dart

import '../../domain/models/user_saved_word.dart';
import '../../domain/repositories/user_words_repository.dart';

/// In-memory implementation of [UserWordsRepository] for explicit "My Words" saves.
class InMemoryUserWordsRepository implements UserWordsRepository {
  final Map<String, UserSavedWord> _savedWords = {};

  @override
  Future<List<UserSavedWord>> getSavedWords() async {
    return _savedWords.values.toList()
      ..sort((a, b) => b.savedAt.compareTo(a.savedAt));
  }

  @override
  Future<void> saveWord(UserSavedWord word) async {
    _savedWords[word.normalizedWord.toLowerCase().trim()] = word;
  }

  @override
  Future<void> removeWord(String id) async {
    _savedWords.removeWhere((k, v) => v.id == id || v.normalizedWord.toLowerCase() == id.toLowerCase());
  }

  @override
  Future<bool> isWordSaved(String normalizedWord) async {
    return _savedWords.containsKey(normalizedWord.toLowerCase().trim());
  }

  int get count => _savedWords.length;
}
