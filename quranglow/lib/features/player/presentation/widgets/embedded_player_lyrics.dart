import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/di/providers.dart';
import 'package:quranglow/core/model/book/surah.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class EmbeddedPlayerLyrics extends ConsumerStatefulWidget {
  const EmbeddedPlayerLyrics({super.key});

  @override
  ConsumerState<EmbeddedPlayerLyrics> createState() => _EmbeddedPlayerLyricsState();
}

class _EmbeddedPlayerLyricsState extends ConsumerState<EmbeddedPlayerLyrics> {
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

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Colors.tealAccent));
    }

    if (_surah == null) {
      return const Center(
        child: Text(
          'تعذر تحميل الكلمات',
          style: TextStyle(color: Colors.white54),
        ),
      );
    }

    return ScrollablePositionedList.builder(
      itemScrollController: _scrollController,
      itemCount: _surah!.ayat.length,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
            margin: const EdgeInsets.only(bottom: 24),
            child: Text(
              '${aya.text} ﴿${aya.numberInSurah}﴾',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Uthman', 
                fontSize: isActive ? 24 : 18,
                height: 1.8,
                color: isActive ? Colors.white : Colors.white38,
                fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        );
      },
    );
  }
}
