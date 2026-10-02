import 'package:flutter/material.dart';
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
import 'package:german_lexicon_admin/features/review/data/review_repository.dart';
import 'package:german_lexicon_admin/features/review/domain/models/review_queue_counts.dart';
import 'package:german_lexicon_admin/features/review/domain/models/review_queue_item.dart';
import 'package:german_lexicon_admin/features/review/presentation/controllers/review_queue_controller.dart';
import 'package:german_lexicon_admin/features/review/presentation/screens/review_queue_screen.dart';

class MockLexiconRepository implements LexiconRepository {
  final List<MasterLexiconEntry> _entries = [];

  void seedEntries(List<MasterLexiconEntry> items) {
    _entries.addAll(items);
  }

  @override
  Future<({List<MasterLexiconEntry> entries, int totalCount})> getEntries(
    LexiconFilter filter,
  ) async {
    return (entries: List<MasterLexiconEntry>.from(_entries), totalCount: _entries.length);
  }

  @override
  Future<MasterLexiconEntry> getEntryById(String id) async {
    return _entries.firstWhere((e) => e.id == id);
  }

  @override
  Future<MasterLexiconEntry> createEntry(MasterLexiconEntry entry) async => entry;

  @override
  Future<MasterLexiconEntry> updateEntry(MasterLexiconEntry entry) async => entry;

  @override
  Future<void> deleteEntry(String id) async {}

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

  @override
  Future<BulkActionResult> bulkUpdateStatus({
    required List<String> entryIds,
    required String status,
  }) async {
    return BulkActionResult(
      totalRequested: entryIds.length,
      succeededIds: entryIds,
      failureErrors: {},
    );
  }

  @override
  Future<BulkActionResult> bulkUpdateCefr({
    required List<String> entryIds,
    required String cefrLevel,
  }) async {
    return BulkActionResult(
      totalRequested: entryIds.length,
      succeededIds: entryIds,
      failureErrors: {},
    );
  }
}

class MockReviewRepository implements ReviewRepository {
  List<MasterLexiconEntry> masterEntries = [];
  List<LexiconTranslation> translations = [];
  List<LexiconSense> senses = [];
  List<LexiconSynonym> synonyms = [];
  List<LexiconExample> examples = [];

  bool shouldThrowRls = false;
  bool shouldThrowNetwork = false;

  @override
  Future<ReviewQueueCounts> getCounts() async {
    if (shouldThrowNetwork) throw Exception('Network connection failure');
    if (shouldThrowRls) throw const RlsPermissionException('RLS read rejected');

    return ReviewQueueCounts(
      masterCount: masterEntries.where((e) => e.status == 'review').length,
      translationsCount: translations.where((t) => t.status == 'review').length,
      sensesCount: senses.where((s) {
        final parent = masterEntries.firstWhere(
          (e) => e.id == s.entryId,
          orElse: () => MasterLexiconEntry(
            id: '',
            lemma: '',
            normalizedLemma: '',
            partOfSpeech: '',
            status: 'verified',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        return parent.status == 'review';
      }).length,
      synonymsCount: synonyms.where((s) => s.status == 'review').length,
      examplesCount: examples.where((e) => e.status == 'review').length,
    );
  }

  @override
  Future<({List<ReviewQueueItem> items, int totalCount})> getQueueItems({
    required ReviewCategory category,
    String? searchQuery,
    String? cefrLevel,
    String? partOfSpeech,
    int page = 1,
    int pageSize = 15,
  }) async {
    if (shouldThrowNetwork) throw Exception('Network connection failure');
    if (shouldThrowRls) throw const RlsPermissionException('RLS read rejected');

    List<ReviewQueueItem> allItems = [];

    switch (category) {
      case ReviewCategory.masterWords:
        var filtered = masterEntries.where((e) => e.status == 'review');
        if (searchQuery != null && searchQuery.trim().isNotEmpty) {
          final q = searchQuery.trim().toLowerCase();
          filtered = filtered.where((e) => e.lemma.toLowerCase().contains(q));
        }
        if (cefrLevel != null && cefrLevel != 'all') {
          filtered = filtered.where((e) => e.cefrLevel == cefrLevel);
        }
        if (partOfSpeech != null && partOfSpeech != 'all') {
          filtered = filtered.where((e) => e.partOfSpeech == partOfSpeech);
        }
        allItems = filtered.map((e) => ReviewQueueItem.fromMasterEntry(e)).toList();
        break;

      case ReviewCategory.translations:
        var filtered = translations.where((t) => t.status == 'review');
        allItems = filtered.map((t) {
          final parent = masterEntries.firstWhere(
            (e) => e.id == t.entryId,
            orElse: () => MasterLexiconEntry(
              id: t.entryId,
              lemma: 'Parent',
              normalizedLemma: 'parent',
              partOfSpeech: 'noun',
              status: 'verified',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          return ReviewQueueItem.fromTranslation(
            translation: t,
            parentLemma: parent.lemma,
            partOfSpeech: parent.partOfSpeech,
            cefrLevel: parent.cefrLevel,
          );
        }).where((item) {
          if (searchQuery != null && searchQuery.trim().isNotEmpty) {
            final q = searchQuery.trim().toLowerCase();
            if (!item.parentLemma.toLowerCase().contains(q) &&
                !item.title.toLowerCase().contains(q)) {
              return false;
            }
          }
          if (cefrLevel != null && cefrLevel != 'all' && item.cefrLevel != cefrLevel) {
            return false;
          }
          if (partOfSpeech != null &&
              partOfSpeech != 'all' &&
              item.partOfSpeech != partOfSpeech) {
            return false;
          }
          return true;
        }).toList();
        break;

      case ReviewCategory.senses:
        var filtered = senses.where((s) {
          final parent = masterEntries.firstWhere(
            (e) => e.id == s.entryId,
            orElse: () => MasterLexiconEntry(
              id: '',
              lemma: '',
              normalizedLemma: '',
              partOfSpeech: '',
              status: 'verified',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          return parent.status == 'review';
        });
        allItems = filtered.map((s) {
          final parent = masterEntries.firstWhere((e) => e.id == s.entryId);
          return ReviewQueueItem.fromSense(
            sense: s,
            parentLemma: parent.lemma,
            partOfSpeech: parent.partOfSpeech,
            cefrLevel: parent.cefrLevel,
          );
        }).where((item) {
          if (searchQuery != null && searchQuery.trim().isNotEmpty) {
            final q = searchQuery.trim().toLowerCase();
            if (!item.parentLemma.toLowerCase().contains(q)) return false;
          }
          if (cefrLevel != null && cefrLevel != 'all' && item.cefrLevel != cefrLevel) {
            return false;
          }
          if (partOfSpeech != null &&
              partOfSpeech != 'all' &&
              item.partOfSpeech != partOfSpeech) {
            return false;
          }
          return true;
        }).toList();
        break;

      case ReviewCategory.synonyms:
        var filtered = synonyms.where((s) => s.status == 'review');
        allItems = filtered.map((s) {
          final parent = masterEntries.firstWhere(
            (e) => e.id == s.entryId,
            orElse: () => MasterLexiconEntry(
              id: s.entryId,
              lemma: 'Parent',
              normalizedLemma: 'parent',
              partOfSpeech: 'noun',
              status: 'verified',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          return ReviewQueueItem.fromSynonym(
            synonym: s,
            parentLemma: parent.lemma,
            partOfSpeech: parent.partOfSpeech,
            cefrLevel: parent.cefrLevel,
          );
        }).where((item) {
          if (searchQuery != null && searchQuery.trim().isNotEmpty) {
            final q = searchQuery.trim().toLowerCase();
            if (!item.parentLemma.toLowerCase().contains(q) &&
                !item.title.toLowerCase().contains(q)) {
              return false;
            }
          }
          if (cefrLevel != null && cefrLevel != 'all' && item.cefrLevel != cefrLevel) {
            return false;
          }
          if (partOfSpeech != null &&
              partOfSpeech != 'all' &&
              item.partOfSpeech != partOfSpeech) {
            return false;
          }
          return true;
        }).toList();
        break;

      case ReviewCategory.examples:
        var filtered = examples.where((ex) => ex.status == 'review');
        allItems = filtered.map((ex) {
          final parent = masterEntries.firstWhere(
            (e) => e.id == ex.entryId,
            orElse: () => MasterLexiconEntry(
              id: ex.entryId,
              lemma: 'Parent',
              normalizedLemma: 'parent',
              partOfSpeech: 'noun',
              status: 'verified',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          );
          return ReviewQueueItem.fromExample(
            example: ex,
            parentLemma: parent.lemma,
            partOfSpeech: parent.partOfSpeech,
          );
        }).where((item) {
          if (searchQuery != null && searchQuery.trim().isNotEmpty) {
            final q = searchQuery.trim().toLowerCase();
            if (!item.parentLemma.toLowerCase().contains(q) &&
                !item.title.toLowerCase().contains(q)) {
              return false;
            }
          }
          if (cefrLevel != null && cefrLevel != 'all' && item.cefrLevel != cefrLevel) {
            return false;
          }
          if (partOfSpeech != null &&
              partOfSpeech != 'all' &&
              item.partOfSpeech != partOfSpeech) {
            return false;
          }
          return true;
        }).toList();
        break;
    }

    final fromIndex = (page - 1) * pageSize;
    final paged = allItems.skip(fromIndex).take(pageSize).toList();
    return (items: paged, totalCount: allItems.length);
  }

  @override
  Future<void> verifyItem(ReviewQueueItem item) async {
    if (shouldThrowNetwork) throw Exception('Network connection failure');
    if (shouldThrowRls) throw const RlsPermissionException('RLS action rejected');

    switch (item.category) {
      case ReviewCategory.masterWords:
      case ReviewCategory.senses:
        final idx = masterEntries.indexWhere((e) => e.id == item.entryId);
        if (idx != -1) {
          masterEntries[idx] = masterEntries[idx].copyWith(status: 'verified');
        }
        break;
      case ReviewCategory.translations:
        final idx = translations.indexWhere((t) => t.id == item.id);
        if (idx != -1) {
          translations[idx] = translations[idx].copyWith(status: 'verified');
        }
        break;
      case ReviewCategory.synonyms:
        final idx = synonyms.indexWhere((s) => s.id == item.id);
        if (idx != -1) {
          synonyms[idx] = synonyms[idx].copyWith(status: 'verified');
        }
        break;
      case ReviewCategory.examples:
        final idx = examples.indexWhere((e) => e.id == item.id);
        if (idx != -1) {
          examples[idx] = examples[idx].copyWith(status: 'verified');
        }
        break;
    }
  }

  @override
  Future<void> rejectItem(ReviewQueueItem item) async {
    if (shouldThrowNetwork) throw Exception('Network connection failure');
    if (shouldThrowRls) throw const RlsPermissionException('RLS action rejected');

    switch (item.category) {
      case ReviewCategory.masterWords:
      case ReviewCategory.senses:
        final idx = masterEntries.indexWhere((e) => e.id == item.entryId);
        if (idx != -1) {
          masterEntries[idx] = masterEntries[idx].copyWith(status: 'rejected');
        }
        break;
      case ReviewCategory.translations:
        final idx = translations.indexWhere((t) => t.id == item.id);
        if (idx != -1) {
          translations[idx] = translations[idx].copyWith(status: 'rejected');
        }
        break;
      case ReviewCategory.synonyms:
        final idx = synonyms.indexWhere((s) => s.id == item.id);
        if (idx != -1) {
          synonyms[idx] = synonyms[idx].copyWith(status: 'rejected');
        }
        break;
      case ReviewCategory.examples:
        final idx = examples.indexWhere((e) => e.id == item.id);
        if (idx != -1) {
          examples[idx] = examples[idx].copyWith(status: 'rejected');
        }
        break;
    }
  }
}

void main() {
  group('Review Queue Tests (Items A through T)', () {
    late MockReviewRepository reviewRepo;
    late MockLexiconRepository lexiconRepo;
    late ReviewQueueController controller;
    late LexiconController lexiconController;

    final testNow = DateTime.now();

    final sampleMasterReview1 = MasterLexiconEntry(
      id: 'm1',
      lemma: 'Haus',
      normalizedLemma: 'haus',
      partOfSpeech: 'noun',
      gender: 'das',
      cefrLevel: 'A1',
      status: 'review',
      createdAt: testNow,
      updatedAt: testNow,
    );

    final sampleMasterReview2 = MasterLexiconEntry(
      id: 'm2',
      lemma: 'Laufen',
      normalizedLemma: 'laufen',
      partOfSpeech: 'verb',
      cefrLevel: 'B1',
      status: 'review',
      createdAt: testNow,
      updatedAt: testNow,
    );

    final sampleMasterVerified = MasterLexiconEntry(
      id: 'm3',
      lemma: 'Buch',
      normalizedLemma: 'buch',
      partOfSpeech: 'noun',
      gender: 'das',
      cefrLevel: 'A2',
      status: 'verified',
      createdAt: testNow,
      updatedAt: testNow,
    );

    final sampleTransEn = LexiconTranslation(
      id: 't1',
      entryId: 'm1',
      targetLang: 'en',
      translation: 'house',
      status: 'review',
      createdAt: testNow,
      updatedAt: testNow,
    );

    final sampleTransUr = LexiconTranslation(
      id: 't2',
      entryId: 'm1',
      targetLang: 'ur',
      translation: 'گھر',
      status: 'review',
      createdAt: testNow,
      updatedAt: testNow,
    );

    final sampleTransFa = LexiconTranslation(
      id: 't3',
      entryId: 'm1',
      targetLang: 'fa',
      translation: 'خانه',
      status: 'review',
      createdAt: testNow,
      updatedAt: testNow,
    );

    final sampleTransAr = LexiconTranslation(
      id: 't4',
      entryId: 'm1',
      targetLang: 'ar',
      translation: 'منزل',
      status: 'review',
      createdAt: testNow,
      updatedAt: testNow,
    );

    final sampleSense = LexiconSense(
      id: 's1',
      entryId: 'm1',
      senseOrder: 1,
      definitionDe: 'Wohngebäude für Menschen',
      definitionEn: 'Residential building for humans',
      contextDomain: 'architecture',
      createdAt: testNow,
      updatedAt: testNow,
    );

    final sampleSynonym = LexiconSynonym(
      id: 'syn1',
      entryId: 'm1',
      synonymWord: 'Gebäude',
      nuanceNote: 'General building',
      status: 'review',
      createdAt: testNow,
      updatedAt: testNow,
    );

    final sampleExample = LexiconExample(
      id: 'ex1',
      entryId: 'm1',
      sentenceDe: 'Das Haus steht am Waldrand.',
      sentenceEn: 'The house stands at the edge of the forest.',
      cefrLevel: 'A1',
      status: 'review',
      createdAt: testNow,
      updatedAt: testNow,
    );

    setUp(() async {
      reviewRepo = MockReviewRepository();
      lexiconRepo = MockLexiconRepository();

      reviewRepo.masterEntries = [sampleMasterReview1, sampleMasterReview2, sampleMasterVerified];
      reviewRepo.translations = [sampleTransEn, sampleTransUr, sampleTransFa, sampleTransAr];
      reviewRepo.senses = [sampleSense];
      reviewRepo.synonyms = [sampleSynonym];
      reviewRepo.examples = [sampleExample];

      lexiconRepo.seedEntries(reviewRepo.masterEntries);

      controller = ReviewQueueController(repository: reviewRepo);
      lexiconController = LexiconController(repository: lexiconRepo);
      await controller.refresh();
    });

    test('A. Master Words review items appear', () async {
      await controller.refresh();

      expect(controller.activeCategory, ReviewCategory.masterWords);
      expect(controller.items.length, 2);
      expect(controller.items.map((i) => i.title), containsAll(['Haus', 'Laufen']));
      expect(controller.items.every((i) => i.status == 'review'), isTrue);
      expect(controller.counts.masterCount, 2);
    });

    test('B. Translations review items appear', () async {
      await controller.selectCategory(ReviewCategory.translations);

      expect(controller.activeCategory, ReviewCategory.translations);
      expect(controller.items.length, 4);
      expect(controller.items.first.parentLemma, 'Haus');
      expect(controller.counts.translationsCount, 4);
    });

    test('C. Translation language isolation works (en vs ur vs fa vs ar)', () async {
      await controller.selectCategory(ReviewCategory.translations);

      final titles = controller.items.map((i) => i.title).toList();
      final subtitles = controller.items.map((i) => i.subtitle).toList();

      expect(titles, containsAll(['house', 'گھر', 'خانه', 'منزل']));
      expect(subtitles, containsAll([
        'English [EN]',
        'Urdu [UR]',
        'Persian (Farsi) [FA]',
        'Arabic [AR]',
      ]));

      // Verify each item has distinct targetLang
      final langs = controller.items.map((i) => i.rawTranslation?.targetLang).toList();
      expect(langs, containsAll(['en', 'ur', 'fa', 'ar']));
    });

    test('D. Sense review items appear', () async {
      await controller.selectCategory(ReviewCategory.senses);

      expect(controller.activeCategory, ReviewCategory.senses);
      expect(controller.items.length, 1);
      expect(controller.items.first.title, contains('Sense #1: Wohngebäude für Menschen'));
      expect(controller.items.first.parentLemma, 'Haus');
      expect(controller.counts.sensesCount, 1);
    });

    test('E. Synonym review items appear', () async {
      await controller.selectCategory(ReviewCategory.synonyms);

      expect(controller.activeCategory, ReviewCategory.synonyms);
      expect(controller.items.length, 1);
      expect(controller.items.first.title, 'Gebäude');
      expect(controller.items.first.parentLemma, 'Haus');
      expect(controller.counts.synonymsCount, 1);
    });

    test('F. Example review items appear', () async {
      await controller.selectCategory(ReviewCategory.examples);

      expect(controller.activeCategory, ReviewCategory.examples);
      expect(controller.items.length, 1);
      expect(controller.items.first.title, 'Das Haus steht am Waldrand.');
      expect(controller.items.first.parentLemma, 'Haus');
      expect(controller.counts.examplesCount, 1);
    });

    test('G. Search works for German word in queue', () async {
      await controller.refresh();
      expect(controller.items.length, 2);

      await controller.setSearchQuery('Laufen');
      expect(controller.items.length, 1);
      expect(controller.items.first.title, 'Laufen');

      await controller.setSearchQuery('Haus');
      expect(controller.items.length, 1);
      expect(controller.items.first.title, 'Haus');

      await controller.setSearchQuery(null);
      expect(controller.items.length, 2);
    });

    test('H. CEFR filter works', () async {
      await controller.refresh();

      await controller.setCefrFilter('B1');
      expect(controller.items.length, 1);
      expect(controller.items.first.title, 'Laufen');

      await controller.setCefrFilter('A1');
      expect(controller.items.length, 1);
      expect(controller.items.first.title, 'Haus');

      await controller.setCefrFilter('all');
      expect(controller.items.length, 2);
    });

    test('I. POS filter works', () async {
      await controller.refresh();

      await controller.setPosFilter('verb');
      expect(controller.items.length, 1);
      expect(controller.items.first.title, 'Laufen');

      await controller.setPosFilter('noun');
      expect(controller.items.length, 1);
      expect(controller.items.first.title, 'Haus');

      await controller.setPosFilter('all');
      expect(controller.items.length, 2);
    });

    test('J. Review-type filter works (switching categories resets page and updates items)', () async {
      await controller.refresh();
      expect(controller.activeCategory, ReviewCategory.masterWords);

      await controller.selectCategory(ReviewCategory.synonyms);
      expect(controller.activeCategory, ReviewCategory.synonyms);
      expect(controller.page, 1);
      expect(controller.items.first.category, ReviewCategory.synonyms);

      await controller.selectCategory(ReviewCategory.examples);
      expect(controller.activeCategory, ReviewCategory.examples);
      expect(controller.page, 1);
      expect(controller.items.first.category, ReviewCategory.examples);
    });

    test('K. Reviewer can verify item', () async {
      await controller.refresh();
      final itemToVerify = controller.items.firstWhere((i) => i.id == 'm1');

      final success = await controller.verifyItem(itemToVerify);
      expect(success, isTrue);

      // Status in repository updated
      final updated = reviewRepo.masterEntries.firstWhere((e) => e.id == 'm1');
      expect(updated.status, 'verified');
    });

    test('L. Reviewer can reject item', () async {
      await controller.refresh();
      final itemToReject = controller.items.firstWhere((i) => i.id == 'm2');

      final success = await controller.rejectItem(itemToReject);
      expect(success, isTrue);

      // Status in repository updated
      final updated = reviewRepo.masterEntries.firstWhere((e) => e.id == 'm2');
      expect(updated.status, 'rejected');
    });

    testWidgets('M. Editor cannot verify (Verify button is hidden)', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: ReviewQueueScreen(
          controller: controller,
          lexiconRepository: lexiconRepo,
          userRole: AdminRole.editor,
          lexiconController: lexiconController,
        ),
      ));
      await tester.pumpAndSettle();

      // Editor should NOT see Verify button (Icons.check_circle_outline)
      expect(find.byIcon(Icons.check_circle_outline), findsNothing);
      // Editor CAN see Inspect button (Icons.visibility_outlined)
      expect(find.byIcon(Icons.visibility_outlined), findsWidgets);
    });

    testWidgets('N. Editor cannot access privileged review actions (Reject button is hidden)', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: ReviewQueueScreen(
          controller: controller,
          lexiconRepository: lexiconRepo,
          userRole: AdminRole.editor,
          lexiconController: lexiconController,
        ),
      ));
      await tester.pumpAndSettle();

      // Editor should NOT see Reject button (Icons.cancel_outlined)
      expect(find.byIcon(Icons.cancel_outlined), findsNothing);
    });

    testWidgets('O. Superadmin review actions work (Verify and Reject buttons visible)', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: ReviewQueueScreen(
          controller: controller,
          lexiconRepository: lexiconRepo,
          userRole: AdminRole.superadmin,
          lexiconController: lexiconController,
        ),
      ));
      await tester.pumpAndSettle();

      // Superadmin sees both Verify and Reject buttons
      expect(find.byIcon(Icons.check_circle_outline), findsWidgets);
      expect(find.byIcon(Icons.cancel_outlined), findsWidgets);
      expect(find.byIcon(Icons.visibility_outlined), findsWidgets);
    });

    testWidgets('Reviewer sees Verify and Reject buttons in UI', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: ReviewQueueScreen(
          controller: controller,
          lexiconRepository: lexiconRepo,
          userRole: AdminRole.reviewer,
          lexiconController: lexiconController,
        ),
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.check_circle_outline), findsWidgets);
      expect(find.byIcon(Icons.cancel_outlined), findsWidgets);
      expect(find.byIcon(Icons.visibility_outlined), findsWidgets);
    });

    test('P. Verified items disappear from pending queue', () async {
      await controller.refresh();
      expect(controller.items.length, 2);
      expect(controller.totalCount, 2);

      final itemToVerify = controller.items.first;
      await controller.verifyItem(itemToVerify);

      expect(controller.items.any((i) => i.id == itemToVerify.id), isFalse);
      expect(controller.items.length, 1);
      expect(controller.totalCount, 1);
      expect(controller.counts.masterCount, 1);
    });

    test('Q. Rejected items disappear from pending queue', () async {
      await controller.refresh();
      expect(controller.items.length, 2);
      expect(controller.totalCount, 2);

      final itemToReject = controller.items.first;
      await controller.rejectItem(itemToReject);

      expect(controller.items.any((i) => i.id == itemToReject.id), isFalse);
      expect(controller.items.length, 1);
      expect(controller.totalCount, 1);
      expect(controller.counts.masterCount, 1);
    });

    test('R. Empty queue works cleanly', () async {
      reviewRepo.masterEntries = [sampleMasterVerified]; // 0 in review
      await controller.refresh();

      expect(controller.items, isEmpty);
      expect(controller.totalCount, 0);
      expect(controller.counts.masterCount, 0);
      expect(controller.errorMessage, isNull);
    });

    test('S. RLS rejection is handled gracefully', () async {
      await controller.refresh();
      reviewRepo.shouldThrowRls = true;

      final item = controller.items.first;
      final success = await controller.verifyItem(item);

      expect(success, isFalse);
      expect(controller.errorMessage, contains('RLS'));
      expect(controller.isActionLoading, isFalse);
    });

    test('T. Network error is handled gracefully', () async {
      reviewRepo.shouldThrowNetwork = true;
      await controller.loadQueueItems();

      expect(controller.items, isEmpty);
      expect(controller.errorMessage, contains('Network connection failure'));
      expect(controller.isLoading, isFalse);
    });
  });
}
