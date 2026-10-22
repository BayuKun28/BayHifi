import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../app_typography.dart';
import 'app_palette.dart';

/// Generator ThemeData untuk Dark Mode dan Light Mode
class AppThemeBuilder {
  static ThemeData buildTheme(AppPalette palette, {required bool isDark, bool isWallpaperActive = false}) {
    final isOled = palette.isOledBlack;
    final bg = isWallpaperActive
        ? Colors.transparent
        : (isDark
            ? (isOled ? const Color(0xFF000000) : const Color(0xFF0D0E12))
            : palette.backgroundLight);
    final surface = isDark
        ? (isOled ? const Color(0xFF0A0A0A) : const Color(0xFF12141A))
        : palette.surfaceLight;
    final surfaceContainer = isDark
        ? (isOled ? const Color(0xFF141414) : const Color(0xFF16181F))
        : palette.surfaceContainerLight;
    final textPrimary = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    // Solid Studio Card Boundaries & Outlines (clean neutral charcoal, zero green tint)
    final outlineVariant = isDark
        ? (palette.isOledBlack
            ? const Color(0xFF1E1E1E)
            : const Color(0xFF262936))
        : const Color(0xFFE2E8F0);

    final outline = isDark
        ? (palette.isOledBlack
            ? const Color(0xFF2A2A2A)
            : const Color(0xFF323647))
        : const Color(0xFFCBD5E1);

    final surfaceContainerHigh = isDark
        ? (palette.isOledBlack
            ? const Color(0xFF1C1C1C)
            : const Color(0xFF1E212B))
        : Color.alphaBlend(palette.primary.withValues(alpha: 0.05), surfaceContainer);

    final surfaceContainerHighest = isDark
        ? (palette.isOledBlack
            ? const Color(0xFF242424)
            : const Color(0xFF252834))
        : Color.alphaBlend(palette.primary.withValues(alpha: 0.10), surfaceContainer);

    final surfaceContainerLow = isDark
        ? (palette.isOledBlack
            ? const Color(0xFF0A0A0A)
            : Color.alphaBlend(surface.withValues(alpha: 0.85), bg))
        : Color.alphaBlend(palette.primary.withValues(alpha: 0.03), bg);

    final surfaceContainerLowest = isDark
        ? (palette.isOledBlack ? const Color(0xFF000000) : bg)
        : const Color(0xFFFFFFFF);

    final onPrimary = palette.primary.computeLuminance() > 0.45
        ? const Color(0xFF0C0E12)
        : const Color(0xFFFFFFFF);
    final onSecondary = palette.secondary.computeLuminance() > 0.45
        ? const Color(0xFF0C0E12)
        : const Color(0xFFFFFFFF);

    final colorScheme = isDark
        ? ColorScheme.dark(
            primary: palette.primary,
            onPrimary: onPrimary,
            secondary: palette.secondary,
            onSecondary: onSecondary,
            tertiary: palette.accent,
            surface: surface,
            onSurface: textPrimary,
            onSurfaceVariant: textSecondary,
            surfaceContainer: surfaceContainer,
            surfaceContainerHigh: surfaceContainerHigh,
            surfaceContainerHighest: surfaceContainerHighest,
            surfaceContainerLow: surfaceContainerLow,
            surfaceContainerLowest: surfaceContainerLowest,
            outline: outline,
            outlineVariant: outlineVariant,
            error: const Color(0xFFFF453A),
          )
        : ColorScheme.light(
            primary: palette.primary,
            onPrimary: onPrimary,
            secondary: palette.secondary,
            onSecondary: onSecondary,
            tertiary: palette.accent,
            surface: surface,
            onSurface: textPrimary,
            onSurfaceVariant: textSecondary,
            surfaceContainer: surfaceContainer,
            surfaceContainerHigh: surfaceContainerHigh,
            surfaceContainerHighest: surfaceContainerHighest,
            surfaceContainerLow: surfaceContainerLow,
            surfaceContainerLowest: surfaceContainerLowest,
            outline: outline,
            outlineVariant: outlineVariant,
            error: const Color(0xFFD32F2F),
          );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      cardColor: surfaceContainer,
      dividerColor: outlineVariant,
      textTheme: AppTypography.textTheme(isDark: isDark),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: textPrimary),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: palette.primary,
        inactiveTrackColor: palette.primary.withValues(alpha: 0.20),
        thumbColor: palette.primary,
        overlayColor: palette.primary.withValues(alpha: 0.15),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surfaceContainer,
        elevation: 0,
        indicatorColor: palette.primary.withValues(alpha: 0.18),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return IconThemeData(color: palette.primary);
          }
          return IconThemeData(color: textSecondary);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return TextStyle(
              color: palette.primary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            );
          }
          return TextStyle(
            color: textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          );
        }),
      ),
    );
  }

  /// Generator M3EThemeData resmi dari material_3_expressive
  static M3EThemeData buildM3ETheme(AppPalette palette, {required bool isDark, bool isWallpaperActive = false}) {
    final bg = isWallpaperActive
        ? Colors.transparent
        : (isDark ? palette.backgroundDark : palette.backgroundLight);
    final surface = isDark ? palette.surfaceDark : palette.surfaceLight;
    final surfaceContainer = isDark ? palette.surfaceContainerDark : palette.surfaceContainerLight;
    final textPrimary = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    // Soft Studio Card Boundaries & Outlines (harmonized with palette)
    final outlineVariant = isDark
        ? (palette.isOledBlack
            ? const Color(0xFF1E1E1E)
            : Color.alphaBlend(palette.primary.withValues(alpha: 0.08), const Color(0xFF1E293B)))
        : Color.alphaBlend(palette.primary.withValues(alpha: 0.06), const Color(0xFFE2E8F0));

    final outline = isDark
        ? (palette.isOledBlack
            ? const Color(0xFF2A2A2A)
            : Color.alphaBlend(palette.primary.withValues(alpha: 0.15), const Color(0xFF334155)))
        : Color.alphaBlend(palette.primary.withValues(alpha: 0.12), const Color(0xFFCBD5E1));

    final surfaceContainerHigh = isDark
        ? (palette.isOledBlack
            ? const Color(0xFF1C1C1C)
            : Color.alphaBlend(palette.primary.withValues(alpha: 0.08), surfaceContainer))
        : Color.alphaBlend(palette.primary.withValues(alpha: 0.05), surfaceContainer);

    final surfaceContainerHighest = isDark
        ? (palette.isOledBlack
            ? const Color(0xFF242424)
            : Color.alphaBlend(palette.primary.withValues(alpha: 0.15), surfaceContainer))
        : Color.alphaBlend(palette.primary.withValues(alpha: 0.10), surfaceContainer);

    final surfaceContainerLow = isDark
        ? (palette.isOledBlack
            ? const Color(0xFF0A0A0A)
            : Color.alphaBlend(surface.withValues(alpha: 0.85), bg))
        : Color.alphaBlend(palette.primary.withValues(alpha: 0.03), bg);

    final surfaceContainerLowest = isDark
        ? (palette.isOledBlack ? const Color(0xFF000000) : bg)
        : const Color(0xFFFFFFFF);

    final onPrimary = palette.primary.computeLuminance() > 0.45
        ? const Color(0xFF0C0E12)
        : const Color(0xFFFFFFFF);
    final onSecondary = palette.secondary.computeLuminance() > 0.45
        ? const Color(0xFF0C0E12)
        : const Color(0xFFFFFFFF);

    final scheme = M3EColorScheme.fromSeed(
      palette.primary,
      brightness: isDark ? Brightness.dark : Brightness.light,
    ).copyWith(
      primary: palette.primary,
      onPrimary: onPrimary,
      secondary: palette.secondary,
      onSecondary: onSecondary,
      tertiary: palette.accent,
      surface: surface,
      onSurface: textPrimary,
      onSurfaceVariant: textSecondary,
      surfaceContainerLowest: surfaceContainerLowest,
      surfaceContainerLow: surfaceContainerLow,
      surfaceContainer: surfaceContainer,
      surfaceContainerHigh: surfaceContainerHigh,
      surfaceContainerHighest: surfaceContainerHighest,
      outline: outline,
      outlineVariant: outlineVariant,
    );

    return M3EThemeData(
      colorScheme: scheme,
      visualDensity: 0,
      useMaterial3: true,
    );
  }
}
