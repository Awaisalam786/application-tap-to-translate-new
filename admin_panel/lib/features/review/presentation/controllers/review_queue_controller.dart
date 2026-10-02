import 'package:flutter/foundation.dart';
import 'package:german_lexicon_admin/features/review/data/review_repository.dart';
import 'package:german_lexicon_admin/features/review/domain/models/review_queue_counts.dart';
import 'package:german_lexicon_admin/features/review/domain/models/review_queue_item.dart';

class ReviewQueueController extends ChangeNotifier {
  final ReviewRepository _repository;

  ReviewQueueController({required this._repository});

  ReviewQueueCounts _counts = const ReviewQueueCounts();
  ReviewCategory _activeCategory = ReviewCategory.masterWords;
  List<ReviewQueueItem> _items = [];
  int _totalCount = 0;

  String? _searchQuery;
  String? _cefrFilter = 'all';
  String? _posFilter = 'all';
  int _page = 1;
  final int _pageSize = 15;

  bool _isLoading = false;
  bool _isActionLoading = false;
  String? _errorMessage;

  ReviewQueueCounts get counts => _counts;
  ReviewCategory get activeCategory => _activeCategory;
  List<ReviewQueueItem> get items => _items;
  int get totalCount => _totalCount;
  String? get searchQuery => _searchQuery;
  String? get cefrFilter => _cefrFilter;
  String? get posFilter => _posFilter;
  int get page => _page;
  int get pageSize => _pageSize;
  bool get isLoading => _isLoading;
  bool get isActionLoading => _isActionLoading;
  String? get errorMessage => _errorMessage;

  int get totalPages => (_totalCount / _pageSize).ceil().clamp(1, 999999);
  bool get hasPreviousPage => _page > 1;
  bool get hasNextPage => _page < totalPages;

  Future<void> refresh() async {
    await loadCounts();
    await loadQueueItems();
  }

  Future<void> loadCounts() async {
    try {
      _counts = await _repository.getCounts();
      notifyListeners();
    } catch (e) {
      // Non-fatal for counts
    }
  }

  Future<void> loadQueueItems() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _repository.getQueueItems(
        category: _activeCategory,
        searchQuery: _searchQuery,
        cefrLevel: _cefrFilter,
        partOfSpeech: _posFilter,
        page: _page,
        pageSize: _pageSize,
      );
      _items = res.items;
      _totalCount = res.totalCount;
    } catch (e) {
      _errorMessage = e.toString();
      _items = [];
      _totalCount = 0;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> selectCategory(ReviewCategory category) async {
    if (_activeCategory == category) return;
    _activeCategory = category;
    _page = 1;
    await loadQueueItems();
  }

  Future<void> setSearchQuery(String? query) async {
    final cleaned = query?.trim();
    if (cleaned == _searchQuery) return;
    _searchQuery = (cleaned != null && cleaned.isNotEmpty) ? cleaned : null;
    _page = 1;
    await loadQueueItems();
  }

  Future<void> setCefrFilter(String? cefr) async {
    if (cefr == _cefrFilter) return;
    _cefrFilter = cefr;
    _page = 1;
    await loadQueueItems();
  }

  Future<void> setPosFilter(String? pos) async {
    if (pos == _posFilter) return;
    _posFilter = pos;
    _page = 1;
    await loadQueueItems();
  }

  Future<void> setPage(int newPage) async {
    if (newPage == _page || newPage < 1 || newPage > totalPages) return;
    _page = newPage;
    await loadQueueItems();
  }

  Future<bool> verifyItem(ReviewQueueItem item) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.verifyItem(item);
      // Remove from active list immediately
      _items.removeWhere((i) => i.id == item.id);
      _totalCount = (_totalCount - 1).clamp(0, 999999);
      _isActionLoading = false;
      notifyListeners();

      // Refresh counts in background
      await loadCounts();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isActionLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectItem(ReviewQueueItem item) async {
    _isActionLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.rejectItem(item);
      // Remove from active list immediately
      _items.removeWhere((i) => i.id == item.id);
      _totalCount = (_totalCount - 1).clamp(0, 999999);
      _isActionLoading = false;
      notifyListeners();

      // Refresh counts in background
      await loadCounts();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isActionLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
