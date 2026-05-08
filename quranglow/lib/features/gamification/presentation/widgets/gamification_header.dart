import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/features/gamification/application/providers/gamification_providers.dart';
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
        boxShadow: const [GameificationColors.softShadow],
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            children: [
              // 1. Top row: Profile level, XP, Coins and Hearts
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Profile Level Section
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: GameificationColors.primaryGradient,
                          boxShadow: [GameificationColors.softShadow],
                        ),
                        child: const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 24,
                        ),
                      ).animate().scale(duration: 300.ms, curve: Curves.easeOutBack),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Level ${userProfile.currentLevel}',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: GameificationColors.primaryGreenDark,
                                ),
                          ),
                          Text(
                            '${userProfile.totalXp} XP',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: GameificationColors.goldDark,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  // Coins & Hearts Actions
                  Row(
                    children: [
                      // Coins Display
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.amber, width: 1.5),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.monetization_on, color: Colors.amber, size: 18),
                            const SizedBox(width: 4),
                            Text(
                              '${userProfile.coins}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.amber,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fade().slideX(begin: 0.2),
                      const SizedBox(width: 10),

                      // Hearts refill action
                      GestureDetector(
                        onTap: () async {
                          if (userProfile.hearts < 5) {
                            if (userProfile.coins >= 50) {
                              final success = await ref
                                  .read(gamificationControllerProvider.notifier)
                                  .buyHeart();
                              if (context.mounted && success) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('تمت استعادة قلب جديد بنجاح! 💖'),
                                    backgroundColor: GameificationColors.primaryGreen,
                                  ),
                                );
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('لا توجد قطع نقدية كافية (تحتاج 50 قطعة)! 🪙'),
                                  backgroundColor: Colors.redAccent,
                                ),
                              );
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.red.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.red, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                userProfile.hearts > 0 ? Icons.favorite : Icons.favorite_border,
                                color: Colors.red,
                                size: 18,
                              ).animate(target: userProfile.hearts < 3 ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1)),
                              const SizedBox(width: 4),
                              Text(
                                '${userProfile.hearts}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: Colors.red,
                                ),
                              ),
                              if (userProfile.hearts < 5) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.add_circle, color: Colors.red, size: 14),
                              ]
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. XP Progress bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress to Level ${userProfile.currentLevel + 1}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                      ),
                      Text(
                        '${(userProfile.levelProgress * 100).toStringAsFixed(0)}%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                      backgroundColor: Colors.grey[200],
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        GameificationColors.primaryGreen,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3. Streak and stats row
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.local_fire_department,
                      iconColor: Colors.orange,
                      label: 'Streak',
                      value: '${userProfile.currentStreak}',
                      subValue: 'days',
                    ).animate().fade(delay: 100.ms).slideY(begin: 0.1),
                  ),
                  const SizedBox(width: 10),
                  // Streak Freeze Shield buy/display card
                  Expanded(
                    child: GestureDetector(
                      onTap: () async {
                        if (userProfile.coins >= 150) {
                          final ok = await ref
                              .read(gamificationControllerProvider.notifier)
                              .buyStreakFreeze();
                          if (context.mounted && ok) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('تم شراء درع حماية الحماس بنجاح! 🛡️'),
                                backgroundColor: Colors.teal,
                              ),
                            );
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('لا تملك قطع نقدية كافية (تحتاج 150)! 🪙'),
                              backgroundColor: Colors.redAccent,
                            ),
                          );
                        }
                      },
                      child: _StatCard(
                        icon: Icons.shield_rounded,
                        iconColor: Colors.teal,
                        label: 'Shields',
                        value: '${userProfile.streakFreezeCount}',
                        subValue: 'Tap to Buy (150)',
                      ),
                    ).animate().fade(delay: 200.ms).slideY(begin: 0.1),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.workspace_premium_rounded,
                      iconColor: GameificationColors.goldAccent,
                      label: 'Achievements',
                      value: '${userProfile.achievements.length}',
                      subValue: 'unlocked',
                    ).animate().fade(delay: 300.ms).slideY(begin: 0.1),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 4. Motivational quote
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: GameificationColors.primaryGreen.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(GameificationColors.radiusMedium),
                  border: Border.all(
                    color: GameificationColors.primaryGreen.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.spa_rounded,
                      color: GameificationColors.primaryGreen,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _getMotivationalQuote(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: GameificationColors.primaryGreen,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.bold,
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
      ),
    );
  }

  String _getMotivationalQuote() {
    final quotes = [
      'كل آية تقرؤها ترفعك درجة في الجنة.. ثابر في رحلتك!',
      'الاستمرار والمداومة على تلاوة كتاب الله تصنع المعجزات في قلبك.',
      'رحلتك القرآنية نور يضيء دربك في الدنيا والآخرة.',
      'أنت تصنع شيئاً عظيماً جداً اليوم بمراجعتك للقرآن الكريم.',
      'إن هذا القرآن يهدي للتي هي أقوم.. دم على درب النور.',
      'خيركم من تعلم القرآن وعلمه.. أهلاً بك في ركب الخيرية.',
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
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(GameificationColors.radiusMedium),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 3),
          )
        ],
        border: Border.all(
          color: Colors.grey[100]!,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 22),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          Text(
            subValue,
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
