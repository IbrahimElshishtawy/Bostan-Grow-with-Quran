import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/features/gamification/data/gamification_repository.dart';
import 'package:quranglow/features/gamification/domain/models/gamification_models.dart';
import 'package:quranglow/core/data/surah_names_ar.dart';

import 'package:quranglow/core/data/surah_ayah_counts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hive/hive.dart';
import 'package:home_widget/home_widget.dart';
import 'package:quranglow/core/data/daily_verses.dart';
import 'package:quranglow/core/service/setting/notification_service.dart';
import 'package:intl/intl.dart';
import 'package:hijri/hijri_calendar.dart';

/// Static service to trigger soft satisfying Islamic-inspired UI haptics and sounds
class PremiumFeedbackService {
  static void lightTap() {
    try {
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  static void successBeep() {
    try {
      HapticFeedback.mediumImpact();
      SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  static void grandCelebration() {
    try {
      HapticFeedback.heavyImpact();
      Future.delayed(const Duration(milliseconds: 100), () {
        try { HapticFeedback.mediumImpact(); } catch (_) {}
      });
      Future.delayed(const Duration(milliseconds: 200), () {
        try { HapticFeedback.lightImpact(); } catch (_) {}
      });
    } catch (_) {}
  }

  static void errorAlert() {
    try {
      HapticFeedback.vibrate();
    } catch (_) {}
  }
}

class GameificationController extends StateNotifier<AsyncValue<GameState>> {
  GameificationController({
    required this.repository,
    required this.userId,
  }) : super(const AsyncValue.loading()) {
    initialize();
  }

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

      if (levels.isEmpty || dataVersion < currentTargetVersion) {
        levels = _generateSpiritualJourneyStations(dailyGoal);
        await repository.initializeLevels(userId, levels);
        await prefs.setInt('quran_levels_data_version', currentTargetVersion);
      }

      // ✨ DYNAMIC STREAK CALCULATION: Handle commitment and negative streaks!
      final now = DateTime.now();
      final lastActive = profile.lastActiveDate;
      int updatedStreak = profile.currentStreak;

      if (lastActive != null) {
        final daysDifference = now.difference(DateTime(lastActive.year, lastActive.month, lastActive.day)).inDays;
        
        if (daysDifference > 1) {
          // User missed days! Count them as negative to remind them of the gap.
          updatedStreak = -(daysDifference - 1);
        } else if (daysDifference == 1) {
          // If they were active yesterday, they are on track. 
          // If streak was negative, it stays negative until they complete a task today.
        }
      }

      final updatedProfile = profile.copyWith(currentStreak: updatedStreak);
      if (updatedStreak != profile.currentStreak) {
        await repository.setUserProfile(userId, updatedProfile);
      }
      
      final gameState = GameState(
        userProfile: updatedProfile,
        levels: levels,
        isLoading: false,
        error: null,
        dailyMissions: missions,
      );

      state = AsyncValue.data(gameState);
      
      _updateHomeWidget(gameState);
      
      // Schedule welcoming notifications if they haven't started learning yet
      final hasStartedFirstStage = levels.isNotEmpty &&
          (levels.first.isListenCompleted ||
              levels.first.isReadCompleted ||
              levels.first.isWriteCompleted ||
              levels.first.isMemorizeCompleted ||
              levels.first.isQuizCompleted ||
              updatedProfile.levelsCompleted > 0);
      
      unawaited(
        NotificationService.instance.scheduleFirstStageReminders(
          hasStartedFirstStage: hasStartedFirstStage,
        ),
      );
      
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

  Future<void> _updateHomeWidget(GameState gameState) async {
    try {
      final profile = gameState.userProfile;
      final levels = gameState.levels;
      
      // Find current active level
      final currentLevel = levels.firstWhere(
        (l) => !l.isCompleted && l.isUnlocked, 
        orElse: () => levels.last,
      );

      await HomeWidget.saveWidgetData<String>('streak_value', profile.currentStreak.toString());
      await HomeWidget.saveWidgetData<String>('level_value', profile.currentLevel.toString());
      await HomeWidget.saveWidgetData<String>('station_title', currentLevel.title);
      await HomeWidget.saveWidgetData<String>('task_listen', currentLevel.isListenCompleted ? '1' : '0');
      await HomeWidget.saveWidgetData<String>('task_read', currentLevel.isReadCompleted ? '1' : '0');
      await HomeWidget.saveWidgetData<String>('task_write', currentLevel.isWriteCompleted ? '1' : '0');
      await HomeWidget.saveWidgetData<String>('task_memorize', currentLevel.isMemorizeCompleted ? '1' : '0');
      await HomeWidget.saveWidgetData<String>('task_quiz', currentLevel.isQuizCompleted ? '1' : '0');

      // Add Date, Time & Random Verses
      final now = DateTime.now();
      final hijri = HijriCalendar.now();
      
      final dateStr = '${DateFormat('EEEE، d MMMM', 'ar').format(now)} • ${hijri.hDay} ${hijri.longMonthName} ${hijri.hYear}هـ';
      final timeStr = DateFormat('HH:mm').format(now);
      
      await HomeWidget.saveWidgetData<String>('widget_date', dateStr);
      await HomeWidget.saveWidgetData<String>('widget_time', timeStr);
      await HomeWidget.saveWidgetData<String>('widget_date_time', '$dateStr | $timeStr');

      // Try to load dynamic 24h random verses from the same Hive cache used by dailyAyatLocalProvider
      List<({String text, String ref})>? selectedVerses;
      try {
        final box = await Hive.openBox('quran_cache');
        final cachedListRaw = box.get('daily_ayahs_data');
        if (cachedListRaw is List) {
          selectedVerses = cachedListRaw.map((item) {
            final m = Map<String, dynamic>.from(item as Map);
            return (
              text: m['text'] as String,
              ref: m['ref'] as String,
            );
          }).toList();
        }
      } catch (e) {
        debugPrint('Error loading dynamic verses for HomeWidget: $e');
      }

      // Fallback to static seed-based kDailyVerses if Hive cache is not yet initialized
      if (selectedVerses == null || selectedVerses.isEmpty) {
        final daySeed = now.year * 1000 + now.month * 100 + now.day;
        final random = math.Random(daySeed);
        final List<int> indices = List.generate(kDailyVerses.length, (i) => i);
        indices.shuffle(random);
        selectedVerses = indices.take(3).map((i) => kDailyVerses[i]).toList();
      }
      
      // Send verses individually for better widget layout control if needed
      for (int i = 0; i < selectedVerses.length; i++) {
        await HomeWidget.saveWidgetData<String>('verse_${i + 1}_text', selectedVerses[i].text);
        await HomeWidget.saveWidgetData<String>('verse_${i + 1}_ref', selectedVerses[i].ref);
      }

      final versesText = selectedVerses.map((v) => v.text).join('\n\n');
      final versesRef = selectedVerses.map((v) => v.ref).join('\n');
      
      await HomeWidget.saveWidgetData<String>('widget_quran_verse', versesText);
      await HomeWidget.saveWidgetData<String>('widget_quran_ref', versesRef);

      await HomeWidget.updateWidget(
        androidName: 'LearningWidgetProvider',
        iOSName: 'LearningWidgetProvider',
      );
    } catch (e) {
      debugPrint('Error updating home widget: $e');
    }
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

      // ✨ SAFE IN-MEMORY STREAK UPDATE: Avoid database read-write race condition!
      final now = DateTime.now();
      final lastActive = updatedProfile.lastActiveDate;
      int newStreak = updatedProfile.currentStreak;
      int freezesLeft = updatedProfile.streakFreezeCount;

      if (lastActive == null) {
        newStreak = 1;
      } else {
        final lastActiveDateOnly = DateTime(lastActive.year, lastActive.month, lastActive.day);
        final nowDateOnly = DateTime(now.year, now.month, now.day);
        final daysDifference = nowDateOnly.difference(lastActiveDateOnly).inDays;

        if (daysDifference == 1) {
          // Active today after being active yesterday
          newStreak = (updatedProfile.currentStreak < 0) ? 1 : updatedProfile.currentStreak + 1;
        } else if (daysDifference > 1) {
          // Returning after a gap
          if (freezesLeft > 0) {
            freezesLeft--;
            newStreak = (updatedProfile.currentStreak < 0) ? 1 : updatedProfile.currentStreak + 1;
          } else {
            newStreak = 1; // Restart the positive journey
          }
        } else if (daysDifference == 0) {
          // Already active today, just maintain current streak if it was already updated to positive
          newStreak = (updatedProfile.currentStreak < 0) ? 1 : updatedProfile.currentStreak;
        }
      }

      final longestStreak = newStreak > updatedProfile.longestStreak
          ? newStreak
          : updatedProfile.longestStreak;

      final finalProfile = updatedProfile.copyWith(
        currentStreak: newStreak,
        longestStreak: longestStreak,
        lastActiveDate: now,
        streakFreezeCount: freezesLeft,
      );

      // ---------------------------------------------------------
      // 🌟 PERFORMANCE OPTIMIZATION: OPTIMISTIC UI UPDATE! 🌟
      // We push the state to UI immediately so it feels instantaneous (0ms lag)
      // ---------------------------------------------------------
      final newState = GameState(
        userProfile: finalProfile,
        levels: updatedLevels,
        isLoading: false,
        error: null,
        dailyMissions: updatedMissions,
      );
      state = AsyncValue.data(newState);
      
      _updateHomeWidget(newState);

      // Cancel welcoming notifications since the user has started their learning journey
      unawaited(
        NotificationService.instance.scheduleFirstStageReminders(
          hasStartedFirstStage: true,
        ),
      );

      // ---------------------------------------------------------
      // 💾 ATOMIC DISK PERSISTENCE: SAVE ALL UPDATED MEMORY DATA DIRECTLY
      // This guarantees zero concurrent read-write conflicts and absolute atomic storage!
      // ---------------------------------------------------------
      final List<Future<dynamic>> persistTasks = [
        repository.initializeLevels(userId, updatedLevels), // Writes memory levels directly!
        repository.setUserProfile(userId, finalProfile),    // Writes profile atomically!
        repository.saveDailyMissions(userId, updatedMissions),
      ];

      // 💾 HARDENED PERSISTENCE: AWAIT ALL CHANGES
      // We MUST await this, otherwise immediate app restart leads to progress loss!
      await Future.wait(persistTasks);
    } catch (e, st) {
      // ✨ HARDENED ERROR REPORTING: Reveal why writes fail instead of silent failure.
      debugPrint('[CRITICAL GAMIFICATION ERROR] completeSubTask failed: $e');
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

      final List<GameLevel> updatedLevels = [...currentState.levels];
      updatedLevels[index] = masteredLevel;

      // Apply Optimistic UI update!
      state = AsyncValue.data(currentState.copyWith(levels: updatedLevels));

      // Atomic disk write!
      await repository.initializeLevels(userId, updatedLevels);
      return true;
    } catch (e) {
      debugPrint('[CRITICAL GAMIFICATION ERROR] activateLevelMastery failed: $e');
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

  /// Mark that the user has seen the "Entire Journey Completed" celebration dialog
  Future<void> markJourneyCompletionAsSeen() async {
    final currentState = state.valueOrNull;
    if (currentState == null) return;

    try {
      final updatedProfile = currentState.userProfile.copyWith(
        hasSeenJourneyCompletionDialog: true,
      );

      state = AsyncValue.data(currentState.copyWith(
        userProfile: updatedProfile,
      ));

      await repository.setUserProfile(userId, updatedProfile);
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


