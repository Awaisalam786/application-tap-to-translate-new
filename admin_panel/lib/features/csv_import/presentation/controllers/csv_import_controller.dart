import 'package:flutter/foundation.dart';
import 'package:german_lexicon_admin/features/csv_import/data/csv_import_repository.dart';
import 'package:german_lexicon_admin/features/csv_import/domain/models/csv_import_row.dart';
import 'package:german_lexicon_admin/features/csv_import/domain/models/csv_import_summary.dart';
import 'package:german_lexicon_admin/features/csv_import/domain/services/csv_parser.dart';
import 'package:german_lexicon_admin/features/csv_import/domain/services/csv_validator.dart';
import 'package:german_lexicon_admin/features/lexicon/data/lexicon_repository.dart';

class CsvImportController extends ChangeNotifier {
  final CsvImportRepository _repository;

  CsvImportController(this._repository);

  String _csvRawText = '';
  List<CsvImportRow> _rows = [];
  String _targetStatus = 'review'; // Default to 'review' for Review Queue integration
  bool _isParsing = false;
  bool _isImporting = false;
  String? _errorMessage;
  CsvImportExecutionResult? _lastResult;
  String _activePreviewFilter = 'all'; // all, valid, warnings, errors, conflicts

  String get csvRawText => _csvRawText;
  List<CsvImportRow> get rows => _rows;
  String get targetStatus => _targetStatus;
  bool get isParsing => _isParsing;
  bool get isImporting => _isImporting;
  String? get errorMessage => _errorMessage;
  CsvImportExecutionResult? get lastResult => _lastResult;
  String get activePreviewFilter => _activePreviewFilter;

  bool get hasRows => _rows.isNotEmpty;
  CsvImportSummary get summary => CsvImportSummary.fromRows(_rows);

  List<CsvImportRow> get filteredRows {
    switch (_activePreviewFilter) {
      case 'valid':
        return _rows.where((r) => r.validationStatus == CsvValidationStatus.valid && !r.isVerifiedConflict).toList();
      case 'warnings':
        return _rows.where((r) => r.validationStatus == CsvValidationStatus.warning).toList();
      case 'errors':
        return _rows.where((r) => r.validationStatus == CsvValidationStatus.error).toList();
      case 'conflicts':
        return _rows.where((r) => r.isVerifiedConflict || r.duplicateStatus == DuplicateStatus.duplicateInFile).toList();
      case 'all':
      default:
        return _rows;
    }
  }

  void setCsvText(String text) {
    _csvRawText = text;
    notifyListeners();
  }

  /// Sets target status: ONLY 'draft' or 'review'. Throws if 'verified'.
  void setTargetStatus(String status) {
    if (status == 'verified') {
      throw ArgumentError('Security policy prohibits importing directly as "verified".');
    }
    if (status != 'draft' && status != 'review') {
      return;
    }
    _targetStatus = status;
    notifyListeners();
  }

  void setPreviewFilter(String filter) {
    _activePreviewFilter = filter;
    notifyListeners();
  }

  void toggleRowSelection(int rowIndex) {
    final idx = _rows.indexWhere((r) => r.rowIndex == rowIndex);
    if (idx != -1) {
      final row = _rows[idx];
      // Cannot select verified conflicts or errors
      if (row.isVerifiedConflict || !row.isValid) return;

      _rows[idx] = row.copyWith(shouldImport: !row.shouldImport);
      notifyListeners();
    }
  }

  void selectAll(bool select) {
    _rows = _rows.map((r) {
      if (r.isVerifiedConflict || !r.isValid) {
        return r.copyWith(shouldImport: false);
      }
      return r.copyWith(shouldImport: select);
    }).toList();
    notifyListeners();
  }

  Future<bool> parseAndValidate() async {
    if (_csvRawText.trim().isEmpty) {
      _errorMessage = 'Please provide CSV content to parse.';
      notifyListeners();
      return false;
    }

    _isParsing = true;
    _errorMessage = null;
    _lastResult = null;
    notifyListeners();

    try {
      // 1. Parse CSV
      final records = CsvParser.parse(_csvRawText);
      if (records.isEmpty) {
        _errorMessage = 'No valid data rows found in CSV. Please ensure a header row is included.';
        _isParsing = false;
        notifyListeners();
        return false;
      }

      // 2. Validate & normalize
      final validated = CsvValidator.validate(records);

      // 3. Check database duplicates
      _rows = await _repository.checkDatabaseDuplicates(validated);
      _isParsing = false;
      notifyListeners();
      return true;
    } on RlsPermissionException catch (e) {
      _errorMessage = e.message;
      _isParsing = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to parse CSV: $e';
      _isParsing = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> executeImport({String? createdBy}) async {
    final toImport = _rows.where((r) => r.canBeImported).toList();
    if (toImport.isEmpty) {
      _errorMessage = 'No valid rows selected for import.';
      notifyListeners();
      return false;
    }

    _isImporting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _repository.executeImport(
        _rows,
        targetStatus: _targetStatus,
        createdBy: createdBy,
      );

      _lastResult = result;
      _isImporting = false;
      notifyListeners();
      return result.successCount > 0;
    } catch (e) {
      _errorMessage = 'Import failed: $e';
      _isImporting = false;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _csvRawText = '';
    _rows = [];
    _errorMessage = null;
    _lastResult = null;
    _activePreviewFilter = 'all';
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
