class SyncConflictResolver {
  const SyncConflictResolver();

  /// Resolves conflicts using Last-Write-Wins based on ISO-8601 updatedAt timestamps
  Map<String, dynamic> resolve({
    required Map<String, dynamic> localData,
    required Map<String, dynamic> remoteData,
  }) {
    final localUpdatedAtStr = localData['updatedAt'] as String?;
    final remoteUpdatedAtStr = remoteData['updatedAt'] as String?;

    if (localUpdatedAtStr == null && remoteUpdatedAtStr == null) {
      return localData;
    }
    if (localUpdatedAtStr == null) return remoteData;
    if (remoteUpdatedAtStr == null) return localData;

    final localTime = DateTime.tryParse(localUpdatedAtStr) ?? DateTime.fromMillisecondsSinceEpoch(0);
    final remoteTime = DateTime.tryParse(remoteUpdatedAtStr) ?? DateTime.fromMillisecondsSinceEpoch(0);

    if (remoteTime.isAfter(localTime)) {
      return remoteData;
    } else {
      return localData;
    }
  }
}
