import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quranglow/core/data/surah_names_ar.dart';
import 'package:quranglow/core/di/core_providers.dart';
import 'package:quranglow/core/di/service_providers.dart';
import 'package:quranglow/core/model/book/Play_list_State.dart';
import 'package:quranglow/core/model/book/surah.dart';
import 'package:quranglow/features/player/presentation/widgets/CombinedPositionData.dart';

final audioEditionsProvider = FutureProvider<List<dynamic>>((ref) async {
  return ref.read(quranServiceProvider).listAudioEditions();
});

final editionIdProvider = StateProvider<String>((ref) => 'ar.alafasy');
final chapterProvider = StateProvider<int>((ref) => 1);

final surahTextProvider = FutureProvider.family<Surah, int>((ref, chapter) async {
  final service = ref.read(quranServiceProvider);
  return service.getSurahText('quran-uthmani', chapter);
});

final playerLyricsModeProvider = StateProvider<bool>((ref) => false);

class PlayerUiState extends PlaylistState {
  final Duration? totalDurationOverride;
  final bool? isPlaying;
  final String? currentUrl;
  final String? surahName;
  final String? reciterName;
  final int? currentAyah;

  const PlayerUiState({
    required super.editionId,
    required super.chapter,
    required super.total,
    required super.timelineStream,
    required super.durationStream,
    required super.positionStream,
    required super.bufferedStream,
    required super.indexStream,
    required super.playingStream,
    required super.loopModeStream,
    required super.volumeStream,
    required super.processingStateStream,

    this.totalDurationOverride,
    this.isPlaying,
    this.currentUrl,
    this.surahName,
    this.reciterName,
    this.currentAyah,
  });

  PlayerUiState copyWith({
    String? editionId,
    int? chapter,
    int? total,
    Stream<CombinedPositionData>? timelineStream,
    Stream<Duration?>? durationStream,
    Stream<Duration>? positionStream,
    Stream<Duration>? bufferedStream,
    Stream<int?>? indexStream,
    Stream<bool>? playingStream,
    Stream<LoopMode>? loopModeStream,
    Stream<double>? volumeStream,
    Stream<ProcessingState>? processingStateStream,
    Duration? totalDurationOverride,
    bool? isPlaying,
    String? currentUrl,
    String? surahName,
    String? reciterName,
    int? currentAyah,
  }) {
    return PlayerUiState(
      editionId: editionId ?? this.editionId,
      chapter: chapter ?? this.chapter,
      total: total ?? this.total,
      timelineStream: timelineStream ?? this.timelineStream,
      durationStream: durationStream ?? this.durationStream,
      positionStream: positionStream ?? this.positionStream,
      bufferedStream: bufferedStream ?? this.bufferedStream,
      indexStream: indexStream ?? this.indexStream,
      playingStream: playingStream ?? this.playingStream,
      loopModeStream: loopModeStream ?? this.loopModeStream,
      volumeStream: volumeStream ?? this.volumeStream,
      processingStateStream:
          processingStateStream ?? this.processingStateStream,
      totalDurationOverride:
          totalDurationOverride ?? this.totalDurationOverride,
      isPlaying: isPlaying ?? this.isPlaying,
      currentUrl: currentUrl ?? this.currentUrl,
      surahName: surahName ?? this.surahName,
      reciterName: reciterName ?? this.reciterName,
      currentAyah: currentAyah ?? this.currentAyah,
    );
  }
}

final playerControllerProvider =
    StateNotifierProvider<PlayerController, AsyncValue<PlayerUiState>>(
      (ref) => PlayerController(ref),
    );

class PlayerController extends StateNotifier<AsyncValue<PlayerUiState>> {
  PlayerController(this.ref) : super(const AsyncValue.loading()) {
    final handler = ref.read(audioHandlerProvider);
    _player = handler.player;
    _timelineStream = combinedPositionStream(_player).asBroadcastStream();

    // Auto-skip failed ayahs to prevent playback reset
    _player.playbackEventStream.listen(
      (_) {},
      onError: (error) {
        debugPrint('Playback error detected: $error. Skipping to next...');
        _player.seekToNext();
      },
    );

    // Track real-time ayah index changes for dynamic lyrics highlights in the player screen
    _posSub = _player.positionStream.listen((pos) {
      if (_disposed || !mounted) return;
      if (_ayahOffsets.isEmpty) return;

      int newAyahIndex = 0;
      for (int i = _ayahOffsets.length - 1; i >= 0; i--) {
        if (pos >= _ayahOffsets[i]) {
          newAyahIndex = i;
          break;
        }
      }

      final currentUi = state.value;
      if (currentUi == null || currentUi.currentAyah != newAyahIndex) {
        _emitState();
      }
    });

    _init();
  }

  final Ref ref;
  late final AudioPlayer _player;
  late final Stream<CombinedPositionData> _timelineStream;
  StreamSubscription<bool>? _playingSub;
  StreamSubscription<Duration>? _posSub;
  String _reciterName = '';
  List<String> _urls = [];
  List<Duration> _ayahOffsets = [];
  bool _disposed = false;
  int _currentRequestId = 0;

  static const _kReciterNames = {
    'ar.alafasy': 'مشاري العفاسي',
    'ar.abdurrahmaansudais': 'عبد الرحمن السديس',
    'ar.saoodshuraym': 'سعود الشريم',
    'ar.minshawi': 'محمد صديق المنشاوي',
    'ar.abdulbasitmurattal': 'عبد الباسط عبد الصمد',
    'ar.husary': 'محمود خليل الحصري',
    'ar.hudhaify': 'علي الحذيفي',
    'ar.ghamadi': 'سعد الغامدي',
    'ar.mahermuaiqly': 'ماهر المعيقلي',
  };

  Future<void> _init() async {
    if (_disposed || !mounted) return;
    final editionId = ref.read(editionIdProvider);
    final chapter = ref.read(chapterProvider).clamp(1, 114);
    await _loadSurah(editionId: editionId, chapter: chapter, autoPlay: false);
  }

  Future<void> _loadSurah({
    required String editionId,
    required int chapter,
    required bool autoPlay,
  }) async {
    final requestId = ++_currentRequestId;
    if (_disposed || !mounted) return;

    final nextSurahName = (chapter >= 1 && chapter <= kSurahNamesAr.length)
        ? kSurahNamesAr[chapter - 1]
        : 'سورة $chapter';
    final nextReciter = _kReciterNames[editionId] ?? editionId;

    if (state.hasValue) {
      state = AsyncValue.data(
        state.value!.copyWith(
          chapter: chapter,
          editionId: editionId,
          surahName: nextSurahName,
          reciterName: nextReciter,
        ),
      );
    } else {
      state = const AsyncValue.loading();
    }

    try {
      final service = ref.read(quranServiceProvider);

      final urls = await service.getSurahAudioUrls(editionId, chapter);
      if (requestId != _currentRequestId || _disposed || !mounted) return;
      if (urls.isEmpty) {
        throw Exception('لا توجد روابط صوتية متاحة');
      }

      _urls = urls;
      _reciterName =
          _kReciterNames[editionId] ?? await _resolveReciterName(editionId);
      if (requestId != _currentRequestId || _disposed || !mounted) return;

      final handler = ref.read(audioHandlerProvider);
      handler.mediaItem.add(
        MediaItem(
          id: 'surah_$chapter',
          title: nextSurahName,
          artist: _reciterName,
          album: 'القرآن الكريم',
        ),
      );

      try {
        final surahData = await service.getSurahText('quran-uthmani', chapter);
        if (requestId != _currentRequestId || _disposed || !mounted) return;
        final allAyat = surahData.ayat;

        final verseDurations = await service.getVerseDurations(
          editionId,
          chapter,
        );
        if (requestId != _currentRequestId || _disposed || !mounted) return;

        _totalDuration = verseDurations.values.fold(
          Duration.zero,
          (a, b) => a + b,
        );
        _emitState();

        final fullSurahUrl = service.getSurahFullAudioUrl(editionId, chapter);
        _urls = [fullSurahUrl];

        _ayahOffsets = [];
        Duration cumulative = Duration.zero;
        for (final a in allAyat) {
          _ayahOffsets.add(cumulative);
          cumulative +=
              verseDurations[a.numberInSurah] ?? const Duration(seconds: 5);
        }
        _totalDuration = cumulative;

        await _player.stop();
        if (requestId != _currentRequestId || _disposed || !mounted) return;

        await _player.setAudioSource(
          AudioSource.uri(
            Uri.parse(fullSurahUrl),
            headers: const {'User-Agent': 'QuranGlow/1.0'},
            tag: MediaItem(
              id: 'surah_$chapter',
              title: 'سورة $nextSurahName',
              album: _reciterName,
              artist: _reciterName,
              duration: cumulative,
            ),
          ),
          initialPosition: Duration.zero,
          preload: true,
        );
      } on PlayerInterruptedException {
        debugPrint(
          'Audio loading was interrupted (handled PlayerInterruptedException) for request #$requestId',
        );
        return;
      } catch (e) {
        if (requestId != _currentRequestId || _disposed || !mounted) return;
        debugPrint(
          'Source error or PlatformException with full surah URL: $e. Falling back to Ayah playlist...',
        );

        try {
          final audioMap = await service.getSurahAudioUrlMap(
            editionId,
            chapter,
          );
          if (requestId != _currentRequestId || _disposed || !mounted) return;

          _urls = audioMap.values.toList();
          if (_urls.isEmpty) {
            throw Exception('لا توجد روابط آيات صوتية متاحة');
          }
          final playlist = ConcatenatingAudioSource(
            children: _urls
                .map(
                  (url) => AudioSource.uri(
                    Uri.parse(url),
                    headers: const {
                      'User-Agent':
                          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36',
                    },
                  ),
                )
                .toList(),
          );
          await _player.stop();
          if (requestId != _currentRequestId || _disposed || !mounted) return;

          await _player.setAudioSource(playlist, preload: true);
        } catch (fallbackError) {
          debugPrint('Failed to load fallback Ayah playlist: $fallbackError');
          rethrow;
        }
      }

      if (requestId != _currentRequestId || _disposed || !mounted) return;

      if (autoPlay) {
        await _player.setLoopMode(LoopMode.off);
        await _player.play();
      }

      _emitState();
    } catch (e, st) {
      if (requestId != _currentRequestId || _disposed || !mounted) return;

      final err = e.toString().toLowerCase();
      if (err.contains('abort') ||
          err.contains('interrupted') ||
          err.contains('10000000') ||
          err.contains('connection aborted') ||
          err.contains('loading interrupted')) {
        debugPrint('Audio loading was interrupted silently at outer catch: $e');
        return;
      }

      debugPrint('Error in _loadSurah: $e');
      if (state.hasValue) {
        _emitState();
      } else {
        state = AsyncValue.error(e, st);
      }
    }
  }

  Future<String> _resolveReciterName(String editionId) async {
    if (_kReciterNames.containsKey(editionId)) {
      return _kReciterNames[editionId]!;
    }

    try {
      final editions = await ref.read(quranServiceProvider).listAudioEditions();
      for (final item in editions) {
        if (item is! Map) continue;
        final map = Map<String, dynamic>.from(item);
        final id = (map['identifier'] ?? map['id'] ?? '').toString();
        if (id == editionId) {
          return (map['name'] ?? map['englishName'] ?? editionId).toString();
        }
      }
    } catch (_) {}
    return editionId;
  }

  void _emitState() {
    if (_disposed || !mounted) return;
    if (_ayahOffsets.isEmpty) return;

    final editionId = ref.read(editionIdProvider);
    final chapter = ref.read(chapterProvider).clamp(1, 114);

    int ayahIndex = 0;
    final pos = _player.position;
    for (int i = _ayahOffsets.length - 1; i >= 0; i--) {
      if (pos >= _ayahOffsets[i]) {
        ayahIndex = i;
        break;
      }
    }

    final surahName = (chapter >= 1 && chapter <= kSurahNamesAr.length)
        ? kSurahNamesAr[chapter - 1]
        : 'سورة $chapter';

    state = AsyncValue.data(
      PlayerUiState(
        editionId: editionId,
        chapter: chapter,
        total: _ayahOffsets.length,
        timelineStream: _timelineStream,
        durationStream: _player.durationStream,
        positionStream: _player.positionStream,
        bufferedStream: _player.bufferedPositionStream,
        indexStream: _player.currentIndexStream
            .map((idx) => idx)
            .asBroadcastStream(),
        playingStream: _player.playingStream,
        loopModeStream: _player.loopModeStream,
        volumeStream: _player.volumeStream,
        processingStateStream: _player.processingStateStream
            .cast<ProcessingState>(),
        totalDurationOverride: _totalDuration,
        isPlaying: _player.playing,
        currentUrl: _urls.isNotEmpty ? _urls.first : '',
        surahName: surahName,
        reciterName: _reciterName,
        currentAyah: ayahIndex,
      ),
    );
  }

  Future<void> play() async {
    try {
      await _player.play();
      if (_disposed || !mounted) return;
      _emitState();
    } catch (e) {
      debugPrint('Error playing audio (handled gracefully): $e');
    }
  }

  Future<void> pause() async {
    try {
      await _player.pause();
      if (_disposed || !mounted) return;
      _emitState();
    } catch (e) {
      debugPrint('Error pausing audio (handled gracefully): $e');
    }
  }

  Future<void> next() async {
    try {
      final curPos = _player.position;
      int nextIdx = 0;
      for (int i = 0; i < _ayahOffsets.length; i++) {
        if (_ayahOffsets[i] > curPos + const Duration(milliseconds: 200)) {
          nextIdx = i;
          break;
        }
      }
      await _player.seek(_ayahOffsets[nextIdx]);
      if (_disposed || !mounted) return;
      _emitState();
    } catch (e) {
      debugPrint('Error skipping to next (handled gracefully): $e');
    }
  }

  Future<void> previous() async {
    try {
      final curPos = _player.position;
      int prevIdx = 0;
      for (int i = _ayahOffsets.length - 1; i >= 0; i--) {
        if (_ayahOffsets[i] < curPos - const Duration(seconds: 2)) {
          prevIdx = i;
          break;
        }
      }
      await _player.seek(_ayahOffsets[prevIdx]);
      if (_disposed || !mounted) return;
      _emitState();
    } catch (e) {
      debugPrint('Error skipping to previous (handled gracefully): $e');
    }
  }

  Future<void> seekTo(Duration position) async {
    try {
      await _player.seek(position);
    } catch (e) {
      debugPrint('Error seeking audio (handled gracefully): $e');
    }
  }

  Future<void> seekToIndex(int index) async {
    try {
      if (index >= 0 && index < _ayahOffsets.length) {
        await _player.seek(_ayahOffsets[index]);
      }
    } catch (e) {
      debugPrint('Error seeking to index (handled gracefully): $e');
    }
  }

  Future<void> setSpeed(double speed) async {
    try {
      await _player.setSpeed(speed);
      if (_disposed || !mounted) return;
      _emitState();
    } catch (e) {
      debugPrint('Error setting speed (handled gracefully): $e');
    }
  }

  Future<void> toggleLoop() async {
    try {
      final nextMode = _player.loopMode == LoopMode.off
          ? LoopMode.all
          : LoopMode.off;
      await _player.setLoopMode(nextMode);
      if (_disposed || !mounted) return;
      _emitState();
    } catch (e) {
      debugPrint('Error toggling loop (handled gracefully): $e');
    }
  }

  Future<void> toggleMute() async {
    try {
      final nextVolume = _player.volume > 0 ? 0.0 : 1.0;
      await _player.setVolume(nextVolume);
      if (_disposed || !mounted) return;
      _emitState();
    } catch (e) {
      debugPrint('Error toggling mute (handled gracefully): $e');
    }
  }

  Future<void> changeEdition(String editionId) async {
    ref.read(editionIdProvider.notifier).state = editionId;
    final chapter = ref.read(chapterProvider).clamp(1, 114);
    await _loadSurah(editionId: editionId, chapter: chapter, autoPlay: false);
  }

  Duration _totalDuration = Duration.zero;
  Duration get totalDuration => _totalDuration;

  Future<void> playSurah(int chapter, {int? startAyah}) async {
    final safeChapter = chapter.clamp(1, 114);
    ref.read(chapterProvider.notifier).state = safeChapter;
    final editionId = ref.read(editionIdProvider);
    await _loadSurah(
      editionId: editionId,
      chapter: safeChapter,
      autoPlay: true,
    );
  }

  Future<void> changeChapter(int chapter) async {
    final safeChapter = chapter.clamp(1, 114);
    ref.read(chapterProvider.notifier).state = safeChapter;
    final editionId = ref.read(editionIdProvider);
    await _loadSurah(
      editionId: editionId,
      chapter: safeChapter,
      autoPlay: false,
    );
  }

  @override
  void dispose() {
    _disposed = true;
    _playingSub?.cancel();
    _posSub?.cancel();
    _player.dispose();
    super.dispose();
  }
}
