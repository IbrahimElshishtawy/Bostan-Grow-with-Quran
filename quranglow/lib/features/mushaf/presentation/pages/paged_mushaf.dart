// ignore_for_file: library_private_types_in_public_api


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
    this.onVisiblePageChanged,
    this.onBackgroundTap,
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
  final void Function(int pageFirstAyahNumber)? onVisiblePageChanged;
  final VoidCallback? onBackgroundTap;
  final Color? ayahNumberColor;

  @override
  State<PagedMushaf> createState() => PagedMushafState();
}

class PagedMushafState extends State<PagedMushaf> with WidgetsBindingObserver {
  final _pos = PositionStore();
  final _controller = PageController(keepPage: true);

  int? _currentAyahIdx0;
  int? _savedAyahIndex;
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
    // Load the permanently saved position for this surah
    final loaded = await _pos.load(widget.surahNumber);
    if (!mounted) return;
    
    setState(() {
      _savedAyahIndex = loaded;
    });

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
    // Auto-saving explicitly disabled by user request to only save manually.
  }

  void _onAyahTap(int index0) {
    setState(() {
      _currentAyahIdx0 = index0;
    });

    if (index0 >= 0 && index0 < widget.ayat.length) {
      final aya = widget.ayat[index0];
      widget.onAyahTap(aya.numberInSurah, aya);
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

  /// Allows externally triggering a UI refresh for the bookmark ribbon!
  void forceRefreshBookmark(int? index) {
    setState(() {
      _savedAyahIndex = index;
      _justSaved = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _justSaved = false);
    });
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
                          onBackgroundTap: widget.onBackgroundTap, // Direct pass down
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
                // 4. Ultimate High-End Physical Floating Bookmark Ribbon!
                if (_savedAyahIndex != null && r.contains(_savedAyahIndex!))
                  Positioned(
                    top: 0,
                    right: 30,
                    child: TweenAnimationBuilder<double>(
                      duration: const Duration(milliseconds: 600),
                      tween: Tween(begin: -60.0, end: 0.0),
                      curve: Curves.elasticOut,
                      builder: (context, value, child) {
                        return Transform.translate(
                          offset: Offset(0, value),
                          child: child,
                        );
                      },
                      child: Container(
                        height: 65,
                        width: 32,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0xFF8DA740),
                              Color(0xFF627A25),
                            ],
                          ),
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(8),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Icon(
                                Icons.bookmark_added_rounded,
                                size: 18,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
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
        if (newPageIndex >= 0 && newPageIndex < _pages.length) {
          final range = _pages[newPageIndex];
          if (range.start >= 0 && range.start < widget.ayat.length) {
            final firstAyahNum = widget.ayat[range.start].numberInSurah;
            // Dynamically notify the host page what ayah is currently viewed
            widget.onVisiblePageChanged?.call(firstAyahNum);
          }
        }
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

