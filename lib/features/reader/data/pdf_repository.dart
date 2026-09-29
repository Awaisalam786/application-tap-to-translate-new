// lib/features/reader/data/pdf_repository.dart

import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

/// Represents a source from which a PDF document can be opened.
enum PdfDocumentSourceType { asset, file }

class PdfDocumentDescriptor {
  final String title;
  final String path;
  final PdfDocumentSourceType type;

  const PdfDocumentDescriptor({
    required this.title,
    required this.path,
    required this.type,
  });
}

/// Repository responsible for resolving and preparing PDF documents.
class PdfRepository {
  const PdfRepository();

  /// Standard bundled German reference documents for testing and evaluation.
  static const sampleGermanDoc = PdfDocumentDescriptor(
    title: 'Deutsches Lesebuch (Geometrie & Tabellen)',
    path: 'assets/test_german_comprehensive.pdf',
    type: PdfDocumentSourceType.asset,
  );

  static const sampleThesisDoc = PdfDocumentDescriptor(
    title: 'KIT Bachelorarbeit (Akademisches Dokument)',
    path: 'assets/kit_thesis.pdf',
    type: PdfDocumentSourceType.asset,
  );

  static const sampleScannedGermanDoc = PdfDocumentDescriptor(
    title: 'Gescannter Text (OCR ML Kit Test)',
    path: 'assets/scanned_german_test.pdf',
    type: PdfDocumentSourceType.asset,
  );

  /// Prepares an asset PDF for file-based access if needed, or returns existing path.
  Future<File> copyAssetToLocalFile(String assetPath) async {
    final byteData = await rootBundle.load(assetPath);
    final tempDir = await getTemporaryDirectory();
    final fileName = assetPath.split('/').last;
    final file = File('${tempDir.path}/$fileName');
    await file.writeAsBytes(byteData.buffer.asUint8List(), flush: true);
    return file;
  }
}
