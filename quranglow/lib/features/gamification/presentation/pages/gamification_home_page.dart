import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/features/gamification/application/providers/gamification_providers.dart';
import 'package:quranglow/features/gamification/domain/models/gamification_models.dart';
import 'package:quranglow/features/gamification/presentation/theme/gamification_colors.dart';
import 'package:quranglow/features/gamification/presentation/widgets/components/station_tasks_sheet.dart';
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
  final double _rowHeight = 220.0;

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
      builder: (context) => StationTasksSheet(level: level),
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
