class DailyGoal {
  final int targetPages;
  final int targetMinutes;
  final int targetVerses;
  final int todayPagesRead;
  final int todayMinutesRead;

  const DailyGoal({
    this.targetPages = 4,
    this.targetMinutes = 20,
    this.targetVerses = 20,
    this.todayPagesRead = 0,
    this.todayMinutesRead = 0,
  });

  double get pageProgress => targetPages > 0 ? (todayPagesRead / targetPages).clamp(0.0, 1.0) : 0.0;
  double get minutesProgress => targetMinutes > 0 ? (todayMinutesRead / targetMinutes).clamp(0.0, 1.0) : 0.0;
  bool get isCompleted => todayPagesRead >= targetPages;

  DailyGoal copyWith({
    int? targetPages,
    int? targetMinutes,
    int? targetVerses,
    int? todayPagesRead,
    int? todayMinutesRead,
  }) {
    return DailyGoal(
      targetPages: targetPages ?? this.targetPages,
      targetMinutes: targetMinutes ?? this.targetMinutes,
      targetVerses: targetVerses ?? this.targetVerses,
      todayPagesRead: todayPagesRead ?? this.todayPagesRead,
      todayMinutesRead: todayMinutesRead ?? this.todayMinutesRead,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'targetPages': targetPages,
      'targetMinutes': targetMinutes,
      'targetVerses': targetVerses,
      'todayPagesRead': todayPagesRead,
      'todayMinutesRead': todayMinutesRead,
    };
  }

  factory DailyGoal.fromMap(Map<String, dynamic> map) {
    return DailyGoal(
      targetPages: map['targetPages'] is int ? map['targetPages'] : 4,
      targetMinutes: map['targetMinutes'] is int ? map['targetMinutes'] : 20,
      targetVerses: map['targetVerses'] is int ? map['targetVerses'] : 20,
      todayPagesRead: map['todayPagesRead'] is int ? map['todayPagesRead'] : 0,
      todayMinutesRead: map['todayMinutesRead'] is int ? map['todayMinutesRead'] : 0,
    );
  }
}
