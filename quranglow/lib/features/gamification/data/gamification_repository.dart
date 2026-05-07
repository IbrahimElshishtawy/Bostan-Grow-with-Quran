/// Gamification repository for managing user progress and levels
/// Integrates with Firebase Firestore and local Hive cache


import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:quranglow/features/gamification/domain/models/gamification_models.dart';

class GameificationRepository {
  GameificationRepository({
    required this.firestore,
  });

  final FirebaseFirestore firestore;

  static const String _usersCollection = 'users';
  static const String _gameProfileDoc = 'gameProfile';
  static const String _levelsCollection = 'levels';

  /// Get user's game profile
  Future<UserGameProfile> getUserProfile(String userId) async {
    try {
      final doc = await firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_gameProfileDoc)
          .doc('profile')
          .get();

      if (doc.exists) {
        return UserGameProfile.fromJson({
          'userId': userId,
          ...doc.data() ?? {},
        });
      }

      // Create initial profile if doesn't exist
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
      );

      await setUserProfile(userId, initialProfile);
      return initialProfile;
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }

  /// Save user's game profile
  Future<void> setUserProfile(String userId, UserGameProfile profile) async {
    try {
      final data = profile.toJson();
      data.remove('userId');

      await firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_gameProfileDoc)
          .doc('profile')
          .set(data, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save user profile: $e');
    }
  }

  /// Get all game levels
  Future<List<GameLevel>> getLevels(String userId) async {
    try {
      final snapshot = await firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_levelsCollection)
          .orderBy('sequence')
          .get();

      return snapshot.docs
          .map((doc) => GameLevel.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    } catch (e) {
      throw Exception('Failed to get levels: $e');
    }
  }

  /// Get specific level
  Future<GameLevel?> getLevel(String userId, String levelId) async {
    try {
      final doc = await firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_levelsCollection)
          .doc(levelId)
          .get();

      if (doc.exists) {
        return GameLevel.fromJson({
          'id': doc.id,
          ...doc.data() ?? {},
        });
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get level: $e');
    }
  }

  /// Update level progress
  Future<void> updateLevelProgress(
    String userId,
    String levelId,
    GameLevel updatedLevel,
  ) async {
    try {
      final data = updatedLevel.toJson();
      data.remove('id');

      await firestore
          .collection(_usersCollection)
          .doc(userId)
          .collection(_levelsCollection)
          .doc(levelId)
          .set(data, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to update level progress: $e');
    }
  }

  /// Create or initialize levels for user
  Future<void> initializeLevels(String userId, List<GameLevel> levels) async {
    try {
      final batch = firestore.batch();

      for (final level in levels) {
        final data = level.toJson();
        data.remove('id');

        final docRef = firestore
            .collection(_usersCollection)
            .doc(userId)
            .collection(_levelsCollection)
            .doc(level.id);

        batch.set(docRef, data, SetOptions(merge: true));
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to initialize levels: $e');
    }
  }

  /// Update user XP and level
  Future<void> updateUserXp(
    String userId,
    int xpGained,
  ) async {
    try {
      final profile = await getUserProfile(userId);
      final newTotalXp = profile.totalXp + xpGained;
      final newLevel = (newTotalXp ~/ 1000) + 1;

      await setUserProfile(
        userId,
        profile.copyWith(
          totalXp: newTotalXp,
          currentLevel: newLevel,
        ),
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
      if (lastActive == null) {
        newStreak = 1;
      } else {
        final daysDifference = now.difference(lastActive).inDays;
        if (daysDifference == 1) {
          newStreak = profile.currentStreak + 1;
        } else if (daysDifference > 1) {
          newStreak = 1;
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

      await setUserProfile(
        userId,
        profile.copyWith(hearts: clampedHearts),
      );
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
      };
    } catch (e) {
      throw Exception('Failed to get user stats: $e');
    }
  }

  /// Stream user profile updates
  Stream<UserGameProfile> streamUserProfile(String userId) {
    return firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_gameProfileDoc)
        .doc('profile')
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return UserGameProfile.fromJson({
          'userId': userId,
          ...doc.data() ?? {},
        });
      }
      throw Exception('Profile not found');
    });
  }

  /// Stream levels updates
  Stream<List<GameLevel>> streamLevels(String userId) {
    return firestore
        .collection(_usersCollection)
        .doc(userId)
        .collection(_levelsCollection)
        .orderBy('sequence')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => GameLevel.fromJson({
                'id': doc.id,
                ...doc.data(),
              }))
          .toList();
    });
  }

  /// Sync local data with Firebase
  Future<void> syncWithFirebase(
    String userId,
    UserGameProfile profile,
    List<GameLevel> levels,
  ) async {
    try {
      await setUserProfile(userId, profile);
      await initializeLevels(userId, levels);
    } catch (e) {
      throw Exception('Failed to sync with Firebase: $e');
    }
  }
}
