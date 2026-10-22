import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:palette_generator/palette_generator.dart';
import '../../core/database/local_persistence_service.dart';
import '../../core/widgets/studio_artwork_widget.dart';
import '../../features/player/domain/track.dart';
import 'domain/app_palette.dart';
import 'domain/app_theme_models.dart';
import 'domain/studio_color_harmonizer.dart';
import 'domain/studio_wallpaper_presets.dart';

// Re-export domain models & builders for backward compatibility
export 'domain/app_palette.dart';
export 'domain/app_theme_builder.dart';
export 'domain/app_theme_models.dart';
export 'domain/studio_color_harmonizer.dart';
export 'domain/studio_wallpaper_presets.dart';

/// State untuk Theming Aplikasi
@immutable
class ThemeSettingsState {
  final AppThemeMode themeMode;
  final AppPalette currentPalette;
  final Color customAccentColor;
  final bool dynamicAlbumArtEnabled;
  final SurfaceFillStyle? surfaceFillStyle;
  final WallpaperSettings wallpaperSettings;

  SurfaceFillStyle get effectiveSurfaceFillStyle => SurfaceFillStyle.solid;
  bool get isSolidStyle => true;

  const ThemeSettingsState({
    this.themeMode = AppThemeMode.dark,
    this.currentPalette = AppPalette.simpleAsF,
    this.customAccentColor = const Color(0xFF10B981),
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

  void hydrateFromStorage() {
    state = _loadInitialState();
  }

  static ThemeSettingsState _loadInitialState() {
    try {
      final saved = LocalPersistenceService.instance.getThemeSettings();
      var paletteId = saved['palette_id'] as String? ?? 'simple_as_f';
      if (paletteId == 'obsidian_cyan') {
        paletteId = 'simple_as_f';
      }
      final modeIndex = saved['theme_mode'] as int? ?? AppThemeMode.dark.index;
      var accentVal = saved['custom_accent'] as int? ?? 0xFF2EE672;
      if (accentVal == 0xFF38BDF8) {
        accentVal = 0xFF2EE672;
      }
      final dynamicArt = saved['dynamic_album_art'] as bool? ?? false;
      final fillStyleStr = saved['surface_fill_style'] as String? ?? 'solid';

      final wallpaperJson = LocalPersistenceService.instance.getWallpaperSettings();
      final wallpaperSettings = WallpaperSettings.fromJson(wallpaperJson);

      final themeMode = (modeIndex >= 0 && modeIndex < AppThemeMode.values.length)
          ? AppThemeMode.values[modeIndex]
          : AppThemeMode.dark;

      final palette = AppPalette.allPresets.firstWhere(
        (p) => p.id == paletteId,
        orElse: () => AppPalette.simpleAsF,
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
      wallpaperSettings: state.wallpaperSettings.copyWith(syncPalette: false),
    );
    _persist();
  }

  void setCustomAccent(Color color) {
    final isOled = state.currentPalette.isOledBlack;
    final surfaceDark = isOled ? const Color(0xFF0A0A0A) : const Color(0xFF12141A);
    final surfaceContainerDark = isOled ? const Color(0xFF141414) : const Color(0xFF16181F);
    final backgroundDark = isOled ? const Color(0xFF000000) : const Color(0xFF0D0E12);
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
        ? AppPalette.simpleAsF
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
