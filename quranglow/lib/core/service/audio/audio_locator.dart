// lib/core/audio/audio_locator.dart
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'my_audio_handler.dart';

MyAudioHandler? _audioHandler;

MyAudioHandler get audioHandler {
  final handler = _audioHandler;
  if (handler == null) {
    throw StateError('Audio handler is not initialized');
  }
  return handler;
}

bool get isAudioHandlerReady => _audioHandler != null;

Future<void> initAudioHandler() async {
  _audioHandler = await AudioService.init(
    builder: () => MyAudioHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'playback_ch',
      androidNotificationChannelName: 'تشغيل الصوت',
      androidNotificationOngoing: false,
      androidStopForegroundOnPause: false,
      androidNotificationClickStartsActivity: true,
      notificationColor: Color(0xFF1B5E20),
      preloadArtwork: true,
    ),
  );
}
