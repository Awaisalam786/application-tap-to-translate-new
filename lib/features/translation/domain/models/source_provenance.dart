// lib/features/translation/domain/models/source_provenance.dart

/// Retains full legal provenance and attribution tracking for every lexical entry.
/// Answers the mandatory architectural question: "Where did this translation come from?"
class SourceProvenance {
  /// Name of the upstream data source (e.g. 'Wiktionary', 'FreeDict', 'OpenThesaurus', 'ManualCurated').
  final String source;

  /// Upstream unique identifier, article title, or page ID in the primary database.
  final String sourceId;

  /// SPDX or exact license identifier (e.g. 'CC-BY-SA-4.0', 'GPL-3.0-or-later', 'CC-BY-2.0-FR').
  final String license;

  /// Human-readable attribution string required by license compliance.
  final String provenance;

  /// Ingestion pipeline batch version (e.g. 'v1.0.0-2026Q1').
  final String version;

  /// Timestamp when this entry was ingested or updated.
  final DateTime updatedAt;

  const SourceProvenance({
    required this.source,
    required this.sourceId,
    required this.license,
    required this.provenance,
    required this.version,
    required this.updatedAt,
  });

  Map<String, dynamic> toJson() => {
        'source': source,
        'sourceId': sourceId,
        'license': license,
        'provenance': provenance,
        'version': version,
        'updatedAt': updatedAt.toIso8601String(),
      };

  factory SourceProvenance.fromJson(Map<String, dynamic> json) =>
      SourceProvenance(
        source: json['source'] as String,
        sourceId: json['sourceId'] as String,
        license: json['license'] as String,
        provenance: json['provenance'] as String,
        version: json['version'] as String,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
      );

  @override
  String toString() =>
      'SourceProvenance(source: "$source", id: "$sourceId", lic: "$license")';
}
