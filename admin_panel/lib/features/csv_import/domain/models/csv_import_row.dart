enum CsvValidationStatus {
  valid,
  warning,
  error;

  String get label {
    switch (this) {
      case CsvValidationStatus.valid:
        return 'Valid';
      case CsvValidationStatus.warning:
        return 'Warning';
      case CsvValidationStatus.error:
        return 'Error';
    }
  }
}

enum DuplicateStatus {
  none,
  duplicateInFile,
  existingDraftReview,
  existingVerified;

  String get label {
    switch (this) {
      case DuplicateStatus.none:
        return 'New Word';
      case DuplicateStatus.duplicateInFile:
        return 'Duplicate in File';
      case DuplicateStatus.existingDraftReview:
        return 'Existing (Draft/Review)';
      case DuplicateStatus.existingVerified:
        return 'Existing (VERIFIED - Skip)';
    }
  }
}

class CsvImportRow {
  final int rowIndex; // 1-based index from CSV
  final String lemma;
  final String normalizedLemma;
  final String partOfSpeech;
  final String? gender;
  final String? pluralForm;
  final String cefrLevel;
  final Map<String, String> translations; // targetLang -> translation
  final String? senseDe;
  final String? senseEn;
  final List<String> synonyms;
  final String? exampleDe;
  final String? exampleEn;
  final String? exampleUr;

  final CsvValidationStatus validationStatus;
  final List<String> validationErrors;
  final List<String> validationWarnings;

  final DuplicateStatus duplicateStatus;
  final String? duplicateDetail;
  final String? existingEntryId;

  final bool shouldImport;

  const CsvImportRow({
    required this.rowIndex,
    required this.lemma,
    required this.normalizedLemma,
    required this.partOfSpeech,
    this.gender,
    this.pluralForm,
    this.cefrLevel = 'unclassified',
    this.translations = const {},
    this.senseDe,
    this.senseEn,
    this.synonyms = const [],
    this.exampleDe,
    this.exampleEn,
    this.exampleUr,
    this.validationStatus = CsvValidationStatus.valid,
    this.validationErrors = const [],
    this.validationWarnings = const [],
    this.duplicateStatus = DuplicateStatus.none,
    this.duplicateDetail,
    this.existingEntryId,
    this.shouldImport = true,
  });

  bool get isValid => validationStatus != CsvValidationStatus.error;
  bool get isVerifiedConflict => duplicateStatus == DuplicateStatus.existingVerified;
  bool get canBeImported => isValid && !isVerifiedConflict && shouldImport;

  CsvImportRow copyWith({
    int? rowIndex,
    String? lemma,
    String? normalizedLemma,
    String? partOfSpeech,
    String? gender,
    String? pluralForm,
    String? cefrLevel,
    Map<String, String>? translations,
    String? senseDe,
    String? senseEn,
    List<String>? synonyms,
    String? exampleDe,
    String? exampleEn,
    String? exampleUr,
    CsvValidationStatus? validationStatus,
    List<String>? validationErrors,
    List<String>? validationWarnings,
    DuplicateStatus? duplicateStatus,
    String? duplicateDetail,
    String? existingEntryId,
    bool? shouldImport,
  }) {
    return CsvImportRow(
      rowIndex: rowIndex ?? this.rowIndex,
      lemma: lemma ?? this.lemma,
      normalizedLemma: normalizedLemma ?? this.normalizedLemma,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      gender: gender ?? this.gender,
      pluralForm: pluralForm ?? this.pluralForm,
      cefrLevel: cefrLevel ?? this.cefrLevel,
      translations: translations ?? this.translations,
      senseDe: senseDe ?? this.senseDe,
      senseEn: senseEn ?? this.senseEn,
      synonyms: synonyms ?? this.synonyms,
      exampleDe: exampleDe ?? this.exampleDe,
      exampleEn: exampleEn ?? this.exampleEn,
      exampleUr: exampleUr ?? this.exampleUr,
      validationStatus: validationStatus ?? this.validationStatus,
      validationErrors: validationErrors ?? this.validationErrors,
      validationWarnings: validationWarnings ?? this.validationWarnings,
      duplicateStatus: duplicateStatus ?? this.duplicateStatus,
      duplicateDetail: duplicateDetail ?? this.duplicateDetail,
      existingEntryId: existingEntryId ?? this.existingEntryId,
      shouldImport: shouldImport ?? this.shouldImport,
    );
  }
}
