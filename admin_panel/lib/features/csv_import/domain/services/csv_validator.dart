import 'package:german_lexicon_admin/features/csv_import/domain/models/csv_import_row.dart';
import 'package:german_lexicon_admin/features/csv_import/domain/services/csv_parser.dart';

class CsvValidator {
  static const Set<String> _validPos = {
    'noun',
    'verb',
    'adjective',
    'adverb',
    'pronoun',
    'preposition',
    'conjunction',
    'interjection',
    'particle',
    'other',
  };

  static const Set<String> _validCefr = {
    'A1',
    'A2',
    'B1',
    'B2',
    'C1',
    'C2',
    'unclassified',
  };

  /// Normalizes and validates a list of parsed CSV records
  static List<CsvImportRow> validate(List<CsvParsedRecord> records) {
    final rows = <CsvImportRow>[];
    final seenLemmas = <String, int>{}; // "$normLemma|$pos" -> firstRowIndex

    for (final rec in records) {
      final errors = <String>[];
      final warnings = <String>[];
      DuplicateStatus dupStatus = DuplicateStatus.none;
      String? dupDetail;

      final fields = rec.mappedFields;

      // 1. Lemma validation
      final rawLemma = fields['lemma']?.trim() ?? '';
      if (rawLemma.isEmpty) {
        errors.add('German word/lemma is required.');
      } else if (rawLemma.length > 100) {
        errors.add('Lemma exceeds 100 characters.');
      }

      final lemma = rawLemma;
      final normalizedLemma = rawLemma.toLowerCase();

      // 2. Part of Speech normalization & validation
      final rawPos = fields['part_of_speech']?.trim() ?? '';
      String pos = _normalizePos(rawPos);
      if (pos.isEmpty) {
        pos = 'noun';
        if (rawPos.isNotEmpty) {
          warnings.add('Unrecognized POS "$rawPos" defaulted to "noun".');
        } else {
          warnings.add('Missing POS defaulted to "noun".');
        }
      } else if (!_validPos.contains(pos)) {
        errors.add('Invalid part of speech: "$pos".');
      }

      // 3. Gender validation (only nouns)
      final rawGender = fields['gender']?.trim();
      String? gender;
      if (pos == 'noun') {
        gender = _normalizeGender(rawGender);
        if (rawGender != null && rawGender.isNotEmpty && gender == null) {
          warnings.add('Unrecognized gender article "$rawGender" omitted.');
        }
      } else if (rawGender != null && rawGender.isNotEmpty) {
        warnings.add('Gender article "$rawGender" ignored for non-noun ($pos).');
      }

      // 4. Plural form
      final plural = fields['plural_form']?.trim();

      // 5. CEFR level normalization
      final rawCefr = fields['cefr_level']?.trim() ?? '';
      String cefr = 'unclassified';
      if (rawCefr.isNotEmpty) {
        final upperCefr = rawCefr.toUpperCase();
        if (_validCefr.contains(upperCefr)) {
          cefr = upperCefr;
        } else {
          warnings.add('Unrecognized CEFR level "$rawCefr" set to "unclassified".');
        }
      }

      // 6. Translations
      final translations = <String, String>{};
      if (fields['translation_en'] != null && fields['translation_en']!.trim().isNotEmpty) {
        translations['en'] = fields['translation_en']!.trim();
      }
      if (fields['translation_ur'] != null && fields['translation_ur']!.trim().isNotEmpty) {
        translations['ur'] = fields['translation_ur']!.trim();
      }
      if (fields['translation_fa'] != null && fields['translation_fa']!.trim().isNotEmpty) {
        translations['fa'] = fields['translation_fa']!.trim();
      }
      if (fields['translation_ar'] != null && fields['translation_ar']!.trim().isNotEmpty) {
        translations['ar'] = fields['translation_ar']!.trim();
      }

      if (translations.isEmpty) {
        warnings.add('No translation provided for this word.');
      }

      // 7. Senses
      final senseDe = fields['sense_de']?.trim();
      final senseEn = fields['sense_en']?.trim();

      // 8. Synonyms
      final rawSyn = fields['synonyms']?.trim();
      final synonyms = <String>[];
      if (rawSyn != null && rawSyn.isNotEmpty) {
        final tokens = rawSyn.split(RegExp(r'[,;]'));
        for (final token in tokens) {
          final t = token.trim();
          if (t.isNotEmpty && !synonyms.contains(t)) {
            synonyms.add(t);
          }
        }
      }

      // 9. Example
      final exDe = fields['example_de']?.trim();
      final exEn = fields['example_en']?.trim();
      final exUr = fields['example_ur']?.trim();

      // 10. In-file duplicate detection
      if (lemma.isNotEmpty) {
        final key = '$normalizedLemma|$pos';
        if (seenLemmas.containsKey(key)) {
          final firstRow = seenLemmas[key]!;
          dupStatus = DuplicateStatus.duplicateInFile;
          dupDetail = 'Duplicate in file: already defined in row #$firstRow.';
          warnings.add(dupDetail);
        } else {
          seenLemmas[key] = rec.rowIndex;
        }
      }

      // Determine validation status
      final validationStatus = errors.isNotEmpty
          ? CsvValidationStatus.error
          : (warnings.isNotEmpty ? CsvValidationStatus.warning : CsvValidationStatus.valid);

      final shouldImport = errors.isEmpty && dupStatus != DuplicateStatus.duplicateInFile;

      rows.add(CsvImportRow(
        rowIndex: rec.rowIndex,
        lemma: lemma,
        normalizedLemma: normalizedLemma,
        partOfSpeech: pos,
        gender: gender,
        pluralForm: plural != null && plural.isNotEmpty ? plural : null,
        cefrLevel: cefr,
        translations: translations,
        senseDe: senseDe != null && senseDe.isNotEmpty ? senseDe : null,
        senseEn: senseEn != null && senseEn.isNotEmpty ? senseEn : null,
        synonyms: synonyms,
        exampleDe: exDe != null && exDe.isNotEmpty ? exDe : null,
        exampleEn: exEn != null && exEn.isNotEmpty ? exEn : null,
        exampleUr: exUr != null && exUr.isNotEmpty ? exUr : null,
        validationStatus: validationStatus,
        validationErrors: errors,
        validationWarnings: warnings,
        duplicateStatus: dupStatus,
        duplicateDetail: dupDetail,
        shouldImport: shouldImport,
      ));
    }

    return rows;
  }

  static String _normalizePos(String input) {
    final lower = input.trim().toLowerCase();
    switch (lower) {
      case 'noun':
      case 'n':
      case 'substantiv':
      case 'nomen':
        return 'noun';
      case 'verb':
      case 'v':
      case 'verben':
        return 'verb';
      case 'adjective':
      case 'adj':
      case 'adjektiv':
        return 'adjective';
      case 'adverb':
      case 'adv':
        return 'adverb';
      case 'pronoun':
      case 'pron':
      case 'pronomen':
        return 'pronoun';
      case 'preposition':
      case 'prep':
      case 'präposition':
        return 'preposition';
      case 'conjunction':
      case 'conj':
      case 'konjunktion':
        return 'conjunction';
      case 'interjection':
      case 'interj':
      case 'interjektion':
        return 'interjection';
      case 'particle':
      case 'part':
      case 'partikel':
        return 'particle';
      case 'other':
      case 'sonstige':
        return 'other';
      default:
        return lower;
    }
  }

  static String? _normalizeGender(String? input) {
    if (input == null || input.trim().isEmpty) return null;
    final lower = input.trim().toLowerCase();
    switch (lower) {
      case 'der':
      case 'm':
      case 'maskulin':
      case 'masculine':
        return 'der';
      case 'die':
      case 'f':
      case 'feminin':
      case 'feminine':
        return 'die';
      case 'das':
      case 'n':
      case 'nt':
      case 'neutrum':
      case 'neuter':
        return 'das';
      case 'none':
      case 'kein':
      case 'ohne':
        return 'none';
      default:
        return null;
    }
  }
}
