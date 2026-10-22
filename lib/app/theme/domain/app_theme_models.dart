import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// App Theme Mode Selection
enum AppThemeMode {
  system(ThemeMode.system, 'System', 'Follows operating system preferences', LucideIcons.laptop),
  light(ThemeMode.light, 'Light', 'Studio Clean Light Champagne', LucideIcons.sun),
  dark(ThemeMode.dark, 'Dark', 'Studio Dark Obsidian / OLED', LucideIcons.moon);

  final ThemeMode mode;
  final String label;
  final String description;
  final IconData icon;
  const AppThemeMode(this.mode, this.label, this.description, this.icon);
}

/// Surface and component fill style (translucent soft tint vs pure solid M3)
enum SurfaceFillStyle {
  translucent('Translucent Soft Tint', 'Subtle transparent tint for cards and surfaces', LucideIcons.layers),
  solid('Pure Solid M3', '100% solid filled colors for all cards, containers and buttons', LucideIcons.square);

  final String label;
  final String description;
  final IconData icon;
  const SurfaceFillStyle(this.label, this.description, this.icon);
}

/// Scope for wallpaper background rendering
enum WallpaperScope {
  appWide('App-Wide Ground', 'Wallpaper applied across all screens and tabs', LucideIcons.layers),
  dashboardAndPlayer('Dashboard & Player Only', 'Wallpaper applied only to main screen and player', LucideIcons.playSquare);

  final String label;
  final String description;
  final IconData icon;
  const WallpaperScope(this.label, this.description, this.icon);
}

/// Custom Wallpaper & Dynamic Backdrop Settings
@immutable
class WallpaperSettings {
  final bool enabled;
  final String? imagePath;
  final double blurRadius;
  final double dimOpacity;
  final bool syncPalette;
  final WallpaperScope scope;
  final Color? extractedPrimary;
  final Color? extractedSecondary;
  final Color? extractedTertiary;

  const WallpaperSettings({
    this.enabled = false,
    this.imagePath,
    this.blurRadius = 16.0,
    this.dimOpacity = 0.45,
    this.syncPalette = true,
    this.scope = WallpaperScope.appWide,
    this.extractedPrimary,
    this.extractedSecondary,
    this.extractedTertiary,
  });

  WallpaperSettings copyWith({
    bool? enabled,
    String? imagePath,
    double? blurRadius,
    double? dimOpacity,
    bool? syncPalette,
    WallpaperScope? scope,
    Color? extractedPrimary,
    Color? extractedSecondary,
    Color? extractedTertiary,
  }) {
    return WallpaperSettings(
      enabled: enabled ?? this.enabled,
      imagePath: imagePath ?? this.imagePath,
      blurRadius: blurRadius ?? this.blurRadius,
      dimOpacity: dimOpacity ?? this.dimOpacity,
      syncPalette: syncPalette ?? this.syncPalette,
      scope: scope ?? this.scope,
      extractedPrimary: extractedPrimary ?? this.extractedPrimary,
      extractedSecondary: extractedSecondary ?? this.extractedSecondary,
      extractedTertiary: extractedTertiary ?? this.extractedTertiary,
    );
  }

  bool get isAsset => imagePath != null && imagePath!.startsWith('assets/');
  bool get hasWallpaper => imagePath != null && imagePath!.isNotEmpty;

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'image_path': imagePath,
    'blur_radius': blurRadius,
    'dim_opacity': dimOpacity,
    'sync_palette': syncPalette,
    'scope': scope.name,
    'extracted_primary': extractedPrimary?.toARGB32(),
    'extracted_secondary': extractedSecondary?.toARGB32(),
    'extracted_tertiary': extractedTertiary?.toARGB32(),
  };

  factory WallpaperSettings.fromJson(Map<String, dynamic> json) {
    final scopeStr = json['scope'] as String? ?? 'appWide';
    final scope = WallpaperScope.values.firstWhere(
      (s) => s.name == scopeStr,
      orElse: () => WallpaperScope.appWide,
    );
    final extPrim = json['extracted_primary'] as int?;
    final extSec = json['extracted_secondary'] as int?;
    final extTert = json['extracted_tertiary'] as int?;

    return WallpaperSettings(
      enabled: json['enabled'] as bool? ?? false,
      imagePath: json['image_path'] as String?,
      blurRadius: (json['blur_radius'] as num?)?.toDouble() ?? 16.0,
      dimOpacity: (json['dim_opacity'] as num?)?.toDouble() ?? 0.45,
      syncPalette: json['sync_palette'] as bool? ?? true,
      scope: scope,
      extractedPrimary: extPrim != null ? Color(extPrim) : null,
      extractedSecondary: extSec != null ? Color(extSec) : null,
      extractedTertiary: extTert != null ? Color(extTert) : null,
    );
  }
}
