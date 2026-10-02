import 'package:flutter/material.dart';
import '../../../auth/domain/admin_user_model.dart';
import '../../domain/models/lexicon_example.dart';
import '../../domain/models/lexicon_filter.dart';

class ExampleDialog extends StatefulWidget {
  final String entryId;
  final LexiconExample? example; // null for add
  final AdminRole userRole;

  const ExampleDialog({
    super.key,
    required this.entryId,
    this.example,
    required this.userRole,
  });

  @override
  State<ExampleDialog> createState() => _ExampleDialogState();
}

class _ExampleDialogState extends State<ExampleDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _deController;
  late final TextEditingController _enController;
  late final TextEditingController _urController;

  String? _cefrLevel;
  late String _status;
  late String _sourceType;

  @override
  void initState() {
    super.initState();
    _deController =
        TextEditingController(text: widget.example?.sentenceDe ?? '');
    _enController =
        TextEditingController(text: widget.example?.sentenceEn ?? '');
    _urController =
        TextEditingController(text: widget.example?.sentenceUr ?? '');

    _cefrLevel = widget.example?.cefrLevel ?? 'A1';
    _status = widget.example?.status ?? 'draft';
    _sourceType = widget.example?.sourceType ?? 'original_curated';
  }

  @override
  void dispose() {
    _deController.dispose();
    _enController.dispose();
    _urController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final ex = LexiconExample(
      id: widget.example?.id ?? '',
      entryId: widget.entryId,
      sentenceDe: _deController.text.trim(),
      sentenceEn: _enController.text.trim().isEmpty
          ? null
          : _enController.text.trim(),
      sentenceUr: _urController.text.trim().isEmpty
          ? null
          : _urController.text.trim(),
      cefrLevel: _cefrLevel,
      status: _status,
      sourceType: _sourceType,
      createdAt: widget.example?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Navigator.of(context).pop(ex);
  }

  @override
  Widget build(BuildContext context) {
    final isEditor = widget.userRole == AdminRole.editor;
    final isNew = widget.example == null;
    final allowedStatuses = isEditor
        ? ['draft', 'review']
        : ['draft', 'review', 'verified', 'rejected'];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
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
                      const Icon(Icons.format_quote, color: Color(0xFF2563EB)),
                      const SizedBox(width: 8),
                      Text(
                        isNew ? 'Add Learning Example' : 'Edit Learning Example',
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
                  TextFormField(
                    controller: _deController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Original German Example Sentence *',
                      hintText: 'e.g. Das Haus steht am Stadtrand.',
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _enController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'English Translation (optional)',
                      hintText: 'The house is located on the edge of the city.',
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _urController,
                    maxLines: 2,
                    textDirection: TextDirection.rtl,
                    decoration: const InputDecoration(
                      labelText: 'Urdu Translation (optional)',
                      hintText: 'گھر شہر کے کنارے پر واقع ہے۔',
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _cefrLevel,
                          decoration: const InputDecoration(
                            labelText: 'Example CEFR Level',
                          ),
                          items: LexiconFilter.availableCefr
                              .where((c) => c != 'all' && c != 'unclassified')
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
                        child: Text(isNew ? 'Add Example' : 'Save Example'),
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
