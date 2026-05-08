import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:quranglow/features/gamification/presentation/theme/gamification_colors.dart';

class QuranJourneyPathPainter extends CustomPainter {
  QuranJourneyPathPainter({
    required this.stationCount,
    required this.completedCount,
    required this.activeIndex,
    required this.rowHeight,
    required this.animationValue,
  });

  final int stationCount;
  final int completedCount;
  final int activeIndex;
  final double rowHeight;
  final double animationValue;

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    if (width <= 0) return;

    // Draw the World/Progress Background floating islands
    _drawFloatingIslands(canvas, size);

    // Draw continuous organic wavy connecting path with progress-based gradient
    final mainPath = Path();
    final completedPath = Path();
    final activePath = Path();

    Offset lastPoint = _getNodeOffset(0, width);
    mainPath.moveTo(lastPoint.dx, lastPoint.dy);

    for (int i = 1; i < stationCount; i++) {
      final currentPoint = _getNodeOffset(i, width);
      
      // Calculate smooth organic quadratic control points
      final controlX = (lastPoint.dx + currentPoint.dx) / 2 + math.sin(i * 1.5) * 35;
      final controlY = (lastPoint.dy + currentPoint.dy) / 2;

      mainPath.quadraticBezierTo(controlX, controlY, currentPoint.dx, currentPoint.dy);

      if (i <= completedCount) {
        if (completedPath.isEmpty) completedPath.moveTo(lastPoint.dx, lastPoint.dy);
        completedPath.quadraticBezierTo(controlX, controlY, currentPoint.dx, currentPoint.dy);
      } else if (i == activeIndex + 1) {
        if (activePath.isEmpty) activePath.moveTo(lastPoint.dx, lastPoint.dy);
        activePath.quadraticBezierTo(controlX, controlY, currentPoint.dx, currentPoint.dy);
      }

      lastPoint = currentPoint;
    }

    // Determine path color theme depending on current world index
    final worldColor = _getWorldThemeColor();

    final pathPaint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final completedPathPaint = Paint()
      ..color = worldColor
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final activePathPaint = Paint()
      ..color = GameificationColors.goldAccent
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // 1. Draw locked background path
    canvas.drawPath(mainPath, pathPaint);

    // 2. Draw completed path segments
    canvas.drawPath(completedPath, completedPathPaint);

    // 3. Draw active glowing pathway segments
    if (activePath.isNotEmpty) {
      final activeGlowPaint = Paint()
        ..color = GameificationColors.goldAccent.withValues(alpha: 0.25 * (1 + math.sin(animationValue * math.pi * 2)))
        ..strokeWidth = 16
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawPath(activePath, activeGlowPaint);
      canvas.drawPath(activePath, activePathPaint);
    }

    // 4. Draw celestial/ambient stars and lanterns near path curves
    final decorationPaint = Paint()
      ..color = GameificationColors.goldLight.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    for (int i = 0; i < stationCount; i++) {
      final nodePos = _getNodeOffset(i, width);
      final double starX = nodePos.dx + (i % 2 == 0 ? 80 : -80);
      final double starY = nodePos.dy - 30;
      
      _drawStar(canvas, Offset(starX, starY), 6 + 4 * math.sin(animationValue * math.pi + i), decorationPaint);
    }
  }

  Offset _getNodeOffset(int index, double screenWidth) {
    final double x = screenWidth / 2 + math.sin(index * 0.9) * 85;
    final double y = index * rowHeight + rowHeight / 2;
    return Offset(x, y);
  }

  Color _getWorldThemeColor() {
    if (completedCount < 10) {
      return GameificationColors.primaryGreen; // Meadow of Beginning
    } else if (completedCount < 25) {
      return Colors.blueAccent; // Valley of Hope
    } else {
      return Colors.deepPurpleAccent; // Peak of Light
    }
  }

  void _drawFloatingIslands(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill;

    // Draw 3 beautiful floating islands strategically positioned in background
    for (int i = 0; i < stationCount; i += 6) {
      final isLeft = i % 12 == 0;
      final double islandX = isLeft ? 40 : size.width - 120;
      final double islandY = i * rowHeight + 100;

      final path = Path()
        ..moveTo(islandX, islandY)
        ..quadraticBezierTo(islandX + 40, islandY - 15, islandX + 80, islandY)
        ..quadraticBezierTo(islandX + 60, islandY + 20, islandX, islandY)
        ..close();

      paint.color = GameificationColors.primaryGreen.withValues(alpha: 0.04);
      canvas.drawPath(path, paint);
    }
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    for (int i = 0; i < 8; i++) {
      final angle = i * math.pi / 4;
      final double r = i % 2 == 0 ? radius : radius / 2.5;
      final double x = center.dx + r * math.cos(angle);
      final double y = center.dy + r * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(QuranJourneyPathPainter oldDelegate) {
    return oldDelegate.completedCount != completedCount ||
        oldDelegate.activeIndex != activeIndex ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.stationCount != stationCount;
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

    final centerX = size.width / 2;
    final centerY = size.height / 2;
    final radius = size.width / 3;

    for (int i = 0; i < 8; i++) {
      final angle = (i * 45) * math.pi / 180;
      final x1 = centerX + radius * math.cos(angle);
      final y1 = centerY + radius * math.sin(angle);

      final nextAngle = ((i + 1) * 45) * math.pi / 180;
      final x2 = centerX + radius * math.cos(nextAngle);
      final y2 = centerY + radius * math.sin(nextAngle);

      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
    }

    canvas.drawCircle(Offset(centerX, centerY), radius * 0.5, paint);
  }

  @override
  bool shouldRepaint(IslamicDecorationPainter oldDelegate) {
    return oldDelegate.opacity != opacity;
  }
}
