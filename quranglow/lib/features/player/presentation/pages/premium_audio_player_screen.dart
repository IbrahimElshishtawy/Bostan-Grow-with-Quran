// ignore_for_file: dangling_library_doc_comments

/// Premium Spotify-like Audio Player Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/di/providers.dart';
import 'package:quranglow/features/player/presentation/providers/favorites_controller.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quranglow/features/player/presentation/widgets/CombinedPositionData.dart';
import 'dart:math' as math;

class PremiumAudioPlayerScreen extends ConsumerWidget {
  final String title;
  final String subtitle;
  final String duration;

  const PremiumAudioPlayerScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.duration,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playerState = ref.watch(playerControllerProvider);
    final controller = ref.read(playerControllerProvider.notifier);

    final uiState = playerState.value;
    final isLoading = playerState.isLoading;
    final hasError = playerState.hasError;
    final error = playerState.error;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.expand_more, size: 30),
          color: Colors.white,
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            color: Colors.white,
            onPressed: () => _showPlaylistMenu(context),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1E3C72),
              Color(0xFF2A5298),
            ], // Gorgeous deep premium blue gradient
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Premium thin loading indicator under AppBar
              if (isLoading)
                const LinearProgressIndicator(
                  color: Colors.amber,
                  backgroundColor: Colors.white12,
                  minHeight: 3,
                ),

              Expanded(
                child: () {
                  if (uiState != null) {
                    return Column(
                      children: [
                        // Album Art with animated background
                        Expanded(
                          child: _buildAlbumArtSection(uiState, isLoading),
                        ),

                        // Player Controls Section
                        _buildPlayerControlsSection(
                          ref,
                          uiState,
                          controller,
                          isLoading,
                        ),

                        // Playback Speed & Queue
                        _buildPlaybackOptionsSection(uiState, controller),
                      ],
                    );
                  } else if (isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(color: Colors.amber),
                    );
                  } else if (hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: Colors.amber,
                              size: 64,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'تعذر تحميل الملف الصوتي',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Tajawal',
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              error?.toString() ??
                                  'خطأ في الاتصال بالخادم الرئيسي',
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontFamily: 'Tajawal',
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: () {
                                final chapter = ref.read(chapterProvider);
                                controller.playSurah(chapter);
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                ),
                              ),
                              icon: const Icon(Icons.refresh_rounded),
                              label: const Text(
                                'إعادة المحاولة',
                                style: TextStyle(
                                  fontFamily: 'Tajawal',
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  } else {
                    return const SizedBox();
                  }
                }(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumArtSection(PlayerUiState state, bool isLoading) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Album art placeholder with glow
            Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withValues(
                      alpha: isLoading ? 0.15 : 0.3,
                    ),
                    blurRadius: 40,
                    spreadRadius: 20,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(260),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.amber.shade200, Colors.amber.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.music_note,
                      size: 100,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40),

            // Title and Subtitle
            Text(
              state.surahName ?? title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Tajawal',
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              state.reciterName ?? subtitle,
              style: TextStyle(
                fontSize: 16,
                fontFamily: 'Tajawal',
                color: Colors.white.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerControlsSection(
    WidgetRef ref,
    PlayerUiState state,
    PlayerController controller,
    bool isLoading,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        children: [
          // Waveform Visualizer
          _buildWaveformVisualizer(state),

          const SizedBox(height: 16),

          // Time and Progress
          _buildProgressBar(state, controller),

          const SizedBox(height: 20),

          // Main Controls
          _buildMainControls(state, controller, isLoading),

          const SizedBox(height: 20),

          // Favorite and More buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: () => ref
                    .read(favoritesControllerProvider.notifier)
                    .toggleFavorite(
                      editionId: state.editionId,
                      chapter: state.chapter,
                      surahName: state.surahName ?? title,
                      reciterName: state.reciterName ?? subtitle,
                    ),
                icon: Icon(
                  ref
                          .watch(favoritesControllerProvider)
                          .any(
                            (e) =>
                                e.editionId == state.editionId &&
                                e.chapter == state.chapter,
                          )
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color:
                      ref
                          .watch(favoritesControllerProvider)
                          .any(
                            (e) =>
                                e.editionId == state.editionId &&
                                e.chapter == state.chapter,
                          )
                      ? Colors.redAccent
                      : Colors.white70,
                  size: 28,
                ),
              ),
              _buildIconButton(Icons.share, Colors.white70, onPressed: () {}),
              _buildIconButton(Icons.list, Colors.white70, onPressed: () {}),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWaveformVisualizer(PlayerUiState state) {
    return StreamBuilder<bool>(
      stream: state.playingStream,
      builder: (context, snapshot) {
        final isPlaying = snapshot.data ?? false;
        return SizedBox(
          height: 60,
          child: CustomPaint(
            painter: WaveformPainter(isActive: isPlaying),
            size: const Size(double.infinity, 60),
          ),
        );
      },
    );
  }

  Widget _buildProgressBar(PlayerUiState state, PlayerController controller) {
    return StreamBuilder<CombinedPositionData>(
      stream: state.timelineStream,
      builder: (context, snapshot) {
        final posData = snapshot.data;
        final pos = posData?.position ?? Duration.zero;
        final total =
            posData?.duration ?? state.totalDurationOverride ?? Duration.zero;

        final value = (total.inMilliseconds > 0)
            ? pos.inMilliseconds / total.inMilliseconds
            : 0.0;

        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                activeTrackColor: Colors.white,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.2),
                thumbColor: Colors.white,
              ),
              child: Slider(
                value: value.clamp(0.0, 1.0),
                onChanged: (v) {
                  final target = Duration(
                    milliseconds: (v * total.inMilliseconds).toInt(),
                  );
                  controller.seekTo(target);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDuration(pos),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _formatDuration(total),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes;
    final seconds = d.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildMainControls(
    PlayerUiState state,
    PlayerController controller,
    bool isLoading,
  ) {
    return StreamBuilder<bool>(
      stream: state.playingStream,
      builder: (context, playingSnapshot) {
        final isPlaying = playingSnapshot.data ?? false;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            StreamBuilder<LoopMode>(
              stream: state.loopModeStream,
              builder: (context, loopSnapshot) {
                final isLoop =
                    (loopSnapshot.data ?? LoopMode.off) != LoopMode.off;
                return _buildControlButton(
                  isLoop ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                  isLoop ? Colors.amber : Colors.white70,
                  onPressed: () => controller.toggleLoop(),
                );
              },
            ),
            _buildLargeControlButton(
              Icons.skip_previous_rounded,
              onPressed: () => controller.previous(),
            ),
            // Play/Pause button with loading spinner overlay when buffering or loading new reciter/surah
            StreamBuilder<ProcessingState>(
              stream: state.processingStateStream,
              builder: (context, procSnapshot) {
                final procState = procSnapshot.data;
                final isBuffering =
                    procState == ProcessingState.loading ||
                    procState == ProcessingState.buffering ||
                    isLoading;

                return _buildLargeControlButton(
                  isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                  isPlay: true,
                  isLoading: isBuffering,
                  onPressed: () =>
                      isPlaying ? controller.pause() : controller.play(),
                );
              },
            ),
            _buildLargeControlButton(
              Icons.skip_next_rounded,
              onPressed: () => controller.next(),
            ),
            _buildControlButton(
              Icons.shuffle,
              Colors.white70,
              onPressed: () {},
            ),
          ],
        );
      },
    );
  }

  Widget _buildPlaybackOptionsSection(
    PlayerUiState state,
    PlayerController controller,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Speed selector
          StreamBuilder<double>(
            stream: state.volumeStream.map((_) => 1.0), // Mock for speed stream
            builder: (context, _) {
              // Note: Just using a static speed display for now,
              // as speedStream isn't explicitly in PlaylistState yet
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildSpeedButton(
                      '0.75x',
                      onPressed: () => controller.setSpeed(0.75),
                    ),
                    _buildSpeedButton(
                      '1.0x',
                      isSelected: true,
                      onPressed: () => controller.setSpeed(1.0),
                    ),
                    _buildSpeedButton(
                      '1.25x',
                      onPressed: () => controller.setSpeed(1.25),
                    ),
                    _buildSpeedButton(
                      '1.5x',
                      onPressed: () => controller.setSpeed(1.5),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          // Quality selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQualityButton('Low', Colors.grey),
                _buildQualityButton(
                  'Normal',
                  Colors.orangeAccent,
                  isSelected: true,
                ),
                _buildQualityButton('High', Colors.blue),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlButton(
    IconData icon,
    Color color, {
    VoidCallback? onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, color: color, size: 28),
      onPressed: onPressed,
    );
  }

  Widget _buildLargeControlButton(
    IconData icon, {
    bool isPlay = false,
    bool isLoading = false,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: isPlay ? 64 : 52,
      height: isPlay ? 64 : 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            spreadRadius: 2,
          ),
        ],
      ),
      child: isLoading
          ? Center(
              child: SizedBox(
                width: isPlay ? 28 : 20,
                height: isPlay ? 28 : 20,
                child: CircularProgressIndicator(
                  color: Colors.indigoAccent.shade700,
                  strokeWidth: 3,
                ),
              ),
            )
          : IconButton(
              icon: Icon(
                icon,
                color: Colors.indigoAccent.shade700,
                size: isPlay ? 32 : 24,
              ),
              onPressed: onPressed,
            ),
    );
  }

  Widget _buildIconButton(
    IconData icon,
    Color color, {
    VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.1),
      ),
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: onPressed ?? () {},
      ),
    );
  }

  Widget _buildSpeedButton(
    String label, {
    bool isSelected = false,
    VoidCallback? onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.black87 : Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildQualityButton(
    String label,
    Color color, {
    bool isSelected = false,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected
            ? color.withValues(alpha: 0.3)
            : Colors.white.withValues(alpha: 0.1),
        border: Border.all(
          color: color.withValues(alpha: 0.5),
          width: isSelected ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected
              ? Colors.white
              : Colors.white.withValues(alpha: 0.7),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  void _showPlaylistMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade900,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.download_rounded, color: Colors.white),
              title: const Text(
                'Download for offline',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.playlist_add, color: Colors.white),
              title: const Text(
                'Add to Playlist',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.share, color: Colors.white),
              title: const Text('Share', style: TextStyle(color: Colors.white)),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.info, color: Colors.white),
              title: const Text(
                'Details',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter for waveform visualization
class WaveformPainter extends CustomPainter {
  final bool isActive;
  WaveformPainter({this.isActive = false});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final centerY = size.height / 2;
    const barWidth = 4.0;
    const gap = 3.0;
    final numBars = ((size.width / (barWidth + gap)) - 1).toInt();

    final time = DateTime.now().millisecondsSinceEpoch / 500;

    for (int i = 0; i < numBars; i++) {
      final x =
          i * (barWidth + gap) +
          (size.width / 2 - numBars * (barWidth + gap) / 2);

      // Animate if active
      final height = isActive
          ? 10 + (math.sin(i * 0.5 + time * 5) * 15).abs()
          : 10 + (math.sin(i * 0.5) * 15).abs();

      canvas.drawLine(
        Offset(x, centerY - height / 2),
        Offset(x, centerY + height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) =>
      oldDelegate.isActive != isActive || isActive;
}
