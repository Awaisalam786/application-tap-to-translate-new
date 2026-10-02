import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/models/bulk_action_result.dart';
import '../domain/models/lexicon_example.dart';
import '../domain/models/lexicon_filter.dart';
import '../domain/models/lexicon_sense.dart';
import '../domain/models/lexicon_synonym.dart';
import '../domain/models/lexicon_translation.dart';
import '../domain/models/master_lexicon_entry.dart';

class DuplicateLexiconEntryException implements Exception {
  final String message;
  const DuplicateLexiconEntryException(this.message);
  @override
  String toString() => message;
}

class RlsPermissionException implements Exception {
  final String message;
  const RlsPermissionException(this.message);
  @override
  String toString() => message;
}

abstract class LexiconRepository {
  Future<({List<MasterLexiconEntry> entries, int totalCount})> getEntries(
    LexiconFilter filter,
  );
  Future<MasterLexiconEntry> getEntryById(String id);
  Future<MasterLexiconEntry> createEntry(MasterLexiconEntry entry);
  Future<MasterLexiconEntry> updateEntry(MasterLexiconEntry entry);
  Future<void> deleteEntry(String id);

  // Bulk Operations
  Future<BulkActionResult> bulkUpdateStatus({
    required List<String> entryIds,
    required String status,
  });
  Future<BulkActionResult> bulkUpdateCefr({
    required List<String> entryIds,
    required String cefrLevel,
  });

  // Translations
  Future<List<LexiconTranslation>> getTranslations(String entryId);
  Future<LexiconTranslation> createTranslation(LexiconTranslation translation);
  Future<LexiconTranslation> updateTranslation(LexiconTranslation translation);
  Future<void> deleteTranslation(String id);

  // Senses
  Future<List<LexiconSense>> getSenses(String entryId);
  Future<LexiconSense> createSense(LexiconSense sense);
  Future<LexiconSense> updateSense(LexiconSense sense);
  Future<void> deleteSense(String id);

  // Synonyms
  Future<List<LexiconSynonym>> getSynonyms(String entryId);
  Future<LexiconSynonym> createSynonym(LexiconSynonym synonym);
  Future<LexiconSynonym> updateSynonym(LexiconSynonym synonym);
  Future<void> deleteSynonym(String id);

  // Examples
  Future<List<LexiconExample>> getExamples(String entryId);
  Future<LexiconExample> createExample(LexiconExample example);
  Future<LexiconExample> updateExample(LexiconExample example);
  Future<void> deleteExample(String id);
}

class SupabaseLexiconRepository implements LexiconRepository {
  final SupabaseClient _client;

  SupabaseLexiconRepository(this._client);

  void _handlePostgrestError(PostgrestException e) {
    final code = e.code;
    final msg = e.message.toLowerCase();

    if (code == '23505' || msg.contains('unique') || msg.contains('duplicate')) {
      throw DuplicateLexiconEntryException(
        'A record with these unique details already exists in the dictionary.',
      );
    }
    if (code == '42501' || msg.contains('row-level security') || msg.contains('violates')) {
      throw RlsPermissionException(
        'Permission denied by Row-Level Security. Your current role does not have authorization for this action.',
      );
    }
    throw e;
  }

  @override
  Future<({List<MasterLexiconEntry> entries, int totalCount})> getEntries(
    LexiconFilter filter,
  ) async {
    try {
      var query = _client.from('master_lexicon_entries').select(
        '*, lexicon_translations(*), lexicon_senses(*), lexicon_examples(*), lexicon_synonyms(*)',
      );

      if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
        final queryStr = filter.searchQuery!.trim();
        query = query.ilike('lemma', '%$queryStr%');
      }

      if (filter.cefrLevel != null && filter.cefrLevel != 'all') {
        query = query.eq('cefr_level', filter.cefrLevel!);
      }

      if (filter.partOfSpeech != null && filter.partOfSpeech != 'all') {
        query = query.eq('part_of_speech', filter.partOfSpeech!);
      }

      if (filter.status != null && filter.status != 'all') {
        query = query.eq('status', filter.status!);
      }

      if (filter.gender != null && filter.gender != 'all') {
        query = query.eq('gender', filter.gender!);
      }

      final fromIndex = (filter.page - 1) * filter.pageSize;
      final toIndex = fromIndex + filter.pageSize - 1;

      final PostgrestResponse response = await query
          .order('lemma', ascending: true)
          .range(fromIndex, toIndex)
          .count(CountOption.exact);

      var list = (response.data as List)
          .map((item) => MasterLexiconEntry.fromJson(item as Map<String, dynamic>))
          .toList();

      // In-memory evaluation for advanced translation and richness flags
      if (filter.hasAdvancedFilters) {
        list = list.where((entry) {
          final trans = entry.translations ?? [];

          if (filter.hasEnTranslation != null) {
            final has = trans.any((t) => t.targetLang == 'en' && t.translation.trim().isNotEmpty);
            if (has != filter.hasEnTranslation) return false;
          }
          if (filter.hasUrTranslation != null) {
            final has = trans.any((t) => t.targetLang == 'ur' && t.translation.trim().isNotEmpty);
            if (has != filter.hasUrTranslation) return false;
          }
          if (filter.hasFaTranslation != null) {
            final has = trans.any((t) => t.targetLang == 'fa' && t.translation.trim().isNotEmpty);
            if (has != filter.hasFaTranslation) return false;
          }
          if (filter.hasArTranslation != null) {
            final has = trans.any((t) => t.targetLang == 'ar' && t.translation.trim().isNotEmpty);
            if (has != filter.hasArTranslation) return false;
          }
          if (filter.hasExample != null) {
            final has = (entry.examples ?? []).isNotEmpty;
            if (has != filter.hasExample) return false;
          }
          if (filter.hasSense != null) {
            final has = (entry.senses ?? []).isNotEmpty;
            if (has != filter.hasSense) return false;
          }
          if (filter.hasSynonym != null) {
            final has = (entry.synonyms ?? []).isNotEmpty;
            if (has != filter.hasSynonym) return false;
          }
          return true;
        }).toList();
      }

      final int total = filter.hasAdvancedFilters ? list.length : response.count;
      return (entries: list, totalCount: total);
    } on PostgrestException catch (e) {
      _handlePostgrestError(e);
      rethrow;
    }
  }

  @override
  Future<BulkActionResult> bulkUpdateStatus({
    required List<String> entryIds,
    required String status,
  }) async {
    final succeeded = <String>[];
    final errors = <String, String>{};

    for (final id in entryIds) {
      try {
        await _client
            .from('master_lexicon_entries')
            .update({
              'status': status,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', id);
        succeeded.add(id);
      } on PostgrestException catch (e) {
        if (e.code == '42501' || e.message.toLowerCase().contains('row-level security')) {
          errors[id] = 'RLS Permission Denied';
        } else {
          errors[id] = e.message;
        }
      } catch (e) {
        errors[id] = e.toString();
      }
    }

    return BulkActionResult(
      totalRequested: entryIds.length,
      succeededIds: succeeded,
      failureErrors: errors,
    );
  }

  @override
  Future<BulkActionResult> bulkUpdateCefr({
    required List<String> entryIds,
    required String cefrLevel,
  }) async {
    final succeeded = <String>[];
    final errors = <String, String>{};

    for (final id in entryIds) {
      try {
        await _client
            .from('master_lexicon_entries')
            .update({
              'cefr_level': cefrLevel,
              'updated_at': DateTime.now().toUtc().toIso8601String(),
            })
            .eq('id', id);
        succeeded.add(id);
      } on PostgrestException catch (e) {
        if (e.code == '42501' || e.message.toLowerCase().contains('row-level security')) {
          errors[id] = 'RLS Permission Denied';
        } else {
          errors[id] = e.message;
        }
      } catch (e) {
        errors[id] = e.toString();
      }
    }

    return BulkActionResult(
      totalRequested: entryIds.length,
      succeededIds: succeeded,
      failureErrors: errors,
    );
  }

  @override
  Future<MasterLexiconEntry> getEntryById(String id) async {
    try {
      final res = await _client
          .from('master_lexicon_entries')
          .select()
          .eq('id', id)
          .single();
      return MasterLexiconEntry.fromJson(res);
    } on PostgrestException catch (e) {
      _handlePostgrestError(e);
      rethrow;
    }
  }

  @override
  Future<MasterLexiconEntry> createEntry(MasterLexiconEntry entry) async {
    try {
      final payload = Map<String, dynamic>.from(entry.toJson())..remove('id');
      final res = await _client
          .from('master_lexicon_entries')
          .insert(payload)
          .select()
          .single();
      return MasterLexiconEntry.fromJson(res);
    } on PostgrestException catch (e) {
      _handlePostgrestError(e);
      rethrow;
    }
  }

  @override
  Future<MasterLexiconEntry> updateEntry(MasterLexiconEntry entry) async {
    try {
      final payload = Map<String, dynamic>.from(entry.toJson())..remove('id');
      final res = await _client
          .from('master_lexicon_entries')
          .update(payload)
          .eq('id', entry.id)
          .select()
          .single();
      return MasterLexiconEntry.fromJson(res);
    } on PostgrestException catch (e) {
      _handlePostgrestError(e);
      rethrow;
    }
  }

  @override
  Future<void> deleteEntry(String id) async {
    try {
      await _client.from('master_lexicon_entries').delete().eq('id', id);
    } on PostgrestException catch (e) {
      _handlePostgrestError(e);
      rethrow;
    }
  }

  // --- Translations ---

  @override
  Future<List<LexiconTranslation>> getTranslations(String entryId) async {
    try {
      final res = await _client
          .from('lexicon_translations')
          .select()
          .eq('entry_id', entryId)
          .order('target_lang', ascending: true);
      return (res as List)
          .map((item) => LexiconTranslation.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      _handlePostgrestError(e);
      rethrow;
    }
  }

  @override
  Future<LexiconTranslation> createTranslation(
    LexiconTranslation translation,
  ) async {
    try {
      final payload = Map<String, dynamic>.from(translation.toJson())
        ..remove('id');
      final res = await _client
          .from('lexicon_translations')
          .insert(payload)
          .select()
          .single();
      return LexiconTranslation.fromJson(res);
    } on PostgrestException catch (e) {
      _handlePostgrestError(e);
      rethrow;
    }
  }

  @override
  Future<LexiconTranslation> updateTranslation(
    LexiconTranslation translation,
  ) async {
    try {
      final payload = Map<String, dynamic>.from(translation.toJson())
        ..remove('id');
      final res = await _client
          .from('lexicon_translations')
          .update(payload)
          .eq('id', translation.id)
          .select()
          .single();
      return LexiconTranslation.fromJson(res);
    } on PostgrestException catch (e) {
      _handlePostgrestError(e);
      rethrow;
    }
  }

  @override
  Future<void> deleteTranslation(String id) async {
    try {
      await _client.from('lexicon_translations').delete().eq('id', id);
    } on PostgrestException catch (e) {
      _handlePostgrestError(e);
      rethrow;
    }
  }

  // --- Senses ---

  @override
  Future<List<LexiconSense>> getSenses(String entryId) async {
    try {
      final res = await _client
          .from('lexicon_senses')
          .select()
          .eq('entry_id', entryId)
          .order('sense_order', ascending: true);
      return (res as List)
          .map((item) => LexiconSense.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      _handlePostgrestError(e);
      rethrow;
    }
  }

  @override
  Future<LexiconSense> createSense(LexiconSense sense) async {
    try {
      final payload = Map<String, dynamic>.from(sense.toJson())..remove('id');
      final res = await _client
          .from('lexicon_senses')
          .insert(payload)
          .select()
          .single();
      return LexiconSense.fromJson(res);
    } on PostgrestException catch (e) {
      _handlePostgrestError(e);
      rethrow;
    }
  }

  @override
  Future<LexiconSense> updateSense(LexiconSense sense) async {
    try {
      final payload = Map<String, dynamic>.from(sense.toJson())..remove('id');
      final res = await _client
          .from('lexicon_senses')
          .update(payload)
          .eq('id', sense.id)
          .select()
          .single();
      return LexiconSense.fromJson(res);
    } on PostgrestException catch (e) {
      _handlePostgrestError(e);
      rethrow;
    }
  }

  @override
  Future<void> deleteSense(String id) async {
    try {
      await _client.from('lexicon_senses').delete().eq('id', id);
    } on PostgrestException catch (e) {
      _handlePostgrestError(e);
      rethrow;
    }
  }

  // --- Synonyms ---

  @override
  Future<List<LexiconSynonym>> getSynonyms(String entryId) async {
    try {
      final res = await _client
          .from('lexicon_synonyms')
          .select()
          .eq('entry_id', entryId)
          .order('synonym_word', ascending: true);
      return (res as List)
          .map((item) => LexiconSynonym.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      _handlePostgrestError(e);
      rethrow;
    }
  }

  @override
  Future<LexiconSynonym> createSynonym(LexiconSynonym synonym) async {
    try {
      final payload = Map<String, dynamic>.from(synonym.toJson())
        ..remove('id');
      final res = await _client
          .from('lexicon_synonyms')
          .insert(payload)
          .select()
          .single();
      return LexiconSynonym.fromJson(res);
    } on PostgrestException catch (e) {
      _handlePostgrestError(e);
      rethrow;
    }
  }

  @override
  Future<LexiconSynonym> updateSynonym(LexiconSynonym synonym) async {
    try {
      final payload = Map<String, dynamic>.from(synonym.toJson())
        ..remove('id');
      final res = await _client
          .from('lexicon_synonyms')
          .update(payload)
          .eq('id', synonym.id)
          .select()
          .single();
      return LexiconSynonym.fromJson(res);
    } on PostgrestException catch (e) {
      _handlePostgrestError(e);
      rethrow;
    }
  }

  @override
  Future<void> deleteSynonym(String id) async {
    try {
      await _client.from('lexicon_synonyms').delete().eq('id', id);
    } on PostgrestException catch (e) {
      _handlePostgrestError(e);
      rethrow;
    }
  }

  // --- Examples ---

  @override
  Future<List<LexiconExample>> getExamples(String entryId) async {
    try {
      final res = await _client
          .from('lexicon_examples')
          .select()
          .eq('entry_id', entryId)
          .order('created_at', ascending: true);
      return (res as List)
          .map((item) => LexiconExample.fromJson(item as Map<String, dynamic>))
          .toList();
    } on PostgrestException catch (e) {
      _handlePostgrestError(e);
      rethrow;
    }
  }

  @override
  Future<LexiconExample> createExample(LexiconExample example) async {
    try {
      final payload = Map<String, dynamic>.from(example.toJson())
        ..remove('id');
      final res = await _client
          .from('lexicon_examples')
          .insert(payload)
          .select()
          .single();
      return LexiconExample.fromJson(res);
    } on PostgrestException catch (e) {
      _handlePostgrestError(e);
      rethrow;
    }
  }

  @override
  Future<LexiconExample> updateExample(LexiconExample example) async {
    try {
      final payload = Map<String, dynamic>.from(example.toJson())
        ..remove('id');
      final res = await _client
          .from('lexicon_examples')
          .update(payload)
          .eq('id', example.id)
          .select()
          .single();
      return LexiconExample.fromJson(res);
    } on PostgrestException catch (e) {
      _handlePostgrestError(e);
      rethrow;
    }
  }

  @override
  Future<void> deleteExample(String id) async {
    try {
      await _client.from('lexicon_examples').delete().eq('id', id);
    } on PostgrestException catch (e) {
      _handlePostgrestError(e);
      rethrow;
    }
  }
}
