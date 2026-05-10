import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/features/gamification/application/level_gameplay_controller.dart';
import 'package:quranglow/features/gamification/domain/models/gamification_models.dart';
import 'package:quranglow/features/gamification/application/providers/gamification_providers.dart';

class LevelGameplayScreen extends ConsumerWidget {
  final GameLevel level;

  const LevelGameplayScreen({
    super.key,
    required this.level,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(levelGameplayControllerProvider(level));
    final controller = ref.read(levelGameplayControllerProvider(level).notifier);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: const Color(0xFF0B1A13),
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                level.surahName,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
              ),
              Text(
                'آيات ${level.ayahStart} - ${level.ayahEnd}',
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.info_outline_rounded),
              onPressed: () {},
            ),
          ],
        ),
        body: state.isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFFBDE156)))
            : state.error != null
                ? Center(child: Text('خطأ: ${state.error}', style: const TextStyle(color: Colors.redAccent)))
                : Stack(
                    children: [
                      // Background Ambient Glow Layer
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment.topCenter,
                              radius: 1.2,
                              colors: [
                                const Color(0xFF153524),
                                const Color(0xFF0B1A13),
                              ],
                            ),
                          ),
                        ),
                      ),

                      Column(
                        children: [
                          // 1. Top Level Progress Header
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: _buildStatusBar(state),
                          ),

                          // 2. Scrolling Interactive Text View
                          Expanded(
                            child: ListView.separated(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              itemCount: state.ayahs.length,
                              separatorBuilder: (c, i) => const SizedBox(height: 16),
                              itemBuilder: (context, index) {
                                final ayah = state.ayahs[index];
                                final isActive = state.currentPlayingAyahIndex == index;

                                return GestureDetector(
                                  onTap: () => controller.seekToAyah(index),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: isActive
                                          ? const Color(0xFFBDE156).withValues(alpha: 0.15)
                                          : Colors.white.withValues(alpha: 0.03),
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color: isActive
                                            ? const Color(0xFFBDE156).withValues(alpha: 0.4)
                                            : Colors.white.withValues(alpha: 0.05),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              width: 28,
                                              height: 28,
                                              decoration: BoxDecoration(
                                                color: isActive ? const Color(0xFFBDE156) : Colors.white12,
                                                shape: BoxShape.circle,
                                              ),
                                              alignment: Alignment.center,
                                              child: Text(
                                                '${ayah.ayahNumber}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  color: isActive ? Colors.black : Colors.white70,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            if (isActive)
                                              const Text(
                                                'قيد الاستماع...',
                                                style: TextStyle(color: Color(0xFFBDE156), fontSize: 12, fontWeight: FontWeight.bold),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          ayah.text,
                                          style: TextStyle(
                                            fontSize: 26,
                                            height: 1.8,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Kitab', // Standard local font fallback
                                            color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.6),
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),

                          // 3. Premium Playback Footer Controls
                          _buildPlaybackControlBar(controller, state, ref, context),
                        ],
                      ),
                    ],
                  ),
      ),
    );
  }

  Widget _buildStatusBar(LevelGameplayState state) {
    final double progress = state.ayahs.isEmpty ? 0 : (state.currentPlayingAyahIndex + 1) / state.ayahs.length;
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('معدل استماع الآيات', style: TextStyle(color: Colors.white60, fontSize: 12)),
            Text(
              '${(progress * 100).toInt()}%',
              style: const TextStyle(color: Color(0xFFBDE156), fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 6,
            backgroundColor: Colors.white10,
            color: const Color(0xFFBDE156),
          ),
        ),
      ],
    );
  }

  Widget _buildPlaybackControlBar(LevelGameplayController controller, LevelGameplayState state, WidgetRef ref, BuildContext context) {
    
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 35),
      decoration: BoxDecoration(
        color: const Color(0xFF102419),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                iconSize: 32,
                icon: const Icon(Icons.skip_next_rounded, color: Colors.white70),
                onPressed: () => controller.seekToAyah(state.currentPlayingAyahIndex - 1),
              ),
              const SizedBox(width: 20),
              GestureDetector(
                onTap: controller.playPause,
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFBDE156), Color(0xFF9DBB48)],
                    ),
                    boxShadow: [
                      BoxShadow(color: Color(0x40BDE156), blurRadius: 15, spreadRadius: 5),
                    ],
                  ),
                  child: Icon(
                    state.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    size: 38,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(width: 20),
              IconButton(
                iconSize: 32,
                icon: const Icon(Icons.skip_previous_rounded, color: Colors.white70),
                onPressed: () => controller.seekToAyah(state.currentPlayingAyahIndex + 1),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // "Done" Button to finish mission
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.1),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                ),
              ),
              onPressed: () async {
                // Log subtask completion natively!
                await ref.read(gamificationControllerProvider.notifier).completeSubTask(level.id, 'listen');
                if (context.mounted) {
                  Navigator.pop(context); // Exit screen back to map
                }
              },
              child: const Text('تمت القراءة والإنصات بنجاح', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
