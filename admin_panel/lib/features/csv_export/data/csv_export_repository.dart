import 'package:supabase_flutter/supabase_flutter.dart';
import '../../lexicon/data/lexicon_repository.dart';
import '../../lexicon/domain/models/lexicon_filter.dart';
import '../domain/models/csv_export_entry.dart';

abstract class CsvExportRepository {
  /// Fetches export entries matching the filter.
  /// If [filter] is null, fetches all entries up to [maxRows].
  Future<List<CsvExportEntry>> fetchExportEntries({
    LexiconFilter? filter,
    int? maxRows,
    void Function(int fetched, int total)? onProgress,
  });

  /// Counts total entries matching the filter without fetching child relations.
  Future<int> countMatchingEntries(LexiconFilter? filter);
}

class SupabaseCsvExportRepository implements CsvExportRepository {
  final SupabaseClient _client;
  static const int defaultChunkSize = 200;

  SupabaseCsvExportRepository(this._client);

  void _handlePostgrestError(PostgrestException e) {
    final code = e.code;
    final msg = e.message.toLowerCase();
    if (code == '42501' || msg.contains('row-level security') || msg.contains('violates')) {
      throw RlsPermissionException(
        'Permission denied by Row-Level Security for CSV Export.',
      );
    }
    throw e;
  }

  @override
  Future<int> countMatchingEntries(LexiconFilter? filter) async {
    try {
      var query = _client.from('master_lexicon_entries').select('id');

      if (filter != null) {
        if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
          query = query.ilike('lemma', '%${filter.searchQuery!.trim()}%');
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
      }

      final res = await query.count(CountOption.exact);
      return res.count;
    } on PostgrestException catch (e) {
      _handlePostgrestError(e);
      rethrow;
    }
  }

  @override
  Future<List<CsvExportEntry>> fetchExportEntries({
    LexiconFilter? filter,
    int? maxRows,
    void Function(int fetched, int total)? onProgress,
  }) async {
    try {
      final totalCount = await countMatchingEntries(filter);
      if (totalCount == 0) {
        onProgress?.call(0, 0);
        return [];
      }

      final limit = maxRows != null && maxRows < totalCount ? maxRows : totalCount;
      final results = <CsvExportEntry>[];

      int offset = 0;
      while (offset < limit) {
        final currentChunk = (limit - offset > defaultChunkSize)
            ? defaultChunkSize
            : (limit - offset);

        var query = _client.from('master_lexicon_entries').select('''
          *,
          lexicon_translations(*),
          lexicon_senses(*),
          lexicon_synonyms(*),
          lexicon_examples(*)
        ''');

        if (filter != null) {
          if (filter.searchQuery != null && filter.searchQuery!.trim().isNotEmpty) {
            query = query.ilike('lemma', '%${filter.searchQuery!.trim()}%');
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
        }

        final chunkData = await query
            .order('lemma', ascending: true)
            .range(offset, offset + currentChunk - 1);

        final list = (chunkData as List)
            .map((json) => CsvExportEntry.fromJson(json as Map<String, dynamic>))
            .toList();

        results.addAll(list);
        offset += list.length;
        onProgress?.call(results.length, limit);

        if (list.length < currentChunk) {
          break; // No more rows
        }
      }

      return results;
    } on PostgrestException catch (e) {
      _handlePostgrestError(e);
      rethrow;
    }
  }
}
