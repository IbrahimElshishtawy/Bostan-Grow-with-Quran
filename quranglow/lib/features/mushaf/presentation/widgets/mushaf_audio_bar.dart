import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quranglow/features/player/presentation/widgets/CombinedPositionData.dart';

class MushafAudioBar extends StatelessWidget {
  const MushafAudioBar({
    super.key,
    required this.visible,
    required this.player,
    required this.surahName,
    required this.onClose,
  });

  final bool visible;
  final AudioPlayer player;
  final String surahName;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: AnimatedSlide(
          offset: visible ? Offset.zero : const Offset(0, 1.2),
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1B4D3E), const Color(0xFF112D25)]
                    : [const Color(0xFFE8F5E9), const Color(0xFFC8E6C9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        // Play/Pause button
                        StreamBuilder<PlayerState>(
                          stream: player.playerStateStream,
                          builder: (context, snapshot) {
                            final state = snapshot.data;
                            final playing = state?.playing ?? false;
                            final processing =
                                state?.processingState ?? ProcessingState.idle;

                            if (processing == ProcessingState.loading ||
                                processing == ProcessingState.buffering) {
                              return const SizedBox(
                                width: 44,
                                height: 44,
                                child: Padding(
                                  padding: EdgeInsets.all(10),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 3,
                                    color: Colors.amber,
                                  ),
                                ),
                              );
                            }

                            return IconButton(
                              icon: Icon(
                                playing
                                    ? Icons.pause_circle_filled_rounded
                                    : Icons.play_circle_filled_rounded,
                                size: 40,
                                color: isDark
                                    ? Colors.amber
                                    : const Color(0xFF2E7D32),
                              ),
                              onPressed: () {
                                if (playing) {
                                  player.pause();
                                } else {
                                  player.play();
                                }
                              },
                            );
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                surahName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                              StreamBuilder<int?>(
                                stream: player.currentIndexStream,
                                builder: (context, snapshot) {
                                  final idx = snapshot.data;
                                  return Text(
                                    idx != null
                                        ? 'الآية ${idx + 1}'
                                        : 'جاري التحميل...',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black54,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        // Close button
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: onClose,
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
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
                        final total = timeline.total;
                        final pos = timeline.position;

                        // If total is 0 (not loaded), fallback to ayah-based progress
                        final currentIndex = player.currentIndex ?? 0;
                        final totalVerses = player.sequence.length;

                        double sliderValue = pos.inMilliseconds.toDouble();
                        double sliderMax = total.inMilliseconds.toDouble();

                        bool useTimeMode = total.inMilliseconds > 0;

                        if (!useTimeMode) {
                          // Fallback to verse-based progress if durations aren't loaded
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
                                activeColor: isDark
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
                                        ? '${((sliderValue / sliderMax) * 100).toInt()}%'
                                        : 'الآية ${currentIndex + 1} / $totalVerses',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color:
                                          (isDark ? Colors.white : Colors.black)
                                              .withValues(alpha: 0.6),
                                    ),
                                  ),
                                  Text(
                                    formatDuration(total),
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
