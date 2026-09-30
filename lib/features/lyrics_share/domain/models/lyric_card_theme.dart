import 'package:flutter/material.dart';

/// Supported card layout aspect ratios for social sharing
enum LyricCardRatio {
  story_9_16('Story (9:16)', 9 / 16, 1080, 1920),
  portrait_4_5('Portrait (4:5)', 4 / 5, 1080, 1350),
  square_1_1('Square (1:1)', 1 / 1, 1080, 1080),
  landscape_16_9('Landscape (16:9)', 16 / 9, 1920, 1080);

  final String label;
  final double aspectRatio;
  final double renderWidth;
  final double renderHeight;

  const LyricCardRatio(
    this.label,
    this.aspectRatio,
    this.renderWidth,
    this.renderHeight,
  );
}

/// Supported font families for lyric typography
enum LyricCardFontFamily {
  sans('Studio Sans', null),
  serif('Editorial Serif', 'serif'),
  monospace('Studio Mono', 'monospace'),
  cursive('Script Flow', 'cursive');

  final String label;
  final String? fontFamily;

  const LyricCardFontFamily(this.label, this.fontFamily);
}

/// Background visual styling mode for the lyric card
enum LyricCardBackgroundMode {
  blurredArtwork('Blurred Cover'),
  albumPalette('Cover Palette'),
  studioPreset('Studio Theme'),
  customColor('Custom Color');

  final String label;

  const LyricCardBackgroundMode(this.label);
}

/// Curated Studio Aesthetic Theme Presets for Lyric Cards
enum LyricCardThemePreset {
  dynamicAlbumArt('Dynamic Album', 'Auto-matched to artwork colors'),
  studioOledBlack('Studio OLED', 'Pure deep black with crisp studio white'),
  precisionMint('Precision Mint', 'Audiophile emerald & sage studio palette'),
  skyStudio('Sky Studio', 'Deep navy with arctic sky accents'),
  warmAmber('Warm Tube', 'Analog tube glow amber palette'),
  mutedRose('Studio Rose', 'Refined acoustic mauve & muted rose');

  final String label;
  final String description;

  const LyricCardThemePreset(this.label, this.description);
}

/// Resolved concrete color palette for rendering the lyric card canvas
class LyricCardColors {
  final Color backgroundColor;
  final Color surfaceColor;
  final Color primaryTextColor;
  final Color secondaryTextColor;
  final Color accentColor;
  final Color borderColor;
  final Color badgeBackgroundColor;
  final Color badgeTextColor;

  const LyricCardColors({
    required this.backgroundColor,
    required this.surfaceColor,
    required this.primaryTextColor,
    required this.secondaryTextColor,
    required this.accentColor,
    required this.borderColor,
    required this.badgeBackgroundColor,
    required this.badgeTextColor,
  });

  /// Resolve color theme based on preset and optional extracted album colors
  factory LyricCardColors.fromPreset(
    LyricCardThemePreset preset, {
    Color? dominantAlbumColor,
    Color? vibrantAlbumColor,
    Color? lightVibrantAlbumColor,
  }) {
    switch (preset) {
      case LyricCardThemePreset.dynamicAlbumArt:
        final base = dominantAlbumColor ?? const Color(0xFF1E222B);
        return LyricCardColors.fromDynamicColor(
          base,
          accentColor: vibrantAlbumColor ?? lightVibrantAlbumColor,
        );

      case LyricCardThemePreset.studioOledBlack:
        return const LyricCardColors(
          backgroundColor: Color(0xFF000000),
          surfaceColor: Color(0xFF121418),
          primaryTextColor: Color(0xFFFFFFFF),
          secondaryTextColor: Color(0xFF8E95A5),
          accentColor: Color(0xFFE2E8F0),
          borderColor: Color(0xFF262B35),
          badgeBackgroundColor: Color(0xFF1C2028),
          badgeTextColor: Color(0xFFF1F5F9),
        );

      case LyricCardThemePreset.precisionMint:
        return const LyricCardColors(
          backgroundColor: Color(0xFF0C1713),
          surfaceColor: Color(0xFF14241E),
          primaryTextColor: Color(0xFFF0FDF4),
          secondaryTextColor: Color(0xFF86EFAC),
          accentColor: Color(0xFF34D399),
          borderColor: Color(0xFF1A382C),
          badgeBackgroundColor: Color(0xFF064E3B),
          badgeTextColor: Color(0xFF6EE7B7),
        );

      case LyricCardThemePreset.skyStudio:
        return const LyricCardColors(
          backgroundColor: Color(0xFF0B1320),
          surfaceColor: Color(0xFF131F33),
          primaryTextColor: Color(0xFFF8FAFC),
          secondaryTextColor: Color(0xFF94A3B8),
          accentColor: Color(0xFF38BDF8),
          borderColor: Color(0xFF1E3A5F),
          badgeBackgroundColor: Color(0xFF0C4A6E),
          badgeTextColor: Color(0xFF7DD3FC),
        );

      case LyricCardThemePreset.warmAmber:
        return const LyricCardColors(
          backgroundColor: Color(0xFF1A120A),
          surfaceColor: Color(0xFF261B0E),
          primaryTextColor: Color(0xFFFFFBEB),
          secondaryTextColor: Color(0xFFFCD34D),
          accentColor: Color(0xFFF59E0B),
          borderColor: Color(0xFF3D2C17),
          badgeBackgroundColor: Color(0xFF451A03),
          badgeTextColor: Color(0xFFFBBF24),
        );

      case LyricCardThemePreset.mutedRose:
        return const LyricCardColors(
          backgroundColor: Color(0xFF170E14),
          surfaceColor: Color(0xFF24151F),
          primaryTextColor: Color(0xFFFFF1F2),
          secondaryTextColor: Color(0xFFFDA4AF),
          accentColor: Color(0xFFFB7185),
          borderColor: Color(0xFF3D1F31),
          badgeBackgroundColor: Color(0xFF4C0519),
          badgeTextColor: Color(0xFFFECDD3),
        );
    }
  }

  /// Create a color scheme from a dynamic cover palette color with safe contrast protection
  factory LyricCardColors.fromDynamicColor(Color baseColor, {Color? accentColor}) {
    final hsl = HSLColor.fromColor(baseColor);
    final lum = baseColor.computeLuminance();
    final isVeryDark = lum < 0.12 || hsl.lightness < 0.20;
    final isLowSat = hsl.saturation < 0.18;

    final bg = isVeryDark
        ? const Color(0xFF0C0E14)
        : hsl.withLightness(0.10).withSaturation((hsl.saturation * 0.7).clamp(0.15, 0.5)).toColor();
    final surface = isVeryDark
        ? const Color(0xFF161A22)
        : hsl.withLightness(0.16).withSaturation((hsl.saturation * 0.6).clamp(0.12, 0.45)).toColor();

    Color resolvedAccent;
    if (accentColor != null && accentColor.computeLuminance() > 0.18) {
      resolvedAccent = accentColor;
    } else if (isLowSat || isVeryDark) {
      // Fallback to high-contrast refined studio slate / silver gray
      resolvedAccent = const Color(0xFF94A3B8);
    } else {
      resolvedAccent = hsl.withLightness(0.65).withSaturation(0.85).toColor();
    }

    return LyricCardColors(
      backgroundColor: bg,
      surfaceColor: surface,
      primaryTextColor: const Color(0xFFFFFFFF),
      secondaryTextColor: const Color(0xFFCBD5E1),
      accentColor: resolvedAccent,
      borderColor: resolvedAccent.withValues(alpha: 0.25),
      badgeBackgroundColor: resolvedAccent.withValues(alpha: 0.18),
      badgeTextColor: resolvedAccent,
    );
  }

  /// Resolve color palette tailored for blurred artwork background overlay
  factory LyricCardColors.forBlurredArtwork({Color? accentColor}) {
    final accent = accentColor ?? const Color(0xFF7DD3FC);
    return LyricCardColors(
      backgroundColor: const Color(0x88000000),
      surfaceColor: const Color(0x66181B22),
      primaryTextColor: const Color(0xFFFFFFFF),
      secondaryTextColor: const Color(0xFFE2E8F0),
      accentColor: accent,
      borderColor: Colors.white.withValues(alpha: 0.22),
      badgeBackgroundColor: Colors.black.withValues(alpha: 0.45),
      badgeTextColor: accent,
    );
  }

  /// Create a color scheme from any user-selected custom color
  factory LyricCardColors.fromCustomColor(Color customColor) {
    final hsl = HSLColor.fromColor(customColor);
    final bg = hsl.withLightness(0.10).withSaturation((hsl.saturation * 0.65).clamp(0.2, 0.7)).toColor();
    final surface = hsl.withLightness(0.16).withSaturation((hsl.saturation * 0.55).clamp(0.15, 0.6)).toColor();
    final accent = hsl.withLightness(0.68).withSaturation(0.85).toColor();

    return LyricCardColors(
      backgroundColor: bg,
      surfaceColor: surface,
      primaryTextColor: const Color(0xFFFFFFFF),
      secondaryTextColor: const Color(0xFFCBD5E1),
      accentColor: accent,
      borderColor: accent.withValues(alpha: 0.28),
      badgeBackgroundColor: accent.withValues(alpha: 0.20),
      badgeTextColor: accent,
    );
  }
}
