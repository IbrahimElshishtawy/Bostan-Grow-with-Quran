import 'package:flutter/material.dart';
import '../colors/app_palette.dart';
import '../radius/app_radius.dart';

class AppThemeData {
  AppThemeData._();

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppPalette.primary,
      scaffoldBackgroundColor: AppPalette.backgroundLight,
      colorScheme: const ColorScheme.light(
        primary: AppPalette.primary,
        secondary: AppPalette.gold,
        surface: AppPalette.surfaceLight,
        error: AppPalette.error,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: AppPalette.textPrimaryLight,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppPalette.surfaceLight,
        foregroundColor: AppPalette.textPrimaryLight,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: const CardThemeData(
        color: AppPalette.surfaceLight,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedL),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: AppPalette.primaryLight,
      scaffoldBackgroundColor: AppPalette.backgroundDark,
      colorScheme: const ColorScheme.dark(
        primary: AppPalette.primaryLight,
        secondary: AppPalette.gold,
        surface: AppPalette.surfaceDark,
        error: AppPalette.error,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: AppPalette.textPrimaryDark,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppPalette.surfaceDark,
        foregroundColor: AppPalette.textPrimaryDark,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: const CardThemeData(
        color: AppPalette.surfaceDark,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.roundedL),
      ),
    );
  }
}
