/// Custom painter for drawing curved paths between level nodes

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:quranglow/features/gamification/presentation/theme/gamification_colors.dart';

class LevelPathPainter extends CustomPainter {
  LevelPathPainter({
    required this.isCompleted,
    required this.isActive,
    required this.progress,
  });

  final bool isCompleted;
  final bool isActive;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isCompleted
          ? GameificationColors.primaryGreen
          : GameificationColors.mediumGray
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    if (isActive) {
      paint.color = GameificationColors.goldAccent;
      paint.strokeWidth = 5;
    }

    // Draw curved path
    final path = Path();
    path.moveTo(0, 0);

    // Create a smooth curve using quadratic bezier
    final controlX = size.width / 2;
    final controlY = size.height / 2;

    path.quadraticBezierTo(controlX, controlY, size.width, size.height);

    // Draw the full path
    canvas.drawPath(path, paint);

    // Draw animated progress if active
    if (isActive && progress > 0) {
      final progressPaint = Paint()
        ..color = GameificationColors.goldAccent.withValues(alpha: 0.6)
        ..strokeWidth = 6
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      final pathMetrics = path.computeMetrics();
      for (final metric in pathMetrics) {
        final extractPath = metric.extractPath(0, metric.length * progress);
        canvas.drawPath(extractPath, progressPaint);
      }
    }
  }

  @override
  bool shouldRepaint(LevelPathPainter oldDelegate) {
    return oldDelegate.isCompleted != isCompleted ||
        oldDelegate.isActive != isActive ||
        oldDelegate.progress != progress;
  }
}

class IslamicDecorationPainter extends CustomPainter {
  IslamicDecorationPainter({
    required this.opacity,
  });

  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = GameificationColors.primaryGreen.withValues(alpha: 0.1 * opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    // Draw geometric Islamic pattern
    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width / 3;

    // Draw star pattern
    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * math.pi / 180;
      final x1 = centerX + radius * math.cos(angle);
      final y1 = centerY + radius * math.sin(angle);

      final nextAngle = ((i + 1) * 45) * math.pi / 180;
      final x2 = centerX + radius * math.cos(nextAngle);
      final y2 = centerY + radius * math.sin(nextAngle);

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }

    // Draw inner circle
    canvas.drawCircle(Offset(centerX, centerY), radius * 0.5, paint);
  }

  @override
  bool shouldRepaint(IslamicDecorationPainter oldDelegate) {
    return oldDelegate.opacity != opacity;
  }
}
