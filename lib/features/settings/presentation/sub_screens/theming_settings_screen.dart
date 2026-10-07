import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
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
          // ─── 1. ACTIVE THEME COCKPIT PREVIEW ───────────────────────────
          _buildSectionHeader(context, 'ACTIVE STUDIO THEME PREVIEW', HugeIcons.strokeRoundedView),
          const SizedBox(height: 8),
          _buildLiveThemePreview(context, themeState, isSolid),
          const SizedBox(height: 24),

          // ─── 2. DISPLAY GROUND & SURFACE STYLE ─────────────────────────
          _buildSectionHeader(context, 'DISPLAY GROUND & SURFACE STYLE', HugeIcons.strokeRoundedSun01),
          const SizedBox(height: 8),
          _buildDisplayGroundCard(context, themeState, themeNotifier, isSolid),
          const SizedBox(height: 24),

          // ─── 3. DYNAMIC & OLED ENGINES ─────────────────────────────────
          _buildSectionHeader(context, 'DYNAMIC & DISPLAY ENGINES', HugeIcons.strokeRoundedSparkles),
          const SizedBox(height: 8),
          _buildEnginesRow(context, themeState, themeNotifier, isSolid),
          const SizedBox(height: 24),

          // ─── 4. CURATED STUDIO PALETTES ────────────────────────────────
          _buildSectionHeader(context, 'STUDIO COLOR PALETTES', HugeIcons.strokeRoundedLayers01),
          const SizedBox(height: 8),
          _buildPaletteCategoryFilterBar(context, isSolid),
          const SizedBox(height: 12),
          _buildPalettesGrid(context, themeState, themeNotifier, isSolid),
          const SizedBox(height: 24),

          // ─── 5. CUSTOM STUDIO ACCENT COLOR ─────────────────────────────
          _buildSectionHeader(context, 'CUSTOM STUDIO ACCENT COLOR', HugeIcons.strokeRoundedColorPicker),
          const SizedBox(height: 8),
          _buildAccentPicker(context, themeState, themeNotifier, isSolid),
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
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedMusicNote01,
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
                          HugeIcon(
                            icon: modeOption.icon,
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

          // Surface Fill Style (2 Options)
          Text(
            'SURFACE & COMPONENT FILL STYLE',
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: SurfaceFillStyle.values.map((fillOption) {
              final activeStyle = state.surfaceFillStyle ?? SurfaceFillStyle.solid;
              final isSelected = activeStyle == fillOption;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3.0),
                  child: InkWell(
                    onTap: () {
                      AppHaptics.selectionClick();
                      notifier.setSurfaceFillStyle(fillOption);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
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
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          HugeIcon(
                            icon: fillOption.icon,
                            size: 17,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              fillOption.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedSparkles,
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
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedMoon02,
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
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedCheckmarkCircle02,
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
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedCheckmarkCircle02,
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
                boxShadow: [
                  if (isSelected)
                    BoxShadow(
                      color: accentColor.withValues(alpha: 0.5),
                      blurRadius: 10,
                      spreadRadius: 2,
                    ),
                ],
                border: isSelected
                    ? Border.all(
                        color: Colors.white,
                        width: 2.0,
                      )
                    : null,
              ),
              child: isSelected
                  ? Center(
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedTick02,
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
}
