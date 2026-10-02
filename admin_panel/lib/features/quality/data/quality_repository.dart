import 'package:supabase_flutter/supabase_flutter.dart';
import '../../lexicon/domain/models/master_lexicon_entry.dart';
import '../domain/models/quality_dashboard_stats.dart';
import '../domain/services/duplicate_detector.dart';

abstract class QualityRepository {
  Future<QualityDashboardStats> getQualityStats();
  Future<List<DuplicateCandidate>> getDuplicateCandidates({int limit = 200});
}

class SupabaseQualityRepository implements QualityRepository {
  final SupabaseClient _client;

  SupabaseQualityRepository(this._client);

  @override
  Future<QualityDashboardStats> getQualityStats() async {
    try {
      // Execute fast server-side count queries concurrently
      final futures = await Future.wait([
        // 0: Total words
        _client
            .from('master_lexicon_entries')
            .select('id')
            .limit(0)
            .count(CountOption.exact),
        // 1: Draft count
        _client
            .from('master_lexicon_entries')
            .select('id')
            .eq('status', 'draft')
            .limit(0)
            .count(CountOption.exact),
        // 2: Review count
        _client
            .from('master_lexicon_entries')
            .select('id')
            .eq('status', 'review')
            .limit(0)
            .count(CountOption.exact),
        // 3: Verified count
        _client
            .from('master_lexicon_entries')
            .select('id')
            .eq('status', 'verified')
            .limit(0)
            .count(CountOption.exact),
        // 4: Rejected count
        _client
            .from('master_lexicon_entries')
            .select('id')
            .eq('status', 'rejected')
            .limit(0)
            .count(CountOption.exact),
        // 5: A1 count
        _client
            .from('master_lexicon_entries')
            .select('id')
            .eq('cefr_level', 'A1')
            .limit(0)
            .count(CountOption.exact),
        // 6: A2 count
        _client
            .from('master_lexicon_entries')
            .select('id')
            .eq('cefr_level', 'A2')
            .limit(0)
            .count(CountOption.exact),
        // 7: B1 count
        _client
            .from('master_lexicon_entries')
            .select('id')
            .eq('cefr_level', 'B1')
            .limit(0)
            .count(CountOption.exact),
        // 8: B2 count
        _client
            .from('master_lexicon_entries')
            .select('id')
            .eq('cefr_level', 'B2')
            .limit(0)
            .count(CountOption.exact),
        // 9: C1 count
        _client
            .from('master_lexicon_entries')
            .select('id')
            .eq('cefr_level', 'C1')
            .limit(0)
            .count(CountOption.exact),
        // 10: C2 count
        _client
            .from('master_lexicon_entries')
            .select('id')
            .eq('cefr_level', 'C2')
            .limit(0)
            .count(CountOption.exact),
        // 11: Unclassified count
        _client
            .from('master_lexicon_entries')
            .select('id')
            .eq('cefr_level', 'unclassified')
            .limit(0)
            .count(CountOption.exact),
        // 12: Nouns missing gender (gender is null or 'none')
        _client
            .from('master_lexicon_entries')
            .select('id')
            .eq('part_of_speech', 'noun')
            .or('gender.is.null,gender.eq.none')
            .limit(0)
            .count(CountOption.exact),
        // 13: Nouns missing plural
        _client
            .from('master_lexicon_entries')
            .select('id')
            .eq('part_of_speech', 'noun')
            .or('plural_form.is.null,plural_form.eq.')
            .limit(0)
            .count(CountOption.exact),
      ]);

      final totalWords = futures[0].count;
      final draftCount = futures[1].count;
      final reviewCount = futures[2].count;
      final verifiedCount = futures[3].count;
      final rejectedCount = futures[4].count;
      final a1Count = futures[5].count;
      final a2Count = futures[6].count;
      final b1Count = futures[7].count;
      final b2Count = futures[8].count;
      final c1Count = futures[9].count;
      final c2Count = futures[10].count;
      final unclassifiedCount = futures[11].count;
      final missingGenderCount = futures[12].count;
      final missingPluralCount = futures[13].count;

      // Query translation, sense, and example presence
      int wordsWithEn = 0;
      int wordsWithUr = 0;
      int wordsWithFa = 0;
      int wordsWithAr = 0;
      int wordsWithSense = 0;
      int wordsWithExample = 0;

      if (totalWords > 0) {
        try {
          final childFutures = await Future.wait([
            _client
                .from('master_lexicon_entries')
                .select('id, lexicon_translations!inner(target_lang)')
                .eq('lexicon_translations.target_lang', 'en')
                .limit(0)
                .count(CountOption.exact),
            _client
                .from('master_lexicon_entries')
                .select('id, lexicon_translations!inner(target_lang)')
                .eq('lexicon_translations.target_lang', 'ur')
                .limit(0)
                .count(CountOption.exact),
            _client
                .from('master_lexicon_entries')
                .select('id, lexicon_translations!inner(target_lang)')
                .eq('lexicon_translations.target_lang', 'fa')
                .limit(0)
                .count(CountOption.exact),
            _client
                .from('master_lexicon_entries')
                .select('id, lexicon_translations!inner(target_lang)')
                .eq('lexicon_translations.target_lang', 'ar')
                .limit(0)
                .count(CountOption.exact),
            _client
                .from('master_lexicon_entries')
                .select('id, lexicon_senses!inner(id)')
                .limit(0)
                .count(CountOption.exact),
            _client
                .from('master_lexicon_entries')
                .select('id, lexicon_examples!inner(id)')
                .limit(0)
                .count(CountOption.exact),
          ]);

          wordsWithEn = childFutures[0].count;
          wordsWithUr = childFutures[1].count;
          wordsWithFa = childFutures[2].count;
          wordsWithAr = childFutures[3].count;
          wordsWithSense = childFutures[4].count;
          wordsWithExample = childFutures[5].count;
        } catch (_) {
          // Fallback if inner joins are not supported on some PostgREST configurations
        }
      }

      return QualityDashboardStats(
        totalWords: totalWords,
        draftCount: draftCount,
        reviewCount: reviewCount,
        verifiedCount: verifiedCount,
        rejectedCount: rejectedCount,
        a1Count: a1Count,
        a2Count: a2Count,
        b1Count: b1Count,
        b2Count: b2Count,
        c1Count: c1Count,
        c2Count: c2Count,
        unclassifiedCount: unclassifiedCount,
        missingEnCount: (totalWords - wordsWithEn).clamp(0, totalWords),
        missingUrCount: (totalWords - wordsWithUr).clamp(0, totalWords),
        missingFaCount: (totalWords - wordsWithFa).clamp(0, totalWords),
        missingArCount: (totalWords - wordsWithAr).clamp(0, totalWords),
        missingGenderCount: missingGenderCount,
        missingPluralCount: missingPluralCount,
        missingSenseCount: (totalWords - wordsWithSense).clamp(0, totalWords),
        missingExampleCount: (totalWords - wordsWithExample).clamp(0, totalWords),
      );
    } catch (e) {
      // Return zeroes if query fails or on empty DB
      return const QualityDashboardStats();
    }
  }

  @override
  Future<List<DuplicateCandidate>> getDuplicateCandidates({int limit = 200}) async {
    try {
      final res = await _client
          .from('master_lexicon_entries')
          .select()
          .order('lemma', ascending: true)
          .limit(limit);

      final entries = (res as List)
          .map((item) => MasterLexiconEntry.fromJson(item as Map<String, dynamic>))
          .toList();

      return DuplicateDetector.detectEntryDuplicates(entries);
    } catch (_) {
      return [];
    }
  }
}
