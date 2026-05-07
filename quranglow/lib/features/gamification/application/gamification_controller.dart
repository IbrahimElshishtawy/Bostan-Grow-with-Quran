/// Gamification controller for managing game state and logic

library gamification_controller;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/features/gamification/data/gamification_repository.dart';
import 'package:quranglow/features/gamification/domain/models/gamification_models.dart';

class GameificationController extends StateNotifier<AsyncValue<GameState>> {
  GameificationController({
    required this.repository,
    required this.userId,
  }) : super(const AsyncValue.loading());

  final GameificationRepository repository;
  final String userId;

  Future<void> initialize() async {
    try {
      state = const AsyncValue.loading();

      final profile = await repository.getUserProfile(userId);
      var levels = await repository.getLevels(userId);

      if (levels.isEmpty) {
        levels = _generateDefaultLevels();
        await repository.initializeLevels(userId, levels);
      }

      final gameState = GameState(
        userProfile: profile,
        levels: levels,
        isLoading: false,
        error: null,
      );

      state = AsyncValue.data(gameState);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> reload() async {
    await initialize();
  }

  Future<void> completeLevel(
    String levelId,
    int starsEarned,
    int xpEarned,
  ) async {
    try {
      final currentState = state.maybeWhen(
        data: (data) => data,
        orElse: () => null,
      );

      if (currentState == null) return;

      final levelIndex =
          currentState.levels.indexWhere((l) => l.id == levelId);
      if (levelIndex == -1) return;

      final level = currentState.levels[levelIndex];
      final updatedLevel = level.copyWith(
        starsEarned: starsEarned,
        xpEarned: xpEarned,
        completionPercentage: 100,
        completedAt: DateTime.now(),
        isUnlocked: true,
      );

      await repository.updateLevelProgress(userId, levelId, updatedLevel);

      // Update user profile
      final newProfile = currentState.userProfile.copyWith(
        totalXp: currentState.userProfile.totalXp + xpEarned,
        levelsCompleted: currentState.userProfile.levelsCompleted + 1,
        totalStars: currentState.userProfile.totalStars + starsEarned,
      );

      await repository.setUserProfile(userId, newProfile);

      // Unlock next level if exists
      if (levelIndex + 1 < currentState.levels.length) {
        final nextLevel = currentState.levels[levelIndex + 1];
        if (!nextLevel.isUnlocked) {
          final unlockedNextLevel = nextLevel.copyWith(isUnlocked: true);
          await repository.updateLevelProgress(
            userId,
            nextLevel.id,
            unlockedNextLevel,
          );
        }
      }

      // Update streak
      await repository.updateStreak(userId);

      // Reload state
      await initialize();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateLevelProgress(
    String levelId,
    double completionPercentage,
  ) async {
    try {
      final currentState = state.maybeWhen(
        data: (data) => data,
        orElse: () => null,
      );

      if (currentState == null) return;

      final level = currentState.levels.firstWhere(
        (l) => l.id == levelId,
        orElse: () => throw Exception('Level not found'),
      );

      final updatedLevel = level.copyWith(
        completionPercentage: completionPercentage,
      );

      await repository.updateLevelProgress(userId, levelId, updatedLevel);
      await initialize();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addXp(int xp) async {
    try {
      await repository.updateUserXp(userId, xp);
      await initialize();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateHearts(int hearts) async {
    try {
      await repository.updateHearts(userId, hearts);
      await initialize();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> updateStreak() async {
    try {
      await repository.updateStreak(userId);
      await initialize();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  List<GameLevel> _generateDefaultLevels() {
    final levels = <GameLevel>[];

    // Generate 30 default levels covering all Surahs
    for (int i = 1; i <= 30; i++) {
      final surahId = i;
      final surahName = _getSurahName(i);

      // Main Surah level
      levels.add(
        GameLevel(
          id: 'level_$i',
          sequence: (i - 1) * 3 + 1,
          type: LevelType.surah,
          surahId: surahId,
          surahName: surahName,
          ayahStart: 1,
          ayahEnd: _getAyahCount(i),
          title: 'Learn $surahName',
          description: 'Master the verses of $surahName',
          xpReward: 100,
          maxStars: 3,
          isUnlocked: i == 1,
          starsEarned: 0,
          xpEarned: 0,
          completionPercentage: 0,
          hasAudio: true,
          difficulty: 'Beginner',
        ),
      );

      // Tajweed lesson
      levels.add(
        GameLevel(
          id: 'tajweed_$i',
          sequence: (i - 1) * 3 + 2,
          type: LevelType.tajweed,
          surahId: surahId,
          surahName: surahName,
          ayahStart: 1,
          ayahEnd: 5,
          title: 'Tajweed: $surahName',
          description: 'Learn proper recitation rules',
          xpReward: 75,
          maxStars: 3,
          isUnlocked: false,
          starsEarned: 0,
          xpEarned: 0,
          completionPercentage: 0,
          hasAudio: true,
          difficulty: 'Medium',
        ),
      );

      // Review level
      if (i % 5 == 0) {
        levels.add(
          GameLevel(
            id: 'review_$i',
            sequence: (i - 1) * 3 + 3,
            type: LevelType.review,
            surahId: surahId,
            surahName: surahName,
            ayahStart: 1,
            ayahEnd: 10,
            title: 'Review Checkpoint',
            description: 'Review previous lessons',
            xpReward: 150,
            maxStars: 3,
            isUnlocked: false,
            starsEarned: 0,
            xpEarned: 0,
            completionPercentage: 0,
            hasAudio: true,
            difficulty: 'Hard',
          ),
        );
      }

      // Boss test every 10 levels
      if (i % 10 == 0) {
        levels.add(
          GameLevel(
            id: 'boss_$i',
            sequence: (i - 1) * 3 + 3,
            type: LevelType.bossTest,
            surahId: surahId,
            surahName: surahName,
            ayahStart: 1,
            ayahEnd: 20,
            title: 'Boss Test: $surahName',
            description: 'Master challenge - prove your skills!',
            xpReward: 300,
            maxStars: 3,
            isUnlocked: false,
            starsEarned: 0,
            xpEarned: 0,
            completionPercentage: 0,
            hasAudio: true,
            difficulty: 'Expert',
          ),
        );
      }
    }

    return levels;
  }

  String _getSurahName(int surahNumber) {
    const surahNames = [
      'Al-Fatiha',
      'Al-Baqarah',
      'Ali Imran',
      'An-Nisa',
      'Al-Maidah',
      'Al-Anam',
      'Al-Araf',
      'Al-Anfal',
      'At-Tawbah',
      'Yunus',
      'Hud',
      'Yusuf',
      'Ar-Rad',
      'Ibrahim',
      'Al-Hijr',
      'An-Nahl',
      'Al-Isra',
      'Al-Kahf',
      'Maryam',
      'Taha',
      'Al-Anbiya',
      'Al-Hajj',
      'Al-Muminun',
      'An-Nur',
      'Al-Furqan',
      'Ash-Shuara',
      'An-Naml',
      'Al-Qasas',
      'Al-Ankabut',
      'Ar-Rum',
    ];

    if (surahNumber >= 1 && surahNumber <= surahNames.length) {
      return surahNames[surahNumber - 1];
    }
    return 'Surah $surahNumber';
  }

  int _getAyahCount(int surahNumber) {
    const ayahCounts = [
      7, 286, 200, 176, 120, 165, 206, 75, 129, 109, 123, 111, 43, 52, 99,
      128, 111, 110, 98, 135, 112, 78, 118, 64, 77, 227, 93, 88, 69, 60,
    ];

    if (surahNumber >= 1 && surahNumber <= ayahCounts.length) {
      return ayahCounts[surahNumber - 1];
    }
    return 50;
  }
}
