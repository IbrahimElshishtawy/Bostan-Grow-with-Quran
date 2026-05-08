import 'dart:math' as math;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/features/gamification/data/gamification_repository.dart';
import 'package:quranglow/features/gamification/domain/models/gamification_models.dart';

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

      if (levels.isEmpty) {
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
  List<GameLevel> _generateSpiritualJourneyStations() {
    final List<GameLevel> stations = [];
    
    final journeyGroups = [
      _JourneyGroup('s1', 1, 1, 7, 'الفاتحة والتدشين', 'The spiritual opening of the hearts', StationType.learning, 100),
      _JourneyGroup('s78', 78, 1, 16, 'النبأ العظيم', 'Deep news of eternity', StationType.listening, 120),
      _JourneyGroup('s79', 79, 1, 20, 'النازعات والخشوع', 'Solemnity of soul departure', StationType.reading, 120),
      _JourneyGroup('s80', 80, 1, 15, 'عبس والتذكرة', 'Divine reminder of care', StationType.writing, 130),
      _JourneyGroup('s81', 81, 1, 14, 'التكوير والانفطار', 'Cosmic changes and alignment', StationType.memorization, 140),
      _JourneyGroup('gate1', 78, 1, 40, 'بوابة التمكين الجزء الأول', 'First spiritual consolidation gate', StationType.revisionGate, 150),
      _JourneyGroup('s82', 82, 1, 19, 'الانفطار والعدل', 'Cosmic splitting and mercy', StationType.learning, 110),
      _JourneyGroup('s83', 83, 1, 10, 'المطففين والأمانة', 'Integrity in life and business', StationType.listening, 120),
      _JourneyGroup('s84', 84, 1, 12, 'الانشقاق والاستعداد', 'Splitting of heaven & final destiny', StationType.reading, 120),
      _JourneyGroup('s85', 85, 1, 11, 'البروج والثبات', 'The celestial mansions and resilience', StationType.writing, 130),
      _JourneyGroup('s86', 86, 1, 17, 'الطارق والنجم الساطع', 'The nightcomer and human creation', StationType.memorization, 140),
      _JourneyGroup('boss1', 85, 1, 22, 'التحدي الأكبر لثبات العقيدة', 'Sovereign test of Surah Al-Buruj', StationType.bossChallenge, 300),
      _JourneyGroup('s87', 87, 1, 19, 'الأعلى والتنزيه', 'Praise of the Most High', StationType.learning, 110),
      _JourneyGroup('s88', 88, 1, 16, 'الغاشية واليقظة', 'The overwhelming event and path', StationType.listening, 120),
      _JourneyGroup('s89', 89, 1, 15, 'الفجر والليالي العشر', 'The dawn and divine light', StationType.reading, 120),
      _JourneyGroup('s90', 90, 1, 20, 'البلد والجهاد الداخلي', 'The sacred city and steep path', StationType.writing, 130),
      _JourneyGroup('s91', 91, 1, 15, 'الشمس وتزكية النفس', 'The sun and purity of the soul', StationType.memorization, 140),
      _JourneyGroup('gate2', 87, 1, 19, 'بوابة التمكين الجزء الثاني', 'Second spiritual consolidation gate', StationType.revisionGate, 150),
      _JourneyGroup('s92', 92, 1, 21, 'الليل وسعي الإنسان', 'The night and diverse human efforts', StationType.learning, 110),
      _JourneyGroup('s93', 93, 1, 11, 'الضحى والأمل', 'The morning brightness and relief', StationType.listening, 120),
      _JourneyGroup('s94', 94, 1, 8, 'الشرح وتيسير العسر', 'Expansion of chest and relief', StationType.reading, 120),
      _JourneyGroup('s95', 95, 1, 8, 'التين وخلق الإنسان', 'The fig and human design', StationType.writing, 130),
      _JourneyGroup('s96', 96, 1, 19, 'العلق وأول الوحي', 'Read in the name of your Lord', StationType.memorization, 140),
      _JourneyGroup('boss2', 96, 1, 19, 'تحدي آية اقرأ والوعي', 'Sovereign test of Surah Al-Alaq', StationType.bossChallenge, 350),
      _JourneyGroup('s97', 97, 1, 5, 'القدر ونور القرآن', 'The night of decree and destiny', StationType.learning, 110),
      _JourneyGroup('s98', 98, 1, 8, 'البينة والبرهان', 'The clear evidence and truth', StationType.listening, 120),
      _JourneyGroup('s99', 99, 1, 8, 'الزلزلة والحساب', 'The earthquake and weight of actions', StationType.reading, 120),
      _JourneyGroup('s100', 100, 1, 11, 'العاديات وضجيج الحياة', 'The chargers and human ingratitude', StationType.writing, 130),
      _JourneyGroup('s101', 101, 1, 11, 'القارعة وقرع القلوب', 'The striking hour and final balance', StationType.memorization, 140),
      _JourneyGroup('gate3', 97, 1, 5, 'بوابة التمكين الجزء الثالث', 'Third spiritual consolidation gate', StationType.revisionGate, 150),
      _JourneyGroup('s102', 102, 1, 8, 'التكاثر ولهو الدنيا', 'Rivalry in worldly increase', StationType.learning, 110),
      _JourneyGroup('s103', 103, 1, 3, 'العصر والزمن الثمين', 'Time and the path of success', StationType.listening, 120),
      _JourneyGroup('s104', 104, 1, 9, 'الهمزة وآفة الغيبة', 'The backbiter and worldly obsession', StationType.reading, 120),
      _JourneyGroup('s105', 105, 1, 5, 'الفيل ورعاية البيت', 'The elephant and divine protection', StationType.writing, 130),
      _JourneyGroup('s106', 106, 1, 4, 'قريش والأمن والرزق', 'Provision, security, and gratitude', StationType.memorization, 140),
      _JourneyGroup('gate4', 102, 1, 8, 'بوابة التمكين الجزء الرابع', 'Fourth spiritual consolidation gate', StationType.revisionGate, 150),
      _JourneyGroup('s107', 107, 1, 7, 'الماعون وأعمال الخير', 'Small kindnesses and prayers', StationType.learning, 110),
      _JourneyGroup('s108', 108, 1, 3, 'الكوثر والعطاء الوافر', 'The abundance and sacrifice', StationType.listening, 120),
      _JourneyGroup('s109', 109, 1, 6, 'الكافرون والتوحيد الخالص', 'Uncompromised faith and unity', StationType.reading, 120),
      _JourneyGroup('s110', 110, 1, 3, 'النصر وتمام التنزيل', 'The help, victory, and forgiveness', StationType.writing, 130),
      _JourneyGroup('s111', 111, 1, 5, 'المسد ومآل الكفر', 'The palm fiber rope and justice', StationType.memorization, 140),
      _JourneyGroup('s112', 112, 1, 4, 'الإخلاص والتوحيد الصرف', 'Sincerity and oneness of Creator', StationType.learning, 110),
      _JourneyGroup('s113', 113, 1, 5, 'الفلق والتحصين الرباني', 'Seek refuge in the Lord of Daybreak', StationType.listening, 120),
      _JourneyGroup('s114', 114, 1, 6, 'الناس وحماية النفوس', 'Seek refuge in the Lord of Mankind', StationType.reading, 120),
      _JourneyGroup('boss3', 112, 1, 4, 'التحدي النهائي والمحيط', 'The ultimate master boss challenge', StationType.bossChallenge, 500),
    ];

    int sequence = 1;
    for (final group in journeyGroups) {
      stations.add(
        GameLevel(
          id: group.id,
          sequence: sequence,
          type: group.type,
          surahId: group.surahId,
          surahName: group.surahName,
          ayahStart: group.ayahStart,
          ayahEnd: group.ayahEnd,
          title: group.title,
          description: group.description,
          xpReward: group.xp,
          maxStars: 3,
          isUnlocked: sequence == 1,
          starsEarned: 0,
          xpEarned: 0,
          completionPercentage: 0.0,
          hasAudio: true,
          difficulty: sequence <= 10
              ? 'Beginner'
              : sequence <= 25
                  ? 'Medium'
                  : 'Hard',
          isMystery: sequence % 8 == 0, // Mystery bonus stations placed seamlessly on the roadmap!
        ),
      );
      sequence++;
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
