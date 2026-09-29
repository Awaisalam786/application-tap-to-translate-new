// lib/features/translation/domain/models/lexicon_entry_status.dart

/// Verification and curation status of a lexical entry or translation sense.
///
/// Invariant: Machine-generated or online fallback translations must NEVER
/// be automatically promoted to [verified] or [curated].
enum LexiconEntryStatus {
  /// Newly ingested or user-submitted word pending initial pipeline check.
  newEntry(code: 'NEW', displayName: 'Neu eingetragen'),

  /// Generated via automated machine translation or automated heuristic parsing.
  machineGenerated(code: 'MACHINE_GENERATED', displayName: 'Maschinell erzeugt'),

  /// Flagged for linguistic or editorial review (e.g. uncertain gender or polysemy).
  review(code: 'REVIEW', displayName: 'In Prüfung'),

  /// Cross-verified against authoritative open dictionaries (e.g. Wiktionary, FreeDict).
  verified(code: 'VERIFIED', displayName: 'Verifiziert'),

  /// Manually curated and vetted by German lexicographers or editors.
  curated(code: 'CURATED', displayName: 'Kuriert');

  final String code;
  final String displayName;

  const LexiconEntryStatus({
    required this.code,
    required this.displayName,
  });

  static LexiconEntryStatus fromCode(String code) {
    for (final status in LexiconEntryStatus.values) {
      if (status.code == code) return status;
    }
    return LexiconEntryStatus.newEntry;
  }
}
