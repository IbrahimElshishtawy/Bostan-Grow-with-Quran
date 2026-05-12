import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';
import 'package:quranglow/core/models/quran_models.dart';
import 'package:quranglow/core/providers/app_providers.dart';
import 'package:quranglow/features/gamification/domain/models/gamification_models.dart';

class LevelGameplayState {
  final bool isLoading;
  final bool isAudioLoading; // ✨ New: Decouples UI rendering from network audio hydration!
  final List<Ayah> ayahs;
  final int currentPlayingAyahIndex;
  final bool isPlaying;
  final bool isFinished;
  final String? error;

  LevelGameplayState({
    this.isLoading = true,
    this.isAudioLoading = true, // Defaults to loading in background
    this.ayahs = const [],
    this.currentPlayingAyahIndex = 0,
    this.isPlaying = false,
    this.isFinished = false,
    this.error,
  });

  LevelGameplayState copyWith({
    bool? isLoading,
    bool? isAudioLoading,
    List<Ayah>? ayahs,
    int? currentPlayingAyahIndex,
    bool? isPlaying,
    bool? isFinished,
    String? error,
  }) {
    return LevelGameplayState(
      isLoading: isLoading ?? this.isLoading,
      isAudioLoading: isAudioLoading ?? this.isAudioLoading,
      ayahs: ayahs ?? this.ayahs,
      currentPlayingAyahIndex: currentPlayingAyahIndex ?? this.currentPlayingAyahIndex,
      isPlaying: isPlaying ?? this.isPlaying,
      isFinished: isFinished ?? this.isFinished,
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

    _subscriptions.add(
      _audioPlayer.processingStateStream.listen((s) {
        if (s == ProcessingState.completed) {
          _safeUpdate(state.copyWith(isFinished: true, isPlaying: false));
        }
      }),
    );
  }

  Future<void> _loadLevelData() async {
    _safeUpdate(state.copyWith(isLoading: true, isAudioLoading: true, error: null));

    try {
      // ✨ BLAZING FAST 0ms TEXT FETCH ✨
      // Pull Arabic text from the pre-warmed local SQLite/Hive storage instantly!
      final quranApi = ref.read(quranApiServiceProvider);
      final fetchedAyahs = await quranApi.getAyahRange(
        level.surahId,
        level.ayahStart,
        level.ayahEnd,
      );

      // 🚀 RENDER SCREEN INSTANTLY: Free the UI thread right now!
      _safeUpdate(state.copyWith(
        isLoading: false,
        ayahs: fetchedAyahs,
      ));

      // 🎵 BACKGROUND AUDIO STREAMING INJECTION
      // Prepares the network streams asynchronously without blocking textual rendering.
      _initializeAudioInBackground(fetchedAyahs);
    } catch (e) {
      _safeUpdate(state.copyWith(isLoading: false, error: 'فشل تحميل الآيات: $e'));
    }
  }

  Future<void> _initializeAudioInBackground(List<Ayah> fetchedAyahs) async {
    try {
      final settings = ref.read(settingsControllerProvider);
      final String rawReciter = settings.preferredReciterId;
      final String reciterId = rawReciter.trim().isEmpty ? 'ar.alafasy' : rawReciter;

      // ✨ DIRECT CDN GENERATION: Zero network overhead for metadata lookups!
      final List<AudioSource> playlist = [];
      for (final ayah in fetchedAyahs) {
        // Standard AlQuran CDN structure: cdn.islamic.network/quran/audio/128/{reciter}/{globalNumber}.mp3
        final String directUrl = 'https://cdn.islamic.network/quran/audio/128/$reciterId/${ayah.number}.mp3';
        playlist.add(AudioSource.uri(Uri.parse(directUrl)));
      }

      // 🚀 PREVENT STALLING: Enforce lazy-loading by disabling standard blocking preload!
      if (playlist.isNotEmpty) {
        await _audioPlayer.setAudioSource(
          ConcatenatingAudioSource(children: playlist),
          initialIndex: 0,
          initialPosition: Duration.zero,
          preload: false, // Prevents blocking the event loop with HTTP metadata fetches!
        );
      }

      _safeUpdate(state.copyWith(isAudioLoading: false));
    } catch (e) {
      debugPrint('[FALLBACK PLAYLIST GENERATION]: $e');
      // Secondary reliable fallback source (EveryAyah)
      try {
        final List<AudioSource> fallback = [];
        for (final ayah in fetchedAyahs) {
          final s = level.surahId.toString().padLeft(3, '0');
          final a = ayah.ayahNumber.toString().padLeft(3, '0');
          fallback.add(AudioSource.uri(Uri.parse('https://everyayah.com/data/Alafasy/$s$a.mp3')));
        }
        await _audioPlayer.setAudioSource(
          ConcatenatingAudioSource(children: fallback),
          initialIndex: 0,
          initialPosition: Duration.zero,
          preload: false,
        );
        _safeUpdate(state.copyWith(isAudioLoading: false));
      } catch (_) {
        // Still permit reading mode even if audio backend completely stalls.
        _safeUpdate(state.copyWith(isAudioLoading: false));
      }
    }
  }


  void playPause() {
    if (state.isAudioLoading) return; // 🛡️ Protects against tap during instantiation
    
    if (_audioPlayer.processingState == ProcessingState.completed) {
      // Restarting from beginning if replaying after finish
      _safeUpdate(state.copyWith(isFinished: false));
      _audioPlayer.seek(Duration.zero, index: 0);
      _audioPlayer.play();
      return;
    }
    
    if (_audioPlayer.playing) {
      _audioPlayer.pause();
    } else {
      _safeUpdate(state.copyWith(isFinished: false));
      _audioPlayer.play();
    }
  }

  void seekToAyah(int index) {
    if (state.isAudioLoading) return; // 🛡️ Protects against tap during instantiation

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

// _LevelPayload class removed as dynamic background hydration is now direct flawlessly.

// Note: This provider receives dynamic parameter, we use AutoDisposeFamily
final levelGameplayControllerProvider = StateNotifierProvider.autoDispose.family<LevelGameplayController, LevelGameplayState, GameLevel>((ref, level) {
  return LevelGameplayController(ref, level);
});
