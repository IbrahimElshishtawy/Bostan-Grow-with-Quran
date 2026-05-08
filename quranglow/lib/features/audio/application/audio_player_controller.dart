/// Audio player state controller
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/models/audio_models.dart';

class AudioPlayerController extends StateNotifier<PlaybackSession> {
  AudioPlayerController()
      : super(
          PlaybackSession(
            id: 'default',
            queue: [],
            currentIndex: -1,
            state: PlaybackState.idle,
          ),
        );

  /// Initialize playback session
  void initializeSession(List<AudioTrack> tracks) {
    final queue = tracks
        .map((track) => QueueItem(track: track))
        .toList();

    state = state.copyWith(
      queue: queue,
      currentIndex: 0,
      state: PlaybackState.idle,
    );
  }

  /// Play audio
  void play() {
    state = state.copyWith(state: PlaybackState.playing);
  }

  /// Pause audio
  void pause() {
    state = state.copyWith(state: PlaybackState.paused);
  }

  /// Stop audio
  void stop() {
    state = state.copyWith(
      state: PlaybackState.stopped,
      currentPosition: Duration.zero,
    );
  }

  /// Seek to position
  void seek(Duration position) {
    state = state.copyWith(currentPosition: position);
  }

  /// Play next track
  void playNext() {
    if (state.hasNext) {
      state = state.copyWith(currentIndex: state.currentIndex + 1);
    }
  }

  /// Play previous track
  void playPrevious() {
    if (state.hasPrevious) {
      state = state.copyWith(currentIndex: state.currentIndex - 1);
    }
  }

  /// Set playback speed
  void setSpeed(double speed) {
    state = state.copyWith(speed: speed);
  }

  /// Set repeat mode
  void setRepeatMode(RepeatMode mode) {
    state = state.copyWith(repeatMode: mode);
  }

  /// Toggle shuffle
  void toggleShuffle() {
    state = state.copyWith(isShuffled: !state.isShuffled);
  }

  /// Add track to queue
  void addToQueue(AudioTrack track) {
    final newQueue = [...state.queue, QueueItem(track: track)];
    state = state.copyWith(queue: newQueue);
  }

  /// Remove track from queue
  void removeFromQueue(int index) {
    if (index >= 0 && index < state.queue.length) {
      final newQueue = [...state.queue];
      newQueue.removeAt(index);
      state = state.copyWith(queue: newQueue);
    }
  }

  /// Clear queue
  void clearQueue() {
    state = state.copyWith(
      queue: [],
      currentIndex: -1,
      state: PlaybackState.idle,
    );
  }

  /// Update current position
  void updatePosition(Duration position) {
    state = state.copyWith(currentPosition: position);
  }

  /// Mark track as completed
  void markTrackCompleted(int index) {
    if (index >= 0 && index < state.queue.length) {
      final newQueue = [...state.queue];
      newQueue[index] = newQueue[index].copyWith(isCompleted: true);
      state = state.copyWith(queue: newQueue);
    }
  }
}
