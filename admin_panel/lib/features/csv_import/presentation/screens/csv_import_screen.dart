import 'package:flutter/material.dart';
import 'package:german_lexicon_admin/features/auth/domain/admin_user_model.dart';
import 'package:german_lexicon_admin/features/csv_import/presentation/controllers/csv_import_controller.dart';
import 'package:german_lexicon_admin/features/csv_import/presentation/widgets/csv_preview_table.dart';

class CsvImportScreen extends StatefulWidget {
  final CsvImportController controller;
  final AdminRole userRole;
  final String? currentUserId;
  final VoidCallback? onNavigateToReviewQueue;
  final VoidCallback? onNavigateToLexicon;

  const CsvImportScreen({
    super.key,
    required this.controller,
    required this.userRole,
    this.currentUserId,
    this.onNavigateToReviewQueue,
    this.onNavigateToLexicon,
  });

  @override
  State<CsvImportScreen> createState() => _CsvImportScreenState();
}

class _CsvImportScreenState extends State<CsvImportScreen> {
  final _textController = TextEditingController();

  static const String _sampleCsvTemplate =
      'lemma,part_of_speech,gender,plural_form,cefr_level,translation_en,translation_ur,translation_fa,translation_ar,sense_de,example_de,example_en\n'
      'Garten,noun,der,Gärten,A1,garden,باغ,باغ,حديقة,abgegrenztes Stück Land für Pflanzen,Der Garten ist grün.,The garden is green.\n'
      'trinken,verb,,,A1,drink,پینا,نوشیدن,شرب,Flüssigkeit zu sich nehmen,Ich trinke Wasser.,I drink water.\n'
      'schnell,adjective,,,A2,fast; quick,تیز,سریع,سريع,hohe Geschwindigkeit aufweisend,Das Auto ist schnell.,The car is fast.\n';

  @override
  void initState() {
    super.initState();
    _textController.text = widget.controller.csvRawText;
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _loadSampleTemplate() {
    setState(() {
      _textController.text = _sampleCsvTemplate;
      widget.controller.setCsvText(_sampleCsvTemplate);
    });
  }

  Future<void> _handleParse() async {
    widget.controller.setCsvText(_textController.text);
    await widget.controller.parseAndValidate();
  }

  Future<void> _handleImport() async {
    final toImportCount = widget.controller.rows.where((r) => r.canBeImported).length;
    if (toImportCount == 0) return;

    final targetStatus = widget.controller.targetStatus;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm Vocabulary Import'),
        content: Text(
          'Are you sure you want to import $toImportCount candidate word(s) with status "$targetStatus"?\n\n'
          '${targetStatus == 'review' ? 'These words will immediately appear in the Review Queue for verification.' : 'These words will be saved as drafts in the Master Lexicon.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Proceed with Import'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await widget.controller.executeImport(
        createdBy: widget.currentUserId,
      );

      if (!mounted) return;

      if (success) {
        final res = widget.controller.lastResult;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Successfully imported ${res?.successCount ?? 0} words into "$targetStatus" status!',
            ),
            backgroundColor: const Color(0xFF16A34A),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = widget.controller;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final summary = controller.summary;
        final hasRows = controller.hasRows;

        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'CSV Vocabulary Import',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Batch import German vocabulary candidates with schema validation, duplicate detection, and Review Queue routing.',
                            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ),
                    if (hasRows) ...[
                      OutlinedButton.icon(
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('New Import'),
                        onPressed: () {
                          controller.reset();
                          _textController.clear();
                        },
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // Error Banner
                if (controller.errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEE2E2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFF87171)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Color(0xFFB91C1C), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            controller.errorMessage!,
                            style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 16, color: Color(0xFF991B1B)),
                          onPressed: controller.clearError,
                        ),
                      ],
                    ),
                  ),
                ],

                // Post-import Result Banner
                if (controller.lastResult != null) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFF86EFAC)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Import Completed: ${controller.lastResult!.successCount} succeeded, ${controller.lastResult!.skippedCount} skipped, ${controller.lastResult!.errorCount} errors.',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF166534),
                                  fontSize: 14,
                                ),
                              ),
                              if (controller.targetStatus == 'review') ...[
                                const Text(
                                  'Imported vocabulary has been sent directly to the Review Queue.',
                                  style: TextStyle(color: Color(0xFF15803D), fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (widget.onNavigateToReviewQueue != null &&
                            controller.targetStatus == 'review') ...[
                          ElevatedButton.icon(
                            icon: const Icon(Icons.rate_review_outlined, size: 16),
                            label: const Text('Go to Review Queue'),
                            onPressed: widget.onNavigateToReviewQueue,
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                // Input Section (shown when no rows parsed yet or when editing)
                if (!hasRows) ...[
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                const Text(
                                  'Paste CSV Data (RFC 4180 format)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const Spacer(),
                                TextButton.icon(
                                  icon: const Icon(Icons.file_copy_outlined, size: 16),
                                  label: const Text('Load Sample Template'),
                                  onPressed: _loadSampleTemplate,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: TextField(
                                controller: _textController,
                                maxLines: null,
                                expands: true,
                                decoration: InputDecoration(
                                  hintText:
                                      'lemma,part_of_speech,gender,plural_form,cefr_level,translation_en,translation_ur,translation_fa,translation_ar\n'
                                      'Haus,noun,das,Häuser,A1,house,گھر,خانه,منزل\n'
                                      'laufen,verb,,,A2,run; walk,دوڑنا,دویدن,ركض',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  filled: true,
                                  fillColor: const Color(0xFFF8FAFC),
                                ),
                                style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                OutlinedButton(
                                  onPressed: () => _textController.clear(),
                                  child: const Text('Clear'),
                                ),
                                const SizedBox(width: 12),
                                ElevatedButton.icon(
                                  icon: controller.isParsing
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        )
                                      : const Icon(Icons.fact_check_outlined, size: 18),
                                  label: const Text('Parse & Validate CSV'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2563EB),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                  ),
                                  onPressed: controller.isParsing ? null : _handleParse,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],

                // Preview & Configuration Section (shown once parsed)
                if (hasRows) ...[
                  // Summary Cards Bar
                  Row(
                    children: [
                      _buildSummaryCard('Total Parsed', '${summary.totalRows}', const Color(0xFF0F172A), Icons.format_list_numbered),
                      const SizedBox(width: 8),
                      _buildSummaryCard('Valid', '${summary.validRows}', const Color(0xFF16A34A), Icons.check_circle_outline),
                      const SizedBox(width: 8),
                      _buildSummaryCard('Warnings', '${summary.warningRows}', const Color(0xFFD97706), Icons.warning_amber_outlined),
                      const SizedBox(width: 8),
                      _buildSummaryCard('Errors', '${summary.errorRows}', const Color(0xFFDC2626), Icons.error_outline),
                      const SizedBox(width: 8),
                      _buildSummaryCard('Verified Conflicts', '${summary.verifiedConflictRows}', const Color(0xFF991B1B), Icons.block),
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Target Status & Actions Card
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            const Text(
                              'Assign Status on Import:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(width: 12),
                            SegmentedButton<String>(
                              segments: const [
                                ButtonSegment(
                                  value: 'review',
                                  label: Text('Review Queue (review)'),
                                  icon: Icon(Icons.rate_review_outlined, size: 16),
                                ),
                                ButtonSegment(
                                  value: 'draft',
                                  label: Text('Draft (draft)'),
                                  icon: Icon(Icons.edit_note_outlined, size: 16),
                                ),
                              ],
                              selected: {controller.targetStatus},
                              onSelectionChanged: (newSelection) {
                                if (newSelection.isNotEmpty) {
                                  controller.setTargetStatus(newSelection.first);
                                }
                              },
                            ),
                            const SizedBox(width: 24),
                            // Quick selection helpers
                            TextButton(
                              onPressed: () => controller.selectAll(true),
                              child: const Text('Select All Valid'),
                            ),
                            TextButton(
                              onPressed: () => controller.selectAll(false),
                              child: const Text('Deselect All'),
                            ),
                            const SizedBox(width: 12),
                            // Execute import button
                            ElevatedButton.icon(
                              icon: controller.isImporting
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.cloud_upload_outlined, size: 18),
                              label: Text(
                                'Import ${summary.selectedForImport} Words (${controller.targetStatus})',
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF2563EB),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              ),
                              onPressed: (controller.isImporting || summary.selectedForImport == 0)
                                  ? null
                                  : _handleImport,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Filter Chips Bar
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip('All Rows (${summary.totalRows})', 'all', controller),
                        const SizedBox(width: 6),
                        _buildFilterChip('Valid (${summary.validRows})', 'valid', controller),
                        const SizedBox(width: 6),
                        _buildFilterChip('Warnings (${summary.warningRows})', 'warnings', controller),
                        const SizedBox(width: 6),
                        _buildFilterChip('Errors (${summary.errorRows})', 'errors', controller),
                        const SizedBox(width: 6),
                        _buildFilterChip('Conflicts (${summary.verifiedConflictRows})', 'conflicts', controller),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Preview Table Card
                  Expanded(
                    child: Card(
                      child: CsvPreviewTable(
                        rows: controller.filteredRows,
                        onToggleSelect: controller.toggleRowSelection,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String filterKey, CsvImportController controller) {
    final isSelected = controller.activePreviewFilter == filterKey;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => controller.setPreviewFilter(filterKey),
      selectedColor: const Color(0xFFE0E7FF),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? const Color(0xFF3730A3) : const Color(0xFF475569),
      ),
    );
  }
}
