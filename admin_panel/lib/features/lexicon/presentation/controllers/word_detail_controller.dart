import 'package:flutter/foundation.dart';
import '../../data/lexicon_repository.dart';
import '../../domain/models/lexicon_example.dart';
import '../../domain/models/lexicon_sense.dart';
import '../../domain/models/lexicon_synonym.dart';
import '../../domain/models/lexicon_translation.dart';
import '../../domain/models/master_lexicon_entry.dart';

class WordDetailController extends ChangeNotifier {
  final LexiconRepository _repository;
  MasterLexiconEntry _entry;

  WordDetailController({
    required this._repository,
    required this._entry,
  });

  MasterLexiconEntry get entry => _entry;

  List<LexiconTranslation> _translations = [];
  List<LexiconSense> _senses = [];
  List<LexiconSynonym> _synonyms = [];
  List<LexiconExample> _examples = [];

  bool _isLoading = false;
  String? _errorMessage;

  List<LexiconTranslation> get translations => _translations;
  List<LexiconSense> get senses => _senses;
  List<LexiconSynonym> get synonyms => _synonyms;
  List<LexiconExample> get examples => _examples;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadDetails() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updatedEntry = await _repository.getEntryById(_entry.id);
      _entry = updatedEntry;

      final t = await _repository.getTranslations(_entry.id);
      final s = await _repository.getSenses(_entry.id);
      final syn = await _repository.getSynonyms(_entry.id);
      final ex = await _repository.getExamples(_entry.id);

      _translations = t;
      _senses = s;
      _synonyms = syn;
      _examples = ex;
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // --- Status Transitions ---

  Future<bool> updateEntryStatus(String newStatus) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final updated = _entry.copyWith(status: newStatus);
      _entry = await _repository.updateEntry(updated);
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

  // --- Translations CRUD ---

  Future<bool> addTranslation(LexiconTranslation translation) async {
    try {
      final created = await _repository.createTranslation(translation);
      _translations.add(created);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateTranslation(LexiconTranslation translation) async {
    try {
      final updated = await _repository.updateTranslation(translation);
      final index = _translations.indexWhere((t) => t.id == updated.id);
      if (index != -1) _translations[index] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteTranslation(String id) async {
    try {
      await _repository.deleteTranslation(id);
      _translations.removeWhere((t) => t.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // --- Senses CRUD ---

  Future<bool> addSense(LexiconSense sense) async {
    try {
      final created = await _repository.createSense(sense);
      _senses.add(created);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSense(LexiconSense sense) async {
    try {
      final updated = await _repository.updateSense(sense);
      final index = _senses.indexWhere((s) => s.id == updated.id);
      if (index != -1) _senses[index] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSense(String id) async {
    try {
      await _repository.deleteSense(id);
      _senses.removeWhere((s) => s.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // --- Synonyms CRUD ---

  Future<bool> addSynonym(LexiconSynonym synonym) async {
    try {
      final created = await _repository.createSynonym(synonym);
      _synonyms.add(created);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSynonym(LexiconSynonym synonym) async {
    try {
      final updated = await _repository.updateSynonym(synonym);
      final index = _synonyms.indexWhere((s) => s.id == updated.id);
      if (index != -1) _synonyms[index] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSynonym(String id) async {
    try {
      await _repository.deleteSynonym(id);
      _synonyms.removeWhere((s) => s.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // --- Examples CRUD ---

  Future<bool> addExample(LexiconExample example) async {
    try {
      final created = await _repository.createExample(example);
      _examples.add(created);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateExample(LexiconExample example) async {
    try {
      final updated = await _repository.updateExample(example);
      final index = _examples.indexWhere((e) => e.id == updated.id);
      if (index != -1) _examples[index] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteExample(String id) async {
    try {
      await _repository.deleteExample(id);
      _examples.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
