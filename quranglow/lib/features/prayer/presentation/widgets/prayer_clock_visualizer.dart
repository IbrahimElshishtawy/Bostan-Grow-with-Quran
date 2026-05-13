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
  late AnimationController _pulseController;

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

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  (DateTime prevTime, String prevName, DateTime nextTime, String nextName, double progress) _calculateTimes() {
    final sortedPrayers = widget.data.prayers.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));

    DateTime? prev;
    String prevNm = '';
    DateTime? next;
    String nextNm = '';

    for (int i = 0; i < sortedPrayers.length; i++) {
      final t = sortedPrayers[i].value;
      if (t.isAfter(_now)) {
        next = t;
        nextNm = sortedPrayers[i].key;
        if (i > 0) {
          prev = sortedPrayers[i - 1].value;
          prevNm = sortedPrayers[i - 1].key;
        }
        break;
      }
    }

    // Rollovers
    if (next == null) {
      next = widget.data.nextPrayerTime;
      nextNm = widget.data.nextPrayerName;
      prev = sortedPrayers.last.value;
      prevNm = sortedPrayers.last.key;
    }
    if (prev == null) {
      prev = sortedPrayers.first.value.subtract(const Duration(hours: 8));
      prevNm = 'Isha';
      next = sortedPrayers.first.value;
      nextNm = sortedPrayers.first.key;
    }

    final totalSecs = next.difference(prev).inSeconds;
    final elapsedSecs = _now.difference(prev).inSeconds;
    double pct = 0.0;
    if (totalSecs > 0) {
      pct = (elapsedSecs / totalSecs).clamp(0.0, 1.0);
    }

    return (prev, prevNm, next, nextNm, pct);
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return "00:00:00";
    final hh = d.inHours.toString().padLeft(2, '0');
    final mm = (d.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (d.inSeconds % 60).toString().padLeft(2, '0');
    return "$hh:$mm:$ss";
  }

  String _formatHourMinute(DateTime t) {
    return "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
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
    final (prevTime, prevName, nextTime, nextName, progress) = _calculateTimes();
    final remaining = nextTime.difference(_now);
    final arabicNext = _arabicName(nextName);
    final arabicPrev = _arabicName(prevName);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            cs.primary.withValues(alpha: 0.18),
            cs.surfaceContainerHigh.withValues(alpha: 0.5),
          ],
        ),
        border: Border.all(
          color: cs.primary.withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: cs.primary.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 12),
          )
        ],
      ),
      child: Stack(
        children: [
          // Glowing decorative accent behind
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    cs.primary.withValues(alpha: 0.15),
                    cs.primary.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Title Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 14, color: cs.primary),
                    const SizedBox(width: 6),
                    Text(
                      'الوقت المتبقي للأذان القادم',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: cs.primary,
                        fontFamily: 'Tajawal',
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // 2. Hero Center Clock Visualizer
                SizedBox(
                  width: 180,
                  height: 180,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Glowing pulse ring
                      AnimatedBuilder(
                        animation: _pulseController,
                        builder: (context, child) {
                          return Container(
                            width: 166 + (14 * _pulseController.value),
                            height: 166 + (14 * _pulseController.value),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: cs.primary.withValues(alpha: 0.15 * (1.0 - _pulseController.value)),
                                width: 3,
                              ),
                            ),
                          );
                        },
                      ),
                      
                      // Dynamic Custom Painter
                      CustomPaint(
                        size: const Size(180, 180),
                        painter: _ClockArcPainter(
                          progress: progress,
                          color: cs.primary,
                          bgColor: cs.outlineVariant.withValues(alpha: 0.35),
                        ),
                      ),
                      
                      // Inner central content hub
                      Container(
                        width: 148,
                        height: 148,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: cs.surface,
                          boxShadow: [
                            BoxShadow(
                              color: cs.primary.withValues(alpha: 0.12),
                              blurRadius: 15,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _formatDuration(remaining),
                              style: TextStyle(
                                fontFamily: 'System',
                                fontSize: 24,
                                fontWeight: FontWeight.w900,
                                color: cs.onSurface,
                                letterSpacing: 0.8,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                arabicNext,
                                style: TextStyle(
                                  color: cs.onPrimaryContainer,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  fontFamily: 'Tajawal',
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 26),

                // 3. Enhanced Dual Timeline Navigation Bar
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  decoration: BoxDecoration(
                            color: cs.surface.withValues(alpha: 0.5),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.4)),
                          ),
                  child: Row(
                    children: [
                      // Previous Prayer Anchor
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'السابق: $arabicPrev',
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.onSurfaceVariant,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Tajawal',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatHourMinute(prevTime),
                              style: TextStyle(
                                fontSize: 13,
                                color: cs.onSurface,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Visual arrow separator
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Icon(Icons.arrow_forward_ios_rounded, size: 12, color: cs.primary.withValues(alpha: 0.6)),
                      ),
                      
                      // Next Prayer Anchor (Right)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'القادم: $arabicNext',
                              style: TextStyle(
                                fontSize: 11,
                                color: cs.primary,
                                fontWeight: FontWeight.w900,
                                fontFamily: 'Tajawal',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatHourMinute(nextTime),
                              style: TextStyle(
                                fontSize: 13,
                                color: cs.primary,
                                fontWeight: FontWeight.w900,
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
    final strokeWidth = 8.0;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paintBg = Paint()
      ..color = bgColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Create a beautiful gradient shader for high-fidelity progression
    final rect = Rect.fromCircle(center: center, radius: radius);
    final paintFg = Paint()
      ..strokeWidth = strokeWidth + 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..shader = SweepGradient(
        colors: [
          color.withValues(alpha: 0.2),
          color,
        ],
        stops: const [0.0, 1.0],
        transform: const GradientRotation(-math.pi / 2),
      ).createShader(rect);

    // Draw static background circle track
    canvas.drawCircle(center, radius, paintBg);

    // Draw active progress arc
    final sweepAngle = 2 * math.pi * progress;
    canvas.drawArc(
      rect,
      -math.pi / 2,
      sweepAngle,
      false,
      paintFg,
    );

    // Draw glowing tip dot at the end of progress
    if (progress > 0) {
      final tipAngle = -math.pi / 2 + sweepAngle;
      final tipX = center.dx + radius * math.cos(tipAngle);
      final tipY = center.dy + radius * math.sin(tipAngle);

      final shadowPaint = Paint()
        ..color = color.withValues(alpha: 0.4)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5);

      final tipPaint = Paint()..color = Colors.white;
      final outlinePaint = Paint()
        ..color = color
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;

      // Draw glow
      canvas.drawCircle(Offset(tipX, tipY), 9, shadowPaint);
      // Draw solid tip center
      canvas.drawCircle(Offset(tipX, tipY), 5, tipPaint);
      // Draw accent border around tip
      canvas.drawCircle(Offset(tipX, tipY), 5, outlinePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _ClockArcPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.color != color ||
        oldDelegate.bgColor != bgColor;
  }
}
