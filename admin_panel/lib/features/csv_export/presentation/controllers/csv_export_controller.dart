import 'package:flutter/foundation.dart';
import 'package:german_lexicon_admin/features/lexicon/domain/models/lexicon_filter.dart';
import 'package:german_lexicon_admin/features/csv_export/data/csv_export_repository.dart';
import 'package:german_lexicon_admin/features/csv_export/domain/models/csv_export_entry.dart';
import 'package:german_lexicon_admin/features/csv_export/domain/services/csv_serializer.dart';

enum CsvExportState { idle, fetching, serializing, success, error }

class CsvExportController extends ChangeNotifier {
  final CsvExportRepository repository;

  CsvExportState _state = CsvExportState.idle;
  CsvExportState get state => _state;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  LexiconFilter _filter = const LexiconFilter();
  LexiconFilter get filter => _filter;

  List<CsvExportEntry> _entries = [];
  List<CsvExportEntry> get entries => _entries;

  String _csvContent = '';
  String get csvContent => _csvContent;

  int _totalCount = 0;
  int get totalCount => _totalCount;

  int _fetchedCount = 0;
  int get fetchedCount => _fetchedCount;

  CsvExportController({required this.repository});

  void updateFilter(LexiconFilter newFilter) {
    _filter = newFilter;
    refreshCount();
  }

  void resetFilter() {
    _filter = const LexiconFilter();
    refreshCount();
  }

  Future<void> refreshCount() async {
    try {
      _totalCount = await repository.countMatchingEntries(_filter);
      notifyListeners();
    } catch (e) {
      // Keep existing total or reset to 0
      _totalCount = 0;
      notifyListeners();
    }
  }

  Future<void> runExport({int? maxRows}) async {
    _state = CsvExportState.fetching;
    _errorMessage = null;
    _fetchedCount = 0;
    _entries = [];
    _csvContent = '';
    notifyListeners();

    try {
      _entries = await repository.fetchExportEntries(
        filter: _filter,
        maxRows: maxRows,
        onProgress: (fetched, total) {
          _fetchedCount = fetched;
          _totalCount = total;
          notifyListeners();
        },
      );

      _state = CsvExportState.serializing;
      notifyListeners();

      _csvContent = CsvSerializer.serialize(_entries);

      _state = CsvExportState.success;
      notifyListeners();
    } catch (e) {
      _state = CsvExportState.error;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  void clearExport() {
    _state = CsvExportState.idle;
    _errorMessage = null;
    _entries = [];
    _csvContent = '';
    _fetchedCount = 0;
    notifyListeners();
  }
}
