import '../models/master_lexicon_entry.dart';

/// Result object for POS and lexicon rule validation.
class PosValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;
  final String? suggestedLemma;
  final String? suggestedArticle;

  const PosValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
    this.suggestedLemma,
    this.suggestedArticle,
  });

  factory PosValidationResult.valid({
    List<String> warnings = const [],
    String? suggestedLemma,
    String? suggestedArticle,
  }) {
    return PosValidationResult(
      isValid: true,
      warnings: warnings,
      suggestedLemma: suggestedLemma,
      suggestedArticle: suggestedArticle,
    );
  }

  factory PosValidationResult.invalid(
    List<String> errors, {
    List<String> warnings = const [],
    String? suggestedLemma,
    String? suggestedArticle,
  }) {
    return PosValidationResult(
      isValid: false,
      errors: errors,
      warnings: warnings,
      suggestedLemma: suggestedLemma,
      suggestedArticle: suggestedArticle,
    );
  }
}

/// Domain validation service enforcing Master Lexicon linguistic and structural rules (Phase 12C-1).
class PosRulesValidator {
  static const Set<String> validArticles = {'der', 'die', 'das'};

  static const Set<String> validCefrLevels = {
    'A1',
    'A2',
    'B1',
    'B2',
    'C1',
    'C2',
    'unclassified',
  };

  static const Set<String> validStatuses = {
    'draft',
    'review',
    'verified',
    'rejected',
    'archived',
  };

  static const Set<String> validSourceTypes = {
    'original_curated',
    'admin_entered',
    'machine_generated',
    'imported_reference',
    'reviewed',
    'manual_entry',
    'candidate_import',
    'curated_expansion',
    'community_submission',
  };

  // Known irregular conjugated verb forms that should not be entered as master entries
  static const Set<String> conjugatedVerbForms = {
    'geht', 'ging', 'gingen', 'gegangen',
    'macht', 'machte', 'machten', 'gemacht',
    'gibt', 'gab', 'gaben', 'gegeben',
    'ist', 'war', 'waren', 'gewesen', 'bin', 'bist', 'seid',
    'hat', 'hatte', 'hatten', 'gehabt', 'hast', 'habt',
    'wird', 'wurde', 'wurden', 'geworden', 'wirst',
    'fährt', 'fuhr', 'fuhren', 'gefahren',
    'spricht', 'sprach', 'sprachen', 'gesprochen',
    'schreibt', 'schrieb', 'schrieben', 'geschrieben',
    'liest', 'las', 'lasen', 'gelesen',
    'sieht', 'sah', 'sahen', 'gesehen',
    'kommt', 'kam', 'kamen', 'gekommen',
    'nimmt', 'nahm', 'nahmen', 'genommen',
    'bringt', 'brachte', 'brachten', 'gebracht',
    'denkt', 'dachte', 'dachten', 'gedacht',
    'weiß', 'wusste', 'wussten', 'gewusst',
    'findet', 'fand', 'fanden', 'gefunden',
    'bleibt', 'blieb', 'blieben', 'geblieben',
    'liegt', 'lag', 'lagen', 'gelegen',
    'steht', 'stand', 'standen', 'gestanden',
  };

  // Known comparative and superlative adjectives that should not be entered as master entries
  static const Set<String> nonBaseAdjectives = {
    'besser', 'am besten', 'beste', 'besten', 'bester', 'bestes',
    'mehr', 'am meisten', 'meiste', 'meisten',
    'höher', 'am höchsten', 'höchste', 'höchsten', 'höchster', 'höchstes',
    'näher', 'am nächsten', 'nächste', 'nächsten',
    'lieber', 'am liebsten', 'liebste', 'liebsten',
    'größer', 'am größten', 'größte', 'größten', 'größter', 'größtes',
    'stärker', 'am stärksten', 'stärkste', 'stärksten',
    'länger', 'am längsten', 'längste', 'längsten',
    'kälter', 'am kältesten', 'kälteste', 'kältesten',
    'wärmer', 'am wärmsten', 'wärmste', 'wärmsten',
    'jünger', 'am jüngsten', 'jüngste', 'jüngsten',
    'älter', 'am ältesten', 'älteste', 'ältesten',
    'kleiner', 'am kleinsten', 'kleinste', 'kleinsten',
    'schneller', 'am schnellsten', 'schnellste', 'schnellsten',
    'schöner', 'am schönsten', 'schönste', 'schönsten',
    'heller', 'am hellsten',
    'dunkler', 'am dunkelsten',
  };

  // Base adjectives that legitimately end in 'er' (positive degree)
  static const Set<String> legitimateErAdjectives = {
    'teuer', 'sauer', 'bitter', 'tapfer', 'heiter', 'clever',
    'mager', 'düster', 'lauter', 'locker', 'sauber', 'sicher',
    'schwer', 'spontan', 'unlauter', 'unsicher', 'unsauber',
  };

  // Leading article regex pattern
  static final RegExp _leadingArticleRegex = RegExp(
    r'^(der|die|das|den|dem|des|ein|eine|einen|einem|einer|eines)\s+',
    caseSensitive: false,
  );

  /// Validates a German noun according to Master Lexicon rules:
  /// - Lemma must be canonical without leading article (e.g. "Tisch", NOT "der Tisch")
  /// - Valid noun articles: 'der', 'die', 'das'
  /// - Plural form must not contain articles
  static PosValidationResult validateNoun({
    required String lemma,
    String? article,
    String? pluralForm,
  }) {
    final errors = <String>[];
    final warnings = <String>[];
    String? suggestedLemma;
    String? suggestedArticle;

    final trimmedLemma = lemma.trim();
    if (trimmedLemma.isEmpty) {
      return PosValidationResult.invalid(['German noun lemma is required.']);
    }

    // Check if lemma starts with an article
    final match = _leadingArticleRegex.firstMatch(trimmedLemma);
    if (match != null) {
      final articleFound = match.group(1)!.toLowerCase();
      suggestedLemma = trimmedLemma.substring(match.end).trim();
      if (validArticles.contains(articleFound)) {
        suggestedArticle = articleFound;
      }
      errors.add(
        'German noun lemma must not include leading article. '
        'Store canonical lemma as "$suggestedLemma" and select article "$articleFound".',
      );
    }

    // Check article
    final normArticle = article?.trim().toLowerCase();
    if (normArticle != null && normArticle.isNotEmpty && normArticle != 'none') {
      if (!validArticles.contains(normArticle)) {
        errors.add(
          'Invalid noun article "$article". Valid German noun articles are: der, die, das.',
        );
      }
    } else {
      warnings.add('Noun is missing gender article (der, die, or das).');
    }

    // Check plural form
    if (pluralForm != null && pluralForm.trim().isNotEmpty) {
      final trimmedPlural = pluralForm.trim();
      final pluralMatch = _leadingArticleRegex.firstMatch(trimmedPlural);
      if (pluralMatch != null) {
        warnings.add(
          'Plural form should not include leading article (e.g. use "${trimmedPlural.substring(pluralMatch.end).trim()}" instead of "$trimmedPlural").',
        );
      }
    }

    if (errors.isNotEmpty) {
      return PosValidationResult.invalid(
        errors,
        warnings: warnings,
        suggestedLemma: suggestedLemma,
        suggestedArticle: suggestedArticle,
      );
    }

    return PosValidationResult.valid(
      warnings: warnings,
      suggestedLemma: suggestedLemma,
      suggestedArticle: suggestedArticle,
    );
  }

  /// Validates a German verb according to Master Lexicon rules:
  /// - Canonical form must be infinitive (e.g. "gehen", NOT "geht", "ging", "gegangen")
  /// - Reflexive verbs are fully supported (e.g. "sich erinnern", "sich freuen")
  /// - Infinitives end in -en, -eln, -ern, 'sein', or 'tun'
  static PosValidationResult validateVerb({required String lemma}) {
    final errors = <String>[];
    final warnings = <String>[];
    final trimmedLemma = lemma.trim();

    if (trimmedLemma.isEmpty) {
      return PosValidationResult.invalid(['German verb lemma is required.']);
    }

    // Check leading article mistakenly put on verb
    if (_leadingArticleRegex.hasMatch(trimmedLemma)) {
      errors.add('Verb lemma must not include an article.');
    }

    // Handle reflexive verbs: e.g. "sich erinnern"
    String verbStem = trimmedLemma;
    final isReflexive = trimmedLemma.toLowerCase().startsWith('sich ');
    if (isReflexive) {
      verbStem = trimmedLemma.substring(5).trim();
    }

    final lowerVerbStem = verbStem.toLowerCase();

    // Check known non-infinitive conjugated forms
    if (conjugatedVerbForms.contains(lowerVerbStem)) {
      errors.add(
        'Verb "$trimmedLemma" is a conjugated form. '
        'Canonical verb entries must be in the infinitive (e.g. "gehen" instead of "geht" or "ging").',
      );
    }

    // Check infinitive endings: -en, -eln, -ern, or special verbs sein / tun
    final hasInfinitiveEnding = lowerVerbStem.endsWith('en') ||
        lowerVerbStem.endsWith('eln') ||
        lowerVerbStem.endsWith('ern') ||
        lowerVerbStem == 'sein' ||
        lowerVerbStem == 'tun';

    if (!hasInfinitiveEnding) {
      errors.add(
        'Verb lemma "$trimmedLemma" is not in canonical infinitive form. '
        'German infinitives end in -en, -eln, -ern, "sein", or "tun".',
      );
    }

    // Check Partizip II pattern like "gemacht", "gekauft" (starts with ge- and ends with -t)
    if (lowerVerbStem.startsWith('ge') && lowerVerbStem.endsWith('t') && lowerVerbStem.length > 4) {
      errors.add(
        'Verb "$trimmedLemma" appears to be a past participle (Partizip II). '
        'Master lexicon entries must use the infinitive form.',
      );
    }

    if (errors.isNotEmpty) {
      return PosValidationResult.invalid(errors, warnings: warnings);
    }

    return PosValidationResult.valid(warnings: warnings);
  }

  /// Validates a German adjective according to Master Lexicon rules:
  /// - Canonical base form (positive degree, e.g. "schnell", NOT "schneller" or "am schnellsten")
  static PosValidationResult validateAdjective({required String lemma}) {
    final errors = <String>[];
    final warnings = <String>[];
    final trimmedLemma = lemma.trim();

    if (trimmedLemma.isEmpty) {
      return PosValidationResult.invalid(['German adjective lemma is required.']);
    }

    // Check leading article mistakenly put on adjective
    if (_leadingArticleRegex.hasMatch(trimmedLemma)) {
      errors.add('Adjective lemma must not include an article.');
    }

    final lower = trimmedLemma.toLowerCase();

    // Check superlative with "am ...sten"
    if (lower.startsWith('am ') && (lower.endsWith('sten') || lower.endsWith('ten'))) {
      errors.add(
        'Adjective "$trimmedLemma" is a superlative. '
        'Canonical entries must be in the base positive form (e.g. "schnell" instead of "am schnellsten").',
      );
    }

    // Check known non-base forms
    if (nonBaseAdjectives.contains(lower)) {
      errors.add(
        'Adjective "$trimmedLemma" is a comparative or superlative form. '
        'Canonical entries must use the base form (positive degree).',
      );
    }

    if (errors.isNotEmpty) {
      return PosValidationResult.invalid(errors, warnings: warnings);
    }

    return PosValidationResult.valid(warnings: warnings);
  }

  /// Validates a German adverb according to Master Lexicon rules:
  /// - Store canonical lexical form
  static PosValidationResult validateAdverb({required String lemma}) {
    final errors = <String>[];
    final warnings = <String>[];
    final trimmedLemma = lemma.trim();

    if (trimmedLemma.isEmpty) {
      return PosValidationResult.invalid(['German adverb lemma is required.']);
    }

    if (_leadingArticleRegex.hasMatch(trimmedLemma)) {
      errors.add('Adverb lemma must not include an article.');
    }

    if (errors.isNotEmpty) {
      return PosValidationResult.invalid(errors, warnings: warnings);
    }

    return PosValidationResult.valid(warnings: warnings);
  }

  /// Validates CEFR level
  static PosValidationResult validateCefr(String cefr) {
    final trimmed = cefr.trim();
    final upper = trimmed.toUpperCase();
    if (upper == 'UNCLASSIFIED' || validCefrLevels.contains(upper)) {
      return PosValidationResult.valid();
    }
    return PosValidationResult.invalid([
      'Invalid CEFR level "$cefr". Valid levels are: A1, A2, B1, B2, C1, C2, unclassified.',
    ]);
  }

  /// Validates workflow status and provenance security invariant:
  /// Machine-generated content must NEVER automatically become VERIFIED.
  static PosValidationResult validateStatusAndProvenance({
    required String status,
    required String sourceType,
    String? provenance,
  }) {
    final errors = <String>[];
    final warnings = <String>[];
    final normStatus = status.trim().toLowerCase();
    final normSource = sourceType.trim().toLowerCase();

    if (!validStatuses.contains(normStatus)) {
      errors.add(
        'Invalid workflow status "$status". Allowed statuses: draft, review, verified, rejected, archived.',
      );
    }

    // STRICT INVARIANT: Machine-generated content cannot be directly VERIFIED
    if (normStatus == 'verified' && normSource == 'machine_generated') {
      errors.add(
        'Security policy violation: Machine-generated content must NEVER automatically become VERIFIED. '
        'It must first pass through DRAFT or REVIEW and be reviewed by a human.',
      );
    }

    if (errors.isNotEmpty) {
      return PosValidationResult.invalid(errors, warnings: warnings);
    }

    return PosValidationResult.valid(warnings: warnings);
  }

  /// Validates German Unicode characters (ä, ö, ü, ß preserved)
  static bool containsValidGermanCharacters(String text) {
    // Basic check ensuring string can contain standard Latin and German characters
    return RegExp(r'[a-zA-ZäöüÄÖÜß\s\-\.\,\(\)]+').hasMatch(text);
  }

  /// Validates RTL Unicode characters for Urdu, Persian (Farsi), Arabic.
  /// Arabic/Persian/Urdu Unicode ranges: \u0600-\u06FF, \u0750-\u077F, \uFB50-\uFDFF, \uFE70-\uFEFF
  static bool hasRtlUnicodeCharacters(String text) {
    return RegExp(r'[\u0600-\u06FF\u0750-\u077F\uFB50-\uFDFF\uFE70-\uFEFF]').hasMatch(text);
  }

  /// Master validator for an entire [MasterLexiconEntry]
  static PosValidationResult validateEntry(MasterLexiconEntry entry) {
    final errors = <String>[];
    final warnings = <String>[];

    final pos = entry.partOfSpeech.trim().toLowerCase();
    final lemma = entry.lemma.trim();

    if (lemma.isEmpty) {
      errors.add('German lemma is required.');
    }

    // POS specific rules
    PosValidationResult posResult;
    switch (pos) {
      case 'noun':
        posResult = validateNoun(
          lemma: lemma,
          article: entry.gender,
          pluralForm: entry.pluralForm,
        );
        break;
      case 'verb':
        posResult = validateVerb(lemma: lemma);
        break;
      case 'adjective':
        posResult = validateAdjective(lemma: lemma);
        break;
      case 'adverb':
        posResult = validateAdverb(lemma: lemma);
        break;
      default:
        posResult = PosValidationResult.valid();
        break;
    }

    if (!posResult.isValid) {
      errors.addAll(posResult.errors);
    }
    warnings.addAll(posResult.warnings);

    // CEFR check
    final cefrResult = validateCefr(entry.cefrLevel);
    if (!cefrResult.isValid) {
      errors.addAll(cefrResult.errors);
    }

    // Status & provenance check
    final statusResult = validateStatusAndProvenance(
      status: entry.status,
      sourceType: entry.sourceType,
      provenance: entry.provenance,
    );
    if (!statusResult.isValid) {
      errors.addAll(statusResult.errors);
    }

    if (errors.isNotEmpty) {
      return PosValidationResult.invalid(
        errors,
        warnings: warnings,
        suggestedLemma: posResult.suggestedLemma,
        suggestedArticle: posResult.suggestedArticle,
      );
    }

    return PosValidationResult.valid(
      warnings: warnings,
      suggestedLemma: posResult.suggestedLemma,
      suggestedArticle: posResult.suggestedArticle,
    );
  }
}
