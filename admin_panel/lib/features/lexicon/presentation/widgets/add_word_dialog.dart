import 'package:flutter/material.dart';
import '../../../auth/domain/admin_user_model.dart';
import '../../domain/models/lexicon_filter.dart';
import '../../domain/models/master_lexicon_entry.dart';
import '../controllers/lexicon_controller.dart';

class AddWordDialog extends StatefulWidget {
  final LexiconController controller;
  final AdminRole userRole;

  const AddWordDialog({
    super.key,
    required this.controller,
    required this.userRole,
  });

  @override
  State<AddWordDialog> createState() => _AddWordDialogState();
}

class _AddWordDialogState extends State<AddWordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _lemmaController = TextEditingController();
  final _pluralController = TextEditingController();
  final _provenanceController = TextEditingController();

  String _partOfSpeech = 'noun';
  String _gender = 'none';
  String _cefrLevel = 'A1';
  String _status = 'draft';
  String _sourceType = 'manual_entry';
  bool _isSubmitting = false;
  String? _formError;

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

    final newEntry = MasterLexiconEntry(
      id: '',
      lemma: lemma,
      normalizedLemma: normalized,
      partOfSpeech: _partOfSpeech,
      gender: _gender == 'none' ? null : _gender,
      pluralForm: _pluralController.text.trim().isEmpty
          ? null
          : _pluralController.text.trim(),
      cefrLevel: _cefrLevel,
      status: _status,
      sourceType: _sourceType,
      provenance: _provenanceController.text.trim().isEmpty
          ? null
          : _provenanceController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final success = await widget.controller.createEntry(newEntry);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _isSubmitting = false;
        _formError = widget.controller.errorMessage ?? 'Failed to create word.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Only reviewers/superadmins can set status directly to 'verified' on creation
    final allowedStatuses = widget.userRole == AdminRole.editor
        ? ['draft', 'review']
        : ['draft', 'review', 'verified', 'rejected'];

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
                      const Icon(Icons.add_circle_outline, color: Color(0xFF2563EB)),
                      const SizedBox(width: 8),
                      const Text(
                        'Add Master Lexicon Word',
                        style: TextStyle(
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
                  const SizedBox(height: 16),
                  if (_formError != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
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
                              _formError!,
                              style: const TextStyle(
                                color: Color(0xFF991B1B),
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // German Word (Lemma)
                  TextFormField(
                    controller: _lemmaController,
                    decoration: const InputDecoration(
                      labelText: 'German Word (Lemma) *',
                      hintText: 'e.g. Haus, laufen, schnell',
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'German word is required';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  // Word Type (POS) & Article (Gender)
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
                          onChanged: (v) {
                            if (v != null) {
                              setState(() {
                                _partOfSpeech = v;
                                if (_partOfSpeech != 'noun') {
                                  _gender = 'none';
                                }
                              });
                            }
                          },
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
                                    child: Text(g == 'none' ? 'None / N/A' : g),
                                  ))
                              .toList(),
                          onChanged: _partOfSpeech == 'noun'
                              ? (v) {
                                  if (v != null) setState(() => _gender = v);
                                }
                              : null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Plural Form & CEFR Level
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _pluralController,
                          decoration: const InputDecoration(
                            labelText: 'Plural Form (optional)',
                            hintText: 'e.g. Häuser',
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
                          onChanged: (v) {
                            if (v != null) setState(() => _cefrLevel = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Status & Source Type
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _status,
                          decoration: const InputDecoration(
                            labelText: 'Initial Status',
                          ),
                          items: allowedStatuses
                              .map((s) => DropdownMenuItem(
                                    value: s,
                                    child: Text(s.toUpperCase()),
                                  ))
                              .toList(),
                          onChanged: (v) {
                            if (v != null) setState(() => _status = v);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _sourceType,
                          decoration: const InputDecoration(
                            labelText: 'Source Type',
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'manual_entry',
                              child: Text('Manual Entry'),
                            ),
                            DropdownMenuItem(
                              value: 'candidate_import',
                              child: Text('Candidate Import'),
                            ),
                            DropdownMenuItem(
                              value: 'curated_expansion',
                              child: Text('Curated Expansion'),
                            ),
                            DropdownMenuItem(
                              value: 'community_submission',
                              child: Text('Community Submission'),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) setState(() => _sourceType = v);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Provenance / Notes
                  TextFormField(
                    controller: _provenanceController,
                    decoration: const InputDecoration(
                      labelText: 'Provenance / Reference Notes (optional)',
                      hintText: 'e.g. Goethe B1 Curriculum, Duden Reference',
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: _isSubmitting
                            ? null
                            : () => Navigator.of(context).pop(false),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 12),
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
                        label: const Text('Add Word'),
                        onPressed: _isSubmitting ? null : _submit,
                      ),
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
