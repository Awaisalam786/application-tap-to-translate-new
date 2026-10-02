import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:german_lexicon_admin/features/auth/domain/admin_user_model.dart';
import 'package:german_lexicon_admin/features/csv_export/data/csv_export_repository.dart';
import 'package:german_lexicon_admin/features/csv_export/domain/models/csv_export_entry.dart';
import 'package:german_lexicon_admin/features/csv_export/domain/services/csv_serializer.dart';
import 'package:german_lexicon_admin/features/csv_export/presentation/controllers/csv_export_controller.dart';
import 'package:german_lexicon_admin/features/csv_export/presentation/screens/csv_export_screen.dart';
import 'package:german_lexicon_admin/features/csv_import/domain/services/csv_parser.dart';
import 'package:german_lexicon_admin/features/lexicon/data/lexicon_repository.dart';
import 'package:german_lexicon_admin/features/lexicon/domain/models/lexicon_example.dart';
import 'package:german_lexicon_admin/features/lexicon/domain/models/lexicon_filter.dart';
import 'package:german_lexicon_admin/features/lexicon/domain/models/lexicon_sense.dart';
import 'package:german_lexicon_admin/features/lexicon/domain/models/lexicon_synonym.dart';
import 'package:german_lexicon_admin/features/lexicon/domain/models/lexicon_translation.dart';
import 'package:german_lexicon_admin/features/lexicon/domain/models/master_lexicon_entry.dart';

class MockCsvExportRepository implements CsvExportRepository {
  List<CsvExportEntry> entries = [];
  bool shouldThrowRls = false;
  bool shouldThrowNetwork = false;

  @override
  Future<int> countMatchingEntries(LexiconFilter? filter) async {
    if (shouldThrowRls) {
      throw const RlsPermissionException('RLS permission denied');
    }
    if (shouldThrowNetwork) {
      throw Exception('Network error');
    }
    return _applyFilter(filter).length;
  }

  @override
  Future<List<CsvExportEntry>> fetchExportEntries({
    LexiconFilter? filter,
    int? maxRows,
    void Function(int fetched, int total)? onProgress,
  }) async {
    if (shouldThrowRls) {
      throw const RlsPermissionException('RLS permission denied');
    }
    if (shouldThrowNetwork) {
      throw Exception('Network error');
    }

    final filtered = _applyFilter(filter);
    final count = maxRows != null && maxRows < filtered.length ? maxRows : filtered.length;
    final result = filtered.take(count).toList();
    onProgress?.call(result.length, result.length);
    return result;
  }

  List<CsvExportEntry> _applyFilter(LexiconFilter? filter) {
    if (filter == null) return entries;
    return entries.where((e) {
      if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
        if (!e.master.lemma.toLowerCase().contains(filter.searchQuery!.toLowerCase())) {
          return false;
        }
      }
      if (filter.cefrLevel != null && filter.cefrLevel != 'all') {
        if (e.master.cefrLevel != filter.cefrLevel) return false;
      }
      if (filter.partOfSpeech != null && filter.partOfSpeech != 'all') {
        if (e.master.partOfSpeech != filter.partOfSpeech) return false;
      }
      if (filter.status != null && filter.status != 'all') {
        if (e.master.status != filter.status) return false;
      }
      return true;
    }).toList();
  }
}

MasterLexiconEntry createTestMaster({
  String id = 'test-id-1',
  String lemma = 'Haus',
  String partOfSpeech = 'noun',
  String? gender = 'das',
  String? pluralForm = 'Häuser',
  String cefrLevel = 'A1',
  String status = 'verified',
  String? provenance = 'Goethe A1',
}) {
  return MasterLexiconEntry(
    id: id,
    lemma: lemma,
    normalizedLemma: lemma.toLowerCase(),
    partOfSpeech: partOfSpeech,
    gender: gender,
    pluralForm: pluralForm,
    cefrLevel: cefrLevel,
    status: status,
    provenance: provenance,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );
}

void main() {
  group('Phase 12B-4: CsvSerializer Unit Tests', () {
    test('1. Prefixes CSV with UTF-8 BOM \\uFEFF for Excel compatibility', () {
      final entry = CsvExportEntry(master: createTestMaster());
      final csv = CsvSerializer.serialize([entry]);

      expect(csv.startsWith('\uFEFF'), isTrue);
    });

    test('2. Header row contains all required fields', () {
      final csv = CsvSerializer.serialize([]);
      final lines = csv.replaceFirst('\uFEFF', '').trim().split('\n');

      expect(lines.isNotEmpty, isTrue);
      final headers = lines.first.split(',');
      expect(headers, contains('lemma'));
      expect(headers, contains('article'));
      expect(headers, contains('pos'));
      expect(headers, contains('plural'));
      expect(headers, contains('cefr'));
      expect(headers, contains('topic'));
      expect(headers, contains('english'));
      expect(headers, contains('urdu'));
      expect(headers, contains('farsi'));
      expect(headers, contains('arabic'));
      expect(headers, contains('senses'));
      expect(headers, contains('synonyms'));
      expect(headers, contains('example_german'));
      expect(headers, contains('example_english'));
      expect(headers, contains('status'));
      expect(headers, contains('source'));
    });

    test('3. RFC 4180 Escaping: Commas, semicolons, quotes, line breaks', () {
      expect(CsvSerializer.escapeField('simple'), 'simple');
      expect(CsvSerializer.escapeField('hello, world'), '"hello, world"');
      expect(CsvSerializer.escapeField('hello; world'), '"hello; world"');
      expect(CsvSerializer.escapeField('say "hello" now'), '"say ""hello"" now"');
      expect(CsvSerializer.escapeField('line1\nline2'), '"line1\nline2"');
      expect(CsvSerializer.escapeField('line1\r\nline2'), '"line1\r\nline2"');
    });

    test('4. Unicode & RTL preservation: Urdu, Farsi, and Arabic without corruption', () {
      final entry = CsvExportEntry(
        master: createTestMaster(lemma: 'Buch', gender: 'das', cefrLevel: 'A1'),
        translations: [
          LexiconTranslation(
            id: 't-en',
            entryId: 'test-id-1',
            targetLang: 'en',
            translation: 'book',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          LexiconTranslation(
            id: 't-ur',
            entryId: 'test-id-1',
            targetLang: 'ur',
            translation: 'کتاب',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          LexiconTranslation(
            id: 't-fa',
            entryId: 'test-id-1',
            targetLang: 'fa',
            translation: 'کتاب',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          LexiconTranslation(
            id: 't-ar',
            entryId: 'test-id-1',
            targetLang: 'ar',
            translation: 'كتاب',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
      );

      final csv = CsvSerializer.serialize([entry]);

      // Check RTL script preservation
      expect(csv.contains('کتاب'), isTrue); // Urdu / Farsi
      expect(csv.contains('كتاب'), isTrue); // Arabic kaf

      // Round-trip parse with CsvParser
      final parsed = CsvParser.parse(csv);
      expect(parsed.length, 1);
      expect(parsed.first.mappedFields['lemma'], 'Buch');
      expect(parsed.first.mappedFields['translation_en'], 'book');
      expect(parsed.first.mappedFields['translation_ur'], 'کتاب');
      expect(parsed.first.mappedFields['translation_fa'], 'کتاب');
      expect(parsed.first.mappedFields['translation_ar'], 'كتاب');
    });

    test('5. Multi-value collation: Multiple translations, senses, synonyms, examples', () {
      final entry = CsvExportEntry(
        master: createTestMaster(lemma: 'Haus', gender: 'das'),
        translations: [
          LexiconTranslation(
            id: 't1',
            entryId: 'test-id-1',
            targetLang: 'en',
            translation: 'house',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          LexiconTranslation(
            id: 't2',
            entryId: 'test-id-1',
            targetLang: 'en',
            translation: 'home',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          LexiconTranslation(
            id: 't3',
            entryId: 'test-id-1',
            targetLang: 'en',
            translation: 'building',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
        senses: [
          LexiconSense(
            id: 's1',
            entryId: 'test-id-1',
            senseOrder: 1,
            definitionDe: 'Wohngebäude',
            definitionEn: 'residential building',
            contextDomain: 'Architecture',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          LexiconSense(
            id: 's2',
            entryId: 'test-id-1',
            senseOrder: 2,
            definitionDe: 'Familie/Geschlecht',
            definitionEn: 'dynasty',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
        synonyms: [
          LexiconSynonym(
            id: 'syn1',
            entryId: 'test-id-1',
            synonymWord: 'Gebäude',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          LexiconSynonym(
            id: 'syn2',
            entryId: 'test-id-1',
            synonymWord: 'Heim',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
        examples: [
          LexiconExample(
            id: 'ex1',
            entryId: 'test-id-1',
            sentenceDe: 'Das ist mein Haus.',
            sentenceEn: 'This is my house.',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
          LexiconExample(
            id: 'ex2',
            entryId: 'test-id-1',
            sentenceDe: 'Er kommt nach Hause.',
            sentenceEn: 'He comes home.',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        ],
      );

      final csv = CsvSerializer.serialize([entry]);

      // Verify semicolon separation and pipe separation in CSV
      expect(csv.contains('house; home; building'), isTrue);
      expect(csv.contains('Gebäude; Heim'), isTrue);
      expect(csv.contains('Wohngebäude (residential building) [Architecture]; Familie/Geschlecht (dynasty)'), isTrue);
      expect(csv.contains('Das ist mein Haus. | Er kommt nach Hause.'), isTrue);
      expect(csv.contains('This is my house. | He comes home.'), isTrue);
    });

    test('6. Empty dataset serializes header only without error', () {
      final csv = CsvSerializer.serialize([]);
      expect(csv.startsWith('\uFEFF'), isTrue);
      final lines = csv.replaceFirst('\uFEFF', '').trim().split('\n');
      expect(lines.length, 1);
    });
  });

  group('Phase 12B-4: CsvExportController Tests', () {
    late MockCsvExportRepository repo;
    late CsvExportController controller;

    setUp(() {
      repo = MockCsvExportRepository();
      repo.entries = [
        CsvExportEntry(master: createTestMaster(id: '1', lemma: 'Apfel', cefrLevel: 'A1', status: 'verified')),
        CsvExportEntry(master: createTestMaster(id: '2', lemma: 'Birne', cefrLevel: 'A1', status: 'review')),
        CsvExportEntry(master: createTestMaster(id: '3', lemma: 'Computer', cefrLevel: 'B1', status: 'verified')),
        CsvExportEntry(master: createTestMaster(id: '4', lemma: 'Demokratie', cefrLevel: 'C1', status: 'draft')),
      ];
      controller = CsvExportController(repository: repo);
    });

    test('1. Initial state is idle with 0 count until refreshed', () async {
      expect(controller.state, CsvExportState.idle);
      await controller.refreshCount();
      expect(controller.totalCount, 4);
    });

    test('2. Filter updates reflect in matching entry count', () async {
      controller.updateFilter(const LexiconFilter(cefrLevel: 'A1'));
      await Future.delayed(Duration.zero);
      expect(controller.totalCount, 2);

      controller.updateFilter(const LexiconFilter(status: 'verified'));
      await Future.delayed(Duration.zero);
      expect(controller.totalCount, 2);

      controller.updateFilter(const LexiconFilter(searchQuery: 'Apf'));
      await Future.delayed(Duration.zero);
      expect(controller.totalCount, 1);
    });

    test('3. runExport fetches filtered records and generates CSV string', () async {
      controller.updateFilter(const LexiconFilter(status: 'verified'));
      await controller.runExport();

      expect(controller.state, CsvExportState.success);
      expect(controller.entries.length, 2);
      expect(controller.csvContent.startsWith('\uFEFF'), isTrue);
      expect(controller.csvContent.contains('Apfel'), isTrue);
      expect(controller.csvContent.contains('Computer'), isTrue);
      expect(controller.csvContent.contains('Birne'), isFalse);
    });

    test('4. RLS permission error sets error state with descriptive message', () async {
      repo.shouldThrowRls = true;
      await controller.runExport();

      expect(controller.state, CsvExportState.error);
      expect(controller.errorMessage, contains('RLS'));
    });

    test('5. clearExport resets controller state back to idle', () async {
      await controller.runExport();
      expect(controller.state, CsvExportState.success);

      controller.clearExport();
      expect(controller.state, CsvExportState.idle);
      expect(controller.csvContent.isEmpty, isTrue);
      expect(controller.entries.isEmpty, isTrue);
    });
  });

  group('Phase 12B-4: CsvExportScreen Widget Tests', () {
    late MockCsvExportRepository repo;
    late CsvExportController controller;

    setUp(() {
      repo = MockCsvExportRepository();
      repo.entries = [
        CsvExportEntry(
          master: createTestMaster(id: '1', lemma: 'Auto', cefrLevel: 'A1', status: 'verified'),
          translations: [
            LexiconTranslation(
              id: 't1',
              entryId: '1',
              targetLang: 'en',
              translation: 'car',
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            ),
          ],
        ),
      ];
      controller = CsvExportController(repository: repo);
    });

    testWidgets('1. Renders screen title, filter widgets, and action button', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: CsvExportScreen(
            controller: controller,
            userRole: AdminRole.superadmin,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Export Master Lexicon to CSV'), findsOneWidget);
      expect(find.text('Generate CSV Export'), findsOneWidget);
      expect(find.text('CEFR Level'), findsOneWidget);
      expect(find.text('Part of Speech'), findsOneWidget);
      expect(find.text('Entry Status'), findsOneWidget);
      expect(find.text('Ready to Export'), findsOneWidget);
    });

    testWidgets('2. Clicking Generate CSV Export runs export and displays completion preview', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: CsvExportScreen(
            controller: controller,
            userRole: AdminRole.superadmin,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final exportBtn = find.text('Generate CSV Export');
      await tester.tap(exportBtn);
      await tester.pumpAndSettle();

      expect(find.text('Export Complete: 1 records generated successfully'), findsOneWidget);
      expect(find.text('Copy to Clipboard'), findsOneWidget);
      expect(find.textContaining('Auto'), findsWidgets);
    });

    testWidgets('3. Displays error message when export encounters an error', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      repo.shouldThrowRls = true;

      await tester.pumpWidget(
        MaterialApp(
          home: CsvExportScreen(
            controller: controller,
            userRole: AdminRole.superadmin,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final exportBtn = find.text('Generate CSV Export');
      await tester.tap(exportBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('RLS'), findsOneWidget);
    });

    testWidgets('4. Back to Lexicon button triggers navigation callback', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool navCalled = false;
      await tester.pumpWidget(
        MaterialApp(
          home: CsvExportScreen(
            controller: controller,
            userRole: AdminRole.superadmin,
            onNavigateToLexicon: () => navCalled = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final backBtn = find.text('Back to Lexicon');
      expect(backBtn, findsOneWidget);
      await tester.tap(backBtn);
      expect(navCalled, isTrue);
    });
  });
}
