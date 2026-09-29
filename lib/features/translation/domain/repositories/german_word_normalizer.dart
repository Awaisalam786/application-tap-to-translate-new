// lib/features/translation/domain/repositories/german_word_normalizer.dart

/// Contract for normalizing German tokens tapped in a PDF before dictionary lookup.
abstract class GermanWordNormalizer {
  /// Strips extraneous punctuation, German quotes („...“, «...»), and handles
  /// capitalization while preserving German umlauts (ä, ö, ü, Ä, Ö, Ü) and Eszett (ß).
  String normalize(String rawWord);

  /// Generates prioritized candidate lemmas for lexicon lookup (e.g. Capitalized Noun,
  /// lowercase verb/adjective).
  List<String> generateLookupCandidates(String rawWord);
}
