import 'package:flutter/material.dart';

/// Palet warna resmi Baydev HiFi — Material 3 Expressive Studio Aesthetic.
class AppColors {
  AppColors._();

  // Backgrounds & Surfaces (Studio Obsidian)
  static const Color background = Color(0xFF0D0F12);
  static const Color surface = Color(0xFF14171D);
  static const Color surfaceContainer = Color(0xFF1C2028);
  static const Color surfaceContainerHigh = Color(0xFF242A35);
  static const Color surfaceContainerHighest = Color(0xFF2D3442);
  static const Color surfaceBorder = Color(0xFF2E3544);

  // Audiophile Neon & Curve Accents
  static const Color amberEq = Color(0xFFFF9F0A);       // — EQ line glowing amber
  static const Color cyanDriver = Color(0xFF00E5FF);     // -- Driver FR dashed cyan
  static const Color mintTarget = Color(0xFF00FFA3);     // -- Target FR dashed mint
  static const Color rtaBar = Color(0xFF38BDF8);         // — RTA spectrum visualizer
  static const Color purpleActive = Color(0xFFBF5AF2);   // Selected band halo
  static const Color emeraldApply = Color(0xFF10B981);   // Apply to DSP button
  static const Color crimsonAlert = Color(0xFFFF453A);   // Peak clipping warning
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // 7 Frequency Band Zone Colors (Studio Reference)
  static const Color zoneSubBass = Color(0xFFFF453A);       // 20 - 60 Hz
  static const Color zoneMidBass = Color(0xFFFF9F0A);       // 60 - 250 Hz
  static const Color zoneLowerMid = Color(0xFF30D158);      // 250 - 500 Hz
  static const Color zoneUpperMid = Color(0xFF64D2FF);      // 500 - 2k Hz
  static const Color zonePresence = Color(0xFF0A84FF);      // 2k - 4k Hz
  static const Color zoneMidTreble = Color(0xFFBF5AF2);     // 4k - 10k Hz
  static const Color zoneAir = Color(0xFFFF375F);           // 10k - 20k Hz

  // Preset Palettes
  static const List<Color> curatedAccents = [
    amberEq,
    cyanDriver,
    mintTarget,
    purpleActive,
    emeraldApply,
    Color(0xFFFF2D55), // Hot Pink
    Color(0xFFFFD60A), // HiFi Gold
  ];
}
