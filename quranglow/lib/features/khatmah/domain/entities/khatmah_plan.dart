class KhatmahPlan {
  final String id;
  final String title;
  final int durationDays;
  final int startPage;
  final int currentPage;
  final DateTime startDate;
  final DateTime targetEndDate;
  final bool isCompleted;

  const KhatmahPlan({
    required this.id,
    required this.title,
    required this.durationDays,
    this.startPage = 1,
    this.currentPage = 1,
    required this.startDate,
    required this.targetEndDate,
    this.isCompleted = false,
  });

  int get totalPages => 604;
  int get remainingPages => (totalPages - currentPage).clamp(0, totalPages);
  
  int get remainingDays {
    final diff = targetEndDate.difference(DateTime.now()).inDays;
    return diff > 0 ? diff : 0;
  }

  int get requiredDailyPages {
    if (remainingDays <= 0) return remainingPages;
    final req = (remainingPages / remainingDays).ceil();
    return req > 0 ? req : 1;
  }

  double get progressPercentage {
    if (currentPage <= 1) return 0.0;
    if (currentPage >= 604) return 1.0;
    return (currentPage - 1) / 603.0;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'durationDays': durationDays,
      'startPage': startPage,
      'currentPage': currentPage,
      'startDate': startDate.toIso8601String(),
      'targetEndDate': targetEndDate.toIso8601String(),
      'isCompleted': isCompleted,
    };
  }

  factory KhatmahPlan.fromMap(Map<String, dynamic> map) {
    return KhatmahPlan(
      id: map['id'] as String,
      title: map['title'] as String? ?? 'ختمة القرآن',
      durationDays: map['durationDays'] as int? ?? 30,
      startPage: map['startPage'] as int? ?? 1,
      currentPage: map['currentPage'] as int? ?? 1,
      startDate: DateTime.tryParse(map['startDate'] as String? ?? '') ?? DateTime.now(),
      targetEndDate: DateTime.tryParse(map['targetEndDate'] as String? ?? '') ??
          DateTime.now().add(Duration(days: map['durationDays'] as int? ?? 30)),
      isCompleted: map['isCompleted'] as bool? ?? false,
    );
  }

  KhatmahPlan copyWith({
    String? id,
    String? title,
    int? durationDays,
    int? startPage,
    int? currentPage,
    DateTime? startDate,
    DateTime? targetEndDate,
    bool? isCompleted,
  }) {
    return KhatmahPlan(
      id: id ?? this.id,
      title: title ?? this.title,
      durationDays: durationDays ?? this.durationDays,
      startPage: startPage ?? this.startPage,
      currentPage: currentPage ?? this.currentPage,
      startDate: startDate ?? this.startDate,
      targetEndDate: targetEndDate ?? this.targetEndDate,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
