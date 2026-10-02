import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:german_lexicon_admin/features/auth/domain/admin_user_model.dart';
import 'package:german_lexicon_admin/features/csv_import/data/csv_import_repository.dart';
import 'package:german_lexicon_admin/features/csv_import/domain/models/csv_import_row.dart';
import 'package:german_lexicon_admin/features/csv_import/domain/services/csv_parser.dart';
import 'package:german_lexicon_admin/features/csv_import/domain/services/csv_validator.dart';
import 'package:german_lexicon_admin/features/csv_import/presentation/controllers/csv_import_controller.dart';
import 'package:german_lexicon_admin/features/csv_import/presentation/screens/csv_import_screen.dart';
import 'package:german_lexicon_admin/features/lexicon/data/lexicon_repository.dart';
import 'package:german_lexicon_admin/features/lexicon/domain/models/master_lexicon_entry.dart';

class MockCsvImportRepository implements CsvImportRepository {
  final List<MasterLexiconEntry> existingEntries = [];
  final List<Map<String, dynamic>> importedRecords = [];

  bool shouldThrowRls = false;
  bool shouldThrowNetwork = false;

  @override
  Future<List<CsvImportRow>> checkDatabaseDuplicates(List<CsvImportRow> rows) async {
    if (shouldThrowRls) {
      throw const RlsPermissionException('RLS read permission denied');
    }
    if (shouldThrowNetwork) {
      throw Exception('Network connection failure');
    }

    final updated = <CsvImportRow>[];
    for (final row in rows) {
      if (!row.isValid || row.duplicateStatus == DuplicateStatus.duplicateInFile) {
        updated.add(row);
        continue;
      }

      final match = existingEntries.cast<MasterLexiconEntry?>().firstWhere(
            (e) => e != null &&
                e.normalizedLemma == row.normalizedLemma &&
                e.partOfSpeech == row.partOfSpeech,
            orElse: () => null,
          );

      if (match != null) {
        if (match.status == 'verified') {
          updated.add(row.copyWith(
            duplicateStatus: DuplicateStatus.existingVerified,
            duplicateDetail: 'Word is already VERIFIED in dictionary. Overwriting is prohibited.',
            existingEntryId: match.id,
            shouldImport: false,
          ));
        } else {
          updated.add(row.copyWith(
            duplicateStatus: DuplicateStatus.existingDraftReview,
            duplicateDetail: 'Word already exists in "${match.status}" status.',
            existingEntryId: match.id,
            shouldImport: false,
          ));
        }
      } else {
        updated.add(row.copyWith(
          duplicateStatus: DuplicateStatus.none,
          duplicateDetail: null,
          existingEntryId: null,
          shouldImport: true,
        ));
      }
    }
    return updated;
  }

  @override
  Future<CsvImportExecutionResult> executeImport(
    List<CsvImportRow> rows, {
    required String targetStatus,
    String? createdBy,
  }) async {
    if (shouldThrowRls) {
      throw const RlsPermissionException('RLS write permission denied');
    }
    if (shouldThrowNetwork) {
      throw Exception('Network connection failure');
    }

    // STRICT INVARIANT: Never import directly as verified
    if (targetStatus == 'verified') {
      throw ArgumentError('Security policy violation: Cannot import directly as verified.');
    }

    int successCount = 0;
    int skippedCount = 0;
    int errorCount = 0;
    final errors = <String>[];

    for (final row in rows) {
      if (!row.canBeImported) {
        skippedCount++;
        continue;
      }

      importedRecords.add({
        'lemma': row.lemma,
        'normalized_lemma': row.normalizedLemma,
        'part_of_speech': row.partOfSpeech,
        'gender': row.gender,
        'cefr_level': row.cefrLevel,
        'status': targetStatus,
        'translations': row.translations,
        'synonyms': row.synonyms,
        'senseDe': row.senseDe,
        'exampleDe': row.exampleDe,
      });

      successCount++;
    }

    return CsvImportExecutionResult(
      totalProcessed: rows.length,
      successCount: successCount,
      skippedCount: skippedCount,
      errorCount: errorCount,
      errors: errors,
    );
  }
}

void main() {
  group('CSV Parser Tests', () {
    test('1. Parses comma-separated CSV with headers and data', () {
      const csv = 'lemma,part_of_speech,gender,cefr_level,translation_en\n'
          'Haus,noun,das,A1,house\n'
          'Auto,noun,das,A1,car\n';

      final records = CsvParser.parse(csv);
      expect(records.length, 2);
      expect(records[0].mappedFields['lemma'], 'Haus');
      expect(records[0].mappedFields['gender'], 'das');
      expect(records[0].mappedFields['translation_en'], 'house');
      expect(records[1].mappedFields['lemma'], 'Auto');
    });

    test('2. Parses semicolon-separated CSV automatically', () {
      const csv = 'lemma;part_of_speech;gender;translation_en\n'
          'Buch;noun;das;book\n'
          'Tisch;noun;der;table\n';

      final records = CsvParser.parse(csv);
      expect(records.length, 2);
      expect(records[0].mappedFields['lemma'], 'Buch');
      expect(records[0].mappedFields['translation_en'], 'book');
      expect(records[1].mappedFields['lemma'], 'Tisch');
    });

    test('3. Handles UTF-8 BOM marker transparently', () {
      const csv = '\uFEFFlemma,pos,translation_en\nFenster,noun,window\n';

      final records = CsvParser.parse(csv);
      expect(records.length, 1);
      expect(records[0].mappedFields['lemma'], 'Fenster');
      expect(records[0].mappedFields['translation_en'], 'window');
    });

    test('4. Handles multiline and escaped quotes in CSV fields according to RFC 4180', () {
      const csv = 'lemma,part_of_speech,sense_de\n'
          'Zelle,noun,"Biologische Einheit,\nGrundbaustein ""des Lebens"""\n';

      final records = CsvParser.parse(csv);
      expect(records.length, 1);
      expect(records[0].mappedFields['lemma'], 'Zelle');
      expect(records[0].mappedFields['sense_de'],
          'Biologische Einheit,\nGrundbaustein "des Lebens"');
    });

    test('5. Handles multiple header alias variations', () {
      const csv = 'word,pos,article,level,english,urdu,farsi,arabic\n'
          'Hund,n,m,A1,dog,کتا,سگ,كلب\n';

      final records = CsvParser.parse(csv);
      expect(records.length, 1);
      expect(records[0].mappedFields['lemma'], 'Hund');
      expect(records[0].mappedFields['part_of_speech'], 'n');
      expect(records[0].mappedFields['gender'], 'm');
      expect(records[0].mappedFields['cefr_level'], 'A1');
      expect(records[0].mappedFields['translation_en'], 'dog');
      expect(records[0].mappedFields['translation_ur'], 'کتا');
      expect(records[0].mappedFields['translation_fa'], 'سگ');
      expect(records[0].mappedFields['translation_ar'], 'كلب');
    });

    test('6. Returns empty list for empty or whitespace CSV', () {
      expect(CsvParser.parse(''), isEmpty);
      expect(CsvParser.parse('   \n  \n'), isEmpty);
    });
  });

  group('CSV Validator & Normalizer Tests', () {
    test('7. Normalizes and validates standard vocabulary row', () {
      final records = CsvParser.parse(
        'lemma,part_of_speech,gender,cefr_level,translation_en,synonyms\n'
        'Haus,n,das,a1,house,"Gebäude, Heim"\n',
      );

      final rows = CsvValidator.validate(records);
      expect(rows.length, 1);
      final r = rows.first;
      expect(r.lemma, 'Haus');
      expect(r.normalizedLemma, 'haus');
      expect(r.partOfSpeech, 'noun');
      expect(r.gender, 'das');
      expect(r.cefrLevel, 'A1');
      expect(r.translations['en'], 'house');
      expect(r.synonyms, containsAll(['Gebäude', 'Heim']));
      expect(r.validationStatus, CsvValidationStatus.valid);
      expect(r.isValid, isTrue);
    });

    test('8. Rejects missing lemma with validation error', () {
      final records = CsvParser.parse(
        'lemma,part_of_speech,translation_en\n'
        ',noun,thing\n',
      );

      final rows = CsvValidator.validate(records);
      expect(rows.length, 1);
      expect(rows.first.validationStatus, CsvValidationStatus.error);
      expect(rows.first.validationErrors, contains('German word/lemma is required.'));
      expect(rows.first.canBeImported, isFalse);
    });

    test('9. Strips gender for non-nouns with warning', () {
      final records = CsvParser.parse(
        'lemma,part_of_speech,gender,cefr_level\n'
        'schnell,adjective,der,A1\n',
      );

      final rows = CsvValidator.validate(records);
      expect(rows.first.partOfSpeech, 'adjective');
      expect(rows.first.gender, isNull);
      expect(rows.first.validationWarnings.any((w) => w.contains('ignored for non-noun')), isTrue);
    });

    test('10. Detects in-file duplicates and marks second occurrence as duplicateInFile', () {
      const csv = 'lemma,part_of_speech,translation_en\n'
          'Haus,noun,house\n'
          'laufen,verb,run\n'
          'Haus,noun,home\n';

      final records = CsvParser.parse(csv);
      final rows = CsvValidator.validate(records);

      expect(rows.length, 3);
      expect(rows[0].duplicateStatus, DuplicateStatus.none);
      expect(rows[0].shouldImport, isTrue);

      expect(rows[1].duplicateStatus, DuplicateStatus.none);
      expect(rows[1].shouldImport, isTrue);

      expect(rows[2].duplicateStatus, DuplicateStatus.duplicateInFile);
      expect(rows[2].shouldImport, isFalse); // Default unchecked
      expect(rows[2].duplicateDetail, contains('already defined in row #1'));
    });
  });

  group('Duplicate Detection & Security Policy Tests', () {
    late MockCsvImportRepository repository;

    final existingVerifiedEntry = MasterLexiconEntry(
      id: 'v1',
      lemma: 'Haus',
      normalizedLemma: 'haus',
      partOfSpeech: 'noun',
      gender: 'das',
      cefrLevel: 'A1',
      status: 'verified',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final existingDraftEntry = MasterLexiconEntry(
      id: 'd1',
      lemma: 'laufen',
      normalizedLemma: 'laufen',
      partOfSpeech: 'verb',
      cefrLevel: 'A2',
      status: 'draft',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    setUp(() {
      repository = MockCsvImportRepository();
      repository.existingEntries.addAll([existingVerifiedEntry, existingDraftEntry]);
    });

    test('11. Prevents overwrite of VERIFIED database records', () async {
      final records = CsvParser.parse(
        'lemma,part_of_speech,gender,translation_en\n'
        'Haus,noun,das,house 2\n'
        'neu,adjective,,new\n',
      );
      final validated = CsvValidator.validate(records);
      final checked = await repository.checkDatabaseDuplicates(validated);

      // 'Haus' matches existing verified entry
      final hausRow = checked.firstWhere((r) => r.lemma == 'Haus');
      expect(hausRow.duplicateStatus, DuplicateStatus.existingVerified);
      expect(hausRow.isVerifiedConflict, isTrue);
      expect(hausRow.shouldImport, isFalse);
      expect(hausRow.canBeImported, isFalse);

      // 'neu' is new
      final neuRow = checked.firstWhere((r) => r.lemma == 'neu');
      expect(neuRow.duplicateStatus, DuplicateStatus.none);
      expect(neuRow.canBeImported, isTrue);
    });

    test('12. Flags existing DRAFT records as existingDraftReview', () async {
      final records = CsvParser.parse(
        'lemma,part_of_speech,translation_en\n'
        'laufen,verb,run fast\n',
      );
      final validated = CsvValidator.validate(records);
      final checked = await repository.checkDatabaseDuplicates(validated);

      final row = checked.first;
      expect(row.duplicateStatus, DuplicateStatus.existingDraftReview);
      expect(row.existingEntryId, 'd1');
      expect(row.isVerifiedConflict, isFalse);
    });

    test('13. Strictly rejects targetStatus = "verified" with ArgumentError', () async {
      final records = CsvParser.parse('lemma,pos\nneu,adjective\n');
      final rows = CsvValidator.validate(records);

      expect(
        () => repository.executeImport(rows, targetStatus: 'verified'),
        throwsArgumentError,
      );
    });
  });

  group('CsvImportController Tests', () {
    late MockCsvImportRepository repository;
    late CsvImportController controller;

    setUp(() {
      repository = MockCsvImportRepository();
      controller = CsvImportController(repository);
    });

    test('14. setTargetStatus rejects verified and accepts draft / review', () {
      expect(() => controller.setTargetStatus('verified'), throwsArgumentError);

      controller.setTargetStatus('draft');
      expect(controller.targetStatus, 'draft');

      controller.setTargetStatus('review');
      expect(controller.targetStatus, 'review');
    });

    test('15. parseAndValidate parses raw CSV and calculates summary', () async {
      controller.setCsvText(
        'lemma,part_of_speech,gender,cefr_level,translation_en\n'
        'Garten,noun,der,A1,garden\n'
        'fliegen,verb,,A2,fly\n'
        ',noun,,A1,broken\n', // Row with error
      );

      final success = await controller.parseAndValidate();
      expect(success, isTrue);
      expect(controller.rows.length, 3);

      final summary = controller.summary;
      expect(summary.totalRows, 3);
      expect(summary.validRows, 2);
      expect(summary.errorRows, 1);
      expect(summary.selectedForImport, 2);
    });

    test('16. Preview filtering works (valid, errors, conflicts)', () async {
      repository.existingEntries.add(MasterLexiconEntry(
        id: 'v1',
        lemma: 'Alt',
        normalizedLemma: 'alt',
        partOfSpeech: 'adjective',
        status: 'verified',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      controller.setCsvText(
        'lemma,part_of_speech,translation_en\n'
        'Neu,adjective,new\n'
        'Alt,adjective,old\n' // verified conflict
        ',noun,missing\n', // error
      );

      await controller.parseAndValidate();
      expect(controller.rows.length, 3);

      controller.setPreviewFilter('valid');
      expect(controller.filteredRows.length, 1);
      expect(controller.filteredRows.first.lemma, 'Neu');

      controller.setPreviewFilter('errors');
      expect(controller.filteredRows.length, 1);
      expect(controller.filteredRows.first.validationStatus, CsvValidationStatus.error);

      controller.setPreviewFilter('conflicts');
      expect(controller.filteredRows.length, 1);
      expect(controller.filteredRows.first.lemma, 'Alt');
    });

    test('17. Selection helpers toggle and select/deselect all', () async {
      controller.setCsvText(
        'lemma,pos\n'
        'Eins,noun\n'
        'Zwei,noun\n',
      );
      await controller.parseAndValidate();

      expect(controller.rows.every((r) => r.shouldImport), isTrue);

      controller.selectAll(false);
      expect(controller.rows.every((r) => !r.shouldImport), isTrue);

      controller.toggleRowSelection(1);
      expect(controller.rows[0].shouldImport, isTrue);
      expect(controller.rows[1].shouldImport, isFalse);

      controller.selectAll(true);
      expect(controller.rows.every((r) => r.shouldImport), isTrue);
    });

    test('18. executeImport successfully imports approved candidates into Review Queue', () async {
      controller.setCsvText(
        'lemma,part_of_speech,gender,cefr_level,translation_en,translation_ur\n'
        'Wasser,noun,das,A1,water,پانی\n'
        'Brot,noun,das,A1,bread,روٹی\n',
      );
      await controller.parseAndValidate();
      controller.setTargetStatus('review');

      final success = await controller.executeImport(createdBy: 'test_admin');
      expect(success, isTrue);

      expect(controller.lastResult?.successCount, 2);
      expect(repository.importedRecords.length, 2);
      expect(repository.importedRecords.every((r) => r['status'] == 'review'), isTrue);
      expect(repository.importedRecords.first['translations']['en'], 'water');
      expect(repository.importedRecords.first['translations']['ur'], 'پانی');
    });

    test('19. Handles RLS permission exception gracefully', () async {
      repository.shouldThrowRls = true;
      controller.setCsvText('lemma,pos\nTest,noun\n');

      final success = await controller.parseAndValidate();
      expect(success, isFalse);
      expect(controller.errorMessage, contains('RLS'));
      expect(controller.isParsing, isFalse);
    });
  });

  group('CsvImportScreen UI Widget Tests', () {
    late MockCsvImportRepository repository;
    late CsvImportController controller;

    setUp(() {
      repository = MockCsvImportRepository();
      controller = CsvImportController(repository);
    });

    testWidgets('20. Renders input view, loads sample template, and parses CSV', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(MaterialApp(
        home: CsvImportScreen(
          controller: controller,
          userRole: AdminRole.superadmin,
        ),
      ));
      await tester.pumpAndSettle();

      // Screen title
      expect(find.text('CSV Vocabulary Import'), findsOneWidget);
      expect(find.text('Load Sample Template'), findsOneWidget);

      // Click "Load Sample Template"
      await tester.tap(find.text('Load Sample Template'));
      await tester.pumpAndSettle();

      // Verify template populated text field
      expect(find.textContaining('Garten,noun,der'), findsOneWidget);

      // Click "Parse & Validate CSV"
      await tester.tap(find.text('Parse & Validate CSV'));
      await tester.pumpAndSettle();

      // Should now show preview metrics
      expect(find.text('Total Parsed'), findsOneWidget);
      expect(find.text('3'), findsWidgets); // 3 total, 3 valid
      expect(find.text('Review Queue (review)'), findsOneWidget);
      expect(find.text('Draft (draft)'), findsOneWidget);
      expect(find.textContaining('Import 3 Words (review)'), findsOneWidget);
    });

    testWidgets('21. SegmentedButton switches target status between review and draft', (tester) async {
      tester.view.physicalSize = const Size(1280, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      controller.setCsvText('lemma,pos\nSonne,noun\n');
      await controller.parseAndValidate();

      await tester.pumpWidget(MaterialApp(
        home: CsvImportScreen(
          controller: controller,
          userRole: AdminRole.editor,
        ),
      ));
      await tester.pumpAndSettle();

      expect(controller.targetStatus, 'review');

      // Tap "Draft (draft)"
      await tester.tap(find.text('Draft (draft)'));
      await tester.pumpAndSettle();

      expect(controller.targetStatus, 'draft');
      expect(find.textContaining('Import 1 Words (draft)'), findsOneWidget);
    });
  });
}
