// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/data/surah_names_ar.dart';
import 'package:quranglow/core/di/providers.dart';
import 'package:quranglow/core/model/aya/aya.dart';
import 'package:quranglow/core/model/book/surah.dart';
import 'package:quranglow/core/model/setting/reader_settings.dart';
import 'package:quranglow/core/service/audio/audio_locator.dart';
import 'package:quranglow/features/downloads/presentation/widgets/AyahPickerSheet.dart';
import 'package:quranglow/features/player/presentation/widgets/reader_row.dart';
import 'package:quranglow/features/player/presentation/widgets/track_card.dart';
import 'package:quranglow/features/player/presentation/widgets/transport_controls.dart';
import 'package:quranglow/features/player/presentation/pages/favorites_page.dart';
import 'package:quranglow/features/ui/routes/app_routes.dart';
import 'package:quranglow/core/widgets/shimmer_loading.dart';

class PlayerPage extends ConsumerStatefulWidget {
  const PlayerPage({super.key});

  @override
  ConsumerState<PlayerPage> createState() => _PlayerPageState();
}

class _PlayerPageState extends ConsumerState<PlayerPage> {
  ProviderSubscription<AsyncValue<PlayerUiState>>? _playbackSub;
  DateTime? _listeningStartedAt;
  bool _trackingSessionStarted = false;
  late final dynamic _trackingService;
  String? _forwardedUrl;
  bool _wasPlaying = false;

  @override
  void initState() {
    super.initState();
    _trackingService = ref.read(trackingServiceProvider);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _trackingService.startSession();
      if (!mounted) return;
      _trackingSessionStarted = true;
    });

    _playbackSub = ref.listenManual<AsyncValue<PlayerUiState>>(
      playerControllerProvider,
      (prev, next) async {
        if (!mounted || !isAudioHandlerReady) return;

        final state = next.valueOrNull;
        if (state == null) {
          if (next.hasError) {
            await audioHandler.stop();
          }
          return;
        }

        final isPlaying = state.isPlaying ?? false;
        final url = state.currentUrl;
        final title =
            (state.surahName ?? 'سورة') +
            (state.reciterName != null ? ' - ${state.reciterName}' : '');

        _trackListeningState(isPlaying);

        if (isPlaying && url != null && url.isNotEmpty) {
          final shouldReload = _forwardedUrl != url;
          if (shouldReload) {
            _forwardedUrl = url;
            await audioHandler.playUri(Uri.parse(url), title: title);
          } else if (!_wasPlaying) {
            await audioHandler.play();
          }
        } else if (!isPlaying) {
          _forwardedUrl = url;
          await audioHandler.pause();
        }

        _wasPlaying = isPlaying;
      },
      fireImmediately: false,
    );
  }

  @override
  void dispose() {
    _flushListeningTime();
    if (_trackingSessionStarted) {
      _trackingService.endSession();
    }
    _playbackSub?.close();
    super.dispose();
  }

  void _trackListeningState(bool isPlaying) {
    if (isPlaying) {
      _listeningStartedAt ??= DateTime.now();
      return;
    }
    _flushListeningTime();
  }

  void _flushListeningTime() {
    if (!mounted) return;
    final startedAt = _listeningStartedAt;
    if (startedAt == null) return;
    final seconds = DateTime.now().difference(startedAt).inSeconds;
    _listeningStartedAt = null;
    if (seconds > 0) {
      _trackingService.addListeningTime(seconds);
    }
  }

  Future<void> _downloadCurrent(BuildContext context, WidgetRef ref) async {
    final cs = Theme.of(context).colorScheme;
    final editionId = ref.read(editionIdProvider);
    final chapter = ref.read(chapterProvider).clamp(1, 114);
    final settings = ref.read(settingsProvider).whenOrNull(data: (s) => s);

    if (settings?.audioDownloadMode == AudioDownloadMode.selectedAyat) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        builder: (ctx) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: AyahPickerSheet(reciterId: editionId, surah: chapter),
          );
        },
      );
      return;
    }

    final service = ref.read(quranServiceProvider);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final urls = await service.getSurahAudioUrls(editionId, chapter);
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      if (urls.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('لا توجد روابط صوت متاحة لهذه السورة.'),
            backgroundColor: cs.error,
          ),
        );
        return;
      }
      if (!context.mounted) return;
      Navigator.pushNamed(
        context,
        AppRoutes.downloadDetail,
        arguments: {'surah': chapter, 'reciterId': editionId},
      );
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تعذر بدء التنزيل: $e'),
          backgroundColor: cs.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = ref.watch(playerControllerProvider);
    final ed = ref.watch(editionIdProvider);
    final ch = ref.watch(chapterProvider).clamp(1, 114);
    final editions = ref.watch(audioEditionsProvider);

    final surahs = AsyncValue.data(
      List<Surah>.generate(
        kSurahNamesAr.length,
        (i) => Surah(number: i + 1, name: kSurahNamesAr[i], ayat: const <Aya>[]),
        growable: false,
      ),
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: const SizedBox.shrink(), // Removed down arrow
          title: const Text(
            'قيد التشغيل الآن',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.favorite_rounded, color: Colors.redAccent),
              tooltip: 'المفضلات',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FavoritesPage()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.library_music_rounded, color: Colors.white),
              onPressed: () => Navigator.pushNamed(context, AppRoutes.downloadsLibrary),
            ),
            IconButton(
              icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
              onPressed: () => _downloadCurrent(context, ref),
            ),
          ],
        ),
        extendBodyBehindAppBar: true,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF1E3C40), // Deep Teal/Spotify-esque top color
                Color(0xFF121212), // Pure dark bottom
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Column(
                children: [
                  // Sleek Reader Selector
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: ReaderRow(
                      editions: editions,
                      surahs: surahs,
                      selectedEditionId: ed,
                      selectedSurah: ch,
                      onEditionChanged: (v) => ref
                          .read(playerControllerProvider.notifier)
                          .changeEdition(v),
                      onChapterChanged: (v) => ref
                          .read(playerControllerProvider.notifier)
                          .changeChapter(v),
                    ),
                  ),
                  const SizedBox(height: 32),
                  
                  // Main Player Content
                  Expanded(
                    child: ctrl.when(
                      loading: () => const PlayerSkeleton(),
                      error: (e, st) => Center(
                        child: Text(
                          'تعذر التحميل: $e',
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                      data: (s) => SingleChildScrollView(
                        child: Column(
                          children: [
                            TrackCard(state: s),
                            const SizedBox(height: 24),
                            TransportControls(state: s),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
