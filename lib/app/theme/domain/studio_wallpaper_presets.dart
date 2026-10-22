import 'package:flutter/material.dart';

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
