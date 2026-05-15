import 'package:just_audio/just_audio.dart';
import 'package:rxdart/rxdart.dart';
import 'package:audio_service/audio_service.dart';

class CombinedPositionData {
  final Duration position;
  final Duration bufferedPosition;
  final Duration total;
  CombinedPositionData(this.position, this.bufferedPosition, this.total);
}

Stream<CombinedPositionData> combinedPositionStream(AudioPlayer player) {
  return Rx.combineLatest3<Duration, Duration, SequenceState?,
      CombinedPositionData>(
    player.positionStream,
    player.bufferedPositionStream,
    player.sequenceStateStream,
    (position, buffered, seqState) {
      final sequence = seqState?.sequence ?? const <IndexedAudioSource>[];
      final idx = seqState?.currentIndex ?? 0;

      // Extract durations from sources, falling back to MediaItem tag metadata if needed
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
      final passed =
          durations.take(idx).fold<Duration>(Duration.zero, (a, b) => a + b);

      final pos = passed + position;
      final buf = passed + buffered;

      return CombinedPositionData(pos, buf, total);
    },
  );
}
