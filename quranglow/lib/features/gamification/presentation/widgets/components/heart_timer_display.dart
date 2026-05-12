import 'dart:async';
import 'package:flutter/material.dart';
import 'package:quranglow/features/gamification/domain/models/gamification_models.dart';

class HeartTimerDisplay extends StatefulWidget {
  final UserGameProfile profile;
  final Color? textColor;
  final double fontSize;

  const HeartTimerDisplay({
    required this.profile,
    this.textColor,
    this.fontSize = 14,
    super.key,
  });

  @override
  State<HeartTimerDisplay> createState() => _HeartTimerDisplayState();
}

class _HeartTimerDisplayState extends State<HeartTimerDisplay> {
  late StreamController<String> _tickerController;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _tickerController = StreamController<String>.broadcast();
    _startTicker();
  }

  @override
  void didUpdateWidget(HeartTimerDisplay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.nextHeartRegenTime != widget.profile.nextHeartRegenTime ||
        oldWidget.profile.hearts != widget.profile.hearts) {
      _startTicker(); // Reinstate ticker if profile changed externally
    }
  }

  void _startTicker() {
    _timer?.cancel();
    _updateTime();
    
    if (widget.profile.hearts < 5 && widget.profile.nextHeartRegenTime != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTime());
    } else {
      _tickerController.add("ممتلئ"); // Full
    }
  }

  void _updateTime() {
    if (widget.profile.hearts >= 5 || widget.profile.nextHeartRegenTime == null) {
      _tickerController.add("ممتلئ");
      _timer?.cancel();
      return;
    }

    final now = DateTime.now();
    final remaining = widget.profile.nextHeartRegenTime!.difference(now);

    if (remaining.isNegative) {
      _tickerController.add("00:00");
      // Note: The GameificationController periodic logic will automatically fire 
      // shortly to tick a new heart and advance time, no need to fire manual events here.
    } else {
      final mins = remaining.inMinutes.remainder(60).toString().padLeft(2, '0');
      final secs = remaining.inSeconds.remainder(60).toString().padLeft(2, '0');
      _tickerController.add("$mins:$secs");
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tickerController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final effectiveTextColor = widget.textColor ?? Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.8);

    return StreamBuilder<String>(
      stream: _tickerController.stream,
      initialData: "...",
      builder: (context, snapshot) {
        final text = snapshot.data ?? "";
        final isFull = text == "ممتلئ";

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.favorite_rounded, 
              color: Colors.redAccent, 
              size: widget.fontSize + 4
            ),
            const SizedBox(width: 5),
            Text(
              '${widget.profile.hearts}/5',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: widget.textColor ?? Colors.redAccent,
                fontSize: widget.fontSize,
              ),
            ),
            if (!isFull) ...[
              const SizedBox(width: 8),
              Container(
                width: 1,
                height: widget.fontSize,
                color: effectiveTextColor.withValues(alpha: 0.3),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.timer_outlined,
                size: widget.fontSize,
                color: effectiveTextColor,
              ),
              const SizedBox(width: 4),
              Text(
                text,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: widget.fontSize - 1,
                  color: effectiveTextColor,
                  fontFamily: 'monospace', // monospaced for ticker stability
                ),
              ),
            ]
          ],
        );
      },
    );
  }
}
