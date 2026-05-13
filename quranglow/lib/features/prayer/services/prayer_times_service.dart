// ignore_for_file: unused_local_variable

// ignore: dangling_library_doc_comments
/// Prayer times calculation and management service
import 'dart:math';
import 'package:quranglow/core/models/prayer_models.dart';

class PrayerTimesService {
  /// Calculate prayer times for a given date and location
  static PrayerSchedule calculatePrayerTimes({
    required DateTime date,
    required double latitude,
    required double longitude,
    required String location,
    String calculationMethod = 'ISNA',
  }) {
    final prayers = <PrayerTime>[];

    // Calculate prayer times using Hijri algorithm
    final fajrTime = _calculateFajr(date, latitude, longitude);
    final sunriseTime = _calculateSunrise(date, latitude, longitude);
    final dhuhrTime = _calculateDhuhr(date, latitude, longitude);
    final asrTime = _calculateAsr(date, latitude, longitude);
    final maghribTime = _calculateMaghrib(date, latitude, longitude);
    final ishaTime = _calculateIsha(date, latitude, longitude);

    prayers.add(PrayerTime(type: PrayerType.fajr, time: fajrTime));
    prayers.add(PrayerTime(type: PrayerType.sunrise, time: sunriseTime));
    prayers.add(PrayerTime(type: PrayerType.dhuhr, time: dhuhrTime));
    prayers.add(PrayerTime(type: PrayerType.asr, time: asrTime));
    prayers.add(PrayerTime(type: PrayerType.maghrib, time: maghribTime));
    prayers.add(PrayerTime(type: PrayerType.isha, time: ishaTime));

    return PrayerSchedule(
      date: date,
      prayers: prayers,
      location: location,
      calculationMethod: calculationMethod,
    );
  }

  static DateTime _calculateFajr(
    DateTime date,
    double latitude,
    double longitude,
  ) {
    final noon = _calculateNoon(date, longitude);
    final angle = 18.0; // Fajr angle
    final offset = _calculateTimeOffset(latitude, angle);
    return noon.subtract(Duration(minutes: (offset * 60).toInt()));
  }

  static DateTime _calculateSunrise(
    DateTime date,
    double latitude,
    double longitude,
  ) {
    final noon = _calculateNoon(date, longitude);
    final angle = 0.833; // Sunrise angle
    final offset = _calculateTimeOffset(latitude, angle);
    return noon.subtract(Duration(minutes: (offset * 60).toInt()));
  }

  static DateTime _calculateDhuhr(
    DateTime date,
    double latitude,
    double longitude,
  ) {
    return _calculateNoon(date, longitude);
  }

  static DateTime _calculateAsr(
    DateTime date,
    double latitude,
    double longitude,
  ) {
    final noon = _calculateNoon(date, longitude);
    final angle = _calculateAsrAngle(latitude);
    final offset = _calculateTimeOffset(latitude, angle);
    return noon.add(Duration(minutes: (offset * 60).toInt()));
  }

  static DateTime _calculateMaghrib(
    DateTime date,
    double latitude,
    double longitude,
  ) {
    final noon = _calculateNoon(date, longitude);
    final angle = 0.833; // Sunset angle
    final offset = _calculateTimeOffset(latitude, angle);
    return noon.add(Duration(minutes: (offset * 60).toInt()));
  }

  static DateTime _calculateIsha(
    DateTime date,
    double latitude,
    double longitude,
  ) {
    final noon = _calculateNoon(date, longitude);
    final angle = 17.0; // Isha angle
    final offset = _calculateTimeOffset(latitude, angle);
    return noon.add(Duration(minutes: (offset * 60).toInt()));
  }

  static DateTime _calculateNoon(DateTime date, double longitude) {
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays;
    final b = 360.0 / 365.0 * (dayOfYear - 81);
    final eot =
        9.87 * sin(2 * _toRadians(b)) -
        7.53 * cos(_toRadians(b)) -
        1.5 * sin(_toRadians(b));
    final noon = 12.0 - (longitude / 15.0) - (eot / 60.0);
    return DateTime(
      date.year,
      date.month,
      date.day,
    ).add(Duration(hours: noon.toInt(), minutes: ((noon % 1) * 60).toInt()));
  }

  static double _calculateTimeOffset(double latitude, double angle) {
    final latRad = _toRadians(latitude);
    final angleRad = _toRadians(angle);
    final cosH = -tan(latRad) * tan(angleRad);
    final h = acos(cosH.clamp(-1.0, 1.0)) * 180.0 / pi;
    return h / 15.0;
  }

  static double _calculateAsrAngle(double latitude) {
    final latRad = _toRadians(latitude);
    return atan(1.0 / (1.0 + tan(latRad))).abs() * 180.0 / pi;
  }

  static double _toRadians(double degrees) => degrees * pi / 180.0;
}

class PrayerTracker {
  PrayerTracker({required this.stats, required this.achievements});

  PrayerStats stats;
  List<PrayerAchievement> achievements;

  /// Mark prayer as completed
  void completePrayer(PrayerTime prayer) {
    final now = DateTime.now();
    final updatedPrayer = prayer.copyWith(isCompleted: true, completedAt: now);

    // Update stats
    stats = stats.copyWith(
      totalPrayersCompleted: stats.totalPrayersCompleted + 1,
      lastPrayerDate: now,
    );

    // Update streak
    _updateStreak();

    // Check achievements
    _checkAchievements();
  }

  void _updateStreak() {
    final lastPrayer = stats.lastPrayerDate;
    if (lastPrayer == null) {
      stats = stats.copyWith(currentStreak: 1);
      return;
    }

    final daysDifference = DateTime.now().difference(lastPrayer).inDays;
    if (daysDifference == 0) {
      // Same day, streak continues
      return;
    } else if (daysDifference == 1) {
      // Next day, increment streak
      final newStreak = stats.currentStreak + 1;
      stats = stats.copyWith(
        currentStreak: newStreak,
        longestStreak: max(stats.longestStreak, newStreak),
      );
    } else {
      // Gap in streak, reset
      stats = stats.copyWith(currentStreak: 1);
    }
  }

  void _checkAchievements() {
    // Check for achievement unlocks
    for (int i = 0; i < achievements.length; i++) {
      final achievement = achievements[i];
      if (!achievement.isUnlocked &&
          stats.totalPrayersCompleted >= achievement.requirement) {
        achievements[i] = achievement.copyWith(
          isUnlocked: true,
          unlockedAt: DateTime.now(),
        );
      }
    }
  }

  /// Get default achievements
  static List<PrayerAchievement> getDefaultAchievements() {
    return [
      PrayerAchievement(
        id: 'first_prayer',
        name: 'First Step',
        description: 'Complete your first prayer',
        icon: '🌙',
        requirement: 1,
        isUnlocked: false,
      ),
      PrayerAchievement(
        id: 'week_warrior',
        name: 'Week Warrior',
        description: 'Complete 7 prayers',
        icon: '⭐',
        requirement: 7,
        isUnlocked: false,
      ),
      PrayerAchievement(
        id: 'month_master',
        name: 'Month Master',
        description: 'Complete 30 prayers',
        icon: '👑',
        requirement: 30,
        isUnlocked: false,
      ),
      PrayerAchievement(
        id: 'year_champion',
        name: 'Year Champion',
        description: 'Complete 365 prayers',
        icon: '🏆',
        requirement: 365,
        isUnlocked: false,
      ),
      PrayerAchievement(
        id: 'perfect_day',
        name: 'Perfect Day',
        description: 'Complete all 5 prayers in one day',
        icon: '✨',
        requirement: 5,
        isUnlocked: false,
      ),
    ];
  }
}
