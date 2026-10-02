import 'package:german_lexicon_admin/features/csv_import/domain/models/csv_import_row.dart';
import 'package:german_lexicon_admin/features/lexicon/data/lexicon_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CsvImportExecutionResult {
  final int totalProcessed;
  final int successCount;
  final int skippedCount;
  final int errorCount;
  final List<String> errors;

  const CsvImportExecutionResult({
    required this.totalProcessed,
    required this.successCount,
    required this.skippedCount,
    required this.errorCount,
    this.errors = const [],
  });
}

abstract class CsvImportRepository {
  /// Checks database for existing entries and updates duplicate status
  Future<List<CsvImportRow>> checkDatabaseDuplicates(List<CsvImportRow> rows);

  /// Executes batch import for approved rows with the given target status ('draft' or 'review')
  Future<CsvImportExecutionResult> executeImport(
    List<CsvImportRow> rows, {
    required String targetStatus,
    String? createdBy,
  });
}

class SupabaseCsvImportRepository implements CsvImportRepository {
  final SupabaseClient _client;

  SupabaseCsvImportRepository(this._client);

  @override
  Future<List<CsvImportRow>> checkDatabaseDuplicates(List<CsvImportRow> rows) async {
    final updatedRows = <CsvImportRow>[];

    // Collect normalized lemmas to query
    final candidates = rows
        .where((r) => r.isValid && r.duplicateStatus != DuplicateStatus.duplicateInFile)
        .map((r) => r.normalizedLemma)
        .toSet()
        .toList();

    final existingMap = <String, Map<String, dynamic>>{}; // "$normLemma|$pos" -> record

    if (candidates.isNotEmpty) {
      try {
        // Query in chunks of 50 to avoid URL length limits
        const chunkSize = 50;
        for (int i = 0; i < candidates.length; i += chunkSize) {
          final chunk = candidates.sublist(
            i,
            (i + chunkSize > candidates.length) ? candidates.length : i + chunkSize,
          );

          final res = await _client
              .from('master_lexicon_entries')
              .select('id, normalized_lemma, part_of_speech, status')
              .inFilter('normalized_lemma', chunk);

          for (final item in res as List) {
            final map = item as Map<String, dynamic>;
            final key = '${map['normalized_lemma']}|${map['part_of_speech']}';
            existingMap[key] = map;
          }
        }
      } on PostgrestException catch (e) {
        if (e.code == '42501' || e.message.toLowerCase().contains('row-level security')) {
          throw const RlsPermissionException(
            'Permission denied by Row-Level Security while checking duplicates.',
          );
        }
        rethrow;
      }
    }

    for (final row in rows) {
      if (!row.isValid || row.duplicateStatus == DuplicateStatus.duplicateInFile) {
        updatedRows.add(row);
        continue;
      }

      final key = '${row.normalizedLemma}|${row.partOfSpeech}';
      final existing = existingMap[key];

      if (existing != null) {
        final existingStatus = existing['status'] as String? ?? 'draft';
        final existingId = existing['id'] as String;

        if (existingStatus == 'verified') {
          // STRICT RULE: Never overwrite verified records
          updatedRows.add(row.copyWith(
            duplicateStatus: DuplicateStatus.existingVerified,
            duplicateDetail: 'Word is already VERIFIED in dictionary. Overwriting is prohibited.',
            existingEntryId: existingId,
            shouldImport: false,
          ));
        } else {
          updatedRows.add(row.copyWith(
            duplicateStatus: DuplicateStatus.existingDraftReview,
            duplicateDetail: 'Word already exists in "$existingStatus" status.',
            existingEntryId: existingId,
            shouldImport: false, // Default to unchecked; user can opt-in
          ));
        }
      } else {
        updatedRows.add(row.copyWith(
          duplicateStatus: DuplicateStatus.none,
          duplicateDetail: null,
          existingEntryId: null,
          shouldImport: true,
        ));
      }
    }

    return updatedRows;
  }

  @override
  Future<CsvImportExecutionResult> executeImport(
    List<CsvImportRow> rows, {
    required String targetStatus,
    String? createdBy,
  }) async {
    // STRICT SECURITY INVARIANT: Never import directly as verified
    if (targetStatus == 'verified') {
      throw ArgumentError(
        'Security policy violation: Vocabulary cannot be imported directly as "verified". All imported entries must be set to "draft" or "review".',
      );
    }

    if (targetStatus != 'draft' && targetStatus != 'review') {
      throw ArgumentError('Invalid target status "$targetStatus". Allowed: draft, review.');
    }

    int successCount = 0;
    int skippedCount = 0;
    int errorCount = 0;
    final errors = <String>[];

    for (final row in rows) {
      // Skip invalid or unselected rows or verified conflicts
      if (!row.canBeImported) {
        skippedCount++;
        continue;
      }

      try {
        String entryId;

        if (row.existingEntryId == null) {
          // Insert new master lexicon entry
          final insertPayload = <String, dynamic>{
            'lemma': row.lemma,
            'normalized_lemma': row.normalizedLemma,
            'part_of_speech': row.partOfSpeech,
            'gender': row.gender,
            'plural_form': row.pluralForm,
            'cefr_level': row.cefrLevel,
            'status': targetStatus,
            'source_type': 'candidate_import',
            'provenance': row.provenance ?? 'CSV Import',
          };
          if (createdBy != null) {
            insertPayload['created_by'] = createdBy;
          }

          final entryRes = await _client
              .from('master_lexicon_entries')
              .insert(insertPayload)
              .select('id')
              .single();

          entryId = entryRes['id'] as String;
        } else {
          // Attached to existing draft/review entry
          entryId = row.existingEntryId!;
        }

        // Insert translations
        for (final entry in row.translations.entries) {
          try {
            await _client.from('lexicon_translations').insert({
              'entry_id': entryId,
              'target_lang': entry.key,
              'translation': entry.value,
              'status': targetStatus,
              'source_type': 'candidate_import',
            });
          } catch (_) {
            // Ignore duplicate translation if already exists
          }
        }

        // Insert sense if provided or if topic provided
        if ((row.senseDe != null && row.senseDe!.isNotEmpty) ||
            (row.topic != null && row.topic!.isNotEmpty)) {
          try {
            await _client.from('lexicon_senses').insert({
              'entry_id': entryId,
              'sense_order': 1,
              'definition_de': row.senseDe ?? (row.topic != null ? '[Topic: ${row.topic}]' : ''),
              'definition_en': row.senseEn,
              'context_domain': row.topic,
            });
          } catch (_) {
            // Non-fatal if sense order exists
          }
        }

        // Insert synonyms if provided
        for (final syn in row.synonyms) {
          try {
            await _client.from('lexicon_synonyms').insert({
              'entry_id': entryId,
              'synonym_word': syn,
              'status': targetStatus,
              'source_type': 'candidate_import',
            });
          } catch (_) {
            // Non-fatal duplicate synonym
          }
        }

        // Insert example if provided
        if (row.exampleDe != null && row.exampleDe!.isNotEmpty) {
          try {
            await _client.from('lexicon_examples').insert({
              'entry_id': entryId,
              'sentence_de': row.exampleDe!,
              'sentence_en': row.exampleEn,
              'sentence_ur': row.exampleUr,
              'cefr_level': row.cefrLevel != 'unclassified' ? row.cefrLevel : null,
              'status': targetStatus,
              'source_type': 'candidate_import',
            });
          } catch (_) {
            // Non-fatal duplicate example
          }
        }

        successCount++;
      } on PostgrestException catch (e) {
        errorCount++;
        if (e.code == '42501' || e.message.toLowerCase().contains('row-level security')) {
          errors.add('Row #${row.rowIndex} (${row.lemma}): RLS Permission Denied.');
        } else {
          errors.add('Row #${row.rowIndex} (${row.lemma}): ${e.message}');
        }
      } catch (e) {
        errorCount++;
        errors.add('Row #${row.rowIndex} (${row.lemma}): $e');
      }
    }

    return CsvImportExecutionResult(
      totalProcessed: rows.length,
      successCount: successCount,
      skippedCount: skippedCount,
      errorCount: errorCount,
      errors: errors,
    );
  }
}
