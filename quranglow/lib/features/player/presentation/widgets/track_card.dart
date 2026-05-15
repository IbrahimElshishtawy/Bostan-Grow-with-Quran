import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/di/providers.dart';
import 'package:quranglow/features/player/presentation/providers/favorites_controller.dart';

import 'package:quranglow/features/player/presentation/widgets/embedded_player_lyrics.dart';

import 'package:quranglow/core/data/surah_names_ar.dart';
import 'package:quranglow/core/model/aya/aya.dart';
import 'package:quranglow/core/model/book/surah.dart';
import 'package:quranglow/features/player/presentation/widgets/reader_row.dart';

class TrackCard extends ConsumerWidget {
  const TrackCard({super.key, required this.state, required this.showLyrics});

  final PlayerUiState state;
  final bool showLyrics;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final surahLabel = state.surahName ?? 'سورة ${state.chapter}';
    final reciterLabel = state.reciterName ?? state.editionId;
    final isFav = ref
        .watch(favoritesControllerProvider.notifier)
        .isFavorite(state.editionId, state.chapter);
        
    final editions = ref.watch(audioEditionsProvider);
    final ch = ref.watch(chapterProvider).clamp(1, 114);
    final ed = ref.watch(editionIdProvider);
    final surahs = List<Surah>.generate(
      kSurahNamesAr.length,
      (i) => Surah(number: i + 1, name: kSurahNamesAr[i], ayat: const <Aya>[]),
      growable: false,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Rectangular Compact Artwork
        Center(
          child: SizedBox(
            width: MediaQuery.of(context).size.width * 1,
            child: AspectRatio(
              aspectRatio: 1.1, // Enlarged and taller rectangle
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: Theme.of(context).brightness == Brightness.dark
                        ? [
                            const Color(0xFF2C5364),
                            const Color(0xFF203A43),
                            const Color(0xFF0F2027),
                          ]
                        : [
                            cs.primaryContainer,
                            cs.secondaryContainer,
                            cs.surfaceVariant,
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
                            size: 80,
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
                  GestureDetector(
                    onTap: () {
                      showSelectionSheet(
                        context,
                        title: 'اختر السورة',
                        items: surahs
                            .map((s) => {
                                  'id': s.number,
                                  'name': s.name,
                                  'subtitle': 'سورة رقم ${s.number}',
                                })
                            .toList(),
                        selectedId: ch,
                        onSelected: (id) => ref
                            .read(playerControllerProvider.notifier)
                            .changeChapter(id as int),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            surahLabel,
                            style: TextStyle(
                              color: cs.onSurface,
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'Tajawal',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: cs.onSurface.withValues(alpha: 0.7),
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {
                      showSelectionSheet(
                        context,
                        title: 'اختر القارئ',
                        items: editions.maybeWhen(
                          data: (list) => list
                              .whereType<Map>()
                              .map((m) => {
                                    'id': (m['identifier'] ?? '').toString(),
                                    'name': (m['name'] ?? m['englishName'] ?? '')
                                        .toString(),
                                  })
                              .toList(),
                          orElse: () => [],
                        ),
                        selectedId: ed,
                        onSelected: (id) => ref
                            .read(playerControllerProvider.notifier)
                            .changeEdition(id as String),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            reciterLabel,
                            style: TextStyle(
                              color: cs.onSurface.withValues(alpha: 0.7),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Tajawal',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: cs.onSurface.withValues(alpha: 0.5),
                          size: 20,
                        ),
                      ],
                    ),
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
                color: isFav ? Colors.redAccent : cs.onSurface.withValues(alpha: 0.7),
                size: 32,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
