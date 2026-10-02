import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:german_lexicon_admin/features/auth/domain/admin_user_model.dart';
import 'package:german_lexicon_admin/features/lexicon/domain/models/lexicon_filter.dart';
import 'package:german_lexicon_admin/features/csv_export/domain/services/csv_serializer.dart';
import 'package:german_lexicon_admin/features/csv_export/presentation/controllers/csv_export_controller.dart';

class CsvExportScreen extends StatefulWidget {
  final CsvExportController controller;
  final AdminRole userRole;
  final VoidCallback? onNavigateToLexicon;

  const CsvExportScreen({
    super.key,
    required this.controller,
    required this.userRole,
    this.onNavigateToLexicon,
  });

  @override
  State<CsvExportScreen> createState() => _CsvExportScreenState();
}

class _CsvExportScreenState extends State<CsvExportScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.controller.filter.searchQuery ?? '';
    widget.controller.refreshCount();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onFilterChanged({
    String? cefr,
    String? pos,
    String? status,
    String? search,
  }) {
    final current = widget.controller.filter;
    final updated = current.copyWith(
      cefrLevel: cefr ?? current.cefrLevel,
      partOfSpeech: pos ?? current.partOfSpeech,
      status: status ?? current.status,
      searchQuery: search,
    );
    widget.controller.updateFilter(updated);
  }

  void _copyToClipboard(String content) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('CSV copied to clipboard!'),
        backgroundColor: Color(0xFF15803D),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final state = widget.controller.state;
        final filter = widget.controller.filter;
        final count = widget.controller.totalCount;
        final isBusy = state == CsvExportState.fetching ||
            state == CsvExportState.serializing;

        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Export Master Lexicon to CSV',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Download or copy dictionary entries in standard RFC 4180 CSV format (UTF-8 with BOM for Excel).',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (widget.onNavigateToLexicon != null) ...[
                      const SizedBox(width: 16),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.arrow_back, size: 16),
                        label: const Text('Back to Lexicon'),
                        onPressed: widget.onNavigateToLexicon,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 16),

                // Filters and Configuration Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Select Export Dataset & Filters',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Search bar
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Filter by German lemma...',
                                  prefixIcon: const Icon(Icons.search, size: 20),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, size: 18),
                                          onPressed: () {
                                            _searchController.clear();
                                            _onFilterChanged(search: null);
                                          },
                                        )
                                      : null,
                                ),
                                onSubmitted: (v) => _onFilterChanged(search: v),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () =>
                                  _onFilterChanged(search: _searchController.text),
                              child: const Text('Apply Filter'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () {
                                _searchController.clear();
                                widget.controller.resetFilter();
                              },
                              child: const Text('Reset All'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Dropdowns: CEFR, POS, Status
                        Row(
                          children: [
                            // CEFR
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: filter.cefrLevel ?? 'all',
                                decoration: const InputDecoration(
                                  labelText: 'CEFR Level',
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                ),
                                items: LexiconFilter.availableCefr
                                    .map((c) => DropdownMenuItem(
                                          value: c,
                                          child: Text(
                                            c == 'all' ? 'All Levels' : c,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (v) => _onFilterChanged(cefr: v),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // POS
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: filter.partOfSpeech ?? 'all',
                                decoration: const InputDecoration(
                                  labelText: 'Part of Speech',
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                ),
                                items: LexiconFilter.availablePos
                                    .map((p) => DropdownMenuItem(
                                          value: p,
                                          child: Text(
                                            p == 'all'
                                                ? 'All POS'
                                                : p[0].toUpperCase() +
                                                    p.substring(1),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (v) => _onFilterChanged(pos: v),
                              ),
                            ),
                            const SizedBox(width: 12),

                            // Status
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: filter.status ?? 'all',
                                decoration: const InputDecoration(
                                  labelText: 'Entry Status',
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 8),
                                ),
                                items: LexiconFilter.availableStatuses
                                    .map((s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(
                                            s == 'all'
                                                ? 'All Statuses'
                                                : s.toUpperCase(),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ))
                                    .toList(),
                                onChanged: (v) => _onFilterChanged(status: v),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Summary and Action button
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                    color: const Color(0xFFCBD5E1)),
                              ),
                              child: Text(
                                'Matched Entries: $count',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Color(0xFF334155),
                                ),
                              ),
                            ),
                            const Spacer(),
                            ElevatedButton.icon(
                              icon: isBusy
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Icon(Icons.file_download, size: 18),
                              label: Text(isBusy ? 'Exporting...' : 'Generate CSV Export'),
                              onPressed: isBusy
                                  ? null
                                  : () => widget.controller.runExport(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Error State
                if (state == CsvExportState.error) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      border: Border.all(color: const Color(0xFFF87171)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Color(0xFFDC2626)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.controller.errorMessage ??
                                'Export failed. Please check permissions.',
                            style: const TextStyle(
                                color: Color(0xFF991B1B), fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // Export Progress / Results
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: _buildExportContent(state),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExportContent(CsvExportState state) {
    if (state == CsvExportState.fetching || state == CsvExportState.serializing) {
      final fetched = widget.controller.fetchedCount;
      final total = widget.controller.totalCount;
      final progress = total > 0 ? fetched / total : null;

      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(value: progress),
            const SizedBox(height: 16),
            Text(
              state == CsvExportState.fetching
                  ? 'Fetching records from database ($fetched / $total)...'
                  : 'Serializing RFC 4180 CSV with UTF-8 BOM...',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Color(0xFF475569),
              ),
            ),
          ],
        ),
      );
    }

    if (state == CsvExportState.success) {
      final entries = widget.controller.entries;
      final csv = widget.controller.csvContent;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.check_circle, color: Color(0xFF16A34A), size: 20),
              const SizedBox(width: 8),
              Text(
                'Export Complete: ${entries.length} records generated successfully',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF166534),
                ),
              ),
              const Spacer(),
              OutlinedButton.icon(
                icon: const Icon(Icons.copy, size: 16),
                label: const Text('Copy to Clipboard'),
                onPressed: () => _copyToClipboard(csv),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // CSV Field headers preview
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: CsvSerializer.csvHeaders
                  .map(
                    (h) => Chip(
                      label: Text(h, style: const TextStyle(fontSize: 11)),
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          // Preview of CSV text
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A),
                borderRadius: BorderRadius.circular(6),
              ),
              child: SingleChildScrollView(
                child: SelectableText(
                  csv,
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    color: Color(0xFFF8FAFC),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Idle
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.table_chart_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text(
            'Ready to Export',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Configure your filters above and click "Generate CSV Export".',
            style: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
