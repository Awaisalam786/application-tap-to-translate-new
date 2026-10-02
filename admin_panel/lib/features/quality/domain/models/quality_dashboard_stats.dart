class QualityDashboardStats {
  final int totalWords;
  final int draftCount;
  final int reviewCount;
  final int verifiedCount;
  final int rejectedCount;

  final int a1Count;
  final int a2Count;
  final int b1Count;
  final int b2Count;
  final int c1Count;
  final int c2Count;
  final int unclassifiedCount;

  final int missingEnCount;
  final int missingUrCount;
  final int missingFaCount;
  final int missingArCount;

  final int missingGenderCount;
  final int missingPluralCount;
  final int missingSenseCount;
  final int missingExampleCount;

  const QualityDashboardStats({
    this.totalWords = 0,
    this.draftCount = 0,
    this.reviewCount = 0,
    this.verifiedCount = 0,
    this.rejectedCount = 0,
    this.a1Count = 0,
    this.a2Count = 0,
    this.b1Count = 0,
    this.b2Count = 0,
    this.c1Count = 0,
    this.c2Count = 0,
    this.unclassifiedCount = 0,
    this.missingEnCount = 0,
    this.missingUrCount = 0,
    this.missingFaCount = 0,
    this.missingArCount = 0,
    this.missingGenderCount = 0,
    this.missingPluralCount = 0,
    this.missingSenseCount = 0,
    this.missingExampleCount = 0,
  });

  QualityDashboardStats copyWith({
    int? totalWords,
    int? draftCount,
    int? reviewCount,
    int? verifiedCount,
    int? rejectedCount,
    int? a1Count,
    int? a2Count,
    int? b1Count,
    int? b2Count,
    int? c1Count,
    int? c2Count,
    int? unclassifiedCount,
    int? missingEnCount,
    int? missingUrCount,
    int? missingFaCount,
    int? missingArCount,
    int? missingGenderCount,
    int? missingPluralCount,
    int? missingSenseCount,
    int? missingExampleCount,
  }) {
    return QualityDashboardStats(
      totalWords: totalWords ?? this.totalWords,
      draftCount: draftCount ?? this.draftCount,
      reviewCount: reviewCount ?? this.reviewCount,
      verifiedCount: verifiedCount ?? this.verifiedCount,
      rejectedCount: rejectedCount ?? this.rejectedCount,
      a1Count: a1Count ?? this.a1Count,
      a2Count: a2Count ?? this.a2Count,
      b1Count: b1Count ?? this.b1Count,
      b2Count: b2Count ?? this.b2Count,
      c1Count: c1Count ?? this.c1Count,
      c2Count: c2Count ?? this.c2Count,
      unclassifiedCount: unclassifiedCount ?? this.unclassifiedCount,
      missingEnCount: missingEnCount ?? this.missingEnCount,
      missingUrCount: missingUrCount ?? this.missingUrCount,
      missingFaCount: missingFaCount ?? this.missingFaCount,
      missingArCount: missingArCount ?? this.missingArCount,
      missingGenderCount: missingGenderCount ?? this.missingGenderCount,
      missingPluralCount: missingPluralCount ?? this.missingPluralCount,
      missingSenseCount: missingSenseCount ?? this.missingSenseCount,
      missingExampleCount: missingExampleCount ?? this.missingExampleCount,
    );
  }
}
