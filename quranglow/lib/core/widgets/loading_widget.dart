import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;

class LoadingWidget extends StatelessWidget {
  final String? message;
  final Color? color;
  final double size;

  const LoadingWidget({
    super.key,
    this.message,
    this.color,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).primaryColor;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: size + 30,
            height: size + 30,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 💫 Layer 1: Outer Glowing Ring
                Container(
                  width: size + 20,
                  height: size + 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: effectiveColor.withValues(alpha: 0.15),
                      width: 1,
                    ),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true))
                 .scaleXY(begin: 1.0, end: 1.1, duration: 1.seconds, curve: Curves.easeInOut),

                // 🌀 Layer 2: Rotating Gradient Arc
                SizedBox(
                  width: size,
                  height: size,
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(effectiveColor),
                    strokeWidth: 3,
                    backgroundColor: effectiveColor.withValues(alpha: 0.05),
                  ),
                ).animate(onPlay: (c) => c.repeat())
                 .rotate(duration: 1.2.seconds, curve: Curves.easeInOutCubic),

                // ⚛️ Layer 3: Inner Rotating Geometric Shape
                Transform.rotate(
                  angle: math.pi / 4,
                  child: Container(
                    width: size * 0.55,
                    height: size * 0.55,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.grey[900] : Colors.white,
                      borderRadius: BorderRadius.circular(size * 0.15),
                      boxShadow: [
                        BoxShadow(
                          color: effectiveColor.withValues(alpha: 0.3),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.spa_rounded, // Abstract Islamic/Nature brand icon
                      color: effectiveColor,
                      size: size * 0.35,
                    ),
                  ),
                ).animate(onPlay: (c) => c.repeat(reverse: true))
                 .rotate(begin: 0, end: math.pi / 2, duration: 2.seconds, curve: Curves.easeInOutQuad),
              ],
            ),
          ),
          const SizedBox(height: 20),
          
          // ✍️ Layer 4: Elegantly Shimmering Text
          Text(
            message ?? 'جاري التحميل...',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              letterSpacing: 0.5,
            ),
          ).animate(onPlay: (c) => c.repeat())
           .shimmer(
             duration: 2.seconds,
             color: effectiveColor.withValues(alpha: 0.3),
           )
           .fade(begin: 0.7, end: 1.0, duration: 800.ms, curve: Curves.easeInOut),
        ],
      ),
    );
  }
}
