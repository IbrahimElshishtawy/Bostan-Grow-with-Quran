// ignore_for_file: dangling_library_doc_comments

/// Premium Spotify-like Audio Player Screen
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.expand_more, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: () => _showPlaylistMenu(context),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white60, Colors.blueGrey],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Album Art with animated background
              Expanded(child: _buildAlbumArtSection()),

              // Player Controls Section
              _buildPlayerControlsSection(),

              // Playback Speed & Queue
              _buildPlaybackOptionsSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumArtSection() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Album art placeholder with glow
            Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.3),
                    blurRadius: 40,
                    spreadRadius: 20,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(280),
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
                      size: 120,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 48),

            // Title and Subtitle
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 16,
                color: Colors.white.withValues(alpha: 0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerControlsSection() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        children: [
          // Waveform Visualizer
          _buildWaveformVisualizer(),

          const SizedBox(height: 20),

          // Time and Progress
          _buildProgressBar(),

          const SizedBox(height: 28),

          // Main Controls
          _buildMainControls(),

          const SizedBox(height: 24),

          // Favorite and More buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: () => ref
                    .read(favoritesControllerProvider.notifier)
                    .toggleFavorite(
                      editionId: ref.read(editionIdProvider),
                      chapter: ref.read(chapterProvider),
                      surahName: title,
                      reciterName: subtitle,
                    ),
                icon: Icon(
                  ref.watch(favoritesControllerProvider).any((e) =>
                          e.editionId == ref.read(editionIdProvider) &&
                          e.chapter == ref.read(chapterProvider))
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: ref.watch(favoritesControllerProvider).any((e) =>
                          e.editionId == ref.read(editionIdProvider) &&
                          e.chapter == ref.read(chapterProvider))
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

  Widget _buildWaveformVisualizer() {
    return SizedBox(
      height: 60,
      child: CustomPaint(
        painter: WaveformPainter(),
        size: const Size(double.infinity, 60),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: 0.45,
            minHeight: 6,
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            valueColor: const AlwaysStoppedAnimation(Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '2:15',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              '5:00',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMainControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildControlButton(Icons.shuffle, Colors.white70, onPressed: () {}),
        _buildLargeControlButton(Icons.skip_previous),
        _buildLargeControlButton(Icons.play_arrow, isPlay: true),
        _buildLargeControlButton(Icons.skip_next),
        _buildControlButton(Icons.repeat, Colors.white70, onPressed: () {}),
      ],
    );
  }

  Widget _buildPlaybackOptionsSection() {
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
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildSpeedButton('0.75x'),
                _buildSpeedButton('1.0x', isSelected: true),
                _buildSpeedButton('1.25x'),
                _buildSpeedButton('1.5x'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Quality selector
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQualityButton('Low', Colors.grey),
                _buildQualityButton('Normal', Colors.orangeAccent, isSelected: true),
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

  Widget _buildLargeControlButton(IconData icon, {bool isPlay = false}) {
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
      child: IconButton(
        icon: Icon(
          icon,
          color: Colors.indigoAccent.shade700,
          size: isPlay ? 32 : 24,
        ),
        onPressed: () {},
      ),
    );
  }

  Widget _buildIconButton(IconData icon, Color color, {VoidCallback? onPressed}) {
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

  Widget _buildSpeedButton(String label, {bool isSelected = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.2),
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
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.7),
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

    for (int i = 0; i < numBars; i++) {
      final x =
          i * (barWidth + gap) +
          (size.width / 2 - numBars * (barWidth + gap) / 2);
      final height = 10 + (math.sin(i * 0.5) * 15);

      canvas.drawLine(
        Offset(x, centerY - height / 2),
        Offset(x, centerY + height / 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) => false;
}
