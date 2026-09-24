import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_typography.dart';

/// Pilihan Mode Tema
enum AppThemeMode {
  system(ThemeMode.system, 'System', 'Mengikuti preferensi sistem OS', Icons.brightness_auto),
  light(ThemeMode.light, 'Light', 'Studio Clean Light Champagne', Icons.light_mode_outlined),
  dark(ThemeMode.dark, 'Dark', 'Studio Dark Obsidian / OLED', Icons.dark_mode_outlined);

  final ThemeMode mode;
  final String label;
  final String description;
  final IconData icon;
  const AppThemeMode(this.mode, this.label, this.description, this.icon);
}

/// Model Palet Warna Kustom Terinspirasi Namida
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

  // ─── Curated Presets ────────────────────────────────────────────────────────

  static const AppPalette namidaCyan = AppPalette(
    id: 'namida_cyan',
    name: 'Namida Obsidian Cyan',
    description: 'Namida cyber-neon cyan dengan latar studio obsidian pekat',
    primary: Color(0xFF00E5FF),
    secondary: Color(0xFF0288D1),
    accent: Color(0xFF00E5FF),
    backgroundDark: Color(0xFF0D0F14),
    backgroundLight: Color(0xFFF4F6F9),
    surfaceDark: Color(0xFF141922),
    surfaceLight: Color(0xFFFFFFFF),
    surfaceContainerDark: Color(0xFF1B2230),
    surfaceContainerLight: Color(0xFFE9ECF2),
  );

  static const AppPalette amberTube = AppPalette(
    id: 'amber_tube',
    name: 'Amber Tube Glow',
    description: 'Kehangatan lampu tabung analog triode dan aksen amber bersinar',
    primary: Color(0xFFFF9F0A),
    secondary: Color(0xFFFF6D00),
    accent: Color(0xFFFF9F0A),
    backgroundDark: Color(0xFF100D0A),
    backgroundLight: Color(0xFFFAF7F2),
    surfaceDark: Color(0xFF1A1612),
    surfaceLight: Color(0xFFFFFFFF),
    surfaceContainerDark: Color(0xFF26201A),
    surfaceContainerLight: Color(0xFFF0EBE3),
  );

  static const AppPalette emeraldHiFi = AppPalette(
    id: 'emerald_hifi',
    name: 'Emerald HiFi',
    description: 'Warna mint emerald presisi khas instrumen audio mastering',
    primary: Color(0xFF00E676),
    secondary: Color(0xFF00BFA5),
    accent: Color(0xFF00E676),
    backgroundDark: Color(0xFF09120D),
    backgroundLight: Color(0xFFF2FAF5),
    surfaceDark: Color(0xFF101E17),
    surfaceLight: Color(0xFFFFFFFF),
    surfaceContainerDark: Color(0xFF182C22),
    surfaceContainerLight: Color(0xFFE4F2EA),
  );

  static const AppPalette electricPurple = AppPalette(
    id: 'electric_purple',
    name: 'Electric Purple',
    description: 'Nuansa studio ungu elektrik modern berenergi tinggi',
    primary: Color(0xFFBF5AF2),
    secondary: Color(0xFF7B1FA2),
    accent: Color(0xFFCE93D8),
    backgroundDark: Color(0xFF110A18),
    backgroundLight: Color(0xFFF8F2FC),
    surfaceDark: Color(0xFF1B1226),
    surfaceLight: Color(0xFFFFFFFF),
    surfaceContainerDark: Color(0xFF281B38),
    surfaceContainerLight: Color(0xFFEDE2F5),
  );

  static const AppPalette crimsonPassion = AppPalette(
    id: 'crimson_passion',
    name: 'Crimson Passion',
    description: 'Aksen merah audiophile berani dengan kontras tinggi',
    primary: Color(0xFFFF3B30),
    secondary: Color(0xFFC62828),
    accent: Color(0xFFFF5252),
    backgroundDark: Color(0xFF140A0B),
    backgroundLight: Color(0xFFFCF3F3),
    surfaceDark: Color(0xFF201113),
    surfaceLight: Color(0xFFFFFFFF),
    surfaceContainerDark: Color(0xFF2E191C),
    surfaceContainerLight: Color(0xFFF5E4E4),
  );

  static const AppPalette trueOledBlack = AppPalette(
    id: 'true_oled',
    name: 'True OLED Black',
    description: 'Hitam murni 100% untuk layar AMOLED tanpa konsumsi baterai',
    primary: Color(0xFF00E5FF),
    secondary: Color(0xFF00B0FF),
    accent: Color(0xFF00FFA3),
    backgroundDark: Color(0xFF000000),
    backgroundLight: Color(0xFFF8F9FA),
    surfaceDark: Color(0xFF0A0A0A),
    surfaceLight: Color(0xFFFFFFFF),
    surfaceContainerDark: Color(0xFF141414),
    surfaceContainerLight: Color(0xFFEEEEEE),
    isOledBlack: true,
  );

  static const List<AppPalette> allPresets = [
    namidaCyan,
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

  const ThemeSettingsState({
    this.themeMode = AppThemeMode.dark,
    this.currentPalette = AppPalette.namidaCyan,
    this.customAccentColor = const Color(0xFF00E5FF),
    this.dynamicAlbumArtEnabled = false,
  });

  ThemeSettingsState copyWith({
    AppThemeMode? themeMode,
    AppPalette? currentPalette,
    Color? customAccentColor,
    bool? dynamicAlbumArtEnabled,
  }) {
    return ThemeSettingsState(
      themeMode: themeMode ?? this.themeMode,
      currentPalette: currentPalette ?? this.currentPalette,
      customAccentColor: customAccentColor ?? this.customAccentColor,
      dynamicAlbumArtEnabled: dynamicAlbumArtEnabled ?? this.dynamicAlbumArtEnabled,
    );
  }
}

/// Controller untuk Theme Mode dan Custom Palette
class ThemeController extends StateNotifier<ThemeSettingsState> {
  ThemeController() : super(const ThemeSettingsState());

  void setThemeMode(AppThemeMode mode) {
    state = state.copyWith(themeMode: mode);
  }

  void setPalette(AppPalette palette) {
    state = state.copyWith(
      currentPalette: palette,
      customAccentColor: palette.primary,
      dynamicAlbumArtEnabled: false,
    );
  }

  void setCustomAccent(Color color) {
    state = state.copyWith(
      customAccentColor: color,
      currentPalette: state.currentPalette.copyWith(
        primary: color,
        accent: color,
      ),
    );
  }

  void setDynamicAlbumArt(Color dominant, Color vibrant) {
    if (!state.dynamicAlbumArtEnabled) return;

    final dynamicPalette = AppPalette(
      id: 'dynamic_album_art',
      name: 'Dynamic Album Art',
      description: 'Ekstraksi warna otomatis dari cover album yang sedang diputar',
      primary: vibrant,
      secondary: dominant,
      accent: vibrant,
      backgroundDark: Color.lerp(const Color(0xFF0A0C10), dominant, 0.12)!,
      backgroundLight: const Color(0xFFF5F7FA),
      surfaceDark: Color.lerp(const Color(0xFF14171E), dominant, 0.18)!,
      surfaceLight: const Color(0xFFFFFFFF),
      surfaceContainerDark: Color.lerp(const Color(0xFF1D222C), dominant, 0.25)!,
      surfaceContainerLight: const Color(0xFFE8ECF2),
      isDynamic: true,
    );

    state = state.copyWith(
      currentPalette: dynamicPalette,
      customAccentColor: vibrant,
    );
  }

  void toggleDynamicAlbumArt(bool enabled) {
    state = state.copyWith(dynamicAlbumArtEnabled: enabled);
  }
}

final themeControllerProvider =
    StateNotifierProvider<ThemeController, ThemeSettingsState>((ref) {
  return ThemeController();
});

/// Generator ThemeData untuk Dark Mode dan Light Mode
class AppThemeBuilder {
  static ThemeData buildTheme(AppPalette palette, {required bool isDark}) {
    final bg = isDark ? palette.backgroundDark : palette.backgroundLight;
    final surface = isDark ? palette.surfaceDark : palette.surfaceLight;
    final surfaceContainer = isDark ? palette.surfaceContainerDark : palette.surfaceContainerLight;
    final textPrimary = isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A);
    final textSecondary = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final outline = isDark
        ? (palette.isOledBlack ? const Color(0xFF222222) : const Color(0xFF263140))
        : const Color(0xFFCBD5E1);

    final colorScheme = isDark
        ? ColorScheme.dark(
            primary: palette.primary,
            onPrimary: Colors.black,
            secondary: palette.secondary,
            onSecondary: Colors.white,
            tertiary: palette.accent,
            surface: surface,
            onSurface: textPrimary,
            surfaceContainer: surfaceContainer,
            outline: outline,
            error: const Color(0xFFFF453A),
          )
        : ColorScheme.light(
            primary: palette.primary,
            onPrimary: Colors.white,
            secondary: palette.secondary,
            onSecondary: Colors.white,
            tertiary: palette.accent,
            surface: surface,
            onSurface: textPrimary,
            surfaceContainer: surfaceContainer,
            outline: outline,
            error: const Color(0xFFD32F2F),
          );

    return ThemeData(
      useMaterial3: true,
      brightness: isDark ? Brightness.dark : Brightness.light,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: bg,
      cardColor: surface,
      dividerColor: outline,
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
        inactiveTrackColor: outline,
        thumbColor: palette.primary,
        overlayColor: palette.primary.withValues(alpha: 0.15),
        trackHeight: 3,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
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
}
