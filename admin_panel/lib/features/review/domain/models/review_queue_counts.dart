class ReviewQueueCounts {
  final int masterCount;
  final int translationsCount;
  final int sensesCount;
  final int synonymsCount;
  final int examplesCount;

  const ReviewQueueCounts({
    this.masterCount = 0,
    this.translationsCount = 0,
    this.sensesCount = 0,
    this.synonymsCount = 0,
    this.examplesCount = 0,
  });

  int get totalCount =>
      masterCount +
      translationsCount +
      sensesCount +
      synonymsCount +
      examplesCount;

  ReviewQueueCounts copyWith({
    int? masterCount,
    int? translationsCount,
    int? sensesCount,
    int? synonymsCount,
    int? examplesCount,
  }) {
    return ReviewQueueCounts(
      masterCount: masterCount ?? this.masterCount,
      translationsCount: translationsCount ?? this.translationsCount,
      sensesCount: sensesCount ?? this.sensesCount,
      synonymsCount: synonymsCount ?? this.synonymsCount,
      examplesCount: examplesCount ?? this.examplesCount,
    );
  }
}
