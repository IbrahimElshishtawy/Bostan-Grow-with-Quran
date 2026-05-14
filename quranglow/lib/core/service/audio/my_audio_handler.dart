import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

class MyAudioHandler extends BaseAudioHandler with SeekHandler {
  final AudioPlayer _player = AudioPlayer();
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
    if (_activeUrl == nextUrl &&
        _player.processingState != ProcessingState.idle) {
      if (!_player.playing) {
        await _player.play();
      }
      return;
    }

    final artworkUri = await _resolveArtworkUri();
    mediaItem.add(
      MediaItem(
        id: nextUrl,
        title: title ?? 'القرآن الكريم',
        artist: artist ?? 'QuranGlow',
        album: album ?? 'المصحف المرتل',
        artUri: artworkUri,
        displayTitle: title ?? 'القرآن الكريم',
        displaySubtitle: artist ?? 'QuranGlow',
        displayDescription: album,
      ),
    );

    _activeUrl = nextUrl;
    await _player.setUrl(nextUrl);
    await play();
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
      final bytes = await rootBundle.load('assets/iosn/icongrowquran.jpg');
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/quranglow_now_playing_v2.jpg');
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
  Future<void> skipToNext() async {
    // Custom logic can be added here if needed
  }

  @override
  Future<void> skipToPrevious() async {
    // Custom logic can be added here if needed
  }
}
