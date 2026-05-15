import 'package:just_audio/just_audio.dart';
import 'package:quranglow/features/player/presentation/widgets/CombinedPositionData.dart';

class PlaylistState {
  final String editionId;
  final int chapter;
  final int total;
  final Stream<CombinedPositionData> timelineStream;
  final Stream<Duration?> durationStream;
  final Stream<Duration> positionStream;
  final Stream<Duration> bufferedStream;
  final Stream<int?> indexStream;
  final Stream<bool> playingStream;
  final Stream<LoopMode> loopModeStream;
  final Stream<double> volumeStream;
  final Stream<ProcessingState> processingStateStream;

  const PlaylistState({
    required this.editionId,
    required this.chapter,
    required this.total,
    required this.timelineStream,
    required this.durationStream,
    required this.positionStream,
    required this.bufferedStream,
    required this.indexStream,
    required this.playingStream,
    required this.loopModeStream,
    required this.volumeStream,
    required this.processingStateStream,
  });
}
