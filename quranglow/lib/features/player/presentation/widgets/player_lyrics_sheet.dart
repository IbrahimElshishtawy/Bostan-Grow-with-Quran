import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/di/providers.dart';
import 'package:quranglow/core/model/book/surah.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class PlayerLyricsSheet extends ConsumerStatefulWidget {
  const PlayerLyricsSheet({super.key});

  @override
  ConsumerState<PlayerLyricsSheet> createState() => _PlayerLyricsSheetState();
}

class _PlayerLyricsSheetState extends ConsumerState<PlayerLyricsSheet> {
  final ItemScrollController _scrollController = ItemScrollController();
  Surah? _surah;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSurahText();
  }

  Future<void> _loadSurahText() async {
    try {
      final chapter = ref.read(chapterProvider);
      final service = ref.read(quranServiceProvider);
      // Fetch Uthmani text for display
      final surah = await service.getSurahText('quran-uthmani', chapter);
      if (mounted) {
        setState(() {
          _surah = surah;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToCurrent(int index) {
    if (_scrollController.isAttached && index >= 0 && _surah != null && index < _surah!.ayat.length) {
      _scrollController.scrollTo(
        index: index,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
        alignment: 0.3, // Keep the active item near the upper middle
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(playerControllerProvider).valueOrNull;
    final currentIndex = state?.currentAyah ?? 0;

    // Auto-scroll when index changes
    ref.listen(playerControllerProvider, (prev, next) {
      final newIndex = next.valueOrNull?.currentAyah ?? 0;
      final oldIndex = prev?.valueOrNull?.currentAyah ?? -1;
      if (newIndex != oldIndex) {
        _scrollToCurrent(newIndex);
      }
    });

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Color(0xFF1E3C40), // Deep Spotify-like background
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'الكلمات',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.tealAccent))
                : _surah == null
                    ? const Center(
                        child: Text(
                          'تعذر تحميل الكلمات',
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : ScrollablePositionedList.builder(
                        itemScrollController: _scrollController,
                        itemCount: _surah!.ayat.length,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                        itemBuilder: (context, index) {
                          final aya = _surah!.ayat[index];
                          final isActive = index == currentIndex;

                          return GestureDetector(
                            onTap: () {
                              ref.read(playerControllerProvider.notifier).seekToIndex(index);
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 400),
                              curve: Curves.easeOut,
                              margin: const EdgeInsets.only(bottom: 32),
                              child: Text(
                                '${aya.text} ﴿${aya.numberInSurah}﴾',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Uthman', 
                                  fontSize: isActive ? 28 : 22,
                                  height: 1.8,
                                  color: isActive ? Colors.white : Colors.white38,
                                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
