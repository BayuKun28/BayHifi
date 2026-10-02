import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme_mode_controller.dart';

/// Studio Surface & Component Theming Utility
/// Resolves container colors, tinted accents, and surfaces based on [SurfaceFillStyle].
class StudioSurfaceTheme {
  const StudioSurfaceTheme._();

  /// Resolves the primary container color (for cards, bento modules, sheets).
  static Color surfaceContainer(
    BuildContext context, {
    bool isSolid = false,
    double translucentAlpha = 0.85,
  }) {
    final theme = Theme.of(context);
    return isSolid
        ? theme.colorScheme.surfaceContainer
        : theme.colorScheme.surfaceContainer.withValues(alpha: translucentAlpha);
  }

  /// Resolves a higher elevation container color (for nested cards, input fields).
  static Color surfaceContainerHigh(
    BuildContext context, {
    bool isSolid = false,
    double translucentAlpha = 0.90,
  }) {
    final theme = Theme.of(context);
    return isSolid
        ? theme.colorScheme.surfaceContainerHighest
        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: translucentAlpha);
  }

  /// Resolves a lower elevation container color (for inner sub-cards, nested lists).
  static Color surfaceContainerLow(
    BuildContext context, {
    bool isSolid = false,
    double translucentAlpha = 0.70,
  }) {
    final theme = Theme.of(context);
    return isSolid
        ? theme.colorScheme.surfaceContainerLow
        : theme.colorScheme.surfaceContainerLow.withValues(alpha: translucentAlpha);
  }

  /// Resolves the base surface color (e.g. for modal sheets, dialog backgrounds).
  static Color surface(
    BuildContext context, {
    bool isSolid = false,
    double translucentAlpha = 0.90,
  }) {
    final theme = Theme.of(context);
    return isSolid
        ? theme.colorScheme.surface
        : theme.colorScheme.surface.withValues(alpha: translucentAlpha);
  }

  /// Resolves an accent-tinted container color (for badges, active pills, indicators).
  /// In Solid mode: blends [tintColor] into [surfaceContainer] with rich tonal depth (100% opaque).
  /// In Translucent mode: returns a subtle transparent [tintColor] with [translucentAlpha].
  static Color tintedContainer(
    BuildContext context,
    Color tintColor, {
    bool isSolid = false,
    double translucentAlpha = 0.14,
    double solidBlendAlpha = 0.20,
  }) {
    final theme = Theme.of(context);
    if (!isSolid) {
      return tintColor.withValues(alpha: translucentAlpha);
    }
    return Color.alphaBlend(
      tintColor.withValues(alpha: solidBlendAlpha),
      theme.colorScheme.surfaceContainer,
    );
  }

  /// Resolves border outline color (transparent for pure borderless studio design).
  static Color outline(
    BuildContext context, {
    bool isSolid = false,
    double translucentAlpha = 0.0,
  }) {
    return Colors.transparent;
  }

  /// Resolves subtle border outline color for nested containers (transparent).
  static Color subtleOutline(
    BuildContext context, {
    bool isSolid = false,
    double translucentAlpha = 0.0,
  }) {
    return Colors.transparent;
  }

  /// Standard card box decoration helper conforming to M3 Expressive Studio Bento layout (borderless by default).
  static BoxDecoration cardDecoration({
    required BuildContext context,
    bool isSolid = false,
    double radius = 20,
    Color? borderColor,
    Color? backgroundColor,
    double borderWidth = 1.0,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? surfaceContainer(context, isSolid: isSolid),
      borderRadius: BorderRadius.circular(radius),
      border: borderColor != null
          ? Border.all(color: borderColor, width: borderWidth)
          : null,
      boxShadow: shadows ??
          (isSolid
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.14),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null),
    );
  }
}

/// Studio Semantic & Category Colors
/// Provides dedicated, vibrant visual identities for audio components, telemetry,
/// hardware engines, cloud services, and DSP units independent of single-accent palettes.
class StudioCategoryColors {
  const StudioCategoryColors._();

  // ─── Audio Engine & Hardware ──────────────────────────────────────────
  static const Color audioEngine = Color(0xFFF59E0B); // Amber Tube
  static const Color audioEngineSoloud = Color(0xFFF59E0B);
  static const Color audioHardware = Color(0xFF84CC16); // Lime Mint DAC
  static const Color bitPerfect = Color(0xFF10B981); // Precision Emerald

  // ─── DSP & Mastering Hardware ──────────────────────────────────────────
  static const Color dspMastering = Color(0xFF10B981); // Hardware Mint
  static const Color dspTubeWarmth = Color(0xFFF59E0B); // Triode Amber
  static const Color warmTubeAmber = Color(0xFFF59E0B); // Studio Tube Amber
  static const Color proQEqualizer = Color(0xFF06B6D4); // Precision Cyan
  static const Color autoEq = Color(0xFF14B8A6); // Acoustic Teal
  static const Color compressor = Color(0xFFF97316); // Dynamic Orange
  static const Color dspCompressor = Color(0xFFF97316);
  static const Color limiter = Color(0xFFEF4444); // Brickwall Red
  static const Color dspLimiter = Color(0xFFEF4444);

  // ─── Media, Streaming & Cloud ──────────────────────────────────────────
  static const Color youtubeMusic = Color(0xFFFF4B4B); // YouTube Coral Red
  static const Color spotifyGreen = Color(0xFF1DB954); // Spotify Emerald Green
  static const Color cloudNavidrome = Color(0xFF0284C7); // Azure Cloud
  static const Color navidromeAzure = Color(0xFF0284C7);
  static const Color storageCache = Color(0xFF6366F1); // Electric Indigo
  static const Color storageIndigo = Color(0xFF6366F1);
  static const Color libraryScanner = Color(0xFFF97316); // Sunset Orange
  static const Color lyricsShare = Color(0xFFEC4899); // Magenta Rose
  static const Color lyricsMagenta = Color(0xFFEC4899);

  // ─── Audiophile Formats & Telemetry ────────────────────────────────────
  static const Color hiResGold = Color(0xFFEAB308); // Lossless Gold
  static const Color flacLossless = Color(0xFF10B981); // Studio Mint
  static const Color wavPcm = Color(0xFF0284C7); // Pure PCM Sky
  static const Color opusStream = Color(0xFFFF6B6B); // Stream Coral

  // ─── System & Workstation ──────────────────────────────────────────────
  static const Color statistics = Color(0xFF8B5CF6); // Royal Violet
  static const Color visualizer = Color(0xFFF43F5E); // Radiant Rose
  static const Color dockingDesk = Color(0xFFF59E0B); // Cockpit Amber
  static const Color gestures = Color(0xFFFB923C); // Warm Sunset
  static const Color backupVault = Color(0xFF059669); // Emerald Vault
  static const Color themingPalettes = Color(0xFFA855F7); // Studio Violet
  static const Color sleepTimer = Color(0xFF6366F1); // Night Indigo

  /// Helper to create a vibrant tinted container decoration for category icons and badges
  static BoxDecoration pillDecoration({
    required BuildContext context,
    required Color color,
    bool isSolid = false,
    double radius = 8,
    double alpha = 0.16,
  }) {
    return BoxDecoration(
      color: color.withValues(alpha: isSolid ? 0.18 : alpha),
      borderRadius: BorderRadius.circular(radius),
    );
  }
}

/// Convenience extension on [WidgetRef] to check if solid style is active.
extension SurfaceStyleRefExtension on WidgetRef {
  bool get isSolidStyle =>
      watch(themeControllerProvider.select((s) => s.isSolidStyle));

  SurfaceFillStyle get surfaceFillStyle =>
      watch(themeControllerProvider.select((s) => s.effectiveSurfaceFillStyle));
}

