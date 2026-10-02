import 'package:flutter/material.dart';
import '../../../auth/domain/admin_user_model.dart';
import '../../data/lexicon_repository.dart';
import '../../domain/models/lexicon_example.dart';
import '../../domain/models/lexicon_sense.dart';
import '../../domain/models/lexicon_synonym.dart';
import '../../domain/models/lexicon_translation.dart';
import '../../domain/models/master_lexicon_entry.dart';
import '../controllers/lexicon_controller.dart';
import '../controllers/word_detail_controller.dart';
import '../widgets/cefr_badge.dart';
import '../widgets/edit_word_dialog.dart';
import '../widgets/example_dialog.dart';
import '../widgets/sense_dialog.dart';
import '../widgets/status_badge.dart';
import '../widgets/synonym_dialog.dart';
import '../widgets/translation_dialog.dart';

class WordDetailScreen extends StatefulWidget {
  final MasterLexiconEntry initialEntry;
  final LexiconRepository repository;
  final AdminRole userRole;
  final LexiconController listController;

  const WordDetailScreen({
    super.key,
    required this.initialEntry,
    required this.repository,
    required this.userRole,
    required this.listController,
  });

  @override
  State<WordDetailScreen> createState() => _WordDetailScreenState();
}

class _WordDetailScreenState extends State<WordDetailScreen>
    with SingleTickerProviderStateMixin {
  late final WordDetailController _detailController;
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _detailController = WordDetailController(
      repository: widget.repository,
      entry: widget.initialEntry,
    );
    _tabController = TabController(length: 5, vsync: this);
    _detailController.loadDetails();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _detailController.dispose();
    super.dispose();
  }

  Future<void> _handleEditWord() async {
    final updated = await showDialog<bool>(
      context: context,
      builder: (ctx) => EditWordDialog(
        entry: _detailController.entry,
        controller: widget.listController,
        userRole: widget.userRole,
      ),
    );
    if (updated == true) {
      await _detailController.loadDetails();
    }
  }

  Future<void> _handleDeleteWord() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Master Lexicon Word'),
        content: Text(
          'Are you sure you want to permanently delete "${_detailController.entry.lemma}" and all its translations, senses, synonyms, and examples?\n\n'
          'This action is irreversible and restricted to Superadmins.',
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
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await widget.listController.deleteEntry(_detailController.entry.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Word "${_detailController.entry.lemma}" deleted successfully.'),
              backgroundColor: const Color(0xFF15803D),
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(widget.listController.errorMessage ?? 'Failed to delete word.'),
              backgroundColor: const Color(0xFFDC2626),
            ),
          );
        }
      }
    }
  }

  Future<void> _handleStatusTransition(String newStatus) async {
    final success = await _detailController.updateEntryStatus(newStatus);
    if (success) {
      await widget.listController.loadEntries();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status updated to ${newStatus.toUpperCase()}'),
            backgroundColor: const Color(0xFF15803D),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _detailController,
      builder: (context, _) {
        final entry = _detailController.entry;
        final role = widget.userRole;

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.of(context).pop(),
            ),
            title: Row(
              children: [
                Text(entry.lemma),
                const SizedBox(width: 12),
                if (entry.gender != null && entry.gender != 'none') ...[
                  Text(
                    '(${entry.gender})',
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                CefrBadge(cefr: entry.cefrLevel),
                const SizedBox(width: 8),
                StatusBadge(status: entry.status),
              ],
            ),
            actions: [
              if (entry.canEdit(role)) ...[
                IconButton(
                  tooltip: 'Edit Word',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: _handleEditWord,
                ),
              ],
              if (entry.canDelete(role)) ...[
                IconButton(
                  tooltip: 'Delete Word',
                  icon: const Icon(Icons.delete_outline, color: Color(0xFFDC2626)),
                  onPressed: _handleDeleteWord,
                ),
              ],
              IconButton(
                tooltip: 'Refresh',
                icon: const Icon(Icons.refresh),
                onPressed: _detailController.loadDetails,
              ),
              const SizedBox(width: 8),
            ],
            bottom: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: [
                const Tab(icon: Icon(Icons.info_outline), text: 'Overview'),
                Tab(
                  icon: const Icon(Icons.translate),
                  text: 'Translations (${_detailController.translations.length})',
                ),
                Tab(
                  icon: const Icon(Icons.psychology),
                  text: 'Senses (${_detailController.senses.length})',
                ),
                Tab(
                  icon: const Icon(Icons.compare_arrows),
                  text: 'Synonyms (${_detailController.synonyms.length})',
                ),
                Tab(
                  icon: const Icon(Icons.format_quote),
                  text: 'Examples (${_detailController.examples.length})',
                ),
              ],
            ),
          ),
          body: _detailController.isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildOverviewTab(entry, role),
                    _buildTranslationsTab(entry, role),
                    _buildSensesTab(entry, role),
                    _buildSynonymsTab(entry, role),
                    _buildExamplesTab(entry, role),
                  ],
                ),
        );
      },
    );
  }

  // --- Tab 1: Overview ---
  Widget _buildOverviewTab(MasterLexiconEntry entry, AdminRole role) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_detailController.errorMessage != null) ...[
                _buildErrorBanner(_detailController.errorMessage!),
                const SizedBox(height: 16),
              ],
              // Review Workflow Card
              _buildReviewWorkflowCard(entry, role),
              const SizedBox(height: 20),
              // Basic Information Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Basic Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const Divider(height: 24),
                      _buildInfoRow('German Lemma', entry.lemma),
                      _buildInfoRow('Normalized Lemma', entry.normalizedLemma),
                      _buildInfoRow('Part of Speech', entry.partOfSpeech),
                      _buildInfoRow('Gender / Article', entry.gender ?? 'None'),
                      _buildInfoRow('Plural Form', entry.pluralForm ?? '—'),
                      _buildInfoRow('CEFR Level', entry.cefrLevel),
                      _buildInfoRow('Status', entry.status.toUpperCase()),
                      _buildInfoRow('Frequency Index', entry.frequencyIndex.toString()),
                      _buildInfoRow('Source Type', entry.sourceType),
                      _buildInfoRow('Provenance / Notes', entry.provenance ?? '—'),
                      _buildInfoRow('Created At', entry.createdAt.toLocal().toString()),
                      _buildInfoRow('Updated At', entry.updatedAt.toLocal().toString()),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReviewWorkflowCard(MasterLexiconEntry entry, AdminRole role) {
    final canVerify = entry.canVerify(role);
    final isEditor = role == AdminRole.editor;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.fact_check_outlined,
                    color: Color(0xFF2563EB), size: 20),
                const SizedBox(width: 8),
                const Text(
                  'Review & Quality Workflow',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const Spacer(),
                StatusBadge(status: entry.status),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Follow the multi-tier review cycle: Draft → Review → Verified. Only Reviewers and Superadmins can promote an entry to Verified.',
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                if (entry.status == 'draft') ...[
                  ElevatedButton.icon(
                    icon: const Icon(Icons.send, size: 16),
                    label: const Text('Submit for Review'),
                    onPressed: () => _handleStatusTransition('review'),
                  ),
                ],
                if (entry.status == 'review') ...[
                  if (canVerify) ...[
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF16A34A),
                      ),
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: const Text('Verify Entry'),
                      onPressed: () => _handleStatusTransition('verified'),
                    ),
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFDC2626),
                      ),
                      icon: const Icon(Icons.cancel_outlined, size: 16),
                      label: const Text('Reject Entry'),
                      onPressed: () => _handleStatusTransition('rejected'),
                    ),
                  ],
                  if (isEditor) ...[
                    OutlinedButton.icon(
                      icon: const Icon(Icons.undo, size: 16),
                      label: const Text('Return to Draft'),
                      onPressed: () => _handleStatusTransition('draft'),
                    ),
                  ],
                ],
                if (entry.status == 'verified' && canVerify) ...[
                  OutlinedButton.icon(
                    icon: const Icon(Icons.lock_open, size: 16),
                    label: const Text('Re-open for Review'),
                    onPressed: () => _handleStatusTransition('review'),
                  ),
                ],
                if (entry.status == 'rejected') ...[
                  OutlinedButton.icon(
                    icon: const Icon(Icons.restart_alt, size: 16),
                    label: const Text('Reset to Draft'),
                    onPressed: () => _handleStatusTransition('draft'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --- Tab 2: Translations ---
  Widget _buildTranslationsTab(MasterLexiconEntry entry, AdminRole role) {
    final list = _detailController.translations;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Multi-Language Translations',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Translation'),
                    onPressed: () => _openTranslationDialog(null),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (list.isEmpty) ...[
                _buildEmptyCard('No translations added yet for this word.'),
              ] else ...[
                ...list.map((t) => _buildTranslationCard(t, role)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTranslationCard(LexiconTranslation t, AdminRole role) {
    final canEdit = t.canEdit(role);
    final canDelete = t.canDelete(role);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFE0E7FF),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                t.targetLang.toUpperCase(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3730A3),
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.translation,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                      fontFamily: (t.targetLang == 'ur' ||
                              t.targetLang == 'ar' ||
                              t.targetLang == 'fa')
                          ? null
                          : null,
                    ),
                  ),
                  if (t.contextNotes != null && t.contextNotes!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      t.contextNotes!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            StatusBadge(status: t.status),
            const SizedBox(width: 12),
            if (canEdit) ...[
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                tooltip: 'Edit Translation',
                onPressed: () => _openTranslationDialog(t),
              ),
            ],
            if (canDelete) ...[
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: Color(0xFFDC2626)),
                tooltip: 'Delete Translation',
                onPressed: () => _detailController.deleteTranslation(t.id),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openTranslationDialog(LexiconTranslation? existing) async {
    final result = await showDialog<LexiconTranslation>(
      context: context,
      builder: (ctx) => TranslationDialog(
        entryId: _detailController.entry.id,
        translation: existing,
        userRole: widget.userRole,
      ),
    );

    if (result != null) {
      if (existing == null) {
        await _detailController.addTranslation(result);
      } else {
        await _detailController.updateTranslation(result);
      }
    }
  }

  // --- Tab 3: Senses ---
  Widget _buildSensesTab(MasterLexiconEntry entry, AdminRole role) {
    final list = _detailController.senses;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Distinct Semantic Senses',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Sense'),
                    onPressed: () => _openSenseDialog(null),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (list.isEmpty) ...[
                _buildEmptyCard('No semantic senses defined yet.'),
              ] else ...[
                ...list.map((s) => _buildSenseCard(s, entry, role)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSenseCard(
      LexiconSense s, MasterLexiconEntry entry, AdminRole role) {
    final canEdit = s.canEdit(role, parentIsVerified: entry.status == 'verified');
    final canDelete = s.canDelete(role);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 14,
              backgroundColor: const Color(0xFFDBEAFE),
              child: Text(
                '${s.senseOrder}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1D4ED8),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.definitionDe,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (s.definitionEn != null && s.definitionEn!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      s.definitionEn!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF475569),
                      ),
                    ),
                  ],
                  if (s.contextDomain != null && s.contextDomain!.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        s.contextDomain!,
                        style: const TextStyle(
                            fontSize: 11, color: Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (canEdit) ...[
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: () => _openSenseDialog(s),
              ),
            ],
            if (canDelete) ...[
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: Color(0xFFDC2626)),
                onPressed: () => _detailController.deleteSense(s.id),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openSenseDialog(LexiconSense? existing) async {
    final result = await showDialog<LexiconSense>(
      context: context,
      builder: (ctx) => SenseDialog(
        entryId: _detailController.entry.id,
        sense: existing,
        defaultOrder: _detailController.senses.length + 1,
      ),
    );

    if (result != null) {
      if (existing == null) {
        await _detailController.addSense(result);
      } else {
        await _detailController.updateSense(result);
      }
    }
  }

  // --- Tab 4: Synonyms ---
  Widget _buildSynonymsTab(MasterLexiconEntry entry, AdminRole role) {
    final list = _detailController.synonyms;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Curated Synonyms',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Synonym'),
                    onPressed: () => _openSynonymDialog(null),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (list.isEmpty) ...[
                _buildEmptyCard('No synonyms added yet.'),
              ] else ...[
                ...list.map((syn) => _buildSynonymCard(syn, role)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSynonymCard(LexiconSynonym syn, AdminRole role) {
    final canEdit = syn.canEdit(role);
    final canDelete = syn.canDelete(role);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.sync_alt, color: Color(0xFF6366F1), size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    syn.synonymWord,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  if (syn.nuanceNote != null && syn.nuanceNote!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      syn.nuanceNote!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF64748B),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            StatusBadge(status: syn.status),
            const SizedBox(width: 8),
            if (canEdit) ...[
              IconButton(
                icon: const Icon(Icons.edit_outlined, size: 18),
                onPressed: () => _openSynonymDialog(syn),
              ),
            ],
            if (canDelete) ...[
              IconButton(
                icon: const Icon(Icons.delete_outline,
                    size: 18, color: Color(0xFFDC2626)),
                onPressed: () => _detailController.deleteSynonym(syn.id),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openSynonymDialog(LexiconSynonym? existing) async {
    final result = await showDialog<LexiconSynonym>(
      context: context,
      builder: (ctx) => SynonymDialog(
        entryId: _detailController.entry.id,
        synonym: existing,
        userRole: widget.userRole,
      ),
    );

    if (result != null) {
      if (existing == null) {
        await _detailController.addSynonym(result);
      } else {
        await _detailController.updateSynonym(result);
      }
    }
  }

  // --- Tab 5: Examples ---
  Widget _buildExamplesTab(MasterLexiconEntry entry, AdminRole role) {
    final list = _detailController.examples;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text(
                    'Original Pedagogical Examples',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add Example'),
                    onPressed: () => _openExampleDialog(null),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (list.isEmpty) ...[
                _buildEmptyCard('No example sentences recorded yet.'),
              ] else ...[
                ...list.map((ex) => _buildExampleCard(ex, role)),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExampleCard(LexiconExample ex, AdminRole role) {
    final canEdit = ex.canEdit(role);
    final canDelete = ex.canDelete(role);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (ex.cefrLevel != null) ...[
                  CefrBadge(cefr: ex.cefrLevel!),
                  const SizedBox(width: 8),
                ],
                StatusBadge(status: ex.status),
                const Spacer(),
                if (canEdit) ...[
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: () => _openExampleDialog(ex),
                  ),
                ],
                if (canDelete) ...[
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: Color(0xFFDC2626)),
                    onPressed: () => _detailController.deleteExample(ex.id),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            Text(
              ex.sentenceDe,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
            if (ex.sentenceEn != null && ex.sentenceEn!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                ex.sentenceEn!,
                style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
              ),
            ],
            if (ex.sentenceUr != null && ex.sentenceUr!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                ex.sentenceUr!,
                textDirection: TextDirection.rtl,
                style: const TextStyle(fontSize: 13, color: Color(0xFF475569)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openExampleDialog(LexiconExample? existing) async {
    final result = await showDialog<LexiconExample>(
      context: context,
      builder: (ctx) => ExampleDialog(
        entryId: _detailController.entry.id,
        example: existing,
        userRole: widget.userRole,
      ),
    );

    if (result != null) {
      if (existing == null) {
        await _detailController.addExample(result);
      } else {
        await _detailController.updateExample(result);
      }
    }
  }

  // --- Helper Widgets ---

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 180,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.inbox_outlined, size: 40, color: Color(0xFF94A3B8)),
              const SizedBox(height: 8),
              Text(
                message,
                style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorBanner(String message) {
    return Container(
      padding: const EdgeInsets.all(12),
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
              message,
              style: const TextStyle(color: Color(0xFF991B1B), fontSize: 13),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: Color(0xFFB91C1C)),
            onPressed: _detailController.clearError,
          ),
        ],
      ),
    );
  }
}
