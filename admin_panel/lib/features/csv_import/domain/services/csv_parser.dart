class CsvParsedRecord {
  final int rowIndex; // 1-based index (data row)
  final Map<String, String> mappedFields;
  final Map<String, String> rawFields;

  const CsvParsedRecord({
    required this.rowIndex,
    required this.mappedFields,
    required this.rawFields,
  });
}

class CsvParser {
  // Canonical column aliases
  static final Map<String, String> _headerAliases = {
    // Lemma
    'lemma': 'lemma',
    'word': 'lemma',
    'wort': 'lemma',
    'german': 'lemma',
    'german_word': 'lemma',

    // POS
    'part_of_speech': 'part_of_speech',
    'pos': 'part_of_speech',
    'type': 'part_of_speech',
    'wortart': 'part_of_speech',

    // Gender
    'gender': 'gender',
    'article': 'gender',
    'geschlecht': 'gender',
    'artikel': 'gender',

    // Plural
    'plural_form': 'plural_form',
    'plural': 'plural_form',
    'mehrzahl': 'plural_form',

    // CEFR
    'cefr_level': 'cefr_level',
    'cefr': 'cefr_level',
    'level': 'cefr_level',
    'niveau': 'cefr_level',

    // Translations
    'translation_en': 'translation_en',
    'en': 'translation_en',
    'english': 'translation_en',
    'englisch': 'translation_en',
    'translation': 'translation_en',

    'translation_ur': 'translation_ur',
    'ur': 'translation_ur',
    'urdu': 'translation_ur',

    'translation_fa': 'translation_fa',
    'fa': 'translation_fa',
    'farsi': 'translation_fa',
    'persian': 'translation_fa',

    'translation_ar': 'translation_ar',
    'ar': 'translation_ar',
    'arabic': 'translation_ar',
    'arabisch': 'translation_ar',

    // Senses
    'sense_de': 'sense_de',
    'definition_de': 'sense_de',
    'definition': 'sense_de',
    'bedeutung': 'sense_de',

    'sense_en': 'sense_en',
    'definition_en': 'sense_en',

    // Synonyms
    'synonyms': 'synonyms',
    'synonym': 'synonyms',
    'synonyme': 'synonyms',

    // Examples
    'example_de': 'example_de',
    'example_sentence_de': 'example_de',
    'example_german': 'example_de',
    'example': 'example_de',
    'beispiel': 'example_de',
    'beispielsatz': 'example_de',

    'example_en': 'example_en',
    'example_sentence_en': 'example_en',
    'example_english': 'example_en',

    'example_ur': 'example_ur',
    'example_sentence_ur': 'example_ur',
    'example_urdu': 'example_ur',

    // Topic / Category
    'topic': 'topic',
    'category': 'topic',
    'kategorie': 'topic',
    'themenbereich': 'topic',

    // Status
    'status': 'status',

    // Provenance / Source
    'source': 'provenance',
    'provenance': 'provenance',
    'quelle': 'provenance',

    // Additional aliases
    'word_type': 'part_of_speech',
    'normalized_word': 'normalized_lemma',
  };

  /// Parses raw CSV string according to RFC 4180
  static List<CsvParsedRecord> parse(String csvInput) {
    if (csvInput.trim().isEmpty) return [];

    // Strip BOM if present
    String text = csvInput;
    if (text.startsWith('\uFEFF')) {
      text = text.substring(1);
    }

    // Auto-detect delimiter from first non-empty line
    final delimiter = _detectDelimiter(text);

    // Tokenize into 2D table of strings
    final table = _parseRfc4180(text, delimiter);
    if (table.isEmpty) return [];

    // Header row
    final headerRow = table.first;
    if (table.length == 1) return []; // Only header, no data

    // Map headers to canonical keys
    final canonicalHeaders = <int, String>{};
    final rawHeaders = <int, String>{};

    for (int i = 0; i < headerRow.length; i++) {
      final rawHeader = headerRow[i].trim();
      rawHeaders[i] = rawHeader;
      final normalizedKey = _normalizeHeaderKey(rawHeader);
      final canonicalKey = _headerAliases[normalizedKey];
      if (canonicalKey != null) {
        canonicalHeaders[i] = canonicalKey;
      }
    }

    final records = <CsvParsedRecord>[];

    for (int rowIdx = 1; rowIdx < table.length; rowIdx++) {
      final row = table[rowIdx];
      // Skip completely blank rows
      if (row.every((cell) => cell.trim().isEmpty)) continue;

      final mapped = <String, String>{};
      final raw = <String, String>{};

      for (int colIdx = 0; colIdx < row.length; colIdx++) {
        final val = row[colIdx].trim();
        final rawCol = rawHeaders[colIdx] ?? 'col_$colIdx';
        raw[rawCol] = val;

        final canonicalKey = canonicalHeaders[colIdx];
        if (canonicalKey != null && val.isNotEmpty) {
          mapped[canonicalKey] = val;
        }
      }

      records.add(CsvParsedRecord(
        rowIndex: rowIdx,
        mappedFields: mapped,
        rawFields: raw,
      ));
    }

    return records;
  }

  static String _detectDelimiter(String text) {
    final firstLine = text.split('\n').first;
    final commaCount = firstLine.split(',').length - 1;
    final semiCount = firstLine.split(';').length - 1;
    final tabCount = firstLine.split('\t').length - 1;

    if (semiCount > commaCount && semiCount > tabCount) return ';';
    if (tabCount > commaCount && tabCount > semiCount) return '\t';
    return ',';
  }

  static String _normalizeHeaderKey(String header) {
    return header
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9_]'), '_')
        .replaceAll(RegExp(r'_+'), '_')
        .replaceAll(RegExp(r'^_|_$'), '');
  }

  /// Full RFC 4180 compliant CSV parser
  static List<List<String>> _parseRfc4180(String input, String delimiter) {
    final rows = <List<String>>[];
    List<String> currentRow = [];
    final currentField = StringBuffer();
    bool insideQuotes = false;
    final int length = input.length;
    int i = 0;

    final delimChar = delimiter.codeUnitAt(0);
    const int quoteChar = 34; // '"'
    const int crChar = 13; // '\r'
    const int lfChar = 10; // '\n'

    while (i < length) {
      final int char = input.codeUnitAt(i);

      if (insideQuotes) {
        if (char == quoteChar) {
          // Check for escaped quote ""
          if (i + 1 < length && input.codeUnitAt(i + 1) == quoteChar) {
            currentField.write('"');
            i += 2;
            continue;
          } else {
            insideQuotes = false;
            i++;
            continue;
          }
        } else {
          currentField.writeCharCode(char);
          i++;
          continue;
        }
      } else {
        if (char == quoteChar) {
          insideQuotes = true;
          i++;
          continue;
        } else if (char == delimChar) {
          currentRow.add(currentField.toString());
          currentField.clear();
          i++;
          continue;
        } else if (char == crChar) {
          if (i + 1 < length && input.codeUnitAt(i + 1) == lfChar) {
            i++; // Skip LF following CR
          }
          currentRow.add(currentField.toString());
          currentField.clear();
          rows.add(currentRow);
          currentRow = [];
          i++;
          continue;
        } else if (char == lfChar) {
          currentRow.add(currentField.toString());
          currentField.clear();
          rows.add(currentRow);
          currentRow = [];
          i++;
          continue;
        } else {
          currentField.writeCharCode(char);
          i++;
          continue;
        }
      }
    }

    // Add last field and row if any content remains
    if (currentField.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(currentField.toString());
      rows.add(currentRow);
    }

    return rows;
  }
}
