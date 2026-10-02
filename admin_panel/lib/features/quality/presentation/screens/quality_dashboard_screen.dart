import 'package:flutter/material.dart';
import '../../../auth/domain/admin_user_model.dart';
import '../../domain/services/duplicate_detector.dart';
import '../controllers/quality_dashboard_controller.dart';

class QualityDashboardScreen extends StatefulWidget {
  final QualityDashboardController controller;
  final AdminRole userRole;
  final VoidCallback? onNavigateToLexicon;
  final VoidCallback? onNavigateToReviewQueue;
  final void Function(Map<String, dynamic> filters)? onApplyLexiconFilter;

  const QualityDashboardScreen({
    super.key,
    required this.controller,
    required this.userRole,
    this.onNavigateToLexicon,
    this.onNavigateToReviewQueue,
    this.onApplyLexiconFilter,
  });

  @override
  State<QualityDashboardScreen> createState() => _QualityDashboardScreenState();
}

class _QualityDashboardScreenState extends State<QualityDashboardScreen> {
  @override
  void initState() {
    super.initState();
    widget.controller.refresh();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;
        final stats = controller.stats;

        if (controller.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return Scaffold(
          body: SingleChildScrollView(
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
                          'Lexicon Quality Dashboard',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'A1–B2 German vocabulary completeness, CEFR progression, and quality metrics.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Refresh Metrics'),
                      onPressed: () => controller.refresh(),
                    ),
                    const SizedBox(width: 8),
                    if (widget.onNavigateToLexicon != null) ...[
                      ElevatedButton.icon(
                        icon: const Icon(Icons.menu_book, size: 18),
                        label: const Text('Master Lexicon'),
                        onPressed: widget.onNavigateToLexicon,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),

                // Primary Metrics Cards Row
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 900;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        _buildMetricCard(
                          title: 'Total Master Words',
                          value: '${stats.totalWords}',
                          subtitle: 'Total authoritative lemmas in catalog',
                          icon: Icons.auto_stories_outlined,
                          color: const Color(0xFF2563EB),
                          width: isWide ? (constraints.maxWidth - 48) / 4 : constraints.maxWidth,
                        ),
                        _buildMetricCard(
                          title: 'Verified Entries',
                          value: '${stats.verifiedCount}',
                          subtitle: 'Publicly visible authoritative entries',
                          icon: Icons.verified_outlined,
                          color: const Color(0xFF16A34A),
                          width: isWide ? (constraints.maxWidth - 48) / 4 : constraints.maxWidth,
                        ),
                        _buildMetricCard(
                          title: 'In Review Queue',
                          value: '${stats.reviewCount}',
                          subtitle: 'Awaiting reviewer/superadmin verification',
                          icon: Icons.rate_review_outlined,
                          color: const Color(0xFFD97706),
                          width: isWide ? (constraints.maxWidth - 48) / 4 : constraints.maxWidth,
                        ),
                        _buildMetricCard(
                          title: 'Draft Entries',
                          value: '${stats.draftCount}',
                          subtitle: 'Draft candidate records in progress',
                          icon: Icons.edit_note_outlined,
                          color: const Color(0xFF64748B),
                          width: isWide ? (constraints.maxWidth - 48) / 4 : constraints.maxWidth,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // CEFR Level Progression Matrix
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.stairs_outlined, color: Color(0xFF2563EB), size: 22),
                            SizedBox(width: 8),
                            Text(
                              'CEFR Level Progression (A1–B2 Focus)',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            _buildCefrChip('A1', stats.a1Count, const Color(0xFF10B981)),
                            const SizedBox(width: 12),
                            _buildCefrChip('A2', stats.a2Count, const Color(0xFF06B6D4)),
                            const SizedBox(width: 12),
                            _buildCefrChip('B1', stats.b1Count, const Color(0xFF3B82F6)),
                            const SizedBox(width: 12),
                            _buildCefrChip('B2', stats.b2Count, const Color(0xFF8B5CF6)),
                            const SizedBox(width: 12),
                            _buildCefrChip('C1', stats.c1Count, const Color(0xFFEC4899)),
                            const SizedBox(width: 12),
                            _buildCefrChip('C2', stats.c2Count, const Color(0xFFEF4444)),
                            const SizedBox(width: 12),
                            _buildCefrChip('Unclassified', stats.unclassifiedCount, const Color(0xFF94A3B8)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Quality Deficiencies Matrix (Translations, Grammar, Lexical)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Missing Translations Card
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.translate, color: Color(0xFF0284C7), size: 22),
                                  SizedBox(width: 8),
                                  Text(
                                    'Missing Translations',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildDeficiencyRow('Missing English (EN)', stats.missingEnCount),
                              const Divider(height: 16),
                              _buildDeficiencyRow('Missing Urdu (UR)', stats.missingUrCount),
                              const Divider(height: 16),
                              _buildDeficiencyRow('Missing Farsi (FA)', stats.missingFaCount),
                              const Divider(height: 16),
                              _buildDeficiencyRow('Missing Arabic (AR)', stats.missingArCount),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Grammatical & Lexical Richness Card
                    Expanded(
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.menu_book, color: Color(0xFF7C3AED), size: 22),
                                  SizedBox(width: 8),
                                  Text(
                                    'Grammar & Lexical Richness',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              _buildDeficiencyRow('Nouns Missing Article (der/die/das)', stats.missingGenderCount),
                              const Divider(height: 16),
                              _buildDeficiencyRow('Nouns Missing Plural Form', stats.missingPluralCount),
                              const Divider(height: 16),
                              _buildDeficiencyRow('Words Missing Senses / Definitions', stats.missingSenseCount),
                              const Divider(height: 16),
                              _buildDeficiencyRow('Words Missing Usage Examples', stats.missingExampleCount),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Duplicate Detection Section
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.copy_outlined, color: Color(0xFFD97706), size: 22),
                            const SizedBox(width: 8),
                            const Text(
                              'Duplicate Candidate Detection',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF3C7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${controller.duplicates.length} detected',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFFB45309),
                                ),
                              ),
                            ),
                            const Spacer(),
                            if (controller.isDuplicatesLoading) ...[
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ] else ...[
                              TextButton.icon(
                                icon: const Icon(Icons.search, size: 16),
                                label: const Text('Scan Duplicates'),
                                onPressed: () => controller.loadDuplicates(),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Detects exact normalized collisions, spelling/umlaut variations (ä vs ae), and punctuation variants. Records are NOT merged automatically; human review required.',
                          style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 16),
                        if (controller.duplicates.isEmpty) ...[
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE2E8F0)),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.check_circle_outline, color: Color(0xFF16A34A), size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'No duplicates or variant conflicts detected in current dictionary sample.',
                                  style: TextStyle(fontSize: 13, color: Color(0xFF334155)),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: controller.duplicates.length,
                            separatorBuilder: (_, _) => const Divider(height: 12),
                            itemBuilder: (context, index) {
                              final dup = controller.duplicates[index];
                              return _buildDuplicateItem(dup);
                            },
                          ),
                        ],
                      ],
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

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const Spacer(),
              Text(
                value,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildCefrChip(String level, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Text(
              level,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$count',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeficiencyRow(String label, int count) {
    final isClear = count == 0;
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 13, color: Color(0xFF334155)),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isClear ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isClear ? const Color(0xFF166534) : const Color(0xFF991B1B),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDuplicateItem(DuplicateCandidate dup) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFD97706), size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      dup.type.label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF92400E),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${(dup.confidence * 100).toInt()}% match',
                        style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  dup.description,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF78350F)),
                ),
                if (dup.entryB != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Entry 1: "${dup.entryA.lemma}" (${dup.entryA.partOfSpeech}) [${dup.entryA.status}]   vs   Entry 2: "${dup.entryB!.lemma}" (${dup.entryB!.partOfSpeech}) [${dup.entryB!.status}]',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF451A03)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
