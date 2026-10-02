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
import 'package:german_lexicon_admin/features/quality/data/quality_repository.dart';
import 'package:german_lexicon_admin/features/quality/domain/models/quality_dashboard_stats.dart';
import 'package:german_lexicon_admin/features/quality/domain/models/word_quality.dart';
import 'package:german_lexicon_admin/features/quality/domain/services/duplicate_detector.dart';
import 'package:german_lexicon_admin/features/quality/presentation/controllers/quality_dashboard_controller.dart';

class MockLexiconRepository implements LexiconRepository {
  final List<MasterLexiconEntry> _entries = [];
  bool failNextBulk = false;

  void seedEntries(List<MasterLexiconEntry> items) {
    _entries.clear();
    _entries.addAll(items);
  }

  @override
  Future<({List<MasterLexiconEntry> entries, int totalCount})> getEntries(LexiconFilter filter) async {
    var result = List<MasterLexiconEntry>.from(_entries);
    if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
      result = result.where((e) => e.lemma.toLowerCase().contains(filter.searchQuery!.toLowerCase())).toList();
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
    if (filter.gender != null && filter.gender != 'all') {
      result = result.where((e) => e.gender == filter.gender).toList();
    }
    if (filter.hasAdvancedFilters) {
      result = result.where((e) {
        final trans = e.translations ?? [];
        if (filter.hasEnTranslation != null) {
          final has = trans.any((t) => t.targetLang == 'en' && t.translation.isNotEmpty);
          if (has != filter.hasEnTranslation) return false;
        }
        if (filter.hasUrTranslation != null) {
          final has = trans.any((t) => t.targetLang == 'ur' && t.translation.isNotEmpty);
          if (has != filter.hasUrTranslation) return false;
        }
        if (filter.hasFaTranslation != null) {
          final has = trans.any((t) => t.targetLang == 'fa' && t.translation.isNotEmpty);
          if (has != filter.hasFaTranslation) return false;
        }
        if (filter.hasArTranslation != null) {
          final has = trans.any((t) => t.targetLang == 'ar' && t.translation.isNotEmpty);
          if (has != filter.hasArTranslation) return false;
        }
        if (filter.hasExample != null) {
          final has = (e.examples ?? []).isNotEmpty;
          if (has != filter.hasExample) return false;
        }
        if (filter.hasSense != null) {
          final has = (e.senses ?? []).isNotEmpty;
          if (has != filter.hasSense) return false;
        }
        if (filter.hasSynonym != null) {
          final has = (e.synonyms ?? []).isNotEmpty;
          if (has != filter.hasSynonym) return false;
        }
        return true;
      }).toList();
    }
    return (entries: result, totalCount: result.length);
  }

  @override
  Future<MasterLexiconEntry> getEntryById(String id) async =>
      _entries.firstWhere((e) => e.id == id);

  @override
  Future<MasterLexiconEntry> createEntry(MasterLexiconEntry entry) async {
    _entries.add(entry);
    return entry;
  }

  @override
  Future<MasterLexiconEntry> updateEntry(MasterLexiconEntry entry) async {
    final idx = _entries.indexWhere((e) => e.id == entry.id);
    if (idx != -1) _entries[idx] = entry;
    return entry;
  }

  @override
  Future<void> deleteEntry(String id) async {
    _entries.removeWhere((e) => e.id == id);
  }

  @override
  Future<BulkActionResult> bulkUpdateStatus({
    required List<String> entryIds,
    required String status,
  }) async {
    if (failNextBulk) {
      failNextBulk = false;
      return BulkActionResult(
        totalRequested: entryIds.length,
        succeededIds: [],
        failureErrors: {for (final id in entryIds) id: 'Simulated bulk failure'},
      );
    }
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
    if (failNextBulk) {
      failNextBulk = false;
      return BulkActionResult(
        totalRequested: entryIds.length,
        succeededIds: [],
        failureErrors: {for (final id in entryIds) id: 'Simulated bulk failure'},
      );
    }
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

  @override
  Future<List<LexiconTranslation>> getTranslations(String entryId) async => [];
  @override
  Future<LexiconTranslation> createTranslation(LexiconTranslation translation) async => translation;
  @override
  Future<LexiconTranslation> updateTranslation(LexiconTranslation translation) async => translation;
  @override
  Future<void> deleteTranslation(String id) async {}

  @override
  Future<List<LexiconSense>> getSenses(String entryId) async => [];
  @override
  Future<LexiconSense> createSense(LexiconSense sense) async => sense;
  @override
  Future<LexiconSense> updateSense(LexiconSense sense) async => sense;
  @override
  Future<void> deleteSense(String id) async {}

  @override
  Future<List<LexiconSynonym>> getSynonyms(String entryId) async => [];
  @override
  Future<LexiconSynonym> createSynonym(LexiconSynonym synonym) async => synonym;
  @override
  Future<LexiconSynonym> updateSynonym(LexiconSynonym synonym) async => synonym;
  @override
  Future<void> deleteSynonym(String id) async {}

  @override
  Future<List<LexiconExample>> getExamples(String entryId) async => [];
  @override
  Future<LexiconExample> createExample(LexiconExample example) async => example;
  @override
  Future<LexiconExample> updateExample(LexiconExample example) async => example;
  @override
  Future<void> deleteExample(String id) async {}
}

class MockQualityRepository implements QualityRepository {
  QualityDashboardStats stats = const QualityDashboardStats(
    totalWords: 100,
    draftCount: 20,
    reviewCount: 30,
    verifiedCount: 45,
    rejectedCount: 5,
    a1Count: 40,
    a2Count: 30,
    b1Count: 20,
    b2Count: 10,
    missingEnCount: 15,
    missingUrCount: 25,
    missingFaCount: 30,
    missingArCount: 35,
    missingGenderCount: 8,
    missingPluralCount: 10,
    missingSenseCount: 12,
    missingExampleCount: 18,
  );

  List<DuplicateCandidate> duplicates = [];

  @override
  Future<QualityDashboardStats> getQualityStats() async => stats;

  @override
  Future<List<DuplicateCandidate>> getDuplicateCandidates({int limit = 200}) async => duplicates;
}

void main() {
  group('Phase 12B-6 Word Quality Scoring Tests', () {
    test('Evaluates complete noun with all translations, senses, and examples', () {
      final entry = MasterLexiconEntry(
        id: '1',
        lemma: 'Haus',
        normalizedLemma: 'haus',
        partOfSpeech: 'noun',
        gender: 'das',
        pluralForm: 'Häuser',
        cefrLevel: 'A1',
        status: 'verified',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final translations = [
        LexiconTranslation(id: 't1', entryId: '1', targetLang: 'en', translation: 'house', createdAt: DateTime.now(), updatedAt: DateTime.now()),
        LexiconTranslation(id: 't2', entryId: '1', targetLang: 'ur', translation: 'گھر', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      ];
      final senses = [
        LexiconSense(id: 's1', entryId: '1', definitionDe: 'Gebäude zum Wohnen', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      ];
      final examples = [
        LexiconExample(id: 'e1', entryId: '1', sentenceDe: 'Das Haus ist groß.', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      ];

      final report = WordQualityReport.evaluate(
        entry: entry,
        translations: translations,
        senses: senses,
        examples: examples,
      );

      expect(report.status, WordQualityStatus.complete);
      expect(report.score, 100);
      expect(report.issues, isEmpty);
    });

    test('Identifies missingRequired for noun without gender or English translation', () {
      final entry = MasterLexiconEntry(
        id: '2',
        lemma: 'Apfel',
        normalizedLemma: 'apfel',
        partOfSpeech: 'noun',
        gender: null, // missing gender
        pluralForm: 'Äpfel',
        cefrLevel: 'A1',
        status: 'draft',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final report = WordQualityReport.evaluate(
        entry: entry,
        translations: [], // missing English
      );

      expect(report.status, WordQualityStatus.missingRequired);
      expect(report.issues, contains('Noun missing gender / article (der/die/das)'));
      expect(report.issues, contains('Missing English translation'));
    });

    test('Marks status as needsReview when entry status is review', () {
      final entry = MasterLexiconEntry(
        id: '3',
        lemma: 'schnell',
        normalizedLemma: 'schnell',
        partOfSpeech: 'adjective',
        cefrLevel: 'A1',
        status: 'review',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final translations = [
        LexiconTranslation(id: 't1', entryId: '3', targetLang: 'en', translation: 'fast', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      ];

      final report = WordQualityReport.evaluate(
        entry: entry,
        translations: translations,
      );

      expect(report.status, WordQualityStatus.needsReview);
    });
  });

  group('Phase 12B-6 Duplicate Detection Tests', () {
    test('Detects exact lemma + POS duplicates', () {
      final a = MasterLexiconEntry(
        id: '1',
        lemma: 'Bank',
        normalizedLemma: 'bank',
        partOfSpeech: 'noun',
        gender: 'die',
        cefrLevel: 'A1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final b = MasterLexiconEntry(
        id: '2',
        lemma: 'bank',
        normalizedLemma: 'bank',
        partOfSpeech: 'noun',
        gender: 'die',
        cefrLevel: 'A2',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final dups = DuplicateDetector.detectEntryDuplicates([a, b]);
      expect(dups.length, 1);
      expect(dups.first.type, DuplicateType.lemmaPosExact);
      expect(dups.first.confidence, 1.0);
    });

    test('Detects German umlaut / spelling variants (ä vs ae, ß vs ss)', () {
      final a = MasterLexiconEntry(
        id: '1',
        lemma: 'groß',
        normalizedLemma: 'groß',
        partOfSpeech: 'adjective',
        cefrLevel: 'A1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final b = MasterLexiconEntry(
        id: '2',
        lemma: 'gross',
        normalizedLemma: 'gross',
        partOfSpeech: 'adjective',
        cefrLevel: 'A1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final dups = DuplicateDetector.detectEntryDuplicates([a, b]);
      expect(dups.length, 1);
      expect(dups.first.type, DuplicateType.spellingVariant);
    });

    test('Detects duplicate translations within an entry (Unicode UR/AR/FA)', () {
      final entry = MasterLexiconEntry(
        id: '1',
        lemma: 'Wasser',
        normalizedLemma: 'wasser',
        partOfSpeech: 'noun',
        cefrLevel: 'A1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final translations = [
        LexiconTranslation(id: 't1', entryId: '1', targetLang: 'ur', translation: 'پانی', createdAt: DateTime.now(), updatedAt: DateTime.now()),
        LexiconTranslation(id: 't2', entryId: '1', targetLang: 'ur', translation: 'پانی', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      ];

      final dups = DuplicateDetector.detectDuplicateTranslations(entry: entry, translations: translations);
      expect(dups.length, 1);
      expect(dups.first.type, DuplicateType.duplicateTranslation);
    });

    test('Detects duplicate synonyms within an entry', () {
      final entry = MasterLexiconEntry(
        id: '1',
        lemma: 'schön',
        normalizedLemma: 'schön',
        partOfSpeech: 'adjective',
        cefrLevel: 'A1',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final synonyms = [
        LexiconSynonym(id: 's1', entryId: '1', synonymWord: 'hübsch', createdAt: DateTime.now(), updatedAt: DateTime.now()),
        LexiconSynonym(id: 's2', entryId: '1', synonymWord: 'Hübsch', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      ];

      final dups = DuplicateDetector.detectDuplicateSynonyms(entry: entry, synonyms: synonyms);
      expect(dups.length, 1);
      expect(dups.first.type, DuplicateType.duplicateSynonym);
    });
  });

  group('Phase 12B-6 Bulk Selection & Controller Tests', () {
    late MockLexiconRepository repository;
    late LexiconController controller;

    setUp(() {
      repository = MockLexiconRepository();
      controller = LexiconController(repository: repository);
    });

    test('Toggles entry selection and supports selectAll / deselectAll', () async {
      repository.seedEntries([
        MasterLexiconEntry(id: '1', lemma: 'Haus', normalizedLemma: 'haus', partOfSpeech: 'noun', createdAt: DateTime.now(), updatedAt: DateTime.now()),
        MasterLexiconEntry(id: '2', lemma: 'Buch', normalizedLemma: 'buch', partOfSpeech: 'noun', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      ]);
      await controller.loadEntries();

      expect(controller.selectedCount, 0);
      controller.toggleSelection('1');
      expect(controller.selectedCount, 1);
      expect(controller.selectedEntryIds, contains('1'));

      controller.selectAllVisible();
      expect(controller.selectedCount, 2);
      expect(controller.isAllSelected, isTrue);

      controller.clearSelection();
      expect(controller.selectedCount, 0);
    });

    test('Editor is BLOCKED from bulk verify and bulk reject with explicit failure errors', () async {
      repository.seedEntries([
        MasterLexiconEntry(id: '1', lemma: 'Haus', normalizedLemma: 'haus', partOfSpeech: 'noun', status: 'draft', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      ]);
      await controller.loadEntries();
      controller.toggleSelection('1');

      final verifyRes = await controller.bulkVerify(userRole: AdminRole.editor);
      expect(verifyRes.isFullFailure, isTrue);
      expect(verifyRes.failureErrors['1'], contains('Editor role is not authorized to verify'));

      final rejectRes = await controller.bulkReject(userRole: AdminRole.editor);
      expect(rejectRes.isFullFailure, isTrue);
      expect(rejectRes.failureErrors['1'], contains('Editor role is not authorized to reject'));
    });

    test('Reviewer and Superadmin can execute bulk verify and bulk reject', () async {
      repository.seedEntries([
        MasterLexiconEntry(id: '1', lemma: 'Haus', normalizedLemma: 'haus', partOfSpeech: 'noun', status: 'review', createdAt: DateTime.now(), updatedAt: DateTime.now()),
        MasterLexiconEntry(id: '2', lemma: 'Buch', normalizedLemma: 'buch', partOfSpeech: 'noun', status: 'review', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      ]);
      await controller.loadEntries();
      controller.selectAllVisible();

      final verifyRes = await controller.bulkVerify(userRole: AdminRole.reviewer);
      expect(verifyRes.isFullSuccess, isTrue);
      expect(verifyRes.successCount, 2);
      expect(controller.entries.every((e) => e.status == 'verified'), isTrue);

      // Deselect cleared on success
      expect(controller.selectedCount, 0);
    });

    test('All roles can execute bulk move to review', () async {
      repository.seedEntries([
        MasterLexiconEntry(id: '1', lemma: 'Haus', normalizedLemma: 'haus', partOfSpeech: 'noun', status: 'draft', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      ]);
      await controller.loadEntries();
      controller.toggleSelection('1');

      final res = await controller.bulkMoveToReview();
      expect(res.isFullSuccess, isTrue);
      expect(controller.entries.first.status, 'review');
    });

    test('Bulk assign CEFR level succeeds across selected entries', () async {
      repository.seedEntries([
        MasterLexiconEntry(id: '1', lemma: 'Haus', normalizedLemma: 'haus', partOfSpeech: 'noun', cefrLevel: 'unclassified', createdAt: DateTime.now(), updatedAt: DateTime.now()),
        MasterLexiconEntry(id: '2', lemma: 'Buch', normalizedLemma: 'buch', partOfSpeech: 'noun', cefrLevel: 'unclassified', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      ]);
      await controller.loadEntries();
      controller.selectAllVisible();

      final res = await controller.bulkAssignCefr(cefrLevel: 'A1');
      expect(res.isFullSuccess, isTrue);
      expect(controller.entries.every((e) => e.cefrLevel == 'A1'), isTrue);
    });

    test('Handles partial and total bulk failures cleanly without crash', () async {
      repository.seedEntries([
        MasterLexiconEntry(id: '1', lemma: 'Haus', normalizedLemma: 'haus', partOfSpeech: 'noun', createdAt: DateTime.now(), updatedAt: DateTime.now()),
      ]);
      await controller.loadEntries();
      controller.toggleSelection('1');

      repository.failNextBulk = true;
      final res = await controller.bulkAssignCefr(cefrLevel: 'B2');
      expect(res.isFullFailure, isTrue);
      expect(res.failureCount, 1);
    });
  });

  group('Phase 12B-6 Advanced Filtering Tests', () {
    late MockLexiconRepository repository;
    late LexiconController controller;

    setUp(() {
      repository = MockLexiconRepository();
      controller = LexiconController(repository: repository);
    });

    test('Filters by gender and translation availability', () async {
      repository.seedEntries([
        MasterLexiconEntry(
          id: '1',
          lemma: 'Tisch',
          normalizedLemma: 'tisch',
          partOfSpeech: 'noun',
          gender: 'der',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          translations: [
            LexiconTranslation(id: 't1', entryId: '1', targetLang: 'en', translation: 'table', createdAt: DateTime.now(), updatedAt: DateTime.now()),
          ],
        ),
        MasterLexiconEntry(
          id: '2',
          lemma: 'Lampe',
          normalizedLemma: 'lampe',
          partOfSpeech: 'noun',
          gender: 'die',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          translations: [
            LexiconTranslation(id: 't2', entryId: '2', targetLang: 'ur', translation: 'چراغ', createdAt: DateTime.now(), updatedAt: DateTime.now()),
          ],
        ),
      ]);

      // Filter for 'der'
      await controller.setGenderFilter('der');
      expect(controller.entries.length, 1);
      expect(controller.entries.first.lemma, 'Tisch');

      // Filter for 'has EN translation'
      await controller.setGenderFilter('all');
      await controller.setFilterHasTranslation(en: true);
      expect(controller.entries.length, 1);
      expect(controller.entries.first.lemma, 'Tisch');

      // Filter for 'missing EN translation'
      await controller.setFilterHasTranslation(en: false);
      expect(controller.entries.length, 1);
      expect(controller.entries.first.lemma, 'Lampe');

      // Clear filters
      await controller.clearAdvancedFilters();
      expect(controller.entries.length, 2);
    });
  });

  group('Phase 12B-6 Quality Dashboard Controller Tests', () {
    test('Loads dashboard stats and duplicate candidates', () async {
      final repo = MockQualityRepository();
      final controller = QualityDashboardController(repository: repo);

      expect(controller.stats.totalWords, 0);
      await controller.refresh();

      expect(controller.stats.totalWords, 100);
      expect(controller.stats.draftCount, 20);
      expect(controller.stats.reviewCount, 30);
      expect(controller.stats.verifiedCount, 45);
      expect(controller.stats.missingEnCount, 15);
      expect(controller.stats.missingGenderCount, 8);
    });
  });
}
