import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../colors/app_palette.dart';

class AppTypography {
  AppTypography._();

  // Quranic Font for Ayahs
  static TextStyle quranVerse({
    double fontSize = 24.0,
    Color? color,
    double height = 2.2,
  }) {
    return GoogleFonts.amiri(
      fontSize: fontSize,
      fontWeight: FontWeight.bold,
      color: color ?? AppPalette.textPrimaryLight,
      height: height,
    );
  }

  // General App Arabic Typography
  static TextStyle headlineLarge({Color? color}) {
    return GoogleFonts.cairo(
      fontSize: 26.0,
      fontWeight: FontWeight.w700,
      color: color ?? AppPalette.textPrimaryLight,
    );
  }

  static TextStyle headlineMedium({Color? color}) {
    return GoogleFonts.cairo(
      fontSize: 20.0,
      fontWeight: FontWeight.w600,
      color: color ?? AppPalette.textPrimaryLight,
    );
  }

  static TextStyle titleMedium({Color? color}) {
    return GoogleFonts.cairo(
      fontSize: 16.0,
      fontWeight: FontWeight.w600,
      color: color ?? AppPalette.textPrimaryLight,
    );
  }

  static TextStyle bodyMedium({Color? color}) {
    return GoogleFonts.cairo(
      fontSize: 14.0,
      fontWeight: FontWeight.w400,
      color: color ?? AppPalette.textSecondaryLight,
    );
  }

  static TextStyle labelSmall({Color? color}) {
    return GoogleFonts.cairo(
      fontSize: 11.0,
      fontWeight: FontWeight.w500,
      color: color ?? AppPalette.textSecondaryLight,
    );
  }
}
