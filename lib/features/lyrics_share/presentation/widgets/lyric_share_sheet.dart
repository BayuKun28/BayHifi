import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../player/domain/lyrics_line.dart';
import '../../../player/domain/track.dart';
import '../../domain/models/lyric_card_theme.dart';
import '../controllers/lyric_share_controller.dart';
import 'lyric_card_widget.dart';

/// Modal bottom sheet for customizing, previewing, and sharing lyric cards
class LyricShareSheet extends ConsumerStatefulWidget {
  final Track track;
  final List<LyricsLine> allLines;
  final LyricsLine? initialSelectedLine;
  final Color? dominantAlbumColor;
  final Color? vibrantAlbumColor;
  final Color? lightVibrantAlbumColor;
  final String? audioSpec;

  const LyricShareSheet({
    super.key,
    required this.track,
    required this.allLines,
    this.initialSelectedLine,
    this.dominantAlbumColor,
    this.vibrantAlbumColor,
    this.lightVibrantAlbumColor,
    this.audioSpec,
  });

  /// Helper to display the sheet in modern Material 3 bottom modal
  static Future<void> show(
    BuildContext context, {
    required Track track,
    required List<LyricsLine> allLines,
    LyricsLine? initialSelectedLine,
    Color? dominantAlbumColor,
    Color? vibrantAlbumColor,
    Color? lightVibrantAlbumColor,
    String? audioSpec,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LyricShareSheet(
        track: track,
        allLines: allLines,
        initialSelectedLine: initialSelectedLine,
        dominantAlbumColor: dominantAlbumColor,
        vibrantAlbumColor: vibrantAlbumColor,
        lightVibrantAlbumColor: lightVibrantAlbumColor,
        audioSpec: audioSpec,
      ),
    );
  }

  @override
  ConsumerState<LyricShareSheet> createState() => _LyricShareSheetState();
}

class _LyricShareSheetState extends ConsumerState<LyricShareSheet> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  late final StateNotifierProvider<LyricShareController, LyricShareState> _provider;
  int _currentTabIndex = 0; // 0 = Preview & Theme, 1 = Select Lines

  @override
  void initState() {
    super.initState();
    _provider = StateNotifierProvider<LyricShareController, LyricShareState>(
      (ref) => LyricShareController(
        track: widget.track,
        allLines: widget.allLines,
        initialSelectedLine: widget.initialSelectedLine,
        dominantColor: widget.dominantAlbumColor,
        vibrantColor: widget.vibrantAlbumColor,
        lightVibrantColor: widget.lightVibrantAlbumColor,
        audioSpec: widget.audioSpec,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(_provider);
    final controller = ref.read(_provider.notifier);

    final maxSheetHeight = MediaQuery.of(context).size.height * 0.90;

    return Container(
      height: maxSheetHeight,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Top Drag Handle & Title Bar
            _buildHeader(context, theme, state),

            // Tab Selector (Preview & Customize vs Select Lines)
            _buildTabSelector(theme, state),

            const Divider(height: 1, thickness: 0.8),

            // Tab Content
            Expanded(
              child: _currentTabIndex == 0
                  ? _buildPreviewTab(context, theme, state, controller)
                  : _buildSelectLinesTab(theme, state, controller),
            ),

            const Divider(height: 1, thickness: 0.8),

            // Bottom Actions Bar
            _buildBottomActionBar(context, theme, state, controller),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, ThemeData theme, LyricShareState state) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 8),
      child: Column(
        children: [
          // Drag Handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedShare08,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Share Lyrics',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    Text(
                      widget.track.title.isNotEmpty ? widget.track.title : 'Track',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedCancel01,
                  size: 20,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector(ThemeData theme, LyricShareState state) {
    final selectedCount = state.config.selectedLines.length;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: _buildTabPill(
                title: 'Card Preview',
                icon: HugeIcons.strokeRoundedImage01,
                isSelected: _currentTabIndex == 0,
                theme: theme,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _currentTabIndex = 0);
                },
              ),
            ),
            Expanded(
              child: _buildTabPill(
                title: 'Select Lines ($selectedCount/5)',
                icon: HugeIcons.strokeRoundedTextFont,
                isSelected: _currentTabIndex == 1,
                theme: theme,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _currentTabIndex = 1);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabPill({
    required String title,
    required dynamic icon,
    required bool isSelected,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: icon,
              size: 16,
              color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewTab(
    BuildContext context,
    ThemeData theme,
    LyricShareState state,
    LyricShareController controller,
  ) {
    final ratio = state.config.ratio;

    // Viewport bounding box constraints tailored to each aspect ratio
    final double maxStageWidth = ratio == LyricCardRatio.landscape_16_9
        ? 340.0
        : (ratio == LyricCardRatio.story_9_16 ? 210.0 : 250.0);
    final double maxStageHeight = ratio == LyricCardRatio.landscape_16_9
        ? 192.0
        : (ratio == LyricCardRatio.story_9_16 ? 330.0 : 260.0);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── 1. LIVE CARD PREVIEW STAGE ──────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.outline.withValues(alpha: 0.12),
                width: 1.0,
              ),
            ),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOutCubic,
                constraints: BoxConstraints(
                  maxWidth: maxStageWidth,
                  maxHeight: maxStageHeight,
                ),
                child: LyricCardWidget(
                  config: state.config,
                  colors: state.colors,
                  repaintBoundaryKey: _repaintBoundaryKey,
                ),
              ),
            ),
          ).animate().fade(duration: 250.ms).scale(begin: const Offset(0.96, 0.96)),

          const SizedBox(height: 14),

          // ─── 2. CARD RATIO BENTO ─────────────────────────────────────────
          _buildBentoSection(
            theme: theme,
            title: 'CARD RATIO',
            icon: HugeIcons.strokeRoundedAspectRatio,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: [
                  for (final r in LyricCardRatio.values) ...[
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: SizedBox(
                        width: 86,
                        child: _buildRatioOption(r, state.config.ratio, theme, () {
                          HapticFeedback.selectionClick();
                          controller.setRatio(r);
                        }),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // ─── 3. TYPOGRAPHY & FONT WEIGHT BENTO ───────────────────────────
          _buildBentoSection(
            theme: theme,
            title: 'TYPOGRAPHY & FONT WEIGHT',
            icon: HugeIcons.strokeRoundedTextFont,
            child: _buildTypographySection(theme, state, controller),
          ),

          const SizedBox(height: 12),

          // ─── 4. TEXT STYLES & HIGHLIGHTS BENTO (IG & SPOTIFY STYLE) ─────
          _buildBentoSection(
            theme: theme,
            title: 'TEXT STYLES & HIGHLIGHTS',
            icon: HugeIcons.strokeRoundedPaintBoard,
            child: _buildHighlightAndStyleSection(theme, state, controller),
          ),

          const SizedBox(height: 12),

          // ─── 5. BACKGROUND & PALETTE BENTO ───────────────────────────────
          _buildBentoSection(
            theme: theme,
            title: 'BACKGROUND & PALETTE',
            icon: HugeIcons.strokeRoundedColorPicker,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildBackgroundModeSelector(theme, state, controller),
                const SizedBox(height: 10),
                _buildBackgroundModeOptions(theme, state, controller),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // ─── 6. ELEMENTS & BADGES BENTO ──────────────────────────────────
          _buildBentoSection(
            theme: theme,
            title: 'ELEMENTS & BADGES',
            icon: HugeIcons.strokeRoundedSlidersHorizontal,
            child: Column(
              children: [
                _buildAudioSpecsToggleRow(
                  title: 'Audio Specs Badge',
                  subtitle: 'Hi-Res format telemetry tag',
                  value: state.config.showAudioSpecsBadge,
                  customText: state.config.customAudioSpec,
                  theme: theme,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    controller.toggleAudioSpecs(val);
                  },
                  onEditCustomText: () => _showCustomAudioSpecDialog(context, theme, state, controller),
                ),
                const Divider(height: 12, thickness: 0.6),
                _buildToggleRow(
                  title: 'Studio Branding',
                  subtitle: 'Official Baydev HiFi logo badge',
                  value: state.config.showBranding,
                  theme: theme,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    controller.toggleBranding(val);
                  },
                ),
                if (state.allLines.any((l) => l.hasRomanization)) ...[
                  const Divider(height: 12, thickness: 0.6),
                  _buildToggleRow(
                    title: 'Phonetic Subtitle',
                    subtitle: 'Transliterated Latin lyrics',
                    value: state.config.showRomanized,
                    theme: theme,
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      controller.toggleRomanized(val);
                    },
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildBentoSection({
    required ThemeData theme,
    required String title,
    required dynamic icon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.12),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: icon,
                size: 14,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
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
                  HapticFeedback.selectionClick();
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
                    HapticFeedback.selectionClick();
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
                      border: Border.all(
                        color: config.fontWeight == w.$1
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withValues(alpha: 0.15),
                        width: config.fontWeight == w.$1 ? 1.4 : 0.8,
                      ),
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
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                children: [
                  _buildIconToggle(
                    icon: HugeIcons.strokeRoundedTextAlignLeft,
                    isSelected: config.textAlign == TextAlign.left,
                    theme: theme,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      controller.setTextAlign(TextAlign.left);
                    },
                  ),
                  _buildIconToggle(
                    icon: HugeIcons.strokeRoundedTextAlignCenter,
                    isSelected: config.textAlign == TextAlign.center,
                    theme: theme,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      controller.setTextAlign(TextAlign.center);
                    },
                  ),
                  _buildIconToggle(
                    icon: HugeIcons.strokeRoundedTextAlignRight,
                    isSelected: config.textAlign == TextAlign.right,
                    theme: theme,
                    onTap: () {
                      HapticFeedback.selectionClick();
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
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              child: _buildIconToggle(
                icon: HugeIcons.strokeRoundedTextItalic,
                isSelected: config.isItalic,
                theme: theme,
                onTap: () {
                  HapticFeedback.selectionClick();
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
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.1),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      controller.setFontSizeMultiplier(config.fontSizeMultiplier - 0.1);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedMinusSign,
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
                      HapticFeedback.selectionClick();
                      controller.setFontSizeMultiplier(config.fontSizeMultiplier + 0.1);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedPlusSign,
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
        // Style selector chips (Clean, Stroke, Instagram Pill, Spotify Glow)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Row(
            children: [
              for (final style in LyricCardHighlightStyle.values) ...[
                GestureDetector(
                  onTap: () {
                    HapticFeedback.selectionClick();
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
                      border: Border.all(
                        color: config.highlightStyle == style
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withValues(alpha: 0.15),
                        width: config.highlightStyle == style ? 1.5 : 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HugeIcon(
                          icon: _getHighlightIcon(style),
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

        // If Text Stroke is active: Stroke Thickness selector
        if (config.highlightStyle == LyricCardHighlightStyle.stroke) ...[
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              children: [
                Text(
                  'Border Width:',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 10),
                for (final stroke in [
                  (1.5, 'Subtle (1.5px)'),
                  (2.5, 'Standard (2.5px)'),
                  (4.0, 'Thick (4.0px)'),
                ]) ...[
                  GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      controller.setStrokeWidth(stroke.$1);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      margin: const EdgeInsets.only(right: 6),
                      decoration: BoxDecoration(
                        color: config.strokeWidth == stroke.$1
                            ? theme.colorScheme.primary.withValues(alpha: 0.15)
                            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: config.strokeWidth == stroke.$1
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outline.withValues(alpha: 0.15),
                          width: config.strokeWidth == stroke.$1 ? 1.2 : 0.8,
                        ),
                      ),
                      child: Text(
                        stroke.$2,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: config.strokeWidth == stroke.$1 ? FontWeight.w700 : FontWeight.w500,
                          color: config.strokeWidth == stroke.$1
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
                              HapticFeedback.selectionClick();
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
                                border: Border.all(
                                  color: config.lineSpacingMultiplier == spacing.$1
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.outline.withValues(alpha: 0.12),
                                  width: config.lineSpacingMultiplier == spacing.$1 ? 1.2 : 0.8,
                                ),
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
                              HapticFeedback.selectionClick();
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
                                border: Border.all(
                                  color: (config.letterSpacing - lSpace.$1).abs() < 0.05
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.outline.withValues(alpha: 0.12),
                                  width: (config.letterSpacing - lSpace.$1).abs() < 0.05 ? 1.2 : 0.8,
                                ),
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

  dynamic _getHighlightIcon(LyricCardHighlightStyle style) {
    switch (style) {
      case LyricCardHighlightStyle.none:
        return HugeIcons.strokeRoundedTextFont;
      case LyricCardHighlightStyle.stroke:
        return HugeIcons.strokeRoundedPaintBoard;
      case LyricCardHighlightStyle.highlighterPill:
        return HugeIcons.strokeRoundedBookmark02;
      case LyricCardHighlightStyle.dropShadow:
        return HugeIcons.strokeRoundedSparkles;
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
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.15),
            width: isSelected ? 1.5 : 1.0,
          ),
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
    required dynamic icon,
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
        child: HugeIcon(
          icon: icon,
          size: 16,
          color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildAudioSpecsToggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required String? customText,
    required ThemeData theme,
    required ValueChanged<bool> onChanged,
    required VoidCallback onEditCustomText,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (value)
                      GestureDetector(
                        onTap: onEditCustomText,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              HugeIcon(
                                icon: HugeIcons.strokeRoundedEdit02,
                                size: 12,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Custom Text',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
                Text(
                  customText != null ? 'Custom: "$customText"' : subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: customText != null ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  void _showCustomAudioSpecDialog(
    BuildContext context,
    ThemeData theme,
    LyricShareState state,
    LyricShareController controller,
  ) {
    final textController = TextEditingController(
      text: state.config.customAudioSpec ?? '',
    );

    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: theme.colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedMusicNote01,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 10),
            const Text(
              'Custom Audio Specs',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Customize the audio format telemetry badge on the card header.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: textController,
              autofocus: true,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                hintText: 'e.g. 24-BIT 96kHz • STUDIO MASTER',
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: theme.colorScheme.outline.withValues(alpha: 0.2),
                  ),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              controller.setCustomAudioSpec(null);
              Navigator.of(dialogCtx).pop();
            },
            child: const Text('Reset Auto'),
          ),
          FilledButton(
            onPressed: () {
              controller.setCustomAudioSpec(textController.text);
              Navigator.of(dialogCtx).pop();
            },
            child: const Text('Apply'),
          ),
        ],
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
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          for (final mode in LyricCardBackgroundMode.values) ...[
            Expanded(
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
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
                        HapticFeedback.selectionClick();
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
                          border: Border.all(
                            color: (config.backgroundBlurSigma - b.$1).abs() < 1.0
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline.withValues(alpha: 0.15),
                            width: (config.backgroundBlurSigma - b.$1).abs() < 1.0 ? 1.2 : 0.8,
                          ),
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
                        HapticFeedback.selectionClick();
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
                          border: Border.all(
                            color: (config.backgroundDimOpacity - d.$1).abs() < 0.05
                                ? theme.colorScheme.primary
                                : theme.colorScheme.outline.withValues(alpha: 0.15),
                            width: (config.backgroundDimOpacity - d.$1).abs() < 0.05 ? 1.2 : 0.8,
                          ),
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
                    HapticFeedback.selectionClick();
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
                _buildThemePresetChip(preset, state, theme, () {
                  HapticFeedback.selectionClick();
                  controller.setPreset(preset);
                }),
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
                    HapticFeedback.selectionClick();
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
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.4),
                    blurRadius: 6,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: isSelected
            ? const Center(
                child: Icon(
                  Icons.check,
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
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.4),
                    blurRadius: 6,
                    spreadRadius: 1,
                  )
                ]
              : null,
        ),
        child: isSelected
            ? const Center(
                child: Icon(
                  Icons.check,
                  size: 16,
                  color: Colors.white,
                ),
              )
            : null,
      ),
    );
  }

  Widget _buildRatioOption(
    LyricCardRatio ratio,
    LyricCardRatio currentRatio,
    ThemeData theme,
    VoidCallback onTap,
  ) {
    final isSelected = ratio == currentRatio;

    Widget ratioWireframe() {
      double w = 14;
      double h = 14;
      switch (ratio) {
        case LyricCardRatio.story_9_16:
          w = 9;
          h = 16;
          break;
        case LyricCardRatio.square_1_1:
          w = 14;
          h = 14;
          break;
        case LyricCardRatio.portrait_4_5:
          w = 11;
          h = 14;
          break;
        case LyricCardRatio.landscape_16_9:
          w = 16;
          h = 9;
          break;
      }
      return Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2.5),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            width: 1.2,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.15)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline.withValues(alpha: 0.15),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 18,
              child: Center(child: ratioWireframe()),
            ),
            const SizedBox(height: 4),
            Text(
              ratio.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemePresetChip(
    LyricCardThemePreset preset,
    LyricShareState state,
    ThemeData theme,
    VoidCallback onTap,
  ) {
    final isSelected = preset == state.config.preset;
    final presetColors = LyricCardColors.fromPreset(
      preset,
      dominantAlbumColor: state.dominantAlbumColor,
      vibrantAlbumColor: state.vibrantAlbumColor,
      lightVibrantAlbumColor: state.lightVibrantAlbumColor,
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: presetColors.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : presetColors.borderColor,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: presetColors.accentColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              preset.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: presetColors.primaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required String title,
    required String subtitle,
    required bool value,
    required ThemeData theme,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectLinesTab(
    ThemeData theme,
    LyricShareState state,
    LyricShareController controller,
  ) {
    final allLines = state.allLines;

    if (allLines.isEmpty) {
      return Center(
        child: Text(
          'No synchronized lyrics available for this track.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return ListView.separated(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: allLines.length,
      separatorBuilder: (_, _) => const SizedBox(height: 6),
      itemBuilder: (context, index) {
        final line = allLines[index];
        final isSelected = state.config.selectedLines.contains(line);

        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            controller.toggleLineSelection(line);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? theme.colorScheme.primary.withValues(alpha: 0.12)
                  : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.outline.withValues(alpha: 0.12),
                width: isSelected ? 1.5 : 0.8,
              ),
            ),
            child: Row(
              children: [
                HugeIcon(
                  icon: isSelected
                      ? HugeIcons.strokeRoundedCheckmarkCircle02
                      : HugeIcons.strokeRoundedCircle,
                  size: 20,
                  color: isSelected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        line.text,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                      if (line.hasRomanization) ...[
                        const SizedBox(height: 2),
                        Text(
                          line.effectiveRomanized,
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
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
        );
      },
    );
  }

  Widget _buildBottomActionBar(
    BuildContext context,
    ThemeData theme,
    LyricShareState state,
    LyricShareController controller,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          // Save Image Button
          Expanded(
            flex: 2,
            child: OutlinedButton.icon(
              onPressed: state.isRendering
                  ? null
                  : () async {
                      HapticFeedback.lightImpact();
                      final path = await controller.saveImageLocally(_repaintBoundaryKey);
                      if (context.mounted && path != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Saved to Gallery: $path'),
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    },
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedDownload04,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              label: const Text('Save'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Share Story / Socials Button
          Expanded(
            flex: 3,
            child: FilledButton.icon(
              onPressed: state.isRendering || state.config.selectedLines.isEmpty
                  ? null
                  : () async {
                      HapticFeedback.mediumImpact();
                      final result = await controller.shareLyricCard(_repaintBoundaryKey);
                      if (context.mounted) {
                        if (result.isMissingPlugin) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Image saved to Gallery! Restart app to enable direct native sharing.'),
                              duration: Duration(seconds: 4),
                            ),
                          );
                        } else if (!result.success && result.errorMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result.errorMessage!),
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                      }
                    },
              icon: state.isRendering
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : HugeIcon(
                      icon: HugeIcons.strokeRoundedShare08,
                      size: 18,
                      color: theme.colorScheme.onPrimary,
                    ),
              label: Text(state.isRendering ? 'Generating...' : 'Share to Socials'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
