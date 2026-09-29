// lib/features/translation/data/fixtures/dev_german_lexicon_fixture.dart

import '../../domain/models/translation_target_language.dart';

/// ============================================================================
/// WARNING: TEMPORARY DETERMINISTIC FIXTURE — DEVELOPMENT & TESTING ONLY
/// ============================================================================
/// This in-memory lexicon fixture is strictly designed for local testing and
/// development validation during Phase 4.
///
/// DO NOT TREAT THIS AS THE FINAL PRODUCTION DICTIONARY.
/// In production, the GermanLexiconRepository contract will be backed by a licensed
/// or open-source offline dataset (e.g. FreeDict, Wiktionary German dump) with
/// tens of thousands of lemmas and full inflectional paradigms.
/// ============================================================================

class DevLexiconEntry {
  final String lemma;
  final String? gender; // der, die, das
  final String? partOfSpeech; // Nomen, Verb, Adjektiv
  final Map<TranslationTargetLanguage, String> translations;
  final Map<TranslationTargetLanguage, List<String>> secondaryTranslations;
  final String? exampleSentenceDe;
  final Map<TranslationTargetLanguage, String> exampleTranslations;

  const DevLexiconEntry({
    required this.lemma,
    this.gender,
    this.partOfSpeech,
    required this.translations,
    this.secondaryTranslations = const {},
    this.exampleSentenceDe,
    this.exampleTranslations = const {},
  });
}

/// Deterministic test dictionary for Phase 4.
/// Contains all required test words across English, Urdu, Farsi, and Arabic.
const Map<String, DevLexiconEntry> kDevGermanLexiconFixture = {
  // 1. Deutschland (Mandatory test word)
  'Deutschland': DevLexiconEntry(
    lemma: 'Deutschland',
    gender: 'das',
    partOfSpeech: 'Substantiv (Eigenname)',
    translations: {
      TranslationTargetLanguage.english: 'Germany',
      TranslationTargetLanguage.urdu: 'جرمنی',
      TranslationTargetLanguage.farsi: 'آلمان',
      TranslationTargetLanguage.arabic: 'ألمانيا',
    },
    secondaryTranslations: {
      TranslationTargetLanguage.english: ['Federal Republic of Germany'],
      TranslationTargetLanguage.urdu: ['وفاقی جمہوریہ جرمنی'],
      TranslationTargetLanguage.farsi: ['جمهوری فدرال آلمان'],
      TranslationTargetLanguage.arabic: ['جمهورية ألمانيا الاتحادية'],
    },
    exampleSentenceDe: 'Ich lebe und lerne in Deutschland.',
    exampleTranslations: {
      TranslationTargetLanguage.english: 'I live and learn in Germany.',
      TranslationTargetLanguage.urdu: 'میں جرمنی میں رہتا اور سیکھتا ہوں۔',
      TranslationTargetLanguage.farsi: 'من در آلمان زندگی می‌کنم و یاد می‌گیرم.',
      TranslationTargetLanguage.arabic: 'أنا أعيش وأتعلم في ألمانيا.',
    },
  ),

  // 2. arbeiten (Mandatory test word)
  'arbeiten': DevLexiconEntry(
    lemma: 'arbeiten',
    partOfSpeech: 'Verb',
    translations: {
      TranslationTargetLanguage.english: 'to work',
      TranslationTargetLanguage.urdu: 'کام کرنا',
      TranslationTargetLanguage.farsi: 'کار کردن',
      TranslationTargetLanguage.arabic: 'يعمل / اشتغل',
    },
    secondaryTranslations: {
      TranslationTargetLanguage.english: ['labor', 'function', 'operate'],
      TranslationTargetLanguage.urdu: ['محنت کرنا', 'ملازمت کرنا'],
      TranslationTargetLanguage.farsi: ['فعالیت کردن', 'زحمت کشیدن'],
      TranslationTargetLanguage.arabic: ['يشتغل', 'يكدح'],
    },
    exampleSentenceDe: 'Sie arbeiten heute im Büro.',
    exampleTranslations: {
      TranslationTargetLanguage.english: 'They are working in the office today.',
      TranslationTargetLanguage.urdu: 'وہ آج دفتر میں کام کر رہے ہیں۔',
      TranslationTargetLanguage.farsi: 'آن‌ها امروز در دفتر کار می‌کنند.',
      TranslationTargetLanguage.arabic: 'هم يعملون في المكتب اليوم.',
    },
  ),

  // 3. Möglichkeit (Mandatory test word with Umlaut 'ö')
  'Möglichkeit': DevLexiconEntry(
    lemma: 'Möglichkeit',
    gender: 'die',
    partOfSpeech: 'Substantiv',
    translations: {
      TranslationTargetLanguage.english: 'possibility, opportunity',
      TranslationTargetLanguage.urdu: 'امکان / موقع',
      TranslationTargetLanguage.farsi: 'امکان / فرصت',
      TranslationTargetLanguage.arabic: 'إمكانية / فرصة',
    },
    secondaryTranslations: {
      TranslationTargetLanguage.english: ['option', 'chance', 'feasibility'],
      TranslationTargetLanguage.urdu: ['صورت', 'گنجائش'],
      TranslationTargetLanguage.farsi: ['احتمال', 'گزینه'],
      TranslationTargetLanguage.arabic: ['احتمال', 'خيار'],
    },
    exampleSentenceDe: 'Es gibt viele Möglichkeiten, Deutsch zu üben.',
    exampleTranslations: {
      TranslationTargetLanguage.english: 'There are many possibilities to practice German.',
      TranslationTargetLanguage.urdu: 'جرمن زبان کی مشق کے بہت سے مواقع ہیں۔',
      TranslationTargetLanguage.farsi: 'فرصت‌های زیادی برای تمرین آلمانی وجود دارد.',
      TranslationTargetLanguage.arabic: 'هناك العديد من الفرص لممارسة اللغة الألمانية.',
    },
  ),

  // 4. normal (Mandatory test word)
  'normal': DevLexiconEntry(
    lemma: 'normal',
    partOfSpeech: 'Adjektiv',
    translations: {
      TranslationTargetLanguage.english: 'normal, standard',
      TranslationTargetLanguage.urdu: 'عام / معمول',
      TranslationTargetLanguage.farsi: 'عادی / معمول',
      TranslationTargetLanguage.arabic: 'عادي / طبيعي',
    },
    secondaryTranslations: {
      TranslationTargetLanguage.english: ['regular', 'ordinary', 'typical'],
      TranslationTargetLanguage.urdu: ['معمول کے مطابق', 'روایتی'],
      TranslationTargetLanguage.farsi: ['طبیعی', 'استاندارد'],
      TranslationTargetLanguage.arabic: ['اعتيادي', 'نموذجي'],
    },
    exampleSentenceDe: 'Das ist ganz normal.',
    exampleTranslations: {
      TranslationTargetLanguage.english: 'That is completely normal.',
      TranslationTargetLanguage.urdu: 'یہ بالکل عام بات ہے۔',
      TranslationTargetLanguage.farsi: 'این کاملاً عادی است.',
      TranslationTargetLanguage.arabic: 'هذا أمر طبيعي تمامًا.',
    },
  ),

  // 5. lernen (Mandatory test word)
  'lernen': DevLexiconEntry(
    lemma: 'lernen',
    partOfSpeech: 'Verb',
    translations: {
      TranslationTargetLanguage.english: 'to learn, to study',
      TranslationTargetLanguage.urdu: 'سیکھنا / پڑھنا',
      TranslationTargetLanguage.farsi: 'یاد گرفتن / آموختن',
      TranslationTargetLanguage.arabic: 'يتعلم / يدرس',
    },
    secondaryTranslations: {
      TranslationTargetLanguage.english: ['acquire knowledge', 'memorize'],
      TranslationTargetLanguage.urdu: ['حفظ کرنا', 'علم حاصل کرنا'],
      TranslationTargetLanguage.farsi: ['فرا گرفتن', 'درس خواندن'],
      TranslationTargetLanguage.arabic: ['يتحصل العلم', 'يحفظ'],
    },
    exampleSentenceDe: 'Wir lernen jeden Tag neue Wörter.',
    exampleTranslations: {
      TranslationTargetLanguage.english: 'We learn new words every day.',
      TranslationTargetLanguage.urdu: 'ہم ہر روز نئے الفاظ سیکھتے ہیں۔',
      TranslationTargetLanguage.farsi: 'ما هر روز کلمات جدیدی یاد می‌گیریم.',
      TranslationTargetLanguage.arabic: 'نحن نتعلم كلمات جديدة كل يوم.',
    },
  ),

  // 6. Buch (Mandatory test word)
  'Buch': DevLexiconEntry(
    lemma: 'Buch',
    gender: 'das',
    partOfSpeech: 'Substantiv',
    translations: {
      TranslationTargetLanguage.english: 'book',
      TranslationTargetLanguage.urdu: 'کتاب',
      TranslationTargetLanguage.farsi: 'کتاب',
      TranslationTargetLanguage.arabic: 'كتاب',
    },
    secondaryTranslations: {
      TranslationTargetLanguage.english: ['volume', 'tome'],
      TranslationTargetLanguage.urdu: ['رسالہ', 'جلد'],
      TranslationTargetLanguage.farsi: ['جلد', 'نسخه'],
      TranslationTargetLanguage.arabic: ['مجلد', 'سفر'],
    },
    exampleSentenceDe: 'Dieses Buch ist sehr nützlich.',
    exampleTranslations: {
      TranslationTargetLanguage.english: 'This book is very useful.',
      TranslationTargetLanguage.urdu: 'یہ کتاب بہت مفید ہے۔',
      TranslationTargetLanguage.farsi: 'این کتاب بسیار مفید است.',
      TranslationTargetLanguage.arabic: 'هذا الكتاب مفيد جداً.',
    },
  ),

  // 7. Haus (Mandatory test word)
  'Haus': DevLexiconEntry(
    lemma: 'Haus',
    gender: 'das',
    partOfSpeech: 'Substantiv',
    translations: {
      TranslationTargetLanguage.english: 'house, home, building',
      TranslationTargetLanguage.urdu: 'گھر / مکان',
      TranslationTargetLanguage.farsi: 'خانه / ساختمان',
      TranslationTargetLanguage.arabic: 'منزل / بيت / دار',
    },
    secondaryTranslations: {
      TranslationTargetLanguage.english: ['residence', 'dwelling'],
      TranslationTargetLanguage.urdu: ['رہائش گاہ'],
      TranslationTargetLanguage.farsi: ['اقامتگاه', 'مسکن'],
      TranslationTargetLanguage.arabic: ['مسكن', 'بناية'],
    },
    exampleSentenceDe: 'Sie gehen nach Hause.',
    exampleTranslations: {
      TranslationTargetLanguage.english: 'They are going home.',
      TranslationTargetLanguage.urdu: 'وہ گھر جا رہے ہیں۔',
      TranslationTargetLanguage.farsi: 'آن‌ها به خانه می‌روند.',
      TranslationTargetLanguage.arabic: 'هم ذاهبون إلى المنزل.',
    },
  ),

  // 8. Fußball (Test word with Eszett 'ß')
  'Fußball': DevLexiconEntry(
    lemma: 'Fußball',
    gender: 'der',
    partOfSpeech: 'Substantiv',
    translations: {
      TranslationTargetLanguage.english: 'football, soccer',
      TranslationTargetLanguage.urdu: 'فٹ بال',
      TranslationTargetLanguage.farsi: 'فوتبال',
      TranslationTargetLanguage.arabic: 'كرة القدم',
    },
    exampleSentenceDe: 'Fußball ist in Deutschland sehr beliebt.',
    exampleTranslations: {
      TranslationTargetLanguage.english: 'Football is very popular in Germany.',
      TranslationTargetLanguage.urdu: 'جرمنی میں فٹ بال بہت مقبول ہے۔',
      TranslationTargetLanguage.farsi: 'فوتبال در آلمان بسیار محبوب است.',
      TranslationTargetLanguage.arabic: 'كرة القدم تحظى بشعبية كبيرة في ألمانيا.',
    },
  ),

  // 9. größer (Test word with Umlaut 'ö' and Eszett 'ß')
  'größer': DevLexiconEntry(
    lemma: 'größer',
    partOfSpeech: 'Adjektiv (Komparativ)',
    translations: {
      TranslationTargetLanguage.english: 'bigger, larger, taller',
      TranslationTargetLanguage.urdu: 'بڑا / زیادہ بڑا',
      TranslationTargetLanguage.farsi: 'بزرگ‌تر',
      TranslationTargetLanguage.arabic: 'أكبر / أضخم',
    },
    exampleSentenceDe: 'Das neue Haus ist viel größer als das alte.',
    exampleTranslations: {
      TranslationTargetLanguage.english: 'The new house is much larger than the old one.',
      TranslationTargetLanguage.urdu: 'نیا مکان پرانے سے بہت بڑا ہے۔',
      TranslationTargetLanguage.farsi: 'خانه جدید بسیار بزرگ‌تر از خانه قدیمی است.',
      TranslationTargetLanguage.arabic: 'المنزل الجديد أكبر بكثير من القديم.',
    },
  ),

  // 10. Mädchen (Test word with Umlaut 'ä')
  'Mädchen': DevLexiconEntry(
    lemma: 'Mädchen',
    gender: 'das',
    partOfSpeech: 'Substantiv',
    translations: {
      TranslationTargetLanguage.english: 'girl',
      TranslationTargetLanguage.urdu: 'لڑکی',
      TranslationTargetLanguage.farsi: 'دختر',
      TranslationTargetLanguage.arabic: 'فتاة / بنت',
    },
    exampleSentenceDe: 'Das Mädchen liest ein deutsches Buch.',
    exampleTranslations: {
      TranslationTargetLanguage.english: 'The girl is reading a German book.',
      TranslationTargetLanguage.urdu: 'لڑکی جرمن کتاب پڑھ رہی ہے۔',
      TranslationTargetLanguage.farsi: 'دختر در حال خواندن یک کتاب آلمانی است.',
      TranslationTargetLanguage.arabic: 'الفتاة تقرأ كتاباً ألمانياً.',
    },
  ),

  // 11. Zusammenfassung (KIT Thesis document test word)
  'Zusammenfassung': DevLexiconEntry(
    lemma: 'Zusammenfassung',
    gender: 'die',
    partOfSpeech: 'Substantiv',
    translations: {
      TranslationTargetLanguage.english: 'summary, abstract',
      TranslationTargetLanguage.urdu: 'خلاصہ',
      TranslationTargetLanguage.farsi: 'خلاصه / چکیده',
      TranslationTargetLanguage.arabic: 'ملخص / موجز',
    },
    exampleSentenceDe: 'Die Deutsche Zusammenfassung fasst die Arbeit zusammen.',
    exampleTranslations: {
      TranslationTargetLanguage.english: 'The German summary abstracts the thesis.',
      TranslationTargetLanguage.urdu: 'جرمن خلاصہ مقالے کا جائزہ پیش کرتا ہے۔',
      TranslationTargetLanguage.farsi: 'خلاصه آلمانی پایان‌نامه را جمع‌بندی می‌کند.',
      TranslationTargetLanguage.arabic: 'الملخص الألماني يوجز أطروحة البحث.',
    },
  ),
};
