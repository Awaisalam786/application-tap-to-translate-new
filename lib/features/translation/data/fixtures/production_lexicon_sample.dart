// lib/features/translation/data/fixtures/production_lexicon_sample.dart

import '../../domain/models/lexicon_entry.dart';
import '../../domain/models/lexicon_entry_status.dart';
import '../../domain/models/lexicon_translation.dart';
import '../../domain/models/source_provenance.dart';

/// ============================================================================
/// PRODUCTION-COMPLIANT SAMPLE LEXICAL DATASET (DEVELOPMENT / TEST VALIDATION)
/// ============================================================================
/// Conforms to the full Phase 5 production schema:
/// - Rigorous source provenance (Wiktionary CC BY-SA 4.0 & FreeDict GPL 3.0)
/// - Extensible multilingual translation list (en, ur, fa, ar)
/// - Distinct inflection tables (verb tenses, noun plurals, adjective comparatives)
/// - Orthographic variants (ß <-> ss, umlauts)
/// ============================================================================

final SourceProvenance _kWiktionaryProvenance = SourceProvenance(
  source: 'Wiktionary',
  sourceId: 'de.wiktionary.org',
  license: 'CC-BY-SA-4.0',
  provenance: 'Wiktionary contributors via Wiktextract parsed dataset',
  version: '2026.01-sample',
  updatedAt: DateTime.utc(2026, 1, 15),
);

final List<LexiconEntry> kProductionSampleLexicon = [
  // 1. Deutschland
  LexiconEntry(
    word: 'Deutschland',
    lemma: 'Deutschland',
    article: 'das',
    partOfSpeech: 'Substantiv',
    gender: 'Neutrum',
    meanings: const [
      'Staat in Mitteleuropa; Bundesrepublik Deutschland',
    ],
    synonyms: const ['Bundesrepublik Deutschland', 'BRD'],
    examples: const ['Ich wohne in Deutschland.'],
    pronunciation: '/ˈdɔɪ̯t͡ʃlant/',
    language: 'de',
    status: LexiconEntryStatus.curated,
    confidence: 1.0,
    updatedAt: DateTime.utc(2026, 1, 15),
    provenance: _kWiktionaryProvenance,
    inflectedForms: const ['Deutschlands', 'deutschland'],
    translations: [
      LexiconTranslation(
        language: 'en',
        meanings: const ['Germany', 'Federal Republic of Germany'],
        exampleTranslation: 'I live in Germany.',
        status: LexiconEntryStatus.curated,
        provenance: _kWiktionaryProvenance,
      ),
      LexiconTranslation(
        language: 'ur',
        meanings: const ['جرمنی', 'وفاقی جمہوریہ جرمنی'],
        exampleTranslation: 'میں جرمنی میں رہتا ہوں۔',
        status: LexiconEntryStatus.curated,
        provenance: _kWiktionaryProvenance,
      ),
      LexiconTranslation(
        language: 'fa',
        meanings: const ['آلمان', 'جمهوری فدرال آلمان'],
        exampleTranslation: 'من در آلمان زندگی می‌کنم.',
        status: LexiconEntryStatus.curated,
        provenance: _kWiktionaryProvenance,
      ),
      LexiconTranslation(
        language: 'ar',
        meanings: const ['ألمانيا', 'جمهورية ألمانيا الاتحادية'],
        exampleTranslation: 'أنا أعيش في ألمانيا.',
        status: LexiconEntryStatus.curated,
        provenance: _kWiktionaryProvenance,
      ),
    ],
  ),

  // 2. deutsch
  LexiconEntry(
    word: 'deutsch',
    lemma: 'deutsch',
    partOfSpeech: 'Adjektiv',
    meanings: const [
      'die Sprache Deutsch betreffend oder aus Deutschland stammend',
    ],
    synonyms: const ['germanisch'],
    examples: const ['Sie spricht fließend deutsch.'],
    pronunciation: '/dɔɪ̯t͡ʃ/',
    language: 'de',
    status: LexiconEntryStatus.curated,
    confidence: 1.0,
    updatedAt: DateTime.utc(2026, 1, 15),
    provenance: _kWiktionaryProvenance,
    inflectedForms: const ['deutsche', 'deutschen', 'deutscher', 'deutsches', 'Deutsch'],
    translations: [
      LexiconTranslation(
        language: 'en',
        meanings: const ['German'],
        exampleTranslation: 'She speaks fluent German.',
        status: LexiconEntryStatus.curated,
        provenance: _kWiktionaryProvenance,
      ),
      LexiconTranslation(
        language: 'ur',
        meanings: const ['جرمن'],
        exampleTranslation: 'وہ روانی سے جرمن بولتی ہے۔',
        status: LexiconEntryStatus.curated,
        provenance: _kWiktionaryProvenance,
      ),
      LexiconTranslation(
        language: 'fa',
        meanings: const ['آلمانی'],
        exampleTranslation: 'او روان آلمانی صحبت می‌کند.',
        status: LexiconEntryStatus.curated,
        provenance: _kWiktionaryProvenance,
      ),
      LexiconTranslation(
        language: 'ar',
        meanings: const ['ألماني'],
        exampleTranslation: 'هي تتحدث الألمانية بطلاقة.',
        status: LexiconEntryStatus.curated,
        provenance: _kWiktionaryProvenance,
      ),
    ],
  ),

  // 3. arbeiten (Verb with past tense "arbeitete")
  LexiconEntry(
    word: 'arbeiten',
    lemma: 'arbeiten',
    partOfSpeech: 'Verb',
    meanings: const [
      'eine zielgerichtete körperliche oder geistige Tätigkeit ausüben',
    ],
    synonyms: const ['tätig sein', 'wirken', 'schaffen', 'werkeln'],
    examples: const ['Er arbeitete gestern den ganzen Tag.'],
    pronunciation: '/ˈaʁbaɪ̯tn̩/',
    language: 'de',
    status: LexiconEntryStatus.curated,
    confidence: 1.0,
    updatedAt: DateTime.utc(2026, 1, 15),
    provenance: _kWiktionaryProvenance,
    inflectedForms: const [
      'arbeite',
      'arbeitest',
      'arbeitet',
      'arbeitete',
      'arbeiteten',
      'arbeitetet',
      'gearbeitet',
      'Arbeiten',
    ],
    translations: [
      LexiconTranslation(
        language: 'en',
        meanings: const ['to work', 'to labor', 'to function'],
        exampleTranslation: 'He worked all day yesterday.',
        status: LexiconEntryStatus.curated,
        provenance: _kWiktionaryProvenance,
      ),
      LexiconTranslation(
        language: 'ur',
        meanings: const ['کام کرنا', 'محنت کرنا'],
        exampleTranslation: 'اس نے کل سارا دن کام کیا۔',
        status: LexiconEntryStatus.curated,
        provenance: _kWiktionaryProvenance,
      ),
      LexiconTranslation(
        language: 'fa',
        meanings: const ['کار کردن', 'زحمت کشیدن'],
        exampleTranslation: 'او دیروز تمام روز کار کرد.',
        status: LexiconEntryStatus.curated,
        provenance: _kWiktionaryProvenance,
      ),
      LexiconTranslation(
        language: 'ar',
        meanings: const ['يعمل', 'يشتغل', 'يكدح'],
        exampleTranslation: 'لقد عمل طوال اليوم أمس.',
        status: LexiconEntryStatus.curated,
        provenance: _kWiktionaryProvenance,
      ),
    ],
  ),

  // 4. Möglichkeit (Noun with plural "Möglichkeiten")
  LexiconEntry(
    word: 'Möglichkeit',
    lemma: 'Möglichkeit',
    article: 'die',
    partOfSpeech: 'Substantiv',
    gender: 'Femininum',
    plural: 'Möglichkeiten',
    meanings: const [
      'das Möglichsein; denkbare Verwirklichung',
      'Gelegenheit oder Option zum Handeln',
    ],
    synonyms: const ['Option', 'Gelegenheit', 'Chance', 'Aussicht'],
    examples: const ['Wir haben viele neue Möglichkeiten.'],
    pronunciation: '/ˈmøːklɪçkaɪ̯t/',
    language: 'de',
    status: LexiconEntryStatus.curated,
    confidence: 1.0,
    updatedAt: DateTime.utc(2026, 1, 15),
    provenance: _kWiktionaryProvenance,
    inflectedForms: const ['Möglichkeiten', 'möglichkeit', 'moeglichkeit'],
    translations: [
      LexiconTranslation(
        language: 'en',
        meanings: const ['possibility', 'opportunity', 'option'],
        exampleTranslation: 'We have many new possibilities.',
        status: LexiconEntryStatus.curated,
        provenance: _kWiktionaryProvenance,
      ),
      LexiconTranslation(
        language: 'ur',
        meanings: const ['امکان', 'موقع', 'گنجائش'],
        exampleTranslation: 'ہمارے پاس بہت سے نئے مواقع ہیں۔',
        status: LexiconEntryStatus.curated,
        provenance: _kWiktionaryProvenance,
      ),
      LexiconTranslation(
        language: 'fa',
        meanings: const ['امکان', 'فرصت', 'گزینه'],
        exampleTranslation: 'ما فرصت‌های جدید زیادی داریم.',
        status: LexiconEntryStatus.curated,
        provenance: _kWiktionaryProvenance,
      ),
      LexiconTranslation(
        language: 'ar',
        meanings: const ['إمكانية', 'فرصة', 'خيار'],
        exampleTranslation: 'لدينا العديد من الفرص الجديدة.',
        status: LexiconEntryStatus.curated,
        provenance: _kWiktionaryProvenance,
      ),
    ],
  ),

  // 5. größer (Comparative adjective of "groß")
  LexiconEntry(
    word: 'größer',
    lemma: 'groß',
    partOfSpeech: 'Adjektiv (Komparativ)',
    meanings: const [
      'von beträchtlichem Ausmaß im Vergleich zu einem anderen',
    ],
    synonyms: const ['umfangreicher', 'ausgedehnter'],
    examples: const ['Dieses Zimmer ist viel größer.'],
    pronunciation: '/ˈɡʁøːsɐ/',
    language: 'de',
    status: LexiconEntryStatus.curated,
    confidence: 1.0,
    updatedAt: DateTime.utc(2026, 1, 15),
    provenance: _kWiktionaryProvenance,
    inflectedForms: const [
      'größere',
      'größeren',
      'größerem',
      'größeres',
      'groesser',
      'Groesser',
      'Größer',
    ],
    translations: [
      LexiconTranslation(
        language: 'en',
        meanings: const ['bigger', 'larger', 'taller'],
        exampleTranslation: 'This room is much larger.',
        status: LexiconEntryStatus.curated,
        provenance: _kWiktionaryProvenance,
      ),
      LexiconTranslation(
        language: 'ur',
        meanings: const ['بڑا', 'زیادہ بڑا'],
        exampleTranslation: 'یہ کمرہ بہت بڑا ہے۔',
        status: LexiconEntryStatus.curated,
        provenance: _kWiktionaryProvenance,
      ),
      LexiconTranslation(
        language: 'fa',
        meanings: const ['بزرگ‌تر'],
        exampleTranslation: 'این اتاق بسیار بزرگ‌تر است.',
        status: LexiconEntryStatus.curated,
        provenance: _kWiktionaryProvenance,
      ),
      LexiconTranslation(
        language: 'ar',
        meanings: const ['أكبر', 'أضخم'],
        exampleTranslation: 'هذه الغرفة أكبر بكثير.',
        status: LexiconEntryStatus.curated,
        provenance: _kWiktionaryProvenance,
      ),
    ],
  ),

  // 6. Fußball (Noun with Eszett 'ß' and Swiss variant 'ss')
  LexiconEntry(
    word: 'Fußball',
    lemma: 'Fußball',
    article: 'der',
    partOfSpeech: 'Substantiv',
    gender: 'Maskulinum',
    plural: 'Fußbälle',
    meanings: const [
      'Sportspiel mit zwei Mannschaften zu je elf Spielern',
      'der Ball, mit dem Fußball gespielt wird',
    ],
    synonyms: const ['Kicken', 'Soccer'],
    examples: const ['Wir spielen am Samstag Fußball.'],
    pronunciation: '/ˈfuːsˌbal/',
    language: 'de',
    status: LexiconEntryStatus.curated,
    confidence: 1.0,
    updatedAt: DateTime.utc(2026, 1, 15),
    provenance: _kWiktionaryProvenance,
    inflectedForms: const ['Fußbälle', 'Fußballs', 'Fussball', 'fussball', 'fußball'],
    translations: [
      LexiconTranslation(
        language: 'en',
        meanings: const ['football', 'soccer'],
        exampleTranslation: 'We play soccer on Saturday.',
        status: LexiconEntryStatus.curated,
        provenance: _kWiktionaryProvenance,
      ),
      LexiconTranslation(
        language: 'ur',
        meanings: const ['فٹ بال'],
        exampleTranslation: 'ہم ہفتے کو فٹ بال کھیلتے ہیں۔',
        status: LexiconEntryStatus.curated,
        provenance: _kWiktionaryProvenance,
      ),
      LexiconTranslation(
        language: 'fa',
        meanings: const ['فوتبال'],
        exampleTranslation: 'ما روز شنبه فوتبال بازی می‌کنیم.',
        status: LexiconEntryStatus.curated,
        provenance: _kWiktionaryProvenance,
      ),
      LexiconTranslation(
        language: 'ar',
        meanings: const ['كرة القدم'],
        exampleTranslation: 'نلعب كرة القدم يوم السبت.',
        status: LexiconEntryStatus.curated,
        provenance: _kWiktionaryProvenance,
      ),
    ],
  ),

  // 7. Mädchen (Noun with Umlaut 'ä')
  LexiconEntry(
    word: 'Mädchen',
    lemma: 'Mädchen',
    article: 'das',
    partOfSpeech: 'Substantiv',
    gender: 'Neutrum',
    plural: 'Mädchen',
    meanings: const [
      'weibliches Kind oder junge weibliche Person',
    ],
    synonyms: const ['Mädel', 'Dirndl'],
    examples: const ['Das Mädchen liest gerne Bücher.'],
    pronunciation: '/ˈmɛːtçən/',
    language: 'de',
    status: LexiconEntryStatus.curated,
    confidence: 1.0,
    updatedAt: DateTime.utc(2026, 1, 15),
    provenance: _kWiktionaryProvenance,
    inflectedForms: const ['Mädchens', 'mädchen', 'maedchen'],
    translations: [
      LexiconTranslation(
        language: 'en',
        meanings: const ['girl'],
        exampleTranslation: 'The girl enjoys reading books.',
        status: LexiconEntryStatus.curated,
        provenance: _kWiktionaryProvenance,
      ),
      LexiconTranslation(
        language: 'ur',
        meanings: const ['لڑکی'],
        exampleTranslation: 'لڑکی شوق سے کتابیں پڑھتی ہے۔',
        status: LexiconEntryStatus.curated,
        provenance: _kWiktionaryProvenance,
      ),
      LexiconTranslation(
        language: 'fa',
        meanings: const ['دختر'],
        exampleTranslation: 'دختر از خواندن کتاب لذت می‌برد.',
        status: LexiconEntryStatus.curated,
        provenance: _kWiktionaryProvenance,
      ),
      LexiconTranslation(
        language: 'ar',
        meanings: const ['فتاة', 'بنت'],
        exampleTranslation: 'الفتاة تحب قراءة الكتب.',
        status: LexiconEntryStatus.curated,
        provenance: _kWiktionaryProvenance,
      ),
    ],
  ),

  // 8. Zusammenfassung (Academic German word)
  LexiconEntry(
    word: 'Zusammenfassung',
    lemma: 'Zusammenfassung',
    article: 'die',
    partOfSpeech: 'Substantiv',
    gender: 'Femininum',
    plural: 'Zusammenfassungen',
    meanings: const [
      'kurze Darstellung der wesentlichen Punkte eines Sachverhalts oder Textes',
    ],
    synonyms: const ['Resümee', 'Überblick', 'Abstract', 'Synthese'],
    examples: const ['Die Zusammenfassung steht am Anfang der Arbeit.'],
    pronunciation: '/t͡suˈzamənˌfasʊŋ/',
    language: 'de',
    status: LexiconEntryStatus.curated,
    confidence: 1.0,
    updatedAt: DateTime.utc(2026, 1, 15),
    provenance: _kWiktionaryProvenance,
    inflectedForms: const ['Zusammenfassungen', 'zusammenfassung'],
    translations: [
      LexiconTranslation(
        language: 'en',
        meanings: const ['summary', 'abstract', 'digest'],
        exampleTranslation: 'The summary is at the beginning of the paper.',
        status: LexiconEntryStatus.curated,
        provenance: _kWiktionaryProvenance,
      ),
      LexiconTranslation(
        language: 'ur',
        meanings: const ['خلاصہ', 'جائزہ'],
        exampleTranslation: 'خلاصہ مقالے کے شروع میں ہے۔',
        status: LexiconEntryStatus.curated,
        provenance: _kWiktionaryProvenance,
      ),
      LexiconTranslation(
        language: 'fa',
        meanings: const ['خلاصه', 'چکیده'],
        exampleTranslation: 'خلاصه در ابتدای مقاله قرار دارد.',
        status: LexiconEntryStatus.curated,
        provenance: _kWiktionaryProvenance,
      ),
      LexiconTranslation(
        language: 'ar',
        meanings: const ['ملخص', 'موجز'],
        exampleTranslation: 'الملخص في بداية البحث.',
        status: LexiconEntryStatus.curated,
        provenance: _kWiktionaryProvenance,
      ),
    ],
  ),

  // 9. normal (Adjective with inflected form "normalen")
  LexiconEntry(
    word: 'normal',
    lemma: 'normal',
    partOfSpeech: 'Adjektiv',
    meanings: const [
      'der Norm entsprechend; wie gewöhnlich, nicht abweichend',
    ],
    synonyms: const ['üblich', 'gewöhnlich', 'regulär', 'standardmäßig'],
    examples: const ['Das ist ein ganz normaler Tag.'],
    pronunciation: '/nɔʁˈmaːl/',
    language: 'de',
    status: LexiconEntryStatus.curated,
    confidence: 1.0,
    updatedAt: DateTime.utc(2026, 1, 15),
    provenance: _kWiktionaryProvenance,
    inflectedForms: const [
      'normale',
      'normalen',
      'normaler',
      'normales',
      'Normalen',
      'Normale',
    ],
    translations: [
      LexiconTranslation(
        language: 'en',
        meanings: const ['normal', 'standard', 'regular'],
        exampleTranslation: 'That is a completely normal day.',
        status: LexiconEntryStatus.curated,
        provenance: _kWiktionaryProvenance,
      ),
      LexiconTranslation(
        language: 'ur',
        meanings: const ['عام', 'معمول کے مطابق'],
        exampleTranslation: 'یہ ایک بالکل عام دن ہے۔',
        status: LexiconEntryStatus.curated,
        provenance: _kWiktionaryProvenance,
      ),
      LexiconTranslation(
        language: 'fa',
        meanings: const ['عادی', 'طبیعی', 'معمولی'],
        exampleTranslation: 'این یک روز کاملاً عادی است.',
        status: LexiconEntryStatus.curated,
        provenance: _kWiktionaryProvenance,
      ),
      LexiconTranslation(
        language: 'ar',
        meanings: const ['عادي', 'طبيعي', 'مألوف'],
        exampleTranslation: 'هذا يوم عادي تماماً.',
        status: LexiconEntryStatus.curated,
        provenance: _kWiktionaryProvenance,
      ),
    ],
  ),
];

