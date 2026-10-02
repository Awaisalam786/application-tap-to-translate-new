import 'package:flutter/foundation.dart';
import '../../../auth/domain/admin_user_model.dart';
import '../../data/lexicon_repository.dart';
import '../../domain/models/bulk_action_result.dart';
import '../../domain/models/lexicon_filter.dart';
import '../../domain/models/master_lexicon_entry.dart';

class LexiconController extends ChangeNotifier {
  final LexiconRepository _repository;

  LexiconController({required LexiconRepository repository})
      // ignore: prefer_initializing_formals
      : _repository = repository;

  List<MasterLexiconEntry> _entries = [];
  int _totalCount = 0;
  LexiconFilter _filter = const LexiconFilter();
  bool _isLoading = false;
  String? _errorMessage;

  // Bulk Selection State
  final Set<String> _selectedEntryIds = <String>{};
  bool _isBulkActionLoading = false;

  List<MasterLexiconEntry> get entries => _entries;
  int get totalCount => _totalCount;
  LexiconFilter get filter => _filter;
  bool get isLoading => _isLoading;
  bool get isBulkActionLoading => _isBulkActionLoading;
  String? get errorMessage => _errorMessage;

  Set<String> get selectedEntryIds => Set.unmodifiable(_selectedEntryIds);
  int get selectedCount => _selectedEntryIds.length;
  bool get isAllSelected =>
      _entries.isNotEmpty && _entries.every((e) => _selectedEntryIds.contains(e.id));

  List<MasterLexiconEntry> get selectedEntries =>
      _entries.where((e) => _selectedEntryIds.contains(e.id)).toList();

  int get totalPages => (_totalCount / _filter.pageSize).ceil().clamp(1, 999999);
  bool get hasPreviousPage => _filter.page > 1;
  bool get hasNextPage => _filter.page < totalPages;

  void toggleSelection(String id) {
    if (_selectedEntryIds.contains(id)) {
      _selectedEntryIds.remove(id);
    } else {
      _selectedEntryIds.add(id);
    }
    notifyListeners();
  }

  void selectAllVisible() {
    if (isAllSelected) {
      _selectedEntryIds.removeAll(_entries.map((e) => e.id));
    } else {
      _selectedEntryIds.addAll(_entries.map((e) => e.id));
    }
    notifyListeners();
  }

  void clearSelection() {
    _selectedEntryIds.clear();
    notifyListeners();
  }

  Future<void> loadEntries() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.getEntries(_filter);
      _entries = result.entries;
      _totalCount = result.totalCount;
    } catch (e) {
      _errorMessage = e.toString();
      _entries = [];
      _totalCount = 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> setSearchQuery(String? query) async {
    final cleaned = query?.trim();
    if (cleaned == _filter.searchQuery) return;
    _filter = _filter.copyWith(
      searchQuery: (cleaned != null && cleaned.isNotEmpty) ? cleaned : null,
      page: 1,
      clearSearch: (cleaned == null || cleaned.isEmpty),
    );
    await loadEntries();
  }

  Future<void> setCefrFilter(String? cefr) async {
    if (cefr == _filter.cefrLevel) return;
    _filter = _filter.copyWith(cefrLevel: cefr, page: 1);
    await loadEntries();
  }

  Future<void> setPosFilter(String? pos) async {
    if (pos == _filter.partOfSpeech) return;
    _filter = _filter.copyWith(partOfSpeech: pos, page: 1);
    await loadEntries();
  }

  Future<void> setStatusFilter(String? status) async {
    if (status == _filter.status) return;
    _filter = _filter.copyWith(status: status, page: 1);
    await loadEntries();
  }

  Future<void> setGenderFilter(String? gender) async {
    if (gender == _filter.gender) return;
    _filter = _filter.copyWith(gender: gender, page: 1);
    await loadEntries();
  }

  Future<void> setFilterHasTranslation({
    bool? en,
    bool? ur,
    bool? fa,
    bool? ar,
  }) async {
    _filter = _filter.copyWith(
      hasEnTranslation: en,
      hasUrTranslation: ur,
      hasFaTranslation: fa,
      hasArTranslation: ar,
      page: 1,
    );
    await loadEntries();
  }

  Future<void> setFilterCompleteness({
    bool? hasExample,
    bool? hasSense,
    bool? hasSynonym,
  }) async {
    _filter = _filter.copyWith(
      hasExample: hasExample,
      hasSense: hasSense,
      hasSynonym: hasSynonym,
      page: 1,
    );
    await loadEntries();
  }

  Future<void> clearAdvancedFilters() async {
    _filter = _filter.copyWith(clearAdvanced: true, page: 1);
    await loadEntries();
  }

  Future<void> setPage(int page) async {
    if (page == _filter.page || page < 1 || page > totalPages) return;
    _filter = _filter.copyWith(page: page);
    await loadEntries();
  }

  Future<void> setPageSize(int pageSize) async {
    if (pageSize == _filter.pageSize) return;
    _filter = _filter.copyWith(pageSize: pageSize, page: 1);
    await loadEntries();
  }

  /// Bulk approve / verify entries. Blocked for Editor role.
  Future<BulkActionResult> bulkVerify({
    required AdminRole userRole,
    List<String>? targetIds,
  }) async {
    if (userRole == AdminRole.editor) {
      return BulkActionResult(
        totalRequested: targetIds?.length ?? _selectedEntryIds.length,
        succeededIds: const [],
        failureErrors: {
          for (final id in (targetIds ?? _selectedEntryIds))
            id: 'Editor role is not authorized to verify entries.'
        },
      );
    }
    return _performBulkStatusUpdate('verified', targetIds);
  }

  /// Bulk reject entries. Blocked for Editor role.
  Future<BulkActionResult> bulkReject({
    required AdminRole userRole,
    List<String>? targetIds,
  }) async {
    if (userRole == AdminRole.editor) {
      return BulkActionResult(
        totalRequested: targetIds?.length ?? _selectedEntryIds.length,
        succeededIds: const [],
        failureErrors: {
          for (final id in (targetIds ?? _selectedEntryIds))
            id: 'Editor role is not authorized to reject entries.'
        },
      );
    }
    return _performBulkStatusUpdate('rejected', targetIds);
  }

  /// Move selected entries to review queue (permitted for editor, reviewer, superadmin)
  Future<BulkActionResult> bulkMoveToReview({
    List<String>? targetIds,
  }) async {
    return _performBulkStatusUpdate('review', targetIds);
  }

  /// Bulk assign CEFR level
  Future<BulkActionResult> bulkAssignCefr({
    required String cefrLevel,
    List<String>? targetIds,
  }) async {
    final ids = targetIds ?? _selectedEntryIds.toList();
    if (ids.isEmpty) {
      return const BulkActionResult(
        totalRequested: 0,
        succeededIds: [],
        failureErrors: {},
      );
    }

    _isBulkActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _repository.bulkUpdateCefr(
        entryIds: ids,
        cefrLevel: cefrLevel,
      );
      if (res.succeededIds.isNotEmpty) {
        _selectedEntryIds.removeAll(res.succeededIds);
      }
      await loadEntries();
      return res;
    } catch (e) {
      _errorMessage = e.toString();
      return BulkActionResult(
        totalRequested: ids.length,
        succeededIds: const [],
        failureErrors: {for (final id in ids) id: e.toString()},
      );
    } finally {
      _isBulkActionLoading = false;
      notifyListeners();
    }
  }

  Future<BulkActionResult> _performBulkStatusUpdate(
    String status,
    List<String>? targetIds,
  ) async {
    final ids = targetIds ?? _selectedEntryIds.toList();
    if (ids.isEmpty) {
      return const BulkActionResult(
        totalRequested: 0,
        succeededIds: [],
        failureErrors: {},
      );
    }

    _isBulkActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _repository.bulkUpdateStatus(
        entryIds: ids,
        status: status,
      );
      if (res.succeededIds.isNotEmpty) {
        _selectedEntryIds.removeAll(res.succeededIds);
      }
      await loadEntries();
      return res;
    } catch (e) {
      _errorMessage = e.toString();
      return BulkActionResult(
        totalRequested: ids.length,
        succeededIds: const [],
        failureErrors: {for (final id in ids) id: e.toString()},
      );
    } finally {
      _isBulkActionLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createEntry(MasterLexiconEntry entry) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.createEntry(entry);
      await loadEntries();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateEntry(MasterLexiconEntry entry) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = await _repository.updateEntry(entry);
      final index = _entries.indexWhere((e) => e.id == updated.id);
      if (index != -1) {
        _entries[index] = updated;
      }
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteEntry(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.deleteEntry(id);
      _selectedEntryIds.remove(id);
      await loadEntries();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
