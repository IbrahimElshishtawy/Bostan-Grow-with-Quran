/// Prayer-related Riverpod providers
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/models/prayer_models.dart';

/// Prayer times provider - stub for now, will be replaced with actual calculations
final prayerTimesProvider =
    FutureProvider.family<List<PrayerTime>, (double, double)>((
      ref,
      coords,
    ) async {
      // This will be replaced with actual Adhan library implementation
      // For now, return empty list
      return [];
    });

/// Get next prayer time from schedule
final nextPrayerProvider = Provider.family<PrayerTime?, List<PrayerTime>>((
  ref,
  prayers,
) {
  final now = DateTime.now();

  try {
    return prayers.firstWhere((prayer) => prayer.time.isAfter(now));
  } catch (e) {
    return null;
  }
});

/// Prayer streak state
class PrayerStreakState {
  final int currentStreak;
  final int longestStreak;
  final DateTime lastPrayerDate;
  final Map<String, bool> todaysPrayers; // prayer name -> completed

  PrayerStreakState({
    required this.currentStreak,
    required this.longestStreak,
    required this.lastPrayerDate,
    required this.todaysPrayers,
  });

  PrayerStreakState copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastPrayerDate,
    Map<String, bool>? todaysPrayers,
  }) {
    return PrayerStreakState(
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastPrayerDate: lastPrayerDate ?? this.lastPrayerDate,
      todaysPrayers: todaysPrayers ?? this.todaysPrayers,
    );
  }
}

class PrayerStreakNotifier extends StateNotifier<PrayerStreakState> {
  PrayerStreakNotifier()
    : super(
        PrayerStreakState(
          currentStreak: 0,
          longestStreak: 0,
          lastPrayerDate: DateTime.now(),
          todaysPrayers: {
            'fajr': false,
            'dhuhr': false,
            'asr': false,
            'maghrib': false,
            'isha': false,
          },
        ),
      );

  void markPrayerCompleted(String prayerName) {
    state = state.copyWith(
      todaysPrayers: {...state.todaysPrayers, prayerName: true},
    );
  }

  void incrementStreak() {
    state = state.copyWith(
      currentStreak: state.currentStreak + 1,
      longestStreak: state.currentStreak + 1 > state.longestStreak
          ? state.currentStreak + 1
          : state.longestStreak,
    );
  }

  void resetStreak() {
    state = state.copyWith(currentStreak: 0);
  }
}

final prayerStreakProvider =
    StateNotifierProvider<PrayerStreakNotifier, PrayerStreakState>((ref) {
      return PrayerStreakNotifier();
    });

/// Prayer XP system
class PrayerXPState {
  final int totalXP;
  final int level;
  final int xpForNextLevel;

  PrayerXPState({
    required this.totalXP,
    required this.level,
    required this.xpForNextLevel,
  });

  PrayerXPState copyWith({int? totalXP, int? level, int? xpForNextLevel}) {
    return PrayerXPState(
      totalXP: totalXP ?? this.totalXP,
      level: level ?? this.level,
      xpForNextLevel: xpForNextLevel ?? this.xpForNextLevel,
    );
  }
}

class PrayerXPNotifier extends StateNotifier<PrayerXPState> {
  static const int baseXPPerPrayer = 10;
  static const int baseXPForLevel = 100;

  PrayerXPNotifier()
    : super(
        PrayerXPState(totalXP: 0, level: 1, xpForNextLevel: baseXPForLevel),
      );

  void addXP(int amount) {
    int newTotal = state.totalXP + amount;
    int newLevel = state.level;
    int newXPForNext = state.xpForNextLevel;

    while (newTotal >= newXPForNext) {
      newTotal -= newXPForNext;
      newLevel++;
      newXPForNext = baseXPForLevel * newLevel;
    }

    state = state.copyWith(
      totalXP: newTotal,
      level: newLevel,
      xpForNextLevel: newXPForNext - newTotal,
    );
  }

  void addXPForPrayerCompletion() {
    addXP(baseXPPerPrayer);
  }

  void addXPForStreak(int streakDays) {
    // Bonus XP for streaks: 1 XP per day of streak
    addXP(baseXPPerPrayer + streakDays);
  }
}

final prayerXPProvider = StateNotifierProvider<PrayerXPNotifier, PrayerXPState>(
  (ref) {
    return PrayerXPNotifier();
  },
);
