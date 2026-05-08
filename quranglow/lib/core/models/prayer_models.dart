/// Prayer times models and calculations
import 'package:intl/intl.dart';

enum PrayerType {
  fajr('Fajr', 'الفجر'),
  sunrise('Sunrise', 'الشروق'),
  dhuhr('Dhuhr', 'الظهر'),
  asr('Asr', 'العصر'),
  maghrib('Maghrib', 'المغرب'),
  isha('Isha', 'العشاء');

  const PrayerType(this.englishName, this.arabicName);
  final String englishName;
  final String arabicName;
}

class PrayerTime {
  const PrayerTime({
    required this.type,
    required this.time,
    this.isCompleted = false,
    this.completedAt,
  });

  final PrayerType type;
  final DateTime time;
  final bool isCompleted;
  final DateTime? completedAt;

  bool get isUpcoming => !isCompleted && DateTime.now().isBefore(time);
  bool get isPast => DateTime.now().isAfter(time);
  Duration get timeUntil => time.difference(DateTime.now());

  PrayerTime copyWith({
    PrayerType? type,
    DateTime? time,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return PrayerTime(
      type: type ?? this.type,
      time: time ?? this.time,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'time': time.toIso8601String(),
    'isCompleted': isCompleted,
    'completedAt': completedAt?.toIso8601String(),
  };

  factory PrayerTime.fromJson(Map<String, dynamic> json) {
    return PrayerTime(
      type: PrayerType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => PrayerType.fajr,
      ),
      time: DateTime.parse(json['time'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
    );
  }
}

class PrayerSchedule {
  const PrayerSchedule({
    required this.date,
    required this.prayers,
    required this.location,
    required this.calculationMethod,
  });

  final DateTime date;
  final List<PrayerTime> prayers;
  final String location;
  final String calculationMethod;

  PrayerTime? get nextPrayer {
    try {
      return prayers.firstWhere((p) => p.isUpcoming);
    } catch (e) {
      return null;
    }
  }

  PrayerTime? get currentPrayer {
    try {
      return prayers.firstWhere((p) => !p.isUpcoming && !p.isPast);
    } catch (e) {
      return null;
    }
  }

  int get completedCount => prayers.where((p) => p.isCompleted).length;
  int get totalPrayers => prayers.length;
  double get completionPercentage => (completedCount / totalPrayers) * 100;

  PrayerSchedule copyWith({
    DateTime? date,
    List<PrayerTime>? prayers,
    String? location,
    String? calculationMethod,
  }) {
    return PrayerSchedule(
      date: date ?? this.date,
      prayers: prayers ?? this.prayers,
      location: location ?? this.location,
      calculationMethod: calculationMethod ?? this.calculationMethod,
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'prayers': prayers.map((p) => p.toJson()).toList(),
    'location': location,
    'calculationMethod': calculationMethod,
  };

  factory PrayerSchedule.fromJson(Map<String, dynamic> json) {
    return PrayerSchedule(
      date: DateTime.parse(json['date'] as String),
      prayers: (json['prayers'] as List<dynamic>)
          .map((p) => PrayerTime.fromJson(p as Map<String, dynamic>))
          .toList(),
      location: json['location'] as String? ?? '',
      calculationMethod: json['calculationMethod'] as String? ?? 'ISNA',
    );
  }
}

class PrayerStats {
  const PrayerStats({
    required this.totalPrayersCompleted,
    required this.currentStreak,
    required this.longestStreak,
    required this.completionRate,
    required this.lastPrayerDate,
  });

  final int totalPrayersCompleted;
  final int currentStreak;
  final int longestStreak;
  final double completionRate;
  final DateTime? lastPrayerDate;

  PrayerStats copyWith({
    int? totalPrayersCompleted,
    int? currentStreak,
    int? longestStreak,
    double? completionRate,
    DateTime? lastPrayerDate,
  }) {
    return PrayerStats(
      totalPrayersCompleted: totalPrayersCompleted ?? this.totalPrayersCompleted,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      completionRate: completionRate ?? this.completionRate,
      lastPrayerDate: lastPrayerDate ?? this.lastPrayerDate,
    );
  }

  Map<String, dynamic> toJson() => {
    'totalPrayersCompleted': totalPrayersCompleted,
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'completionRate': completionRate,
    'lastPrayerDate': lastPrayerDate?.toIso8601String(),
  };

  factory PrayerStats.fromJson(Map<String, dynamic> json) {
    return PrayerStats(
      totalPrayersCompleted: json['totalPrayersCompleted'] as int? ?? 0,
      currentStreak: json['currentStreak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      completionRate: json['completionRate'] as double? ?? 0.0,
      lastPrayerDate: json['lastPrayerDate'] != null
          ? DateTime.parse(json['lastPrayerDate'] as String)
          : null,
    );
  }
}

class PrayerAchievement {
  const PrayerAchievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.requirement,
    required this.isUnlocked,
    this.unlockedAt,
  });

  final String id;
  final String name;
  final String description;
  final String icon;
  final int requirement;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  PrayerAchievement copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    int? requirement,
    bool? isUnlocked,
    DateTime? unlockedAt,
  }) {
    return PrayerAchievement(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      requirement: requirement ?? this.requirement,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
    );
  }
}

class HijriDate {
  const HijriDate({
    required this.day,
    required this.month,
    required this.year,
  });

  final int day;
  final int month;
  final int year;

  static const List<String> monthNames = [
    'Muharram',
    'Safar',
    'Rabi\' al-awwal',
    'Rabi\' al-thani',
    'Jumada al-awwal',
    'Jumada al-thani',
    'Rajab',
    'Sha\'ban',
    'Ramadan',
    'Shawwal',
    'Dhu al-Qi\'dah',
    'Dhu al-Hijjah',
  ];

  String get monthName => monthNames[month - 1];
  String get formatted => '$day ${monthNames[month - 1]} $year AH';

  factory HijriDate.fromGregorian(DateTime gregorian) {
    final jd = _gregorianToJD(gregorian);
    return _jdToHijri(jd);
  }

  static int _gregorianToJD(DateTime date) {
    final a = (14 - date.month) ~/ 12;
    final y = date.year + 4800 - a;
    final m = date.month + 12 * a - 3;
    return date.day +
        (153 * m + 2) ~/ 5 +
        365 * y +
        y ~/ 4 -
        y ~/ 100 +
        y ~/ 400 -
        32045;
  }

  static HijriDate _jdToHijri(int jd) {
    final n = jd + 1948440 - 385;
    final q = n ~/ 10631;
    final r = n % 10631;
    final a = (r + 1) ~/ 354;
    final w = 30 * a + (r % 354 + 30) ~/ 325;
    final y = 30 * q + a;
    final m = (w % 12) + 1;
    final d = (w % 30) + 1;
    return HijriDate(day: d, month: m, year: y);
  }
}
