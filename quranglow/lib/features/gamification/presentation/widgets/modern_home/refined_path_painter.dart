import 'package:flutter/material.dart';

class RefinedPathPainter extends CustomPainter {
  final List<Offset> offsets;
  final int activeIndex;

  RefinedPathPainter({required this.offsets, this.activeIndex = 0});

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

    // 2. Baseline unlit track
    final basePaint = Paint()
      ..color = const Color(0xFF2E3F33).withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(fullPath, basePaint);

    // 3. Active glowing backlight neon track
    final glowPaint = Paint()
      ..color = const Color(0xFFB4D455).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0)
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(fillPath, glowPaint);

    // 4. Bright foreground neon track
    final vibrantPaint = Paint()
      ..color = const Color(0xFFBDE156)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(fillPath, vibrantPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
