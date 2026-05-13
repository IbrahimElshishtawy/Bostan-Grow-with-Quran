import 'package:flutter/material.dart';

class StationSectionHeader extends StatelessWidget {
  final int stationNumber;

  const StationSectionHeader({
    super.key,
    required this.stationNumber,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final title = 'المحطة $stationNumber';
    final subtitle = 'المرحلة القادمة من رحلة النور';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark 
            ? [
                const Color(0xFF1A3022).withValues(alpha: 0.9),
                const Color(0xFF121E16).withValues(alpha: 0.95),
              ]
            : [
                Colors.white.withValues(alpha: 0.98),
                const Color(0xFFF5F8ED),
              ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFBDE156).withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.4) : const Color(0xFF1A3022).withValues(alpha: 0.15),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(
              color: const Color(0xFFBDE156).withValues(alpha: isDark ? 0.2 : 0.25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFBDE156).withValues(alpha: isDark ? 0.3 : 0.5)),
            ),
            child: const Icon(
              Icons.flag_circle_rounded,
              color: Color(0xFF8DA740), // Stronger darker green icon always readable
              size: 32,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: isDark ? Colors.white : const Color(0xFF1A3022),
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white.withValues(alpha: 0.65) : const Color(0xFF1A3022).withValues(alpha: 0.6),
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
