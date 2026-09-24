import 'package:flutter/material.dart';

/// Standar tipografi Baydev HiFi dengan dukungan Tabular Figures untuk nilai audio.
class AppTypography {
  AppTypography._();

  static const List<FontFeature> audioFigures = [
    FontFeature.tabularFigures(),
    FontFeature.slashedZero(),
  ];

  static TextStyle display(Color color) => TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        letterSpacing: -0.5,
        color: color,
      );

  static TextStyle title(Color color) => TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
        color: color,
      );

  static TextStyle subtitle(Color color) => TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: color,
      );

  static TextStyle body(Color color) => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.normal,
        color: color,
      );

  /// Tipografi khusus angka audio (Hz, dB, Q, bit-depth) agar tidak jitter/bergetar saat nilainya berubah
  static TextStyle audioValue({
    required Color color,
    double fontSize = 12,
    FontWeight fontWeight = FontWeight.w600,
  }) =>
      TextStyle(
        fontSize: fontSize,
        fontWeight: fontWeight,
        fontFeatures: audioFigures,
        color: color,
      );

  static TextStyle badge({
    required Color color,
    double fontSize = 10,
  }) =>
      TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        letterSpacing: 0.5,
        fontFeatures: audioFigures,
        color: color,
      );
  static TextTheme textTheme({required bool isDark}) {
    final color = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final secondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    return TextTheme(
      displayLarge: display(color),
      titleLarge: title(color),
      titleMedium: subtitle(color),
      bodyLarge: body(color),
      bodyMedium: body(secondary),
    );
  }
}
