import 'package:flutter/foundation.dart';
import '../../data/quality_repository.dart';
import '../../domain/models/quality_dashboard_stats.dart';
import '../../domain/services/duplicate_detector.dart';

class QualityDashboardController extends ChangeNotifier {
  final QualityRepository _repository;

  QualityDashboardController({required QualityRepository repository})
      // ignore: prefer_initializing_formals
      : _repository = repository;

  QualityDashboardStats _stats = const QualityDashboardStats();
  List<DuplicateCandidate> _duplicates = [];
  bool _isLoading = false;
  bool _isDuplicatesLoading = false;
  String? _errorMessage;

  QualityDashboardStats get stats => _stats;
  List<DuplicateCandidate> get duplicates => _duplicates;
  bool get isLoading => _isLoading;
  bool get isDuplicatesLoading => _isDuplicatesLoading;
  String? get errorMessage => _errorMessage;

  Future<void> refresh() async {
    await Future.wait([
      loadStats(),
      loadDuplicates(),
    ]);
  }

  Future<void> loadStats() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _stats = await _repository.getQualityStats();
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDuplicates() async {
    _isDuplicatesLoading = true;
    notifyListeners();

    try {
      _duplicates = await _repository.getDuplicateCandidates();
    } catch (e) {
      _duplicates = [];
    } finally {
      _isDuplicatesLoading = false;
      notifyListeners();
    }
  }
}
