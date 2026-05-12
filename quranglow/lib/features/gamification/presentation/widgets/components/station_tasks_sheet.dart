import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/providers/app_providers.dart';
import 'package:quranglow/features/gamification/application/providers/gamification_providers.dart';
import 'package:quranglow/features/gamification/domain/models/gamification_models.dart';
import 'package:quranglow/features/gamification/presentation/theme/gamification_colors.dart';
import 'package:quranglow/features/gamification/presentation/widgets/components/task_tile.dart';
import 'package:quranglow/features/gamification/presentation/widgets/dialogs/memorize_dialog.dart';
import 'package:quranglow/features/gamification/presentation/widgets/dialogs/quiz_dialog.dart';
import 'package:quranglow/features/gamification/presentation/widgets/components/heart_timer_display.dart';
import 'package:quranglow/features/gamification/presentation/widgets/dialogs/read_dialog.dart';

import 'package:quranglow/features/gamification/presentation/pages/gameplay/level_gameplay_screen.dart';
import 'package:quranglow/features/gamification/presentation/pages/gameplay/write_gameplay_screen.dart';
import 'package:quranglow/features/gamification/presentation/pages/gameplay/voice_gameplay_screen.dart';

import 'package:quranglow/core/di/providers.dart'; // For alQuranProvider & settings

class StationTasksSheet extends ConsumerStatefulWidget {
  const StationTasksSheet({required this.level, super.key});

  final GameLevel level;

  @override
  ConsumerState<StationTasksSheet> createState() => _StationTasksSheetState();
}

class _StationTasksSheetState extends ConsumerState<StationTasksSheet> {
  @override
  void initState() {
    super.initState();
    // 🚀 INTELLIGENT PRE-CACHING: Fires instantly in background when the user expands the sheet!
    // By the time they click "Listening" or "Reading", the data will already be cached and load instantly.
    Future.microtask(() => _prefetchData());
  }

  Future<void> _prefetchData() async {
    try {
      final level = widget.level;

      // 1. Prefetch textual data for Reading and Quiz tasks (shared cached endpoint)
      ref
          .read(quranApiServiceProvider)
          .getAyahRange(level.surahId, level.ayahStart, level.ayahEnd);

      // 2. Prefetch Audio metadata for the Listening task pipeline
      final settings = ref.read(settingsControllerProvider);
      final reciterId = settings.preferredReciterId.isNotEmpty
          ? settings.preferredReciterId
          : 'ar.alafasy';

      ref.read(alQuranProvider).getSurahAudio(reciterId, level.surahId);
    } catch (_) {
      // Background prefetch is completely safe to ignore errors silently
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(gamificationControllerProvider);

    // Derive the current live level object from global state to ensure real-time reactivity!
    final liveLevel =
        asyncState.valueOrNull?.levels.firstWhere(
          (l) => l.id == widget.level.id,
          orElse: () => widget.level,
        ) ??
        widget.level;

    return DraggableScrollableSheet(
      initialChildSize: 0.8,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        final cs = Theme.of(context).colorScheme;

        return Container(
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
            border: Border(
              top: BorderSide(color: cs.outlineVariant.withValues(alpha: 0.3)),
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
                    color: cs.outlineVariant.withValues(alpha: 0.5),
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
                      child: const Icon(
                        Icons.auto_stories,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                liveLevel.surahName,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                ),
                              ),
                              // Dynamic Heart Status indicator requested by User!
                              _buildHeartsRow(ref),
                            ],
                          ),
                          Text(
                            'المستوى الحالي • آيات ${liveLevel.ayahStart}-${liveLevel.ayahEnd}',
                            style: TextStyle(
                              fontSize: 13,
                              color: cs.onSurfaceVariant.withValues(alpha: 0.8),
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
                    if (liveLevel.isCompleted &&
                        liveLevel.masteryLevel == 0) ...[
                      GestureDetector(
                        onTap: () async {
                          final ok = await ref
                              .read(gamificationControllerProvider.notifier)
                              .activateLevelMastery(liveLevel.id);
                          if (context.mounted && ok) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'تهانينا! تم تفعيل مستوى التاج الذهبي للتحدي المضاعف! 👑🏆',
                                ),
                                backgroundColor: GameificationColors.goldAccent,
                              ),
                            );
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Colors.orange, Colors.amber],
                            ),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.workspace_premium_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
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
                      ).animate().scale(
                        begin: const Offset(1, 1),
                        end: const Offset(1.05, 1.05),
                      ),
                      const SizedBox(height: 16),
                    ],

                    Text(
                      'أكمل المهام الخمس لتثبيت المستوى وحصد النجوم والجوائز الكبرى:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    TaskTile(
                      index: 1,
                      title: 'الاستماع والترتيل',
                      subtitle: 'استمع بخشوع لآيات المستوى',
                      icon: Icons.headphones_rounded,
                      isCompleted: liveLevel.isListenCompleted,
                      onTap: () => _launchListenTask(context, ref, liveLevel),
                    ),
                    TaskTile(
                      index: 2,
                      title: 'القراءة والتحسين',
                      subtitle: 'اقرأ الآيات بتركيز مع الترجمة والتفسير',
                      icon: Icons.menu_book_rounded,
                      isCompleted: liveLevel.isReadCompleted,
                      onTap: () => _launchReadTask(context, ref, liveLevel),
                    ),
                    TaskTile(
                      index: 3,
                      title: 'الكتابة والتركيب',
                      subtitle:
                          'أعد بناء الآيات عن طريق ترتيب الكلمات المبعثرة',
                      icon: Icons.edit_note_rounded,
                      isCompleted: liveLevel.isWriteCompleted,
                      onTap: () => _launchWriteTask(context, ref, liveLevel),
                    ),
                    TaskTile(
                      index: 4,
                      title: 'الحفظ والتمكين',
                      subtitle: 'اختبر ذاكرتك بإخفاء الكلمات المظللة وتثبيتها',
                      icon: Icons.psychology_rounded,
                      isCompleted: liveLevel.isMemorizeCompleted,
                      onTap: () => _launchMemorizeTask(context, ref, liveLevel),
                    ),
                    TaskTile(
                      index: 5,
                      title: 'القراءة الصوتية',
                      subtitle: 'اقرأ الآيات بصوتك وتأكد من النطق السليم',
                      icon: Icons.mic_rounded,
                      isCompleted: liveLevel.isQuizCompleted,
                      onTap: () => _launchQuizTask(context, ref, liveLevel),
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

  // Updated helpers to explicitly accept GameLevel to avoid capturing stale widget instance fields
  void _launchListenTask(
    BuildContext context,
    WidgetRef ref,
    GameLevel liveLevel,
  ) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LevelGameplayScreen(level: liveLevel)),
    );
  }

  void _launchReadTask(
    BuildContext context,
    WidgetRef ref,
    GameLevel liveLevel,
  ) {
    showDialog(
      context: context,
      builder: (context) => InteractiveReadDialog(
        level: liveLevel,
        onComplete: () {
          ref
              .read(gamificationControllerProvider.notifier)
              .completeSubTask(liveLevel.id, 'read');
        },
      ),
    );
  }

  void _launchWriteTask(
    BuildContext context,
    WidgetRef ref,
    GameLevel liveLevel,
  ) {
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => WriteGameplayScreen(level: liveLevel)),
    );
  }

  void _launchMemorizeTask(
    BuildContext context,
    WidgetRef ref,
    GameLevel liveLevel,
  ) {
    showDialog(
      context: context,
      builder: (context) => InteractiveMemorizeDialog(
        level: liveLevel,
        onComplete: () {
          ref
              .read(gamificationControllerProvider.notifier)
              .completeSubTask(liveLevel.id, 'memorize');
        },
      ),
    );
  }

  void _launchQuizTask(
    BuildContext context,
    WidgetRef ref,
    GameLevel liveLevel,
  ) {
    Navigator.pop(context); // Close sheet
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VoiceGameplayScreen(level: liveLevel),
      ),
    );
  }

  Widget _buildHeartsRow(WidgetRef ref) {
    final asyncState = ref.watch(gamificationControllerProvider);
    final profile = asyncState.valueOrNull?.userProfile;
    
    if (profile == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.red.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.red.withValues(alpha: 0.1)),
      ),
      child: HeartTimerDisplay(
        profile: profile,
        fontSize: 13,
      ),
    );
  }
}
