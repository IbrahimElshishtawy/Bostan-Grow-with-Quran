// ignore_for_file: library_private_types_in_public_api

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import 'package:quranglow/core/model/aya/aya.dart';

import 'package:quranglow/features/mushaf/presentation/widgets/page_indicator.dart';
import 'package:quranglow/features/mushaf/presentation/widgets/page_rich_block.dart';
import 'package:quranglow/features/mushaf/presentation/widgets/position_store.dart';
import 'package:quranglow/features/mushaf/presentation/widgets/saved_position_banner.dart';

class PagedMushaf extends StatefulWidget {
  const PagedMushaf({
    super.key,
    required this.ayat,
    required this.surahName,
    required this.surahNumber,
    this.showBasmala = false,
    this.basmalaText = '﷽',
    this.initialSelectedAyah,
    required this.onAyahTap,
    required this.onAyahLongPress,
    this.ayahNumberColor,
  });

  final List<Aya> ayat;
  final String surahName;
  final int surahNumber;
  final bool showBasmala;
  final String basmalaText;
  final int? initialSelectedAyah;
  final void Function(int ayahNumber, Aya aya) onAyahTap;
  final void Function(int ayahNumber, Aya aya) onAyahLongPress;
  final Color? ayahNumberColor;

  @override
  State<PagedMushaf> createState() => PagedMushafState();
}

class PagedMushafState extends State<PagedMushaf> with WidgetsBindingObserver {
  final _pos = PositionStore();
  final _controller = PageController(keepPage: true);

  int? _currentAyahIdx0;
  late final List<PageRange> _pages;
  bool _justSaved = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _pages = _buildPages(widget.ayat);
    _restoreInitial();
  }

  Future<void> _restoreInitial() async {
    int? idx0;
    if (widget.initialSelectedAyah != null) {
      final targetAyah = widget.initialSelectedAyah!;
      final found = widget.ayat.indexWhere((a) => a.numberInSurah == targetAyah);
      if (found != -1) {
        idx0 = found;
      } else {
        idx0 = (targetAyah - 1).clamp(0, widget.ayat.length - 1);
      }
    } else {
      final loaded = await _pos.load(widget.surahNumber);
      if (loaded is int) idx0 = loaded.clamp(0, widget.ayat.length - 1);
    }

    if (!mounted) return;
    if (idx0 != null) {
      setState(() => _currentAyahIdx0 = idx0);
      final p = _pageIndexForAyah(idx0);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _controller.jumpToPage(p);
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _saveCurrentIfAny();
    }
  }

  void _saveCurrentIfAny() {
    final i = _currentAyahIdx0;
    if (i != null) _pos.save(widget.surahNumber, i);
  }

  void _onAyahTap(int index0) async {
    setState(() => _currentAyahIdx0 = index0);
    await _pos.save(widget.surahNumber, index0);

    setState(() => _justSaved = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _justSaved = false);
    });

    if (index0 >= 0 && index0 < widget.ayat.length) {
      final aya = widget.ayat[index0];
      widget.onAyahTap(aya.numberInSurah, aya);
    }

    if (kDebugMode) {
      // ignore: avoid_print
      print('saved ${widget.surahNumber}:${widget.ayat[index0].numberInSurah}');
    }
  }

  void _onAyahLongPress(int index0) {
    if (index0 < 0 || index0 >= widget.ayat.length) return;
    setState(() => _currentAyahIdx0 = index0);
    final aya = widget.ayat[index0];
    widget.onAyahLongPress(aya.numberInSurah, aya);
  }

  void animateToPage(int page) {
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PageView.builder(
      controller: _controller,
      reverse: false,
      allowImplicitScrolling: true,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      itemCount: _pages.length,
      itemBuilder: (context, pageIndex) {
        final r = _pages[pageIndex];
        final cs = Theme.of(context).colorScheme;
        return Directionality(
          textDirection: TextDirection.rtl,
          child: SafeArea(
            child: Stack(
              children: [
                // 1. Ultimate Edge-to-Edge Content Area
                Positioned.fill(
                  child: Column(
                    children: [
                      // Dynamic Minimal Header Spacer for alignment
                      const SizedBox(height: 12),
                      
                      // 2. The Immersive Interactive Quran Text Block
                      Expanded(
                        child: PageRichBlock(
                          ayat: widget.ayat,
                          range: r,
                          showBasmala: widget.showBasmala && pageIndex == 0,
                          basmalaText: widget.basmalaText,
                          currentAyahIndex: _currentAyahIdx0,
                          onTapIndex: _onAyahTap,
                          onLongPressIndex: _onAyahLongPress,
                          ayahNumberColor: widget.ayahNumberColor ?? cs.primary,
                        ),
                      ),

                      // 3. Sleek, minimal Page Indicator floating at base
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: PageIndicator(
                          current: pageIndex + 1,
                          total: _pages.length,
                        ),
                      ),
                    ],
                  ),
                ),
                SavedPositionBanner(
                  visible: _justSaved,
                  text: _currentAyahIdx0 == null
                      ? ''
                      : 'تم حفظ موضعك: آية ${_toArabicDigits(widget.ayat[_currentAyahIdx0!].numberInSurah)} من ${widget.surahName}',
                ),
              ],
            ),
          ),
        );
      },
      onPageChanged: (newPageIndex) {
        _saveCurrentIfAny();
      },
    );
  }

  List<PageRange> _buildPages(List<Aya> ayat) {
    if (ayat.isEmpty) return const [PageRange(start: 0, end: 0)];
    final res = <PageRange>[];
    int start = 0;
    int currentPage = quran.getPageNumber(widget.surahNumber, 1);

    for (int i = 0; i < ayat.length; i++) {
      final page = quran.getPageNumber(widget.surahNumber, i + 1);
      if (page != currentPage) {
        res.add(PageRange(start: start, end: i));
        start = i;
        currentPage = page;
      }
    }

    if (res.isEmpty || res.last.end != ayat.length) {
      res.add(PageRange(start: start, end: ayat.length));
    }
    return res;
  }

  int _pageIndexForAyah(int idx0) {
    for (int p = 0; p < _pages.length; p++) {
      if (_pages[p].contains(idx0)) return p;
    }
    return 0;
  }

  String _toArabicDigits(int number) {
    const western = ['0', '1', '2', '3', '4', '5', '6', '7', '8', '9'];
    const eastern = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    final s = number.toString();
    final buf = StringBuffer();
    for (final ch in s.split('')) {
      final i = western.indexOf(ch);
      buf.write(i == -1 ? ch : eastern[i]);
    }
    return buf.toString();
  }
}

