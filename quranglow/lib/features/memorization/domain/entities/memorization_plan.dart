class MemorizationPlan {
  final String id;
  final int surahNumber;
  final String surahName;
  final int startAyah;
  final int endAyah;
  final int targetDays;
  final List<int> memorizedAyahs;
  final List<int> weakAyahs;
  final DateTime createdAt;
  final DateTime nextRevisionDate;

  const MemorizationPlan({
    required this.id,
    required this.surahNumber,
    required this.surahName,
    required this.startAyah,
    required this.endAyah,
    required this.targetDays,
    this.memorizedAyahs = const [],
    this.weakAyahs = const [],
    required this.createdAt,
    required this.nextRevisionDate,
  });

  int get totalAyahs => (endAyah - startAyah + 1).clamp(1, 286);
  int get memorizedCount => memorizedAyahs.length;
  double get progressPercentage => totalAyahs > 0 ? (memorizedCount / totalAyahs) : 0.0;
  bool get isCompleted => memorizedCount >= totalAyahs;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'surahNumber': surahNumber,
      'surahName': surahName,
      'startAyah': startAyah,
      'endAyah': endAyah,
      'targetDays': targetDays,
      'memorizedAyahs': memorizedAyahs,
      'weakAyahs': weakAyahs,
      'createdAt': createdAt.toIso8601String(),
      'nextRevisionDate': nextRevisionDate.toIso8601String(),
    };
  }

  factory MemorizationPlan.fromMap(Map<String, dynamic> map) {
    return MemorizationPlan(
      id: map['id'] as String,
      surahNumber: map['surahNumber'] as int? ?? 1,
      surahName: map['surahName'] as String? ?? 'الفاتحة',
      startAyah: map['startAyah'] as int? ?? 1,
      endAyah: map['endAyah'] as int? ?? 7,
      targetDays: map['targetDays'] as int? ?? 7,
      memorizedAyahs: (map['memorizedAyahs'] as List?)?.map((e) => e as int).toList() ?? [],
      weakAyahs: (map['weakAyahs'] as List?)?.map((e) => e as int).toList() ?? [],
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      nextRevisionDate: DateTime.tryParse(map['nextRevisionDate'] as String? ?? '') ?? DateTime.now(),
    );
  }

  MemorizationPlan copyWith({
    String? id,
    int? surahNumber,
    String? surahName,
    int? startAyah,
    int? endAyah,
    int? targetDays,
    List<int>? memorizedAyahs,
    List<int>? weakAyahs,
    DateTime? createdAt,
    DateTime? nextRevisionDate,
  }) {
    return MemorizationPlan(
      id: id ?? this.id,
      surahNumber: surahNumber ?? this.surahNumber,
      surahName: surahName ?? this.surahName,
      startAyah: startAyah ?? this.startAyah,
      endAyah: endAyah ?? this.endAyah,
      targetDays: targetDays ?? this.targetDays,
      memorizedAyahs: memorizedAyahs ?? this.memorizedAyahs,
      weakAyahs: weakAyahs ?? this.weakAyahs,
      createdAt: createdAt ?? this.createdAt,
      nextRevisionDate: nextRevisionDate ?? this.nextRevisionDate,
    );
  }
}
