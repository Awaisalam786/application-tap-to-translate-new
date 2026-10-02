import 'package:flutter/material.dart';
import '../../../auth/domain/admin_user_model.dart';
import '../../domain/models/lexicon_translation.dart';

class TranslationDialog extends StatefulWidget {
  final String entryId;
  final LexiconTranslation? translation; // null for add
  final AdminRole userRole;

  const TranslationDialog({
    super.key,
    required this.entryId,
    this.translation,
    required this.userRole,
  });

  @override
  State<TranslationDialog> createState() => _TranslationDialogState();
}

class _TranslationDialogState extends State<TranslationDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _translationController;
  late final TextEditingController _notesController;

  late String _targetLang;
  late String _status;
  late String _sourceType;
  late String _provider;

  @override
  void initState() {
    super.initState();
    _translationController =
        TextEditingController(text: widget.translation?.translation ?? '');
    _notesController =
        TextEditingController(text: widget.translation?.contextNotes ?? '');

    _targetLang = widget.translation?.targetLang ?? 'en';
    _status = widget.translation?.status ?? 'draft';
    _sourceType = widget.translation?.sourceType ?? 'manual';
    _provider = widget.translation?.provider ?? 'human';
  }

  @override
  void dispose() {
    _translationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final translation = LexiconTranslation(
      id: widget.translation?.id ?? '',
      entryId: widget.entryId,
      targetLang: _targetLang,
      translation: _translationController.text.trim(),
      contextNotes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      status: _status,
      sourceType: _sourceType,
      provider: _provider,
      createdAt: widget.translation?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Navigator.of(context).pop(translation);
  }

  @override
  Widget build(BuildContext context) {
    final isEditor = widget.userRole == AdminRole.editor;
    final isNew = widget.translation == null;
    final allowedStatuses = isEditor
        ? ['draft', 'review']
        : ['draft', 'review', 'verified', 'rejected'];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.translate, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    Text(
                      isNew ? 'Add Translation' : 'Edit Translation',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.of(context).pop(null),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _targetLang,
                        decoration: const InputDecoration(
                          labelText: 'Target Language *',
                        ),
                        items: const [
                          DropdownMenuItem(value: 'en', child: Text('English (en)')),
                          DropdownMenuItem(value: 'ur', child: Text('Urdu (ur)')),
                          DropdownMenuItem(value: 'fa', child: Text('Persian (fa)')),
                          DropdownMenuItem(value: 'ar', child: Text('Arabic (ar)')),
                        ],
                        onChanged: isNew
                            ? (v) {
                                if (v != null) setState(() => _targetLang = v);
                              }
                            : null, // target language is immutable once created
                      ),
                    ),
                    const SizedBox(width: 12),
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
                        onChanged: (v) {
                          if (v != null) setState(() => _status = v);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _translationController,
                  decoration: InputDecoration(
                    labelText:
                        'Translation in ${LexiconTranslation.languageName(_targetLang)} *',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Context Notes / Specific Nuances (optional)',
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(null),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _submit,
                      child: Text(isNew ? 'Add' : 'Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
