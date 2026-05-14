import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/di/providers.dart';
import 'package:quranglow/core/model/book/Play_list_State.dart';
import 'package:quranglow/features/player/presentation/widgets/position_bar.dart';
import 'package:quranglow/features/player/presentation/widgets/speed_menu.dart';

final playbackSpeedProvider = StateProvider<double>((_) => 1.0);

class TransportControls extends ConsumerWidget {
  const TransportControls({super.key, required this.state});

  final PlaylistState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final speed = ref.watch(playbackSpeedProvider);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ayah Indicator (Minimal)
        StreamBuilder<int?>(
          stream: state.indexStream,
          initialData: 0,
          builder: (_, indexSnap) {
            final currentAyah = (indexSnap.data ?? 0) + 1;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'الآية $currentAyah',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    'مجموع الآيات: ${state.total}',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        
        // Progress Slider
        PositionBar(
          timelineStream: state.timelineStream,
          onSeek: ref.read(playerControllerProvider.notifier).seekTo,
        ),
        const SizedBox(height: 24),
        
        // Main Transport Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Shuffle/Repeat Left side
            IconButton(
              onPressed: () => ref.read(playerControllerProvider.notifier).toggleLoop(),
              icon: const Icon(Icons.repeat_rounded),
              color: Colors.white70,
              iconSize: 26,
            ),
            
            // Core Controls
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => ref.read(playerControllerProvider.notifier).previous(),
                  icon: const Icon(Icons.skip_previous_rounded),
                  color: Colors.white,
                  iconSize: 42,
                ),
                const SizedBox(width: 16),
                StreamBuilder<bool>(
                  stream: state.playingStream,
                  initialData: false,
                  builder: (_, snap) {
                    final playing = snap.data ?? false;
                    return Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: () => playing
                            ? ref.read(playerControllerProvider.notifier).pause()
                            : ref.read(playerControllerProvider.notifier).play(),
                        icon: Icon(
                          playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        ),
                        color: Colors.black,
                        iconSize: 42,
                        padding: const EdgeInsets.all(16),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 16),
                IconButton(
                  onPressed: () => ref.read(playerControllerProvider.notifier).next(),
                  icon: const Icon(Icons.skip_next_rounded),
                  color: Colors.white,
                  iconSize: 42,
                ),
              ],
            ),
            
            // Speed Menu Right side
            SpeedMenu(
              currentSpeed: speed,
              onSelect: (v) {
                ref.read(playbackSpeedProvider.notifier).state = v;
                ref.read(playerControllerProvider.notifier).setSpeed(v);
              },
            ),
          ],
        ),
      ],
    );
  }
}
