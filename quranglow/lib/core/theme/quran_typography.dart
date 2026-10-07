import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuranTypography {
  QuranTypography._();

  /// Dedicated text style for Quranic text (using Amiri / Uthmanic style)
  static TextStyle ayahText({
    double fontSize = 24.0,
    Color? color,
    FontWeight fontWeight = FontWeight.normal,
    double height = 2.1,
  }) {
    return GoogleFonts.amiri(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: height,
    );
  }

  /// Style for Surah Titles and Headers
  static TextStyle surahTitle({
    double fontSize = 22.0,
    Color? color,
    FontWeight fontWeight = FontWeight.bold,
  }) {
    return GoogleFonts.amiri(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
    );
  }

  /// Basmalah style
  static TextStyle basmalah({
    double fontSize = 20.0,
    Color? color,
  }) {
    return GoogleFonts.amiri(
      fontSize: fontSize,
      fontWeight: FontWeight.w600,
      color: color,
    );
  }

  /// Translation text style
  static TextStyle translationText({
    double fontSize = 15.0,
    Color? color,
    double height = 1.6,
  }) {
    return GoogleFonts.tajawal(
      fontSize: fontSize,
      fontWeight: FontWeight.normal,
      color: color,
      height: height,
    );
  }

  /// Tafsir text style
  static TextStyle tafsirText({
    double fontSize = 16.0,
    Color? color,
    double height = 1.8,
  }) {
    return GoogleFonts.tajawal(
      fontSize: fontSize,
      fontWeight: FontWeight.normal,
      color: color,
      height: height,
    );
  }
}
