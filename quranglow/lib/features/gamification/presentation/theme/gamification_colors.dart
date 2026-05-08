// ignore_for_file: dangling_library_doc_comments
/// Gamification color palette - Islamic minimal design
/// Colors: Green, Gold, White, Dark Navy with soft gradients


import 'package:flutter/material.dart';

class GameificationColors {
  // Primary Colors
  static const Color primaryGreen = Color(0xFF1B5E20);
  static const Color primaryGreenLight = Color(0xFF2E7D32);
  static const Color primaryGreenDark = Color(0xFF104016);

  // Accent Colors
  static const Color goldAccent = Color(0xFFD4AF37);
  static const Color goldLight = Color(0xFFE8C547);
  static const Color goldDark = Color(0xFFC9A227);

  // Neutral Colors
  static const Color white = Color(0xFFFFFFFF);
  static const Color darkNavy = Color(0xFF0B0F12);
  static const Color darkNavyLight = Color(0xFF1A1F26);
  static const Color lightGray = Color(0xFFF5F5F5);
  static const Color mediumGray = Color(0xFFE0E0E0);
  static const Color darkGray = Color(0xFF757575);

  // Status Colors
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFC107);
  static const Color error = Color(0xFFF44336);
  static const Color info = Color(0xFF2196F3);

  // Level Type Colors
  static const Color surahLevelColor = Color(0xFF1B5E20);
  static const Color tajweedLevelColor = Color(0xFFD4AF37);
  static const Color reviewLevelColor = Color(0xFF2196F3);
  static const Color bossTestColor = Color(0xFFFF6F00);
  static const Color dailyChallengeColor = Color(0xFF9C27B0);

  // Gradient Colors
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryGreen, primaryGreenLight],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [goldAccent, goldLight],
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [white, Color(0xFFF0F7F4)],
  );

  static const LinearGradient darkBackgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [darkNavyLight, darkNavy],
  );

  // Shadow definitions
  static const BoxShadow softShadow = BoxShadow(
    color: Color(0x1A000000),
    blurRadius: 8,
    offset: Offset(0, 2),
  );

  static const BoxShadow mediumShadow = BoxShadow(
    color: Color(0x26000000),
    blurRadius: 12,
    offset: Offset(0, 4),
  );

  static const BoxShadow largeShadow = BoxShadow(
    color: Color(0x33000000),
    blurRadius: 16,
    offset: Offset(0, 8),
  );

  static const List<BoxShadow> glowShadow = [
    BoxShadow(
      color: Color(0x4D1B5E20),
      blurRadius: 20,
      offset: Offset(0, 0),
    ),
  ];

  // Border radius
  static const double radiusSmall = 8;
  static const double radiusMedium = 12;
  static const double radiusLarge = 16;
  static const double radiusXLarge = 24;

  // Opacity values
  static const double opacityDisabled = 0.5;
  static const double opacityHover = 0.8;
  static const double opacityActive = 1.0;
}
