class SyncMetadata {
  final DateTime? lastSyncTime;
  final bool isSyncing;
  final int pendingOperationsCount;
  final String? lastError;

  const SyncMetadata({
    this.lastSyncTime,
    this.isSyncing = false,
    this.pendingOperationsCount = 0,
    this.lastError,
  });

  SyncMetadata copyWith({
    DateTime? lastSyncTime,
    bool? isSyncing,
    int? pendingOperationsCount,
    String? lastError,
  }) {
    return SyncMetadata(
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
      isSyncing: isSyncing ?? this.isSyncing,
      pendingOperationsCount: pendingOperationsCount ?? this.pendingOperationsCount,
      lastError: lastError,
    );
  }
}
