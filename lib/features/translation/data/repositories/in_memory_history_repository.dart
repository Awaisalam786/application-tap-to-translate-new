// lib/features/translation/data/repositories/in_memory_history_repository.dart

import '../../domain/models/history_entry.dart';
import '../../domain/repositories/history_repository.dart';

/// In-memory implementation of [HistoryRepository] for automatic lookup audit history.
class InMemoryHistoryRepository implements HistoryRepository {
  final List<HistoryEntry> _history = [];

  @override
  Future<List<HistoryEntry>> getRecentHistory({int limit = 100}) async {
    return _history.take(limit).toList();
  }

  @override
  Future<void> recordLookup(HistoryEntry entry) async {
    _history.insert(0, entry);
  }

  @override
  Future<void> clearHistory() async {
    _history.clear();
  }

  int get count => _history.length;
}
