import 'package:flutter/material.dart';
import '../../domain/models/lexicon_sense.dart';

class SenseDialog extends StatefulWidget {
  final String entryId;
  final LexiconSense? sense; // null for add
  final int defaultOrder;

  const SenseDialog({
    super.key,
    required this.entryId,
    this.sense,
    this.defaultOrder = 1,
  });

  @override
  State<SenseDialog> createState() => _SenseDialogState();
}

class _SenseDialogState extends State<SenseDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _orderController;
  late final TextEditingController _defDeController;
  late final TextEditingController _defEnController;
  late final TextEditingController _domainController;

  @override
  void initState() {
    super.initState();
    _orderController = TextEditingController(
      text: (widget.sense?.senseOrder ?? widget.defaultOrder).toString(),
    );
    _defDeController =
        TextEditingController(text: widget.sense?.definitionDe ?? '');
    _defEnController =
        TextEditingController(text: widget.sense?.definitionEn ?? '');
    _domainController =
        TextEditingController(text: widget.sense?.contextDomain ?? '');
  }

  @override
  void dispose() {
    _orderController.dispose();
    _defDeController.dispose();
    _defEnController.dispose();
    _domainController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    final order = int.tryParse(_orderController.text.trim()) ?? 1;

    final sense = LexiconSense(
      id: widget.sense?.id ?? '',
      entryId: widget.entryId,
      senseOrder: order,
      definitionDe: _defDeController.text.trim(),
      definitionEn: _defEnController.text.trim().isEmpty
          ? null
          : _defEnController.text.trim(),
      contextDomain: _domainController.text.trim().isEmpty
          ? null
          : _domainController.text.trim(),
      createdAt: widget.sense?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    Navigator.of(context).pop(sense);
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.sense == null;

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
                    const Icon(Icons.psychology, color: Color(0xFF2563EB)),
                    const SizedBox(width: 8),
                    Text(
                      isNew ? 'Add Word Sense' : 'Edit Word Sense',
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
                    SizedBox(
                      width: 120,
                      child: TextFormField(
                        controller: _orderController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Sense # *',
                          hintText: '1, 2, ...',
                        ),
                        validator: (v) {
                          if (v == null || int.tryParse(v.trim()) == null) {
                            return 'Valid #';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _domainController,
                        decoration: const InputDecoration(
                          labelText: 'Domain / Context (optional)',
                          hintText: 'e.g. Finance, Architecture',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _defDeController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'German Definition *',
                    hintText: 'Genaue Bedeutung auf Deutsch',
                  ),
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _defEnController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'English Definition (optional)',
                    hintText: 'Definition in English',
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
                      child: Text(isNew ? 'Add Sense' : 'Save Sense'),
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
