// lib/features/translation/data/repositories/in_memory_supabase_lexicon_repository.dart

import '../../domain/models/lexicon_entry_status.dart';
import '../../domain/models/translation_query.dart';
import '../../domain/models/translation_result.dart';
import '../../domain/models/translation_source.dart';
import '../../domain/models/translation_target_language.dart';
import '../../domain/repositories/supabase_lexicon_repository.dart';

/// In-memory mock/emulator of [SupabaseLexiconRepository] for unit testing and offline development.
class InMemorySupabaseLexiconRepository implements SupabaseLexiconRepository {
  /// Canonical storage: key is `${normalizedWord.toLowerCase()}_${targetLang.code}`
  final Map<String, Map<String, dynamic>> _entries = {};
  final List<Map<String, dynamic>> requestsLog = [];

  bool available;
  bool shouldFailSave;
  bool shouldFailLookup;
  int lookupCount = 0;
  int saveCount = 0;

  InMemorySupabaseLexiconRepository({
    this.available = true,
    this.shouldFailSave = false,
    this.shouldFailLookup = false,
    Map<String, String>? initialTranslations,
  }) {
    if (initialTranslations != null) {
      for (final entry in initialTranslations.entries) {
        // Assume key format: "word_langCode", e.g. "technologie_en"
        final parts = entry.key.split('_');
        final word = parts[0].toLowerCase();
        final lang = parts.length > 1 ? parts[1] : 'en';
        final key = '${word}_$lang';
        _entries[key] = {
          'german_word': word,
          'normalized_word': word,
          'target_language': lang,
          'translation': entry.value,
          'status': LexiconEntryStatus.verified.code,
          'source': 'supabase_initial',
          'provider': 'curated',
          'created_at': DateTime.now().toIso8601String(),
        };
      }
    }
  }

  @override
  bool get isAvailable => available;

  @override
  Future<TranslationResult?> lookup({
    required String normalizedWord,
    required TranslationTargetLanguage targetLanguage,
    required TranslationQuery query,
  }) async {
    lookupCount++;
    if (!isAvailable || shouldFailLookup) return null;

    final key = '${normalizedWord.toLowerCase().trim()}_${targetLanguage.code}';
    final data = _entries[key];
    if (data == null) return null;

    return TranslationResult.success(
      query: query,
      source: TranslationSource.supabaseCentralLexicon,
      primaryTranslation: data['translation'] as String,
      partOfSpeech: data['partOfSpeech'] as String?,
      gender: data['gender'] as String?,
    );
  }

  @override
  Future<bool> saveTranslation({
    required TranslationResult result,
    required String providerName,
  }) async {
    saveCount++;
    if (!isAvailable || shouldFailSave) return false;
    if (!result.isSuccess || result.primaryTranslation == null) return false;

    final word = result.query.normalizedWord.toLowerCase().trim();
    final lang = result.query.targetLanguage.code;
    final key = '${word}_$lang';

    // Canonical upsert: deduplicate by (normalized_word + target_language)
    _entries[key] = {
      'german_word': result.query.rawWord,
      'normalized_word': word,
      'source_language': 'de',
      'target_language': lang,
      'translation': result.primaryTranslation!,
      'status': LexiconEntryStatus.machineGenerated.code, // Strictly MACHINE_GENERATED per requirement 7
      'source': 'online_translation',
      'provider': providerName,
      'created_at': _entries[key]?['created_at'] ?? DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    return true;
  }

  @override
  Future<void> logRequest({
    required TranslationQuery query,
    required String providerName,
    required String status,
    String? result,
  }) async {
    requestsLog.add({
      'normalized_word': query.normalizedWord,
      'source_language': 'de',
      'target_language': query.targetLanguage.code,
      'provider': providerName,
      'status': status,
      'result': result,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  int get entryCount => _entries.length;

  bool containsWord(String normalizedWord, TranslationTargetLanguage lang) {
    return _entries.containsKey('${normalizedWord.toLowerCase().trim()}_${lang.code}');
  }

  Map<String, dynamic>? getEntry(String normalizedWord, TranslationTargetLanguage lang) {
    return _entries['${normalizedWord.toLowerCase().trim()}_${lang.code}'];
  }
}
