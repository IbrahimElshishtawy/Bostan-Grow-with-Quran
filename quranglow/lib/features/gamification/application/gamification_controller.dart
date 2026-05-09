import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/features/gamification/data/gamification_repository.dart';
import 'package:quranglow/features/gamification/domain/models/gamification_models.dart';
import 'package:quranglow/core/data/surah_names_ar.dart';

/// Static service to trigger soft satisfying Islamic-inspired UI haptics and sounds
class PremiumFeedbackService {
  static void lightTap() {
    HapticFeedback.lightImpact();
  }

  static void successBeep() {
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);
  }

  static void grandCelebration() {
    HapticFeedback.heavyImpact();
    // Soft sequential haptic vibration pulses for a premium feel
    Future.delayed(const Duration(milliseconds: 100), () => HapticFeedback.mediumImpact());
    Future.delayed(const Duration(milliseconds: 200), () => HapticFeedback.lightImpact());
  }

  static void errorAlert() {
    HapticFeedback.vibrate();
  }
}

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
      final missions = await repository.getDailyMissions(userId);

      // Automatically upgrade legacy small data schemas to full 114 Quran Coverage!
      if (levels.isEmpty || levels.length < 100) {
        levels = _generateSpiritualJourneyStations();
        await repository.initializeLevels(userId, levels);
      }

      final gameState = GameState(
        userProfile: profile,
        levels: levels,
        isLoading: false,
        error: null,
        dailyMissions: missions,
      );

      state = AsyncValue.data(gameState);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> reload() async {
    await initialize();
  }

  /// Complete an interactive learning sub-task (Listen, Read, Write, Memorize, Quiz)
  Future<void> completeSubTask(String levelId, String taskType, {int quizCombo = 1}) async {
    try {
      final currentState = state.valueOrNull;
      if (currentState == null) return;

      final levelIndex = currentState.levels.indexWhere((l) => l.id == levelId);
      if (levelIndex == -1) return;

      final level = currentState.levels[levelIndex];
      bool isListen = level.isListenCompleted;
      bool isRead = level.isReadCompleted;
      bool isWrite = level.isWriteCompleted;
      bool isMemorize = level.isMemorizeCompleted;
      bool isQuiz = level.isQuizCompleted;

      // Base Rewards
      int xpGained = 15;
      int coinsGained = 5;

      // Combo rewards for consecutive correct answers (Quiz combo)
      if (taskType == 'quiz' && quizCombo > 1) {
        xpGained += (quizCombo * 5); // Combo reward bonus XP!
        coinsGained += (quizCombo * 2); // Combo coins bonus!
        PremiumFeedbackService.grandCelebration();
      } else {
        PremiumFeedbackService.successBeep();
      }

      switch (taskType) {
        case 'listen':
          if (isListen) return;
          isListen = true;
          break;
        case 'read':
          if (isRead) return;
          isRead = true;
          break;
        case 'write':
          if (isWrite) return;
          isWrite = true;
          break;
        case 'memorize':
          if (isMemorize) return;
          isMemorize = true;
          break;
        case 'quiz':
          if (isQuiz) return;
          isQuiz = true;
          break;
        default:
          return;
      }

      // Apply double rewards if playing on Gold Crown Mastery Level
      if (level.masteryLevel > 0) {
        xpGained *= 2;
        coinsGained *= 2;
      }

      var updatedLevel = level.copyWith(
        isListenCompleted: isListen,
        isReadCompleted: isRead,
        isWriteCompleted: isWrite,
        isMemorizeCompleted: isMemorize,
        isQuizCompleted: isQuiz,
      );

      bool justCompletedFullStation = !level.isCompleted &&
          isListen &&
          isRead &&
          isWrite &&
          isMemorize &&
          isQuiz;

      if (justCompletedFullStation) {
        xpGained += 100; // Enhanced full station bonus XP
        coinsGained += 50; // Enhanced Coins
        updatedLevel = updatedLevel.copyWith(
          starsEarned: 3,
          xpEarned: level.xpEarned + xpGained,
          completionPercentage: 100.0,
          completedAt: DateTime.now(),
        );
        PremiumFeedbackService.grandCelebration();
      }

      // Update level progress locally
      await repository.updateLevelProgress(userId, levelId, updatedLevel);

      // Update player profile
      var updatedProfile = currentState.userProfile.copyWith(
        totalXp: currentState.userProfile.totalXp + xpGained,
        coins: currentState.userProfile.coins + coinsGained,
        totalStars: currentState.userProfile.totalStars + (justCompletedFullStation ? 3 : 0),
        levelsCompleted: currentState.userProfile.levelsCompleted + (justCompletedFullStation ? 1 : 0),
      );

      // Level Up calculations
      final calculatedLevel = (updatedProfile.totalXp ~/ 1000) + 1;
      if (calculatedLevel > updatedProfile.currentLevel) {
        updatedProfile = updatedProfile.copyWith(
          currentLevel: calculatedLevel,
          hearts: 5,
        );
        PremiumFeedbackService.grandCelebration();
      }

      // Unlock spiritual achievements
      final updatedAchievements = [...updatedProfile.achievements];
      if (updatedProfile.totalXp >= 1000 && !updatedAchievements.contains('spirit_seeker')) {
        updatedAchievements.add('spirit_seeker');
        updatedProfile = updatedProfile.copyWith(coins: updatedProfile.coins + 50);
        PremiumFeedbackService.grandCelebration();
      }
      if (updatedProfile.levelsCompleted >= 5 && !updatedAchievements.contains('station_master')) {
        updatedAchievements.add('station_master');
        updatedProfile = updatedProfile.copyWith(coins: updatedProfile.coins + 100);
        PremiumFeedbackService.grandCelebration();
      }
      if (updatedProfile.streak >= 5 && !updatedAchievements.contains('streak_legend')) {
        updatedAchievements.add('streak_legend');
        updatedProfile = updatedProfile.copyWith(coins: updatedProfile.coins + 150);
        PremiumFeedbackService.grandCelebration();
      }

      updatedProfile = updatedProfile.copyWith(achievements: updatedAchievements);
      await repository.setUserProfile(userId, updatedProfile);

      // Unlock next level in sequence
      final List<GameLevel> updatedLevels = [...currentState.levels];
      updatedLevels[levelIndex] = updatedLevel;

      if (justCompletedFullStation && levelIndex + 1 < updatedLevels.length) {
        final nextLevel = updatedLevels[levelIndex + 1];
        if (!nextLevel.isUnlocked) {
          final unlockedNext = nextLevel.copyWith(isUnlocked: true);
          await repository.updateLevelProgress(userId, nextLevel.id, unlockedNext);
          updatedLevels[levelIndex + 1] = unlockedNext;
        }
      }

      // Update daily missions
      final updatedMissions = currentState.dailyMissions.map((m) {
        int progress = m.progress;
        if (m.id == 'mission_complete_station' && justCompletedFullStation) {
          progress += 1;
        } else if (m.id == 'mission_xp_goal') {
          progress = math.min(m.target, progress + xpGained);
        } else if (m.id == 'mission_listen_task' && taskType == 'listen') {
          progress += 1;
        }

        final isCompleted = progress >= m.target;
        return m.copyWith(
          progress: progress,
          isCompleted: isCompleted,
        );
      }).toList();

      await repository.saveDailyMissions(userId, updatedMissions);
      await repository.updateStreak(userId);

      state = AsyncValue.data(GameState(
        userProfile: updatedProfile,
        levels: updatedLevels,
        isLoading: false,
        error: null,
        dailyMissions: updatedMissions,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Claim a surprise reward chest placed on the roadmap
  Future<bool> claimSurpriseChest(String chestId) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return false;

    if (currentState.userProfile.chestsClaimed.contains(chestId)) {
      return false; // Already claimed
    }

    try {
      PremiumFeedbackService.grandCelebration();
      
      final updatedChests = [...currentState.userProfile.chestsClaimed, chestId];
      final updatedProfile = currentState.userProfile.copyWith(
        coins: currentState.userProfile.coins + 100, // +100 Coins reward!
        totalXp: currentState.userProfile.totalXp + 50, // +50 XP reward!
        chestsClaimed: updatedChests,
      );

      await repository.setUserProfile(userId, updatedProfile);
      
      state = AsyncValue.data(currentState.copyWith(
        userProfile: updatedProfile,
      ));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Purchase a Daily Streak Freeze Shield item for 150 coins
  Future<bool> buyStreakFreeze() async {
    final currentState = state.valueOrNull;
    if (currentState == null) return false;

    if (currentState.userProfile.coins < 150) {
      PremiumFeedbackService.errorAlert();
      return false;
    }

    try {
      PremiumFeedbackService.successBeep();

      final updatedProfile = currentState.userProfile.copyWith(
        streakFreezeCount: currentState.userProfile.streakFreezeCount + 1,
        coins: currentState.userProfile.coins - 150,
      );

      await repository.setUserProfile(userId, updatedProfile);

      state = AsyncValue.data(currentState.copyWith(
        userProfile: updatedProfile,
      ));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Activate level mastery (Crown/Gold border replays for double rewards)
  Future<bool> activateLevelMastery(String levelId) async {
    final currentState = state.valueOrNull;
    if (currentState == null) return false;

    try {
      final index = currentState.levels.indexWhere((l) => l.id == levelId);
      if (index == -1) return false;

      final level = currentState.levels[index];
      if (!level.isCompleted) return false; // Must complete standard level first!

      PremiumFeedbackService.grandCelebration();

      final masteredLevel = level.copyWith(
        masteryLevel: 1, // Unlock gold crown mastery
        isListenCompleted: false, // reset tasks for replay!
        isReadCompleted: false,
        isWriteCompleted: false,
        isMemorizeCompleted: false,
        isQuizCompleted: false,
      );

      await repository.updateLevelProgress(userId, levelId, masteredLevel);
      await initialize();
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Purchase 1 heart for 50 coins
  Future<bool> buyHeart() async {
    final currentState = state.valueOrNull;
    if (currentState == null) return false;

    if (currentState.userProfile.hearts >= 5 || currentState.userProfile.coins < 50) {
      PremiumFeedbackService.errorAlert();
      return false;
    }

    try {
      PremiumFeedbackService.successBeep();

      final updatedProfile = currentState.userProfile.copyWith(
        hearts: currentState.userProfile.hearts + 1,
        coins: currentState.userProfile.coins - 50,
      );

      await repository.setUserProfile(userId, updatedProfile);
      
      state = AsyncValue.data(currentState.copyWith(
        userProfile: updatedProfile,
      ));
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Deduct 1 heart on a failed quiz/challenge
  Future<void> loseHeart() async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    try {
      PremiumFeedbackService.errorAlert();

      final updatedProfile = currentState.userProfile.copyWith(
        hearts: math.max(0, currentState.userProfile.hearts - 1),
      );

      await repository.setUserProfile(userId, updatedProfile);

      state = AsyncValue.data(currentState.copyWith(
        userProfile: updatedProfile,
      ));
    } catch (_) {}
  }

  /// Claim a daily reward (gems/coins + XP)
  Future<void> claimDailyReward() async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    try {
      PremiumFeedbackService.grandCelebration();

      final updatedProfile = currentState.userProfile.copyWith(
        coins: currentState.userProfile.coins + 50,
        totalXp: currentState.userProfile.totalXp + 100,
        streak: currentState.userProfile.streak + 1,
      );

      await repository.setUserProfile(userId, updatedProfile);
      await initialize();
    } catch (_) {}
  }

  /// Generate default beautifully distributed stations across Surahs for the Spiritual Journey Map
  /// Generates the comprehensive complete Quran Roadmap comprising all 114 Divine Surahs!
  List<GameLevel> _generateSpiritualJourneyStations() {
    final List<GameLevel> stations = [];
    
    // Loop through the complete global array containing 114 Arabic names!
    for (int i = 0; i < kSurahNamesAr.length; i++) {
      final int surahIndex = i + 1;
      final String name = kSurahNamesAr[i];
      
      // Distribute station types smoothly down the path
      final type = (surahIndex % 4 == 0) 
          ? StationType.memorization 
          : (surahIndex % 3 == 0) 
              ? StationType.reading 
              : (surahIndex % 2 == 0) 
                  ? StationType.listening 
                  : StationType.learning;

      stations.add(
        GameLevel(
          id: 'surah_$surahIndex',
          sequence: surahIndex,
          type: type,
          surahId: surahIndex,
          surahName: name,
          ayahStart: 1, // Simplified mapping covering the general surah
          ayahEnd: 0, // Indicating whole surah context
          title: 'محطة سورة $name',
          description: 'أكمل رحلة النور وتدبر معاني وأسرار سورة $name المباركة',
          xpReward: 150,
          maxStars: 3,
          isUnlocked: surahIndex == 1, // Only Surah 1 initially unlocked
          starsEarned: 0,
          xpEarned: 0,
          completionPercentage: 0.0,
          hasAudio: true,
          difficulty: surahIndex <= 20 ? 'Beginner' : surahIndex <= 60 ? 'Medium' : 'Hard',
          isMystery: surahIndex % 10 == 0, // Inject surprise mystery nodes every 10 surahs!
        ),
      );
    }

    return stations;
  }
}

class _JourneyGroup {
  const _JourneyGroup(
    this.id,
    this.surahId,
    this.ayahStart,
    this.ayahEnd,
    this.surahName,
    this.title,
    this.type,
    this.xp,
  );

  final String id;
  final int surahId;
  final int ayahStart;
  final int ayahEnd;
  final String surahName;
  final String title;
  final StationType type;
  final int xp;

  String get description => 'أكمل المهام الخمس لتثبيت ومراجعة $surahName آيات $ayahStart-$ayahEnd';
}
