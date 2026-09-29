// lib/features/translation/domain/models/translation_target_language.dart

/// Supported translation target languages.
/// Designed for extensibility: new languages can be registered without
/// altering the reader architecture or hit-testing logic.
enum TranslationTargetLanguage {
  english(
    code: 'en',
    englishName: 'English',
    nativeName: 'English',
    flagEmoji: '🇬🇧',
    isRtl: false,
  ),
  urdu(
    code: 'ur',
    englishName: 'Urdu',
    nativeName: 'اردو',
    flagEmoji: '🇵🇰',
    isRtl: true,
  ),
  farsi(
    code: 'fa',
    englishName: 'Farsi',
    nativeName: 'فارسی',
    flagEmoji: '🇮🇷',
    isRtl: true,
  ),
  arabic(
    code: 'ar',
    englishName: 'Arabic',
    nativeName: 'العربية',
    flagEmoji: '🇸🇦',
    isRtl: true,
  );

  final String code;
  final String englishName;
  final String nativeName;
  final String flagEmoji;
  final bool isRtl;

  const TranslationTargetLanguage({
    required this.code,
    required this.englishName,
    required this.nativeName,
    required this.flagEmoji,
    required this.isRtl,
  });

  /// Factory helper to resolve language by ISO code (case-insensitive).
  static TranslationTargetLanguage fromCode(String code) {
    final lower = code.toLowerCase().trim();
    for (final lang in TranslationTargetLanguage.values) {
      if (lang.code == lower) return lang;
    }
    return TranslationTargetLanguage.english;
  }
}
