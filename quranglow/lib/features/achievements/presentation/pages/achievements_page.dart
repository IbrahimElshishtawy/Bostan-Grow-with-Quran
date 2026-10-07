import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../design_system/colors/app_palette.dart';
import '../../../design_system/components/app_components.dart';
import '../../../design_system/spacing/app_spacing.dart';
import '../../domain/entities/achievement.dart';

class AchievementsPage extends StatelessWidget {
  const AchievementsPage({super.key});

  static const List<Achievement> _defaultAchievements = [
    Achievement(
      id: 'first_reading',
      title: 'بداية الرحلة',
      description: 'أتممت أول جلسة قراءة لك في بستان القرآن',
      category: 'reading',
      isUnlocked: true,
    ),
    Achievement(
      id: '7_day_streak',
      title: 'مداومة أسبوعية',
      description: 'حافظت على قراءة وردك لـ 7 أيام متتالية',
      category: 'streak',
      isUnlocked: true,
    ),
    Achievement(
      id: '30_day_streak',
      title: 'مداومة شهرية',
      description: 'حافظت على قراءة القرآن لـ 30 يوماً متتالياً',
      category: 'streak',
      isUnlocked: false,
    ),
    Achievement(
      id: '100_pages',
      title: 'مئة صفحة من النور',
      description: 'أتممت قراءة 100 صفحة من القرآن الكريم',
      category: 'reading',
      isUnlocked: false,
    ),
    Achievement(
      id: 'first_memorization',
      title: 'حامل القرآن',
      description: 'بدأت أول خطة لحفظ كتاب الله',
      category: 'memorization',
      isUnlocked: true,
    ),
    Achievement(
      id: 'first_khatmah',
      title: 'ختمة مباركة',
      description: 'مبارك إتمام أول ختمة للقرآن الكريم',
      category: 'khatmah',
      isUnlocked: false,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('أوسمة الإنجاز', style: GoogleFonts.cairo(fontWeight: FontWeight.bold)),
      ),
      body: ListView.separated(
        padding: AppSpacing.pagePadding,
        itemCount: _defaultAchievements.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.m),
        itemBuilder: (context, index) {
          final ach = _defaultAchievements[index];
          return AppSurfaceCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: ach.isUnlocked ? AppPalette.gold.withAlpha(40) : Colors.grey.withAlpha(30),
                  child: Icon(
                    ach.isUnlocked ? Icons.workspace_premium_rounded : Icons.lock_outline_rounded,
                    color: ach.isUnlocked ? AppPalette.goldDark : Colors.grey,
                    size: 30,
                  ),
                ),
                const SizedBox(width: AppSpacing.l),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ach.title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: ach.isUnlocked ? AppPalette.textPrimaryLight : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        ach.description,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                if (ach.isUnlocked)
                  const Icon(Icons.check_circle_rounded, color: AppPalette.success, size: 22),
              ],
            ),
          );
        },
      ),
    );
  }
}
