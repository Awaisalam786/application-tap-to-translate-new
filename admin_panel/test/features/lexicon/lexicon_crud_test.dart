import 'package:flutter_test/flutter_test.dart';
import 'package:german_lexicon_admin/features/auth/domain/admin_user_model.dart';
import 'package:german_lexicon_admin/features/lexicon/data/lexicon_repository.dart';
import 'package:german_lexicon_admin/features/lexicon/domain/models/bulk_action_result.dart';
import 'package:german_lexicon_admin/features/lexicon/domain/models/lexicon_example.dart';
import 'package:german_lexicon_admin/features/lexicon/domain/models/lexicon_filter.dart';
import 'package:german_lexicon_admin/features/lexicon/domain/models/lexicon_sense.dart';
import 'package:german_lexicon_admin/features/lexicon/domain/models/lexicon_synonym.dart';
import 'package:german_lexicon_admin/features/lexicon/domain/models/lexicon_translation.dart';
import 'package:german_lexicon_admin/features/lexicon/domain/models/master_lexicon_entry.dart';
import 'package:german_lexicon_admin/features/lexicon/presentation/controllers/lexicon_controller.dart';
import 'package:german_lexicon_admin/features/lexicon/presentation/controllers/word_detail_controller.dart';

class MockLexiconRepository implements LexiconRepository {
  final List<MasterLexiconEntry> _entries = [];
  final List<LexiconTranslation> _translations = [];
  final List<LexiconSense> _senses = [];
  final List<LexiconSynonym> _synonyms = [];
  final List<LexiconExample> _examples = [];

  bool shouldThrowRls = false;
  bool shouldThrowNetwork = false;

  void seedEntries(List<MasterLexiconEntry> items) {
    _entries.addAll(items);
  }

  @override
  Future<({List<MasterLexiconEntry> entries, int totalCount})> getEntries(
    LexiconFilter filter,
  ) async {
    if (shouldThrowNetwork) {
      throw Exception('Network connection failure');
    }
    if (shouldThrowRls) {
      throw const RlsPermissionException('RLS read rejected');
    }

    var result = List<MasterLexiconEntry>.from(_entries);

    if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
      final q = filter.searchQuery!.toLowerCase();
      result = result
          .where((e) =>
              e.lemma.toLowerCase().contains(q) ||
              e.normalizedLemma.contains(q))
          .toList();
    }

    if (filter.cefrLevel != null && filter.cefrLevel != 'all') {
      result = result.where((e) => e.cefrLevel == filter.cefrLevel).toList();
    }

    if (filter.partOfSpeech != null && filter.partOfSpeech != 'all') {
      result = result.where((e) => e.partOfSpeech == filter.partOfSpeech).toList();
    }

    if (filter.status != null && filter.status != 'all') {
      result = result.where((e) => e.status == filter.status).toList();
    }

    final total = result.length;
    final fromIndex = (filter.page - 1) * filter.pageSize;
    if (fromIndex >= total) {
      return (entries: <MasterLexiconEntry>[], totalCount: total);
    }
    final toIndex = (fromIndex + filter.pageSize).clamp(0, total);
    final pageList = result.sublist(fromIndex, toIndex);

    return (entries: pageList, totalCount: total);
  }

  @override
  Future<MasterLexiconEntry> getEntryById(String id) async {
    return _entries.firstWhere((e) => e.id == id);
  }

  @override
  Future<MasterLexiconEntry> createEntry(MasterLexiconEntry entry) async {
    if (shouldThrowRls) {
      throw const RlsPermissionException('RLS insert rejected');
    }

    final isDuplicate = _entries.any((e) =>
        e.normalizedLemma == entry.normalizedLemma &&
        e.partOfSpeech == entry.partOfSpeech);

    if (isDuplicate) {
      throw const DuplicateLexiconEntryException(
        'A record with these unique details already exists in the dictionary.',
      );
    }

    final created = entry.copyWith(id: 'entry_${_entries.length + 1}');
    _entries.add(created);
    return created;
  }

  @override
  Future<MasterLexiconEntry> updateEntry(MasterLexiconEntry entry) async {
    if (shouldThrowRls) {
      throw const RlsPermissionException('RLS update rejected');
    }

    final idx = _entries.indexWhere((e) => e.id == entry.id);
    if (idx != -1) {
      _entries[idx] = entry;
      return entry;
    }
    throw Exception('Not found');
  }

  @override
  Future<void> deleteEntry(String id) async {
    if (shouldThrowRls) {
      throw const RlsPermissionException('RLS delete rejected');
    }
    _entries.removeWhere((e) => e.id == id);
  }

  // --- Translations ---

  @override
  Future<List<LexiconTranslation>> getTranslations(String entryId) async {
    return _translations.where((t) => t.entryId == entryId).toList();
  }

  @override
  Future<LexiconTranslation> createTranslation(
    LexiconTranslation translation,
  ) async {
    final created = translation.copyWith(id: 'trans_${_translations.length + 1}');
    _translations.add(created);
    return created;
  }

  @override
  Future<LexiconTranslation> updateTranslation(
    LexiconTranslation translation,
  ) async {
    final idx = _translations.indexWhere((t) => t.id == translation.id);
    if (idx != -1) {
      _translations[idx] = translation;
      return translation;
    }
    throw Exception('Translation not found');
  }

  @override
  Future<void> deleteTranslation(String id) async {
    _translations.removeWhere((t) => t.id == id);
  }

  // --- Senses ---

  @override
  Future<List<LexiconSense>> getSenses(String entryId) async {
    return _senses.where((s) => s.entryId == entryId).toList();
  }

  @override
  Future<LexiconSense> createSense(LexiconSense sense) async {
    final created = sense.copyWith(id: 'sense_${_senses.length + 1}');
    _senses.add(created);
    return created;
  }

  @override
  Future<LexiconSense> updateSense(LexiconSense sense) async {
    final idx = _senses.indexWhere((s) => s.id == sense.id);
    if (idx != -1) {
      _senses[idx] = sense;
      return sense;
    }
    throw Exception('Sense not found');
  }

  @override
  Future<void> deleteSense(String id) async {
    _senses.removeWhere((s) => s.id == id);
  }

  // --- Synonyms ---

  @override
  Future<List<LexiconSynonym>> getSynonyms(String entryId) async {
    return _synonyms.where((s) => s.entryId == entryId).toList();
  }

  @override
  Future<LexiconSynonym> createSynonym(LexiconSynonym synonym) async {
    final created = synonym.copyWith(id: 'syn_${_synonyms.length + 1}');
    _synonyms.add(created);
    return created;
  }

  @override
  Future<LexiconSynonym> updateSynonym(LexiconSynonym synonym) async {
    final idx = _synonyms.indexWhere((s) => s.id == synonym.id);
    if (idx != -1) {
      _synonyms[idx] = synonym;
      return synonym;
    }
    throw Exception('Synonym not found');
  }

  @override
  Future<void> deleteSynonym(String id) async {
    _synonyms.removeWhere((s) => s.id == id);
  }

  // --- Examples ---

  @override
  Future<List<LexiconExample>> getExamples(String entryId) async {
    return _examples.where((e) => e.entryId == entryId).toList();
  }

  @override
  Future<LexiconExample> createExample(LexiconExample example) async {
    final created = example.copyWith(id: 'ex_${_examples.length + 1}');
    _examples.add(created);
    return created;
  }

  @override
  Future<LexiconExample> updateExample(LexiconExample example) async {
    final idx = _examples.indexWhere((e) => e.id == example.id);
    if (idx != -1) {
      _examples[idx] = example;
      return example;
    }
    throw Exception('Example not found');
  }

  @override
  Future<void> deleteExample(String id) async {
    _examples.removeWhere((e) => e.id == id);
  }

  @override
  Future<BulkActionResult> bulkUpdateStatus({
    required List<String> entryIds,
    required String status,
  }) async {
    final succeeded = <String>[];
    for (final id in entryIds) {
      final idx = _entries.indexWhere((e) => e.id == id);
      if (idx != -1) {
        _entries[idx] = _entries[idx].copyWith(status: status);
        succeeded.add(id);
      }
    }
    return BulkActionResult(
      totalRequested: entryIds.length,
      succeededIds: succeeded,
      failureErrors: {},
    );
  }

  @override
  Future<BulkActionResult> bulkUpdateCefr({
    required List<String> entryIds,
    required String cefrLevel,
  }) async {
    final succeeded = <String>[];
    for (final id in entryIds) {
      final idx = _entries.indexWhere((e) => e.id == id);
      if (idx != -1) {
        _entries[idx] = _entries[idx].copyWith(cefrLevel: cefrLevel);
        succeeded.add(id);
      }
    }
    return BulkActionResult(
      totalRequested: entryIds.length,
      succeededIds: succeeded,
      failureErrors: {},
    );
  }
}

void main() {
  group('Master Lexicon CRUD & Search Tests', () {
    late MockLexiconRepository repository;
    late LexiconController controller;

    setUp(() {
      repository = MockLexiconRepository();
      controller = LexiconController(repository: repository);
    });

    test('A. Add word succeeds and adds entry', () async {
      final entry = MasterLexiconEntry(
        id: '',
        lemma: 'Haus',
        normalizedLemma: MasterLexiconEntry.normalizeLemma('Haus'),
        partOfSpeech: 'noun',
        gender: 'das',
        cefrLevel: 'A1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = await controller.createEntry(entry);
      expect(success, isTrue);
      expect(controller.entries.length, 1);
      expect(controller.entries.first.lemma, 'Haus');
      expect(controller.entries.first.normalizedLemma, 'haus');
      expect(controller.totalCount, 1);
    });

    test('B. Duplicate word with same normalized lemma and POS is rejected', () async {
      final entry1 = MasterLexiconEntry(
        id: '',
        lemma: 'Haus',
        normalizedLemma: 'haus',
        partOfSpeech: 'noun',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await controller.createEntry(entry1);

      // Attempt duplicate
      final entry2 = MasterLexiconEntry(
        id: '',
        lemma: ' haus ',
        normalizedLemma: MasterLexiconEntry.normalizeLemma(' haus '),
        partOfSpeech: 'noun',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = await controller.createEntry(entry2);
      expect(success, isFalse);
      expect(controller.errorMessage, contains('already exists'));
      expect(controller.entries.length, 1);
    });

    test('C. Search filters by German word and normalized lemma', () async {
      repository.seedEntries([
        MasterLexiconEntry(
          id: '1',
          lemma: 'Apfel',
          normalizedLemma: 'apfel',
          partOfSpeech: 'noun',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MasterLexiconEntry(
          id: '2',
          lemma: 'Banane',
          normalizedLemma: 'banane',
          partOfSpeech: 'noun',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ]);

      await controller.setSearchQuery('apf');
      expect(controller.entries.length, 1);
      expect(controller.entries.first.lemma, 'Apfel');

      await controller.setSearchQuery('nan');
      expect(controller.entries.length, 1);
      expect(controller.entries.first.lemma, 'Banane');

      await controller.setSearchQuery(null);
      expect(controller.entries.length, 2);
    });

    test('D. CEFR filter restricts results', () async {
      repository.seedEntries([
        MasterLexiconEntry(
          id: '1',
          lemma: 'Wort A1',
          normalizedLemma: 'wort a1',
          partOfSpeech: 'noun',
          cefrLevel: 'A1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MasterLexiconEntry(
          id: '2',
          lemma: 'Wort B2',
          normalizedLemma: 'wort b2',
          partOfSpeech: 'noun',
          cefrLevel: 'B2',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ]);

      await controller.setCefrFilter('B2');
      expect(controller.entries.length, 1);
      expect(controller.entries.first.lemma, 'Wort B2');
    });

    test('E. POS filter restricts results', () async {
      repository.seedEntries([
        MasterLexiconEntry(
          id: '1',
          lemma: 'gehen',
          normalizedLemma: 'gehen',
          partOfSpeech: 'verb',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MasterLexiconEntry(
          id: '2',
          lemma: 'gut',
          normalizedLemma: 'gut',
          partOfSpeech: 'adjective',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ]);

      await controller.setPosFilter('verb');
      expect(controller.entries.length, 1);
      expect(controller.entries.first.lemma, 'gehen');
    });

    test('F. Status filter restricts results', () async {
      repository.seedEntries([
        MasterLexiconEntry(
          id: '1',
          lemma: 'DraftWort',
          normalizedLemma: 'draftwort',
          partOfSpeech: 'noun',
          status: 'draft',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MasterLexiconEntry(
          id: '2',
          lemma: 'VerifiedWort',
          normalizedLemma: 'verifiedwort',
          partOfSpeech: 'noun',
          status: 'verified',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ]);

      await controller.setStatusFilter('verified');
      expect(controller.entries.length, 1);
      expect(controller.entries.first.lemma, 'VerifiedWort');
    });

    test('G. Edit word updates lemma and attributes', () async {
      final entry = MasterLexiconEntry(
        id: '1',
        lemma: 'Original',
        normalizedLemma: 'original',
        partOfSpeech: 'noun',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      repository.seedEntries([entry]);
      await controller.loadEntries();

      final updated = entry.copyWith(lemma: 'Modifiziert');
      final success = await controller.updateEntry(updated);

      expect(success, isTrue);
      expect(controller.entries.first.lemma, 'Modifiziert');
    });

    test('H. Translations CRUD functions correctly with multi-language independence', () async {
      final entry = MasterLexiconEntry(
        id: '1',
        lemma: 'Haus',
        normalizedLemma: 'haus',
        partOfSpeech: 'noun',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      repository.seedEntries([entry]);

      final detailController = WordDetailController(
        repository: repository,
        entry: entry,
      );
      await detailController.loadDetails();

      // Add English translation
      final enTrans = LexiconTranslation(
        id: '',
        entryId: entry.id,
        targetLang: 'en',
        translation: 'house',
        status: 'verified',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await detailController.addTranslation(enTrans);

      // Add Urdu translation with independent status
      final urTrans = LexiconTranslation(
        id: '',
        entryId: entry.id,
        targetLang: 'ur',
        translation: 'گھر',
        status: 'draft',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      await detailController.addTranslation(urTrans);

      expect(detailController.translations.length, 2);
      expect(detailController.translations[0].status, 'verified');
      expect(detailController.translations[1].status, 'draft');

      // Update Urdu translation
      final updatedUr = detailController.translations[1].copyWith(status: 'review');
      await detailController.updateTranslation(updatedUr);
      expect(detailController.translations[1].status, 'review');

      // Delete translation
      await detailController.deleteTranslation(detailController.translations[0].id);
      expect(detailController.translations.length, 1);
      expect(detailController.translations.first.targetLang, 'ur');
    });

    test('I. Senses CRUD supports distinct polysemous meanings', () async {
      final entry = MasterLexiconEntry(
        id: 'bank_entry',
        lemma: 'Bank',
        normalizedLemma: 'bank',
        partOfSpeech: 'noun',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      repository.seedEntries([entry]);

      final detailController = WordDetailController(
        repository: repository,
        entry: entry,
      );
      await detailController.loadDetails();

      // Sense 1: Financial
      await detailController.addSense(LexiconSense(
        id: '',
        entryId: entry.id,
        senseOrder: 1,
        definitionDe: 'Kreditinstitut, Finanzunternehmen',
        contextDomain: 'Finance',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      // Sense 2: Furniture
      await detailController.addSense(LexiconSense(
        id: '',
        entryId: entry.id,
        senseOrder: 2,
        definitionDe: 'Sitzgelegenheit für mehrere Personen',
        contextDomain: 'Furniture',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      expect(detailController.senses.length, 2);
      expect(detailController.senses[0].definitionDe, contains('Kreditinstitut'));
      expect(detailController.senses[1].definitionDe, contains('Sitzgelegenheit'));
    });

    test('J. Synonyms CRUD functions independently without collapsing into translations', () async {
      final entry = MasterLexiconEntry(
        id: '1',
        lemma: 'Haus',
        normalizedLemma: 'haus',
        partOfSpeech: 'noun',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      repository.seedEntries([entry]);

      final detailController = WordDetailController(
        repository: repository,
        entry: entry,
      );
      await detailController.loadDetails();

      await detailController.addSynonym(LexiconSynonym(
        id: '',
        entryId: entry.id,
        synonymWord: 'Gebäude',
        nuanceNote: 'General term',
        status: 'draft',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      expect(detailController.synonyms.length, 1);
      expect(detailController.synonyms.first.synonymWord, 'Gebäude');
    });

    test('K. Examples CRUD manages original sentences', () async {
      final entry = MasterLexiconEntry(
        id: '1',
        lemma: 'Haus',
        normalizedLemma: 'haus',
        partOfSpeech: 'noun',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      repository.seedEntries([entry]);

      final detailController = WordDetailController(
        repository: repository,
        entry: entry,
      );
      await detailController.loadDetails();

      await detailController.addExample(LexiconExample(
        id: '',
        entryId: entry.id,
        sentenceDe: 'Das Haus steht am Waldrand.',
        sentenceEn: 'The house stands at the edge of the forest.',
        cefrLevel: 'A1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      expect(detailController.examples.length, 1);
      expect(detailController.examples.first.sentenceDe, 'Das Haus steht am Waldrand.');
    });

    test('L. Role-based permissions correctly constrain Editor vs Reviewer vs Superadmin', () {
      final draftEntry = MasterLexiconEntry(
        id: '1',
        lemma: 'Draft',
        normalizedLemma: 'draft',
        partOfSpeech: 'noun',
        status: 'draft',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final verifiedEntry = MasterLexiconEntry(
        id: '2',
        lemma: 'Verified',
        normalizedLemma: 'verified',
        partOfSpeech: 'noun',
        status: 'verified',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Editor permissions
      expect(draftEntry.canEdit(AdminRole.editor), isTrue);
      expect(verifiedEntry.canEdit(AdminRole.editor), isFalse); // Editor cannot edit verified
      expect(draftEntry.canVerify(AdminRole.editor), isFalse); // Editor cannot verify
      expect(draftEntry.canDelete(AdminRole.editor), isFalse); // Editor cannot delete

      // Reviewer permissions
      expect(draftEntry.canEdit(AdminRole.reviewer), isTrue);
      expect(verifiedEntry.canEdit(AdminRole.reviewer), isTrue);
      expect(draftEntry.canVerify(AdminRole.reviewer), isTrue); // Reviewer can verify
      expect(draftEntry.canDelete(AdminRole.reviewer), isFalse); // Reviewer cannot delete

      // Superadmin permissions
      expect(draftEntry.canEdit(AdminRole.superadmin), isTrue);
      expect(verifiedEntry.canEdit(AdminRole.superadmin), isTrue);
      expect(draftEntry.canVerify(AdminRole.superadmin), isTrue);
      expect(draftEntry.canDelete(AdminRole.superadmin), isTrue); // Superadmin can delete
    });

    test('M. RLS rejection handling records friendly error message', () async {
      repository.shouldThrowRls = true;
      final entry = MasterLexiconEntry(
        id: '1',
        lemma: 'Restricted',
        normalizedLemma: 'restricted',
        partOfSpeech: 'noun',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final success = await controller.createEntry(entry);
      expect(success, isFalse);
      expect(controller.errorMessage, contains('RLS'));
    });

    test('N. Empty results handled cleanly', () async {
      await controller.loadEntries();
      expect(controller.entries, isEmpty);
      expect(controller.totalCount, 0);
      expect(controller.errorMessage, isNull);
    });

    test('O. Network error records user-facing failure message', () async {
      repository.shouldThrowNetwork = true;
      await controller.loadEntries();
      expect(controller.entries, isEmpty);
      expect(controller.errorMessage, contains('Network connection failure'));
    });
  });
}
