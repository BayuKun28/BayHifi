import 'package:flutter/material.dart';

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

  static const AppPalette simpleAsF = AppPalette(
    id: 'simple_as_f',
    name: 'Simple as F*** (Matte Obsidian)',
    description: 'Ultra-minimalist matte obsidian dark with clean studio emerald mint accents',
    primary: Color(0xFF10B981),
    secondary: Color(0xFF34D399),
    accent: Color(0xFF10B981),
    backgroundDark: Color(0xFF0D0E12),
    backgroundLight: Color(0xFFF1F8F4),
    surfaceDark: Color(0xFF12141A),
    surfaceLight: Color(0xFFF7FBF9),
    surfaceContainerDark: Color(0xFF16181F),
    surfaceContainerLight: Color(0xFFE2F5EA),
  );

  static const AppPalette namidaCyan = AppPalette(
    id: 'obsidian_cyan',
    name: 'Obsidian Cyan',
    description: 'Refined sky cyan with deep obsidian studio background',
    primary: Color(0xFF38BDF8),
    secondary: Color(0xFF0284C7),
    accent: Color(0xFF38BDF8),
    backgroundDark: Color(0xFF0D0E12),
    backgroundLight: Color(0xFFF1F6FB),
    surfaceDark: Color(0xFF12141A),
    surfaceLight: Color(0xFFF7FAFD),
    surfaceContainerDark: Color(0xFF16181F),
    surfaceContainerLight: Color(0xFFE2EFF9),
  );

  static const AppPalette amberTube = AppPalette(
    id: 'amber_tube',
    name: 'Amber Tube Glow',
    description: 'Warmth of analog triode tube glow and radiant amber accents',
    primary: Color(0xFFF59E0B),
    secondary: Color(0xFFD97706),
    accent: Color(0xFFF59E0B),
    backgroundDark: Color(0xFF0D0E12),
    backgroundLight: Color(0xFFFAF6F0),
    surfaceDark: Color(0xFF12141A),
    surfaceLight: Color(0xFFFCFAF6),
    surfaceContainerDark: Color(0xFF16181F),
    surfaceContainerLight: Color(0xFFF6EADB),
  );

  static const AppPalette emeraldHiFi = AppPalette(
    id: 'emerald_hifi',
    name: 'Emerald HiFi',
    description: 'Precision emerald mint aesthetic of mastering hardware instruments',
    primary: Color(0xFF10B981),
    secondary: Color(0xFF059669),
    accent: Color(0xFF10B981),
    backgroundDark: Color(0xFF0D0E12),
    backgroundLight: Color(0xFFF0F8F4),
    surfaceDark: Color(0xFF12141A),
    surfaceLight: Color(0xFFF6FBF8),
    surfaceContainerDark: Color(0xFF16181F),
    surfaceContainerLight: Color(0xFFDDF5EA),
  );

  static const AppPalette electricPurple = AppPalette(
    id: 'electric_purple',
    name: 'Studio Violet',
    description: 'Modern studio violet and lavender mastering aesthetic',
    primary: Color(0xFFA855F7),
    secondary: Color(0xFF7E22CE),
    accent: Color(0xFFC084FC),
    backgroundDark: Color(0xFF0D0E12),
    backgroundLight: Color(0xFFF8F3FC),
    surfaceDark: Color(0xFF12141A),
    surfaceLight: Color(0xFFFAF6FD),
    surfaceContainerDark: Color(0xFF16181F),
    surfaceContainerLight: Color(0xFFF0E3FA),
  );

  static const AppPalette crimsonPassion = AppPalette(
    id: 'crimson_passion',
    name: 'Crimson Passion',
    description: 'Bold audiophile crimson red with ultra-high contrast',
    primary: Color(0xFFF43F5E),
    secondary: Color(0xFFBE123C),
    accent: Color(0xFFFB7185),
    backgroundDark: Color(0xFF0D0E12),
    backgroundLight: Color(0xFFFAF2F4),
    surfaceDark: Color(0xFF12141A),
    surfaceLight: Color(0xFFFDF6F8),
    surfaceContainerDark: Color(0xFF16181F),
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
    backgroundDark: Color(0xFF0D0E12),
    backgroundLight: Color(0xFFF7F5FC),
    surfaceDark: Color(0xFF12141A),
    surfaceLight: Color(0xFFFAF8FE),
    surfaceContainerDark: Color(0xFF16181F),
    surfaceContainerLight: Color(0xFFECE7F8),
  );

  static const AppPalette pastelSage = AppPalette(
    id: 'pastel_sage',
    name: 'Pastel Sage Mint',
    description: 'Muted tranquil pastel sage green for relaxed studio listening',
    primary: Color(0xFF93D5C0),
    secondary: Color(0xFF72B8A2),
    accent: Color(0xFF93D5C0),
    backgroundDark: Color(0xFF0D0E12),
    backgroundLight: Color(0xFFF2F8F5),
    surfaceDark: Color(0xFF12141A),
    surfaceLight: Color(0xFFF7FCFA),
    surfaceContainerDark: Color(0xFF16181F),
    surfaceContainerLight: Color(0xFFE2F3EC),
  );

  static const AppPalette pastelSky = AppPalette(
    id: 'pastel_sky',
    name: 'Pastel Powder Sky',
    description: 'Airy and luminous soft pastel blue studio aesthetic',
    primary: Color(0xFF9AC8EB),
    secondary: Color(0xFF74ABD4),
    accent: Color(0xFF9AC8EB),
    backgroundDark: Color(0xFF0D0E12),
    backgroundLight: Color(0xFFF2F7FB),
    surfaceDark: Color(0xFF12141A),
    surfaceLight: Color(0xFFF7FAFD),
    surfaceContainerDark: Color(0xFF16181F),
    surfaceContainerLight: Color(0xFFE2EFF8),
  );

  static const AppPalette pastelPeach = AppPalette(
    id: 'pastel_peach',
    name: 'Pastel Soft Peach',
    description: 'Warm and gentle acoustic pastel apricot and peach glow',
    primary: Color(0xFFF7B297),
    secondary: Color(0xFFDE9173),
    accent: Color(0xFFF7B297),
    backgroundDark: Color(0xFF0D0E12),
    backgroundLight: Color(0xFFFAF4F1),
    surfaceDark: Color(0xFF12141A),
    surfaceLight: Color(0xFFFCF8F6),
    surfaceContainerDark: Color(0xFF16181F),
    surfaceContainerLight: Color(0xFFF9EAE3),
  );

  static const AppPalette pastelBlush = AppPalette(
    id: 'pastel_blush',
    name: 'Pastel Blush Rose',
    description: 'Soft studio blush rose with delicate acoustic warmth',
    primary: Color(0xFFF2A7B5),
    secondary: Color(0xFFD78494),
    accent: Color(0xFFF2A7B5),
    backgroundDark: Color(0xFF0D0E12),
    backgroundLight: Color(0xFFFAF3F5),
    surfaceDark: Color(0xFF12141A),
    surfaceLight: Color(0xFFFCF7F9),
    surfaceContainerDark: Color(0xFF16181F),
    surfaceContainerLight: Color(0xFFF8E7EC),
  );

  static const AppPalette pastelButter = AppPalette(
    id: 'pastel_butter',
    name: 'Pastel Butter Cream',
    description: 'Velvety warm studio cream with muted vintage gold touch',
    primary: Color(0xFFE8D18C),
    secondary: Color(0xFFCDB367),
    accent: Color(0xFFE8D18C),
    backgroundDark: Color(0xFF0D0E12),
    backgroundLight: Color(0xFFFAF8EE),
    surfaceDark: Color(0xFF12141A),
    surfaceLight: Color(0xFFFCFAF2),
    surfaceContainerDark: Color(0xFF16181F),
    surfaceContainerLight: Color(0xFFF7F3DC),
  );

  static const AppPalette nordicSlate = AppPalette(
    id: 'nordic_slate',
    name: 'Nordic Slate Frost',
    description: 'Minimalist Scandinavian studio slate blue and cool brushed silver tone',
    primary: Color(0xFF64748B),
    secondary: Color(0xFF475569),
    accent: Color(0xFF94A3B8),
    backgroundDark: Color(0xFF0D0E12),
    backgroundLight: Color(0xFFF2F5F8),
    surfaceDark: Color(0xFF12141A),
    surfaceLight: Color(0xFFF8FAFC),
    surfaceContainerDark: Color(0xFF16181F),
    surfaceContainerLight: Color(0xFFE6ECF2),
  );

  static const AppPalette terracottaClay = AppPalette(
    id: 'terracotta_clay',
    name: 'Terracotta Clay',
    description: 'Warm acoustic earth, organic ceramic kiln and burnt sienna tone',
    primary: Color(0xFFC2410C),
    secondary: Color(0xFF9A3412),
    accent: Color(0xFFEA580C),
    backgroundDark: Color(0xFF0D0E12),
    backgroundLight: Color(0xFFFAF4F0),
    surfaceDark: Color(0xFF12141A),
    surfaceLight: Color(0xFFFCF8F5),
    surfaceContainerDark: Color(0xFF16181F),
    surfaceContainerLight: Color(0xFFF7ECE4),
  );

  static const AppPalette matchaBotanical = AppPalette(
    id: 'matcha_botanical',
    name: 'Matcha Botanical',
    description: 'Deep organic matcha green tea and bamboo studio tranquility',
    primary: Color(0xFF15803D),
    secondary: Color(0xFF166534),
    accent: Color(0xFF22C55E),
    backgroundDark: Color(0xFF0D0E12),
    backgroundLight: Color(0xFFF1F7F3),
    surfaceDark: Color(0xFF12141A),
    surfaceLight: Color(0xFFF7FAF7),
    surfaceContainerDark: Color(0xFF16181F),
    surfaceContainerLight: Color(0xFFE2F0E5),
  );

  static const AppPalette midnightSapphire = AppPalette(
    id: 'midnight_sapphire',
    name: 'Midnight Sapphire',
    description: 'Deep naval sapphire blue and cobalt mastering console tone',
    primary: Color(0xFF2563EB),
    secondary: Color(0xFF1D4ED8),
    accent: Color(0xFF3B82F6),
    backgroundDark: Color(0xFF0D0E12),
    backgroundLight: Color(0xFFF1F5FC),
    surfaceDark: Color(0xFF12141A),
    surfaceLight: Color(0xFFF7FAFD),
    surfaceContainerDark: Color(0xFF16181F),
    surfaceContainerLight: Color(0xFFE3EDFA),
  );

  static const AppPalette vintageBrass = AppPalette(
    id: 'vintage_brass',
    name: 'Vintage Brass & Walnut',
    description: 'Luxury vintage vacuum tube amplifier brass and dark walnut aesthetic',
    primary: Color(0xFFCA8A04),
    secondary: Color(0xFFA16207),
    accent: Color(0xFFEAB308),
    backgroundDark: Color(0xFF0D0E12),
    backgroundLight: Color(0xFFFAF7EE),
    surfaceDark: Color(0xFF12141A),
    surfaceLight: Color(0xFFFCF9F2),
    surfaceContainerDark: Color(0xFF16181F),
    surfaceContainerLight: Color(0xFFF5EFDC),
  );

  static const AppPalette mochaEspresso = AppPalette(
    id: 'mocha_espresso',
    name: 'Mocha Espresso',
    description: 'Rich artisanal dark roast coffee and warm roasted cacao studio tone',
    primary: Color(0xFF78350F),
    secondary: Color(0xFF92400E),
    accent: Color(0xFFB45309),
    backgroundDark: Color(0xFF0D0E12),
    backgroundLight: Color(0xFFFAF4F0),
    surfaceDark: Color(0xFF12141A),
    surfaceLight: Color(0xFFFCF8F5),
    surfaceContainerDark: Color(0xFF16181F),
    surfaceContainerLight: Color(0xFFF6EDE6),
  );

  static const AppPalette proCarbon = AppPalette(
    id: 'pro_carbon',
    name: 'Monochrome Pro Carbon',
    description: 'High-contrast pure grayscale studio reference mastering monitor aesthetic',
    primary: Color(0xFF71717A),
    secondary: Color(0xFF52525B),
    accent: Color(0xFFA1A1AA),
    backgroundDark: Color(0xFF0D0E12),
    backgroundLight: Color(0xFFF4F4F5),
    surfaceDark: Color(0xFF12141A),
    surfaceLight: Color(0xFFFAFAFA),
    surfaceContainerDark: Color(0xFF16181F),
    surfaceContainerLight: Color(0xFFEAEAEB),
  );

  static const List<AppPalette> allPresets = [
    simpleAsF,
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
