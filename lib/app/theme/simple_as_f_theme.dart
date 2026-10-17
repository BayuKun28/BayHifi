import 'package:flutter/material.dart';

/// Design tokens and styling constants for the Simple-As-F Minimalist Architecture
/// Reference: Dribbble 27089924 (Music App by Murat Ak)
abstract final class SimpleAsFTheme {
  // ─── Color Palette Tokens (Pure Solid Neutral Audiophile Darks) ───────────────
  /// Main application background: Neutral matte obsidian carbon dark
  static const Color forestCanvas = Color(0xFF0D0E12);

  /// Secondary dark canvas: Pitch black foundation for maximum contrast
  static const Color forestCanvasDark = Color(0xFF08090B);

  /// Ambient dark tone: Neutral dark depth
  static const Color forestGlow = Color(0xFF12141A);
  static const Color forestGlowAccent = Color(0xFF16181F);

  /// Primary restrained accent: Clean Studio Mint
  static const Color emeraldMint = Color(0xFF10B981);

  /// Secondary accent for highlights
  static const Color emeraldMintLight = Color(0xFF34D399);

  /// Soft dark capsule container for currently active playing track or selection
  static const Color surfaceActiveCapsule = Color(0xFF1E212B);

  /// Elevated surface for floating capsule dock and dialog cards
  static const Color surfaceElevated = Color(0xFF16181F);

  /// Deep container for unselected controls
  static const Color surfaceMuted = Color(0xFF121318);

  /// Primary text color: 100% Solid Pure White
  static const Color textWhite = Color(0xFFFFFFFF);

  /// Subtitle & metadata text color: Neutral Slate Gray
  static const Color sageSlate = Color(0xFF94A3B8);

  /// Dimmer tertiary slate for timestamps and inactive elements
  static const Color sageSlateDim = Color(0xFF64748B);

  /// Unplayed seekbar bars color
  static const Color unplayedBar = Color(0xFF252834);

  /// Ultra-subtle hairline border color: Neutral slate charcoal
  static const Color borderSubtle = Color(0xFF262936);

  // ─── Radii & Geometry Tokens ───────────────────────────────────────────────
  /// Album Art on Now Playing Screen
  static final BorderRadius squircleArtworkRadius = BorderRadius.circular(30.0);

  /// Album Cards on Home & Library Grids
  static final BorderRadius squircleCardRadius = BorderRadius.circular(20.0);

  /// Active track capsule container
  static final BorderRadius capsuleRowRadius = BorderRadius.circular(16.0);

  /// Floating dock & MiniPlayer pill
  static final BorderRadius floatingDockRadius = BorderRadius.circular(26.0);

  /// Small meta tags & buttons
  static final BorderRadius buttonPillRadius = BorderRadius.circular(999.0);

  // ─── Static Fallback BoxDecorations ────────────────────────────────────────
  /// Default active playing track capsule decoration
  static BoxDecoration activeTrackDecoration = BoxDecoration(
    color: surfaceActiveCapsule,
    borderRadius: capsuleRowRadius,
    border: Border.all(
      color: const Color(0xFF2E3242),
      width: 0.8,
    ),
  );

  /// Default squircle album art decoration with clean dark shadow
  static BoxDecoration squircleArtworkDecoration({String? imagePath}) => BoxDecoration(
    borderRadius: squircleArtworkRadius,
    color: surfaceElevated,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.45),
        blurRadius: 24.0,
        offset: const Offset(0, 12),
      ),
    ],
  );

  // ─── Dynamic Context-Aware Accessors ──────────────────────────────────────
  /// Dynamic vibrant primary accent (derived from Theme's ColorScheme)
  static Color accent(BuildContext context) =>
      Theme.of(context).colorScheme.primary;

  /// Dynamic secondary accent
  static Color accentLight(BuildContext context) =>
      Theme.of(context).colorScheme.secondary;

  /// Dynamic main background canvas
  static Color canvas(BuildContext context) =>
      Theme.of(context).scaffoldBackgroundColor;

  /// Dynamic surface color
  static Color surface(BuildContext context) =>
      Theme.of(context).colorScheme.surface;

  /// Dynamic surface container
  static Color surfaceContainer(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainer;

  /// Dynamic soft dark capsule container for active playing track
  static Color surfaceActive(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? surfaceActiveCapsule : Theme.of(context).colorScheme.surfaceContainerHighest;
  }

  /// Dynamic elevated surface color for cards and dialogs
  static Color surfaceElevatedColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? surfaceElevated : Theme.of(context).colorScheme.surfaceContainer;
  }

  /// Dynamic unplayed seekbar bar color
  static Color unplayedBarColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF252834) : const Color(0xFFCBD5E1);
  }

  /// Dynamic subtle hairline border
  static Color subtleBorder(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF262936) : Theme.of(context).colorScheme.outlineVariant;
  }

  /// Dynamic ambient dark depth
  static Color ambientGlow(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF12141A) : Colors.transparent;
  }

  /// Dynamic primary text color
  static Color textPrimary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? textWhite : Theme.of(context).colorScheme.onSurface;
  }

  /// Dynamic secondary text color
  static Color textSecondary(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? sageSlate : Theme.of(context).colorScheme.onSurfaceVariant;
  }

  /// Dynamic active playing track capsule decoration
  static BoxDecoration activeTrackCapsuleDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: isDark ? const Color(0xFF1E212B) : Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: capsuleRowRadius,
      border: Border.all(
        color: isDark ? const Color(0xFF2E3242) : Theme.of(context).colorScheme.outlineVariant,
        width: 0.8,
      ),
    );
  }

  /// Dynamic squircle card decoration
  static BoxDecoration squircleCardDecoration(
    BuildContext context, {
    BorderRadius? radius,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      borderRadius: radius ?? squircleCardRadius,
      color: isDark ? const Color(0xFF16181F) : Theme.of(context).colorScheme.surfaceContainer,
      border: Border.all(
        color: isDark ? const Color(0xFF262936) : Theme.of(context).colorScheme.outlineVariant,
        width: 0.8,
      ),
    );
  }
}
