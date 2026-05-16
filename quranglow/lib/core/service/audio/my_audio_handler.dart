import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class MyAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  AudioPlayer get player => _player;
  String? _activeUrl;
  Uri? _artworkUri;

  MyAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // Handle audio focus and interruptions (e.g., phone call, other music app)
    session.interruptionEventStream.listen((event) {
      if (event.begin) {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _player.setVolume(0.5);
            break;
          case AudioInterruptionType.pause:
          case AudioInterruptionType.unknown:
            pause();
            break;
        }
      } else {
        switch (event.type) {
          case AudioInterruptionType.duck:
            _player.setVolume(1.0);
            break;
          case AudioInterruptionType.pause:
            play();
            break;
          case AudioInterruptionType.unknown:
            break;
        }
      }
    });

    // Handle unplugging headphones (becoming noisy)
    session.becomingNoisyEventStream.listen((_) => pause());

    _player.playbackEventStream.listen((_) => _broadcastPlaybackState());

    _player.durationStream.listen((duration) {
      final currentItem = mediaItem.value;
      if (currentItem == null || duration == null) return;
      if (currentItem.duration == duration) return;
      mediaItem.add(currentItem.copyWith(duration: duration));
    });
  }

  Future<void> playUri(
    Uri uri, {
    String? title,
    String? artist,
    String? album,
  }) async {
    final nextUrl = uri.toString();
    // 1. If already loading/playing this exact URL, don't interrupt it
    if (_activeUrl == nextUrl &&
        _player.processingState != ProcessingState.idle &&
        _player.processingState != ProcessingState.completed) {
      if (!_player.playing) {
        await _player.play();
      }
      return;
    }

    // 2. Resolve metadata
    final artworkUri = await _resolveArtworkUri();
    mediaItem.add(
      MediaItem(
        id: nextUrl,
        title: title ?? 'القرآن الكريم',
        artist: artist ?? 'بُستان',
        album: album ?? 'المصحف المرتل',
        artUri: artworkUri,
        displayTitle: title ?? 'القرآن الكريم',
        displaySubtitle: artist ?? 'بُستان',
        displayDescription: album,
      ),
    );

    // 3. Update intent and load
    _activeUrl = nextUrl;
    try {
      // Small pause to allow the engine to settle if switching rapidly
      await _player.stop(); 
      await _player.setUrl(
        nextUrl,
        headers: const {'User-Agent': 'QuranGlow/1.0'},
      );
      await play();
    } catch (e) {
      // just_audio throws this if a new setUrl/load is called before this one finishes.
      // We can safely ignore it as the new request will take over.
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('abort') || 
          errorStr.contains('interrupted') ||
          errorStr.contains('1001') || // Common code for interruption
          errorStr.contains('loading interrupted')) {
        return;
      }
      rethrow;
    }
  }

  void _broadcastPlaybackState() {
    final playing = _player.playing;
    playbackState.add(
      playbackState.value.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          MediaControl.rewind,
          if (playing) MediaControl.pause else MediaControl.play,
          MediaControl.fastForward,
          MediaControl.skipToNext,
        ],
        androidCompactActionIndices: const [0, 2, 4],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        processingState: const {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      ),
    );
  }

  Future<Uri?> _resolveArtworkUri() async {
    if (_artworkUri != null) return _artworkUri;

    try {
      final bytes = await rootBundle.load('assets/images/bustan_splash.png');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/bustan_now_playing.png');
      await file.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      _artworkUri = Uri.file(file.path);
      return _artworkUri;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> stop() async {
    _activeUrl = null;
    await _player.stop();
    await super.stop();
  }

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> fastForward() => _player.seek(_player.position + const Duration(seconds: 10));

  @override
  Future<void> rewind() => _player.seek(_player.position - const Duration(seconds: 10));

  @override
  Future<void> skipToNext() => _player.seekToNext();

  @override
  Future<void> skipToPrevious() => _player.seekToPrevious();
}
