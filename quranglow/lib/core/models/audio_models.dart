/// Audio models for playback and streaming
import 'package:quranglow/core/models/quran_models.dart';

enum AudioQuality {
  low(bitrate: 64),
  medium(bitrate: 128),
  high(bitrate: 192),
  veryHigh(bitrate: 320);

  const AudioQuality({required this.bitrate});
  final int bitrate;
}

enum PlaybackState {
  idle,
  loading,
  playing,
  paused,
  stopped,
  error,
}

class AudioTrack {
  const AudioTrack({
    required this.id,
    required this.surahNumber,
    required this.ayahNumber,
    required this.reciter,
    required this.audioUrl,
    required this.duration,
    this.quality = AudioQuality.high,
    this.title = '',
    this.subtitle = '',
    this.imageUrl = '',
  });

  final String id;
  final int surahNumber;
  final int ayahNumber;
  final Reciter reciter;
  final String audioUrl;
  final Duration duration;
  final AudioQuality quality;
  final String title;
  final String subtitle;
  final String imageUrl;

  factory AudioTrack.fromRecitationAudio(
    RecitationAudio audio, {
    String title = '',
    String subtitle = '',
    String imageUrl = '',
  }) {
    return AudioTrack(
      id: '${audio.surahNumber}:${audio.ayahNumber}:${audio.reciter.identifier}',
      surahNumber: audio.surahNumber,
      ayahNumber: audio.ayahNumber,
      reciter: audio.reciter,
      audioUrl: audio.audioUrl,
      duration: audio.duration,
      title: title,
      subtitle: subtitle,
      imageUrl: imageUrl,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'surahNumber': surahNumber,
    'ayahNumber': ayahNumber,
    'reciter': reciter.identifier,
    'audioUrl': audioUrl,
    'duration': duration.inSeconds,
    'quality': quality.name,
    'title': title,
    'subtitle': subtitle,
    'imageUrl': imageUrl,
  };

  factory AudioTrack.fromJson(Map<String, dynamic> json) {
    return AudioTrack(
      id: json['id'] as String? ?? '',
      surahNumber: json['surahNumber'] as int? ?? 0,
      ayahNumber: json['ayahNumber'] as int? ?? 0,
      reciter: Reciter(
        name: ReciterName.misharyrashid,
        displayName: json['reciter'] as String? ?? '',
        identifier: json['reciter'] as String? ?? '',
      ),
      audioUrl: json['audioUrl'] as String? ?? '',
      duration: Duration(seconds: json['duration'] as int? ?? 0),
      quality: AudioQuality.values.firstWhere(
        (q) => q.name == json['quality'],
        orElse: () => AudioQuality.high,
      ),
      title: json['title'] as String? ?? '',
      subtitle: json['subtitle'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
    );
  }
}

class QueueItem {
  const QueueItem({
    required this.track,
    this.isPlaying = false,
    this.isCompleted = false,
    this.currentPosition = Duration.zero,
  });

  final AudioTrack track;
  final bool isPlaying;
  final bool isCompleted;
  final Duration currentPosition;

  QueueItem copyWith({
    AudioTrack? track,
    bool? isPlaying,
    bool? isCompleted,
    Duration? currentPosition,
  }) {
    return QueueItem(
      track: track ?? this.track,
      isPlaying: isPlaying ?? this.isPlaying,
      isCompleted: isCompleted ?? this.isCompleted,
      currentPosition: currentPosition ?? this.currentPosition,
    );
  }
}

class PlaybackSession {
  const PlaybackSession({
    required this.id,
    required this.queue,
    required this.currentIndex,
    required this.state,
    this.currentPosition = Duration.zero,
    this.speed = 1.0,
    this.repeatMode = RepeatMode.off,
    this.isShuffled = false,
  });

  final String id;
  final List<QueueItem> queue;
  final int currentIndex;
  final PlaybackState state;
  final Duration currentPosition;
  final double speed;
  final RepeatMode repeatMode;
  final bool isShuffled;

  QueueItem? get currentTrack =>
      currentIndex >= 0 && currentIndex < queue.length
          ? queue[currentIndex]
          : null;

  bool get hasNext => currentIndex < queue.length - 1;
  bool get hasPrevious => currentIndex > 0;

  PlaybackSession copyWith({
    String? id,
    List<QueueItem>? queue,
    int? currentIndex,
    PlaybackState? state,
    Duration? currentPosition,
    double? speed,
    RepeatMode? repeatMode,
    bool? isShuffled,
  }) {
    return PlaybackSession(
      id: id ?? this.id,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      state: state ?? this.state,
      currentPosition: currentPosition ?? this.currentPosition,
      speed: speed ?? this.speed,
      repeatMode: repeatMode ?? this.repeatMode,
      isShuffled: isShuffled ?? this.isShuffled,
    );
  }
}

enum RepeatMode {
  off,
  one,
  all,
}

class AudioMetadata {
  const AudioMetadata({
    required this.surahName,
    required this.reciterName,
    required this.ayahNumber,
    required this.totalAyahs,
    this.imageUrl = '',
    this.description = '',
  });

  final String surahName;
  final String reciterName;
  final int ayahNumber;
  final int totalAyahs;
  final String imageUrl;
  final String description;
}
