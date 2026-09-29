// lib/features/reader/presentation/screens/reader_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';

import '../controllers/reader_controller.dart';
import '../widgets/pdf_viewer_widget.dart';
import '../widgets/reader_toolbar.dart';
import '../widgets/word_inspection_sheet.dart';
import 'package:tap_to_translate/features/translation/presentation/controllers/translation_controller.dart';
import 'package:tap_to_translate/features/translation/presentation/widgets/translation_popup.dart';

class ReaderScreen extends ConsumerStatefulWidget {
  const ReaderScreen({super.key});

  @override
  ConsumerState<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends ConsumerState<ReaderScreen> {
  late final PdfViewerController _pdfController;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
  }


  @override
  Widget build(BuildContext context) {
    final state = ref.watch(readerControllerProvider);
    final notifier = ref.read(readerControllerProvider.notifier);

    final doc = state.document;
    if (doc == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('PDF Reader')),
        body: const Center(child: Text('Kein Dokument ausgewählt')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              doc.title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              state.isDebugMode ? 'MODUS: DEBUG GEOMETRIE (Sichtbar)' : 'MODUS: PRODUKTION (Unsichtbar)',
              style: TextStyle(
                fontSize: 11,
                color: state.isDebugMode ? Colors.orangeAccent : Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(state.isDebugMode ? Icons.layers : Icons.layers_outlined),
            tooltip: 'Debug-Modus umschalten',
            onPressed: notifier.toggleDebugMode,
          ),
        ],
      ),
      body: Column(
        children: [
          // Reader controls toolbar
          ReaderToolbar(controller: _pdfController),

          // Main PDF viewer with tap hit-testing and optional debug overlay
          Expanded(
            child: Stack(
              children: [
                PdfViewerWidget(
                  document: doc,
                  controller: _pdfController,
                ),

                // Translation Popup when exact word is selected
                if (ref.watch(translationControllerProvider).currentResult != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: TranslationPopup(
                      onClose: () {
                        ref.read(translationControllerProvider.notifier).dismissPopup();
                        notifier.clearSelection();
                      },
                    ),
                  )
                // In debug mode, if translation popup is not showing or if user is inspecting debug geometry
                else if (state.isDebugMode && state.lastSelection != null)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: WordInspectionSheet(
                      result: state.lastSelection!,
                      isDebugMode: true,
                      onDismiss: notifier.clearSelection,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
