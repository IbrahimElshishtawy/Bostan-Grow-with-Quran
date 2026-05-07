/// Gamification header widget showing user profile, XP, streak, and hearts

library gamification_header;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/features/gamification/domain/models/gamification_models.dart';
import 'package:quranglow/features/gamification/presentation/theme/gamification_colors.dart';

class GameificationHeader extends ConsumerWidget {
  const GameificationHeader({
    required this.userProfile,
    required this.gameState,
    super.key,
  });

  final UserGameProfile userProfile;
  final GameState gameState;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        gradient: isDark
            ? GameificationColors.darkBackgroundGradient
            : GameificationColors.backgroundGradient,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(GameificationColors.radiusXLarge),
          bottomRight: Radius.circular(GameificationColors.radiusXLarge),
        ),
        boxShadow: [GameificationColors.softShadow],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Top row: Profile and hearts
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Profile section
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: GameificationColors.primaryGradient,
                        boxShadow: [GameificationColors.softShadow],
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Level ${userProfile.currentLevel}',
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        Text(
                          '${userProfile.totalXp} XP',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: GameificationColors.goldAccent,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),
                // Hearts
                Row(
                  children: List.generate(
                    5,
                    (index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Icon(
                        index < userProfile.hearts
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: index < userProfile.hearts
                            ? Colors.red
                            : Colors.grey[400],
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // XP Progress bar
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Progress to Level ${userProfile.currentLevel + 1}',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    Text(
                      '${(userProfile.levelProgress * 100).toStringAsFixed(0)}%',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: GameificationColors.goldAccent,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: userProfile.levelProgress,
                    minHeight: 8,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      GameificationColors.primaryGreen,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Streak and stats row
            Row(
              children: [
                // Streak
                Expanded(
                  child: _StatCard(
                    icon: Icons.local_fire_department,
                    iconColor: Colors.orange,
                    label: 'Streak',
                    value: '${userProfile.currentStreak}',
                    subValue: 'days',
                  ),
                ),
                const SizedBox(width: 12),
                // Levels completed
                Expanded(
                  child: _StatCard(
                    icon: Icons.check_circle,
                    iconColor: GameificationColors.primaryGreen,
                    label: 'Completed',
                    value: '${gameState.completedLevels}',
                    subValue: 'levels',
                  ),
                ),
                const SizedBox(width: 12),
                // Total stars
                Expanded(
                  child: _StatCard(
                    icon: Icons.star,
                    iconColor: GameificationColors.goldAccent,
                    label: 'Stars',
                    value: '${userProfile.totalStars}',
                    subValue: 'earned',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Motivational quote
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: GameificationColors.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(GameificationColors.radiusMedium),
                border: Border.all(
                  color: GameificationColors.primaryGreen.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.lightbulb,
                    color: GameificationColors.primaryGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _getMotivationalQuote(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: GameificationColors.primaryGreen,
                            fontStyle: FontStyle.italic,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getMotivationalQuote() {
    final quotes = [
      'Every verse brings you closer to mastery',
      'Consistency is the key to success',
      'Your dedication will be rewarded',
      'Keep the momentum going!',
      'You are making great progress',
      'Believe in your journey',
      'Excellence comes with practice',
      'Stay focused, stay blessed',
    ];

    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    return quotes[dayOfYear % quotes.length];
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subValue,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String subValue;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(GameificationColors.radiusMedium),
        border: Border.all(
          color: Colors.grey[300]!,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          Text(
            subValue,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }
}
