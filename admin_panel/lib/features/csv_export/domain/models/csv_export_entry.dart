import 'package:german_lexicon_admin/features/lexicon/domain/models/lexicon_example.dart';
import 'package:german_lexicon_admin/features/lexicon/domain/models/lexicon_sense.dart';
import 'package:german_lexicon_admin/features/lexicon/domain/models/lexicon_synonym.dart';
import 'package:german_lexicon_admin/features/lexicon/domain/models/lexicon_translation.dart';
import 'package:german_lexicon_admin/features/lexicon/domain/models/master_lexicon_entry.dart';

class CsvExportEntry {
  final MasterLexiconEntry master;
  final List<LexiconTranslation> translations;
  final List<LexiconSense> senses;
  final List<LexiconSynonym> synonyms;
  final List<LexiconExample> examples;

  const CsvExportEntry({
    required this.master,
    this.translations = const [],
    this.senses = const [],
    this.synonyms = const [],
    this.examples = const [],
  });

  factory CsvExportEntry.fromJson(Map<String, dynamic> json) {
    final master = MasterLexiconEntry.fromJson(json);

    final rawTranslations = json['lexicon_translations'] as List? ?? [];
    final translations = rawTranslations
        .map((t) => LexiconTranslation.fromJson(t as Map<String, dynamic>))
        .toList();

    final rawSenses = json['lexicon_senses'] as List? ?? [];
    final senses = rawSenses
        .map((s) => LexiconSense.fromJson(s as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.senseOrder.compareTo(b.senseOrder));

    final rawSynonyms = json['lexicon_synonyms'] as List? ?? [];
    final synonyms = rawSynonyms
        .map((s) => LexiconSynonym.fromJson(s as Map<String, dynamic>))
        .toList();

    final rawExamples = json['lexicon_examples'] as List? ?? [];
    final examples = rawExamples
        .map((e) => LexiconExample.fromJson(e as Map<String, dynamic>))
        .toList();

    return CsvExportEntry(
      master: master,
      translations: translations,
      senses: senses,
      synonyms: synonyms,
      examples: examples,
    );
  }
}
