import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:quranglow/core/di/providers.dart';
import 'package:quranglow/features/player/presentation/widgets/CombinedPositionData.dart';

class PositionBar extends ConsumerWidget {
  const PositionBar({
    super.key,
    required this.timelineStream,
    required this.onSeek,
  });

  final Stream<CombinedPositionData> timelineStream;
  final Future<void> Function(Duration) onSeek;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return StreamBuilder<CombinedPositionData>(
      stream: timelineStream,
      initialData: CombinedPositionData(
        Duration.zero,
        Duration.zero,
        Duration.zero,
      ),
      builder: (_, snap) {
        final timeline =
            snap.data ??
            CombinedPositionData(Duration.zero, Duration.zero, Duration.zero);
        
        final playerState = ref.watch(playerControllerProvider).asData?.value;
        final totalOverride = playerState?.totalDurationOverride ?? Duration.zero;
        
        final total = (totalOverride > timeline.total) ? totalOverride : timeline.total;
        final position = timeline.position > total ? total : timeline.position;
        
        // Custom buffering logic for "YouTube-style" bar across multiple ayahs
        final bufferedVal = playerState?.bufferedPercent ?? 0.0;
        final bufferedMs = (bufferedVal * total.inMilliseconds).toDouble();
            
        final sliderMax = total.inMilliseconds <= 0
            ? 1.0
            : total.inMilliseconds.toDouble();

        return Column(
          children: [
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 5,
                inactiveTrackColor: cs.surfaceContainerHighest,
                secondaryActiveTrackColor: cs.primary.withValues(alpha: 0.22),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
              ),
              child: Slider(
                min: 0,
                max: sliderMax,
                value: position.inMilliseconds.clamp(0, sliderMax).toDouble(),
                secondaryTrackValue: bufferedMs.clamp(0, sliderMax).toDouble(),
                onChanged: total.inMilliseconds <= 0
                    ? null
                    : (value) => onSeek(Duration(milliseconds: value.round())),
              ),
            ),
            Row(
              children: [
                _TimeChip(label: 'الآن', value: _fmt(position)),
                const Spacer(),
                Text(
                  '${_fmt(position)} / ${_fmt(total)}',
                  style: TextStyle(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                const Spacer(),
                _TimeChip(label: 'المتبقي', value: _fmt(total - position)),
              ],
            ),
          ],
        );
      },
    );
  }

  String _fmt(Duration d) {
    if (d.isNegative) {
      d = Duration.zero;
    }
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hh = d.inHours;
    return hh > 0 ? '$hh:$mm:$ss' : '$mm:$ss';
  }
}

class _TimeChip extends StatelessWidget {
  const _TimeChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$label $value',
        style: TextStyle(
          color: cs.onSurfaceVariant,
          fontWeight: FontWeight.w700,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}
