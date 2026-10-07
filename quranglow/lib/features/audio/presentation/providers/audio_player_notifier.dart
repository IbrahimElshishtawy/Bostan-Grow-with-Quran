import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quran/quran.dart' as quran;
import '../../domain/entities/reciter.dart';

class QuranAudioState {
  final Reciter selectedReciter;
  final int currentSurah;
  final int currentAyah;
  final bool isPlaying;
  final bool isBuffering;
  final Duration currentPosition;
  final Duration totalDuration;
  final double speed;
  final bool repeatAyah;
  final String? errorMessage;

  const QuranAudioState({
    required this.selectedReciter,
    this.currentSurah = 1,
    this.currentAyah = 1,
    this.isPlaying = false,
    this.isBuffering = false,
    this.currentPosition = Duration.zero,
    this.totalDuration = Duration.zero,
    this.speed = 1.0,
    this.repeatAyah = false,
    this.errorMessage,
  });

  QuranAudioState copyWith({
    Reciter? selectedReciter,
    int? currentSurah,
    int? currentAyah,
    bool? isPlaying,
    bool? isBuffering,
    Duration? currentPosition,
    Duration? totalDuration,
    double? speed,
    bool? repeatAyah,
    String? errorMessage,
    bool clearError = false,
  }) {
    return QuranAudioState(
      selectedReciter: selectedReciter ?? this.selectedReciter,
      currentSurah: currentSurah ?? this.currentSurah,
      currentAyah: currentAyah ?? this.currentAyah,
      isPlaying: isPlaying ?? this.isPlaying,
      isBuffering: isBuffering ?? this.isBuffering,
      currentPosition: currentPosition ?? this.currentPosition,
      totalDuration: totalDuration ?? this.totalDuration,
      speed: speed ?? this.speed,
      repeatAyah: repeatAyah ?? this.repeatAyah,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class QuranAudioNotifier extends StateNotifier<QuranAudioState> {
  final AudioPlayer _player;

  QuranAudioNotifier()
      : _player = AudioPlayer(),
        super(QuranAudioState(selectedReciter: Reciter.defaultReciters.first)) {
    _initListeners();
  }

  void _initListeners() {
    _player.playerStateStream.listen((playerState) {
      final isPlaying = playerState.playing;
      final processing = playerState.processingState;
      final isBuffering = processing == ProcessingState.buffering ||
          processing == ProcessingState.loading;

      state = state.copyWith(
        isPlaying: isPlaying,
        isBuffering: isBuffering,
      );

      if (processing == ProcessingState.completed) {
        _onAyahCompleted();
      }
    });

    _player.positionStream.listen((pos) {
      state = state.copyWith(currentPosition: pos);
    });

    _player.durationStream.listen((dur) {
      if (dur != null) {
        state = state.copyWith(totalDuration: dur);
      }
    });
  }

  void _onAyahCompleted() {
    if (state.repeatAyah) {
      playAyah(state.currentSurah, state.currentAyah);
    } else {
      nextAyah();
    }
  }

  Future<void> playAyah(int surah, int ayah) async {
    state = state.copyWith(
      currentSurah: surah,
      currentAyah: ayah,
      isBuffering: true,
      clearError: true,
    );

    try {
      final url = state.selectedReciter.getAyahAudioUrl(surah, ayah);
      await _player.setUrl(url);
      await _player.setSpeed(state.speed);
      await _player.play();
    } catch (e) {
      state = state.copyWith(
        isBuffering: false,
        isPlaying: false,
        errorMessage: 'تعذر تشغيل تلاوة الآية ($e)',
      );
    }
  }

  Future<void> pause() async {
    await _player.pause();
  }

  Future<void> resume() async {
    await _player.play();
  }

  Future<void> stop() async {
    await _player.stop();
    state = state.copyWith(isPlaying: false, currentPosition: Duration.zero);
  }

  Future<void> seek(Duration position) async {
    await _player.seek(position);
  }

  void nextAyah() {
    final maxVerses = quran.getVerseCount(state.currentSurah);
    if (state.currentAyah < maxVerses) {
      playAyah(state.currentSurah, state.currentAyah + 1);
    } else if (state.currentSurah < 114) {
      playAyah(state.currentSurah + 1, 1);
    } else {
      stop();
    }
  }

  void previousAyah() {
    if (state.currentAyah > 1) {
      playAyah(state.currentSurah, state.currentAyah - 1);
    } else if (state.currentSurah > 1) {
      final prevSurah = state.currentSurah - 1;
      final prevVerses = quran.getVerseCount(prevSurah);
      playAyah(prevSurah, prevVerses);
    }
  }

  void setReciter(Reciter reciter) {
    state = state.copyWith(selectedReciter: reciter);
    if (state.isPlaying) {
      playAyah(state.currentSurah, state.currentAyah);
    }
  }

  void setSpeed(double speed) {
    state = state.copyWith(speed: speed);
    _player.setSpeed(speed);
  }

  void toggleRepeatAyah() {
    state = state.copyWith(repeatAyah: !state.repeatAyah);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}

final quranAudioNotifierProvider =
    StateNotifierProvider<QuranAudioNotifier, QuranAudioState>((ref) {
  return QuranAudioNotifier();
});
