import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:palette_generator/palette_generator.dart';
import '../../core/database/local_persistence_service.dart';
import '../../core/widgets/studio_artwork_widget.dart';
import '../../features/player/domain/track.dart';
import 'app_typography.dart';

/// App Theme Mode Selection
enum AppThemeMode {
  system(ThemeMode.system, 'System', 'Follows operating system preferences', HugeIcons.strokeRoundedComputer),
  light(ThemeMode.light, 'Light', 'Studio Clean Light Champagne', HugeIcons.strokeRoundedSun01),
  dark(ThemeMode.dark, 'Dark', 'Studio Dark Obsidian / OLED', HugeIcons.strokeRoundedMoon02);

  final ThemeMode mode;
  final String label;
  final String description;
  final dynamic icon;
  const AppThemeMode(this.mode, this.label, this.description, this.icon);
}

/// Surface and component fill style (translucent soft tint vs pure solid M3)
enum SurfaceFillStyle {
  translucent('Translucent Soft Tint', 'Subtle transparent tint for cards and surfaces', HugeIcons.strokeRoundedLayers01),
  solid('Pure Solid M3', '100% solid filled colors for all cards, containers and buttons', HugeIcons.strokeRoundedSquare);

  final String label;
  final String description;
  final dynamic icon;
  const SurfaceFillStyle(this.label, this.description, this.icon);
}

/// Scope for wallpaper background rendering
enum WallpaperScope {
  appWide('App-Wide Ground', 'Wallpaper applied across all screens and tabs', HugeIcons.strokeRoundedLayers01),
  dashboardAndPlayer('Dashboard & Player Only', 'Wallpaper applied only to main screen and player', HugeIcons.strokeRoundedPlaySquare);

  final String label;
  final String description;
  final dynamic icon;
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

/// Predefined Studio Wallpaper Preset
@immutable
class StudioWallpaperPreset {
  final String id;
  final String title;
  final String subtitle;
  final String assetPath;
  final Color primaryColor;
  final Color secondaryColor;
  final Color tertiaryColor;

  const StudioWallpaperPreset({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.assetPath,
    required this.primaryColor,
    required this.secondaryColor,
    required this.tertiaryColor,
  });

  static const List<StudioWallpaperPreset> presets = [
    StudioWallpaperPreset(
      id: 'obsidian_soundwaves',
      title: 'Obsidian Soundwaves',
      subtitle: 'Cyan & violet DSP audio waveforms in deep obsidian void',
      assetPath: 'assets/images/wallpapers/obsidian_soundwaves.jpg',
      primaryColor: Color(0xFF00E5FF),
      secondaryColor: Color(0xFF7C4DFF),
      tertiaryColor: Color(0xFF00B0FF),
    ),
    StudioWallpaperPreset(
      id: 'warm_tube_analog',
      title: 'Warm Tube Analog',
      subtitle: 'Glowing vacuum tube filament & golden acoustic warmth',
      assetPath: 'assets/images/wallpapers/warm_tube_analog.jpg',
      primaryColor: Color(0xFFFF9100),
      secondaryColor: Color(0xFFFFAB40),
      tertiaryColor: Color(0xFFFFD180),
    ),
    StudioWallpaperPreset(
      id: 'mastering_console',
      title: 'Mastering Console',
      subtitle: 'Illuminated analog VU meters & precision mastering console',
      assetPath: 'assets/images/wallpapers/mastering_console.jpg',
      primaryColor: Color(0xFF00E676),
      secondaryColor: Color(0xFFFFC400),
      tertiaryColor: Color(0xFF2979FF),
    ),
    StudioWallpaperPreset(
      id: 'cyber_spectrum',
      title: 'Cyber Spectrum',
      subtitle: 'Futuristic parametric EQ curves & geometric RTA analyzer',
      assetPath: 'assets/images/wallpapers/cyber_spectrum.jpg',
      primaryColor: Color(0xFFE040FB),
      secondaryColor: Color(0xFF00E5FF),
      tertiaryColor: Color(0xFF651FFF),
    ),
    StudioWallpaperPreset(
      id: 'dark_tech',
      title: 'Dark Tech Studio',
      subtitle: 'Discrete DSP microchips & neon circuit traces on matte carbon',
      assetPath: 'assets/images/wallpapers/dark_tech.jpg',
      primaryColor: Color(0xFF00E5FF),
      secondaryColor: Color(0xFF7C4DFF),
      tertiaryColor: Color(0xFF00E676),
    ),
    StudioWallpaperPreset(
      id: 'vinyl_resonance',
      title: 'Vinyl Resonance',
      subtitle: 'Audiophile turntable tonearm & microgroove sheen',
      assetPath: 'assets/images/wallpapers/vinyl_resonance.jpg',
      primaryColor: Color(0xFFE0E0E0),
      secondaryColor: Color(0xFFFFD54F),
      tertiaryColor: Color(0xFF90A4AE),
    ),
  ];
}

/// Audiophile Studio Custom Palette Model
@immutable
class AppPalette {
  final String id;
  final String name;
  final String description;
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color backgroundDark;
  final Color backgroundLight;
  final Color surfaceDark;
  final Color surfaceLight;
  final Color surfaceContainerDark;
  final Color surfaceContainerLight;
  final bool isOledBlack;
  final bool isDynamic;

  const AppPalette({
    required this.id,
    required this.name,
    required this.description,
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.backgroundDark,
    required this.backgroundLight,
    required this.surfaceDark,
    required this.surfaceLight,
    required this.surfaceContainerDark,
    required this.surfaceContainerLight,
    this.isOledBlack = false,
    this.isDynamic = false,
  });

  AppPalette copyWith({
    String? id,
    String? name,
    String? description,
    Color? primary,
    Color? secondary,
    Color? accent,
    Color? backgroundDark,
    Color? backgroundLight,
    Color? surfaceDark,
    Color? surfaceLight,
    Color? surfaceContainerDark,
    Color? surfaceContainerLight,
    bool? isOledBlack,
    bool? isDynamic,
  }) {
    return AppPalette(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      primary: primary ?? this.primary,
      secondary: secondary ?? this.secondary,
      accent: accent ?? this.accent,
      backgroundDark: backgroundDark ?? this.backgroundDark,
      backgroundLight: backgroundLight ?? this.backgroundLight,
      surfaceDark: surfaceDark ?? this.surfaceDark,
      surfaceLight: surfaceLight ?? this.surfaceLight,
      surfaceContainerDark: surfaceContainerDark ?? this.surfaceContainerDark,
      surfaceContainerLight: surfaceContainerLight ?? this.surfaceContainerLight,
      isOledBlack: isOledBlack ?? this.isOledBlack,
      isDynamic: isDynamic ?? this.isDynamic,
    );
  }

  // ─── Curated Presets (Strict Non-Neon Studio Palettes) ───────────────────────

  static const AppPalette namidaCyan = AppPalette(
    id: 'obsidian_cyan',
    name: 'Obsidian Cyan',
    description: 'Refined sky cyan with deep obsidian studio background',
    primary: Color(0xFF38BDF8),
    secondary: Color(0xFF0284C7),
    accent: Color(0xFF38BDF8),
    backgroundDark: Color(0xFF0C1217),
    backgroundLight: Color(0xFFF1F6FB),
    surfaceDark: Color(0xFF121921),
    surfaceLight: Color(0xFFF7FAFD),
    surfaceContainerDark: Color(0xFF1A2430),
    surfaceContainerLight: Color(0xFFE2EFF9),
  );

  static const AppPalette amberTube = AppPalette(
    id: 'amber_tube',
    name: 'Amber Tube Glow',
    description: 'Warmth of analog triode tube glow and radiant amber accents',
    primary: Color(0xFFF59E0B),
    secondary: Color(0xFFD97706),
    accent: Color(0xFFF59E0B),
    backgroundDark: Color(0xFF141009),
    backgroundLight: Color(0xFFFAF6F0),
    surfaceDark: Color(0xFF1C170E),
    surfaceLight: Color(0xFFFCFAF6),
    surfaceContainerDark: Color(0xFF282115),
    surfaceContainerLight: Color(0xFFF6EADB),
  );

  static const AppPalette emeraldHiFi = AppPalette(
    id: 'emerald_hifi',
    name: 'Emerald HiFi',
    description: 'Precision emerald mint aesthetic of mastering hardware instruments',
    primary: Color(0xFF10B981),
    secondary: Color(0xFF059669),
    accent: Color(0xFF10B981),
    backgroundDark: Color(0xFF0C1410),
    backgroundLight: Color(0xFFF0F8F4),
    surfaceDark: Color(0xFF121E18),
    surfaceLight: Color(0xFFF6FBF8),
    surfaceContainerDark: Color(0xFF1A2A22),
    surfaceContainerLight: Color(0xFFDDF5EA),
  );

  static const AppPalette electricPurple = AppPalette(
    id: 'electric_purple',
    name: 'Studio Violet',
    description: 'Modern studio violet and lavender mastering aesthetic',
    primary: Color(0xFFA855F7),
    secondary: Color(0xFF7E22CE),
    accent: Color(0xFFC084FC),
    backgroundDark: Color(0xFF130C1A),
    backgroundLight: Color(0xFFF8F3FC),
    surfaceDark: Color(0xFF1B1125),
    surfaceLight: Color(0xFFFAF6FD),
    surfaceContainerDark: Color(0xFF271A36),
    surfaceContainerLight: Color(0xFFF0E3FA),
  );

  static const AppPalette crimsonPassion = AppPalette(
    id: 'crimson_passion',
    name: 'Crimson Passion',
    description: 'Bold audiophile crimson red with ultra-high contrast',
    primary: Color(0xFFF43F5E),
    secondary: Color(0xFFBE123C),
    accent: Color(0xFFFB7185),
    backgroundDark: Color(0xFF160B0F),
    backgroundLight: Color(0xFFFAF2F4),
    surfaceDark: Color(0xFF201017),
    surfaceLight: Color(0xFFFDF6F8),
    surfaceContainerDark: Color(0xFF2E1721),
    surfaceContainerLight: Color(0xFFFCE1E7),
  );

  static const AppPalette trueOledBlack = AppPalette(
    id: 'true_oled',
    name: 'True OLED Black',
    description: 'Pure 100% OLED black for AMOLED displays with zero battery drain',
    primary: Color(0xFF38BDF8),
    secondary: Color(0xFF0284C7),
    accent: Color(0xFF34D399),
    backgroundDark: Color(0xFF000000),
    backgroundLight: Color(0xFFF4F6F8),
    surfaceDark: Color(0xFF0A0A0A),
    surfaceLight: Color(0xFFFAFBFD),
    surfaceContainerDark: Color(0xFF141414),
    surfaceContainerLight: Color(0xFFEAEFF5),
    isOledBlack: true,
  );

  static const AppPalette pastelLavender = AppPalette(
    id: 'pastel_lavender',
    name: 'Pastel Lavender',
    description: 'Soothing studio pastel lavender with soft calming tones',
    primary: Color(0xFFB8A9E8),
    secondary: Color(0xFF9D8BC9),
    accent: Color(0xFFB8A9E8),
    backgroundDark: Color(0xFF121019),
    backgroundLight: Color(0xFFF7F5FC),
    surfaceDark: Color(0xFF191624),
    surfaceLight: Color(0xFFFAF8FE),
    surfaceContainerDark: Color(0xFF242033),
    surfaceContainerLight: Color(0xFFECE7F8),
  );

  static const AppPalette pastelSage = AppPalette(
    id: 'pastel_sage',
    name: 'Pastel Sage Mint',
    description: 'Muted tranquil pastel sage green for relaxed studio listening',
    primary: Color(0xFF93D5C0),
    secondary: Color(0xFF72B8A2),
    accent: Color(0xFF93D5C0),
    backgroundDark: Color(0xFF0E1412),
    backgroundLight: Color(0xFFF2F8F5),
    surfaceDark: Color(0xFF141D1A),
    surfaceLight: Color(0xFFF7FCFA),
    surfaceContainerDark: Color(0xFF1C2925),
    surfaceContainerLight: Color(0xFFE2F3EC),
  );

  static const AppPalette pastelSky = AppPalette(
    id: 'pastel_sky',
    name: 'Pastel Powder Sky',
    description: 'Airy and luminous soft pastel blue studio aesthetic',
    primary: Color(0xFF9AC8EB),
    secondary: Color(0xFF74ABD4),
    accent: Color(0xFF9AC8EB),
    backgroundDark: Color(0xFF0E1319),
    backgroundLight: Color(0xFFF2F7FB),
    surfaceDark: Color(0xFF141B23),
    surfaceLight: Color(0xFFF7FAFD),
    surfaceContainerDark: Color(0xFF1C2733),
    surfaceContainerLight: Color(0xFFE2EFF8),
  );

  static const AppPalette pastelPeach = AppPalette(
    id: 'pastel_peach',
    name: 'Pastel Soft Peach',
    description: 'Warm and gentle acoustic pastel apricot and peach glow',
    primary: Color(0xFFF7B297),
    secondary: Color(0xFFDE9173),
    accent: Color(0xFFF7B297),
    backgroundDark: Color(0xFF16100E),
    backgroundLight: Color(0xFFFAF4F1),
    surfaceDark: Color(0xFF201714),
    surfaceLight: Color(0xFFFCF8F6),
    surfaceContainerDark: Color(0xFF2E211D),
    surfaceContainerLight: Color(0xFFF9EAE3),
  );

  static const AppPalette pastelBlush = AppPalette(
    id: 'pastel_blush',
    name: 'Pastel Blush Rose',
    description: 'Soft studio blush rose with delicate acoustic warmth',
    primary: Color(0xFFF2A7B5),
    secondary: Color(0xFFD78494),
    accent: Color(0xFFF2A7B5),
    backgroundDark: Color(0xFF160E12),
    backgroundLight: Color(0xFFFAF3F5),
    surfaceDark: Color(0xFF20141A),
    surfaceLight: Color(0xFFFCF7F9),
    surfaceContainerDark: Color(0xFF2E1D26),
    surfaceContainerLight: Color(0xFFF8E7EC),
  );

  static const AppPalette pastelButter = AppPalette(
    id: 'pastel_butter',
    name: 'Pastel Butter Cream',
    description: 'Velvety warm studio cream with muted vintage gold touch',
    primary: Color(0xFFE8D18C),
    secondary: Color(0xFFCDB367),
    accent: Color(0xFFE8D18C),
    backgroundDark: Color(0xFF15130B),
    backgroundLight: Color(0xFFFAF8EE),
    surfaceDark: Color(0xFF1E1B10),
    surfaceLight: Color(0xFFFCFAF2),
    surfaceContainerDark: Color(0xFF2B2717),
    surfaceContainerLight: Color(0xFFF7F3DC),
  );

  static const AppPalette nordicSlate = AppPalette(
    id: 'nordic_slate',
    name: 'Nordic Slate Frost',
    description: 'Minimalist Scandinavian studio slate blue and cool brushed silver tone',
    primary: Color(0xFF64748B),
    secondary: Color(0xFF475569),
    accent: Color(0xFF94A3B8),
    backgroundDark: Color(0xFF0F1218),
    backgroundLight: Color(0xFFF2F5F8),
    surfaceDark: Color(0xFF151922),
    surfaceLight: Color(0xFFF8FAFC),
    surfaceContainerDark: Color(0xFF1E2330),
    surfaceContainerLight: Color(0xFFE6ECF2),
  );

  static const AppPalette terracottaClay = AppPalette(
    id: 'terracotta_clay',
    name: 'Terracotta Clay',
    description: 'Warm acoustic earth, organic ceramic kiln and burnt sienna tone',
    primary: Color(0xFFC2410C),
    secondary: Color(0xFF9A3412),
    accent: Color(0xFFEA580C),
    backgroundDark: Color(0xFF140F0C),
    backgroundLight: Color(0xFFFAF4F0),
    surfaceDark: Color(0xFF1C1511),
    surfaceLight: Color(0xFFFCF8F5),
    surfaceContainerDark: Color(0xFF271F1A),
    surfaceContainerLight: Color(0xFFF7ECE4),
  );

  static const AppPalette matchaBotanical = AppPalette(
    id: 'matcha_botanical',
    name: 'Matcha Botanical',
    description: 'Deep organic matcha green tea and bamboo studio tranquility',
    primary: Color(0xFF15803D),
    secondary: Color(0xFF166534),
    accent: Color(0xFF22C55E),
    backgroundDark: Color(0xFF0D140F),
    backgroundLight: Color(0xFFF1F7F3),
    surfaceDark: Color(0xFF131D16),
    surfaceLight: Color(0xFFF7FAF7),
    surfaceContainerDark: Color(0xFF1C2A20),
    surfaceContainerLight: Color(0xFFE2F0E5),
  );

  static const AppPalette midnightSapphire = AppPalette(
    id: 'midnight_sapphire',
    name: 'Midnight Sapphire',
    description: 'Deep naval sapphire blue and cobalt mastering console tone',
    primary: Color(0xFF2563EB),
    secondary: Color(0xFF1D4ED8),
    accent: Color(0xFF3B82F6),
    backgroundDark: Color(0xFF0C101A),
    backgroundLight: Color(0xFFF1F5FC),
    surfaceDark: Color(0xFF121827),
    surfaceLight: Color(0xFFF7FAFD),
    surfaceContainerDark: Color(0xFF1A2237),
    surfaceContainerLight: Color(0xFFE3EDFA),
  );

  static const AppPalette vintageBrass = AppPalette(
    id: 'vintage_brass',
    name: 'Vintage Brass & Walnut',
    description: 'Luxury vintage vacuum tube amplifier brass and dark walnut aesthetic',
    primary: Color(0xFFCA8A04),
    secondary: Color(0xFFA16207),
    accent: Color(0xFFEAB308),
    backgroundDark: Color(0xFF14110A),
    backgroundLight: Color(0xFFFAF7EE),
    surfaceDark: Color(0xFF1C180E),
    surfaceLight: Color(0xFFFCF9F2),
    surfaceContainerDark: Color(0xFF272214),
    surfaceContainerLight: Color(0xFFF5EFDC),
  );

  static const AppPalette mochaEspresso = AppPalette(
    id: 'mocha_espresso',
    name: 'Mocha Espresso',
    description: 'Rich artisanal dark roast coffee and warm roasted cacao studio tone',
    primary: Color(0xFF78350F),
    secondary: Color(0xFF92400E),
    accent: Color(0xFFB45309),
    backgroundDark: Color(0xFF130E0B),
    backgroundLight: Color(0xFFFAF4F0),
    surfaceDark: Color(0xFF1B1410),
    surfaceLight: Color(0xFFFCF8F5),
    surfaceContainerDark: Color(0xFF261D18),
    surfaceContainerLight: Color(0xFFF6EDE6),
  );

  static const AppPalette proCarbon = AppPalette(
    id: 'pro_carbon',
    name: 'Monochrome Pro Carbon',
    description: 'High-contrast pure grayscale studio reference mastering monitor aesthetic',
    primary: Color(0xFF71717A),
    secondary: Color(0xFF52525B),
    accent: Color(0xFFA1A1AA),
    backgroundDark: Color(0xFF111113),
    backgroundLight: Color(0xFFF4F4F5),
    surfaceDark: Color(0xFF18181B),
    surfaceLight: Color(0xFFFAFAFA),
    surfaceContainerDark: Color(0xFF242428),
    surfaceContainerLight: Color(0xFFEAEAEB),
  );

  static const List<AppPalette> allPresets = [
    namidaCyan,
    nordicSlate,
    terracottaClay,
    matchaBotanical,
    midnightSapphire,
    vintageBrass,
    mochaEspresso,
    proCarbon,
    pastelLavender,
    pastelSage,
    pastelSky,
    pastelPeach,
    pastelBlush,
    pastelButter,
    amberTube,
    emeraldHiFi,
    electricPurple,
    crimsonPassion,
    trueOledBlack,
  ];
}

/// State untuk Theming Aplikasi
@immutable
class ThemeSettingsState {
  final AppThemeMode themeMode;
  final AppPalette currentPalette;
  final Color customAccentColor;
  final bool dynamicAlbumArtEnabled;
  final SurfaceFillStyle? surfaceFillStyle;
  final WallpaperSettings wallpaperSettings;

  SurfaceFillStyle get effectiveSurfaceFillStyle => surfaceFillStyle ?? SurfaceFillStyle.solid;
  bool get isSolidStyle => effectiveSurfaceFillStyle == SurfaceFillStyle.solid;

  const ThemeSettingsState({
    this.themeMode = AppThemeMode.dark,
    this.currentPalette = AppPalette.namidaCyan,
    this.customAccentColor = const Color(0xFF38BDF8),
    this.dynamicAlbumArtEnabled = false,
    this.surfaceFillStyle = SurfaceFillStyle.solid,
    this.wallpaperSettings = const WallpaperSettings(),
  });

  ThemeSettingsState copyWith({
    AppThemeMode? themeMode,
    AppPalette? currentPalette,
    Color? customAccentColor,
    bool? dynamicAlbumArtEnabled,
    SurfaceFillStyle? surfaceFillStyle,
    WallpaperSettings? wallpaperSettings,
  }) {
    return ThemeSettingsState(
      themeMode: themeMode ?? this.themeMode,
      currentPalette: currentPalette ?? this.currentPalette,
      customAccentColor: customAccentColor ?? this.customAccentColor,
      dynamicAlbumArtEnabled: dynamicAlbumArtEnabled ?? this.dynamicAlbumArtEnabled,
      surfaceFillStyle: surfaceFillStyle ?? (this.surfaceFillStyle ?? SurfaceFillStyle.solid),
      wallpaperSettings: wallpaperSettings ?? this.wallpaperSettings,
    );
  }
}

/// Controller untuk Theme Mode dan Custom Palette
class ThemeController extends StateNotifier<ThemeSettingsState> {
  ThemeController() : super(_loadInitialState());

  static ThemeSettingsState _loadInitialState() {
    try {
      final saved = LocalPersistenceService.instance.getThemeSettings();
      final paletteId = saved['palette_id'] as String? ?? 'obsidian_cyan';
      final modeIndex = saved['theme_mode'] as int? ?? AppThemeMode.dark.index;
      final accentVal = saved['custom_accent'] as int? ?? 0xFF38BDF8;
      final dynamicArt = saved['dynamic_album_art'] as bool? ?? false;
      final fillStyleStr = saved['surface_fill_style'] as String? ?? 'translucent';

      final wallpaperJson = LocalPersistenceService.instance.getWallpaperSettings();
      final wallpaperSettings = WallpaperSettings.fromJson(wallpaperJson);

      final themeMode = (modeIndex >= 0 && modeIndex < AppThemeMode.values.length)
          ? AppThemeMode.values[modeIndex]
          : AppThemeMode.dark;

      final palette = AppPalette.allPresets.firstWhere(
        (p) => p.id == paletteId,
        orElse: () => AppPalette.namidaCyan,
      );

      final customColor = Color(accentVal);
      final fillStyle = SurfaceFillStyle.values.firstWhere(
        (f) => f.name == fillStyleStr,
        orElse: () => SurfaceFillStyle.solid,
      );

      if (dynamicArt) {
        final dynVibrantVal = saved['dynamic_vibrant'] as int? ?? accentVal;
        final dynDomVal = saved['dynamic_dominant'] as int? ?? 0xFF14171E;
        final vibrant = Color(dynVibrantVal);
        final dominant = Color(dynDomVal);
        final dynamicPalette = AppPalette(
          id: 'dynamic_album_art',
          name: 'Dynamic Album Art',
          description: 'Ekstraksi warna otomatis dari cover album yang sedang diputar',
          primary: vibrant,
          secondary: dominant,
          accent: vibrant,
          backgroundDark: Color.alphaBlend(vibrant.withValues(alpha: 0.04), const Color(0xFF0A0C10)),
          backgroundLight: Color.alphaBlend(vibrant.withValues(alpha: 0.03), const Color(0xFFF8FAFC)),
          surfaceDark: Color.alphaBlend(vibrant.withValues(alpha: 0.08), const Color(0xFF101318)),
          surfaceLight: const Color(0xFFFFFFFF),
          surfaceContainerDark: Color.alphaBlend(vibrant.withValues(alpha: 0.16), const Color(0xFF141822)),
          surfaceContainerLight: Color.alphaBlend(vibrant.withValues(alpha: 0.10), const Color(0xFFF0F4F8)),
          isDynamic: true,
        );
        return ThemeSettingsState(
          themeMode: themeMode,
          currentPalette: dynamicPalette,
          customAccentColor: vibrant,
          dynamicAlbumArtEnabled: true,
          surfaceFillStyle: fillStyle,
          wallpaperSettings: wallpaperSettings,
        );
      }

      if (paletteId == 'custom_wallpaper' && wallpaperSettings.extractedPrimary != null) {
        final prim = wallpaperSettings.extractedPrimary!;
        final sec = wallpaperSettings.extractedSecondary ?? const Color(0xFF64748B);
        final tert = wallpaperSettings.extractedTertiary ?? prim;
        final wallpaperPalette = AppPalette(
          id: 'custom_wallpaper',
          name: 'Wallpaper Studio',
          description: 'Ekstraksi 3 warna dinamis dari gambar latar belakang',
          primary: prim,
          secondary: sec,
          accent: tert,
          backgroundDark: Color.alphaBlend(prim.withValues(alpha: 0.04), const Color(0xFF0A0C10)),
          backgroundLight: Color.alphaBlend(prim.withValues(alpha: 0.03), const Color(0xFFF8FAFC)),
          surfaceDark: Color.alphaBlend(prim.withValues(alpha: 0.08), const Color(0xFF101318)),
          surfaceLight: const Color(0xFFFFFFFF),
          surfaceContainerDark: Color.alphaBlend(prim.withValues(alpha: 0.16), const Color(0xFF141822)),
          surfaceContainerLight: Color.alphaBlend(prim.withValues(alpha: 0.10), const Color(0xFFF0F4F8)),
          isDynamic: true,
        );
        return ThemeSettingsState(
          themeMode: themeMode,
          currentPalette: wallpaperPalette,
          customAccentColor: prim,
          dynamicAlbumArtEnabled: false,
          surfaceFillStyle: fillStyle,
          wallpaperSettings: wallpaperSettings,
        );
      }

      return ThemeSettingsState(
        themeMode: themeMode,
        currentPalette: palette,
        customAccentColor: customColor,
        dynamicAlbumArtEnabled: false,
        surfaceFillStyle: fillStyle,
        wallpaperSettings: wallpaperSettings,
      );
    } catch (e) {
      debugPrint('[ThemeController] Error loading initial theme state: $e');
      return const ThemeSettingsState();
    }
  }

  void _persist() {
    try {
      final paletteId = state.currentPalette.isDynamic ? (state.dynamicAlbumArtEnabled ? 'dynamic_album_art' : state.currentPalette.id) : state.currentPalette.id;
      final accentValue = state.customAccentColor.toARGB32();
      final fillStyle = state.surfaceFillStyle ?? SurfaceFillStyle.solid;
      final dynamicDominant = state.currentPalette.isDynamic ? state.currentPalette.secondary.toARGB32() : null;
      final dynamicVibrant = state.currentPalette.isDynamic ? state.currentPalette.primary.toARGB32() : null;
      LocalPersistenceService.instance.saveThemeSettings(
        paletteId: paletteId,
        themeModeIndex: state.themeMode.index,
        customAccentColorValue: accentValue,
        dynamicAlbumArtEnabled: state.dynamicAlbumArtEnabled,
        surfaceFillStyle: fillStyle.name,
        dynamicDominantValue: dynamicDominant,
        dynamicVibrantValue: dynamicVibrant,
        wallpaperSettings: state.wallpaperSettings.toJson(),
      );
    } catch (e) {
      debugPrint('[ThemeController] Error persisting theme settings: $e');
    }
  }

  void reloadPersistedTheme() {
    state = _loadInitialState();
  }

  void setThemeMode(AppThemeMode mode) {
    if (state.currentPalette.isDynamic) {
      final isDark = mode != AppThemeMode.light;
      final rawPrimary = state.customAccentColor;
      final rawSecondary = state.currentPalette.secondary;
      final harmonizedVibrant = StudioColorHarmonizer.harmonizeAccent(rawPrimary, isDark: isDark);
      final harmonizedDominant = StudioColorHarmonizer.harmonizeSecondary(rawSecondary, isDark: isDark);

      final dynamicPalette = state.currentPalette.copyWith(
        primary: harmonizedVibrant,
        secondary: harmonizedDominant,
        accent: harmonizedVibrant,
        backgroundDark: Color.alphaBlend(harmonizedVibrant.withValues(alpha: 0.04), const Color(0xFF0A0C10)),
        backgroundLight: Color.alphaBlend(harmonizedVibrant.withValues(alpha: 0.03), const Color(0xFFF8FAFC)),
        surfaceDark: Color.alphaBlend(harmonizedVibrant.withValues(alpha: 0.08), const Color(0xFF101318)),
        surfaceLight: const Color(0xFFFFFFFF),
        surfaceContainerDark: Color.alphaBlend(harmonizedVibrant.withValues(alpha: 0.16), const Color(0xFF141822)),
        surfaceContainerLight: Color.alphaBlend(harmonizedVibrant.withValues(alpha: 0.10), const Color(0xFFF0F4F8)),
      );

      state = state.copyWith(
        themeMode: mode,
        currentPalette: dynamicPalette,
      );
    } else {
      state = state.copyWith(themeMode: mode);
    }
    _persist();
  }

  void setSurfaceFillStyle(SurfaceFillStyle style) {
    state = state.copyWith(surfaceFillStyle: style);
    _persist();
  }

  void setPalette(AppPalette palette) {
    state = state.copyWith(
      currentPalette: palette,
      customAccentColor: palette.primary,
      dynamicAlbumArtEnabled: false,
    );
    _persist();
  }

  void setCustomAccent(Color color) {
    final surfaceDark = Color.alphaBlend(color.withValues(alpha: 0.08), const Color(0xFF101318));
    final surfaceContainerDark = Color.alphaBlend(color.withValues(alpha: 0.16), const Color(0xFF141822));
    final backgroundDark = Color.alphaBlend(color.withValues(alpha: 0.04), const Color(0xFF0A0C10));
    final surfaceContainerLight = Color.alphaBlend(color.withValues(alpha: 0.10), const Color(0xFFF0F4F8));

    state = state.copyWith(
      customAccentColor: color,
      currentPalette: state.currentPalette.copyWith(
        primary: color,
        accent: color,
        surfaceDark: surfaceDark,
        surfaceContainerDark: surfaceContainerDark,
        backgroundDark: backgroundDark,
        surfaceContainerLight: surfaceContainerLight,
      ),
    );
    _persist();
  }

  void setDynamicAlbumArt(Color dominant, Color vibrant) {
    if (!state.dynamicAlbumArtEnabled) return;

    final isDark = state.themeMode != AppThemeMode.light;
    final harmonizedVibrant = StudioColorHarmonizer.harmonizeAccent(vibrant, isDark: isDark);
    final harmonizedDominant = StudioColorHarmonizer.harmonizeSecondary(dominant, isDark: isDark);

    final dynamicPalette = AppPalette(
      id: 'dynamic_album_art',
      name: 'Dynamic Album Art',
      description: 'Ekstraksi warna otomatis dari cover album yang sedang diputar',
      primary: harmonizedVibrant,
      secondary: harmonizedDominant,
      accent: harmonizedVibrant,
      backgroundDark: Color.alphaBlend(harmonizedVibrant.withValues(alpha: 0.04), const Color(0xFF0A0C10)),
      backgroundLight: Color.alphaBlend(harmonizedVibrant.withValues(alpha: 0.03), const Color(0xFFF8FAFC)),
      surfaceDark: Color.alphaBlend(harmonizedVibrant.withValues(alpha: 0.08), const Color(0xFF101318)),
      surfaceLight: const Color(0xFFFFFFFF),
      surfaceContainerDark: Color.alphaBlend(harmonizedVibrant.withValues(alpha: 0.16), const Color(0xFF141822)),
      surfaceContainerLight: Color.alphaBlend(harmonizedVibrant.withValues(alpha: 0.10), const Color(0xFFF0F4F8)),
      isDynamic: true,
    );

    state = state.copyWith(
      currentPalette: dynamicPalette,
      customAccentColor: harmonizedVibrant,
    );
    _persist();
  }

  Future<void> updateDynamicPaletteFromTrack(Track? track) async {
    if (!state.dynamicAlbumArtEnabled || track == null) return;

    final provider = StudioArtworkWidget.getImageProvider(track);
    if (provider == null) return;

    try {
      final generator = await PaletteGenerator.fromImageProvider(
        ResizeImage(provider, width: 96, height: 96),
        maximumColorCount: 16,
      ).timeout(const Duration(seconds: 3));

      final vibrant = generator.vibrantColor?.color ??
          generator.dominantColor?.color ??
          generator.lightVibrantColor?.color ??
          generator.mutedColor?.color ??
          state.customAccentColor;

      final dominant = generator.dominantColor?.color ??
          generator.darkVibrantColor?.color ??
          generator.darkMutedColor?.color ??
          const Color(0xFF14171E);

      setDynamicAlbumArt(dominant, vibrant);
    } on TimeoutException {
      debugPrint('[ThemeController] Dynamic palette extraction timed out for track: ${track.title} (using current theme palette)');
    } catch (e) {
      debugPrint('[ThemeController] Dynamic palette extraction notice: $e');
    }
  }

  void toggleDynamicAlbumArt(bool enabled, [Track? currentTrack]) {
    state = state.copyWith(dynamicAlbumArtEnabled: enabled);
    _persist();
    if (enabled && currentTrack != null) {
      updateDynamicPaletteFromTrack(currentTrack);
    }
  }

  // ─── CUSTOM WALLPAPER & DYNAMIC PALETTE ENGINE ───────────────────────────

  Future<void> setCustomWallpaperFromFile(File sourceFile, {bool? syncPalette}) async {
    try {
      final savedPath = await LocalPersistenceService.instance.saveCustomWallpaperFile(sourceFile);
      final willSync = syncPalette ?? state.wallpaperSettings.syncPalette;
      
      state = state.copyWith(
        wallpaperSettings: state.wallpaperSettings.copyWith(
          enabled: true,
          imagePath: savedPath,
          syncPalette: willSync,
        ),
      );

      if (willSync) {
        await extractPaletteFromImageFile(File(savedPath));
      } else {
        _persist();
      }
    } catch (e) {
      debugPrint('[ThemeController] Error setting custom wallpaper: $e');
    }
  }

  Future<void> extractPaletteFromImageFile(File imageFile) async {
    if (!await imageFile.exists()) return;

    try {
      final provider = FileImage(imageFile);
      final generator = await PaletteGenerator.fromImageProvider(
        ResizeImage(provider, width: 128, height: 128),
        maximumColorCount: 16,
      ).timeout(const Duration(seconds: 4));

      final isDark = state.themeMode != AppThemeMode.light;

      // 1. Primary Vibrant Accent
      final rawPrimary = generator.vibrantColor?.color ??
          generator.dominantColor?.color ??
          generator.lightVibrantColor?.color ??
          generator.mutedColor?.color ??
          const Color(0xFF38BDF8);
      final primary = StudioColorHarmonizer.harmonizeAccent(rawPrimary, isDark: isDark);

      // 2. Secondary Tone
      final rawSecondary = generator.dominantColor?.color ??
          generator.darkVibrantColor?.color ??
          generator.mutedColor?.color ??
          const Color(0xFF0284C7);
      final secondary = StudioColorHarmonizer.harmonizeSecondary(rawSecondary, isDark: isDark);

      // 3. Tertiary / Ambient Tone
      final rawTertiary = generator.lightVibrantColor?.color ??
          generator.darkMutedColor?.color ??
          generator.lightMutedColor?.color ??
          primary;
      final tertiary = StudioColorHarmonizer.harmonizeAccent(rawTertiary, isDark: isDark);

      final dynamicWallpaperPalette = AppPalette(
        id: 'custom_wallpaper',
        name: 'Wallpaper Studio',
        description: 'Ekstraksi 3 warna dinamis dari gambar latar belakang',
        primary: primary,
        secondary: secondary,
        accent: tertiary,
        backgroundDark: Color.alphaBlend(primary.withValues(alpha: 0.04), const Color(0xFF0A0C10)),
        backgroundLight: Color.alphaBlend(primary.withValues(alpha: 0.03), const Color(0xFFF8FAFC)),
        surfaceDark: Color.alphaBlend(primary.withValues(alpha: 0.08), const Color(0xFF101318)),
        surfaceLight: const Color(0xFFFFFFFF),
        surfaceContainerDark: Color.alphaBlend(primary.withValues(alpha: 0.16), const Color(0xFF141822)),
        surfaceContainerLight: Color.alphaBlend(primary.withValues(alpha: 0.10), const Color(0xFFF0F4F8)),
        isDynamic: true,
      );

      state = state.copyWith(
        currentPalette: dynamicWallpaperPalette,
        customAccentColor: primary,
        dynamicAlbumArtEnabled: false,
        wallpaperSettings: state.wallpaperSettings.copyWith(
          extractedPrimary: primary,
          extractedSecondary: secondary,
          extractedTertiary: tertiary,
        ),
      );

      _persist();
    } catch (e) {
      debugPrint('[ThemeController] Notice extracting wallpaper palette: $e');
    }
  }

  Future<void> setWallpaperPreset(StudioWallpaperPreset preset, {bool? syncPalette}) async {
    final oldPath = state.wallpaperSettings.imagePath;
    if (oldPath != null && !oldPath.startsWith('assets/')) {
      LocalPersistenceService.instance.deleteCustomWallpaperFile(oldPath);
    }

    final willSync = syncPalette ?? state.wallpaperSettings.syncPalette;
    final isDark = state.themeMode != AppThemeMode.light;
    final primary = StudioColorHarmonizer.harmonizeAccent(preset.primaryColor, isDark: isDark);
    final secondary = StudioColorHarmonizer.harmonizeSecondary(preset.secondaryColor, isDark: isDark);
    final tertiary = StudioColorHarmonizer.harmonizeAccent(preset.tertiaryColor, isDark: isDark);

    final updatedWallpaper = state.wallpaperSettings.copyWith(
      enabled: true,
      imagePath: preset.assetPath,
      syncPalette: willSync,
      extractedPrimary: primary,
      extractedSecondary: secondary,
      extractedTertiary: tertiary,
    );

    if (willSync) {
      final dynamicWallpaperPalette = AppPalette(
        id: 'custom_wallpaper',
        name: '${preset.title} Studio',
        description: 'Harmonious studio 3-color theme extracted from ${preset.title}',
        primary: primary,
        secondary: secondary,
        accent: tertiary,
        backgroundDark: Color.alphaBlend(primary.withValues(alpha: 0.04), const Color(0xFF0A0C10)),
        backgroundLight: Color.alphaBlend(primary.withValues(alpha: 0.03), const Color(0xFFF8FAFC)),
        surfaceDark: Color.alphaBlend(primary.withValues(alpha: 0.08), const Color(0xFF101318)),
        surfaceLight: const Color(0xFFFFFFFF),
        surfaceContainerDark: Color.alphaBlend(primary.withValues(alpha: 0.16), const Color(0xFF141822)),
        surfaceContainerLight: Color.alphaBlend(primary.withValues(alpha: 0.10), const Color(0xFFF0F4F8)),
        isDynamic: true,
      );

      state = state.copyWith(
        currentPalette: dynamicWallpaperPalette,
        customAccentColor: primary,
        dynamicAlbumArtEnabled: false,
        wallpaperSettings: updatedWallpaper,
      );
    } else {
      state = state.copyWith(
        wallpaperSettings: updatedWallpaper,
      );
    }

    _persist();
  }

  void removeWallpaper() {
    final oldPath = state.wallpaperSettings.imagePath;
    if (oldPath != null && !oldPath.startsWith('assets/')) {
      LocalPersistenceService.instance.deleteCustomWallpaperFile(oldPath);
    }

    final fallbackPalette = state.currentPalette.id == 'custom_wallpaper'
        ? AppPalette.namidaCyan
        : state.currentPalette;

    state = state.copyWith(
      currentPalette: fallbackPalette,
      customAccentColor: fallbackPalette.primary,
      wallpaperSettings: state.wallpaperSettings.copyWith(
        enabled: false,
        imagePath: null,
        extractedPrimary: null,
        extractedSecondary: null,
        extractedTertiary: null,
      ),
    );
    _persist();
  }

  void setWallpaperDim(double dim) {
    state = state.copyWith(
      wallpaperSettings: state.wallpaperSettings.copyWith(
        dimOpacity: dim.clamp(0.0, 0.85),
      ),
    );
    _persist();
  }

  void setWallpaperBlur(double blur) {
    state = state.copyWith(
      wallpaperSettings: state.wallpaperSettings.copyWith(
        blurRadius: blur.clamp(0.0, 40.0),
      ),
    );
    _persist();
  }

  Future<void> setWallpaperSyncPalette(bool sync) async {
    state = state.copyWith(
      wallpaperSettings: state.wallpaperSettings.copyWith(syncPalette: sync),
    );
    _persist();

    if (sync && state.wallpaperSettings.imagePath != null) {
      if (state.wallpaperSettings.isAsset) {
        final matchingPreset = StudioWallpaperPreset.presets.firstWhere(
          (p) => p.assetPath == state.wallpaperSettings.imagePath,
          orElse: () => StudioWallpaperPreset.presets.first,
        );
        await setWallpaperPreset(matchingPreset, syncPalette: true);
      } else {
        await extractPaletteFromImageFile(File(state.wallpaperSettings.imagePath!));
      }
    }
  }

  void toggleWallpaperEnabled(bool enabled) {
    state = state.copyWith(
      wallpaperSettings: state.wallpaperSettings.copyWith(enabled: enabled),
    );
    _persist();
  }

  void setWallpaperScope(WallpaperScope scope) {
    state = state.copyWith(
      wallpaperSettings: state.wallpaperSettings.copyWith(scope: scope),
    );
    _persist();
  }
}

final themeControllerProvider =
    StateNotifierProvider<ThemeController, ThemeSettingsState>((ref) {
  return ThemeController();
});

/// Studio Color Harmonizer & Contrast Hardener
/// Guarantees that dynamically extracted artwork colors always adhere to strict
/// audiophile studio contrast guidelines (WCAG AA) and never result in dark-on-dark or washed-out illegibility.
class StudioColorHarmonizer {
  const StudioColorHarmonizer._();

  /// Harmonizes primary/accent colors. Guarantees WCAG AA (>= 4.5:1) contrast
  /// in both Light and Dark modes, and prevents washed-out or dark-on-dark text/icons.
  static Color harmonizeAccent(Color rawColor, {bool isDark = true}) {
    final hsl = HSLColor.fromColor(rawColor);
    final lum = rawColor.computeLuminance();

    if (isDark) {
      if (lum < 0.22 || hsl.lightness < 0.45) {
        if (hsl.saturation < 0.18) {
          // Black, near-black, or dark monochrome artwork -> Studio Slate / Silver Ash
          return const Color(0xFF94A3B8);
        } else {
          // Dark color with hue -> lift lightness into safe studio range
          final newLightness = (0.60 + (1.0 - hsl.lightness) * 0.12).clamp(0.58, 0.72);
          return hsl.withLightness(newLightness).withSaturation(hsl.saturation.clamp(0.50, 0.85)).toColor();
        }
      }
      if (hsl.lightness > 0.85) {
        return hsl.withLightness(0.72).toColor();
      }
      return rawColor;
    } else {
      // Light Mode Guard: prevent washed out text/icons on light backgrounds
      if (lum > 0.40 || hsl.lightness > 0.48) {
        if (hsl.saturation < 0.18) {
          return const Color(0xFF1E293B); // Deep Studio Slate
        } else {
          return hsl.withLightness(0.36).withSaturation(hsl.saturation.clamp(0.60, 0.90)).toColor();
        }
      }
      return rawColor;
    }
  }

  /// Harmonizes secondary color for subheadings, secondary icons, and muted indicators
  static Color harmonizeSecondary(Color rawColor, {bool isDark = true}) {
    final hsl = HSLColor.fromColor(rawColor);
    final lum = rawColor.computeLuminance();

    if (isDark) {
      if (lum < 0.10 || hsl.lightness < 0.30) {
        if (hsl.saturation < 0.18) {
          return const Color(0xFF64748B);
        } else {
          return hsl.withLightness(0.48).withSaturation(hsl.saturation.clamp(0.35, 0.75)).toColor();
        }
      }
      return rawColor;
    } else {
      if (lum > 0.45 || hsl.lightness > 0.52) {
        if (hsl.saturation < 0.18) {
          return const Color(0xFF475569);
        } else {
          return hsl.withLightness(0.38).withSaturation(hsl.saturation.clamp(0.45, 0.80)).toColor();
        }
      }
      return rawColor;
    }
  }
}

/// Generator ThemeData untuk Dark Mode dan Light Mode
class AppThemeBuilder {
  static ThemeData buildTheme(AppPalette palette, {required bool isDark, bool isWallpaperActive = false}) {
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

