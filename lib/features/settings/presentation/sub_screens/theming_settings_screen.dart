import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../app/theme/theme_mode_controller.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../player/presentation/controllers/player_controller.dart';

class ThemingSettingsScreen extends ConsumerWidget {
  const ThemingSettingsScreen({super.key});

  static const List<Color> _accentOptions = [
    Color(0xFF38BDF8), // Sky Studio
    Color(0xFFF59E0B), // Tube Amber
    Color(0xFF10B981), // Precision Mint
    Color(0xFFA855F7), // Studio Violet
    Color(0xFFF43F5E), // Soft Crimson
    Color(0xFFB8A9E8), // Pastel Lavender
    Color(0xFF93D5C0), // Pastel Sage
    Color(0xFF9AC8EB), // Pastel Sky
    Color(0xFFF7B297), // Pastel Peach
    Color(0xFFF2A7B5), // Pastel Blush
    Color(0xFFE8D18C), // Pastel Butter
    Color(0xFF14B8A6), // Sage Teal
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeControllerProvider);
    final themeNotifier = ref.read(themeControllerProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('THEMING & COLOR PALETTES'),
        leading: IconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            size: 20,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          // 1. LIVE PREVIEW CARD
          _buildSectionHeader(context, 'ACTIVE THEME PREVIEW', HugeIcons.strokeRoundedView),
          const SizedBox(height: 8),
          _buildLiveThemePreview(context, themeState),
          const SizedBox(height: 20),

          // 2. THEME MODE
          _buildSectionHeader(context, 'THEME MODE', HugeIcons.strokeRoundedSun01),
          const SizedBox(height: 8),
          _buildThemeModeSelector(context, themeState, themeNotifier),
          const SizedBox(height: 20),

          // 2b. SURFACE & COMPONENT FILL STYLE
          _buildSectionHeader(context, 'SURFACE & COMPONENT FILL STYLE', HugeIcons.strokeRoundedPaintBoard),
          const SizedBox(height: 8),
          _buildSurfaceFillStyleSelector(context, themeState, themeNotifier),
          const SizedBox(height: 20),

          // 3. STUDIO COLOR PALETTES
          _buildSectionHeader(context, 'STUDIO COLOR PALETTES', HugeIcons.strokeRoundedLayers01),
          const SizedBox(height: 8),
          _buildPalettesGrid(context, themeState, themeNotifier),
          const SizedBox(height: 20),

          // 4. CUSTOM ACCENT COLOR
          _buildSectionHeader(context, 'CUSTOM ACCENT COLOR', HugeIcons.strokeRoundedColorPicker),
          const SizedBox(height: 8),
          _buildAccentPicker(context, themeState, themeNotifier),
          const SizedBox(height: 20),

          // 5. DYNAMIC MONET THEME
          _buildSectionHeader(context, 'DYNAMIC ALBUM ART PALETTE', HugeIcons.strokeRoundedSparkles),
          const SizedBox(height: 8),
          _buildDynamicAlbumArtTile(context, themeState, themeNotifier, ref),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, dynamic icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        HugeIcon(icon: icon, size: 15, color: theme.colorScheme.primary),
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
                width: 38,
                height: 38,
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
                child: const Center(
                  child: HugeIcon(icon: HugeIcons.strokeRoundedMusicNote01, color: Colors.black, size: 20),
                ),
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

    return Row(
      children: AppThemeMode.values.map((modeOption) {
        final isSelected = state.themeMode == modeOption;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: InkWell(
              onTap: () => notifier.setThemeMode(modeOption),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.15)
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.dividerColor,
                    width: isSelected ? 1.8 : 1.0,
                  ),
                ),
                child: Column(
                  children: [
                    HugeIcon(
                      icon: modeOption.icon,
                      size: 20,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      modeOption.label,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSurfaceFillStyleSelector(
    BuildContext context,
    ThemeSettingsState state,
    ThemeController notifier,
  ) {
    final theme = Theme.of(context);
    final activeStyle = state.surfaceFillStyle ?? SurfaceFillStyle.translucent;

    return Row(
      children: SurfaceFillStyle.values.map((fillOption) {
        final isSelected = activeStyle == fillOption;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                notifier.setSurfaceFillStyle(fillOption);
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary.withValues(alpha: 0.15)
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.dividerColor,
                    width: isSelected ? 1.8 : 1.0,
                  ),
                ),
                child: Column(
                  children: [
                    HugeIcon(
                      icon: fillOption.icon,
                      size: 20,
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      fillOption.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      fillOption.description,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 9,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPalettesGrid(
    BuildContext context,
    ThemeSettingsState state,
    ThemeController notifier,
  ) {
    final theme = Theme.of(context);

    return Column(
      children: AppPalette.allPresets.map((palette) {
        final isSelected = state.currentPalette.id == palette.id;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: InkWell(
            onTap: () => notifier.setPalette(palette),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? theme.colorScheme.primary : theme.dividerColor,
                  width: isSelected ? 1.8 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  Row(
                    children: [
                      _buildColorDot(palette.primary),
                      const SizedBox(width: 4),
                      _buildColorDot(palette.backgroundDark),
                      const SizedBox(width: 4),
                      _buildColorDot(palette.surfaceContainerDark),
                    ],
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          palette.name,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.bold,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          palette.description,
                          style: TextStyle(
                            fontSize: 10.5,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                      size: 18,
                      color: theme.colorScheme.primary,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
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
      child: Wrap(
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
                  ? const Center(
                      child: HugeIcon(icon: HugeIcons.strokeRoundedTick02, size: 16, color: Colors.black),
                    )
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDynamicAlbumArtTile(
    BuildContext context,
    ThemeSettingsState state,
    ThemeController notifier,
    WidgetRef ref,
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
        onChanged: (val) {
          final currentTrack = ref.read(playerControllerProvider).currentTrack;
          notifier.toggleDynamicAlbumArt(val, currentTrack);
        },
        title: const Text(
          'Monet Dynamic Palette',
          style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
        ),
        subtitle: const Text(
          'Automatically extract primary and accent color palettes from active album artwork',
          style: TextStyle(fontSize: 10.5),
        ),
        activeThumbColor: theme.colorScheme.primary,
        activeTrackColor: theme.colorScheme.primary.withValues(alpha: 0.5),
      ),
    );
  }
}
