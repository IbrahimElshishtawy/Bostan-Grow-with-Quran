enum SyncOperationType {
  create,
  update,
  delete,
}

enum SyncStatus {
  pending,
  inProgress,
  failed,
  completed,
}

class SyncOperation {
  final String id;
  final String entityType; // e.g., 'bookmark', 'khatmah', 'goal', 'reading_progress'
  final SyncOperationType type;
  final Map<String, dynamic> payload;
  final DateTime createdAt;
  final int retryCount;
  final String? lastError;

  const SyncOperation({
    required this.id,
    required this.entityType,
    required this.type,
    required this.payload,
    required this.createdAt,
    this.retryCount = 0,
    this.lastError,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entityType': entityType,
      'type': type.name,
      'payload': payload,
      'createdAt': createdAt.toIso8601String(),
      'retryCount': retryCount,
      'lastError': lastError,
    };
  }

  factory SyncOperation.fromMap(Map<String, dynamic> map) {
    return SyncOperation(
      id: map['id'] as String,
      entityType: map['entityType'] as String,
      type: SyncOperationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => SyncOperationType.update,
      ),
      payload: Map<String, dynamic>.from(map['payload'] as Map? ?? {}),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      retryCount: (map['retryCount'] as num?)?.toInt() ?? 0,
      lastError: map['lastError'] as String?,
    );
  }

  SyncOperation copyWith({
    int? retryCount,
    String? lastError,
  }) {
    return SyncOperation(
      id: id,
      entityType: entityType,
      type: type,
      payload: payload,
      createdAt: createdAt,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
    );
  }
}
