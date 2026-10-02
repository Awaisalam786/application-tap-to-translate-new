import 'package:flutter/material.dart';
import '../../../auth/domain/admin_user_model.dart';
import '../../domain/models/lexicon_filter.dart';
import '../../domain/models/master_lexicon_entry.dart';
import '../../domain/services/pos_rules_validator.dart';
import '../controllers/lexicon_controller.dart';

class EditWordDialog extends StatefulWidget {
  final MasterLexiconEntry entry;
  final LexiconController controller;
  final AdminRole userRole;

  const EditWordDialog({
    super.key,
    required this.entry,
    required this.controller,
    required this.userRole,
  });

  @override
  State<EditWordDialog> createState() => _EditWordDialogState();
}

class _EditWordDialogState extends State<EditWordDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _lemmaController;
  late final TextEditingController _pluralController;
  late final TextEditingController _provenanceController;

  late String _partOfSpeech;
  late String _gender;
  late String _cefrLevel;
  late String _status;
  bool _isSubmitting = false;
  String? _formError;

  @override
  void initState() {
    super.initState();
    _lemmaController = TextEditingController(text: widget.entry.lemma);
    _pluralController = TextEditingController(text: widget.entry.pluralForm ?? '');
    _provenanceController =
        TextEditingController(text: widget.entry.provenance ?? '');

    _partOfSpeech = widget.entry.partOfSpeech;
    _gender = widget.entry.gender ?? 'none';
    _cefrLevel = widget.entry.cefrLevel;
    _status = widget.entry.status;
  }

  @override
  void dispose() {
    _lemmaController.dispose();
    _pluralController.dispose();
    _provenanceController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _formError = null;
    });

    final lemma = _lemmaController.text.trim();
    final normalized = MasterLexiconEntry.normalizeLemma(lemma);

    final updated = widget.entry.copyWith(
      lemma: lemma,
      normalizedLemma: normalized,
      partOfSpeech: _partOfSpeech,
      gender: _gender == 'none' ? null : _gender,
      pluralForm: _pluralController.text.trim().isEmpty
          ? null
          : _pluralController.text.trim(),
      cefrLevel: _cefrLevel,
      status: _status,
      provenance: _provenanceController.text.trim().isEmpty
          ? null
          : _provenanceController.text.trim(),
      updatedAt: DateTime.now(),
    );

    final validation = PosRulesValidator.validateEntry(updated);
    if (!validation.isValid) {
      setState(() {
        _isSubmitting = false;
        _formError = validation.errors.join(' ');
      });
      return;
    }

    final success = await widget.controller.updateEntry(updated);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isSubmitting = false;
        _formError = widget.controller.errorMessage ?? 'Failed to update word.';
      });
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Master Lexicon Entry'),
        content: Text(
          'Are you sure you want to permanently delete "${widget.entry.lemma}" (${widget.entry.partOfSpeech})?\n\n'
          'This will also cascade delete all associated translations, senses, synonyms, and examples.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isSubmitting = true);
      final success = await widget.controller.deleteEntry(widget.entry.id);
      if (!mounted) return;
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _isSubmitting = false;
          _formError = widget.controller.errorMessage ?? 'Failed to delete word.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditor = widget.userRole == AdminRole.editor;
    final isVerified = widget.entry.status == 'verified';
    final canEdit = widget.entry.canEdit(widget.userRole);
    final canDelete = widget.entry.canDelete(widget.userRole);

    final allowedStatuses = isEditor
        ? ['draft', 'review']
        : ['draft', 'review', 'verified', 'rejected', 'archived'];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.edit_note, color: Color(0xFF2563EB)),
                      const SizedBox(width: 8),
                      Text(
                        'Edit "${widget.entry.lemma}"',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, size: 20),
                        onPressed: () => Navigator.of(context).pop(false),
                      ),
                    ],
                  ),
                  if (isEditor && isVerified) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFFBBF24)),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.lock, size: 18, color: Color(0xFFB45309)),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Verified entries cannot be edited by Editors. Only Reviewers and Superadmins can modify verified entries.',
                              style: TextStyle(
                                  fontSize: 12, color: Color(0xFF92400E)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (_formError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFF87171)),
                      ),
                      child: Text(
                        _formError!,
                        style: const TextStyle(
                            color: Color(0xFF991B1B), fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  TextFormField(
                    controller: _lemmaController,
                    enabled: canEdit,
                    decoration: const InputDecoration(
                      labelText: 'German Word (Lemma) *',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (_partOfSpeech == 'noun') {
                        final res = PosRulesValidator.validateNoun(
                          lemma: v,
                          article: _gender,
                          pluralForm: _pluralController.text,
                        );
                        if (!res.isValid) return res.errors.first;
                      } else if (_partOfSpeech == 'verb') {
                        final res = PosRulesValidator.validateVerb(lemma: v);
                        if (!res.isValid) return res.errors.first;
                      } else if (_partOfSpeech == 'adjective') {
                        final res = PosRulesValidator.validateAdjective(lemma: v);
                        if (!res.isValid) return res.errors.first;
                      } else if (_partOfSpeech == 'adverb') {
                        final res = PosRulesValidator.validateAdverb(lemma: v);
                        if (!res.isValid) return res.errors.first;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _partOfSpeech,
                          decoration: const InputDecoration(
                            labelText: 'Word Type (POS) *',
                          ),
                          items: LexiconFilter.availablePos
                              .where((p) => p != 'all')
                              .map((p) => DropdownMenuItem(
                                    value: p,
                                    child: Text(p),
                                  ))
                              .toList(),
                          onChanged: canEdit
                              ? (v) {
                                  if (v != null) {
                                    setState(() {
                                      _partOfSpeech = v;
                                      if (_partOfSpeech != 'noun') {
                                        _gender = 'none';
                                      }
                                    });
                                  }
                                }
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _gender,
                          decoration: const InputDecoration(
                            labelText: 'Article (Gender)',
                          ),
                          items: LexiconFilter.availableGenders
                              .map((g) => DropdownMenuItem(
                                    value: g,
                                    child: Text(g == 'none' ? 'None' : g),
                                  ))
                              .toList(),
                          onChanged: canEdit && _partOfSpeech == 'noun'
                              ? (v) {
                                  if (v != null) setState(() => _gender = v);
                                }
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _pluralController,
                          enabled: canEdit,
                          decoration: const InputDecoration(
                            labelText: 'Plural Form',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _cefrLevel,
                          decoration: const InputDecoration(
                            labelText: 'CEFR Level',
                          ),
                          items: LexiconFilter.availableCefr
                              .where((c) => c != 'all')
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text(c),
                                  ))
                              .toList(),
                          onChanged: canEdit
                              ? (v) {
                                  if (v != null) setState(() => _cefrLevel = v);
                                }
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: allowedStatuses.contains(_status)
                              ? _status
                              : allowedStatuses.first,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                          ),
                          items: allowedStatuses
                              .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s.toUpperCase()),
                                  ))
                              .toList(),
                          onChanged: canEdit
                              ? (v) {
                                  if (v != null) setState(() => _status = v);
                                }
                              : null,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _provenanceController,
                          enabled: canEdit,
                          decoration: const InputDecoration(
                            labelText: 'Provenance / Reference',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      if (canDelete) ...[
                        TextButton.icon(
                          icon: const Icon(Icons.delete_outline,
                              color: Color(0xFFDC2626), size: 18),
                          label: const Text(
                            'Delete Word',
                            style: TextStyle(color: Color(0xFFDC2626)),
                          ),
                          onPressed: _isSubmitting ? null : _confirmDelete,
                        ),
                      ],
                      const Spacer(),
                      OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
                      if (canEdit) ...[
                        ElevatedButton.icon(
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.save, size: 18),
                          label: const Text('Save Changes'),
                          onPressed: _isSubmitting ? null : _submit,
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
