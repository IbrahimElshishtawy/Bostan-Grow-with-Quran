import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/di/providers.dart';
import 'package:quranglow/features/player/presentation/providers/favorites_controller.dart';

import 'package:quranglow/features/player/presentation/widgets/embedded_player_lyrics.dart';

class TrackCard extends ConsumerWidget {
  const TrackCard({super.key, required this.state, required this.showLyrics});

  final PlayerUiState state;
  final bool showLyrics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final surahLabel = state.surahName ?? 'سورة ${state.chapter}';
    final reciterLabel = state.reciterName ?? state.editionId;
    final isFav = ref
        .watch(favoritesControllerProvider.notifier)
        .isFavorite(state.editionId, state.chapter);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rectangular Compact Artwork
        Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 1,
            child: AspectRatio(
              aspectRatio: 1.6, // Wider and shorter as requested
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF2C5364),
                      Color(0xFF203A43),
                      Color(0xFF0F2027),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: showLyrics 
                      ? const EmbeddedPlayerLyrics()
                      : const Center(
                          child: Icon(
                            Icons.graphic_eq_rounded,
                            size: 50,
                            color: Colors.white24,
                          ),
                        ),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
        // Title and Artist
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surahLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Tajawal',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    reciterLabel,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Tajawal',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => ref
                  .read(favoritesControllerProvider.notifier)
                  .toggleFavorite(
                    editionId: state.editionId,
                    chapter: state.chapter,
                    surahName: surahLabel,
                    reciterName: reciterLabel,
                  ),
              icon: Icon(
                isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: isFav ? Colors.redAccent : Colors.white70,
                size: 32,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
