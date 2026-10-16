import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../../app/theme/theme_mode_controller.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../player/presentation/controllers/player_controller.dart';

enum PaletteCategoryFilter {
  all('All Presets', 19),
  studio('Studio Core', 13),
  pastel('Pastel Soft', 6);

  final String label;
  final int count;
  const PaletteCategoryFilter(this.label, this.count);
}

/// Redesigned Material 3 Expressive Theming & Studio Palettes Screen.
/// Provides an intuitive cockpit interface for customizing app display mode,
/// surface fill style, dynamic album art extraction, OLED black mode, and studio palettes.
class ThemingSettingsScreen extends ConsumerStatefulWidget {
  const ThemingSettingsScreen({super.key});

  @override
  ConsumerState<ThemingSettingsScreen> createState() => _ThemingSettingsScreenState();
}

class _ThemingSettingsScreenState extends ConsumerState<ThemingSettingsScreen> {
  PaletteCategoryFilter _selectedCategory = PaletteCategoryFilter.all;

  static const List<Color> _accentOptions = [
    Color(0xFF2EE672), // Organic Emerald Mint (Simple-As-F Default)
    Color(0xFF38BDF8), // Sky Studio
    Color(0xFF64748B), // Nordic Slate
    Color(0xFFC2410C), // Terracotta Clay
    Color(0xFF15803D), // Matcha Botanical
    Color(0xFF2563EB), // Midnight Sapphire
    Color(0xFFCA8A04), // Vintage Brass
    Color(0xFF78350F), // Mocha Espresso
    Color(0xFF71717A), // Pro Carbon
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

  static const Set<String> _pastelIds = {
    'pastel_lavender',
    'pastel_sage',
    'pastel_sky',
    'pastel_peach',
    'pastel_blush',
    'pastel_butter',
  };

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeControllerProvider);
    final themeNotifier = ref.read(themeControllerProvider.notifier);
    final theme = Theme.of(context);
    final isSolid = ref.isSolidStyle;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('THEMING & COLOR PALETTES'),
        leading: M3EIconButton(
          variant: M3EIconButtonVariant.standard,
          icon: Icon(
            LucideIcons.arrowLeft,
            size: 22,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          // ─── 1. ACTIVE THEME COCKPIT PREVIEW ───────────────────────────
          _buildSectionHeader(context, 'ACTIVE STUDIO THEME PREVIEW', LucideIcons.eye),
          const SizedBox(height: 8),
          _buildLiveThemePreview(context, themeState, isSolid),
          const SizedBox(height: 24),

          // ─── 2. DISPLAY GROUND & SURFACE STYLE ─────────────────────────
          _buildSectionHeader(context, 'DISPLAY GROUND & SURFACE STYLE', LucideIcons.sun),
          const SizedBox(height: 8),
          _buildDisplayGroundCard(context, themeState, themeNotifier, isSolid),
          const SizedBox(height: 24),

          // ─── 3. DYNAMIC & OLED ENGINES ─────────────────────────────────
          _buildSectionHeader(context, 'DYNAMIC & DISPLAY ENGINES', LucideIcons.sparkles),
          const SizedBox(height: 8),
          _buildEnginesRow(context, themeState, themeNotifier, isSolid),
          const SizedBox(height: 24),

          // ─── 4. CUSTOM STUDIO WALLPAPER & BACKDROP ─────────────────────
          _buildSectionHeader(context, 'CUSTOM STUDIO WALLPAPER & BACKDROP', LucideIcons.image),
          const SizedBox(height: 8),
          _buildWallpaperSection(context, themeState, themeNotifier, isSolid),
          const SizedBox(height: 24),

          // ─── 5. CURATED STUDIO PALETTES ────────────────────────────────
          _buildSectionHeader(context, 'STUDIO COLOR PALETTES', LucideIcons.layers),
          const SizedBox(height: 8),
          _buildPaletteCategoryFilterBar(context, isSolid),
          const SizedBox(height: 12),
          _buildPalettesGrid(context, themeState, themeNotifier, isSolid),
          const SizedBox(height: 24),

          // ─── 6. CUSTOM STUDIO ACCENT COLOR ─────────────────────────────
          _buildSectionHeader(context, 'CUSTOM STUDIO ACCENT COLOR', LucideIcons.palette),
          const SizedBox(height: 8),
          _buildAccentPicker(context, themeState, themeNotifier, isSolid),
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

  Widget _buildLiveThemePreview(BuildContext context, ThemeSettingsState state, bool isSolid) {
    final theme = Theme.of(context);
    final palette = state.currentPalette;
    final primary = theme.colorScheme.primary;

    String themeTag = palette.isDynamic
        ? 'DYNAMIC ALBUM ART'
        : (palette.isOledBlack ? 'TRUE OLED BLACK' : palette.name.toUpperCase());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: StudioSurfaceTheme.cardDecoration(
        context: context,
        isSolid: isSolid,
        radius: 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Bar: Theme tag badge & Swatch preview
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
                decoration: BoxDecoration(
                  color: StudioSurfaceTheme.tintedContainer(
                    context,
                    primary,
                    isSolid: isSolid,
                    translucentAlpha: 0.16,
                    solidBlendAlpha: 0.20,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      themeTag,
                      style: TextStyle(
                        color: primary,
                        fontWeight: FontWeight.w900,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
              // Color swatch dots
              Row(
                children: [
                  _buildColorDot(palette.primary, tooltip: 'Primary Accent'),
                  const SizedBox(width: 6),
                  _buildColorDot(palette.secondary, tooltip: 'Secondary Tone'),
                  const SizedBox(width: 6),
                  _buildColorDot(
                    state.themeMode == AppThemeMode.light
                        ? palette.surfaceContainerLight
                        : palette.surfaceContainerDark,
                    tooltip: 'Container Surface',
                  ),
                  const SizedBox(width: 6),
                  _buildColorDot(
                    state.themeMode == AppThemeMode.light
                        ? palette.backgroundLight
                        : palette.backgroundDark,
                    tooltip: 'Background Ground',
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Mini Player Simulation Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Icon(
                          LucideIcons.music,
                          color: theme.colorScheme.onPrimary,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Studio Reference Playback',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface,
                              fontWeight: FontWeight.w800,
                              fontSize: 12.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'FLAC 24-bit / 96 kHz • Audiophile Studio Engine',
                            style: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontSize: 10.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'HI-RES',
                        style: TextStyle(
                          color: primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                M3ESlider(
                  value: 0.65,
                  onChanged: (_) {},
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '03:45',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 10,
                        fontFeatures: AppTypography.audioFigures,
                      ),
                    ),
                    Text(
                      '06:30',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 10,
                        fontFeatures: AppTypography.audioFigures,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayGroundCard(
    BuildContext context,
    ThemeSettingsState state,
    ThemeController notifier,
    bool isSolid,
  ) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: StudioSurfaceTheme.cardDecoration(
        context: context,
        isSolid: isSolid,
        radius: 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Theme Mode (3 Segment Options)
          Text(
            'THEME MODE',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: AppThemeMode.values.map((modeOption) {
              final isSelected = state.themeMode == modeOption;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.0),
                  child: InkWell(
                    onTap: () {
                      AppHaptics.selectionClick();
                      notifier.setThemeMode(modeOption);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 6),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? StudioSurfaceTheme.tintedContainer(
                                context,
                                theme.colorScheme.primary,
                                isSolid: isSolid,
                                translucentAlpha: 0.16,
                                solidBlendAlpha: 0.20,
                              )
                            : StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            modeOption.icon,
                            size: 18,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            modeOption.label,
                            style: TextStyle(
                              fontSize: 11,
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
          ),
          const SizedBox(height: 16),

        ],
      ),
    );
  }

  Widget _buildEnginesRow(
    BuildContext context,
    ThemeSettingsState state,
    ThemeController notifier,
    bool isSolid,
  ) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Column(
      children: [
        // Monet Dynamic Album Art Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: StudioSurfaceTheme.outline(context, isSolid: isSolid),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: state.dynamicAlbumArtEnabled
                      ? primary.withValues(alpha: 0.18)
                      : StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    LucideIcons.sparkles,
                    size: 20,
                    color: state.dynamicAlbumArtEnabled ? primary : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Dynamic Album Art Palette',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (state.dynamicAlbumArtEnabled) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'ACTIVE',
                              style: TextStyle(color: primary, fontSize: 8.5, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Dynamically extract safe, high-contrast studio palettes from currently playing cover artwork',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              M3ESwitch(
                value: state.dynamicAlbumArtEnabled,
                onChanged: (val) {
                  AppHaptics.lightImpact();
                  final currentTrack = ref.read(playerControllerProvider).currentTrack;
                  notifier.toggleDynamicAlbumArt(val, currentTrack);
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // True OLED Black Mode Card
        InkWell(
          onTap: () {
            AppHaptics.selectionClick();
            notifier.setPalette(AppPalette.trueOledBlack);
            notifier.setThemeMode(AppThemeMode.dark);
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: StudioSurfaceTheme.cardDecoration(
              context: context,
              isSolid: isSolid,
              radius: 16,
              borderColor: state.currentPalette.id == 'true_oled'
                  ? primary
                  : StudioSurfaceTheme.outline(context, isSolid: isSolid),
              borderWidth: state.currentPalette.id == 'true_oled' ? 1.6 : 1.0,
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(
                      LucideIcons.moon,
                      size: 20,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'True OLED Black Mode',
                            style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(width: 8),
                          if (state.currentPalette.id == 'true_oled')
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: primary.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'ACTIVE',
                                style: TextStyle(color: primary, fontSize: 8.5, fontWeight: FontWeight.w900),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '100% pure black ground for AMOLED screens with high-contrast studio white text',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.currentPalette.id == 'true_oled')
                  Icon(
                    LucideIcons.checkCircle2,
                    size: 20,
                    color: primary,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaletteCategoryFilterBar(BuildContext context, bool isSolid) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: PaletteCategoryFilter.values.map((filter) {
          final isSelected = _selectedCategory == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () {
                AppHaptics.selectionClick();
                setState(() => _selectedCategory = filter);
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isSelected
                      ? StudioSurfaceTheme.tintedContainer(
                          context,
                          primary,
                          isSolid: isSolid,
                          translucentAlpha: 0.18,
                          solidBlendAlpha: 0.22,
                        )
                      : StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      filter.label,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? primary : theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? primary.withValues(alpha: 0.25)
                            : theme.colorScheme.onSurface.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${filter.count}',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w900,
                          color: isSelected ? primary : theme.colorScheme.onSurfaceVariant,
                        ),
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
    bool isSolid,
  ) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final filteredList = AppPalette.allPresets.where((p) {
      if (_selectedCategory == PaletteCategoryFilter.pastel) {
        return _pastelIds.contains(p.id);
      } else if (_selectedCategory == PaletteCategoryFilter.studio) {
        return !_pastelIds.contains(p.id);
      }
      return true;
    }).toList();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        mainAxisExtent: 88,
      ),
      itemCount: filteredList.length,
      itemBuilder: (context, index) {
        final palette = filteredList[index];
        final isSelected = state.currentPalette.id == palette.id;

        return InkWell(
          onTap: () {
            AppHaptics.selectionClick();
            notifier.setPalette(palette);
          },
          borderRadius: BorderRadius.circular(14),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isSelected
                  ? StudioSurfaceTheme.tintedContainer(
                      context,
                      primary,
                      isSolid: isSolid,
                      translucentAlpha: 0.12,
                      solidBlendAlpha: 0.16,
                    )
                  : StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Swatch Dots & Selection Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                    if (isSelected)
                      Icon(
                        LucideIcons.checkCircle2,
                        size: 16,
                        color: primary,
                      ),
                  ],
                ),
                // Title and description
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      palette.name,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? primary : theme.colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 1),
                    Text(
                      palette.description,
                      style: TextStyle(
                        fontSize: 9.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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

  Widget _buildColorDot(Color color, {String? tooltip}) {
    final dot = Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );

    if (tooltip != null) {
      return Tooltip(message: tooltip, child: dot);
    }
    return dot;
  }

  Widget _buildAccentPicker(
    BuildContext context,
    ThemeSettingsState state,
    ThemeController notifier,
    bool isSolid,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: StudioSurfaceTheme.cardDecoration(
        context: context,
        isSolid: isSolid,
        radius: 18,
      ),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        alignment: WrapAlignment.start,
        children: _accentOptions.map((accentColor) {
          final isSelected = state.customAccentColor.toARGB32() == accentColor.toARGB32();
          return InkWell(
            onTap: () {
              AppHaptics.selectionClick();
              notifier.setCustomAccent(accentColor);
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: accentColor,
                shape: BoxShape.circle,
                border: isSelected
                    ? Border.all(
                        color: Colors.white,
                        width: 2.0,
                      )
                    : null,
              ),
              child: isSelected
                  ? Center(
                      child: Icon(
                        LucideIcons.check,
                        size: 16,
                        color: accentColor.computeLuminance() > 0.5 ? Colors.black : Colors.white,
                      ),
                    )
                  : null,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWallpaperSection(
    BuildContext context,
    ThemeSettingsState state,
    ThemeController notifier,
    bool isSolid,
  ) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final wallpaper = state.wallpaperSettings;
    final hasImage = wallpaper.imagePath != null &&
        wallpaper.imagePath!.isNotEmpty &&
        (wallpaper.isAsset || File(wallpaper.imagePath!).existsSync());

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: StudioSurfaceTheme.cardDecoration(
        context: context,
        isSolid: isSolid,
        radius: 18,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Status Tag and Enable Switch
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: wallpaper.enabled
                      ? primary.withValues(alpha: 0.18)
                      : StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(
                    LucideIcons.image,
                    size: 20,
                    color: wallpaper.enabled ? primary : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            'Custom Background Wallpaper',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onSurface,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (wallpaper.enabled && hasImage) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'ACTIVE',
                              style: TextStyle(
                                color: primary,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Personalize background ground with custom wallpaper & dynamic 3-color palette',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              M3ESwitch(
                key: const ValueKey('wallpaper_toggle_switch'),
                value: wallpaper.enabled,
                onChanged: (hasImage || wallpaper.enabled)
                    ? (val) {
                        AppHaptics.lightImpact();
                        notifier.toggleWallpaperEnabled(val);
                      }
                    : null,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Studio Presets Carousel (5 Preloaded)
          _buildPresetWallpapersRow(context, state, isSolid),
          const SizedBox(height: 16),

          // Live Wallpaper Preview & Extracted 3 Swatches
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                // Thumbnail
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: primary.withValues(alpha: 0.25),
                      width: 1.0,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: hasImage
                      ? (wallpaper.isAsset
                          ? Image.asset(
                              wallpaper.imagePath!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Center(
                                child: Icon(
                                  LucideIcons.image,
                                  size: 24,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            )
                          : Image.file(
                              File(wallpaper.imagePath!),
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Center(
                                child: Icon(
                                  LucideIcons.image,
                                  size: 24,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ))
                      : Center(
                          child: Icon(
                            LucideIcons.image,
                            size: 24,
                            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                          ),
                        ),
                ),
                const SizedBox(width: 14),

                // Extracted Swatches & Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasImage
                            ? (wallpaper.isAsset
                                ? 'Studio Preset Palette'
                                : 'Dynamic 3-Color Studio Extraction')
                            : 'No Wallpaper Selected',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (hasImage && wallpaper.extractedPrimary != null) ...[
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _buildColorDotBadge(
                              context,
                              wallpaper.extractedPrimary!,
                              'Primary',
                            ),
                            if (wallpaper.extractedSecondary != null)
                              _buildColorDotBadge(
                                context,
                                wallpaper.extractedSecondary!,
                                'Secondary',
                              ),
                            if (wallpaper.extractedTertiary != null)
                              _buildColorDotBadge(
                                context,
                                wallpaper.extractedTertiary!,
                                'Accent',
                              ),
                          ],
                        ),
                      ] else ...[
                        Text(
                          'Choose a studio preset above or pick an image from device storage',
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons: Pick Image & Remove
          Row(
            children: [
              Expanded(
                child: M3EButton.elevated(
                  label: Text(hasImage && !wallpaper.isAsset ? 'CHANGE CUSTOM IMAGE' : 'CUSTOM IMAGE FROM DEVICE'),
                  icon: Icon(
                    LucideIcons.folder,
                    size: 18,
                    color: primary,
                  ),
                  onPressed: () async {
                    AppHaptics.selectionClick();
                    final files = await FilePicker.pickFiles(
                      type: FileType.image,
                    );
                    if (files.isNotEmpty) {
                      final path = files.first.path;
                      if (path != null) {
                        final selectedFile = File(path);
                        await notifier.setCustomWallpaperFromFile(selectedFile);
                      }
                    }
                  },
                ),
              ),
              if (hasImage) ...[
                const SizedBox(width: 10),
                M3EIconButton(
                  variant: M3EIconButtonVariant.tonal,
                  icon: Icon(
                    LucideIcons.trash2,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
                  onPressed: () {
                    AppHaptics.mediumImpact();
                    notifier.removeWallpaper();
                  },
                ),
              ],
            ],
          ),

          if (hasImage) ...[
            const SizedBox(height: 18),
            // Auto-Sync Palette Switch
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.sparkles,
                    size: 18,
                    color: wallpaper.syncPalette ? primary : theme.colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Auto-Sync Theme Palette',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Keep theme palette in sync with wallpaper colors',
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  M3ESwitch(
                    value: wallpaper.syncPalette,
                    onChanged: (val) {
                      AppHaptics.lightImpact();
                      notifier.setWallpaperSyncPalette(val);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Dimming Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'WALLPAPER DARKNESS / DIM',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${(wallpaper.dimOpacity * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: primary,
                    fontFeatures: AppTypography.audioFigures,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            M3ESlider(
              value: wallpaper.dimOpacity,
              min: 0.0,
              max: 0.85,
              onChanged: (val) {
                notifier.setWallpaperDim(val);
              },
            ),
            const SizedBox(height: 12),

            // Backdrop Blur Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'BACKDROP BLUR RADIUS',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  '${wallpaper.blurRadius.toInt()} px',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: primary,
                    fontFeatures: AppTypography.audioFigures,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            M3ESlider(
              value: wallpaper.blurRadius,
              min: 0.0,
              max: 40.0,
              onChanged: (val) {
                notifier.setWallpaperBlur(val);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPresetWallpapersRow(
    BuildContext context,
    ThemeSettingsState state,
    bool isSolid,
  ) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final currentPath = state.wallpaperSettings.imagePath;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              LucideIcons.palette,
              size: 14,
              color: primary,
            ),
            const SizedBox(width: 6),
            Text(
              'STUDIO PRESETS (${StudioWallpaperPreset.presets.length} PRELOADED)',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 135,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: StudioWallpaperPreset.presets.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final preset = StudioWallpaperPreset.presets[index];
              final isSelected = currentPath == preset.assetPath;

              return InkWell(
                onTap: () {
                  AppHaptics.selectionClick();
                  ref.read(themeControllerProvider.notifier).setWallpaperPreset(preset);
                },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 110,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? primary
                          : StudioSurfaceTheme.outline(context, isSolid: isSolid),
                      width: isSelected ? 2.0 : 1.0,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Preset Wallpaper Image
                      Image.asset(
                        preset.assetPath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                          child: const Center(
                            child: Icon(
                              LucideIcons.image,
                              size: 24,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ),

                      // Gradient Bottom Overlay for Typography Contrast
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        height: 58,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.88),
                                Colors.black.withValues(alpha: 0.0),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // Bottom Info: Title & 3 Swatch Dots
                      Positioned(
                        left: 8,
                        right: 8,
                        bottom: 8,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              preset.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                height: 1.15,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _buildMiniColorDot(preset.primaryColor),
                                const SizedBox(width: 4),
                                _buildMiniColorDot(preset.secondaryColor),
                                const SizedBox(width: 4),
                                _buildMiniColorDot(preset.tertiaryColor),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Selected Badge
                      if (isSelected)
                        Positioned(
                          top: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.all(3),
                            decoration: BoxDecoration(
                              color: primary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              LucideIcons.checkCircle2,
                              size: 13,
                              color: Colors.black,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMiniColorDot(Color color) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 0.5),
      ),
    );
  }

  Widget _buildColorDotBadge(BuildContext context, Color color, String label) {
    final hex = '#${color.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.35), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            hex,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: color,
              fontFeatures: AppTypography.audioFigures,
            ),
          ),
        ],
      ),
    );
  }
}
