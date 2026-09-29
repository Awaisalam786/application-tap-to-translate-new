// lib/features/translation/domain/repositories/german_inflection_resolver.dart

/// Contract distinguishing surface text normalization from true morphological lemma resolution.
///
/// INVARIANT:
/// Do NOT implement a fake or rule-guessing German lemmatizer.
/// German grammatical inflection is highly non-linear (Ablaut: e.g. "ging" -> "gehen",
/// Umlaut plural: e.g. "Häuser" -> "Haus"). Morphological mapping must be backed
/// by verified inflectional tables rather than heuristic suffix stripping.
abstract class GermanInflectionResolver {
  /// Strips typographical punctuation, German quotes, and spacing.
  String normalizeSurface(String rawWord);

  /// Resolves an inflected German surface form to its canonical lemma
  /// via verified morphological index.
  /// Returns `null` if the form is already a lemma or not found in the inflection index.
  String? resolveToLemma(String surfaceWord);

  /// Generates search key variants including:
  /// - Standard German casing (Capitalized Noun, lowercase Verb/Adjective)
  /// - Swiss German / ASCII orthographic aliases (ß <-> ss, ä <-> ae, ö <-> oe, ü <-> ue)
  List<String> generateSearchVariants(String normalizedWord);
}
