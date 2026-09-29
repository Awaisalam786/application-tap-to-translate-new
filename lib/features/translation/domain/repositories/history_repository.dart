// lib/features/translation/domain/repositories/history_repository.dart

import '../models/history_entry.dart';

/// Contract for managing the automatic lookup history.
/// Strictly separated from explicitly saved "My Words".
abstract class HistoryRepository {
  /// Returns recent lookup history entries, newest first.
  Future<List<HistoryEntry>> getRecentHistory({int limit = 100});

  /// Automatically records a lookup attempt or success.
  Future<void> recordLookup(HistoryEntry entry);

  /// Clears the lookup history.
  Future<void> clearHistory();
}
