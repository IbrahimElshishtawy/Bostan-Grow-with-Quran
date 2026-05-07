/// Main gamification home page with progression map
/// Displays the Duolingo/Candy Crush-style level progression

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/features/gamification/application/providers/gamification_providers.dart';
import 'package:quranglow/features/gamification/domain/models/gamification_models.dart';
import 'package:quranglow/features/gamification/presentation/theme/gamification_colors.dart';
import 'package:quranglow/features/gamification/presentation/widgets/gamification_header.dart';
import 'package:quranglow/features/gamification/presentation/widgets/level_node_widget.dart';

class GameificationHomePage extends ConsumerWidget {
  const GameificationHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameStateAsync = ref.watch(gamificationControllerProvider);

    return gameStateAsync.when(
      loading: () => const _GameificationLoading(),
      error: (error, stackTrace) => _GameificationError(
        error: error,
        onRetry: () => ref.refresh(gamificationControllerProvider),
      ),
      data: (gameState) => _GameificationContent(gameState: gameState),
    );
  }
}

class _GameificationLoading extends StatelessWidget {
  const _GameificationLoading();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: GameificationColors.backgroundGradient,
        ),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              GameificationColors.primaryGreen,
            ),
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
      body: Container(
        decoration: BoxDecoration(
          gradient: GameificationColors.backgroundGradient,
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 64,
                color: GameificationColors.primaryGreen,
              ),
              const SizedBox(height: 16),
              Text(
                'Something went wrong',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                error.toString(),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GameificationContent extends ConsumerWidget {
  const _GameificationContent({required this.gameState});

  final GameState gameState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: GameificationColors.backgroundGradient,
        ),
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: GameificationHeader(
                userProfile: gameState.userProfile,
                gameState: gameState,
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Due reviews section
            if (gameState.dueReviewLevels.isNotEmpty)
              SliverToBoxAdapter(
                child: _DueReviewsSection(
                  levels: gameState.dueReviewLevels,
                ),
              ),

            // Progression map title
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Journey',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${gameState.completedLevels} of ${gameState.totalLevels} levels completed',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 12),
                    // Overall progress bar
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: gameState.overallProgress,
                        minHeight: 6,
                        backgroundColor: Colors.grey[300],
                        valueColor: AlwaysStoppedAnimation<Color>(
                          GameificationColors.primaryGreen,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Levels grid
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList.builder(
                itemCount: gameState.levels.length,
                itemBuilder: (context, index) {
                  final level = gameState.levels[index];
                  final isActive = level.id == gameState.currentLevel?.id;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: Center(
                      child: LevelNodeWidget(
                        level: level,
                        isActive: isActive,
                        onTap: () => _openLevelDetail(context, level),
                        showPath: index > 0,
                        pathProgress: level.isCompleted ? 1.0 : 0.0,
                      ),
                    ),
                  );
                },
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        ),
      ),
    );
  }

  void _openLevelDetail(BuildContext context, GameLevel level) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _LevelDetailSheet(level: level),
    );
  }
}

class _DueReviewsSection extends StatelessWidget {
  const _DueReviewsSection({required this.levels});

  final List<GameLevel> levels;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(GameificationColors.radiusMedium),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.schedule,
            color: Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Review Time!',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                ),
                Text(
                  '${levels.length} level${levels.length > 1 ? 's' : ''} ready for review',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.orange[700],
                      ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }
}

class _LevelDetailSheet extends StatelessWidget {
  const _LevelDetailSheet({required this.level});

  final GameLevel level;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(GameificationColors.radiusXLarge),
              topRight: Radius.circular(GameificationColors.radiusXLarge),
            ),
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.all(16),
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Level header
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: GameificationColors.primaryGradient,
                    ),
                    child: Icon(
                      _getLevelTypeIcon(level.type),
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          level.title,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          level.type.label,
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              Text(
                level.description,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),

              // Stats
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      icon: Icons.star,
                      label: 'Stars',
                      value: '${level.starsEarned}/${level.maxStars}',
                      color: GameificationColors.goldAccent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(
                      icon: Icons.flash_on,
                      label: 'XP Reward',
                      value: '+${level.xpReward}',
                      color: GameificationColors.primaryGreen,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Ayah range
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(GameificationColors.radiusMedium),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Content',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${level.surahName} - Ayah ${level.ayahStart} to ${level.ayahEnd}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${level.ayahCount} verses • Difficulty: ${level.difficulty}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action buttons
              if (level.isUnlocked)
                Column(
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        // TODO: Navigate to level content
                      },
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Start Level'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: GameificationColors.primaryGreen,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                      ),
                    ),
                    if (level.hasAudio) ...[
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Play audio
                        },
                        icon: const Icon(Icons.headphones),
                        label: const Text('Listen to Recitation'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                      ),
                    ],
                  ],
                )
              else
                ElevatedButton.icon(
                  onPressed: null,
                  icon: const Icon(Icons.lock),
                  label: const Text('Locked'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  IconData _getLevelTypeIcon(LevelType type) {
    switch (type) {
      case LevelType.surah:
        return Icons.menu_book;
      case LevelType.tajweed:
        return Icons.music_note;
      case LevelType.review:
        return Icons.refresh;
      case LevelType.bossTest:
        return Icons.shield;
      case LevelType.dailyChallenge:
        return Icons.flash_on;
    }
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(GameificationColors.radiusMedium),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }
}
