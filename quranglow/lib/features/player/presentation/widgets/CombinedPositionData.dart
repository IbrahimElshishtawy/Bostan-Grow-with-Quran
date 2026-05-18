import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:audio_service/audio_service.dart';

class CombinedPositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration duration;
  CombinedPositionData(this.position, this.bufferedPosition, this.duration);
}

Stream<CombinedPositionData> combinedPositionStream(AudioPlayer player) {
  // Use a ScanStreamTransformer or similar to keep track of the 'latest valid' state
  // to prevent flickering back to 0 during transitions.
  return Rx.combineLatest3<Duration, Duration, SequenceState?, CombinedPositionData>(
    player.positionStream,
    player.bufferedPositionStream,
    player.sequenceStateStream,
    (position, buffered, seqState) {
      // If seqState is null, the player might be in an intermediate state.
      // We try to use the player's last known index to prevent jumping back to 0.
      final sequence = seqState?.sequence ?? player.sequence;
      final idx = seqState?.currentIndex ?? player.currentIndex ?? 0;

      // Extract durations from sources, falling back to MediaItem tag metadata
      final durations = sequence.map((s) {
        final sourceDuration = s.duration;
        if (sourceDuration != null && sourceDuration != Duration.zero) {
          return sourceDuration;
        }
        final tag = s.tag;
        if (tag is MediaItem && tag.duration != null) {
          return tag.duration!;
        }
        return Duration.zero;
      }).toList();

      final total = durations.fold<Duration>(Duration.zero, (a, b) => a + b);
      final passed = durations
          .take(idx)
          .fold<Duration>(Duration.zero, (a, b) => a + b);

      // Ensure that if we are transitioning, we don't report a position smaller than 'passed'
      // if the player's internal position just reset to zero but 'idx' is already updated.
      final pos = passed + position;
      final buf = passed + buffered;

      return CombinedPositionData(pos, buf, total);
    },
  ).distinct((prev, next) {
    // Avoid emitting a state that goes backwards significantly during playback
    // unless it's a large jump (manual seek).
    if (next.position < prev.position &&
        (prev.position - next.position).inMilliseconds < 1000) {
      return true; // Suppress small backward jumps (likely transition flicker)
    }
    return false;
  }).asBroadcastStream();
}
