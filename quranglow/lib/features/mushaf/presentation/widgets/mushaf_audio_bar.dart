import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quranglow/core/di/providers.dart';
import 'package:quranglow/features/player/presentation/widgets/CombinedPositionData.dart';

class MushafAudioBar extends ConsumerWidget {
  const MushafAudioBar({
    super.key,
    required this.visible,
    required this.player,
    required this.surahName,
    required this.onClose,
    this.onPlay,
  });

  final bool visible;
  final AudioPlayer player;
  final String surahName;
  final VoidCallback onClose;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: AnimatedSlide(
          offset: visible ? Offset.zero : const Offset(0, 1.2),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors:
                    isDark
                        ? [const Color(0xFF1B4D3E), const Color(0xFF112D25)]
                        : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with Reciter & Surah
                    Row(
                      children: [
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : Colors.black)
                                .withValues(alpha: 0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.mic_none_rounded,
                            size: 16,
                            color: isDark ? Colors.amber : Colors.green[800],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                surahName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                              Text(
                                'جاري التشغيل...',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: (isDark ? Colors.white : Colors.black)
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                        StreamBuilder<PlayerState>(
                          stream: player.playerStateStream,
                          builder: (context, snapshot) {
                            final playerState = snapshot.data;
                            final processingState =
                                playerState?.processingState;
                            final playing = playerState?.playing;
                            if (processingState == ProcessingState.loading ||
                                processingState ==
                                    ProcessingState.buffering) {
                              return Container(
                                margin: const EdgeInsets.all(6.0),
                                width: 20.0,
                                height: 20.0,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              );
                            } else if (playing != true) {
                              return IconButton(
                                icon: const Icon(Icons.play_arrow_rounded),
                                iconSize: 24.0,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: onPlay ?? player.play,
                              );
                            } else if (processingState !=
                                ProcessingState.completed) {
                              return IconButton(
                                icon: const Icon(Icons.pause_rounded),
                                iconSize: 24.0,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: player.pause,
                              );
                            } else {
                              return IconButton(
                                icon: const Icon(Icons.replay_rounded),
                                iconSize: 24.0,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => player.seek(Duration.zero),
                              );
                            }
                          },
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: onClose,
                        ),
                        const SizedBox(width: 12),
                      ],
                    ),
                    const SizedBox(height: 2),
                    // Progress Slider - Representing the whole Surah
                    StreamBuilder<CombinedPositionData>(
                      stream: combinedPositionStream(player),
                      builder: (context, snap) {
                        final timeline =
                            snap.data ??
                            CombinedPositionData(
                              Duration.zero,
                              Duration.zero,
                              Duration.zero,
                            );
                        final total = timeline.duration;
                        final pos = timeline.position;

                        // Use the controller's pre-calculated total duration override if it's available and larger than what the player reports
                        final controller = ref.watch(playerControllerProvider.notifier);
                        final totalOverride = controller.totalDuration;
                        
                        final displayTotal = (totalOverride > total) ? totalOverride : total;
                        final useTimeMode = displayTotal.inMilliseconds > 0;

                        double sliderValue = pos.inMilliseconds.toDouble();
                        double sliderMax = displayTotal.inMilliseconds.toDouble();

                        final currentIndex = player.currentIndex ?? 0;
                        final totalVerses = player.sequence.length;

                        if (!useTimeMode) {
                          // Fallback to verse-based progress if durations aren't loaded at all
                          sliderValue = currentIndex.toDouble();
                          sliderMax = totalVerses.toDouble();
                        }

                        // Helper to format duration
                        String formatDuration(Duration d) {
                          if (d.isNegative) d = Duration.zero;
                          final minutes = d.inMinutes;
                          final seconds = d.inSeconds % 60;
                          return '$minutes:${seconds.toString().padLeft(2, '0')}';
                        }

                        return Column(
                          children: [
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3,
                                thumbShape: const RoundSliderThumbShape(
                                  enabledThumbRadius: 6,
                                ),
                                overlayShape: const RoundSliderOverlayShape(
                                  overlayRadius: 14,
                                ),
                              ),
                              child: Slider(
                                value: sliderValue.clamp(0.0, sliderMax),
                                max: sliderMax > 0 ? sliderMax : 1.0,
                                onChanged: (v) {
                                  if (useTimeMode) {
                                    player.seek(
                                      Duration(milliseconds: v.toInt()),
                                    );
                                  } else {
                                    player.seek(
                                      Duration.zero,
                                      index: v.toInt().clamp(
                                        0,
                                        totalVerses - 1,
                                      ),
                                    );
                                  }
                                },
                                activeColor:
                                    isDark
                                        ? Colors.amber
                                        : const Color(0xFF2E7D32),
                                inactiveColor:
                                    (isDark ? Colors.white : Colors.black)
                                        .withValues(alpha: 0.1),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    formatDuration(pos),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color:
                                          (isDark ? Colors.white : Colors.black)
                                              .withValues(alpha: 0.6),
                                    ),
                                  ),
                                  Text(
                                    useTimeMode
                                        ? '${((sliderValue / (sliderMax > 0 ? sliderMax : 1.0)) * 100).toInt()}%'
                                        : 'الآية ${currentIndex + 1} / $totalVerses',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color:
                                          (isDark ? Colors.white : Colors.black)
                                              .withValues(alpha: 0.6),
                                    ),
                                  ),
                                  Text(
                                    formatDuration(displayTotal),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color:
                                          (isDark ? Colors.white : Colors.black)
                                              .withValues(alpha: 0.6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
