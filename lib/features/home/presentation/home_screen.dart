// lib/features/home/presentation/home_screen.dart

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../reader/data/pdf_repository.dart';
import '../../reader/presentation/controllers/reader_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _openCustomPdf(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      final name = result.files.single.name;

      final descriptor = PdfDocumentDescriptor(
        title: name,
        path: path,
        type: PdfDocumentSourceType.file,
      );

      ref.read(readerControllerProvider.notifier).setDocument(descriptor);
      if (context.mounted) {
        context.push('/reader');
      }
    }
  }

  void _openBundledDoc(
    BuildContext context,
    WidgetRef ref,
    PdfDocumentDescriptor descriptor,
  ) {
    ref.read(readerControllerProvider.notifier).setDocument(descriptor);
    context.push('/reader');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('German Reader & Tap-to-Translate'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Header hero card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).colorScheme.primary,
                  Theme.of(context).colorScheme.tertiary,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.menu_book, color: Colors.white, size: 36),
                SizedBox(height: 12),
                Text(
                  'Präzises Tipp-zu-Wort-Lesen',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Öffnen Sie ein beliebiges deutsches PDF. Die originale PDF-Darstellung bleibt 100% unverändert erhalten.',
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          Text(
            'TEST- UND BEISPIELDOKUMENTE',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),

          // Card 1: Comprehensive German PDF
          _buildDocCard(
            context: context,
            title: PdfRepository.sampleGermanDoc.title,
            subtitle: 'Umlaute (ä, ö, ü), ß, Tabellen, Mehrspalten & Zoomtests',
            icon: Icons.auto_stories,
            color: Colors.indigo,
            onTap: () => _openBundledDoc(context, ref, PdfRepository.sampleGermanDoc),
          ),
          const SizedBox(height: 12),

          // Card 2: KIT Academic Thesis
          _buildDocCard(
            context: context,
            title: PdfRepository.sampleThesisDoc.title,
            subtitle: 'Echtes akademisches LaTeX-Dokument mit deutscher Zusammenfassung',
            icon: Icons.school,
            color: Colors.teal,
            onTap: () => _openBundledDoc(context, ref, PdfRepository.sampleThesisDoc),
          ),
          const SizedBox(height: 12),

          // Card 3: Scanned German Document (Real ML Kit OCR)
          _buildDocCard(
            context: context,
            title: PdfRepository.sampleScannedGermanDoc.title,
            subtitle: 'Reines Bild ohne Textschicht: On-Device Google ML Kit Texterkennung',
            icon: Icons.document_scanner,
            color: Colors.deepOrange,
            onTap: () => _openBundledDoc(context, ref, PdfRepository.sampleScannedGermanDoc),
          ),
          const SizedBox(height: 24),

          Text(
            'EIGENE DATEI',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 12),

          // Custom PDF picker button
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            icon: const Icon(Icons.file_open),
            label: const Text(
              'PDF-Datei vom Gerät auswählen...',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
            onPressed: () => _openCustomPdf(context, ref),
          ),

          const SizedBox(height: 32),

          // Architectural principles badge
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.verified, color: Colors.green[700], size: 18),
                    const SizedBox(width: 6),
                    const Expanded(
                      child: Text(
                        'Geprüfte Architekturprinzipien',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  '• Bounding-Box Trefferprüfung (Keine Nächste-Wort-Heuristik)\n'
                  '• Exakte PDF-Seitenkoordinaten als Source-of-Truth\n'
                  '• Originale PDF-Grafik bleibt unverändert\n'
                  '• Vollständig Offline-fähig',
                  style: TextStyle(fontSize: 11, color: Color(0xFF555555), height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                foregroundColor: color,
                radius: 22,
                child: Icon(icon, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
