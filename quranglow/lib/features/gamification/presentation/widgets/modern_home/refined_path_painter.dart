import 'package:flutter/material.dart';

class RefinedPathPainter extends CustomPainter {
  final List<Offset> offsets;
  final int activeIndex;
  final bool isDark;

  RefinedPathPainter({
    required this.offsets, 
    this.activeIndex = 0,
    this.isDark = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (offsets.length < 2) return;

    // 1. Calculate full connecting curves dynamically
    final fullPath = Path();
    final fillPath = Path();

    fullPath.moveTo(offsets[0].dx, offsets[0].dy);
    fillPath.moveTo(offsets[0].dx, offsets[0].dy);

    for (int i = 0; i < offsets.length - 1; i++) {
      final p0 = offsets[i];
      final p1 = offsets[i + 1];

      // Alternative bend direction produces nice snake flow vertically
      final double ctrlOffsetX = (i % 2 == 0) ? 50.0 : -50.0;
      final double ctrlX = (p0.dx + p1.dx) / 2 + ctrlOffsetX;
      final double ctrlY = (p0.dy + p1.dy) / 2;

      fullPath.quadraticBezierTo(ctrlX, ctrlY, p1.dx, p1.dy);

      if (i < activeIndex) {
        fillPath.quadraticBezierTo(ctrlX, ctrlY, p1.dx, p1.dy);
      }
    }

    // 2. Baseline sharp unlit track
    final basePaint = Paint()
      ..color = isDark 
          ? const Color(0xFFBDE156).withValues(alpha: 0.15) 
          : const Color(0xFF1A291D).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(fullPath, basePaint);

    // Inner guiding dash or highlight line
    final innerBasePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(fullPath, innerBasePaint);

    // 3. Sharp High-Contrast Active Track
    final activeTrackPaint = Paint()
      ..color = const Color(0xFF8DA740) // Slightly darker green wrapper
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(fillPath, activeTrackPaint);

    // 4. Bright crisp foreground neon track
    final vibrantPaint = Paint()
      ..color = const Color(0xFFD8F368) // Higher brightness 
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(fillPath, vibrantPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
