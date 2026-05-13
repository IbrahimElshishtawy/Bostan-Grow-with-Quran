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

    _player.playbackEventStream.listen((_) {
      _broadcastPlaybackState();
    });

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
        title: title ?? 'تشغيل القرآن',
        artist: artist,
        album: album,
        artUri: artworkUri,
        displayTitle: title ?? 'تشغيل القرآن',
        displaySubtitle: artist,
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
        controls: playing
            ? [MediaControl.pause, MediaControl.stop]
            : [MediaControl.play, MediaControl.stop],
        androidCompactActionIndices: const [0, 1],
        systemActions: const {MediaAction.seek},
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
      final file = File('${dir.path}/quranglow_now_playing.jpg');
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
}
