import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../core/lyrics/east_asian_romanizer.dart';
import '../../../player/domain/lyrics_line.dart';
import '../../../player/domain/track.dart';
import '../../domain/models/lyric_card_layout_style.dart';
import '../../domain/models/lyric_card_theme.dart';
import '../../domain/models/lyric_sticker_model.dart';
import '../controllers/lyric_share_controller.dart';
import 'lyric_card_widget.dart';

/// Studio Modal bottom sheet for customizing, previewing, and sharing lyric cards
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
      builder: (ctx) => Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: LyricShareSheet(
            track: track,
            allLines: allLines,
            initialSelectedLine: initialSelectedLine,
            dominantAlbumColor: dominantAlbumColor,
            vibrantAlbumColor: vibrantAlbumColor,
            lightVibrantAlbumColor: lightVibrantAlbumColor,
            audioSpec: audioSpec,
          ),
        ),
      ),
    );
  }

  @override
  ConsumerState<LyricShareSheet> createState() => _LyricShareSheetState();
}

class _LyricShareSheetState extends ConsumerState<LyricShareSheet> {
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  late final StateNotifierProvider<LyricShareController, LyricShareState> _provider;
  int _currentTabIndex = 0; // 0 = Template & Ratio, 1 = Lines, 2 = Telemetry & Stickers, 3 = Style & Colors
  final TextEditingController _noteTextController = TextEditingController();

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
  void dispose() {
    _noteTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = ref.watch(_provider);
    final controller = ref.read(_provider.notifier);

    final maxSheetHeight = MediaQuery.of(context).size.height * 0.92;

    return Container(
      height: maxSheetHeight,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            // Top Drag Handle & Title Bar
            _buildHeader(context, theme, state),

            // 4-Tab Studio Navigation Pill Bar
            _buildTabSelector(theme, state),

            const Divider(height: 1, thickness: 0.8),

            // Tab Content
            Expanded(
              child: _buildActiveTabContent(context, theme, state, controller),
            ),

            const Divider(height: 1, thickness: 0.8),

            // Bottom Actions Bar (Save & Share)
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
                      'Lyric Studio Share',
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

    final tabs = [
      (0, 'Studio', HugeIcons.strokeRoundedImage01),
      (1, 'Lines ($selectedCount/6)', HugeIcons.strokeRoundedTextFont),
      (2, 'Telemetry', HugeIcons.strokeRoundedSlidersHorizontal),
      (3, 'Style', HugeIcons.strokeRoundedPaintBoard),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: tabs.map((tab) {
            final isSelected = _currentTabIndex == tab.$1;
            return Expanded(
              child: GestureDetector(
                onTap: () {
                  AppHaptics.selectionClick();
                  setState(() => _currentTabIndex = tab.$1);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: tab.$3,
                        size: 14,
                        color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          tab.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
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
      ),
    );
  }

  Widget _buildActiveTabContent(
    BuildContext context,
    ThemeData theme,
    LyricShareState state,
    LyricShareController controller,
  ) {
    switch (_currentTabIndex) {
      case 0:
        return _buildStudioPreviewTab(context, theme, state, controller);
      case 1:
        return _buildSelectLinesTab(theme, state, controller);
      case 2:
        return _buildTelemetryTab(context, theme, state, controller);
      case 3:
        return _buildStyleTab(context, theme, state, controller);
      default:
        return const SizedBox.shrink();
    }
  }

  // ═════════════════════════════════════════════════════════════════════════
  // TAB 0: STUDIO PREVIEW & TEMPLATES
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildStudioPreviewTab(
    BuildContext context,
    ThemeData theme,
    LyricShareState state,
    LyricShareController controller,
  ) {
    final ratio = state.config.ratio;

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
          // 1. Live Card Preview Stage
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLowest,
              borderRadius: BorderRadius.circular(20),
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

          // 2. Layout Style Templates Bento
          _buildBentoSection(
            theme: theme,
            title: 'LAYOUT TEMPLATES (6 STYLES)',
            icon: HugeIcons.strokeRoundedLayout01,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: LyricCardLayoutStyle.values.map((style) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildTemplateStyleCard(style, state.config.layoutStyle, theme, () {
                      AppHaptics.selectionClick();
                      controller.setLayoutStyle(style);
                    }),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 3. Aspect Ratio Bento
          _buildBentoSection(
            theme: theme,
            title: 'ASPECT RATIO',
            icon: HugeIcons.strokeRoundedAspectRatio,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: LyricCardRatio.values.map((r) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 86,
                      child: _buildRatioOption(r, state.config.ratio, theme, () {
                        AppHaptics.selectionClick();
                        controller.setRatio(r);
                      }),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 4. Quick Branding & Specs Toggles
          _buildBentoSection(
            theme: theme,
            title: 'QUICK BADGES',
            icon: HugeIcons.strokeRoundedSparkles,
            child: Row(
              children: [
                Expanded(
                  child: _buildQuickToggleCard(
                    title: 'Branding',
                    icon: HugeIcons.strokeRoundedSparkles,
                    isActive: state.config.showBranding,
                    theme: theme,
                    onTap: () {
                      AppHaptics.selectionClick();
                      controller.toggleBranding(!state.config.showBranding);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickToggleCard(
                    title: 'Telemetry',
                    icon: HugeIcons.strokeRoundedSlidersHorizontal,
                    isActive: state.config.audiophileStamp.enabled,
                    theme: theme,
                    onTap: () {
                      AppHaptics.selectionClick();
                      controller.updateAudiophileStamp(enabled: !state.config.audiophileStamp.enabled);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildQuickToggleCard(
                    title: 'QR Link',
                    icon: HugeIcons.strokeRoundedQrCode,
                    isActive: state.config.showQrCode,
                    theme: theme,
                    onTap: () {
                      AppHaptics.selectionClick();
                      controller.toggleQrCode(!state.config.showQrCode);
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildTemplateStyleCard(
    LyricCardLayoutStyle style,
    LyricCardLayoutStyle currentStyle,
    ThemeData theme,
    VoidCallback onTap,
  ) {
    final isSelected = style == currentStyle;

    dynamic getStyleIcon() {
      switch (style) {
        case LyricCardLayoutStyle.classicMinimal:
          return HugeIcons.strokeRoundedLayout01;
        case LyricCardLayoutStyle.polaroidFrame:
          return HugeIcons.strokeRoundedImage01;
        case LyricCardLayoutStyle.cassetteJCard:
          return HugeIcons.strokeRoundedAlbum01;
        case LyricCardLayoutStyle.waveformQuote:
          return HugeIcons.strokeRoundedAudioWaveform;
        case LyricCardLayoutStyle.cyberHUD:
          return HugeIcons.strokeRoundedComputer;
        case LyricCardLayoutStyle.abstractAura:
          return HugeIcons.strokeRoundedSparkles;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 104,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.15)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: HugeIcon(
                icon: getStyleIcon(),
                size: 16,
                color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              style.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              style.subtitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickToggleCard({
    required String title,
    required dynamic icon,
    required bool isActive,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.primary.withValues(alpha: 0.15)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? theme.colorScheme.primary : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            HugeIcon(
              icon: icon,
              size: 14,
              color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // TAB 1: LYRICS & SUBTITLES SELECTION
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildSelectLinesTab(
    ThemeData theme,
    LyricShareState state,
    LyricShareController controller,
  ) {
    final allLines = state.allLines;

    return Column(
      children: [
        // Subtitles Options Header (Dual-Line Romanization)
        Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            border: Border(
              bottom: BorderSide(color: theme.colorScheme.outline.withValues(alpha: 0.1)),
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedTextFont,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dual-Line Romanization',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Auto-transliterate CJK (Romaji, Pinyin, Hangul)',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: state.config.showDualLineRomanized,
                onChanged: (val) {
                  AppHaptics.selectionClick();
                  controller.toggleDualLineRomanized(val);
                },
                activeTrackColor: theme.colorScheme.primary,
              ),
            ],
          ),
        ),

        // List of lines
        Expanded(
          child: allLines.isEmpty
              ? Center(
                  child: Text(
                    'No synchronized lyrics available for this track.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                )
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: allLines.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 6),
                  itemBuilder: (context, index) {
                    final line = allLines[index];
                    final isSelected = state.config.selectedLines.contains(line);

                    // Automatic Romanization preview if enabled
                    String? subtitleText;
                    if (line.hasRomanization) {
                      subtitleText = line.effectiveRomanized;
                    } else if (EastAsianRomanizer.needsRomanization(line.text)) {
                      subtitleText = EastAsianRomanizer.romanize(line.text);
                    }

                    return GestureDetector(
                      onTap: () {
                        AppHaptics.selectionClick();
                        controller.toggleLineSelection(line);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary.withValues(alpha: 0.12)
                              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? theme.colorScheme.primary.withValues(alpha: 0.4) : Colors.transparent,
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: HugeIcon(
                                icon: isSelected
                                    ? HugeIcons.strokeRoundedCheckmarkCircle02
                                    : HugeIcons.strokeRoundedCircle,
                                size: 18,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    line.text,
                                    style: TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected
                                          ? theme.colorScheme.primary
                                          : theme.colorScheme.onSurface,
                                    ),
                                  ),
                                  if (subtitleText != null && subtitleText.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(
                                      subtitleText,
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontStyle: FontStyle.italic,
                                        color: isSelected
                                            ? theme.colorScheme.primary.withValues(alpha: 0.8)
                                            : theme.colorScheme.onSurfaceVariant,
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
                ),
        ),
      ],
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // TAB 2: AUDIOPHILE TELEMETRY, STAMPS & STICKERS
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildTelemetryTab(
    BuildContext context,
    ThemeData theme,
    LyricShareState state,
    LyricShareController controller,
  ) {
    final stamp = state.config.audiophileStamp;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Audiophile Signal Chain Stamp Bento
          _buildBentoSection(
            theme: theme,
            title: 'SIGNAL CHAIN TELEMETRY STAMP',
            icon: HugeIcons.strokeRoundedSlidersHorizontal,
            child: Column(
              children: [
                _buildToggleRow(
                  title: 'Master Telemetry Stamp',
                  subtitle: 'Audiophile signal chain badge on footer',
                  value: stamp.enabled,
                  theme: theme,
                  onChanged: (val) {
                    AppHaptics.selectionClick();
                    controller.updateAudiophileStamp(enabled: val);
                  },
                ),
                if (stamp.enabled) ...[
                  const Divider(height: 12, thickness: 0.6),
                  _buildToggleRow(
                    title: 'Format & Sampling Rate',
                    subtitle: 'e.g. FLAC 96kHz / 24-bit',
                    value: stamp.showFormatRate,
                    theme: theme,
                    onChanged: (val) {
                      AppHaptics.selectionClick();
                      controller.updateAudiophileStamp(showFormatRate: val);
                    },
                  ),
                  const Divider(height: 12, thickness: 0.6),
                  _buildToggleRow(
                    title: 'AutoEQ Profile Tag',
                    subtitle: stamp.effectiveAutoEqName,
                    value: stamp.showAutoEqProfile,
                    theme: theme,
                    onChanged: (val) {
                      AppHaptics.selectionClick();
                      controller.updateAudiophileStamp(showAutoEqProfile: val);
                    },
                  ),
                  const Divider(height: 12, thickness: 0.6),
                  _buildToggleRow(
                    title: 'Virtual DSP Chain',
                    subtitle: stamp.effectiveDspChainName,
                    value: stamp.showVirtualDspChain,
                    theme: theme,
                    onChanged: (val) {
                      AppHaptics.selectionClick();
                      controller.updateAudiophileStamp(showVirtualDspChain: val);
                    },
                  ),
                  const Divider(height: 12, thickness: 0.6),
                  _buildToggleRow(
                    title: 'Hardware DAC / USB Bridge',
                    subtitle: stamp.effectiveDacName,
                    value: stamp.showHardwareDac,
                    theme: theme,
                    onChanged: (val) {
                      AppHaptics.selectionClick();
                      controller.updateAudiophileStamp(showHardwareDac: val);
                    },
                  ),
                  const Divider(height: 12, thickness: 0.6),
                  _buildToggleRow(
                    title: 'Timestamp & Signature',
                    subtitle: 'Render timestamp verification tag',
                    value: stamp.showTimestamp,
                    theme: theme,
                    onChanged: (val) {
                      AppHaptics.selectionClick();
                      controller.updateAudiophileStamp(showTimestamp: val);
                    },
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 2. Studio Stickers Bento
          _buildBentoSection(
            theme: theme,
            title: 'STUDIO STICKERS & STAMPS (MAX 3)',
            icon: HugeIcons.strokeRoundedAward01,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: LyricStickerType.values.map((type) {
                final isSelected = state.config.selectedStickers.contains(type);
                return GestureDetector(
                  onTap: () {
                    AppHaptics.selectionClick();
                    controller.toggleSticker(type);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.15)
                          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected ? theme.colorScheme.primary : Colors.transparent,
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HugeIcon(
                          icon: type.icon,
                          size: 14,
                          color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          type.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // 3. Personal Note / Caption Bento
          _buildBentoSection(
            theme: theme,
            title: 'PERSONAL NOTE / CAPTION',
            icon: HugeIcons.strokeRoundedEdit02,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _noteTextController,
                  maxLines: 2,
                  style: const TextStyle(fontSize: 12.5),
                  decoration: InputDecoration(
                    hintText: 'e.g. Listening to this late at night on HD600...',
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                      ),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (text) {
                    controller.setPersonalNote(text);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ═════════════════════════════════════════════════════════════════════════
  // TAB 3: STYLING & PALETTE
  // ═════════════════════════════════════════════════════════════════════════

  Widget _buildStyleTab(
    BuildContext context,
    ThemeData theme,
    LyricShareState state,
    LyricShareController controller,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Typography & Font Weight Bento
          _buildBentoSection(
            theme: theme,
            title: 'TYPOGRAPHY & FONT WEIGHT',
            icon: HugeIcons.strokeRoundedTextFont,
            child: _buildTypographySection(theme, state, controller),
          ),

          const SizedBox(height: 12),

          // 2. Text Styles & Highlights Bento
          _buildBentoSection(
            theme: theme,
            title: 'TEXT STYLES & HIGHLIGHTS',
            icon: HugeIcons.strokeRoundedPaintBoard,
            child: _buildHighlightAndStyleSection(theme, state, controller),
          ),

          const SizedBox(height: 12),

          // 3. Background & Palette Bento
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
                    icon: HugeIcons.strokeRoundedTextAlignLeft,
                    isSelected: config.textAlign == TextAlign.left,
                    theme: theme,
                    onTap: () {
                      AppHaptics.selectionClick();
                      controller.setTextAlign(TextAlign.left);
                    },
                  ),
                  _buildIconToggle(
                    icon: HugeIcons.strokeRoundedTextAlignCenter,
                    isSelected: config.textAlign == TextAlign.center,
                    theme: theme,
                    onTap: () {
                      AppHaptics.selectionClick();
                      controller.setTextAlign(TextAlign.center);
                    },
                  ),
                  _buildIconToggle(
                    icon: HugeIcons.strokeRoundedTextAlignRight,
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
                icon: HugeIcons.strokeRoundedTextItalic,
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
                      AppHaptics.selectionClick();
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

  dynamic _getHighlightIcon(LyricCardHighlightStyle? style) {
    switch (style ?? LyricCardHighlightStyle.none) {
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
                _buildThemePresetChip(preset, state, theme, () {
                  AppHaptics.selectionClick();
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
                      AppHaptics.lightImpact();
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
                      AppHaptics.mediumImpact();
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
