// ignore_for_file: dangling_library_doc_comments
/// Gamification domain models for the premium Quran Journey progression system

enum StationType {
  learning('محطة التفسير والتدبر', 'Study meaning and Tajweed'),
  listening('محطة الاستماع والترتيل', 'Listen to beautiful recitation'),
  reading('محطة القراءة والتحسين', 'Read verses with focus'),
  writing('محطة الكتابة والبناء', 'Reconstruct verses word by word'),
  memorization('محطة الحفظ والتمكين', 'Spaced repetition memorization'),
  revisionGate('بوابة المراجعة والتمكين', 'Solidify previous achievements'),
  bossChallenge('التحدي الأكبر للتدبر', 'Surah master boss challenge'),
  mysteryStation('المحطة الغامضة والمفاجأة', 'Mystery reward bonus station');

  const StationType(this.arabicLabel, this.englishLabel);
  final String arabicLabel;
  final String englishLabel;
}

class GameLevel {
  const GameLevel({
    required this.id,
    required this.sequence,
    required this.type,
    required this.surahId,
    required this.surahName,
    required this.ayahStart,
    required this.ayahEnd,
    required this.title,
    required this.description,
    required this.xpReward,
    required this.maxStars,
    required this.isUnlocked,
    required this.starsEarned,
    required this.xpEarned,
    required this.completionPercentage,
    required this.hasAudio,
    required this.difficulty,
    this.nextReviewDate,
    this.completedAt,
    this.isListenCompleted = false,
    this.isReadCompleted = false,
    this.isWriteCompleted = false,
    this.isMemorizeCompleted = false,
    this.isQuizCompleted = false,
    this.masteryLevel = 0, // 0 = Standard, 1 = Gold Crown Mastery Replay
    this.isMystery = false,
  });

  final String id;
  final int sequence;
  final StationType type;
  final int surahId;
  final String surahName;
  final int ayahStart;
  final int ayahEnd;
  final String title;
  final String description;
  final int xpReward;
  final int maxStars;
  final bool isUnlocked;
  final int starsEarned;
  final int xpEarned;
  final double completionPercentage;
  final bool hasAudio;
  final String difficulty;
  final DateTime? nextReviewDate;
  final DateTime? completedAt;

  final bool isListenCompleted;
  final bool isReadCompleted;
  final bool isWriteCompleted;
  final bool isMemorizeCompleted;
  final bool isQuizCompleted;
  
  final int masteryLevel;
  final bool isMystery;

  bool get isCompleted => isListenCompleted && isReadCompleted && isWriteCompleted && isMemorizeCompleted && isQuizCompleted;
  bool get isPerfect => starsEarned == maxStars;
  int get ayahCount => ayahEnd - ayahStart + 1;

  double get taskProgress {
    int done = 0;
    if (isListenCompleted) done++;
    if (isReadCompleted) done++;
    if (isWriteCompleted) done++;
    if (isMemorizeCompleted) done++;
    if (isQuizCompleted) done++;
    return done / 5.0;
  }

  GameLevel copyWith({
    String? id,
    int? sequence,
    StationType? type,
    int? surahId,
    String? surahName,
    int? ayahStart,
    int? ayahEnd,
    String? title,
    String? description,
    int? xpReward,
    int? maxStars,
    bool? isUnlocked,
    int? starsEarned,
    int? xpEarned,
    double? completionPercentage,
    bool? hasAudio,
    String? difficulty,
    DateTime? nextReviewDate,
    DateTime? completedAt,
    bool? isListenCompleted,
    bool? isReadCompleted,
    bool? isWriteCompleted,
    bool? isMemorizeCompleted,
    bool? isQuizCompleted,
    int? masteryLevel,
    bool? isMystery,
  }) {
    return GameLevel(
      id: id ?? this.id,
      sequence: sequence ?? this.sequence,
      type: type ?? this.type,
      surahId: surahId ?? this.surahId,
      surahName: surahName ?? this.surahName,
      ayahStart: ayahStart ?? this.ayahStart,
      ayahEnd: ayahEnd ?? this.ayahEnd,
      title: title ?? this.title,
      description: description ?? this.description,
      xpReward: xpReward ?? this.xpReward,
      maxStars: maxStars ?? this.maxStars,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      starsEarned: starsEarned ?? this.starsEarned,
      xpEarned: xpEarned ?? this.xpEarned,
      completionPercentage: completionPercentage ?? this.completionPercentage,
      hasAudio: hasAudio ?? this.hasAudio,
      difficulty: difficulty ?? this.difficulty,
      nextReviewDate: nextReviewDate ?? this.nextReviewDate,
      completedAt: completedAt ?? this.completedAt,
      isListenCompleted: isListenCompleted ?? this.isListenCompleted,
      isReadCompleted: isReadCompleted ?? this.isReadCompleted,
      isWriteCompleted: isWriteCompleted ?? this.isWriteCompleted,
      isMemorizeCompleted: isMemorizeCompleted ?? this.isMemorizeCompleted,
      isQuizCompleted: isQuizCompleted ?? this.isQuizCompleted,
      masteryLevel: masteryLevel ?? this.masteryLevel,
      isMystery: isMystery ?? this.isMystery,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'sequence': sequence,
    'type': type.name,
    'surahId': surahId,
    'surahName': surahName,
    'ayahStart': ayahStart,
    'ayahEnd': ayahEnd,
    'title': title,
    'description': description,
    'xpReward': xpReward,
    'maxStars': maxStars,
    'isUnlocked': isUnlocked,
    'starsEarned': starsEarned,
    'xpEarned': xpEarned,
    'completionPercentage': completionPercentage,
    'hasAudio': hasAudio,
    'difficulty': difficulty,
    'nextReviewDate': nextReviewDate?.toIso8601String(),
    'completedAt': completedAt?.toIso8601String(),
    'isListenCompleted': isListenCompleted,
    'isReadCompleted': isReadCompleted,
    'isWriteCompleted': isWriteCompleted,
    'isMemorizeCompleted': isMemorizeCompleted,
    'isQuizCompleted': isQuizCompleted,
    'masteryLevel': masteryLevel,
    'isMystery': isMystery,
  };

  factory GameLevel.fromJson(Map<String, dynamic> json) {
    return GameLevel(
      id: json['id'] as String? ?? '',
      sequence: json['sequence'] as int? ?? 0,
      type: _parseStationType(json['type']),
      surahId: json['surahId'] as int? ?? 0,
      surahName: json['surahName'] as String? ?? '',
      ayahStart: json['ayahStart'] as int? ?? 1,
      ayahEnd: json['ayahEnd'] as int? ?? 1,
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      xpReward: json['xpReward'] as int? ?? 0,
      maxStars: json['maxStars'] as int? ?? 3,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      starsEarned: json['starsEarned'] as int? ?? 0,
      xpEarned: json['xpEarned'] as int? ?? 0,
      completionPercentage: (json['completionPercentage'] as num?)?.toDouble() ?? 0.0,
      hasAudio: json['hasAudio'] as bool? ?? true,
      difficulty: json['difficulty'] as String? ?? 'Beginner',
      nextReviewDate: json['nextReviewDate'] != null
          ? DateTime.tryParse(json['nextReviewDate'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.tryParse(json['completedAt'] as String)
          : null,
      isListenCompleted: json['isListenCompleted'] as bool? ?? false,
      isReadCompleted: json['isReadCompleted'] as bool? ?? false,
      isWriteCompleted: json['isWriteCompleted'] as bool? ?? false,
      isMemorizeCompleted: json['isMemorizeCompleted'] as bool? ?? false,
      isQuizCompleted: json['isQuizCompleted'] as bool? ?? false,
      masteryLevel: json['masteryLevel'] as int? ?? 0,
      isMystery: json['isMystery'] as bool? ?? false,
    );
  }
}

class UserGameProfile {
  const UserGameProfile({
    required this.userId,
    required this.totalXp,
    required this.currentLevel,
    required this.hearts,
    required this.streak,
    required this.longestStreak,
    required this.levelsCompleted,
    required this.totalStars,
    required this.lastActiveDate,
    required this.joinDate,
    required this.currentStreak,
    this.coins = 100,
    this.achievements = const [],
    this.streakFreezeCount = 1, // Streak Freeze Shield item
    this.chestsClaimed = const [], // Surprise reward chests index e.g., 'chest_3'
    this.nextHeartRegenTime,
  });

  final DateTime? nextHeartRegenTime;

  final String userId;
  final int totalXp;
  final int currentLevel;
  final int hearts;
  final int streak;
  final int longestStreak;
  final int levelsCompleted;
  final int totalStars;
  final DateTime? lastActiveDate;
  final DateTime joinDate;
  final int currentStreak;
  final int coins;
  final List<String> achievements;
  
  final int streakFreezeCount;
  final List<String> chestsClaimed;

  int get xpToNextLevel => ((currentLevel + 1) * 1000) - totalXp;
  double get levelProgress => (totalXp % 1000) / 1000.0;

  UserGameProfile copyWith({
    String? userId,
    int? totalXp,
    int? currentLevel,
    int? hearts,
    int? streak,
    int? longestStreak,
    int? levelsCompleted,
    int? totalStars,
    DateTime? lastActiveDate,
    DateTime? joinDate,
    int? currentStreak,
    int? coins,
    List<String>? achievements,
    int? streakFreezeCount,
    List<String>? chestsClaimed,
    DateTime? nextHeartRegenTime,
  }) {
    return UserGameProfile(
      userId: userId ?? this.userId,
      totalXp: totalXp ?? this.totalXp,
      currentLevel: currentLevel ?? this.currentLevel,
      hearts: hearts ?? this.hearts,
      streak: streak ?? this.streak,
      longestStreak: longestStreak ?? this.longestStreak,
      levelsCompleted: levelsCompleted ?? this.levelsCompleted,
      totalStars: totalStars ?? this.totalStars,
      lastActiveDate: lastActiveDate ?? this.lastActiveDate,
      joinDate: joinDate ?? this.joinDate,
      currentStreak: currentStreak ?? this.currentStreak,
      coins: coins ?? this.coins,
      achievements: achievements ?? this.achievements,
      streakFreezeCount: streakFreezeCount ?? this.streakFreezeCount,
      chestsClaimed: chestsClaimed ?? this.chestsClaimed,
      nextHeartRegenTime: nextHeartRegenTime ?? this.nextHeartRegenTime,
    );
  }

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'totalXp': totalXp,
    'currentLevel': currentLevel,
    'hearts': hearts,
    'streak': streak,
    'longestStreak': longestStreak,
    'levelsCompleted': levelsCompleted,
    'totalStars': totalStars,
    'lastActiveDate': lastActiveDate?.toIso8601String(),
    'joinDate': joinDate.toIso8601String(),
    'currentStreak': currentStreak,
    'coins': coins,
    'achievements': achievements,
    'streakFreezeCount': streakFreezeCount,
    'chestsClaimed': chestsClaimed,
    'nextHeartRegenTime': nextHeartRegenTime?.toIso8601String(),
  };

  factory UserGameProfile.fromJson(Map<String, dynamic> json) {
    return UserGameProfile(
      userId: json['userId'] as String? ?? '',
      totalXp: json['totalXp'] as int? ?? 0,
      currentLevel: json['currentLevel'] as int? ?? 1,
      hearts: (json['hearts'] as int? ?? 5).clamp(0, 5),
      streak: json['streak'] as int? ?? 0,
      longestStreak: json['longestStreak'] as int? ?? 0,
      levelsCompleted: json['levelsCompleted'] as int? ?? 0,
      totalStars: json['totalStars'] as int? ?? 0,
      lastActiveDate: json['lastActiveDate'] != null
          ? DateTime.tryParse(json['lastActiveDate'] as String)
          : null,
      joinDate: json['joinDate'] != null
          ? DateTime.tryParse(json['joinDate'] as String) ?? DateTime.now()
          : DateTime.now(),
      currentStreak: json['currentStreak'] as int? ?? 0,
      coins: json['coins'] as int? ?? 100,
      achievements: List<String>.from(json['achievements'] ?? const []),
      streakFreezeCount: json['streakFreezeCount'] as int? ?? 1,
      chestsClaimed: List<String>.from(json['chestsClaimed'] ?? const []),
      nextHeartRegenTime: json['nextHeartRegenTime'] != null
          ? DateTime.tryParse(json['nextHeartRegenTime'] as String)
          : null,
    );
  }
}

class DailyMission {
  const DailyMission({
    required this.id,
    required this.title,
    required this.arabicTitle,
    required this.target,
    required this.progress,
    required this.xpReward,
    required this.isCompleted,
  });

  final String id;
  final String title;
  final String arabicTitle;
  final int target;
  final int progress;
  final int xpReward;
  final bool isCompleted;

  DailyMission copyWith({
    String? id,
    String? title,
    String? arabicTitle,
    int? target,
    int? progress,
    int? xpReward,
    bool? isCompleted,
  }) {
    return DailyMission(
      id: id ?? this.id,
      title: title ?? this.title,
      arabicTitle: arabicTitle ?? this.arabicTitle,
      target: target ?? this.target,
      progress: progress ?? this.progress,
      xpReward: xpReward ?? this.xpReward,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'arabicTitle': arabicTitle,
    'target': target,
    'progress': progress,
    'xpReward': xpReward,
    'isCompleted': isCompleted,
  };

  factory DailyMission.fromJson(Map<String, dynamic> json) {
    return DailyMission(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      arabicTitle: json['arabicTitle'] as String? ?? '',
      target: json['target'] as int? ?? 0,
      progress: json['progress'] as int? ?? 0,
      xpReward: json['xpReward'] as int? ?? 0,
      isCompleted: json['isCompleted'] as bool? ?? false,
    );
  }
}

class GameState {
  const GameState({
    required this.userProfile,
    required this.levels,
    required this.isLoading,
    required this.error,
    this.dailyMissions = const [],
  });

  final UserGameProfile userProfile;
  final List<GameLevel> levels;
  final bool isLoading;
  final String? error;
  final List<DailyMission> dailyMissions;

  int get totalLevels => levels.length;
  int get completedLevels => levels.where((l) => l.isCompleted).length;
  double get overallProgress => totalLevels == 0 ? 0 : completedLevels / totalLevels;

  GameLevel? get currentLevel {
    try {
      return levels.firstWhere((l) => l.isUnlocked && !l.isCompleted);
    } catch (e) {
      return levels.isNotEmpty ? levels.last : null;
    }
  }

  List<GameLevel> get dueReviewLevels {
    final now = DateTime.now();
    return levels
        .where((l) =>
            l.isCompleted &&
            l.nextReviewDate != null &&
            l.nextReviewDate!.isBefore(now.add(const Duration(days: 1))))
        .toList()
      ..sort((a, b) => (a.nextReviewDate ?? DateTime.now())
          .compareTo(b.nextReviewDate ?? DateTime.now()));
  }

  GameState copyWith({
    UserGameProfile? userProfile,
    List<GameLevel>? levels,
    bool? isLoading,
    String? error,
    List<DailyMission>? dailyMissions,
  }) {
    return GameState(
      userProfile: userProfile ?? this.userProfile,
      levels: levels ?? this.levels,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      dailyMissions: dailyMissions ?? this.dailyMissions,
    );
  }
}

class LevelCompletionResult {
  const LevelCompletionResult({
    required this.levelId,
    required this.starsEarned,
    required this.xpEarned,
    required this.unlockedNextLevel,
    required this.newTotalXp,
    required this.leveledUp,
    required this.coinsEarned,
  });

  final String levelId;
  final int starsEarned;
  final int xpEarned;
  final bool unlockedNextLevel;
  final int newTotalXp;
  final bool leveledUp;
  final int coinsEarned;
}

StationType _parseStationType(dynamic value) {
  if (value is StationType) return value;
  if (value is String) {
    return StationType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => StationType.learning,
    );
  }
  return StationType.learning;
}
