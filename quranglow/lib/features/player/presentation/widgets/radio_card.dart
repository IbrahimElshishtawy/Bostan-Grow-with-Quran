import 'package:flutter/material.dart';
import 'package:audio_service/audio_service.dart';
import 'package:quranglow/core/service/audio/audio_locator.dart';

class RadioCard extends StatelessWidget {
  const RadioCard({super.key});

  @override
  Widget build(BuildContext context) {
    if (!isAudioHandlerReady) return const SizedBox.shrink();

    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<MediaItem?>(
      stream: audioHandler.mediaItem,
      builder: (context, mediaSnapshot) {
        final activeMediaId = mediaSnapshot.data?.id;
        final isRadioActive = activeMediaId == 'https://stream.radiojar.com/8s5u5tpdtwzuv';

        return StreamBuilder<PlaybackState>(
          stream: audioHandler.playbackState,
          builder: (context, playbackSnapshot) {
            final playing = playbackSnapshot.data?.playing ?? false;
            final isCurrentlyPlayingRadio = playing && isRadioActive;
            
            return InkWell(
              onTap: () async {
                if (isCurrentlyPlayingRadio) {
                  await audioHandler.pause();
                } else {
                  await audioHandler.playUri(
                    Uri.parse('https://stream.radiojar.com/8s5u5tpdtwzuv'),
                    title: 'إذاعة القرآن الكريم',
                    artist: 'بث مباشر - القاهرة',
                  );
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      cs.primary.withValues(alpha: 0.8),
                      cs.tertiary.withValues(alpha: 0.6),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCurrentlyPlayingRadio ? Icons.pause_rounded : Icons.radio_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'إذاعة القرآن الكريم',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            isCurrentlyPlayingRadio ? 'جاري البث الآن...' : 'بث مباشر من القاهرة',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isCurrentlyPlayingRadio)
                      const Icon(
                        Icons.multitrack_audio_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
