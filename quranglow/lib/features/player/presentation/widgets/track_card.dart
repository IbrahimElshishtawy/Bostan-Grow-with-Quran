import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/di/providers.dart';
import 'package:quranglow/features/player/presentation/providers/favorites_controller.dart';

class TrackCard extends ConsumerWidget {
  const TrackCard({super.key, required this.state});

  final PlayerUiState state;

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
        // Massive Album Art
        AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
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
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.graphic_eq_rounded,
                size: 120,
                color: Colors.white24,
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
