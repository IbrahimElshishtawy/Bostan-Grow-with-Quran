import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ActiveLevelFooter extends StatelessWidget {
  final VoidCallback onStart;
  final int currentLevel;
  final String levelDetails;

  const ActiveLevelFooter({
    super.key,
    required this.onStart,
    required this.currentLevel,
    required this.levelDetails,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  const Color(0xFF1A3225).withValues(alpha: 0.95),
                  const Color(0xFF101D16).withValues(alpha: 0.95),
                ]
              : [
                  Colors.white.withValues(alpha: 0.98),
                  const Color(0xFFF9FDF4),
                ],
        ),
        borderRadius: BorderRadius.circular(28), // Softer elegance
        border: Border.all(
          color: isDark 
              ? const Color(0xFFBDE156).withValues(alpha: 0.3)
              : const Color(0xFF8DA740).withValues(alpha: 0.25),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark 
                ? Colors.black.withValues(alpha: 0.35)
                : const Color(0xFF1A3225).withValues(alpha: 0.15),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          // The Animated Dynamic Action Button
          GestureDetector(
            onTap: onStart,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFBDE156), Color(0xFF8DA740)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFBDE156).withValues(alpha: 0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Text(
                'ابدأ الآن',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1A3225),
                  fontSize: 17,
                  letterSpacing: 0.3,
                ),
              ),
            ).animate(onPlay: (c) => c.repeat(reverse: true))
             .scale(duration: 1.seconds, begin: const Offset(1,1), end: const Offset(1.04,1.04), curve: Curves.easeInOutSine)
             .shimmer(duration: 3.seconds, color: Colors.white.withValues(alpha: 0.3)),
          ),
          
          const Spacer(),

          // Content detail labels
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'مستوى $currentLevel نشط',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1A3225),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                levelDetails,
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? Colors.white.withValues(alpha: 0.75) : const Color(0xFF1A3225).withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          
          // Animated Audio/Play indicator icon
          Icon(
            Icons.play_circle_fill_rounded,
            color: isDark ? const Color(0xFFBDE156) : const Color(0xFF8DA740),
            size: 44,
          ).animate(onPlay: (c) => c.repeat(reverse: true))
           .scale(duration: 1.2.seconds, begin: const Offset(0.95, 0.95), end: const Offset(1.05, 1.05)),
        ],
      ),
    ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.3, end: 0, curve: Curves.easeOutBack);
  }
}
