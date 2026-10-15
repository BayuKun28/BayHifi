import 'package:flutter/material.dart';

/// Design tokens and styling constants for the Simple-As-F Minimalist Architecture
/// Reference: Dribbble 27089924 (Music App by Murat Ak)
abstract final class SimpleAsFTheme {
  // ─── Color Palette Tokens ──────────────────────────────────────────────────
  /// Main application background: Deep obsidian forest dark
  static const Color forestCanvas = Color(0xFF0B110E);

  /// Secondary dark canvas: Slightly lighter obsidian green for contrast
  static const Color forestCanvasDark = Color(0xFF0E1713);

  /// Ambient radial glow color: Used in canvas corners for soft organic depth
  static const Color forestGlow = Color(0xFF12231A);
  static const Color forestGlowAccent = Color(0xFF162E22);

  /// Primary vibrant accent: Organic Emerald Mint
  static const Color emeraldMint = Color(0xFF2EE672);

  /// Lighter tint of Emerald Mint for subtle highlights
  static const Color emeraldMintLight = Color(0xFF4ADE80);

  /// Soft dark capsule container for currently active playing track or selection
  static const Color surfaceActiveCapsule = Color(0xFF16241C);

  /// Elevated surface for floating capsule dock and dialog cards
  static const Color surfaceElevated = Color(0xFF141F18);

  /// Deep container for unselected controls
  static const Color surfaceMuted = Color(0xFF131D17);

  /// Primary text color: 100% Solid Pure White
  static const Color textWhite = Color(0xFFFFFFFF);

  /// Subtitle & metadata text color: Muted Sage Slate
  static const Color sageSlate = Color(0xFF8A9A90);

  /// Dimmer tertiary slate for timestamps and inactive elements
  static const Color sageSlateDim = Color(0xFF5A6B61);

  /// Unplayed seekbar bars color
  static const Color unplayedBar = Color(0xFF23352B);

  /// Ultra-subtle hairline border color
  static const Color borderSubtle = Color(0x1F2EE672);

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
      color: emeraldMint.withValues(alpha: 0.15),
      width: 1.0,
    ),
  );

  /// Default squircle album art decoration with soft dark drop shadow
  static BoxDecoration squircleArtworkDecoration({String? imagePath}) => BoxDecoration(
    borderRadius: squircleArtworkRadius,
    color: surfaceElevated,
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.5),
        blurRadius: 32.0,
        offset: const Offset(0, 16),
        spreadRadius: -4,
      ),
      BoxShadow(
        color: forestGlow.withValues(alpha: 0.3),
        blurRadius: 24.0,
        offset: const Offset(0, 8),
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
  static Color surfaceActive(BuildContext context) =>
      Theme.of(context).colorScheme.surfaceContainer;

  /// Dynamic unplayed seekbar bar color
  static Color unplayedBarColor(BuildContext context) =>
      Color.alphaBlend(
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
        Theme.of(context).scaffoldBackgroundColor,
      );

  /// Dynamic subtle hairline border
  static Color subtleBorder(BuildContext context) =>
      Theme.of(context).colorScheme.primary.withValues(alpha: 0.18);

  /// Dynamic ambient radial glow color
  static Color ambientGlow(BuildContext context) =>
      Color.alphaBlend(
        Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
        Theme.of(context).scaffoldBackgroundColor,
      );

  /// Dynamic active playing track capsule decoration
  static BoxDecoration activeTrackCapsuleDecoration(BuildContext context) =>
      BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: capsuleRowRadius,
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.20),
          width: 1.0,
        ),
      );

  /// Dynamic squircle card decoration
  static BoxDecoration squircleCardDecoration(
    BuildContext context, {
    BorderRadius? radius,
  }) =>
      BoxDecoration(
        borderRadius: radius ?? squircleCardRadius,
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.25),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16.0,
            offset: const Offset(0, 8),
          ),
        ],
      );
}
