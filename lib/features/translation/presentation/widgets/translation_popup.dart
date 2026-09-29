// lib/features/translation/presentation/widgets/translation_popup.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/translation_source.dart';
import '../../domain/models/translation_status.dart';
import '../../domain/models/translation_target_language.dart';
import '../controllers/translation_controller.dart';

/// Clean, responsive Translation Popup card rendered when an exact German word
/// is tapped in the PDF reader.
class TranslationPopup extends ConsumerWidget {
  final VoidCallback? onClose;

  const TranslationPopup({
    super.key,
    this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(translationControllerProvider);
    final notifier = ref.read(translationControllerProvider.notifier);
    final result = state.currentResult;

    if (result == null) {
      return const SizedBox.shrink();
    }

    final query = result.query;
    final isRtl = state.targetLanguage.isRtl;

    return Material(
      color: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 550),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─────────────────────────────────────────────────────────────────
            // 1. Header: Original Word, Lemma, Gender, Audio, Close
            // ─────────────────────────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Gender badge if German noun
                if (result.gender != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: _getGenderColor(result.gender!).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _getGenderColor(result.gender!),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      result.gender!,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: _getGenderColor(result.gender!),
                      ),
                    ),
                  ),
                ],

                // Normalized lemma & raw word display
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.query.normalizedWord,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.2,
                        ),
                      ),
                      if (query.rawWord != query.normalizedWord)
                        Text(
                          'Im PDF: "${query.rawWord}"',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                    ],
                  ),
                ),

                // Audio Pronunciation Button (Placeholder / Interface)
                IconButton(
                  icon: const Icon(Icons.volume_up, size: 20),
                  tooltip: 'Aussprache anhören',
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: notifier.playPronunciation,
                ),

                // Close Button
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  tooltip: 'Schließen',
                  onPressed: () {
                    notifier.dismissPopup();
                    onClose?.call();
                  },
                ),
              ],
            ),

            const SizedBox(height: 10),

            // ─────────────────────────────────────────────────────────────────
            // 2. Language Selector Row
            // ─────────────────────────────────────────────────────────────────
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: TranslationTargetLanguage.values.map((lang) {
                  final isSelected = lang == state.targetLanguage;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      label: Text('${lang.flagEmoji} ${lang.englishName}'),
                      selected: isSelected,
                      onSelected: (_) => notifier.setTargetLanguage(lang),
                    ),
                  );
                }).toList(),
              ),
            ),

            const Divider(height: 16),

            // ─────────────────────────────────────────────────────────────────
            // 3. Translation Body (Loading, Success, or NOT_FOUND)
            // ─────────────────────────────────────────────────────────────────
            if (state.isLoading) ...[
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2.5),
                  ),
                ),
              ),
            ] else if (result.isSuccess) ...[
              // Primary Translation (with RTL support)
              Directionality(
                textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                child: Text(
                  result.primaryTranslation ?? '',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                    height: 1.25,
                  ),
                ),
              ),

              // Part of speech
              if (result.partOfSpeech != null) ...[
                const SizedBox(height: 2),
                Text(
                  result.partOfSpeech!,
                  style: TextStyle(
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                    color: Colors.grey[700],
                  ),
                ),
              ],

              // Secondary Translations
              if (result.secondaryTranslations.isNotEmpty) ...[
                const SizedBox(height: 4),
                Directionality(
                  textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                  child: Text(
                    result.secondaryTranslations.join(', '),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ],

              // Example Sentence
              if (result.exampleSentenceDe != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        result.exampleSentenceDe!,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                      if (result.exampleSentenceTranslation != null) ...[
                        const SizedBox(height: 2),
                        Directionality(
                          textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
                          child: Text(
                            result.exampleSentenceTranslation!,
                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ] else if (result.isNotFound) ...[
              // Explicit NOT_FOUND State
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.shade700, width: 1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_off, color: Colors.amber.shade900, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Wort nicht im Lexikon gefunden',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.amber.shade900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Kein Treffer im Offline-Wörterbuch. (Keine erfundene Übersetzung)',
                            style: TextStyle(fontSize: 11, color: Colors.black87),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 12),

            // ─────────────────────────────────────────────────────────────────
            // 4. Footer: Provenance Badge & "My Words" Save Action
            // ─────────────────────────────────────────────────────────────────
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 6,
              children: [
                // Source / Provenance Badge
                _buildSourceBadge(context, result.source, result.status),

                // "Add to My Words" Action
                if (result.isSuccess)
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    icon: Icon(
                      state.isSavedToMyWords
                          ? Icons.bookmark
                          : Icons.bookmark_border,
                      size: 16,
                      color: state.isSavedToMyWords ? Colors.deepOrange : null,
                    ),
                    label: Text(
                      state.isSavedToMyWords
                          ? 'Gespeichert'
                          : 'Zu Meine Wörter',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: state.isSavedToMyWords
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    onPressed: notifier.toggleSaveToMyWords,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getGenderColor(String gender) {
    switch (gender.toLowerCase()) {
      case 'der':
        return Colors.blue.shade700;
      case 'die':
        return Colors.red.shade700;
      case 'das':
        return Colors.green.shade700;
      default:
        return Colors.grey.shade700;
    }
  }

  Widget _buildSourceBadge(
    BuildContext context,
    TranslationSource source,
    TranslationStatus status,
  ) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    if (status == TranslationStatus.notFound) {
      bg = Colors.grey.shade200;
      fg = Colors.grey.shade800;
      label = 'NICHT GEFUNDEN';
      icon = Icons.not_interested;
    } else {
      switch (source) {
        case TranslationSource.localLexicon:
          bg = Colors.green.shade50;
          fg = Colors.green.shade900;
          label = 'LOKALES LEXIKON';
          icon = Icons.storage;
          break;
        case TranslationSource.cache:
          bg = Colors.blue.shade50;
          fg = Colors.blue.shade900;
          label = 'CACHE';
          icon = Icons.cached;
          break;
        case TranslationSource.onlineFallback:
          bg = Colors.purple.shade50;
          fg = Colors.purple.shade900;
          label = 'ONLINE-FALLBACK';
          icon = Icons.cloud_outlined;
          break;
        case TranslationSource.none:
          bg = Colors.grey.shade200;
          fg = Colors.grey.shade800;
          label = 'KEINE QUELLE';
          icon = Icons.help_outline;
          break;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: fg.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: fg,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
