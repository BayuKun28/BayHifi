import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'theme_mode_controller.dart';

/// Studio Surface & Component Theming Utility
/// Resolves container colors, tinted accents, and borders based on [SurfaceFillStyle]
/// (Translucent Soft Tint vs Pure Solid M3).
class StudioSurfaceTheme {
  const StudioSurfaceTheme._();

  /// Resolves the primary container color (for cards, bento modules, sheets).
  static Color surfaceContainer(
    BuildContext context, {
    bool isSolid = false,
    double translucentAlpha = 0.6,
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
    double translucentAlpha = 0.7,
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
    double translucentAlpha = 0.5,
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
    double translucentAlpha = 0.75,
  }) {
    final theme = Theme.of(context);
    return isSolid
        ? theme.colorScheme.surface
        : theme.colorScheme.surface.withValues(alpha: translucentAlpha);
  }

  /// Resolves an accent-tinted container color (for badges, active pills, indicators).
  /// In Solid mode: returns solid [surfaceContainerHighest] for pure non-neon Material 3 surfaces.
  /// In Translucent mode: uses a subtle alpha transparency on [tintColor].
  static Color tintedContainer(
    BuildContext context,
    Color tintColor, {
    bool isSolid = false,
    double translucentAlpha = 0.12,
    double solidBlendAlpha = 0.0,
  }) {
    final theme = Theme.of(context);
    return isSolid
        ? theme.colorScheme.surfaceContainerHighest
        : tintColor.withValues(alpha: translucentAlpha);
  }

  /// Resolves crisp border outline color.
  static Color outline(
    BuildContext context, {
    bool isSolid = false,
    double translucentAlpha = 0.45,
  }) {
    final theme = Theme.of(context);
    return isSolid
        ? theme.colorScheme.outline
        : theme.dividerColor.withValues(alpha: translucentAlpha);
  }

  /// Resolves subtle border outline color for nested containers.
  static Color subtleOutline(
    BuildContext context, {
    bool isSolid = false,
    double translucentAlpha = 0.25,
  }) {
    final theme = Theme.of(context);
    return isSolid
        ? theme.colorScheme.outlineVariant
        : theme.dividerColor.withValues(alpha: translucentAlpha);
  }

  /// Standard card box decoration helper conforming to M3 Expressive Studio Bento layout.
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
      border: Border.all(
        color: borderColor ?? outline(context, isSolid: isSolid),
        width: borderWidth,
      ),
      boxShadow: shadows ??
          (isSolid
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null),
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
