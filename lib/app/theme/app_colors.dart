import 'package:flutter/material.dart';

/// Palet warna resmi Baydev HiFi — Material 3 Expressive Studio Aesthetic (Non-Neon, Restrained Tones).
class AppColors {
  AppColors._();

  // Backgrounds & Surfaces (Obsidian Forest - Simple-As-F Dribbble 27089924)
  static const Color background = Color(0xFF0B110E);
  static const Color surface = Color(0xFF101914);
  static const Color surfaceContainer = Color(0xFF16241C);
  static const Color surfaceContainerHigh = Color(0xFF1C2C23);
  static const Color surfaceContainerHighest = Color(0xFF24362B);
  static const Color surfaceBorder = Color(0xFF1D3326);
  static const Color emeraldMint = Color(0xFF2EE672);

  // Audiophile Studio Curve Accents (Non-Neon)
  static const Color amberEq = Color(0xFFF59E0B);       // EQ line warm amber
  static const Color cyanDriver = Color(0xFF38BDF8);    // Driver FR sky blue
  static const Color mintTarget = Color(0xFF10B981);    // Target FR soft emerald
  static const Color rtaBar = Color(0xFF0284C7);        // RTA spectrum visualizer
  static const Color purpleActive = Color(0xFFA855F7);  // Selected band studio violet
  static const Color emeraldApply = Color(0xFF059669);  // Apply to DSP button
  static const Color crimsonAlert = Color(0xFFF43F5E);  // Peak clipping warning
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);

  // 7 Frequency Band Zone Colors (Studio Reference)
  static const Color zoneSubBass = Color(0xFFF43F5E);       // 20 - 60 Hz
  static const Color zoneMidBass = Color(0xFFF59E0B);       // 60 - 250 Hz
  static const Color zoneLowerMid = Color(0xFF10B981);      // 250 - 500 Hz
  static const Color zoneUpperMid = Color(0xFF38BDF8);      // 500 - 2k Hz
  static const Color zonePresence = Color(0xFF6366F1);      // 2k - 4k Hz
  static const Color zoneMidTreble = Color(0xFFA855F7);     // 4k - 10k Hz
  static const Color zoneAir = Color(0xFFEC4899);           // 10k - 20k Hz

  // Preset Palettes
  static const List<Color> curatedAccents = [
    amberEq,
    cyanDriver,
    mintTarget,
    purpleActive,
    emeraldApply,
    Color(0xFFE11D48), // Rose Crimson
    Color(0xFFEAB308), // HiFi Gold
  ];
}
