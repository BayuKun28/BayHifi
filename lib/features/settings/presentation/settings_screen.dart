import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/theme_mode_controller.dart';
import '../../../app/theme/app_typography.dart';

/// Halaman Pengaturan (Settings & Personalization)
/// Terinspirasi dari Namida dengan kustomisasi palet warna, ThemeMode (Dark/Light/System),
/// dan konfigurasi audio engine.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const List<Color> _accentOptions = [
    Color(0xFF00E5FF), // Namida Cyan
    Color(0xFFFF9F0A), // Tube Amber
    Color(0xFF00E676), // Mint Emerald
    Color(0xFFBF5AF2), // Electric Purple
    Color(0xFFFF3B30), // Crimson Red
    Color(0xFFFFD60A), // HiFi Gold
    Color(0xFFFF2D55), // Hot Pink
    Color(0xFF29B6F6), // Sky Blue
    Color(0xFF00FFA3), // Neon Mint
    Color(0xFFE040FB), // Magenta
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeControllerProvider);
    final themeNotifier = ref.read(themeControllerProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('PENGATURAN & PERSONALISASI'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.4),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.palette_outlined,
                  size: 13,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  themeState.currentPalette.name,
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96), // Extra bottom padding for floating miniplayer
        children: [
          // ─── 1. LIVE PREVIEW CARD ─────────────────────────────────────────
          _buildSectionHeader(context, 'PREVIEW TEMA AKTIF', Icons.visibility_outlined),
          const SizedBox(height: 8),
          _buildLiveThemePreview(context, themeState),
          const SizedBox(height: 20),

          // ─── 2. THEME MODE (SYSTEM / LIGHT / DARK) ────────────────────────
          _buildSectionHeader(context, 'MODE TAMPILAN (THEME MODE)', Icons.brightness_6_outlined),
          const SizedBox(height: 8),
          _buildThemeModeSelector(context, themeState, themeNotifier),
          const SizedBox(height: 20),

          // ─── 3. NAMIDA CUSTOM PALETTES ────────────────────────────────────
          _buildSectionHeader(context, 'PALET WARNA STUDIO (NAMIDA PRESETS)', Icons.color_lens_outlined),
          const SizedBox(height: 8),
          _buildPalettesGrid(context, themeState, themeNotifier),
          const SizedBox(height: 20),

          // ─── 4. CUSTOM ACCENT COLOR PICKER ────────────────────────────────
          _buildSectionHeader(context, 'WARNA AKSEN KUSTOM (ACCENT COLOR)', Icons.colorize_outlined),
          const SizedBox(height: 8),
          _buildAccentPicker(context, themeState, themeNotifier),
          const SizedBox(height: 20),

          // ─── 5. DYNAMIC ALBUM ART MONET THEME ─────────────────────────────
          _buildSectionHeader(context, 'DYNAMIC ALBUM ART PALETTE', Icons.auto_awesome),
          const SizedBox(height: 8),
          _buildDynamicAlbumArtTile(context, themeState, themeNotifier),
          const SizedBox(height: 20),

          // ─── 6. HARDWARE AUDIO & BIT-PERFECT DAC ──────────────────────────
          _buildSectionHeader(context, 'AUDIO ENGINE & HARDWARE DAC', Icons.memory),
          const SizedBox(height: 8),
          _buildAudioEngineCard(context),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(icon, size: 15, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }

  Widget _buildLiveThemePreview(BuildContext context, ThemeSettingsState state) {
    final theme = Theme.of(context);
    final palette = state.currentPalette;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.dividerColor, width: 1.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: palette.primary,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: palette.primary.withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: const Icon(Icons.music_note, color: Colors.black, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hotel California (Hi-Res Master)',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Eagles • FLAC 24-bit / 96 kHz Studio Lossless',
                      style: TextStyle(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: palette.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: palette.primary, width: 0.8),
                ),
                child: Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: palette.primary,
                    fontWeight: FontWeight.w900,
                    fontSize: 9.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Sample Slider
          SliderTheme(
            data: theme.sliderTheme,
            child: Slider(
              value: 0.65,
              onChanged: (_) {},
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '03:45',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 10,
                  fontFeatures: AppTypography.audioFigures,
                ),
              ),
              Text(
                '06:30',
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  fontSize: 10,
                  fontFeatures: AppTypography.audioFigures,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildThemeModeSelector(
    BuildContext context,
    ThemeSettingsState state,
    ThemeController notifier,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor, width: 1.0),
      ),
      child: Row(
        children: AppThemeMode.values.map((mode) {
          final isSelected = state.themeMode == mode;
          return Expanded(
            child: InkWell(
              onTap: () => notifier.setThemeMode(mode),
              borderRadius: BorderRadius.circular(9),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.18)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  border: isSelected
                      ? Border.all(color: theme.colorScheme.primary, width: 1.2)
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      mode.icon,
                      size: 18,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      mode.label,
                      style: TextStyle(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPalettesGrid(
    BuildContext context,
    ThemeSettingsState state,
    ThemeController notifier,
  ) {
    final theme = Theme.of(context);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 2.1,
      ),
      itemCount: AppPalette.allPresets.length,
      itemBuilder: (context, index) {
        final pal = AppPalette.allPresets[index];
        final isSelected = state.currentPalette.id == pal.id;

        return InkWell(
          onTap: () => notifier.setPalette(pal),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected
                  ? pal.primary.withValues(alpha: 0.12)
                  : theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? pal.primary : theme.dividerColor,
                width: isSelected ? 1.5 : 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        pal.name,
                        style: TextStyle(
                          color: isSelected ? pal.primary : theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          fontSize: 11.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle, size: 14, color: pal.primary),
                  ],
                ),
                Row(
                  children: [
                    _buildColorDot(pal.primary),
                    const SizedBox(width: 4),
                    _buildColorDot(pal.secondary),
                    const SizedBox(width: 4),
                    _buildColorDot(pal.accent),
                    const Spacer(),
                    if (pal.isOledBlack)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.white24, width: 0.6),
                        ),
                        child: const Text(
                          'OLED',
                          style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildColorDot(Color color) {
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black26, width: 0.8),
      ),
    );
  }

  Widget _buildAccentPicker(
    BuildContext context,
    ThemeSettingsState state,
    ThemeController notifier,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 10,
            children: _accentOptions.map((accentColor) {
              final isSelected = state.customAccentColor.toARGB32() == accentColor.toARGB32();
              return InkWell(
                onTap: () => notifier.setCustomAccent(accentColor),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(
                          color: accentColor.withValues(alpha: 0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                    ],
                    border: Border.all(
                      color: isSelected ? Colors.white : Colors.transparent,
                      width: 2.2,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.black)
                      : null,
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicAlbumArtTile(
    BuildContext context,
    ThemeSettingsState state,
    ThemeController notifier,
  ) {
    final theme = Theme.of(context);

    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.dividerColor, width: 1.0),
      ),
      child: SwitchListTile(
        value: state.dynamicAlbumArtEnabled,
        onChanged: (val) => notifier.toggleDynamicAlbumArt(val),
        title: const Text(
          'Monet Dynamic Palette',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
        ),
        subtitle: const Text(
          'Ekstrak palet warna primer & aksen otomatis dari cover lagu yang aktif',
          style: TextStyle(fontSize: 10.5),
        ),
        activeThumbColor: theme.colorScheme.primary, activeTrackColor: theme.colorScheme.primary.withValues(alpha: 0.5),
      ),
    );
  }

  Widget _buildAudioEngineCard(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor, width: 1.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SoLoud C++ Audio Engine',
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF00E676), width: 0.8),
                ),
                child: const Text(
                  'ONLINE',
                  style: TextStyle(
                    color: Color(0xFF00E676),
                    fontWeight: FontWeight.w900,
                    fontSize: 9,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '• Engine Architecture: Native C++ libsoloud with miniaudio backend\n• Native Decoder: dr_flac (24-bit/192kHz), dr_mp3, dr_wav\n• Resampling Mode: Bit-Perfect Native (Automatic DAC Match)\n• Headroom Attenuator: Automatic Anti-Clipping Preamp',
            style: TextStyle(fontSize: 10.5, height: 1.45, color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
