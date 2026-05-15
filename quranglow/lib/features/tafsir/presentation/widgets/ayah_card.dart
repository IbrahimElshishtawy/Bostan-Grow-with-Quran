import 'package:flutter/material.dart';

class AyahCard extends StatelessWidget {
  const AyahCard({
    super.key,
    required this.surahName,
    required this.ayah,
    required this.ayahText,
  });

  final String surahName;
  final int ayah;
  final String ayahText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final Color cardBg = isDark ? const Color(0xFF1E2F26) : const Color(0xFFF6FAF7);
    final Color borderColor = isDark ? Colors.white10 : const Color(0xFFD4AF37).withValues(alpha: 0.2);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Subtle Islamic corner decoration could go here if assets exist
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFD4AF37).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFD4AF37).withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        '$surahName • الآية $ayah',
                        style: TextStyle(
                          color: isDark ? const Color(0xFFF1D486) : const Color(0xFF996515),
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          fontFamily: 'Tajawal',
                        ),
                      ),
                    ),
                    Icon(
                      Icons.format_quote_rounded,
                      color: const Color(0xFFD4AF37).withValues(alpha: 0.3),
                      size: 28,
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  ayahText.isEmpty ? 'لا يوجد نص للآية.' : ayahText,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    height: 1.8,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'KFGQPC Uthmanic Script', // Using the Quran font
                    color: isDark ? Colors.white.withValues(alpha: 0.95) : const Color(0xFF1B3B2B),
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
