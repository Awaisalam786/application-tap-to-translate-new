// lib/features/reader/presentation/widgets/word_inspection_sheet.dart

import 'package:flutter/material.dart';
import '../../../../core/models/selection_result.dart';

class WordInspectionSheet extends StatelessWidget {
  final SelectionResult result;
  final bool isDebugMode;
  final VoidCallback onDismiss;

  const WordInspectionSheet({
    super.key,
    required this.result,
    required this.isDebugMode,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final word = result.word;

    // In non-debug mode, if result is null (whitespace/gap/ambiguous), don't show sheet
    if (word == null && !isDebugMode) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(12),
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildStatusIcon(result.status),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    word != null ? word.cleanWord : _statusTitle(result.status),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onDismiss,
                  tooltip: 'Schließen',
                ),
              ],
            ),
            if (word != null) ...[
              if (word.dehyphenatedCompound != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    'Zusammensetzung: ${word.dehyphenatedCompound}',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              Text(
                'Originaltext: "${word.rawText}" • Seite ${word.pageNumber}',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
            if (isDebugMode) ...[
              const Divider(height: 16),
              _buildDebugTelemetry(context, result),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIcon(SelectionStatus status) {
    switch (status) {
      case SelectionStatus.exactMatch:
        return const Icon(Icons.check_circle, color: Colors.green, size: 22);
      case SelectionStatus.interWordGap:
        return const Icon(Icons.space_bar, color: Colors.orange, size: 22);
      case SelectionStatus.whitespace:
        return const Icon(Icons.crop_free, color: Colors.blueGrey, size: 22);
      case SelectionStatus.ambiguous:
        return const Icon(Icons.warning_amber, color: Colors.red, size: 22);
      case SelectionStatus.lowConfidence:
        return const Icon(Icons.help_outline, color: Colors.amber, size: 22);
    }
  }

  String _statusTitle(SelectionStatus status) {
    switch (status) {
      case SelectionStatus.exactMatch:
        return 'Wort identifiziert';
      case SelectionStatus.interWordGap:
        return 'Lücke zwischen Wörtern (NULL)';
      case SelectionStatus.whitespace:
        return 'Weißraum / Rand (NULL)';
      case SelectionStatus.ambiguous:
        return 'Mehrdeutige Überlappung (NULL)';
      case SelectionStatus.lowConfidence:
        return 'Niedrige OCR-Zuverlässigkeit (NULL)';
    }
  }

  Widget _buildDebugTelemetry(BuildContext context, SelectionResult res) {
    final word = res.word;
    final b = word?.pageBoundingBox;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DEBUG TELEMETRIE:',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.secondary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '• Tipp-Punkt PDF: (${res.pdfTapPoint.x.toStringAsFixed(2)}, ${res.pdfTapPoint.y.toStringAsFixed(2)}) pt\n'
          '• Tipp-Punkt Screen: (${res.screenTapOffset.dx.toStringAsFixed(1)}, ${res.screenTapOffset.dy.toStringAsFixed(1)}) px\n'
          '• Trefferstatus: ${res.status.name.toUpperCase()}\n'
          '${b != null ? "• Bounding Box: [l=${b.left.toStringAsFixed(1)}, b=${b.bottom.toStringAsFixed(1)}, r=${b.right.toStringAsFixed(1)}, t=${b.top.toStringAsFixed(1)}] (w=${b.width.toStringAsFixed(1)}, h=${b.height.toStringAsFixed(1)})\n" : ""}'
          '${word != null ? "• Glyphenanzahl: ${word.charRects.length}\n" : ""}'
          '${word != null && word.isOcr ? "• Quelle: OCR (${word.confidence != null ? '${(word.confidence! * 100).toStringAsFixed(1)}%' : 'ohne Konfidenz'})\n" : ""}'
          '${word != null && word.isOcr && word.blockId != null ? "• OCR Block/Zeile: ${word.blockId}/${word.lineId}\n" : ""}'
          '• Nächste-Wort-Auswahl: STRENG DEAKTIVIERT (0.00)',
          style: const TextStyle(
            fontSize: 11,
            fontFamily: 'monospace',
            color: Color(0xFF37474F),
            height: 1.3,
          ),
        ),
      ],
    );
  }
}
