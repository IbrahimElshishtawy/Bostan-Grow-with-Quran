import 'package:flutter/material.dart';

class AppColors {
  // Primary Islamic Emerald Palette
  static const Color primary = Color(0xFF0F4C3A); // Deep Emerald
  static const Color primaryLight = Color(0xFF1B6A53);
  static const Color primaryDark = Color(0xFF082D22);
  static const Color primaryContainer = Color(0xFFD3E8DE);

  // Spiritual Gold Palette
  static const Color gold = Color(0xFFD4AF37); // Classic Islamic Gold
  static const Color goldLight = Color(0xFFF3D77B);
  static const Color goldDark = Color(0xFFA67C1E);
  static const Color goldContainer = Color(0xFFFFF7DC);

  // Neutral & Surface Palette (Light Mode)
  static const Color backgroundLight = Color(0xFFF9FAF8);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceVariantLight = Color(0xFFF0F4F2);
  static const Color textPrimaryLight = Color(0xFF1E2824);
  static const Color textSecondaryLight = Color(0xFF5D6B64);
  static const Color borderLight = Color(0xFFE2E8E5);

  // Dark Mode Palette (Rich Slate & Deep Forest)
  static const Color backgroundDark = Color(0xFF0D1412);
  static const Color surfaceDark = Color(0xFF141F1C);
  static const Color surfaceVariantDark = Color(0xFF1C2B27);
  static const Color textPrimaryDark = Color(0xFFF0F4F2);
  static const Color textSecondaryDark = Color(0xFF9EAEA7);
  static const Color borderDark = Color(0xFF263833);

  // Accent & Functional
  static const Color accent = Color(0xFF2EB872);
  static const Color accentGreen = Color(0xFF2EB872);
  static const Color error = Color(0xFFD32F2F);
  static const Color success = Color(0xFF388E3C);
  static const Color warning = Color(0xFFF57C00);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF0F4C3A), Color(0xFF1B6A53)],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  static const LinearGradient darkEmeraldGradient = LinearGradient(
    colors: [Color(0xFF082D22), Color(0xFF0F4C3A)],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  static const LinearGradient goldGradient = LinearGradient(
    colors: [Color(0xFFE5B842), Color(0xFFD4AF37), Color(0xFFA67C1E)],
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
  );

  static const LinearGradient cardOverlayGradient = LinearGradient(
    colors: [Color(0xCC0F4C3A), Color(0xE6082D22)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}

