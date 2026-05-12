import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:quranglow/core/di/providers.dart';
import 'package:quranglow/core/model/aya/aya.dart';
import 'package:quranglow/core/model/book/surah.dart';
import 'package:quranglow/features/mushaf/presentation/pages/paged_mushaf.dart';
import 'package:quranglow/features/mushaf/presentation/widgets/ayah_actions_sheet.dart';
import 'package:quranglow/features/mushaf/presentation/widgets/mushaf_top_bar.dart';
import 'package:quranglow/features/mushaf/presentation/widgets/position_store.dart';
import 'package:quranglow/features/mushaf/presentation/widgets/selected_ayah_panel.dart';
import 'package:quranglow/features/tafsir/presentation/widgets/tafsir_args.dart';
import 'package:quranglow/features/ui/routes/app_routes.dart';

final surahProvider = FutureProvider.autoDispose
    .family<Surah, (int chapter, String editionId)>((ref, args) async {
      final service = ref.read(quranServiceProvider);
      return service.getSurahText(args.$2, args.$1);
    });

class MushafPage extends ConsumerStatefulWidget {
  const MushafPage({
    super.key,
    this.chapter = 1,
    this.editionId = 'quran-uthmani',
    this.initialAyah,
  });

  final int chapter;
  final String editionId;
  final int? initialAyah;

  @override
  ConsumerState<MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends ConsumerState<MushafPage> {
  bool _uiVisible = false;
  late int _chapter;
  int? _lastAyahNumber;
  bool _trackingSessionStarted = false;
  late final dynamic _trackingService;

  final _pos = PositionStore();
  final _ayahPreviewPlayer = AudioPlayer();
  final GlobalKey<PagedMushafState> _pagedMushafKey =
      GlobalKey<PagedMushafState>();

  @override
  void initState() {
    super.initState();
    _trackingService = ref.read(trackingServiceProvider);
    _chapter = widget.chapter.clamp(1, 114);
    _lastAyahNumber = widget.initialAyah;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);
      await WakelockPlus.enable();
      if (!mounted) return;
      await _trackingService.startSession();
      if (!mounted) return;
      _trackingSessionStarted = true;
    });
  }

  @override
  void dispose() {
    if (_trackingSessionStarted) {
      _trackingService.endSession();
    }
    _ayahPreviewPlayer.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    WakelockPlus.disable();
    super.dispose();
  }

  String _audioEditionId() {
    final settings = ref.read(settingsProvider);
    return settings.maybeWhen(
      data: (s) {
        final editionId = s.readerEditionId.trim();
        return editionId.isEmpty ? 'ar.alafasy' : editionId;
      },
      orElse: () => 'ar.alafasy',
    );
  }

  void _goPrev() {
    if (_chapter <= 1) return;
    setState(() {
      _chapter--;
      _lastAyahNumber = null;
    });
    _pagedMushafKey.currentState?.animateToPage(0);
  }

  void _goNext() {
    if (_chapter >= 114) return;
    setState(() {
      _chapter++;
      _lastAyahNumber = null;
    });
    _pagedMushafKey.currentState?.animateToPage(0);
  }

  Future<void> _saveCurrentPosition() async {
    final ayahIndex0 = (_lastAyahNumber ?? 1) - 1;
    await _pos.save(_chapter, ayahIndex0);
    // Force visual UI update of the ribbon marker immediately
    _pagedMushafKey.currentState?.forceRefreshBookmark(ayahIndex0);
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم حفظ موضع القراءة')));
  }

  void _openTafsirForAyah(int ayahNumber) {
    Navigator.pushNamed(
      context,
      AppRoutes.tafsirReader,
      arguments: TafsirArgs(chapter: _chapter, ayah: ayahNumber),
    );
  }

  void _copyAyahText(int ayahNumber, String ayahText) {
    final content = '$_chapter:$ayahNumber\n$ayahText';
    Clipboard.setData(ClipboardData(text: content));
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم نسخ الآية')));
  }

  Future<void> _playAyahAudio(Aya aya, int ayahNumber) async {
    if (_ayahPreviewPlayer.playing) {
      await _ayahPreviewPlayer.stop();
      return;
    }
    try {
      String? url = aya.audioUrl;
      if (url == null || url.trim().isEmpty) {
        final service = ref.read(quranServiceProvider);
        final audioMap = await service.getSurahAudioUrlMap(
          _audioEditionId(),
          _chapter,
        );
        url = audioMap[ayahNumber];

        if (url == null || url.trim().isEmpty) {
          final urls = await service.getSurahAudioUrls(
            _audioEditionId(),
            _chapter,
          );
          final idx = ayahNumber - 1;
          if (idx >= 0 && idx < urls.length) {
            url = urls[idx];
          }
        }
      }

      if (url == null || url.trim().isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يوجد ملف صوت متاح لهذه الآية')),
        );
        return;
      }

      await _ayahPreviewPlayer.setUrl(url);
      await _ayahPreviewPlayer.play();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('يتم تشغيل الآية $ayahNumber')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('تعذر تشغيل الآية: $e')));
    }
  }

  Future<void> _openAyahActions({
    required int ayahNumber,
    required List<Aya> ayat,
  }) async {
    setState(() {
      _lastAyahNumber = ayahNumber;
      _uiVisible = true;
    });

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AyahActionsSheet(
        ayat: ayat,
        initialAyahNumber: ayahNumber,
        onAyahChanged: (nextAyahNumber) {
          setState(() => _lastAyahNumber = nextAyahNumber);
        },
        onPlayAyah: _playAyahAudio,
        onOpenTafsir: (currentAyahNumber) {
          Navigator.pop(ctx);
          _openTafsirForAyah(currentAyahNumber);
        },
        onCopyAyah: _copyAyahText,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final asyncSurah = ref.watch(surahProvider((_chapter, widget.editionId)));
    final selectedAyahText = asyncSurah.maybeWhen(
      data: (surah) {
        final selected = _lastAyahNumber;
        if (selected == null) return null;
        final idx = selected - 1;
        if (idx < 0 || idx >= surah.ayat.length) return null;
        return surah.ayat[idx].text;
      },
      orElse: () => null,
    );



    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgGradient = isDark 
        ? const [Color(0xFF18140E), Color(0xFF0D0B08)] 
        : const [Color(0xFFFFFDF8), Color(0xFFFDF7E8)];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: bgGradient,
            ),
          ),
          child: Stack(
            children: [
              // 1. Subtle Subconscious Islamic Pattern Texture
              Positioned.fill(
                child: Opacity(
                  opacity: isDark ? 0.05 : 0.03, // Extremely subtle as requested
                  child: Image.asset(
                    'assets/images/islamic_pattern.png',
                    repeat: ImageRepeat.repeat,
                    width: 220, // Controlled scale for elegance
                    height: 220,
                    color: isDark ? Colors.white : const Color(0xFF8B6D3A),
                    colorBlendMode: BlendMode.modulate,
                  ),
                ),
              ),
              asyncSurah.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('تعذر تحميل السورة'),
                        const SizedBox(height: 8),
                        Text(
                          '$e',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: () => ref.refresh(
                            surahProvider((_chapter, widget.editionId)),
                          ),
                          child: const Text('إعادة المحاولة'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: (surah) => PagedMushaf(
                  key: _pagedMushafKey,
                  ayat: surah.ayat,
                  surahName: surah.name,
                  surahNumber: _chapter,
                  showBasmala: surah.name.trim() != 'التوبة',
                  initialSelectedAyah: _lastAyahNumber,
                  onAyahTap: (int ayahNumber, Aya aya) {
                    setState(() {
                      _lastAyahNumber = ayahNumber;
                      _uiVisible = true;
                    });
                    _trackingService.incAyat(1);
                  },
                  onAyahLongPress: (int ayahNumber, Aya aya) {
                    _openAyahActions(
                      ayahNumber: ayahNumber,
                      ayat: surah.ayat,
                    );
                  },
                  onVisiblePageChanged: (n) => _lastAyahNumber = n,
                  onBackgroundTap: () => setState(() => _uiVisible = !_uiVisible),
                ),
              ),

              MushafTopBar(
                visible: _uiVisible,
                asyncSurah: asyncSurah,
                chapter: _chapter,
                onBack: () => Navigator.pop(context),
                onPrev: _chapter > 1 ? _goPrev : null,
                onNext: _chapter < 114 ? _goNext : null,
                onSave: _saveCurrentPosition,
                onTafsir: () => _openTafsirForAyah(_lastAyahNumber ?? 1),
              ),
              StreamBuilder<bool>(
                stream: _ayahPreviewPlayer.playingStream,
                initialData: false,
                builder: (context, snapshot) {
                  final isPlaying = snapshot.data ?? false;
                  return SelectedAyahPanel(
                    visible: _lastAyahNumber != null && selectedAyahText != null,
                    ayahNumber: _lastAyahNumber,
                    ayahText: selectedAyahText,
                    isPlaying: isPlaying,
                    onClear: () {
                      _ayahPreviewPlayer.stop(); // Stop if user clears panel
                      setState(() => _lastAyahNumber = null);
                    },
                    onOpenTafsir: () => _openTafsirForAyah(_lastAyahNumber ?? 1),
                    onPlay: () {
                      final ayahNum = _lastAyahNumber;
                      final surah = asyncSurah.valueOrNull;
                      if (ayahNum == null || surah == null) return;
                      final idx = ayahNum - 1;
                      if (idx < 0 || idx >= surah.ayat.length) return;
                      _playAyahAudio(surah.ayat[idx], ayahNum);
                    },
                    onCopy: () {
                      final text = selectedAyahText;
                      final ayahNum = _lastAyahNumber;
                      if (text == null || ayahNum == null) return;
                      _copyAyahText(ayahNum, text);
                    },
                    onSave: _saveCurrentPosition,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
