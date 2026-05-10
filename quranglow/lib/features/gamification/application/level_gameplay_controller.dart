import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/utils/either.dart';
import 'package:quranglow/core/di/providers.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quranglow/core/models/quran_models.dart';
import 'package:quranglow/core/providers/app_providers.dart';
import 'package:quranglow/features/gamification/domain/models/gamification_models.dart';

class LevelGameplayState {
  final bool isLoading;
  final List<Ayah> ayahs;
  final int currentPlayingAyahIndex;
  final bool isPlaying;
  final String? error;

  LevelGameplayState({
    this.isLoading = true,
    this.ayahs = const [],
    this.currentPlayingAyahIndex = 0,
    this.isPlaying = false,
    this.error,
  });

  LevelGameplayState copyWith({
    bool? isLoading,
    List<Ayah>? ayahs,
    int? currentPlayingAyahIndex,
    bool? isPlaying,
    String? error,
  }) {
    return LevelGameplayState(
      isLoading: isLoading ?? this.isLoading,
      ayahs: ayahs ?? this.ayahs,
      currentPlayingAyahIndex: currentPlayingAyahIndex ?? this.currentPlayingAyahIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      error: error,
    );
  }
}

class LevelGameplayController extends StateNotifier<LevelGameplayState> {
  final Ref ref;
  final GameLevel level;
  late final AudioPlayer _audioPlayer;
  final List<StreamSubscription> _subscriptions = [];
  bool _isDisposed = false;
  
  LevelGameplayController(this.ref, this.level) : super(LevelGameplayState()) {
    _audioPlayer = AudioPlayer();
    _initListeners();
    _loadLevelData();
  }

  void _safeUpdate(LevelGameplayState newState) {
    if (_isDisposed || !mounted) return;
    try {
      state = newState;
    } catch (_) {
      // Safe suppression for delayed streams firing after unmount
    }
  }

  void _initListeners() {
    _subscriptions.add(
      _audioPlayer.playerStateStream.listen((s) {
        final playing = s.playing;
        _safeUpdate(state.copyWith(isPlaying: playing));
      }),
    );

    _subscriptions.add(
      _audioPlayer.currentIndexStream.listen((index) {
        if (index != null) {
          _safeUpdate(state.copyWith(currentPlayingAyahIndex: index));
        }
      }),
    );
  }

  Future<void> _loadLevelData() async {
    _safeUpdate(state.copyWith(isLoading: true, error: null));

    final result = await _fetchLevelPayload();

    result.match(
      (error) {
        _safeUpdate(state.copyWith(isLoading: false, error: error));
      },
      (payload) {
        _safeUpdate(state.copyWith(
          isLoading: false,
          ayahs: payload.ayahs,
        ));
      },
    );
  }

  Future<Either<String, _LevelPayload>> _fetchLevelPayload() async {
    try {
      // 1. Fetch Arabic text data via existing provider
      final quranApi = ref.read(quranApiServiceProvider);
      final fetchedAyahs = await quranApi.getAyahRange(
        level.surahId,
        level.ayahStart,
        level.ayahEnd,
      );

      // 2. Resolve Dynamic API-derived Audio list via user's explicit api service
      final settings = ref.read(settingsControllerProvider);
      final reciterId = settings.preferredReciterId;
      final cloudApi = ref.read(alQuranProvider);

      // Fetch full metadata package from AlQuran.cloud for reliability over Everyayah
      final audioResponse = await cloudApi.getSurahAudio(reciterId, level.surahId);
      
      final dynamic dataPayload = audioResponse['data'];
      if (dataPayload == null || dataPayload['ayahs'] == null) {
        return const Left('فشل جلب بيانات الصوت من الخادم');
      }
      
      final List rawAyahs = dataPayload['ayahs'] as List;

      // 3. Construct strictly bounded playlist
      final List<AudioSource> playlist = [];
      
      // Map precisely by matching ayahNumberInSurah
      for (final ayah in fetchedAyahs) {
        final audioMatch = rawAyahs.firstWhere(
          (element) => (element['numberInSurah'] as num).toInt() == ayah.ayahNumber,
          orElse: () => null,
        );
        
        final String? remoteUrl = audioMatch != null ? audioMatch['audio'] as String? : null;
        
        if (remoteUrl != null && remoteUrl.isNotEmpty) {
          playlist.add(AudioSource.uri(Uri.parse(remoteUrl)));
        } else {
          // Universal ultra-safe dynamic secondary fallback
          final s = level.surahId.toString().padLeft(3, '0');
          final a = ayah.ayahNumber.toString().padLeft(3, '0');
          playlist.add(AudioSource.uri(Uri.parse('https://everyayah.com/data/Alafasy/$s$a.mp3')));
        }
      }

      // Initialize engine
      if (playlist.isNotEmpty) {
        await _audioPlayer.setAudioSource(
          ConcatenatingAudioSource(children: playlist),
          initialIndex: 0,
          initialPosition: Duration.zero,
        );
      }

      return Right(_LevelPayload(ayahs: fetchedAyahs));
    } catch (e) {
      return Left('خطأ غير متوقع: ${e.toString()}');
    }
  }

  String _normalizeReciterDir(String raw) {
    // Example mapping routine
    if (raw.toLowerCase().contains('alafasy')) return 'Alafasy';
    if (raw.toLowerCase().contains('husary')) return 'Husary';
    if (raw.toLowerCase().contains('abdulbaset')) return 'AbdulBaset_Murattal';
    if (raw.toLowerCase().contains('menshawi')) return 'Minshawi_Murattal';
    return 'Alafasy'; // Safe universal fallback
  }

  void playPause() {
    if (_audioPlayer.playing) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.play();
    }
  }

  void seekToAyah(int index) {
    if (index >= 0 && index < state.ayahs.length) {
      _audioPlayer.seek(Duration.zero, index: index);
      _audioPlayer.play();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _audioPlayer.dispose();
    super.dispose();
  }
}

class _LevelPayload {
  final List<Ayah> ayahs;
  const _LevelPayload({required this.ayahs});
}

// Note: This provider receives dynamic parameter, we use AutoDisposeFamily
final levelGameplayControllerProvider = StateNotifierProvider.autoDispose.family<LevelGameplayController, LevelGameplayState, GameLevel>((ref, level) {
  return LevelGameplayController(ref, level);
});
