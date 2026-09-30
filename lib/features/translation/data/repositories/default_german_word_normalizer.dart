// lib/features/translation/data/repositories/default_german_word_normalizer.dart

import '../../domain/repositories/german_word_normalizer.dart';

/// Production implementation of [GermanWordNormalizer].
///
/// Preserves German orthographic invariants:
/// - Umlauts (ä, ö, ü, Ä, Ö, Ü) are preserved without lossy ASCII-folding.
/// - Eszett (ß) is strictly preserved and not folded to 'ss'.
/// - German typographical quotes („...“, «...», »...«, "...") are cleanly stripped.
/// - Outer punctuation (.,;:!?()[]{}-—) is stripped.
class DefaultGermanWordNormalizer implements GermanWordNormalizer {
  const DefaultGermanWordNormalizer();

  static const String _punctuationChars =
      '„“"\'«»›‹()[]{}<>—–-_.,;:!?\r\n\t ';

  @override
  String normalize(String rawWord) {
    if (rawWord.isEmpty) return '';

    int start = 0;
    while (start < rawWord.length && _punctuationChars.contains(rawWord[start])) {
      start++;
    }

    int end = rawWord.length;
    while (end > start && _punctuationChars.contains(rawWord[end - 1])) {
      end--;
    }

    if (start >= end) return '';
    return rawWord.substring(start, end).trim();
  }

  @override
  List<String> generateLookupCandidates(String rawWord) {
    final cleaned = normalize(rawWord);
    if (cleaned.isEmpty) return const [];

    final candidates = <String>{};

    // 1. As-is cleaned word (maintains original German casing)
    candidates.add(cleaned);

    // 2. Capitalized variant (Standard German noun form: e.g. "buch" -> "Buch")
    if (cleaned.isNotEmpty) {
      final capitalized =
          cleaned[0].toUpperCase() + cleaned.substring(1).toLowerCase();
      candidates.add(capitalized);
    }

    // 3. Fully lowercase variant (Standard German verb/adj form: e.g. "Arbeiten" -> "arbeiten")
    candidates.add(cleaned.toLowerCase());

    return candidates.toList();
  }

  @override
  String toCanonicalLookupKey(String rawWord) {
    final cleaned = normalize(rawWord);
    return cleaned.toLowerCase().trim();
  }
}
