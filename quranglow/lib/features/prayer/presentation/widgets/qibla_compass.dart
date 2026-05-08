/// Animated Qibla Compass Widget
import 'package:flutter/material.dart';
import 'dart:math' as math;

class QiblaCompass extends StatefulWidget {
  /// Current device heading in degrees (0-360)
  final double deviceHeading;

  /// Direction to Qibla in degrees (0-360)
  final double qiblaDirection;

  /// Whether user is facing Qibla
  final bool isFacingQibla;

  /// Compass size
  final double size;

  const QiblaCompass({
    super.key,
    required this.deviceHeading,
    required this.qiblaDirection,
    required this.isFacingQibla,
    this.size = 280,
  });

  @override
  State<QiblaCompass> createState() => _QiblaCompassState();
}

class _QiblaCompassState extends State<QiblaCompass>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(QiblaCompass oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.deviceHeading != widget.deviceHeading) {
      _animationController.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.teal.shade100,
            Colors.teal.shade50,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.teal.withOpacity(0.3),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          final angle = widget.deviceHeading * (math.pi / 180);

          return Stack(
            alignment: Alignment.center,
            children: [
              // Outer circle with graduation marks
              CustomPaint(
                painter: CompassPainter(
                  deviceHeading: widget.deviceHeading,
                ),
                size: Size(widget.size, widget.size),
              ),

              // Qibla indicator needle (from center)
              Transform.rotate(
                angle: (widget.qiblaDirection - widget.deviceHeading) *
                    (math.pi / 180),
                child: Padding(
                  padding: EdgeInsets.only(top: widget.size / 4),
                  child: Container(
                    width: 4,
                    height: widget.size / 4,
                    decoration: BoxDecoration(
                      color: Colors.amber.shade600,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.6),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Center dot
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.amber.shade600,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.6),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),

              // Status indicator
              if (widget.isFacingQibla)
                Positioned(
                  top: 20,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade400,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: const Text(
                      'Facing Qibla ✓',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class CompassPainter extends CustomPainter {
  final double deviceHeading;

  CompassPainter({required this.deviceHeading});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.teal.shade800
      ..strokeWidth = 2;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    // Draw cardinal directions
    _drawDirection(canvas, center, radius, 'N', 0, 12, size, paint);
    _drawDirection(canvas, center, radius, 'E', 90, 12, size, paint);
    _drawDirection(canvas, center, radius, 'S', 180, 12, size, paint);
    _drawDirection(canvas, center, radius, 'W', 270, 12, size, paint);

    // Draw graduation marks
    for (int i = 0; i < 360; i += 10) {
      final angle = (i - deviceHeading) * (math.pi / 180);
      final startRadius = radius - 15;
      final endRadius = radius - 5;

      final startPoint = Offset(
        center.dx + startRadius * math.sin(angle),
        center.dy - startRadius * math.cos(angle),
      );

      final endPoint = Offset(
        center.dx + endRadius * math.sin(angle),
        center.dy - endRadius * math.cos(angle),
      );

      canvas.drawLine(startPoint, endPoint, paint);
    }
  }

  void _drawDirection(Canvas canvas, Offset center, double radius,
      String direction, double angle, double fontSize, Size size, Paint paint) {
    final angleRad = (angle - deviceHeading) * (math.pi / 180);
    final offset = Offset(
      center.dx + (radius - 25) * math.sin(angleRad),
      center.dy - (radius - 25) * math.cos(angleRad),
    );

    final textPainter = TextPainter(
      text: TextSpan(
        text: direction,
        style: TextStyle(
          color: Colors.teal.shade900,
          fontSize: fontSize,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      offset - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }

  @override
  bool shouldRepaint(CompassPainter oldDelegate) {
    return oldDelegate.deviceHeading != deviceHeading;
  }
}
