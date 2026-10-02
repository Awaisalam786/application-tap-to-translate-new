class BulkActionResult {
  final int totalRequested;
  final List<String> succeededIds;
  final Map<String, String> failureErrors; // entryId -> error message

  const BulkActionResult({
    required this.totalRequested,
    required this.succeededIds,
    required this.failureErrors,
  });

  bool get isFullSuccess => failureErrors.isEmpty && succeededIds.length == totalRequested;
  bool get isPartialSuccess => succeededIds.isNotEmpty && failureErrors.isNotEmpty;
  bool get isFullFailure => succeededIds.isEmpty && failureErrors.isNotEmpty;

  int get successCount => succeededIds.length;
  int get failureCount => failureErrors.length;
}
