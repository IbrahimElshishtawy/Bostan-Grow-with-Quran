import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/features/gamification/application/providers/gamification_providers.dart';
import 'package:quranglow/features/gamification/domain/models/gamification_models.dart';
import 'package:quranglow/features/gamification/presentation/theme/gamification_colors.dart';
import 'package:quranglow/features/gamification/presentation/widgets/components/task_tile.dart';
import 'package:quranglow/features/gamification/presentation/widgets/dialogs/listen_dialog.dart';
import 'package:quranglow/features/gamification/presentation/widgets/dialogs/memorize_dialog.dart';
import 'package:quranglow/features/gamification/presentation/widgets/dialogs/quiz_dialog.dart';
import 'package:quranglow/features/gamification/presentation/widgets/dialogs/read_dialog.dart';
import 'package:quranglow/features/gamification/presentation/widgets/dialogs/write_dialog.dart';

class StationTasksSheet extends ConsumerWidget {
  const StationTasksSheet({
    required this.level,
    super.key,
  });

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
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: GameificationColors.primaryGradient,
                      ),
                      child: const Icon(Icons.auto_stories, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            level.surahName,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            'المستوى الحالي • آيات ${level.ayahStart}-${level.ayahEnd}',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.bold,
                            ),
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
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
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

                    TaskTile(
                      index: 1,
                      title: 'الاستماع والترتيل',
                      subtitle: 'استمع بخشوع لآيات المستوى',
                      icon: Icons.headphones_rounded,
                      isCompleted: level.isListenCompleted,
                      onTap: () => _launchListenTask(context, ref),
                    ),
                    TaskTile(
                      index: 2,
                      title: 'القراءة والتحسين',
                      subtitle: 'اقرأ الآيات بتركيز مع الترجمة والتفسير',
                      icon: Icons.menu_book_rounded,
                      isCompleted: level.isReadCompleted,
                      onTap: () => _launchReadTask(context, ref),
                    ),
                    TaskTile(
                      index: 3,
                      title: 'الكتابة والتركيب',
                      subtitle: 'أعد بناء الآيات عن طريق ترتيب الكلمات المبعثرة',
                      icon: Icons.edit_note_rounded,
                      isCompleted: level.isWriteCompleted,
                      onTap: () => _launchWriteTask(context, ref),
                    ),
                    TaskTile(
                      index: 4,
                      title: 'الحفظ والتمكين',
                      subtitle: 'اختبر ذاكرتك بإخفاء الكلمات المظللة وتثبيتها',
                      icon: Icons.psychology_rounded,
                      isCompleted: level.isMemorizeCompleted,
                      onTap: () => _launchMemorizeTask(context, ref),
                    ),
                    TaskTile(
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

  void _launchListenTask(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => InteractiveListenDialog(
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
      builder: (context) => InteractiveReadDialog(
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
      builder: (context) => InteractiveWriteDialog(
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
      builder: (context) => InteractiveMemorizeDialog(
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
      builder: (context) => InteractiveQuizDialog(
        level: level,
        onComplete: (combo) {
          ref.read(gamificationControllerProvider.notifier).completeSubTask(level.id, 'quiz', quizCombo: combo);
        },
      ),
    );
  }
}
