/// Gamification domain models for the progression system

enum LevelType {
  surah('Surah Level'),
  tajweed('Tajweed Lesson'),
  review('Review Checkpoint'),
  bossTest('Boss Test'),
  dailyChallenge('Daily Challenge');

  const LevelType(this.label);
  final String label;
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
  });

  final String id;
  final int sequence;
  final LevelType type;
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

  bool get isCompleted => starsEarned > 0;
  bool get isPerfect => starsEarned == maxStars;
  int get ayahCount => ayahEnd - ayahStart + 1;

  GameLevel copyWith({
    String? id,
    int? sequence,
    LevelType? type,
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
  };

  factory GameLevel.fromJson(Map<String, dynamic> json) {
    return GameLevel(
      id: json['id'] as String? ?? '',
      sequence: json['sequence'] as int? ?? 0,
      type: _parseLevelType(json['type']),
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
  });

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
          ? DateTime.tryParse(json['joinDate'] as String)
          : DateTime.now(),
      currentStreak: json['currentStreak'] as int? ?? 0,
    );
  }
}

class GameState {
  const GameState({
    required this.userProfile,
    required this.levels,
    required this.isLoading,
    required this.error,
  });

  final UserGameProfile userProfile;
  final List<GameLevel> levels;
  final bool isLoading;
  final String? error;

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
  }) {
    return GameState(
      userProfile: userProfile ?? this.userProfile,
      levels: levels ?? this.levels,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
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
  });

  final String levelId;
  final int starsEarned;
  final int xpEarned;
  final bool unlockedNextLevel;
  final int newTotalXp;
  final bool leveledUp;
}

LevelType _parseLevelType(dynamic value) {
  if (value is LevelType) return value;
  if (value is String) {
    return LevelType.values.firstWhere(
      (t) => t.name == value,
      orElse: () => LevelType.surah,
    );
  }
  return LevelType.surah;
}
