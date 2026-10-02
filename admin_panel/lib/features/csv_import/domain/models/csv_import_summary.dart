import 'csv_import_row.dart';

class CsvImportSummary {
  final int totalRows;
  final int validRows;
  final int warningRows;
  final int errorRows;
  final int newRows;
  final int duplicateExistingRows;
  final int verifiedConflictRows;
  final int selectedForImport;

  const CsvImportSummary({
    this.totalRows = 0,
    this.validRows = 0,
    this.warningRows = 0,
    this.errorRows = 0,
    this.newRows = 0,
    this.duplicateExistingRows = 0,
    this.verifiedConflictRows = 0,
    this.selectedForImport = 0,
  });

  factory CsvImportSummary.fromRows(List<CsvImportRow> rows) {
    int total = rows.length;
    int valid = 0;
    int warnings = 0;
    int errors = 0;
    int newRecords = 0;
    int duplicates = 0;
    int verifiedConflicts = 0;
    int selected = 0;

    for (final row in rows) {
      if (row.validationStatus == CsvValidationStatus.valid) {
        valid++;
      } else if (row.validationStatus == CsvValidationStatus.warning) {
        warnings++;
      } else if (row.validationStatus == CsvValidationStatus.error) {
        errors++;
      }

      if (row.duplicateStatus == DuplicateStatus.none) {
        newRecords++;
      } else if (row.duplicateStatus == DuplicateStatus.existingVerified) {
        verifiedConflicts++;
      } else {
        duplicates++;
      }

      if (row.canBeImported) {
        selected++;
      }
    }

    return CsvImportSummary(
      totalRows: total,
      validRows: valid,
      warningRows: warnings,
      errorRows: errors,
      newRows: newRecords,
      duplicateExistingRows: duplicates,
      verifiedConflictRows: verifiedConflicts,
      selectedForImport: selected,
    );
  }
}
