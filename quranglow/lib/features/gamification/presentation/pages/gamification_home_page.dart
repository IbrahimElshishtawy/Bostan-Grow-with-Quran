import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/features/gamification/application/providers/gamification_providers.dart';
import 'package:quranglow/features/gamification/domain/models/gamification_models.dart';
import 'package:quranglow/features/gamification/presentation/theme/gamification_colors.dart';
import 'package:quranglow/features/gamification/presentation/widgets/gamification_header.dart';
import 'package:quranglow/features/gamification/presentation/widgets/level_node_painter.dart';
import 'package:quranglow/features/gamification/presentation/widgets/level_node_widget.dart';

class GameificationHomePage extends ConsumerStatefulWidget {
  const GameificationHomePage({super.key});

  @override
  ConsumerState<GameificationHomePage> createState() => _GameificationHomePageState();
}

class _GameificationHomePageState extends ConsumerState<GameificationHomePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _pathAnimationController;
  final double _rowHeight = 170.0;

  @override
  void initState() {
    super.initState();
    _pathAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _pathAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final gameStateAsync = ref.watch(gamificationControllerProvider);

    return gameStateAsync.when(
      loading: () => const _GameificationLoading(),
      error: (error, stackTrace) => _GameificationError(
        error: error,
        onRetry: () => ref.refresh(gamificationControllerProvider),
      ),
      data: (gameState) => _buildBody(gameState),
    );
  }

  Widget _buildBody(GameState gameState) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final int totalStations = gameState.levels.length;
    final int completedCount = gameState.completedLevels;
    final int activeIndex = gameState.levels.indexWhere((l) => l.id == gameState.currentLevel?.id);

    // Continue Learning Smart Suggestion Finder
    final currentActiveStation = gameState.currentLevel;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F6),
      body: Stack(
        children: [
          // Background atmospheric particles & clouds
          Positioned.fill(
            child: _AmbientBackground(stationCount: totalStations, rowHeight: _rowHeight),
          ),

          // Main Scrollable Roadmap Map
          Positioned.fill(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                // 1. Premium Header
                SliverToBoxAdapter(
                  child: GameificationHeader(
                    userProfile: gameState.userProfile,
                    gameState: gameState,
                  ),
                ),

                // 2. Weekly Challenge & Daily Missions Panel
                SliverToBoxAdapter(
                  child: _MissionsAndWeeklyPanel(
                    missions: gameState.dailyMissions,
                    starsCount: gameState.userProfile.totalStars,
                  ),
                ),

                const SliverToBoxAdapter(child: SizedBox(height: 16)),

                // 3. Curved Organic Roadmap Path & Floating Nodes
                SliverToBoxAdapter(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    height: totalStations * _rowHeight + 100,
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Wavy Organic Connecting Path using CustomPainter
                        Positioned.fill(
                          child: AnimatedBuilder(
                            animation: _pathAnimationController,
                            builder: (context, child) {
                              return CustomPaint(
                                painter: QuranJourneyPathPainter(
                                  stationCount: totalStations,
                                  completedCount: completedCount,
                                  activeIndex: activeIndex == -1 ? 0 : activeIndex,
                                  rowHeight: _rowHeight,
                                  animationValue: _pathAnimationController.value,
                                ),
                              );
                            },
                          ),
                        ),

                        // Float the Level Station Nodes along the wavy path
                        ...List.generate(totalStations, (index) {
                          final station = gameState.levels[index];
                          final isActive = station.id == gameState.currentLevel?.id;
                          
                          final double dx = screenWidth / 2 + math.sin(index * 0.9) * 85;
                          final double dy = index * _rowHeight;

                          return Positioned(
                            left: dx - 80,
                            top: dy,
                            width: 160,
                            height: _rowHeight,
                            child: Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.center,
                              children: [
                                LevelNodeWidget(
                                  level: station,
                                  isActive: isActive,
                                  onTap: () => _openStationTasksSheet(context, station),
                                ),

                                // Interactive Surprise Reward Chest right above mystery stations!
                                if (station.isMystery && !gameState.userProfile.chestsClaimed.contains('chest_$index') && station.isUnlocked)
                                  Positioned(
                                    top: -45,
                                    child: GestureDetector(
                                      onTap: () => _claimSurpriseChestDialog(context, 'chest_$index'),
                                      child: Column(
                                        children: [
                                          const Icon(
                                            Icons.card_giftcard_rounded,
                                            color: Colors.amber,
                                            size: 32,
                                          ).animate(onPlay: (c) => c.repeat()).scale(curve: Curves.easeOutBack).shimmer(duration: 2.seconds),
                                          const Text(
                                            'هدية مفاجأة!',
                                            style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),

          // 4. "Continue Learning" Smart Suggestions Floating Action Button
          if (currentActiveStation != null)
            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: GestureDetector(
                onTap: () => _openStationTasksSheet(context, currentActiveStation),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [GameificationColors.primaryGreen, GameificationColors.primaryGreenLight],
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: GameificationColors.primaryGreen.withValues(alpha: 0.35),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      )
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bolt_rounded, color: Colors.white, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        'تابع رحلتك: ابدأ ${currentActiveStation.surahName}! 🌟',
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate(onPlay: (c) => c.repeat(reverse: true)).scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05)),
            ),
        ],
      ),
    );
  }

  void _openStationTasksSheet(BuildContext context, GameLevel level) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _StationTasksSheet(level: level),
    );
  }

  void _claimSurpriseChestDialog(BuildContext context, String chestId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.card_giftcard_rounded, size: 72, color: Colors.amber)
                .animate()
                .scale(duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 16),
            const Text(
              'صندوق المفاجأة والجوائز! 🎁',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            const Text(
              'أحسنت السير على الدرب الرباني! اضغط لفتح الهدية الخاصة وحصد المكافأة.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                final success = await ref
                    .read(gamificationControllerProvider.notifier)
                    .claimSurpriseChest(chestId);
                if (context.mounted) {
                  Navigator.pop(context);
                  if (success) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('تم فتح الصندوق بنجاح وحصدت +100 قطعة نقدية و+50 XP! 🪙✨'),
                        backgroundColor: GameificationColors.primaryGreen,
                      ),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.amber,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('فتح الصندوق وحصد الجائزة', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }
}

class _GameificationLoading extends StatelessWidget {
  const _GameificationLoading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: GameificationColors.backgroundGradient,
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(
                  GameificationColors.primaryGreen,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'تحميل درب النور والتمكين...',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: GameificationColors.primaryGreenDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameificationError extends StatelessWidget {
  const _GameificationError({
    required this.error,
    required this.onRetry,
  });

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text('حدث خطأ أثناء تحميل الدرب'),
            const SizedBox(height: 8),
            Text(error.toString(), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(onPressed: onRetry, child: const Text('إعادة المحاولة')),
          ],
        ),
      ),
    );
  }
}

class _AmbientBackground extends StatelessWidget {
  const _AmbientBackground({required this.stationCount, required this.rowHeight});

  final int stationCount;
  final double rowHeight;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: List.generate(stationCount, (index) {
          final isEven = index % 2 == 0;
          return Container(
            height: rowHeight,
            alignment: isEven ? Alignment.centerLeft : Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Opacity(
              opacity: 0.15,
              child: Icon(
                isEven ? Icons.cloud_queue_rounded : Icons.wb_sunny_outlined,
                size: 70,
                color: GameificationColors.primaryGreen,
              ),
            ),
          );
        }),
      ),
    );
  }
}

class _MissionsAndWeeklyPanel extends StatelessWidget {
  const _MissionsAndWeeklyPanel({required this.missions, required this.starsCount});

  final List<DailyMission> missions;
  final int starsCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Weekly Quran Challenge banner
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Colors.deepPurple, Colors.indigo]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.military_tech_rounded, color: Colors.amber, size: 28),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'التحدي الأسبوعي للتدبر 🏆',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        'احصد 15 نجمة هذا الأسبوع لتفتح التاج الذهبي! نجومك: $starsCount',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Row(
            children: [
              const Icon(Icons.stars_rounded, color: GameificationColors.goldAccent, size: 24),
              const SizedBox(width: 8),
              Text(
                'المهام اليومية والجوائز',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: GameificationColors.primaryGreenDark,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...missions.map((m) {
            final double percent = m.target == 0 ? 0 : m.progress / m.target;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        m.arabicTitle,
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87),
                      ),
                      Text(
                        '${m.progress}/${m.target}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: GameificationColors.goldDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: LinearProgressIndicator(
                      value: percent,
                      minHeight: 6,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        m.isCompleted ? GameificationColors.primaryGreen : GameificationColors.goldAccent,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    ).animate().fade().slideY(begin: 0.1);
  }
}

class _StationTasksSheet extends ConsumerWidget {
  const _StationTasksSheet({required this.level});

  final GameLevel level;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              SizedBox(
                width: 40,
                height: 4,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Sheet Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(shape: BoxShape.circle, gradient: GameificationColors.primaryGradient),
                      child: const Icon(Icons.auto_stories, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            level.surahName,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
                          ),
                          Text(
                            'المستوى الحالي • آيات ${level.ayahStart}-${level.ayahEnd}',
                            style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Divider(),

              // Sub-tasks list
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    // level mastery trigger option
                    if (level.isCompleted && level.masteryLevel == 0) ...[
                      GestureDetector(
                        onTap: () async {
                          final ok = await ref
                              .read(gamificationControllerProvider.notifier)
                              .activateLevelMastery(level.id);
                          if (context.mounted && ok) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تهانينا! تم تفعيل مستوى التاج الذهبي للتحدي المضاعف! 👑🏆'),
                                backgroundColor: GameificationColors.goldAccent,
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Colors.orange, Colors.amber]),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 22),
                              SizedBox(width: 8),
                              Text(
                                'الترقية لمستوى التاج الذهبي (جوائز x2)! 👑',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ).animate().scale().scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05)),
                      const SizedBox(height: 16),
                    ],

                    const Text(
                      'أكمل المهام الخمس لتثبيت المستوى وحصد النجوم والجوائز الكبرى:',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    _TaskTile(
                      index: 1,
                      title: 'الاستماع والترتيل',
                      subtitle: 'استمع بخشوع لآيات المستوى',
                      icon: Icons.headphones_rounded,
                      isCompleted: level.isListenCompleted,
                      onTap: () => _launchListenTask(context, ref),
                    ),
                    _TaskTile(
                      index: 2,
                      title: 'القراءة والتحسين',
                      subtitle: 'اقرأ الآيات بتركيز مع الترجمة والتفسير',
                      icon: Icons.menu_book_rounded,
                      isCompleted: level.isReadCompleted,
                      onTap: () => _launchReadTask(context, ref),
                    ),
                    _TaskTile(
                      index: 3,
                      title: 'الكتابة والتركيب',
                      subtitle: 'أعد بناء الآيات عن طريق ترتيب الكلمات المبعثرة',
                      icon: Icons.edit_note_rounded,
                      isCompleted: level.isWriteCompleted,
                      onTap: () => _launchWriteTask(context, ref),
                    ),
                    _TaskTile(
                      index: 4,
                      title: 'الحفظ والتمكين',
                      subtitle: 'اختبر ذاكرتك بإخفاء الكلمات المظللة وتثبيتها',
                      icon: Icons.psychology_rounded,
                      isCompleted: level.isMemorizeCompleted,
                      onTap: () => _launchMemorizeTask(context, ref),
                    ),
                    _TaskTile(
                      index: 5,
                      title: 'المسابقة السريعة',
                      subtitle: 'أجب عن أسئلة التدبر والتفسير التفاعلية',
                      icon: Icons.workspace_premium_rounded,
                      isCompleted: level.isQuizCompleted,
                      onTap: () => _launchQuizTask(context, ref),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // --- Interactive Mini Games ---

  void _launchListenTask(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _InteractiveListenDialog(
        level: level,
        onComplete: () {
          ref.read(gamificationControllerProvider.notifier).completeSubTask(level.id, 'listen');
        },
      ),
    );
  }

  void _launchReadTask(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _InteractiveReadDialog(
        level: level,
        onComplete: () {
          ref.read(gamificationControllerProvider.notifier).completeSubTask(level.id, 'read');
        },
      ),
    );
  }

  void _launchWriteTask(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _InteractiveWriteDialog(
        level: level,
        onComplete: () {
          ref.read(gamificationControllerProvider.notifier).completeSubTask(level.id, 'write');
        },
      ),
    );
  }

  void _launchMemorizeTask(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _InteractiveMemorizeDialog(
        level: level,
        onComplete: () {
          ref.read(gamificationControllerProvider.notifier).completeSubTask(level.id, 'memorize');
        },
      ),
    );
  }

  void _launchQuizTask(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => _InteractiveQuizDialog(
        level: level,
        onComplete: (combo) {
          ref.read(gamificationControllerProvider.notifier).completeSubTask(level.id, 'quiz', quizCombo: combo);
        },
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({
    required this.index,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isCompleted,
    required this.onTap,
  });

  final int index;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isCompleted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFFF1F8F5) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted ? GameificationColors.primaryGreen.withValues(alpha: 0.3) : Colors.grey[200]!,
          width: 1.5,
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isCompleted ? GameificationColors.primaryGreen : Colors.grey[100],
          ),
          child: Icon(
            isCompleted ? Icons.check_rounded : icon,
            color: isCompleted ? Colors.white : Colors.grey[600],
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isCompleted ? GameificationColors.primaryGreenDark : Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.bold),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          size: 14,
          color: isCompleted ? GameificationColors.primaryGreen : Colors.grey,
        ),
      ),
    );
  }
}

// ----------------------------------------------------
// TASK MINI GAME DIALOGS WITH MORAL CELEBRATIONS
// ----------------------------------------------------

class _InteractiveListenDialog extends StatefulWidget {
  const _InteractiveListenDialog({required this.level, required this.onComplete});
  final GameLevel level;
  final VoidCallback onComplete;

  @override
  State<_InteractiveListenDialog> createState() => _InteractiveListenDialogState();
}

class _InteractiveListenDialogState extends State<_InteractiveListenDialog> {
  bool _isPlaying = false;
  double _progress = 0.0;
  bool _completed = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.headphones_rounded, size: 56, color: GameificationColors.primaryGreen),
          const SizedBox(height: 12),
          Text('محطة الاستماع • ${widget.level.surahName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('استمع بخشوع لتسجيل ورتل الآيات معه بتدبر.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
          const SizedBox(height: 24),

          if (_isPlaying)
            Container(
              height: 40,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  8,
                  (i) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    width: 4,
                    height: 10.0 + (math.Random().nextDouble() * 30.0),
                    decoration: BoxDecoration(color: GameificationColors.primaryGreen, borderRadius: BorderRadius.circular(2)),
                  ),
                ),
              ).animate(onPlay: (controller) => controller.repeat(reverse: true)).scale(duration: 400.ms),
            ),
          const SizedBox(height: 16),

          LinearProgressIndicator(value: _progress, minHeight: 6, backgroundColor: Colors.grey[200], valueColor: const AlwaysStoppedAnimation<Color>(GameificationColors.primaryGreen)),
          const SizedBox(height: 24),

          if (!_completed)
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _isPlaying = true);
                Future.doWhile(() async {
                  await Future.delayed(const Duration(milliseconds: 100));
                  if (!mounted) return false;
                  setState(() {
                    _progress += 0.04;
                    if (_progress >= 1.0) {
                      _progress = 1.0;
                      _completed = true;
                      _isPlaying = false;
                      widget.onComplete();
                    }
                  });
                  return _progress < 1.0;
                });
              },
              icon: const Icon(Icons.play_arrow),
              label: const Text('بدء الاستماع للترتيل'),
              style: ElevatedButton.styleFrom(backgroundColor: GameificationColors.primaryGreen, foregroundColor: Colors.white),
            )
          else
            Column(
              children: [
                const Text('أحسنت الاستماع والخشوع! 🪙', style: TextStyle(fontWeight: FontWeight.bold, color: GameificationColors.primaryGreen)),
                const SizedBox(height: 8),
                const Text(
                  'قال النبي ﷺ: "الذي يقرأ القرآن وهو ماهر به مع السفرة الكرام البررة."',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: GameificationColors.primaryGreen, foregroundColor: Colors.white),
                  child: const Text('إغلاق والمتابعة'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _InteractiveReadDialog extends StatefulWidget {
  const _InteractiveReadDialog({required this.level, required this.onComplete});
  final GameLevel level;
  final VoidCallback onComplete;

  @override
  State<_InteractiveReadDialog> createState() => _InteractiveReadDialogState();
}

class _InteractiveReadDialogState extends State<_InteractiveReadDialog> {
  bool _finished = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.menu_book_rounded, size: 56, color: GameificationColors.goldAccent),
          const SizedBox(height: 12),
          Text('محطة القراءة والتحسين • ${widget.level.surahName}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFF9FBF9), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey[200]!)),
            child: const Text(
              'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ\nالْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ الرَّحْمَٰنِ الرَّحِيمِ مَالِكِ يَوْمِ الدِّينِ إِيَّاكَ نَعْبُدُ وَإِيَّاكَ نَسْتَعِينُ اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ صِرَاطَ الَّذِينَ أَنْعَمْتَ عَلَيْهِمْ غَيْرِ الْمَغْضُوبِ عَلَيْهِمْ وَلَا الضَّالِّينَ',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Inter', fontSize: 18, fontWeight: FontWeight.bold, height: 1.8, color: GameificationColors.primaryGreenDark),
            ),
          ),
          const SizedBox(height: 20),

          if (!_finished)
            ElevatedButton(
              onPressed: () {
                setState(() => _finished = true);
                widget.onComplete();
              },
              style: ElevatedButton.styleFrom(backgroundColor: GameificationColors.goldAccent, foregroundColor: Colors.white),
              child: const Text('أكملت القراءة والتدبر'),
            )
          else
            Column(
              children: [
                const Text('بارك الله فيك وتقبل منك! 🌟', style: TextStyle(fontWeight: FontWeight.bold, color: GameificationColors.primaryGreen)),
                const SizedBox(height: 8),
                const Text(
                  'عن ابن مسعود رضي الله عنه قال ﷺ: "من قرأ حرفاً من كتاب الله فله به حسنة والحسنة بعشر أمثالها."',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: GameificationColors.primaryGreen, foregroundColor: Colors.white),
                  child: const Text('المتابعة'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _InteractiveWriteDialog extends StatefulWidget {
  const _InteractiveWriteDialog({required this.level, required this.onComplete});
  final GameLevel level;
  final VoidCallback onComplete;

  @override
  State<_InteractiveWriteDialog> createState() => _InteractiveWriteDialogState();
}

class _InteractiveWriteDialogState extends State<_InteractiveWriteDialog> {
  final List<String> _shuffledWords = ['الرَّحْمَٰنِ', 'بِسْمِ', 'الرَّحِيمِ', 'اللَّهِ'];
  final List<String> _selectedWords = [];
  final List<String> _correctAnswer = ['بِسْمِ', 'اللَّهِ', 'الرَّحْمَٰنِ', 'الرَّحِيمِ'];
  bool _correct = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.edit_note_rounded, size: 56, color: Colors.blue),
          const SizedBox(height: 12),
          const Text('محطة بناء الآية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('رتب الكلمات التالية لبناء البسملة بشكل صحيح:', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey[200]!)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: _selectedWords.map((word) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Chip(
                    label: Text(word, style: const TextStyle(fontWeight: FontWeight.bold)),
                    onDeleted: () {
                      setState(() {
                        _selectedWords.remove(word);
                        _shuffledWords.add(word);
                      });
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),

          if (!_correct)
            Wrap(
              spacing: 8,
              children: _shuffledWords.map((word) {
                return ActionChip(
                  label: Text(word, style: const TextStyle(fontWeight: FontWeight.bold)),
                  onPressed: () {
                    setState(() {
                      _shuffledWords.remove(word);
                      _selectedWords.add(word);

                      if (_selectedWords.length == _correctAnswer.length) {
                        bool matched = true;
                        for (int i = 0; i < _correctAnswer.length; i++) {
                          if (_selectedWords[i] != _correctAnswer[i]) matched = false;
                        }
                        if (matched) {
                          _correct = true;
                          widget.onComplete();
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('الترتيب غير صحيح، حاول مجدداً! ❌')));
                          _shuffledWords.addAll(_selectedWords);
                          _selectedWords.clear();
                        }
                      }
                    });
                  },
                );
              }).toList(),
            )
          else
            Column(
              children: [
                const Text('أحسنت الترتيب والبناء! 🎉', style: TextStyle(fontWeight: FontWeight.bold, color: GameificationColors.primaryGreen)),
                const SizedBox(height: 8),
                const Text(
                  'كتابة آيات القرآن الكريم وتثبيتها ترسخ معانيها في وجدانك وعقلك.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: GameificationColors.primaryGreen, foregroundColor: Colors.white),
                  child: const Text('المتابعة'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _InteractiveMemorizeDialog extends StatefulWidget {
  const _InteractiveMemorizeDialog({required this.level, required this.onComplete});
  final GameLevel level;
  final VoidCallback onComplete;

  @override
  State<_InteractiveMemorizeDialog> createState() => _InteractiveMemorizeDialogState();
}

class _InteractiveMemorizeDialogState extends State<_InteractiveMemorizeDialog> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.psychology_rounded, size: 56, color: Colors.purple),
          const SizedBox(height: 12),
          const Text('محطة الحفظ والتمكين', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('اقرأ الآية وحاول استذكار الكلمة المخفية في المربع المظلل:', textAlign: TextAlign.center, style: TextStyle(fontSize: 12)),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: const Color(0xFFFBF8FB), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.purple.withValues(alpha: 0.15))),
            child: Column(
              children: [
                const Text('الْحَمْدُ لِلَّهِ رَبِّ', textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: _revealed ? Colors.transparent : Colors.purple[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _revealed ? 'الْعَالَمِينَ' : '???',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _revealed ? GameificationColors.primaryGreen : Colors.purple[700],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          if (!_revealed)
            ElevatedButton(
              onPressed: () {
                setState(() => _revealed = true);
                widget.onComplete();
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.purple, foregroundColor: Colors.white),
              child: const Text('كشف والتحقق من الحفظ'),
            )
          else
            Column(
              children: [
                const Text('حفظ ممتاز ومبارك! 💖', style: TextStyle(fontWeight: FontWeight.bold, color: GameificationColors.primaryGreen)),
                const SizedBox(height: 8),
                const Text(
                  'قال ابن مسعود: "حفظ القرآن الكريم وتثبيته في الصدور نجاة ورفعة في الدارين."',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontStyle: FontStyle.italic, fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: GameificationColors.primaryGreen, foregroundColor: Colors.white),
                  child: const Text('المتابعة'),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _InteractiveQuizDialog extends StatefulWidget {
  const _InteractiveQuizDialog({required this.level, required this.onComplete});
  final GameLevel level;
  final Function(int combo) onComplete;

  @override
  State<_InteractiveQuizDialog> createState() => _InteractiveQuizDialogState();
}

class _InteractiveQuizDialogState extends State<_InteractiveQuizDialog> {
  int? _selectedIndex;
  final List<String> _options = ['الرحمة والمغفرة', 'الهداية إلى الطريق المستقيم', 'العزة والملكوت'];
  final int _correctIndex = 1;
  int _combo = 1; // Tracking consecutive combo answers

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.workspace_premium_rounded, size: 56, color: Colors.orange),
          const SizedBox(height: 12),
          const Text('مسابقة التدبر والتفسير', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          const Text('ما هو المعنى الرئيسي لقوله تعالى: "اهْدِنَا الصِّرَاطَ الْمُسْتَقِيمَ"؟', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),

          ...List.generate(_options.length, (index) {
            final isSelected = _selectedIndex == index;
            final isCorrectAnswer = index == _correctIndex;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ElevatedButton(
                onPressed: _selectedIndex != null
                    ? null
                    : () {
                        setState(() {
                          _selectedIndex = index;
                          if (index == _correctIndex) {
                            _combo = 3; // award combo multiplier on correct!
                            widget.onComplete(_combo);
                          } else {
                            _combo = 1;
                          }
                        });
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedIndex != null
                      ? isCorrectAnswer
                          ? Colors.green
                          : isSelected
                              ? Colors.red
                              : Colors.white
                      : Colors.white,
                  foregroundColor: _selectedIndex != null && (isCorrectAnswer || isSelected) ? Colors.white : Colors.black87,
                  side: BorderSide(color: Colors.grey[200]!),
                  minimumSize: const Size.fromHeight(48),
                ),
                child: Text(_options[index], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
              ),
            );
          }),

          if (_selectedIndex != null) ...[
            const SizedBox(height: 16),
            if (_selectedIndex == _correctIndex) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.amber.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.bolt, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text('Combo Multiplier x$_combo activated! +15 XP Bonus! ⚡', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber)),
                  ],
                ),
              ).animate().scale(curve: Curves.elasticOut),
              const SizedBox(height: 8),
            ],
            Text(
              _selectedIndex == _correctIndex ? 'أحسنت! الإجابة صحيحة ومباركة 🎉' : 'إجابة خاطئة، حاول مجدداً لاحقاً! ❌',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _selectedIndex == _correctIndex ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(backgroundColor: GameificationColors.primaryGreen, foregroundColor: Colors.white),
              child: const Text('المتابعة والدرب'),
            ),
          ],
        ],
      ),
    );
  }
}
