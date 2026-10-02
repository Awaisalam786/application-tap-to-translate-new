import 'package:flutter/material.dart';
import '../../../auth/domain/admin_user_model.dart';
import '../../domain/models/lexicon_synonym.dart';

class SynonymDialog extends StatefulWidget {
  final String entryId;
  final LexiconSynonym? synonym; // null for add
  final AdminRole userRole;

  const SynonymDialog({
    super.key,
    required this.entryId,
    this.synonym,
    required this.userRole,
  });

  @override
  State<SynonymDialog> createState() => _SynonymDialogState();
}

class _SynonymDialogState extends State<SynonymDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _wordController;
  late final TextEditingController _noteController;
  late String _status;

  @override
  void initState() {
    super.initState();
    _wordController =
        TextEditingController(text: widget.synonym?.synonymWord ?? '');
    _noteController =
        TextEditingController(text: widget.synonym?.nuanceNote ?? '');
    _status = widget.synonym?.status ?? 'draft';
  }

  @override
  void dispose() {
    _wordController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final syn = LexiconSynonym(
      id: widget.synonym?.id ?? '',
      entryId: widget.entryId,
      synonymWord: _wordController.text.trim(),
      nuanceNote: _noteController.text.trim().isEmpty
          ? null
          : _noteController.text.trim(),
      status: _status,
      createdAt: widget.synonym?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Navigator.of(context).pop(syn);
  }

  @override
  Widget build(BuildContext context) {
    final isEditor = widget.userRole == AdminRole.editor;
    final isNew = widget.synonym == null;
    final allowedStatuses = isEditor
        ? ['draft', 'review']
        : ['draft', 'review', 'verified', 'rejected'];

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
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
                    const Icon(Icons.compare_arrows, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    Text(
                      isNew ? 'Add Synonym' : 'Edit Synonym',
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
                  controller: _wordController,
                  decoration: const InputDecoration(
                    labelText: 'Synonym Word (German) *',
                    hintText: 'e.g. Gebäude, Bauwerk',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
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
                const SizedBox(height: 16),
                TextFormField(
                  controller: _noteController,
                  decoration: const InputDecoration(
                    labelText: 'Linguistic Nuance / Note (optional)',
                    hintText: 'e.g. More formal, archaic, regional usage',
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
