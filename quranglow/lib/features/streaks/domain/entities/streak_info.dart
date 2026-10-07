class StreakInfo {
  final int currentStreak;
  final int longestStreak;
  final String lastActiveDate;
  final int totalActiveDays;

  const StreakInfo({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActiveDate = '',
    this.totalActiveDays = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastActiveDate': lastActiveDate,
      'totalActiveDays': totalActiveDays,
    };
  }

  factory StreakInfo.fromMap(Map<String, dynamic> map) {
    return StreakInfo(
      currentStreak: map['currentStreak'] is int ? map['currentStreak'] : 0,
      longestStreak: map['longestStreak'] is int ? map['longestStreak'] : 0,
      lastActiveDate: map['lastActiveDate']?.toString() ?? '',
      totalActiveDays: map['totalActiveDays'] is int ? map['totalActiveDays'] : 0,
    );
  }
}
