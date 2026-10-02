class LexiconFilter {
  final String? searchQuery;
  final String? cefrLevel;
  final String? partOfSpeech;
  final String? status;
  final String? gender;

  // Translation filters (null: all, true: has, false: missing)
  final bool? hasEnTranslation;
  final bool? hasUrTranslation;
  final bool? hasFaTranslation;
  final bool? hasArTranslation;

  // Lexical completeness filters
  final bool? hasExample;
  final bool? hasSense;
  final bool? hasSynonym;

  final int page;
  final int pageSize;

  const LexiconFilter({
    this.searchQuery,
    this.cefrLevel,
    this.partOfSpeech,
    this.status,
    this.gender,
    this.hasEnTranslation,
    this.hasUrTranslation,
    this.hasFaTranslation,
    this.hasArTranslation,
    this.hasExample,
    this.hasSense,
    this.hasSynonym,
    this.page = 1,
    this.pageSize = 15,
  });

  static const List<String> availableStatuses = [
    'all',
    'draft',
    'review',
    'verified',
    'rejected',
  ];

  static const List<String> availableCefr = [
    'all',
    'A1',
    'A2',
    'B1',
    'B2',
    'C1',
    'C2',
    'unclassified',
  ];

  static const List<String> availablePos = [
    'all',
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
  ];

  static const List<String> availableGenders = [
    'all',
    'der',
    'die',
    'das',
    'none',
  ];

  bool get hasAdvancedFilters =>
      (gender != null && gender != 'all') ||
      hasEnTranslation != null ||
      hasUrTranslation != null ||
      hasFaTranslation != null ||
      hasArTranslation != null ||
      hasExample != null ||
      hasSense != null ||
      hasSynonym != null;

  LexiconFilter copyWith({
    String? searchQuery,
    String? cefrLevel,
    String? partOfSpeech,
    String? status,
    String? gender,
    bool? hasEnTranslation,
    bool? hasUrTranslation,
    bool? hasFaTranslation,
    bool? hasArTranslation,
    bool? hasExample,
    bool? hasSense,
    bool? hasSynonym,
    int? page,
    int? pageSize,
    bool clearSearch = false,
    bool clearAdvanced = false,
  }) {
    return LexiconFilter(
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      cefrLevel: cefrLevel ?? this.cefrLevel,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      status: status ?? this.status,
      gender: clearAdvanced ? null : (gender ?? this.gender),
      hasEnTranslation: clearAdvanced ? null : (hasEnTranslation ?? this.hasEnTranslation),
      hasUrTranslation: clearAdvanced ? null : (hasUrTranslation ?? this.hasUrTranslation),
      hasFaTranslation: clearAdvanced ? null : (hasFaTranslation ?? this.hasFaTranslation),
      hasArTranslation: clearAdvanced ? null : (hasArTranslation ?? this.hasArTranslation),
      hasExample: clearAdvanced ? null : (hasExample ?? this.hasExample),
      hasSense: clearAdvanced ? null : (hasSense ?? this.hasSense),
      hasSynonym: clearAdvanced ? null : (hasSynonym ?? this.hasSynonym),
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }
}
