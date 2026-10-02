import 'package:flutter/material.dart';
import 'package:german_lexicon_admin/features/auth/domain/admin_user_model.dart';
import 'package:german_lexicon_admin/features/lexicon/data/lexicon_repository.dart';
import 'package:german_lexicon_admin/features/lexicon/domain/models/lexicon_filter.dart';
import 'package:german_lexicon_admin/features/lexicon/domain/models/master_lexicon_entry.dart';
import 'package:german_lexicon_admin/features/lexicon/presentation/controllers/lexicon_controller.dart';
import 'package:german_lexicon_admin/features/lexicon/presentation/screens/word_detail_screen.dart';
import 'package:german_lexicon_admin/features/lexicon/presentation/widgets/cefr_badge.dart';
import 'package:german_lexicon_admin/features/lexicon/presentation/widgets/status_badge.dart';
import 'package:german_lexicon_admin/features/review/domain/models/review_queue_counts.dart';
import 'package:german_lexicon_admin/features/review/domain/models/review_queue_item.dart';
import 'package:german_lexicon_admin/features/review/presentation/controllers/review_queue_controller.dart';

class ReviewQueueScreen extends StatefulWidget {
  final ReviewQueueController controller;
  final LexiconRepository lexiconRepository;
  final AdminRole userRole;
  final LexiconController lexiconController;

  const ReviewQueueScreen({
    super.key,
    required this.controller,
    required this.lexiconRepository,
    required this.userRole,
    required this.lexiconController,
  });

  @override
  State<ReviewQueueScreen> createState() => _ReviewQueueScreenState();
}

class _ReviewQueueScreenState extends State<ReviewQueueScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.controller.searchQuery ?? '';
    widget.controller.refresh();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _inspectItem(ReviewQueueItem item) async {
    // Fetch parent entry if needed
    MasterLexiconEntry? entry = item.rawMasterEntry;
    if (entry == null) {
      try {
        entry = await widget.lexiconRepository.getEntryById(item.entryId);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not load parent word: $e'),
            backgroundColor: const Color(0xFFDC2626),
          ),
        );
        return;
      }
    }

    if (!mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => WordDetailScreen(
          initialEntry: entry!,
          repository: widget.lexiconRepository,
          userRole: widget.userRole,
          listController: widget.lexiconController,
        ),
      ),
    );

    // Refresh review queue upon returning
    if (mounted) {
      widget.controller.refresh();
    }
  }

  Future<void> _handleVerify(ReviewQueueItem item) async {
    final success = await widget.controller.verifyItem(item);
    if (mounted && success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Verified "${item.title}" successfully!'),
          backgroundColor: const Color(0xFF15803D),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _handleReject(ReviewQueueItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reject Review Item'),
        content: Text(
          'Are you sure you want to mark this item as REJECTED?\n\n'
          'Item: "${item.title}"\n'
          'Category: ${item.category.label}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Reject Item'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await widget.controller.rejectItem(item);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Rejected "${item.title}". Status updated to rejected.'),
            backgroundColor: const Color(0xFFB91C1C),
            duration: const Duration(seconds: 2),
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
        final counts = controller.counts;
        final items = controller.items;
        final role = widget.userRole;
        final canReview = role == AdminRole.reviewer || role == AdminRole.superadmin;

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
                          Row(
                            children: [
                              const Text(
                                'Review Queue',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 3),
                                decoration: BoxDecoration(
                                  color: counts.totalCount > 0
                                      ? const Color(0xFFFEF3C7)
                                      : const Color(0xFFDCFCE7),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: counts.totalCount > 0
                                        ? const Color(0xFFF59E0B)
                                        : const Color(0xFF22C55E),
                                  ),
                                ),
                                child: Text(
                                  '${counts.totalCount} Pending',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: counts.totalCount > 0
                                        ? const Color(0xFFB45309)
                                        : const Color(0xFF15803D),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Quality control workspace: verify or reject pending vocabulary, translations, and examples.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh),
                      tooltip: 'Refresh Queue',
                      onPressed: controller.refresh,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Category Selector Bar with live badges
                _buildCategoryTabs(controller, counts),
                const SizedBox(height: 16),
                // Filters Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search German word in review...',
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
                        const SizedBox(width: 12),
                        // CEFR Filter
                        SizedBox(
                          width: 140,
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: controller.cefrFilter ?? 'all',
                            decoration: const InputDecoration(
                              labelText: 'CEFR Level',
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                            ),
                            items: LexiconFilter.availableCefr
                                .map((c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(c == 'all' ? 'All' : c),
                                    ))
                                .toList(),
                            onChanged: (v) => controller.setCefrFilter(v),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // POS Filter
                        SizedBox(
                          width: 140,
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            initialValue: controller.posFilter ?? 'all',
                            decoration: const InputDecoration(
                              labelText: 'POS',
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 8),
                            ),
                            items: LexiconFilter.availablePos
                                .map((p) => DropdownMenuItem(
                                      value: p,
                                      child: Text(p == 'all' ? 'All' : p),
                                    ))
                                .toList(),
                            onChanged: (v) => controller.setPosFilter(v),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
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
                          onPressed: controller.loadQueueItems,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ],
                // Main Table Content
                Expanded(
                  child: Card(
                    child: controller.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : items.isEmpty
                            ? _buildEmptyState(controller.activeCategory)
                            : _buildQueueTable(items, canReview),
                  ),
                ),
                const SizedBox(height: 12),
                // Pagination Bar
                _buildPaginationBar(controller),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryTabs(
      ReviewQueueController controller, ReviewQueueCounts counts) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildCategoryChip(
            controller,
            category: ReviewCategory.masterWords,
            count: counts.masterCount,
            icon: Icons.menu_book,
          ),
          const SizedBox(width: 8),
          _buildCategoryChip(
            controller,
            category: ReviewCategory.translations,
            count: counts.translationsCount,
            icon: Icons.translate,
          ),
          const SizedBox(width: 8),
          _buildCategoryChip(
            controller,
            category: ReviewCategory.senses,
            count: counts.sensesCount,
            icon: Icons.psychology,
          ),
          const SizedBox(width: 8),
          _buildCategoryChip(
            controller,
            category: ReviewCategory.synonyms,
            count: counts.synonymsCount,
            icon: Icons.compare_arrows,
          ),
          const SizedBox(width: 8),
          _buildCategoryChip(
            controller,
            category: ReviewCategory.examples,
            count: counts.examplesCount,
            icon: Icons.format_quote,
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(
    ReviewQueueController controller, {
    required ReviewCategory category,
    required int count,
    required IconData icon,
  }) {
    final isSelected = controller.activeCategory == category;

    return InkWell(
      onTap: () => controller.selectCategory(category),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF2563EB) : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2563EB)
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            const SizedBox(width: 8),
            Text(
              category.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected ? Colors.white : const Color(0xFF334155),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.white.withValues(alpha: 0.25)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : const Color(0xFF475569),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(ReviewCategory category) {
    String message;
    switch (category) {
      case ReviewCategory.masterWords:
        message = 'No master words are waiting for review.';
        break;
      case ReviewCategory.translations:
        message = 'No translations are waiting for review.';
        break;
      case ReviewCategory.senses:
        message = 'No senses are waiting for review.';
        break;
      case ReviewCategory.synonyms:
        message = 'No synonyms are waiting for review.';
        break;
      case ReviewCategory.examples:
        message = 'No examples are waiting for review.';
        break;
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.done_all, size: 48, color: Color(0xFF16A34A)),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF334155),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'All items in this category are verified or up-to-date.',
            style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueTable(List<ReviewQueueItem> items, bool canReview) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowColor:
                    WidgetStateProperty.all(const Color(0xFFF8FAFC)),
                columns: const [
                  DataColumn(label: Text('German Word')),
                  DataColumn(label: Text('Item Under Review')),
                  DataColumn(label: Text('Context / Details')),
                  DataColumn(label: Text('POS')),
                  DataColumn(label: Text('CEFR')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Updated')),
                  DataColumn(label: Text('Actions')),
                ],
                rows: items.map((item) {
                  return DataRow(
                    cells: [
                      DataCell(
                        InkWell(
                          onTap: () => _inspectItem(item),
                          child: Text(
                            item.parentLemma,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            if (item.subtitle != null) ...[
                              Text(
                                item.subtitle!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      DataCell(
                        Text(
                          item.details ?? '—',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                      DataCell(Text(item.partOfSpeech ?? '—')),
                      DataCell(
                        item.cefrLevel != null
                            ? CefrBadge(cefr: item.cefrLevel!)
                            : const Text('—'),
                      ),
                      DataCell(StatusBadge(status: item.status)),
                      DataCell(
                        Text(
                          '${item.updatedAt.toLocal().year}-${item.updatedAt.toLocal().month.toString().padLeft(2, '0')}-${item.updatedAt.toLocal().day.toString().padLeft(2, '0')}',
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
                              tooltip: 'Inspect Full Word Context',
                              onPressed: () => _inspectItem(item),
                            ),
                            if (canReview) ...[
                              IconButton(
                                icon: const Icon(Icons.check_circle_outline,
                                    size: 18, color: Color(0xFF16A34A)),
                                tooltip: 'Verify & Approve',
                                onPressed: () => _handleVerify(item),
                              ),
                              IconButton(
                                icon: const Icon(Icons.cancel_outlined,
                                    size: 18, color: Color(0xFFDC2626)),
                                tooltip: 'Reject',
                                onPressed: () => _handleReject(item),
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

  Widget _buildPaginationBar(ReviewQueueController controller) {
    final start = ((controller.page - 1) * controller.pageSize) + 1;
    final end = (start + controller.items.length - 1).clamp(0, controller.totalCount);

    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        child: Row(
          children: [
            Text(
              controller.totalCount == 0
                  ? '0 pending review'
                  : 'Showing $start–$end of ${controller.totalCount} pending items',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.chevron_left),
              tooltip: 'Previous Page',
              onPressed: controller.hasPreviousPage
                  ? () => controller.setPage(controller.page - 1)
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'Page ${controller.page} of ${controller.totalPages}',
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.chevron_right),
              tooltip: 'Next Page',
              onPressed: controller.hasNextPage
                  ? () => controller.setPage(controller.page + 1)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
