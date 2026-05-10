import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  
  LevelGameplayController(this.ref, this.level) : super(LevelGameplayState()) {
    _audioPlayer = AudioPlayer();
    _initListeners();
    _loadLevelData();
  }

  void _initListeners() {
    _audioPlayer.playerStateStream.listen((state) {
      final playing = state.playing;
      this.state = this.state.copyWith(isPlaying: playing);
    });

    _audioPlayer.currentIndexStream.listen((index) {
      if (index != null) {
        state = state.copyWith(currentPlayingAyahIndex: index);
      }
    });
  }

  Future<void> _loadLevelData() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // 1. Fetch Arabic text data
      final quranApi = ref.read(quranApiServiceProvider);
      final fetchedAyahs = await quranApi.getAyahRange(
        level.surahId, 
        level.ayahStart, 
        level.ayahEnd,
      );

      // 2. Resolve Reciter
      final settings = ref.read(settingsControllerProvider);
      String reciterCode = settings.preferredReciterId; 
      // Fallback / normalization to everyayah expected ID
      // In a real scenario normalize mapping from API id 'ar.alafasy' to directory name 'Alafasy'
      String directoryName = _normalizeReciterDir(reciterCode);

      // 3. Build Audio Source Concatenation
      final List<AudioSource> playlist = [];
      for (final ayah in fetchedAyahs) {
        final s = level.surahId.toString().padLeft(3, '0');
        final a = ayah.ayahNumber.toString().padLeft(3, '0');
        final url = 'https://everyayah.com/data/$directoryName/$s$a.mp3';
        playlist.add(AudioSource.uri(Uri.parse(url)));
      }

      await _audioPlayer.setAudioSource(
        ConcatenatingAudioSource(children: playlist),
        initialIndex: 0,
        initialPosition: Duration.zero,
      );

      state = state.copyWith(
        isLoading: false,
        ayahs: fetchedAyahs,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
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
    _audioPlayer.dispose();
    super.dispose();
  }
}

// Note: This provider receives dynamic parameter, we use AutoDisposeFamily
final levelGameplayControllerProvider = StateNotifierProvider.autoDispose.family<LevelGameplayController, LevelGameplayState, GameLevel>((ref, level) {
  return LevelGameplayController(ref, level);
});
