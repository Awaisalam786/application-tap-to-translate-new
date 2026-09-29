// lib/features/reader/presentation/widgets/reader_toolbar.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import '../controllers/reader_controller.dart';

class ReaderToolbar extends ConsumerWidget {
  final PdfViewerController controller;

  const ReaderToolbar({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(readerControllerProvider);
    final notifier = ref.read(readerControllerProvider.notifier);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Page counter badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${state.currentPage} / ${state.totalPages > 0 ? state.totalPages : "-"}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Zoom Out
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: const Icon(Icons.zoom_out, size: 18),
            tooltip: 'Verkleinern',
            onPressed: () {
              if (controller.isReady) {
                controller.zoomDown();
              }
            },
          ),

          // Zoom percentage indicator
          Text(
            '${(state.currentZoom * 100).toInt()}%',
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),

          // Zoom In
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: const Icon(Icons.zoom_in, size: 18),
            tooltip: 'Vergrößern',
            onPressed: () {
              if (controller.isReady) {
                controller.zoomUp();
              }
            },
          ),

          const Spacer(),

          // DEBUG MODE Toggle Button
          FilterChip(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 4),
            label: const Text('DEBUG'),
            selected: state.isDebugMode,
            avatar: Icon(
              state.isDebugMode ? Icons.bug_report : Icons.bug_report_outlined,
              size: 14,
              color: state.isDebugMode ? Colors.white : Colors.grey[700],
            ),
            selectedColor: Colors.deepOrange,
            labelStyle: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: state.isDebugMode ? Colors.white : Colors.grey[800],
            ),
            onSelected: (_) => notifier.toggleDebugMode(),
          ),
        ],
      ),
    );
  }
}
