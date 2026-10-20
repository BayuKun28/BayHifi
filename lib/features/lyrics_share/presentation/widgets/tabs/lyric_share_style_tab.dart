import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:baydev_hifi/app/theme/app_haptics.dart';
import 'package:baydev_hifi/features/lyrics_share/domain/models/lyric_card_theme.dart';
import 'package:baydev_hifi/features/lyrics_share/presentation/controllers/lyric_share_controller.dart';
import '../lyric_share_sheet_components.dart';

/// Tab 3: Typography, Text Highlights & Background Palette Styling
class LyricShareStyleTab extends StatelessWidget {
  final LyricShareState state;
  final LyricShareController controller;

  const LyricShareStyleTab({
    super.key,
    required this.state,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Typography & Font Weight Bento
          LyricShareBentoSection(
            theme: theme,
            title: 'TYPOGRAPHY & FONT WEIGHT',
            icon: LucideIcons.type,
            child: _buildTypographySection(theme, state, controller),
          ),

          const SizedBox(height: 12),

          // 2. Text Styles & Highlights Bento
          LyricShareBentoSection(
            theme: theme,
            title: 'TEXT STYLES & HIGHLIGHTS',
            icon: LucideIcons.palette,
            child: _buildHighlightAndStyleSection(theme, state, controller),
          ),

          const SizedBox(height: 12),

          // 3. Background & Palette Bento
          LyricShareBentoSection(
            theme: theme,
            title: 'BACKGROUND & PALETTE',
            icon: LucideIcons.pipette,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBackgroundModeSelector(theme, state, controller),
                const SizedBox(height: 10),
                _buildBackgroundModeOptions(theme, state, controller),
              ],
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTypographySection(
    ThemeData theme,
    LyricShareState state,
    LyricShareController controller,
  ) {
    final config = state.config;

    final weights = const [
      (FontWeight.w400, 'Regular'),
      (FontWeight.w600, 'SemiBold'),
      (FontWeight.w700, 'Bold'),
      (FontWeight.w900, 'Black'),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Font Family Selector Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (final font in LyricCardFontFamily.values) ...[
                _buildFontFamilyChip(font, config.fontFamily, theme, () {
                  AppHaptics.selectionClick();
                  controller.setFontFamily(font);
                }),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Font Weight Selector Chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (final w in weights) ...[
                GestureDetector(
                  onTap: () {
                    AppHaptics.selectionClick();
                    controller.setFontWeight(w.$1);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    margin: const EdgeInsets.only(right: 6),
                    decoration: BoxDecoration(
                      color: config.fontWeight == w.$1
                          ? theme.colorScheme.primary.withValues(alpha: 0.15)
                          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      w.$2,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: w.$1,
                        color: config.fontWeight == w.$1
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 10),
        // Alignment, Italic, and Font Size Stepper Bar
        Row(
          children: [
            // Text Alignment Segment
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  _buildIconToggle(
                    icon: LucideIcons.alignLeft,
                    isSelected: config.textAlign == TextAlign.left,
                    theme: theme,
                    onTap: () {
                      AppHaptics.selectionClick();
                      controller.setTextAlign(TextAlign.left);
                    },
                  ),
                  _buildIconToggle(
                    icon: LucideIcons.alignCenter,
                    isSelected: config.textAlign == TextAlign.center,
                    theme: theme,
                    onTap: () {
                      AppHaptics.selectionClick();
                      controller.setTextAlign(TextAlign.center);
                    },
                  ),
                  _buildIconToggle(
                    icon: LucideIcons.alignRight,
                    isSelected: config.textAlign == TextAlign.right,
                    theme: theme,
                    onTap: () {
                      AppHaptics.selectionClick();
                      controller.setTextAlign(TextAlign.right);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Italic Toggle
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: _buildIconToggle(
                icon: LucideIcons.italic,
                isSelected: config.isItalic,
                theme: theme,
                onTap: () {
                  AppHaptics.selectionClick();
                  controller.toggleItalic(!config.isItalic);
                },
              ),
            ),
            const Spacer(),
            // Font Size Stepper
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      AppHaptics.selectionClick();
                      controller.setFontSizeMultiplier(config.fontSizeMultiplier - 0.1);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        LucideIcons.minus,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Text(
                      '${(config.fontSizeMultiplier * 100).round()}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      AppHaptics.selectionClick();
                      controller.setFontSizeMultiplier(config.fontSizeMultiplier + 0.1);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        LucideIcons.plus,
                        size: 14,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHighlightAndStyleSection(
    ThemeData theme,
    LyricShareState state,
    LyricShareController controller,
  ) {
    final config = state.config;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Style selector chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (final style in LyricCardHighlightStyle.values) ...[
                GestureDetector(
                  onTap: () {
                    AppHaptics.selectionClick();
                    controller.setHighlightStyle(style);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: config.highlightStyle == style
                          ? theme.colorScheme.primary.withValues(alpha: 0.15)
                          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getHighlightIcon(style),
                          size: 14,
                          color: config.highlightStyle == style
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          style.label,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: config.highlightStyle == style ? FontWeight.w700 : FontWeight.w500,
                            color: config.highlightStyle == style
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 10),

        // Line Spacing & Letter Spacing Sub-Row
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Line Spacing',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      for (final spacing in [
                        (0.8, 'Compact'),
                        (1.0, 'Normal'),
                        (1.3, 'Relaxed'),
                      ]) ...[
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              AppHaptics.selectionClick();
                              controller.setLineSpacingMultiplier(spacing.$1);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                color: config.lineSpacingMultiplier == spacing.$1
                                    ? theme.colorScheme.primary.withValues(alpha: 0.15)
                                    : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  spacing.$2,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: config.lineSpacingMultiplier == spacing.$1
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: config.lineSpacingMultiplier == spacing.$1
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Letter Spacing',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      for (final lSpace in [
                        (-0.5, 'Tight'),
                        (-0.2, 'Normal'),
                        (0.8, 'Wide'),
                      ]) ...[
                        Expanded(
                          child: GestureDetector(
                            onTap: () {
                              AppHaptics.selectionClick();
                              controller.setLetterSpacing(lSpace.$1);
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 5),
                              margin: const EdgeInsets.only(right: 4),
                              decoration: BoxDecoration(
                                color: (config.letterSpacing - lSpace.$1).abs() < 0.05
                                    ? theme.colorScheme.primary.withValues(alpha: 0.15)
                                    : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Center(
                                child: Text(
                                  lSpace.$2,
                                  style: TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: (config.letterSpacing - lSpace.$1).abs() < 0.05
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: (config.letterSpacing - lSpace.$1).abs() < 0.05
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  IconData _getHighlightIcon(LyricCardHighlightStyle? style) {
    switch (style ?? LyricCardHighlightStyle.none) {
      case LyricCardHighlightStyle.none:
        return LucideIcons.type;
      case LyricCardHighlightStyle.stroke:
        return LucideIcons.palette;
      case LyricCardHighlightStyle.highlighterPill:
        return LucideIcons.bookmark;
      case LyricCardHighlightStyle.dropShadow:
        return LucideIcons.sparkles;
    }
  }

  Widget _buildFontFamilyChip(
    LyricCardFontFamily font,
    LyricCardFontFamily currentFont,
    ThemeData theme,
    VoidCallback onTap,
  ) {
    final isSelected = font == currentFont;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.15)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          font.label,
          style: TextStyle(
            fontFamily: font.fontFamily,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
          ),
        ),
      ),
    );
  }

  Widget _buildIconToggle({
    required IconData icon,
    required bool isSelected,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(
          icon,
          size: 16,
          color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildBackgroundModeSelector(
    ThemeData theme,
    LyricShareState state,
    LyricShareController controller,
  ) {
    final currentMode = state.config.backgroundMode;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          for (final mode in LyricCardBackgroundMode.values) ...[
            Expanded(
              child: GestureDetector(
                onTap: () {
                  AppHaptics.selectionClick();
                  controller.setBackgroundMode(mode);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  decoration: BoxDecoration(
                    color: currentMode == mode
                        ? theme.colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Center(
                    child: Text(
                      mode.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: currentMode == mode ? FontWeight.w700 : FontWeight.w500,
                        color: currentMode == mode
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBackgroundModeOptions(
    ThemeData theme,
    LyricShareState state,
    LyricShareController controller,
  ) {
    final config = state.config;

    switch (config.backgroundMode) {
      case LyricCardBackgroundMode.blurredArtwork:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Blur Intensity row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  Text(
                    'Blur:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  for (final b in [
                    (15.0, 'Soft (15)'),
                    (30.0, 'Normal (30)'),
                    (50.0, 'Deep (50)'),
                  ]) ...[
                    GestureDetector(
                      onTap: () {
                        AppHaptics.selectionClick();
                        controller.setBackgroundBlurSigma(b.$1);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: (config.backgroundBlurSigma - b.$1).abs() < 1.0
                              ? theme.colorScheme.primary.withValues(alpha: 0.15)
                              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          b.$2,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: (config.backgroundBlurSigma - b.$1).abs() < 1.0
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: (config.backgroundBlurSigma - b.$1).abs() < 1.0
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Dark Shield / Dimming Opacity row
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  Text(
                    'Shield:',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  for (final d in [
                    (0.40, 'Light (40%)'),
                    (0.65, 'Standard (65%)'),
                    (0.85, 'Heavy (85%)'),
                  ]) ...[
                    GestureDetector(
                      onTap: () {
                        AppHaptics.selectionClick();
                        controller.setBackgroundDimOpacity(d.$1);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        margin: const EdgeInsets.only(right: 6),
                        decoration: BoxDecoration(
                          color: (config.backgroundDimOpacity - d.$1).abs() < 0.05
                              ? theme.colorScheme.primary.withValues(alpha: 0.15)
                              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          d.$2,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: (config.backgroundDimOpacity - d.$1).abs() < 0.05
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: (config.backgroundDimOpacity - d.$1).abs() < 0.05
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );

      case LyricCardBackgroundMode.albumPalette:
        if (state.isExtractingPalette) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }

        final swatches = state.extractedPaletteSwatches;
        if (swatches.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text(
              'No dynamic colors extracted. Using default studio theme.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final color in swatches) ...[
                _buildPaletteSwatchChip(
                  color: color,
                  isSelected: state.config.selectedPaletteColor == color ||
                      (state.config.selectedPaletteColor == null &&
                          (state.dominantAlbumColor == color || swatches.first == color)),
                  theme: theme,
                  onTap: () {
                    AppHaptics.selectionClick();
                    controller.selectPaletteColor(color);
                  },
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        );

      case LyricCardBackgroundMode.studioPreset:
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final preset in LyricCardThemePreset.values) ...[
                LyricShareThemePresetChip(
                  preset: preset,
                  state: state,
                  theme: theme,
                  onTap: () {
                    AppHaptics.selectionClick();
                    controller.setPreset(preset);
                  },
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        );

      case LyricCardBackgroundMode.customColor:
        final customColors = const [
          Color(0xFF0A0D12), // OLED Dark
          Color(0xFF0F172A), // Slate
          Color(0xFF0A192F), // Midnight Navy
          Color(0xFF064E3B), // Precision Mint
          Color(0xFF06372A), // Forest Pine
          Color(0xFF451A03), // Warm Tube Amber
          Color(0xFF4C0519), // Acoustic Rose
          Color(0xFF3B0764), // Dark Violet
          Color(0xFF1E1B4B), // Royal Indigo
          Color(0xFF083344), // Oceanic Cyan
          Color(0xFF450A0A), // Crimson Ember
          Color(0xFF292524), // Warm Sand
        ];

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final color in customColors) ...[
                _buildCustomColorChip(
                  color: color,
                  isSelected: state.config.customBackgroundColor == color,
                  theme: theme,
                  onTap: () {
                    AppHaptics.selectionClick();
                    controller.setCustomColor(color);
                  },
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        );
    }
  }

  Widget _buildPaletteSwatchChip({
    required Color color,
    required bool isSelected,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.white.withValues(alpha: 0.3),
            width: isSelected ? 2.5 : 1.0,
          ),
        ),
        child: isSelected
            ? Center(
                child: Icon(
                  LucideIcons.check,
                  size: 16,
                  color: Colors.white,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildCustomColorChip({
    required Color color,
    required bool isSelected,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.white.withValues(alpha: 0.25),
            width: isSelected ? 2.5 : 1.0,
          ),
        ),
        child: isSelected
            ? Center(
                child: Icon(
                  LucideIcons.check,
                  size: 16,
                  color: Colors.white,
                ),
              )
            : null,
      ),
    );
  }
}
