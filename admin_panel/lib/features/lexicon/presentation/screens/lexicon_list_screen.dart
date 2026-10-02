import 'package:flutter/material.dart';
import '../../../auth/domain/admin_user_model.dart';
import '../../data/lexicon_repository.dart';
import '../../domain/models/bulk_action_result.dart';
import '../../domain/models/lexicon_filter.dart';
import '../../domain/models/master_lexicon_entry.dart';
import '../controllers/lexicon_controller.dart';
import '../widgets/add_word_dialog.dart';
import '../widgets/cefr_badge.dart';
import '../widgets/edit_word_dialog.dart';
import '../widgets/quality_badge.dart';
import '../widgets/status_badge.dart';
import 'word_detail_screen.dart';

class LexiconListScreen extends StatefulWidget {
  final LexiconController controller;
  final LexiconRepository repository;
  final AdminRole userRole;
  final VoidCallback? onNavigateToExport;

  const LexiconListScreen({
    super.key,
    required this.controller,
    required this.repository,
    required this.userRole,
    this.onNavigateToExport,
  });

  @override
  State<LexiconListScreen> createState() => _LexiconListScreenState();
}

class _LexiconListScreenState extends State<LexiconListScreen> {
  final _searchController = TextEditingController();
  bool _isAdvancedFiltersExpanded = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.controller.filter.searchQuery ?? '';
    widget.controller.loadEntries();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _openAddWordDialog() async {
    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => AddWordDialog(
        controller: widget.controller,
        userRole: widget.userRole,
      ),
    );
    if (added == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Word successfully added to Master Lexicon!'),
          backgroundColor: Color(0xFF15803D),
        ),
      );
    }
  }

  Future<void> _openEditWordDialog(MasterLexiconEntry entry) async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => EditWordDialog(
        entry: entry,
        controller: widget.controller,
        userRole: widget.userRole,
      ),
    );
    if (updated == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Word updated successfully.'),
          backgroundColor: Color(0xFF15803D),
        ),
      );
    }
  }

  void _openWordDetail(MasterLexiconEntry entry) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => WordDetailScreen(
          initialEntry: entry,
          repository: widget.repository,
          userRole: widget.userRole,
          listController: widget.controller,
        ),
      ),
    );
  }

  Future<void> _confirmAndExecuteBulkAction({
    required String actionTitle,
    required String actionDescription,
    required Future<BulkActionResult> Function() onExecute,
  }) async {
    final selectedEntries = widget.controller.selectedEntries;
    final count = selectedEntries.length;
    if (count == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(actionTitle),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 450, maxHeight: 300),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You are about to $actionDescription for $count selected record(s):',
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: selectedEntries.length,
                    itemBuilder: (c, idx) {
                      final item = selectedEntries[idx];
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2.0),
                        child: Text(
                          '• ${item.lemma} (${item.partOfSpeech.toUpperCase()}, ${item.cefrLevel})',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF334155)),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'This action will be processed and logged. Do you want to proceed?',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Confirm Action'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final res = await onExecute();
      if (!mounted) return;

      if (res.isFullSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully updated all ${res.successCount} record(s).'),
            backgroundColor: const Color(0xFF15803D),
          ),
        );
      } else {
        // Show result dialog with failures
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(res.isPartialSuccess ? 'Action Partially Succeeded' : 'Bulk Action Failed'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Succeeded: ${res.successCount}'),
                Text('Failed: ${res.failureCount}', style: const TextStyle(color: Color(0xFFDC2626))),
                const SizedBox(height: 8),
                const Text('Errors per record:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                const SizedBox(height: 4),
                ...res.failureErrors.entries.take(5).map((e) => Text(
                      '• ID ${e.key.substring(0, 8)}...: ${e.value}',
                      style: const TextStyle(fontSize: 11, color: Color(0xFFB91C1C)),
                    )),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text('Close'),
              ),
            ],
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
        final entries = controller.entries;
        final filter = controller.filter;
        final selectedCount = controller.selectedCount;

        return Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Header Row
                Row(
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Master German Lexicon',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Authoritative dictionary entries with verified translations and examples.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    if (widget.onNavigateToExport != null) ...[
                      OutlinedButton.icon(
                        icon: const Icon(Icons.file_download_outlined, size: 18),
                        label: const Text('Export CSV'),
                        onPressed: widget.onNavigateToExport,
                      ),
                      const SizedBox(width: 8),
                    ],
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Add Word'),
                      onPressed: _openAddWordDialog,
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Search and Filters Bar
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            // Search field
                            Expanded(
                              flex: 3,
                              child: TextField(
                                controller: _searchController,
                                decoration: InputDecoration(
                                  hintText: 'Search German lemma or word...',
                                  prefixIcon: const Icon(Icons.search, size: 20),
                                  suffixIcon: _searchController.text.isNotEmpty
                                      ? IconButton(
                                          icon: const Icon(Icons.clear, size: 18),
                                          onPressed: () {
                                            _searchController.clear();
                                            controller.setSearchQuery(null);
                                          },
                                        )
                                      : null,
                                ),
                                onSubmitted: (v) => controller.setSearchQuery(v),
                              ),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () => controller
                                  .setSearchQuery(_searchController.text),
                              child: const Text('Search'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton.icon(
                              icon: Icon(
                                _isAdvancedFiltersExpanded
                                    ? Icons.filter_list_off
                                    : Icons.tune,
                                size: 18,
                              ),
                              label: Text(
                                filter.hasAdvancedFilters
                                    ? 'Filters (Active)'
                                    : 'Advanced Filters',
                              ),
                              onPressed: () {
                                setState(() {
                                  _isAdvancedFiltersExpanded = !_isAdvancedFiltersExpanded;
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Standard Filter Dropdowns
                        Row(
                          children: [
                            // CEFR Filter
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: filter.cefrLevel ?? 'all',
                                decoration: const InputDecoration(
                                  labelText: 'CEFR Level',
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                                items: LexiconFilter.availableCefr
                                    .map((c) => DropdownMenuItem(
                                          value: c,
                                          child: Text(c == 'all'
                                              ? 'All Levels'
                                              : c),
                                        ))
                                    .toList(),
                                onChanged: (v) => controller.setCefrFilter(v),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // POS Filter
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: filter.partOfSpeech ?? 'all',
                                decoration: const InputDecoration(
                                  labelText: 'Part of Speech',
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                                items: LexiconFilter.availablePos
                                    .map((p) => DropdownMenuItem(
                                          value: p,
                                          child: Text(p == 'all' ? 'All POS' : p),
                                        ))
                                    .toList(),
                                onChanged: (v) => controller.setPosFilter(v),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Status Filter
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: filter.status ?? 'all',
                                decoration: const InputDecoration(
                                  labelText: 'Status',
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                                items: LexiconFilter.availableStatuses
                                    .map((s) => DropdownMenuItem(
                                          value: s,
                                          child: Text(s == 'all'
                                              ? 'All Statuses'
                                              : s.toUpperCase()),
                                        ))
                                    .toList(),
                                onChanged: (v) => controller.setStatusFilter(v),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Page size selector
                            SizedBox(
                              width: 120,
                              child: DropdownButtonFormField<int>(
                                initialValue: filter.pageSize,
                                decoration: const InputDecoration(
                                  labelText: 'Per Page',
                                  contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 10, child: Text('10')),
                                  DropdownMenuItem(value: 15, child: Text('15')),
                                  DropdownMenuItem(value: 25, child: Text('25')),
                                  DropdownMenuItem(value: 50, child: Text('50')),
                                ],
                                onChanged: (v) {
                                  if (v != null) controller.setPageSize(v);
                                },
                              ),
                            ),
                          ],
                        ),

                        // Expandable Advanced Filters Panel
                        if (_isAdvancedFiltersExpanded) ...[
                          const Divider(height: 24),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Text(
                                    'Detailed Quality & Content Filters',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF334155),
                                    ),
                                  ),
                                  const Spacer(),
                                  if (filter.hasAdvancedFilters)
                                    TextButton.icon(
                                      icon: const Icon(Icons.clear, size: 16),
                                      label: const Text('Reset Advanced Filters'),
                                      onPressed: () => controller.clearAdvancedFilters(),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Wrap(
                                spacing: 12,
                                runSpacing: 12,
                                children: [
                                  // Gender / Article Filter
                                  SizedBox(
                                    width: 160,
                                    child: DropdownButtonFormField<String>(
                                      initialValue: filter.gender ?? 'all',
                                      decoration: const InputDecoration(
                                        labelText: 'Gender / Article',
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      ),
                                      items: LexiconFilter.availableGenders
                                          .map((g) => DropdownMenuItem(
                                                value: g,
                                                child: Text(g == 'all' ? 'All Genders' : g),
                                              ))
                                          .toList(),
                                      onChanged: (v) => controller.setGenderFilter(v),
                                    ),
                                  ),

                                  // Has/Missing EN
                                  SizedBox(
                                    width: 150,
                                    child: DropdownButtonFormField<bool?>(
                                      initialValue: filter.hasEnTranslation,
                                      decoration: const InputDecoration(
                                        labelText: 'English (EN)',
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      ),
                                      items: const [
                                        DropdownMenuItem(value: null, child: Text('All')),
                                        DropdownMenuItem(value: true, child: Text('Has EN')),
                                        DropdownMenuItem(value: false, child: Text('Missing EN')),
                                      ],
                                      onChanged: (v) => controller.setFilterHasTranslation(
                                        en: v,
                                        ur: filter.hasUrTranslation,
                                        fa: filter.hasFaTranslation,
                                        ar: filter.hasArTranslation,
                                      ),
                                    ),
                                  ),

                                  // Has/Missing UR
                                  SizedBox(
                                    width: 150,
                                    child: DropdownButtonFormField<bool?>(
                                      initialValue: filter.hasUrTranslation,
                                      decoration: const InputDecoration(
                                        labelText: 'Urdu (UR)',
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      ),
                                      items: const [
                                        DropdownMenuItem(value: null, child: Text('All')),
                                        DropdownMenuItem(value: true, child: Text('Has UR')),
                                        DropdownMenuItem(value: false, child: Text('Missing UR')),
                                      ],
                                      onChanged: (v) => controller.setFilterHasTranslation(
                                        en: filter.hasEnTranslation,
                                        ur: v,
                                        fa: filter.hasFaTranslation,
                                        ar: filter.hasArTranslation,
                                      ),
                                    ),
                                  ),

                                  // Has/Missing FA
                                  SizedBox(
                                    width: 150,
                                    child: DropdownButtonFormField<bool?>(
                                      initialValue: filter.hasFaTranslation,
                                      decoration: const InputDecoration(
                                        labelText: 'Farsi (FA)',
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      ),
                                      items: const [
                                        DropdownMenuItem(value: null, child: Text('All')),
                                        DropdownMenuItem(value: true, child: Text('Has FA')),
                                        DropdownMenuItem(value: false, child: Text('Missing FA')),
                                      ],
                                      onChanged: (v) => controller.setFilterHasTranslation(
                                        en: filter.hasEnTranslation,
                                        ur: filter.hasUrTranslation,
                                        fa: v,
                                        ar: filter.hasArTranslation,
                                      ),
                                    ),
                                  ),

                                  // Has/Missing AR
                                  SizedBox(
                                    width: 150,
                                    child: DropdownButtonFormField<bool?>(
                                      initialValue: filter.hasArTranslation,
                                      decoration: const InputDecoration(
                                        labelText: 'Arabic (AR)',
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      ),
                                      items: const [
                                        DropdownMenuItem(value: null, child: Text('All')),
                                        DropdownMenuItem(value: true, child: Text('Has AR')),
                                        DropdownMenuItem(value: false, child: Text('Missing AR')),
                                      ],
                                      onChanged: (v) => controller.setFilterHasTranslation(
                                        en: filter.hasEnTranslation,
                                        ur: filter.hasUrTranslation,
                                        fa: filter.hasFaTranslation,
                                        ar: v,
                                      ),
                                    ),
                                  ),

                                  // Has/Missing Examples
                                  SizedBox(
                                    width: 160,
                                    child: DropdownButtonFormField<bool?>(
                                      initialValue: filter.hasExample,
                                      decoration: const InputDecoration(
                                        labelText: 'Examples',
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      ),
                                      items: const [
                                        DropdownMenuItem(value: null, child: Text('All')),
                                        DropdownMenuItem(value: true, child: Text('Has Examples')),
                                        DropdownMenuItem(value: false, child: Text('Missing Examples')),
                                      ],
                                      onChanged: (v) => controller.setFilterCompleteness(
                                        hasExample: v,
                                        hasSense: filter.hasSense,
                                        hasSynonym: filter.hasSynonym,
                                      ),
                                    ),
                                  ),

                                  // Has/Missing Senses
                                  SizedBox(
                                    width: 160,
                                    child: DropdownButtonFormField<bool?>(
                                      initialValue: filter.hasSense,
                                      decoration: const InputDecoration(
                                        labelText: 'Senses / Definitions',
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      ),
                                      items: const [
                                        DropdownMenuItem(value: null, child: Text('All')),
                                        DropdownMenuItem(value: true, child: Text('Has Senses')),
                                        DropdownMenuItem(value: false, child: Text('Missing Senses')),
                                      ],
                                      onChanged: (v) => controller.setFilterCompleteness(
                                        hasExample: filter.hasExample,
                                        hasSense: v,
                                        hasSynonym: filter.hasSynonym,
                                      ),
                                    ),
                                  ),

                                  // Has/Missing Synonyms
                                  SizedBox(
                                    width: 160,
                                    child: DropdownButtonFormField<bool?>(
                                      initialValue: filter.hasSynonym,
                                      decoration: const InputDecoration(
                                        labelText: 'Synonyms',
                                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      ),
                                      items: const [
                                        DropdownMenuItem(value: null, child: Text('All')),
                                        DropdownMenuItem(value: true, child: Text('Has Synonyms')),
                                        DropdownMenuItem(value: false, child: Text('Missing Synonyms')),
                                      ],
                                      onChanged: (v) => controller.setFilterCompleteness(
                                        hasExample: filter.hasExample,
                                        hasSense: filter.hasSense,
                                        hasSynonym: v,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),

                // Sticky Bulk Action Bar (Visible when selectedCount > 0)
                if (selectedCount > 0) ...[
                  _buildBulkActionBar(controller),
                  const SizedBox(height: 12),
                ],

                // Error banner if any
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
                        const Icon(Icons.error_outline,
                            color: Color(0xFFB91C1C), size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            controller.errorMessage!,
                            style: const TextStyle(
                                color: Color(0xFF991B1B), fontSize: 13),
                          ),
                        ),
                        TextButton(
                          onPressed: controller.loadEntries,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ],

                // Main Content Table / List
                Expanded(
                  child: Card(
                    child: controller.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : entries.isEmpty
                            ? _buildEmptyState()
                            : _buildLexiconTable(entries, controller),
                  ),
                ),
                const SizedBox(height: 12),

                // Pagination Controls
                _buildPaginationBar(controller),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildBulkActionBar(LexiconController controller) {
    final count = controller.selectedCount;
    final isEditor = widget.userRole == AdminRole.editor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            offset: const Offset(0, 2),
            blurRadius: 8,
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.check_box_outlined, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Text(
            '$count selected',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 16),

          // Move to Review (Permitted for all authenticated roles)
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF64748B)),
            ),
            icon: const Icon(Icons.rate_review_outlined, size: 16),
            label: const Text('Move to Review'),
            onPressed: () => _confirmAndExecuteBulkAction(
              actionTitle: 'Move to Review Queue',
              actionDescription: 'set the status to "REVIEW"',
              onExecute: () => controller.bulkMoveToReview(),
            ),
          ),
          const SizedBox(width: 8),

          // Approve/Verify (Reviewer / Superadmin only)
          if (!isEditor) ...[
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF15803D),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.verified_outlined, size: 16),
              label: const Text('Verify Selected'),
              onPressed: () => _confirmAndExecuteBulkAction(
                actionTitle: 'Bulk Verify Words',
                actionDescription: 'set the status to "VERIFIED" and publish',
                onExecute: () => controller.bulkVerify(userRole: widget.userRole),
              ),
            ),
            const SizedBox(width: 8),
            // Reject (Reviewer / Superadmin only)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.block_outlined, size: 16),
              label: const Text('Reject Selected'),
              onPressed: () => _confirmAndExecuteBulkAction(
                actionTitle: 'Bulk Reject Words',
                actionDescription: 'set the status to "REJECTED"',
                onExecute: () => controller.bulkReject(userRole: widget.userRole),
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Bulk Assign CEFR
          PopupMenuButton<String>(
            tooltip: 'Assign CEFR Level',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF64748B)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Assign CEFR', style: TextStyle(color: Colors.white, fontSize: 13)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
                ],
              ),
            ),
            onSelected: (cefr) => _confirmAndExecuteBulkAction(
              actionTitle: 'Assign CEFR $cefr',
              actionDescription: 'update CEFR level to $cefr',
              onExecute: () => controller.bulkAssignCefr(cefrLevel: cefr),
            ),
            itemBuilder: (ctx) => ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']
                .map((c) => PopupMenuItem(value: c, child: Text('Assign $c')))
                .toList(),
          ),

          const Spacer(),
          TextButton(
            onPressed: () => controller.clearSelection(),
            child: const Text('Deselect All', style: TextStyle(color: Color(0xFF94A3B8))),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.search_off, size: 48, color: Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          const Text(
            'No Master Lexicon entries found.',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Try adjusting search terms or filters, or add a new word.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add First Word'),
            onPressed: _openAddWordDialog,
          ),
        ],
      ),
    );
  }

  Widget _buildLexiconTable(List<MasterLexiconEntry> entries, LexiconController controller) {
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
                columns: [
                  DataColumn(
                    label: Checkbox(
                      value: controller.isAllSelected,
                      onChanged: (_) => controller.selectAllVisible(),
                    ),
                  ),
                  const DataColumn(label: Text('German Word')),
                  const DataColumn(label: Text('Article')),
                  const DataColumn(label: Text('POS')),
                  const DataColumn(label: Text('CEFR')),
                  const DataColumn(label: Text('Status')),
                  const DataColumn(label: Text('Quality')),
                  const DataColumn(label: Text('Plural Form')),
                  const DataColumn(label: Text('Provenance / Notes')),
                  const DataColumn(label: Text('Updated')),
                  const DataColumn(label: Text('Actions')),
                ],
                rows: entries.map((entry) {
                  final isSelected = controller.selectedEntryIds.contains(entry.id);
                  return DataRow(
                    selected: isSelected,
                    onSelectChanged: (_) => controller.toggleSelection(entry.id),
                    cells: [
                      DataCell(
                        Checkbox(
                          value: isSelected,
                          onChanged: (_) => controller.toggleSelection(entry.id),
                        ),
                      ),
                      DataCell(
                        InkWell(
                          onTap: () => _openWordDetail(entry),
                          child: Text(
                            entry.lemma,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text(entry.gender ?? '—')),
                      DataCell(Text(entry.partOfSpeech)),
                      DataCell(CefrBadge(cefr: entry.cefrLevel)),
                      DataCell(StatusBadge(status: entry.status)),
                      DataCell(QualityBadge(quality: entry.quality)),
                      DataCell(Text(entry.pluralForm ?? '—')),
                      DataCell(
                        Text(
                          entry.provenance ?? '—',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      DataCell(
                        Text(
                          '${entry.updatedAt.toLocal().year}-${entry.updatedAt.toLocal().month.toString().padLeft(2, '0')}-${entry.updatedAt.toLocal().day.toString().padLeft(2, '0')}',
                          style: const TextStyle(
                              fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ),
                      DataCell(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.visibility_outlined,
                                  size: 18),
                              tooltip: 'View Details',
                              onPressed: () => _openWordDetail(entry),
                            ),
                            if (entry.canEdit(widget.userRole)) ...[
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                tooltip: 'Edit',
                                onPressed: () => _openEditWordDialog(entry),
                              ),
                            ],
                          ],
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

  Widget _buildPaginationBar(LexiconController controller) {
    final start = ((controller.filter.page - 1) * controller.filter.pageSize) + 1;
    final end = (start + controller.entries.length - 1).clamp(0, controller.totalCount);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Text(
              controller.totalCount == 0
                  ? '0 entries'
                  : 'Showing $start–$end of ${controller.totalCount} entries',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Previous Page',
              onPressed: controller.hasPreviousPage
                  ? () => controller.setPage(controller.filter.page - 1)
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'Page ${controller.filter.page} of ${controller.totalPages}',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Next Page',
              onPressed: controller.hasNextPage
                  ? () => controller.setPage(controller.filter.page + 1)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
