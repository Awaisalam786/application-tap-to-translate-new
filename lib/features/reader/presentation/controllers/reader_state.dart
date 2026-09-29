// lib/features/reader/presentation/controllers/reader_state.dart

import '../../../../core/models/page_geometry.dart';
import '../../../../core/models/selection_result.dart';
import '../../../../core/models/word_occurrence.dart';
import '../../data/pdf_repository.dart';

class ReaderState {
  final PdfDocumentDescriptor? document;
  final int currentPage;
  final int totalPages;
  final double currentZoom;
  final bool isReady;
  final bool isLoading;
  final bool isDebugMode;
  final Map<int, PageGeometry> pageGeometries;
  final SelectionResult? lastSelection;
  final String? errorMessage;

  const ReaderState({
    this.document,
    this.currentPage = 1,
    this.totalPages = 0,
    this.currentZoom = 1.0,
    this.isReady = false,
    this.isLoading = false,
    this.isDebugMode = false,
    this.pageGeometries = const {},
    this.lastSelection,
    this.errorMessage,
  });

  WordOccurrence? get selectedWord => lastSelection?.word;

  ReaderState copyWith({
    PdfDocumentDescriptor? document,
    int? currentPage,
    int? totalPages,
    double? currentZoom,
    bool? isReady,
    bool? isLoading,
    bool? isDebugMode,
    Map<int, PageGeometry>? pageGeometries,
    SelectionResult? lastSelection,
    bool clearSelection = false,
    String? errorMessage,
  }) {
    return ReaderState(
      document: document ?? this.document,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
      currentZoom: currentZoom ?? this.currentZoom,
      isReady: isReady ?? this.isReady,
      isLoading: isLoading ?? this.isLoading,
      isDebugMode: isDebugMode ?? this.isDebugMode,
      pageGeometries: pageGeometries ?? this.pageGeometries,
      lastSelection: clearSelection ? null : (lastSelection ?? this.lastSelection),
      errorMessage: errorMessage,
    );
  }
}
