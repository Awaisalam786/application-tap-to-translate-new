import '../models/csv_export_entry.dart';

class CsvSerializer {
  static const List<String> csvHeaders = [
    'lemma',
    'article',
    'pos',
    'plural',
    'cefr',
    'topic',
    'english',
    'urdu',
    'farsi',
    'arabic',
    'senses',
    'synonyms',
    'example_german',
    'example_english',
    'status',
    'source',
  ];

  /// Serializes a list of [CsvExportEntry] to an RFC 4180 compliant CSV string.
  /// Prefixes with UTF-8 BOM (`\uFEFF`) so Excel natively recognizes
  /// UTF-8 encoding including RTL characters (Urdu, Farsi, Arabic).
  static String serialize(List<CsvExportEntry> entries) {
    final buffer = StringBuffer();
    // UTF-8 Byte Order Mark (BOM)
    buffer.write('\uFEFF');

    // Header row
    buffer.writeln(csvHeaders.map(escapeField).join(','));

    // Data rows
    for (final entry in entries) {
      final row = _mapEntryToRow(entry);
      buffer.writeln(row.map(escapeField).join(','));
    }

    return buffer.toString();
  }

  /// Transforms a single [CsvExportEntry] into an ordered list of cell string values.
  static List<String> _mapEntryToRow(CsvExportEntry entry) {
    final m = entry.master;

    // Translations grouped by language code (targetLang)
    // Sort or preserve order, separate multiple translations with semicolon '; '
    final enTranslations = entry.translations
        .where((t) => t.targetLang.toLowerCase() == 'en')
        .map((t) => t.translation.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final urTranslations = entry.translations
        .where((t) => t.targetLang.toLowerCase() == 'ur')
        .map((t) => t.translation.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final faTranslations = entry.translations
        .where((t) => t.targetLang.toLowerCase() == 'fa')
        .map((t) => t.translation.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    final arTranslations = entry.translations
        .where((t) => t.targetLang.toLowerCase() == 'ar')
        .map((t) => t.translation.trim())
        .where((t) => t.isNotEmpty)
        .toList();

    // Senses formatting: collate definitions with domain context if available
    final sensesFormatted = entry.senses.map((s) {
      final parts = <String>[];
      if (s.definitionDe.isNotEmpty) parts.add(s.definitionDe);
      if (s.definitionEn != null && s.definitionEn!.isNotEmpty) {
        parts.add('(${s.definitionEn})');
      }
      if (s.contextDomain != null && s.contextDomain!.isNotEmpty) {
        parts.add('[${s.contextDomain}]');
      }
      return parts.join(' ');
    }).where((s) => s.isNotEmpty).join('; ');

    // Synonyms formatting: join words with '; '
    final synonymsFormatted = entry.synonyms
        .map((s) => s.synonymWord.trim())
        .where((s) => s.isNotEmpty)
        .join('; ');

    // Examples formatting: German and English sentences
    final exampleGermanList = entry.examples
        .map((e) => e.sentenceDe.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final exampleEnglishList = entry.examples
        .map((e) => (e.sentenceEn ?? '').trim())
        .where((e) => e.isNotEmpty)
        .toList();

    // Topic can come from sense contextDomain if any
    final topic = entry.senses
        .map((s) => s.contextDomain)
        .where((c) => c != null && c.isNotEmpty)
        .map((c) => c!)
        .toSet()
        .join('; ');

    return [
      m.lemma,
      m.gender ?? '',
      m.partOfSpeech,
      m.pluralForm ?? '',
      m.cefrLevel,
      topic,
      enTranslations.join('; '),
      urTranslations.join('; '),
      faTranslations.join('; '),
      arTranslations.join('; '),
      sensesFormatted,
      synonymsFormatted,
      exampleGermanList.join(' | '),
      exampleEnglishList.join(' | '),
      m.status,
      m.provenance ?? m.sourceType,
    ];
  }

  /// Escapes a single string field according to RFC 4180 rules.
  /// If field contains comma, semicolon, quote, or newline (\n, \r), wrap in double quotes
  /// and escape any double quotes by doubling them ("").
  static String escapeField(String field) {
    if (field.isEmpty) return '';

    final needsQuotes = field.contains(',') ||
        field.contains('"') ||
        field.contains('\n') ||
        field.contains('\r') ||
        field.contains(';');

    if (needsQuotes) {
      final escaped = field.replaceAll('"', '""');
      return '"$escaped"';
    }

    return field;
  }
}
