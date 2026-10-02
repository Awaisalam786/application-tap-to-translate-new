import 'package:flutter/material.dart';
import 'package:german_lexicon_admin/features/csv_import/domain/models/csv_import_row.dart';
import 'package:german_lexicon_admin/features/lexicon/presentation/widgets/cefr_badge.dart';

class CsvPreviewTable extends StatelessWidget {
  final List<CsvImportRow> rows;
  final Function(int rowIndex) onToggleSelect;

  const CsvPreviewTable({
    super.key,
    required this.rows,
    required this.onToggleSelect,
  });

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            'No rows match the selected filter.',
            style: TextStyle(color: Color(0xFF64748B)),
          ),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                columns: const [
                  DataColumn(label: Text('Import?')),
                  DataColumn(label: Text('Row #')),
                  DataColumn(label: Text('German Word')),
                  DataColumn(label: Text('POS')),
                  DataColumn(label: Text('Gender')),
                  DataColumn(label: Text('CEFR')),
                  DataColumn(label: Text('Translations')),
                  DataColumn(label: Text('Validation')),
                  DataColumn(label: Text('Duplicate / DB Status')),
                  DataColumn(label: Text('Messages')),
                ],
                rows: rows.map((row) {
                  final isConflict = row.isVerifiedConflict;
                  final isError = row.validationStatus == CsvValidationStatus.error;

                  return DataRow(
                    color: WidgetStateProperty.resolveWith<Color?>((states) {
                      if (isConflict) return const Color(0xFFFEF2F2); // Red tint for conflict
                      if (isError) return const Color(0xFFFFFBEB); // Yellow/red tint for error
                      return null;
                    }),
                    cells: [
                      DataCell(
                        Checkbox(
                          value: row.shouldImport && !isConflict && !isError,
                          onChanged: (isConflict || isError)
                              ? null // Disabled if verified conflict or error
                              : (_) => onToggleSelect(row.rowIndex),
                        ),
                      ),
                      DataCell(Text('#${row.rowIndex}')),
                      DataCell(
                        Text(
                          row.lemma.isNotEmpty ? row.lemma : '—',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      DataCell(Text(row.partOfSpeech)),
                      DataCell(Text(row.gender ?? '—')),
                      DataCell(
                        row.cefrLevel != 'unclassified'
                            ? CefrBadge(cefr: row.cefrLevel)
                            : const Text('unclassified', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11)),
                      ),
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 240),
                          child: Text(
                            _formatTranslations(row.translations),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                        ),
                      ),
                      DataCell(_buildValidationBadge(row.validationStatus)),
                      DataCell(_buildDuplicateBadge(row.duplicateStatus)),
                      DataCell(
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 280),
                          child: Text(
                            _formatMessages(row),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: isConflict || isError
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatTranslations(Map<String, String> translations) {
    if (translations.isEmpty) return '—';
    return translations.entries
        .map((e) => '${e.key.toUpperCase()}: ${e.value}')
        .join(' | ');
  }

  String _formatMessages(CsvImportRow row) {
    final list = <String>[];
    if (row.duplicateDetail != null) list.add(row.duplicateDetail!);
    list.addAll(row.validationErrors);
    list.addAll(row.validationWarnings);
    return list.isEmpty ? 'All checks passed' : list.join(' • ');
  }

  Widget _buildValidationBadge(CsvValidationStatus status) {
    Color bg;
    Color border;
    Color text;

    switch (status) {
      case CsvValidationStatus.valid:
        bg = const Color(0xFFDCFCE7);
        border = const Color(0xFF86EFAC);
        text = const Color(0xFF166534);
        break;
      case CsvValidationStatus.warning:
        bg = const Color(0xFFFEF3C7);
        border = const Color(0xFFFCD34D);
        text = const Color(0xFF92400E);
        break;
      case CsvValidationStatus.error:
        bg = const Color(0xFFFEE2E2);
        border = const Color(0xFFFCA5A5);
        text = const Color(0xFF991B1B);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: text),
      ),
    );
  }

  Widget _buildDuplicateBadge(DuplicateStatus status) {
    Color bg;
    Color border;
    Color text;

    switch (status) {
      case DuplicateStatus.none:
        bg = const Color(0xFFEFF6FF);
        border = const Color(0xFFBFDBFE);
        text = const Color(0xFF1E40AF);
        break;
      case DuplicateStatus.duplicateInFile:
        bg = const Color(0xFFF3E8FF);
        border = const Color(0xFFD8B4FE);
        text = const Color(0xFF6B21A8);
        break;
      case DuplicateStatus.existingDraftReview:
        bg = const Color(0xFFFFF7ED);
        border = const Color(0xFFFFEDD5);
        text = const Color(0xFF9A3412);
        break;
      case DuplicateStatus.existingVerified:
        bg = const Color(0xFFFEF2F2);
        border = const Color(0xFFF87171);
        text = const Color(0xFFB91C1C);
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Text(
        status.label,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: text),
      ),
    );
  }
}
