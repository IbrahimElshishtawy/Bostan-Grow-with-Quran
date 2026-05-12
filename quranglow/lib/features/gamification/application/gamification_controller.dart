import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/features/gamification/data/gamification_repository.dart';
import 'package:quranglow/features/gamification/domain/models/gamification_models.dart';
import 'package:quranglow/core/data/surah_names_ar.dart';

import 'package:quranglow/core/data/surah_ayah_counts.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  
  Timer? _heartRegenTicker;

  // Heart settings!
  static const int _maxHearts = 5;
  static const Duration _regenInterval = Duration(minutes: 15); // User gets a heart every 15 minutes!

  Future<void> initialize() async {
    try {
      state = const AsyncValue.loading();

      final profile = await repository.getUserProfile(userId);
      var levels = await repository.getLevels(userId);
      final missions = await repository.getDailyMissions(userId);

      // Version check for granular level upgrade (force regen once)
      final prefs = await SharedPreferences.getInstance();
      final int dataVersion = prefs.getInt('quran_levels_data_version') ?? 0;
      const int currentTargetVersion = 3; // Force upgrade to enable dynamic chunking
      
      final int dailyGoal = prefs.getInt('daily_reading_goal') ?? 10;

      if (levels.isEmpty || levels.length < 200 || dataVersion < currentTargetVersion) {
        levels = _generateSpiritualJourneyStations(dailyGoal);
        await repository.initializeLevels(userId, levels);
        await prefs.setInt('quran_levels_data_version', currentTargetVersion);
      }

      final gameState = GameState(
        userProfile: profile,
        levels: levels,
        isLoading: false,
        error: null,
        dailyMissions: missions,
      );

      state = AsyncValue.data(gameState);
      
      // Catch up and start heartbeat ticker
      await _processHeartsRegeneration();
      _startHeartsTicker();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void _startHeartsTicker() {
    _heartRegenTicker?.cancel();
    _heartRegenTicker = Timer.periodic(const Duration(seconds: 5), (timer) {
      _processHeartsRegeneration();
    });
  }

  Future<void> _processHeartsRegeneration() async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    final profile = currentState.userProfile;
    
    // Case 1: Already capped? Clear timer reference if lingering.
    if (profile.hearts >= _maxHearts) {
      if (profile.nextHeartRegenTime != null) {
        final updated = profile.copyWith(nextHeartRegenTime: null);
        await repository.setUserProfile(userId, updated);
        state = AsyncValue.data(currentState.copyWith(userProfile: updated));
      }
      return;
    }

    // Case 2: Under cap but no timer anchor? Initialize it immediately!
    if (profile.nextHeartRegenTime == null) {
      final updated = profile.copyWith(
        nextHeartRegenTime: DateTime.now().add(_regenInterval),
      );
      await repository.setUserProfile(userId, updated);
      state = AsyncValue.data(currentState.copyWith(userProfile: updated));
      return;
    }

    // Case 3: Evaluate elapsed time against anchor.
    final now = DateTime.now();
    if (now.isAfter(profile.nextHeartRegenTime!)) {
      // Time crossed threshold! Calculate total accumulated hearts while away
      int heartsRecovered = 1;
      DateTime newRegenTarget = profile.nextHeartRegenTime!.add(_regenInterval);
      
      while (now.isAfter(newRegenTarget) && (profile.hearts + heartsRecovered) < _maxHearts) {
        heartsRecovered++;
        newRegenTarget = newRegenTarget.add(_regenInterval);
      }
      
      final finalHearts = math.min(_maxHearts, profile.hearts + heartsRecovered);
      final finalTime = finalHearts >= _maxHearts ? null : newRegenTarget;
      
      final updated = profile.copyWith(
        hearts: finalHearts,
        nextHeartRegenTime: finalTime,
      );
      
      await repository.setUserProfile(userId, updated);
      state = AsyncValue.data(currentState.copyWith(userProfile: updated));
    }
  }

  @override
  void dispose() {
    _heartRegenTicker?.cancel();
    super.dispose();
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

      // Unlock next level in sequence
      final List<GameLevel> updatedLevels = [...currentState.levels];
      updatedLevels[levelIndex] = updatedLevel;

      if (justCompletedFullStation && levelIndex + 1 < updatedLevels.length) {
        final nextLevel = updatedLevels[levelIndex + 1];
        if (!nextLevel.isUnlocked) {
          final unlockedNext = nextLevel.copyWith(isUnlocked: true);
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

      // ---------------------------------------------------------
      // 🌟 PERFORMANCE OPTIMIZATION: OPTIMISTIC UI UPDATE! 🌟
      // We push the state to UI immediately so it feels instantaneous (0ms lag)
      // ---------------------------------------------------------
      state = AsyncValue.data(GameState(
        userProfile: updatedProfile,
        levels: updatedLevels,
        isLoading: false,
        error: null,
        dailyMissions: updatedMissions,
      ));

      // ---------------------------------------------------------
      // 💾 BACKGROUND PERSISTENCE: SAVE ALL CHANGES IN PARALLEL
      // Fire the async writes in the background without blocking the UI response.
      // ---------------------------------------------------------
      final List<Future<dynamic>> persistTasks = [
        repository.updateLevelProgress(userId, levelId, updatedLevel),
        repository.setUserProfile(userId, updatedProfile),
        repository.saveDailyMissions(userId, updatedMissions),
        repository.updateStreak(userId),
      ];

      if (justCompletedFullStation && levelIndex + 1 < updatedLevels.length) {
        final nextLvl = updatedLevels[levelIndex + 1];
        if (nextLvl.isUnlocked) {
          // We must have just unlocked it in code above!
          persistTasks.add(repository.updateLevelProgress(userId, nextLvl.id, nextLvl));
        }
      }

      // 💾 HARDENED PERSISTENCE: AWAIT ALL CHANGES
      // We MUST await this, otherwise immediate app restart leads to progress loss!
      await Future.wait(persistTasks).catchError((e, st) {
        // Soft background log, doesn't kill UI fluidity.
        return [];
      });
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

      // Instant visual response
      state = AsyncValue.data(currentState.copyWith(
        userProfile: updatedProfile,
      ));

      // HARDENED PERSISTENCE: Safely await write completion!
      await repository.setUserProfile(userId, updatedProfile).catchError((_) {});
      
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

  /// Grants 3 bonus hearts from a Rewarded Ad
  Future<bool> grantRewardAdHearts() async {
    final currentState = state.valueOrNull;
    if (currentState == null) return false;

    // If already at max, block
    if (currentState.userProfile.hearts >= _maxHearts) {
      PremiumFeedbackService.errorAlert();
      return false;
    }

    try {
      PremiumFeedbackService.successBeep();

      final int oldHearts = currentState.userProfile.hearts;
      final int newHearts = math.min(_maxHearts, oldHearts + 3); // Grants 3 hearts for one ad!

      final updatedProfile = currentState.userProfile.copyWith(
        hearts: newHearts,
        // If it hit the cap, clear regen time, otherwise keep it
        nextHeartRegenTime: newHearts >= _maxHearts 
            ? null 
            : currentState.userProfile.nextHeartRegenTime,
      );

      // Instant response
      state = AsyncValue.data(currentState.copyWith(
        userProfile: updatedProfile,
      ));

      // HARDENED PERSISTENCE: Safely await write completion!
      await repository.setUserProfile(userId, updatedProfile).catchError((_) {});
      
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
      final int oldHearts = currentState.userProfile.hearts;
      final int newHearts = math.max(0, oldHearts - 1);
      
      DateTime? regenTime = currentState.userProfile.nextHeartRegenTime;
      
      // If dropping from full hearts, initialize regeneration countdown!
      if (oldHearts >= _maxHearts && newHearts < _maxHearts) {
        regenTime = DateTime.now().add(_regenInterval);
      }

      final updatedProfile = currentState.userProfile.copyWith(
        hearts: newHearts,
        nextHeartRegenTime: regenTime,
      );

      // INSTANT visual updates for ultra-fast reaction on screen!
      state = AsyncValue.data(currentState.copyWith(
        userProfile: updatedProfile,
      ));

      // HARDENED PERSISTENCE: Safely await write completion!
      await repository.setUserProfile(userId, updatedProfile).catchError((_) {});
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

  /// Regenerates the entire roadmap structure based on a new daily goal preference (dynamic chunking).
  Future<void> updateDailyGoalAndRegenerate(int newGoal) async {
    try {
      state = const AsyncValue.loading();

      // 1. Persist the new goal to preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('daily_reading_goal', newGoal);

      // 2. Generate the new partitioned stations list
      final List<GameLevel> regeneratedLevels = _generateSpiritualJourneyStations(newGoal);
      
      // 3. Persist and update local state
      await repository.initializeLevels(userId, regeneratedLevels);
      
      // Trigger reload of remaining pipeline details (profile, stats, etc)
      await initialize();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  List<GameLevel> _generateSpiritualJourneyStations(int chunkSize) {
    final List<GameLevel> stations = [];
    int globalSequence = 1;

    // Sanitize size input just in case
    final size = math.max(5, chunkSize);

    // Iterate through all 114 Surahs
    for (int i = 0; i < kSurahNamesAr.length; i++) {
      final int surahId = i + 1;
      final String surahName = kSurahNamesAr[i];
      final int totalAyahs = kSurahAyahCounts.length > i ? kSurahAyahCounts[i] : 7;

      // Chunk the surah based on the dynamic goal increment!
      int startAyah = 1;
      while (startAyah <= totalAyahs) {
        int endAyah = startAyah + (size - 1);
        if (endAyah > totalAyahs) endAyah = totalAyahs; // cap at the final ayah of this surah

        // Rotational logic for variety along path node styles
        final type = (globalSequence % 4 == 0) 
            ? StationType.memorization 
            : (globalSequence % 3 == 0) 
                ? StationType.reading 
                : (globalSequence % 2 == 0) 
                    ? StationType.listening 
                    : StationType.learning;

        stations.add(
          GameLevel(
            id: 'lvl_$globalSequence',
            sequence: globalSequence,
            type: type,
            surahId: surahId,
            surahName: surahName,
            ayahStart: startAyah,
            ayahEnd: endAyah,
            title: '$surahName ($startAyah-$endAyah)',
            description: 'أكمل رحلة النور وتدبر الآيات المباركة من $startAyah إلى $endAyah في سورة $surahName.',
            xpReward: 150,
            maxStars: 3,
            isUnlocked: globalSequence == 1, 
            starsEarned: 0,
            xpEarned: 0,
            completionPercentage: 0.0,
            hasAudio: true,
            difficulty: globalSequence <= 20 ? 'Beginner' : globalSequence <= 60 ? 'Medium' : 'Hard',
            isMystery: globalSequence % 10 == 0, 
          ),
        );

        globalSequence++;
        startAyah += size; // Advance by the dynamic step chunk
      }
    }

    return stations;
  }
}


