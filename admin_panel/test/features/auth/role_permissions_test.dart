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
import 'package:german_lexicon_admin/features/lexicon/presentation/screens/lexicon_list_screen.dart';
import 'package:german_lexicon_admin/features/lexicon/presentation/screens/word_detail_screen.dart';
import 'package:german_lexicon_admin/features/review/data/review_repository.dart';
import 'package:german_lexicon_admin/features/review/domain/models/review_queue_counts.dart';
import 'package:german_lexicon_admin/features/review/domain/models/review_queue_item.dart';
import 'package:german_lexicon_admin/features/review/presentation/controllers/review_queue_controller.dart';
import 'package:german_lexicon_admin/features/review/presentation/screens/review_queue_screen.dart';

class MockLexiconRepository implements LexiconRepository {
  final List<MasterLexiconEntry> entries = [];
  final Map<String, List<LexiconTranslation>> translations = {};
  final Map<String, List<LexiconSense>> senses = {};
  final Map<String, List<LexiconSynonym>> synonyms = {};
  final Map<String, List<LexiconExample>> examples = {};

  @override
  Future<({List<MasterLexiconEntry> entries, int totalCount})> getEntries(LexiconFilter filter) async {
    return (entries: entries, totalCount: entries.length);
  }

  @override
  Future<MasterLexiconEntry> getEntryById(String id) async {
    return entries.firstWhere((e) => e.id == id);
  }

  @override
  Future<MasterLexiconEntry> createEntry(MasterLexiconEntry entry) async {
    entries.add(entry);
    return entry;
  }

  @override
  Future<MasterLexiconEntry> updateEntry(MasterLexiconEntry entry) async {
    final idx = entries.indexWhere((e) => e.id == entry.id);
    if (idx != -1) entries[idx] = entry;
    return entry;
  }

  @override
  Future<void> deleteEntry(String id) async {
    entries.removeWhere((e) => e.id == id);
  }

  @override
  Future<List<LexiconTranslation>> getTranslations(String entryId) async =>
      translations[entryId] ?? [];

  @override
  Future<LexiconTranslation> createTranslation(LexiconTranslation translation) async {
    translations.putIfAbsent(translation.entryId, () => []).add(translation);
    return translation;
  }

  @override
  Future<LexiconTranslation> updateTranslation(LexiconTranslation translation) async {
    final list = translations[translation.entryId] ?? [];
    final idx = list.indexWhere((t) => t.id == translation.id);
    if (idx != -1) list[idx] = translation;
    return translation;
  }

  @override
  Future<void> deleteTranslation(String id) async {
    for (final list in translations.values) {
      list.removeWhere((t) => t.id == id);
    }
  }

  @override
  Future<List<LexiconSense>> getSenses(String entryId) async => senses[entryId] ?? [];

  @override
  Future<LexiconSense> createSense(LexiconSense sense) async {
    senses.putIfAbsent(sense.entryId, () => []).add(sense);
    return sense;
  }

  @override
  Future<LexiconSense> updateSense(LexiconSense sense) async {
    final list = senses[sense.entryId] ?? [];
    final idx = list.indexWhere((s) => s.id == sense.id);
    if (idx != -1) list[idx] = sense;
    return sense;
  }

  @override
  Future<void> deleteSense(String id) async {
    for (final list in senses.values) {
      list.removeWhere((s) => s.id == id);
    }
  }

  @override
  Future<List<LexiconSynonym>> getSynonyms(String entryId) async => synonyms[entryId] ?? [];

  @override
  Future<LexiconSynonym> createSynonym(LexiconSynonym synonym) async {
    synonyms.putIfAbsent(synonym.entryId, () => []).add(synonym);
    return synonym;
  }

  @override
  Future<LexiconSynonym> updateSynonym(LexiconSynonym synonym) async {
    final list = synonyms[synonym.entryId] ?? [];
    final idx = list.indexWhere((s) => s.id == synonym.id);
    if (idx != -1) list[idx] = synonym;
    return synonym;
  }

  @override
  Future<void> deleteSynonym(String id) async {
    for (final list in synonyms.values) {
      list.removeWhere((s) => s.id == id);
    }
  }

  @override
  Future<List<LexiconExample>> getExamples(String entryId) async => examples[entryId] ?? [];

  @override
  Future<LexiconExample> createExample(LexiconExample example) async {
    examples.putIfAbsent(example.entryId, () => []).add(example);
    return example;
  }

  @override
  Future<LexiconExample> updateExample(LexiconExample example) async {
    final list = examples[example.entryId] ?? [];
    final idx = list.indexWhere((e) => e.id == example.id);
    if (idx != -1) list[idx] = example;
    return example;
  }

  @override
  Future<void> deleteExample(String id) async {
    for (final list in examples.values) {
      list.removeWhere((e) => e.id == id);
    }
  }

  @override
  Future<BulkActionResult> bulkUpdateStatus({
    required List<String> entryIds,
    required String status,
  }) async {
    final succeeded = <String>[];
    for (final id in entryIds) {
      final idx = entries.indexWhere((e) => e.id == id);
      if (idx != -1) {
        entries[idx] = entries[idx].copyWith(status: status);
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
      final idx = entries.indexWhere((e) => e.id == id);
      if (idx != -1) {
        entries[idx] = entries[idx].copyWith(cefrLevel: cefrLevel);
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

class MockReviewRepository implements ReviewRepository {
  List<ReviewQueueItem> items = [];

  @override
  Future<ReviewQueueCounts> getCounts() async {
    return ReviewQueueCounts(masterCount: items.length);
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
    return (items: items, totalCount: items.length);
  }

  @override
  Future<void> verifyItem(ReviewQueueItem item) async {
    items.removeWhere((i) => i.id == item.id);
  }

  @override
  Future<void> rejectItem(ReviewQueueItem item) async {
    items.removeWhere((i) => i.id == item.id);
  }
}

void main() {
  group('Phase 12B-5: Domain Model Role Permission Capabilities', () {
    test('1. Superadmin has full CRUD, verify, and delete rights across all statuses', () {
      final draft = MasterLexiconEntry(
        id: '1',
        lemma: 'Wort',
        normalizedLemma: 'wort',
        partOfSpeech: 'noun',
        status: 'draft',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final verified = draft.copyWith(status: 'verified');

      expect(draft.canEdit(AdminRole.superadmin), isTrue);
      expect(draft.canVerify(AdminRole.superadmin), isTrue);
      expect(draft.canDelete(AdminRole.superadmin), isTrue);

      expect(verified.canEdit(AdminRole.superadmin), isTrue);
      expect(verified.canVerify(AdminRole.superadmin), isTrue);
      expect(verified.canDelete(AdminRole.superadmin), isTrue);
    });

    test('2. Reviewer can edit & verify both draft and verified, but CANNOT delete', () {
      final draft = MasterLexiconEntry(
        id: '1',
        lemma: 'Wort',
        normalizedLemma: 'wort',
        partOfSpeech: 'noun',
        status: 'draft',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final verified = draft.copyWith(status: 'verified');

      expect(draft.canEdit(AdminRole.reviewer), isTrue);
      expect(draft.canVerify(AdminRole.reviewer), isTrue);
      expect(draft.canDelete(AdminRole.reviewer), isFalse);

      expect(verified.canEdit(AdminRole.reviewer), isTrue);
      expect(verified.canVerify(AdminRole.reviewer), isTrue);
      expect(verified.canDelete(AdminRole.reviewer), isFalse);
    });

    test('3. Editor can edit draft/review, but CANNOT edit verified, verify, or delete', () {
      final draft = MasterLexiconEntry(
        id: '1',
        lemma: 'Wort',
        normalizedLemma: 'wort',
        partOfSpeech: 'noun',
        status: 'draft',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final review = draft.copyWith(status: 'review');
      final verified = draft.copyWith(status: 'verified');

      expect(draft.canEdit(AdminRole.editor), isTrue);
      expect(draft.canVerify(AdminRole.editor), isFalse);
      expect(draft.canDelete(AdminRole.editor), isFalse);

      expect(review.canEdit(AdminRole.editor), isTrue);
      expect(review.canVerify(AdminRole.editor), isFalse);
      expect(review.canDelete(AdminRole.editor), isFalse);

      // Verified is strictly read-only for Editor
      expect(verified.canEdit(AdminRole.editor), isFalse);
      expect(verified.canVerify(AdminRole.editor), isFalse);
      expect(verified.canDelete(AdminRole.editor), isFalse);
    });

    test('4. Child relations: Translation permission rules per role', () {
      final transDraft = LexiconTranslation(
        id: 't1',
        entryId: '1',
        targetLang: 'en',
        translation: 'word',
        status: 'draft',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final transVerified = transDraft.copyWith(status: 'verified');

      // Superadmin
      expect(transDraft.canEdit(AdminRole.superadmin), isTrue);
      expect(transDraft.canVerify(AdminRole.superadmin), isTrue);
      expect(transDraft.canDelete(AdminRole.superadmin), isTrue);

      // Reviewer
      expect(transDraft.canEdit(AdminRole.reviewer), isTrue);
      expect(transDraft.canVerify(AdminRole.reviewer), isTrue);
      expect(transDraft.canDelete(AdminRole.reviewer), isFalse);

      // Editor
      expect(transDraft.canEdit(AdminRole.editor), isTrue);
      expect(transDraft.canVerify(AdminRole.editor), isFalse);
      expect(transDraft.canDelete(AdminRole.editor), isFalse);

      expect(transVerified.canEdit(AdminRole.editor), isFalse);
      expect(transVerified.canVerify(AdminRole.editor), isFalse);
      expect(transVerified.canDelete(AdminRole.editor), isFalse);
    });

    test('5. Child relations: Sense cannot be edited by Editor if parent is verified', () {
      final sense = LexiconSense(
        id: 's1',
        entryId: '1',
        definitionDe: 'Bedeutung',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Parent is NOT verified
      expect(sense.canEdit(AdminRole.editor, parentIsVerified: false), isTrue);
      // Parent IS verified -> Editor blocked
      expect(sense.canEdit(AdminRole.editor, parentIsVerified: true), isFalse);
      // Reviewer and Superadmin can edit even if parent is verified
      expect(sense.canEdit(AdminRole.reviewer, parentIsVerified: true), isTrue);
      expect(sense.canEdit(AdminRole.superadmin, parentIsVerified: true), isTrue);
      // Only Superadmin can delete
      expect(sense.canDelete(AdminRole.superadmin), isTrue);
      expect(sense.canDelete(AdminRole.reviewer), isFalse);
      expect(sense.canDelete(AdminRole.editor), isFalse);
    });
  });

  group('Phase 12B-5: UI Hardening Widget Tests across Roles', () {
    late MockLexiconRepository lexiconRepo;
    late MockReviewRepository reviewRepo;
    late LexiconController lexiconController;
    late ReviewQueueController reviewController;

    setUp(() {
      lexiconRepo = MockLexiconRepository();
      reviewRepo = MockReviewRepository();
      lexiconController = LexiconController(repository: lexiconRepo);
      reviewController = ReviewQueueController(repository: reviewRepo);
    });

    testWidgets('1. Lexicon List: Editor sees Edit for draft but NOT for verified word', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      lexiconRepo.entries.addAll([
        MasterLexiconEntry(
          id: '1',
          lemma: 'Entwurf',
          normalizedLemma: 'entwurf',
          partOfSpeech: 'noun',
          status: 'draft',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MasterLexiconEntry(
          id: '2',
          lemma: 'Geprüft',
          normalizedLemma: 'geprüft',
          partOfSpeech: 'noun',
          status: 'verified',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: LexiconListScreen(
            controller: lexiconController,
            repository: lexiconRepo,
            userRole: AdminRole.editor,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Only 1 edit icon button should exist (for the draft entry 'Entwurf')
      expect(find.byIcon(Icons.edit_outlined), findsOneWidget);
    });

    testWidgets('2. Lexicon List: Reviewer and Superadmin see Edit for both draft and verified', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      lexiconRepo.entries.addAll([
        MasterLexiconEntry(
          id: '1',
          lemma: 'Entwurf',
          normalizedLemma: 'entwurf',
          partOfSpeech: 'noun',
          status: 'draft',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        MasterLexiconEntry(
          id: '2',
          lemma: 'Geprüft',
          normalizedLemma: 'geprüft',
          partOfSpeech: 'noun',
          status: 'verified',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ]);

      await tester.pumpWidget(
        MaterialApp(
          home: LexiconListScreen(
            controller: lexiconController,
            repository: lexiconRepo,
            userRole: AdminRole.reviewer,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Reviewer sees edit for BOTH entries
      expect(find.byIcon(Icons.edit_outlined), findsNWidgets(2));
    });

    testWidgets('3. Word Detail: Delete button is visible for Superadmin but hidden for Reviewer & Editor', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final entry = MasterLexiconEntry(
        id: '1',
        lemma: 'TestWort',
        normalizedLemma: 'testwort',
        partOfSpeech: 'noun',
        status: 'draft',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      lexiconRepo.entries.add(entry);

      // Superadmin check
      await tester.pumpWidget(
        MaterialApp(
          home: WordDetailScreen(
            initialEntry: entry,
            repository: lexiconRepo,
            userRole: AdminRole.superadmin,
            listController: lexiconController,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.delete_outline), findsOneWidget); // Superadmin has Delete

      // Reviewer check
      await tester.pumpWidget(
        MaterialApp(
          home: WordDetailScreen(
            initialEntry: entry,
            repository: lexiconRepo,
            userRole: AdminRole.reviewer,
            listController: lexiconController,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.delete_outline), findsNothing); // Reviewer CANNOT delete

      // Editor check
      await tester.pumpWidget(
        MaterialApp(
          home: WordDetailScreen(
            initialEntry: entry,
            repository: lexiconRepo,
            userRole: AdminRole.editor,
            listController: lexiconController,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.delete_outline), findsNothing); // Editor CANNOT delete
    });

    testWidgets('4. Review Queue: Verify & Reject buttons are visible for Reviewer but hidden for Editor', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      reviewRepo.items = [
        ReviewQueueItem(
          id: 'item-1',
          entryId: 'word-1',
          parentLemma: 'ReviewWort',
          title: 'ReviewWort',
          subtitle: 'noun • B1',
          status: 'review',
          category: ReviewCategory.masterWords,
          updatedAt: DateTime.now(),
        ),
      ];

      // Editor view
      await tester.pumpWidget(
        MaterialApp(
          home: ReviewQueueScreen(
            controller: reviewController,
            lexiconRepository: lexiconRepo,
            userRole: AdminRole.editor,
            lexiconController: lexiconController,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle_outline), findsNothing);
      expect(find.byIcon(Icons.cancel_outlined), findsNothing);

      // Reviewer view
      await tester.pumpWidget(
        MaterialApp(
          home: ReviewQueueScreen(
            controller: reviewController,
            lexiconRepository: lexiconRepo,
            userRole: AdminRole.reviewer,
            lexiconController: lexiconController,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);
      expect(find.byIcon(Icons.cancel_outlined), findsOneWidget);
    });
  });
}
