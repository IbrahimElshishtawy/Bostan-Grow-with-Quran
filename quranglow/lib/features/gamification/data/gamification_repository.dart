import 'package:quranglow/core/storage/local_storage.dart';
import 'package:quranglow/core/storage/local_storage_ext.dart';
import 'package:quranglow/features/gamification/domain/models/gamification_models.dart';

class GameificationRepository {
  GameificationRepository({required this.storage});

  final LocalStorage storage;

  static const String _profileKeyPrefix = 'gamification_profile_v2_';
  static const String _levelsKeyPrefix = 'gamification_levels_v2_';
  static const String _missionsKeyPrefix = 'gamification_missions_v2_';

  /// Get user's game profile from local Hive storage
  Future<UserGameProfile> getUserProfile(String userId) async {
    try {
      final key = '$_profileKeyPrefix$userId';
      final Map<String, dynamic>? data = await storage
          .getJson<Map<String, dynamic>>(key);

      if (data != null) {
        return UserGameProfile.fromJson({'userId': userId, ...data});
      }

      // Create initial profile if it doesn't exist
      final initialProfile = UserGameProfile(
        userId: userId,
        totalXp: 0,
        currentLevel: 1,
        hearts: 5,
        streak: 0,
        longestStreak: 0,
        levelsCompleted: 0,
        totalStars: 0,
        lastActiveDate: null,
        joinDate: DateTime.now(),
        currentStreak: 0,
        coins: 100,
        achievements: const [],
        streakFreezeCount: 1,
        chestsClaimed: const [],
      );

      await setUserProfile(userId, initialProfile);
      return initialProfile;
    } catch (e) {
      throw Exception('Failed to get user profile from Hive: $e');
    }
  }

  /// Save user's game profile to local Hive storage
  Future<void> setUserProfile(String userId, UserGameProfile profile) async {
    try {
      final key = '$_profileKeyPrefix$userId';
      final data = profile.toJson();
      data.remove('userId');
      await storage.setJson(key, data);
    } catch (e) {
      throw Exception('Failed to save user profile in Hive: $e');
    }
  }

  /// Get all game levels from local Hive storage
  Future<List<GameLevel>> getLevels(String userId) async {
    try {
      final key = '$_levelsKeyPrefix$userId';
      final List<dynamic>? raw = await storage.getJson<List<dynamic>>(key);

      if (raw == null) return [];

      return raw
          .whereType<Map>()
          .map((item) => GameLevel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } catch (e) {
      throw Exception('Failed to get levels from Hive: $e');
    }
  }

  /// Get specific level
  Future<GameLevel?> getLevel(String userId, String levelId) async {
    try {
      final levels = await getLevels(userId);
      final index = levels.indexWhere((l) => l.id == levelId);
      return index != -1 ? levels[index] : null;
    } catch (e) {
      throw Exception('Failed to get level: $e');
    }
  }

  /// Update level progress in local Hive storage
  Future<void> updateLevelProgress(
    String userId,
    String levelId,
    GameLevel updatedLevel,
  ) async {
    try {
      final levels = await getLevels(userId);
      final index = levels.indexWhere((l) => l.id == levelId);

      if (index != -1) {
        levels[index] = updatedLevel;
      } else {
        levels.add(updatedLevel);
      }

      final key = '$_levelsKeyPrefix$userId';
      await storage.setJson(key, levels.map((l) => l.toJson()).toList());
    } catch (e) {
      throw Exception('Failed to update level progress in Hive: $e');
    }
  }

  /// Create or initialize levels for user
  Future<void> initializeLevels(String userId, List<GameLevel> levels) async {
    try {
      final key = '$_levelsKeyPrefix$userId';
      await storage.setJson(key, levels.map((l) => l.toJson()).toList());
    } catch (e) {
      throw Exception('Failed to initialize levels: $e');
    }
  }

  /// Update user XP and level
  Future<void> updateUserXp(String userId, int xpGained) async {
    try {
      final profile = await getUserProfile(userId);
      final newTotalXp = profile.totalXp + xpGained;
      final newLevel = (newTotalXp ~/ 1000) + 1;

      await setUserProfile(
        userId,
        profile.copyWith(totalXp: newTotalXp, currentLevel: newLevel),
      );
    } catch (e) {
      throw Exception('Failed to update user XP: $e');
    }
  }

  /// Update user streak
  Future<void> updateStreak(String userId) async {
    try {
      final profile = await getUserProfile(userId);
      final now = DateTime.now();
      final lastActive = profile.lastActiveDate;

      int newStreak = profile.currentStreak;
      int freezesLeft = profile.streakFreezeCount;

      if (lastActive == null) {
        newStreak = 1;
      } else {
        final daysDifference = now.difference(lastActive).inDays;
        if (daysDifference == 1) {
          newStreak = profile.currentStreak + 1;
        } else if (daysDifference > 1) {
          // If missed a day, check if streak freeze can shield!
          if (freezesLeft > 0) {
            freezesLeft--;
            newStreak = profile.currentStreak; // keep streak alive!
          } else {
            newStreak = 1;
          }
        }
      }

      final longestStreak = newStreak > profile.longestStreak
          ? newStreak
          : profile.longestStreak;

      await setUserProfile(
        userId,
        profile.copyWith(
          currentStreak: newStreak,
          longestStreak: longestStreak,
          lastActiveDate: now,
          streakFreezeCount: freezesLeft,
        ),
      );
    } catch (e) {
      throw Exception('Failed to update streak: $e');
    }
  }

  /// Update hearts
  Future<void> updateHearts(String userId, int hearts) async {
    try {
      final profile = await getUserProfile(userId);
      final clampedHearts = hearts.clamp(0, 5);

      await setUserProfile(userId, profile.copyWith(hearts: clampedHearts));
    } catch (e) {
      throw Exception('Failed to update hearts: $e');
    }
  }

  /// Get user statistics
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      final profile = await getUserProfile(userId);
      final levels = await getLevels(userId);

      final completedLevels = levels.where((l) => l.isCompleted).length;
      final perfectLevels = levels.where((l) => l.isPerfect).length;
      final totalStars = levels.fold<int>(0, (sum, l) => sum + l.starsEarned);

      return {
        'totalXp': profile.totalXp,
        'currentLevel': profile.currentLevel,
        'hearts': profile.hearts,
        'streak': profile.currentStreak,
        'longestStreak': profile.longestStreak,
        'levelsCompleted': completedLevels,
        'perfectLevels': perfectLevels,
        'totalStars': totalStars,
        'totalLevels': levels.length,
        'progressPercent': levels.isEmpty ? 0 : completedLevels / levels.length,
        'coins': profile.coins,
        'achievementsCount': profile.achievements.length,
        'freezes': profile.streakFreezeCount,
      };
    } catch (e) {
      throw Exception('Failed to get user stats: $e');
    }
  }

  /// Get daily missions from local storage
  Future<List<DailyMission>> getDailyMissions(String userId) async {
    try {
      final key = '$_missionsKeyPrefix$userId';
      final List<dynamic>? raw = await storage.getJson<List<dynamic>>(key);

      if (raw != null && raw.isNotEmpty) {
        return raw
            .whereType<Map>()
            .map(
              (item) => DailyMission.fromJson(Map<String, dynamic>.from(item)),
            )
            .toList();
      }

      final defaultMissions = [
        const DailyMission(
          id: 'mission_complete_station',
          title: 'Complete a Station',
          arabicTitle: 'أكمل محطة في مسار القرآن',
          target: 1,
          progress: 0,
          xpReward: 100,
          isCompleted: false,
        ),
        const DailyMission(
          id: 'mission_xp_goal',
          title: 'Earn 150 XP Today',
          arabicTitle: 'احصد 150 نقطة خبرة اليوم',
          target: 150,
          progress: 0,
          xpReward: 150,
          isCompleted: false,
        ),
        const DailyMission(
          id: 'mission_listen_task',
          title: 'Listen to 2 Recitations',
          arabicTitle: 'استمع إلى تلاوتين',
          target: 2,
          progress: 0,
          xpReward: 80,
          isCompleted: false,
        ),
      ];

      await saveDailyMissions(userId, defaultMissions);
      return defaultMissions;
    } catch (e) {
      throw Exception('Failed to get daily missions: $e');
    }
  }

  /// Save daily missions to local storage
  Future<void> saveDailyMissions(String userId, List<DailyMission> m) async {
    try {
      final key = '$_missionsKeyPrefix$userId';
      await storage.setJson(key, m.map((item) => item.toJson()).toList());
    } catch (e) {
      throw Exception('Failed to save daily missions: $e');
    }
  }

  /// Stream user profile (mocked with future stream for offline)
  Stream<UserGameProfile> streamUserProfile(String userId) async* {
    while (true) {
      yield await getUserProfile(userId);
      await Future.delayed(const Duration(seconds: 15));
    }
  }

  /// Stream levels (mocked with future stream for offline)
  Stream<List<GameLevel>> streamLevels(String userId) async* {
    while (true) {
      yield await getLevels(userId);
      await Future.delayed(const Duration(seconds: 15));
    }
  }
}
