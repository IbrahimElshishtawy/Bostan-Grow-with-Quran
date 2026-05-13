import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:quranglow/core/model/prayer/prayer_times_data.dart';

class PrayerClockVisualizer extends StatefulWidget {
  const PrayerClockVisualizer({super.key, required this.data});

  final PrayerTimesData data;

  @override
  State<PrayerClockVisualizer> createState() => _PrayerClockVisualizerState();
}

class _PrayerClockVisualizerState extends State<PrayerClockVisualizer>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  late DateTime _now;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer.cancel();
    _glowController.dispose();
    super.dispose();
  }

  (DateTime prevTime, DateTime nextTime, double progress) _calculateTimes() {
    final sortedPrayers = widget.data.prayers.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    DateTime? prev;
    DateTime? next;

    for (int i = 0; i < sortedPrayers.length; i++) {
      final t = sortedPrayers[i].value;
      if (t.isAfter(_now)) {
        next = t;
        if (i > 0) {
          prev = sortedPrayers[i - 1].value;
        }
        break;
      }
    }

    // Fallbacks for rollover (after Isha or before Fajr)
    if (next == null) {
      // After Isha, next is tomorrow's Fajr.
      next = widget.data.nextPrayerTime;
      prev = sortedPrayers.last.value; // Isha today
    }
    if (prev == null) {
      // Before Fajr today, prev is yesterday's Isha.
      prev = sortedPrayers.first.value.subtract(const Duration(hours: 8));
      next = sortedPrayers.first.value; // Fajr today
    }

    final totalSecs = next.difference(prev).inSeconds;
    final elapsedSecs = _now.difference(prev).inSeconds;
    double pct = 0.0;
    if (totalSecs > 0) {
      pct = (elapsedSecs / totalSecs).clamp(0.0, 1.0);
    }

    return (prev, next, pct);
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return "00:00:00";
    final hh = d.inHours.toString().padLeft(2, '0');
    final mm = (d.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$hh:$mm:$ss";
  }

  String _arabicName(String key) {
    switch (key) {
      case 'Fajr':
        return 'الفجر';
      case 'Sunrise':
        return 'الشروق';
      case 'Dhuhr':
        return 'الظهر';
      case 'Asr':
        return 'العصر';
      case 'Maghrib':
        return 'المغرب';
      case 'Isha':
        return 'العشاء';
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final (_, nextTime, progress) = _calculateTimes();
    final remaining = nextTime.difference(_now);
    final arabicNextName = _arabicName(widget.data.nextPrayerName);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            cs.primary.withValues(alpha: 0.15),
            cs.surfaceContainerLowest.withValues(alpha: 0.10),
          ],
        ),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.08),
            blurRadius: 25,
            offset: const Offset(0, 12),
          )
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Glow effects
          AnimatedBuilder(
            animation: _glowController,
            builder: (context, child) {
              return Positioned(
                top: -40,
                right: -40,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        cs.primary.withValues(
                          alpha: 0.15 + (_glowController.value * 0.10),
                        ),
                        cs.primary.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Sleek Circular Progress
                SizedBox(
                  width: 120,
                  height: 120,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Dynamic Custom Paint Arc
                      CustomPaint(
                        size: const Size(120, 120),
                        painter: _ClockArcPainter(
                          progress: progress,
                          color: cs.primary,
                          bgColor: cs.onSurface.withValues(alpha: 0.08),
                        ),
                      ),
                      // Elegant center icon or mini info
                      Container(
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.surface,
                          boxShadow: [
                            BoxShadow(
                              color: cs.primary.withValues(alpha: 0.15),
                              blurRadius: 10,
                              spreadRadius: 1,
                            )
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            Icons.schedule_rounded,
                            color: cs.primary,
                            size: 34,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // Expanded Countdown Labels
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'الصلاة القادمة: $arabicNextName',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: cs.onSurface,
                          letterSpacing: 0.2,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'المتبقي على وقت الأذان',
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurfaceVariant,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: cs.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: cs.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.timer_outlined,
                              size: 16,
                              color: cs.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _formatDuration(remaining),
                              style: TextStyle(
                                color: cs.primary,
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'System', // Solid fixed-width font for timer
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClockArcPainter extends CustomPainter {
  _ClockArcPainter({
    required this.progress,
    required this.color,
    required this.bgColor,
  });

  final double progress;
  final Color color;
  final Color bgColor;

  @override
  void paint(Canvas canvas, Size size) {
    final strokeWidth = 10.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paintBg = Paint()
      ..color = bgColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final paintFg = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Draw static background circle
    canvas.drawCircle(center, radius, paintBg);

    // Draw dynamic active arc starting from top (-pi/2)
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweepAngle,
      false,
      paintFg,
    );

    // Draw interactive tip dot to make it premium!
    if (progress > 0) {
      final tipAngle = -math.pi / 2 + sweepAngle;
      final tipX = center.dx + radius * math.cos(tipAngle);
      final tipY = center.dy + radius * math.sin(tipAngle);

      final tipPaint = Paint()..color = color;
      final shadowPaint = Paint()
        ..color = color.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawCircle(Offset(tipX, tipY), 8, shadowPaint);
      canvas.drawCircle(Offset(tipX, tipY), 5, tipPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ClockArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.bgColor != bgColor;
  }
}
