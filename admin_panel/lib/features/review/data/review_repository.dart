import 'package:supabase_flutter/supabase_flutter.dart';
import '../../lexicon/data/lexicon_repository.dart';
import '../../lexicon/domain/models/lexicon_example.dart';
import '../../lexicon/domain/models/lexicon_sense.dart';
import '../../lexicon/domain/models/lexicon_synonym.dart';
import '../../lexicon/domain/models/lexicon_translation.dart';
import '../../lexicon/domain/models/master_lexicon_entry.dart';
import '../domain/models/review_queue_counts.dart';
import '../domain/models/review_queue_item.dart';

abstract class ReviewRepository {
  Future<ReviewQueueCounts> getCounts();

  Future<({List<ReviewQueueItem> items, int totalCount})> getQueueItems({
    required ReviewCategory category,
    String? searchQuery,
    String? cefrLevel,
    String? partOfSpeech,
    int page = 1,
    int pageSize = 15,
  });

  Future<void> verifyItem(ReviewQueueItem item);
  Future<void> rejectItem(ReviewQueueItem item);
}

class SupabaseReviewRepository implements ReviewRepository {
  final SupabaseClient _client;

  SupabaseReviewRepository({required this._client});

  void _handlePostgrestError(PostgrestException e) {
    final code = e.code;
    final msg = e.message.toLowerCase();

    if (code == '42501' || msg.contains('row-level security') || msg.contains('violates')) {
      throw const RlsPermissionException(
        'Permission denied by Row-Level Security. Your current role does not have authorization for this review action.',
      );
    }
    throw e;
  }

  @override
  Future<ReviewQueueCounts> getCounts() async {
    try {
      // 1. Master Entries pending review
      final masterRes = await _client
          .from('master_lexicon_entries')
          .select('id')
          .eq('status', 'review')
          .count(CountOption.exact);

      // 2. Translations pending review
      final transRes = await _client
          .from('lexicon_translations')
          .select('id')
          .eq('status', 'review')
          .count(CountOption.exact);

      // 3. Senses pending review (senses of master entries in review status)
      final sensesRes = await _client
          .from('lexicon_senses')
          .select('id, master_lexicon_entries!inner(status)')
          .eq('master_lexicon_entries.status', 'review')
          .count(CountOption.exact);

      // 4. Synonyms pending review
      final synRes = await _client
          .from('lexicon_synonyms')
          .select('id')
          .eq('status', 'review')
          .count(CountOption.exact);

      // 5. Examples pending review
      final exRes = await _client
          .from('lexicon_examples')
          .select('id')
          .eq('status', 'review')
          .count(CountOption.exact);

      return ReviewQueueCounts(
        masterCount: masterRes.count,
        translationsCount: transRes.count,
        sensesCount: sensesRes.count,
        synonymsCount: synRes.count,
        examplesCount: exRes.count,
      );
    } on PostgrestException catch (e) {
      _handlePostgrestError(e);
      rethrow;
    }
  }

  @override
  Future<({List<ReviewQueueItem> items, int totalCount})> getQueueItems({
    required ReviewCategory category,
    String? searchQuery,
    String? cefrLevel,
    String? partOfSpeech,
    int page = 1,
    int pageSize = 15,
  }) async {
    try {
      final fromIndex = (page - 1) * pageSize;
      final toIndex = fromIndex + pageSize - 1;

      switch (category) {
        case ReviewCategory.masterWords:
          var query = _client.from('master_lexicon_entries').select();
          query = query.eq('status', 'review');

          if (searchQuery != null && searchQuery.trim().isNotEmpty) {
            query = query.ilike('lemma', '%${searchQuery.trim()}%');
          }
          if (cefrLevel != null && cefrLevel != 'all') {
            query = query.eq('cefr_level', cefrLevel);
          }
          if (partOfSpeech != null && partOfSpeech != 'all') {
            query = query.eq('part_of_speech', partOfSpeech);
          }

          final PostgrestResponse res = await query
              .order('updated_at', ascending: false)
              .range(fromIndex, toIndex)
              .count(CountOption.exact);

          final list = (res.data as List)
              .map((json) => ReviewQueueItem.fromMasterEntry(
                    MasterLexiconEntry.fromJson(json as Map<String, dynamic>),
                  ))
              .toList();

          return (items: list, totalCount: res.count);

        case ReviewCategory.translations:
          var query = _client.from('lexicon_translations').select(
                '*, master_lexicon_entries!inner(lemma, part_of_speech, cefr_level)',
              );
          query = query.eq('status', 'review');

          if (searchQuery != null && searchQuery.trim().isNotEmpty) {
            query = query.ilike(
                'master_lexicon_entries.lemma', '%${searchQuery.trim()}%');
          }
          if (cefrLevel != null && cefrLevel != 'all') {
            query = query.eq('master_lexicon_entries.cefr_level', cefrLevel);
          }
          if (partOfSpeech != null && partOfSpeech != 'all') {
            query = query.eq(
                'master_lexicon_entries.part_of_speech', partOfSpeech);
          }

          final PostgrestResponse res = await query
              .order('updated_at', ascending: false)
              .range(fromIndex, toIndex)
              .count(CountOption.exact);

          final list = (res.data as List).map((json) {
            final map = json as Map<String, dynamic>;
            final parent = map['master_lexicon_entries'] as Map<String, dynamic>?;
            return ReviewQueueItem.fromTranslation(
              translation: LexiconTranslation.fromJson(map),
              parentLemma: parent?['lemma'] as String? ?? '—',
              partOfSpeech: parent?['part_of_speech'] as String?,
              cefrLevel: parent?['cefr_level'] as String?,
            );
          }).toList();

          return (items: list, totalCount: res.count);

        case ReviewCategory.senses:
          var query = _client.from('lexicon_senses').select(
                '*, master_lexicon_entries!inner(lemma, part_of_speech, cefr_level, status)',
              );
          query = query.eq('master_lexicon_entries.status', 'review');

          if (searchQuery != null && searchQuery.trim().isNotEmpty) {
            query = query.ilike(
                'master_lexicon_entries.lemma', '%${searchQuery.trim()}%');
          }
          if (cefrLevel != null && cefrLevel != 'all') {
            query = query.eq('master_lexicon_entries.cefr_level', cefrLevel);
          }
          if (partOfSpeech != null && partOfSpeech != 'all') {
            query = query.eq(
                'master_lexicon_entries.part_of_speech', partOfSpeech);
          }

          final PostgrestResponse res = await query
              .order('updated_at', ascending: false)
              .range(fromIndex, toIndex)
              .count(CountOption.exact);

          final list = (res.data as List).map((json) {
            final map = json as Map<String, dynamic>;
            final parent = map['master_lexicon_entries'] as Map<String, dynamic>?;
            return ReviewQueueItem.fromSense(
              sense: LexiconSense.fromJson(map),
              parentLemma: parent?['lemma'] as String? ?? '—',
              partOfSpeech: parent?['part_of_speech'] as String?,
              cefrLevel: parent?['cefr_level'] as String?,
              parentStatus: parent?['status'] as String? ?? 'review',
            );
          }).toList();

          return (items: list, totalCount: res.count);

        case ReviewCategory.synonyms:
          var query = _client.from('lexicon_synonyms').select(
                '*, master_lexicon_entries!inner(lemma, part_of_speech, cefr_level)',
              );
          query = query.eq('status', 'review');

          if (searchQuery != null && searchQuery.trim().isNotEmpty) {
            query = query.ilike(
                'master_lexicon_entries.lemma', '%${searchQuery.trim()}%');
          }
          if (cefrLevel != null && cefrLevel != 'all') {
            query = query.eq('master_lexicon_entries.cefr_level', cefrLevel);
          }
          if (partOfSpeech != null && partOfSpeech != 'all') {
            query = query.eq(
                'master_lexicon_entries.part_of_speech', partOfSpeech);
          }

          final PostgrestResponse res = await query
              .order('updated_at', ascending: false)
              .range(fromIndex, toIndex)
              .count(CountOption.exact);

          final list = (res.data as List).map((json) {
            final map = json as Map<String, dynamic>;
            final parent = map['master_lexicon_entries'] as Map<String, dynamic>?;
            return ReviewQueueItem.fromSynonym(
              synonym: LexiconSynonym.fromJson(map),
              parentLemma: parent?['lemma'] as String? ?? '—',
              partOfSpeech: parent?['part_of_speech'] as String?,
              cefrLevel: parent?['cefr_level'] as String?,
            );
          }).toList();

          return (items: list, totalCount: res.count);

        case ReviewCategory.examples:
          var query = _client.from('lexicon_examples').select(
                '*, master_lexicon_entries!inner(lemma, part_of_speech)',
              );
          query = query.eq('status', 'review');

          if (searchQuery != null && searchQuery.trim().isNotEmpty) {
            query = query.ilike(
                'master_lexicon_entries.lemma', '%${searchQuery.trim()}%');
          }
          if (cefrLevel != null && cefrLevel != 'all') {
            query = query.eq('cefr_level', cefrLevel);
          }
          if (partOfSpeech != null && partOfSpeech != 'all') {
            query = query.eq(
                'master_lexicon_entries.part_of_speech', partOfSpeech);
          }

          final PostgrestResponse res = await query
              .order('updated_at', ascending: false)
              .range(fromIndex, toIndex)
              .count(CountOption.exact);

          final list = (res.data as List).map((json) {
            final map = json as Map<String, dynamic>;
            final parent = map['master_lexicon_entries'] as Map<String, dynamic>?;
            return ReviewQueueItem.fromExample(
              example: LexiconExample.fromJson(map),
              parentLemma: parent?['lemma'] as String? ?? '—',
              partOfSpeech: parent?['part_of_speech'] as String?,
            );
          }).toList();

          return (items: list, totalCount: res.count);
      }
    } on PostgrestException catch (e) {
      _handlePostgrestError(e);
      rethrow;
    }
  }

  @override
  Future<void> verifyItem(ReviewQueueItem item) async {
    try {
      switch (item.category) {
        case ReviewCategory.masterWords:
        case ReviewCategory.senses:
          // For senses, verifying the sense promotes parent word to verified
          await _client
              .from('master_lexicon_entries')
              .update({'status': 'verified'})
              .eq('id', item.entryId);
          break;
        case ReviewCategory.translations:
          await _client
              .from('lexicon_translations')
              .update({'status': 'verified'})
              .eq('id', item.id);
          break;
        case ReviewCategory.synonyms:
          await _client
              .from('lexicon_synonyms')
              .update({'status': 'verified'})
              .eq('id', item.id);
          break;
        case ReviewCategory.examples:
          await _client
              .from('lexicon_examples')
              .update({'status': 'verified'})
              .eq('id', item.id);
          break;
      }
    } on PostgrestException catch (e) {
      _handlePostgrestError(e);
      rethrow;
    }
  }

  @override
  Future<void> rejectItem(ReviewQueueItem item) async {
    try {
      switch (item.category) {
        case ReviewCategory.masterWords:
        case ReviewCategory.senses:
          await _client
              .from('master_lexicon_entries')
              .update({'status': 'rejected'})
              .eq('id', item.entryId);
          break;
        case ReviewCategory.translations:
          await _client
              .from('lexicon_translations')
              .update({'status': 'rejected'})
              .eq('id', item.id);
          break;
        case ReviewCategory.synonyms:
          await _client
              .from('lexicon_synonyms')
              .update({'status': 'rejected'})
              .eq('id', item.id);
          break;
        case ReviewCategory.examples:
          await _client
              .from('lexicon_examples')
              .update({'status': 'rejected'})
              .eq('id', item.id);
          break;
      }
    } on PostgrestException catch (e) {
      _handlePostgrestError(e);
      rethrow;
    }
  }
}
