import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/database/local_persistence_service.dart';
import '../../../../core/lyrics/east_asian_romanizer.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../lyrics_share/presentation/widgets/lyric_share_sheet.dart';
import '../../data/lyrics_service.dart';
import '../../domain/lyrics_line.dart';
import '../controllers/player_controller.dart';

/// Real-time Synchronized & Plain LRC Lyrics Display with East Asian Romanization & Timing Offset Synchronizer
class SynchronizedLyricsView extends ConsumerStatefulWidget {
  final LyricsResult lyricsResult;
  final Duration currentPosition;
  final bool isLoading;
  final VoidCallback? onRefresh;
  final String? trackId;

  const SynchronizedLyricsView({
    super.key,
    required this.lyricsResult,
    required this.currentPosition,
    this.isLoading = false,
    this.onRefresh,
    this.trackId,
  });

  @override
  ConsumerState<SynchronizedLyricsView> createState() => _SynchronizedLyricsViewState();
}

class _SynchronizedLyricsViewState extends ConsumerState<SynchronizedLyricsView> {
  final ScrollController _scrollController = ScrollController();
  final Map<int, GlobalKey> _lineKeys = {};
  int _lastActiveIndex = -1;
  LyricsDisplayMode _displayMode = LyricsDisplayMode.dualLine;
  Duration _timingOffset = Duration.zero;

  @override
  void initState() {
    super.initState();
    _loadPersistedSettings();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.lyricsResult.isSynced && widget.lyricsResult.lines.isNotEmpty) {
        final activeIndex = LrcParser.findActiveIndex(
          widget.lyricsResult.lines,
          widget.currentPosition,
          offset: _timingOffset,
        );
        if (activeIndex >= 0) {
          _lastActiveIndex = activeIndex;
          _scrollToActiveLine(activeIndex);
        }
      }
    });
  }

  void _loadPersistedSettings() {
    // 1. Display Mode
    final savedMode = LocalPersistenceService.instance.getSetting<String>('lyrics_display_mode');
    if (savedMode != null) {
      _displayMode = LyricsDisplayMode.values.firstWhere(
        (m) => m.name == savedMode,
        orElse: () => LyricsDisplayMode.dualLine,
      );
    }

    // 2. Track Timing Offset
    if (widget.trackId != null) {
      final savedOffsetMs = LocalPersistenceService.instance.getSetting<int>('lyrics_offset_${widget.trackId}', 0);
      _timingOffset = Duration(milliseconds: savedOffsetMs ?? 0);
    }
  }

  void _setDisplayMode(LyricsDisplayMode mode) {
    HapticFeedback.selectionClick();
    setState(() {
      _displayMode = mode;
      _lineKeys.clear();
    });
    LocalPersistenceService.instance.saveSetting('lyrics_display_mode', mode.name);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _lastActiveIndex < 0) return;
      _scrollToActiveLine(_lastActiveIndex);
    });
  }

  void _updateTimingOffset(Duration newOffset) {
    HapticFeedback.selectionClick();
    setState(() {
      _timingOffset = newOffset;
    });
    if (widget.trackId != null) {
      LocalPersistenceService.instance.saveSetting('lyrics_offset_${widget.trackId}', newOffset.inMilliseconds);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (widget.lyricsResult.isSynced && widget.lyricsResult.lines.isNotEmpty) {
        final activeIndex = LrcParser.findActiveIndex(
          widget.lyricsResult.lines,
          widget.currentPosition,
          offset: _timingOffset,
        );
        if (activeIndex >= 0) {
          _lastActiveIndex = activeIndex;
          _scrollToActiveLine(activeIndex);
        }
      }
    });
  }

  @override
  void didUpdateWidget(covariant SynchronizedLyricsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trackId != oldWidget.trackId && widget.trackId != null) {
      final savedOffsetMs = LocalPersistenceService.instance.getSetting<int>('lyrics_offset_${widget.trackId}', 0);
      _timingOffset = Duration(milliseconds: savedOffsetMs ?? 0);
      _lineKeys.clear();
    }

    if (widget.lyricsResult.isSynced && widget.lyricsResult.lines.isNotEmpty) {
      final activeIndex = LrcParser.findActiveIndex(
        widget.lyricsResult.lines,
        widget.currentPosition,
        offset: _timingOffset,
      );
      if (activeIndex != _lastActiveIndex && activeIndex >= 0) {
        _lastActiveIndex = activeIndex;
        _scrollToActiveLine(activeIndex);
      }
    }
  }

  void _scrollToActiveLine(int index) {
    if (!_scrollController.hasClients) return;

    final key = _lineKeys[index];
    if (key?.currentContext != null) {
      Scrollable.ensureVisible(
        key!.currentContext!,
        alignment: 0.5,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
    } else {
      final itemHeight = _displayMode == LyricsDisplayMode.dualLine ? 74.0 : 56.0;
      final viewportHeight = _scrollController.position.viewportDimension;
      final targetOffset = (index * itemHeight) - (viewportHeight / 2) + (itemHeight / 2);
      final maxExtent = _scrollController.position.maxScrollExtent;
      _scrollController.animateTo(
        targetOffset.clamp(0.0, maxExtent > 0 ? maxExtent : double.infinity),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
      );
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final k = _lineKeys[index];
        if (k?.currentContext != null) {
          Scrollable.ensureVisible(
            k!.currentContext!,
            alignment: 0.5,
            duration: const Duration(milliseconds: 150),
            curve: Curves.easeOutCubic,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isSolid = ref.isSolidStyle;

    if (widget.isLoading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.2,
                valueColor: AlwaysStoppedAnimation<Color>(primary),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Searching LRCLIB & Local Metadata...',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    if (widget.lyricsResult.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedTextFont,
              size: 40,
              color: theme.dividerColor,
            ),
            const SizedBox(height: 12),
            Text(
              'No lyrics found for this track.',
              style: TextStyle(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (widget.onRefresh != null)
              OutlinedButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  widget.onRefresh!();
                },
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedSearch01,
                  size: 14,
                  color: primary,
                ),
                label: Text(
                  'Search Online (LRCLIB)',
                  style: TextStyle(
                    fontSize: 11,
                    color: primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: isSolid ? theme.colorScheme.outline : primary.withValues(alpha: 0.5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
              ),
          ],
        ),
      );
    }

    final isSynced = widget.lyricsResult.isSynced;
    final lines = widget.lyricsResult.lines;
    final activeIndex = isSynced
        ? LrcParser.findActiveIndex(lines, widget.currentPosition, offset: _timingOffset)
        : -1;

    return Stack(
      children: [
        // Lyrics List
        ShaderMask(
          shaderCallback: (Rect bounds) {
            return const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                Colors.black,
                Colors.black,
                Colors.transparent,
              ],
              stops: [0.0, 0.12, 0.88, 1.0],
            ).createShader(bounds);
          },
          blendMode: BlendMode.dstIn,
          child: ListView.builder(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 56),
            itemCount: lines.isNotEmpty ? lines.length : 1,
            itemBuilder: (context, index) {
              if (lines.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Text(
                    widget.lyricsResult.rawLyrics,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14.5,
                      height: 1.8,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                );
              }

              final line = lines[index];
              final isActive = isSynced && index == activeIndex;
              final lineKey = _lineKeys.putIfAbsent(index, () => GlobalKey());

              return KeyedSubtree(
                key: lineKey,
                child: InkWell(
                  onTap: isSynced
                      ? () {
                          HapticFeedback.selectionClick();
                          final seekPos = line.timestamp - _timingOffset;
                          ref.read(playerControllerProvider.notifier).seek(
                            seekPos < Duration.zero ? Duration.zero : seekPos,
                          );
                        }
                      : () => _openLyricShareSheet(line),
                  onLongPress: () => _openLyricShareSheet(line),
                  borderRadius: BorderRadius.circular(12),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    decoration: BoxDecoration(
                      color: isActive
                          ? StudioSurfaceTheme.tintedContainer(
                              context,
                              primary,
                              isSolid: isSolid,
                              translucentAlpha: 0.15,
                              solidBlendAlpha: 0.18,
                            )
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isActive
                            ? (isSolid ? theme.colorScheme.outline : primary.withValues(alpha: 0.4))
                            : Colors.transparent,
                        width: 1.0,
                      ),
                    ),
                    child: _buildLyricLineContent(line, isActive, isSynced, primary, theme),
                  ),
                ),
              );
            },
          ),
        ),

        // Floating Action Bar at Top (Display Mode Pill, Share Lyrics, Offset Stepper & Source Badge)
        Positioned(
          top: 6,
          left: 12,
          right: 12,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.center,
            child: SizedBox(
              width: MediaQuery.of(context).size.width - 24,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // 1. Display Mode Switcher Capsule
                  _buildModeSwitcherCapsule(theme, primary, isSolid),

                  // 2. Right Actions: Share Lyrics, Timing Offset Stepper & Source Badge
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (lines.isNotEmpty) ...[
                        _buildShareLyricsButton(context, theme, primary, isSolid),
                        const SizedBox(width: 6),
                      ],
                      if (isSynced) ...[
                        _buildTimingOffsetButton(context, theme, primary, isSolid),
                        const SizedBox(width: 6),
                      ],
                      _buildSourceBadge(context, widget.lyricsResult.source, isSynced, primary, theme, isSolid),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLyricLineContent(
    LyricsLine line,
    bool isActive,
    bool isSynced,
    Color primary,
    ThemeData theme,
  ) {
    switch (_displayMode) {
      case LyricsDisplayMode.original:
        return Text(
          line.text,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isActive ? 17.5 : 14.0,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
            color: isActive
                ? primary
                : theme.colorScheme.onSurface.withValues(
                    alpha: isSynced ? 0.45 : 0.8,
                  ),
            letterSpacing: isActive ? 0.3 : 0.0,
            shadows: isActive
                ? [
                    Shadow(
                      color: primary.withValues(alpha: 0.5),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
        );

      case LyricsDisplayMode.romanized:
        return Text(
          line.effectiveRomanized,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: isActive ? 17.0 : 13.5,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
            color: isActive
                ? primary
                : theme.colorScheme.onSurface.withValues(
                    alpha: isSynced ? 0.45 : 0.8,
                  ),
            letterSpacing: isActive ? 0.3 : 0.0,
            shadows: isActive
                ? [
                    Shadow(
                      color: primary.withValues(alpha: 0.5),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
        );

      case LyricsDisplayMode.dualLine:
        final hasRom = line.hasRomanization;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              line.text,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isActive ? 17.0 : 14.0,
                fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                color: isActive
                    ? primary
                    : theme.colorScheme.onSurface.withValues(
                        alpha: isSynced ? 0.5 : 0.85,
                      ),
                letterSpacing: isActive ? 0.2 : 0.0,
                shadows: isActive
                    ? [
                        Shadow(
                          color: primary.withValues(alpha: 0.4),
                          blurRadius: 10,
                        ),
                      ]
                    : null,
              ),
            ),
            if (hasRom) ...[
              const SizedBox(height: 3),
              Text(
                line.romanizedText!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: isActive ? 13.0 : 11.5,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  fontStyle: FontStyle.italic,
                  color: isActive
                      ? primary.withValues(alpha: 0.85)
                      : theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: isSynced ? 0.4 : 0.65,
                        ),
                  letterSpacing: 0.1,
                ),
              ),
            ],
          ],
        );
    }
  }

  Widget _buildModeSwitcherCapsule(ThemeData theme, Color primary, bool isSolid) {
    return Container(
      padding: const EdgeInsets.all(2.5),
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildModeOptionPill('ORIG', LyricsDisplayMode.original, theme, primary),
          _buildModeOptionPill('ROM', LyricsDisplayMode.romanized, theme, primary),
          _buildModeOptionPill('DUAL', LyricsDisplayMode.dualLine, theme, primary),
        ],
      ),
    );
  }

  Widget _buildModeOptionPill(
    String label,
    LyricsDisplayMode mode,
    ThemeData theme,
    Color primary,
  ) {
    final isSelected = _displayMode == mode;
    return GestureDetector(
      onTap: () => _setDisplayMode(mode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 3.0),
        decoration: BoxDecoration(
          color: isSelected ? primary : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9.0,
            fontWeight: FontWeight.w800,
            color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }

  Widget _buildShareLyricsButton(BuildContext context, ThemeData theme, Color primary, bool isSolid) {
    return GestureDetector(
      onTap: () => _openLyricShareSheet(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
        decoration: BoxDecoration(
          color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedShare08,
              size: 11,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 3.5),
            Text(
              'SHARE',
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openLyricShareSheet([LyricsLine? initialLine]) {
    final track = ref.read(playerControllerProvider).currentTrack;
    if (track == null || widget.lyricsResult.lines.isEmpty) return;

    HapticFeedback.mediumImpact();
    LyricShareSheet.show(
      context,
      track: track,
      allLines: widget.lyricsResult.lines,
      initialSelectedLine: initialLine,
      audioSpec: track.format.name.isNotEmpty && track.format.name != 'unknown'
          ? '${track.format.name.toUpperCase()} MASTER'
          : 'STUDIO MASTER',
    );
  }

  Widget _buildTimingOffsetButton(BuildContext context, ThemeData theme, Color primary, bool isSolid) {
    final hasOffset = _timingOffset != Duration.zero;
    final offsetMs = _timingOffset.inMilliseconds;
    final label = hasOffset
        ? '${offsetMs > 0 ? '+' : ''}${offsetMs}ms'
        : 'SYNC';

    return GestureDetector(
      onTap: () => _showTimingOffsetSheet(context, isSolid),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
        decoration: BoxDecoration(
          color: hasOffset
              ? StudioSurfaceTheme.tintedContainer(context, primary, isSolid: isSolid, translucentAlpha: 0.15)
              : StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: hasOffset
                ? (isSolid ? theme.colorScheme.outline : primary)
                : StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedSlidersHorizontal,
              size: 11,
              color: hasOffset ? primary : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 3.5),
            Text(
              label,
              style: TextStyle(
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                color: hasOffset ? primary : theme.colorScheme.onSurfaceVariant,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTimingOffsetSheet(BuildContext context, bool isSolid) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    showModalBottomSheet(
      context: context,
      backgroundColor: StudioSurfaceTheme.surface(context, isSolid: isSolid),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (modalCtx, setModalState) {
            final offsetMs = _timingOffset.inMilliseconds;
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: StudioSurfaceTheme.outline(ctx, isSolid: isSolid),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedClock01,
                              size: 18,
                              color: primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'LRC TIMING SYNCHRONIZER',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        if (_timingOffset != Duration.zero)
                          TextButton(
                            onPressed: () {
                              _updateTimingOffset(Duration.zero);
                              setModalState(() {});
                            },
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'RESET',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.error,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Current Offset Numeric Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: StudioSurfaceTheme.surfaceContainerHigh(ctx, isSolid: isSolid),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: offsetMs != 0
                              ? (isSolid ? theme.colorScheme.outline : primary)
                              : StudioSurfaceTheme.subtleOutline(ctx, isSolid: isSolid),
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Active Offset Delay',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Text(
                            '${offsetMs > 0 ? '+' : ''}$offsetMs ms',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: offsetMs != 0 ? primary : theme.colorScheme.onSurface,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Fast Stepper Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildStepperBtn('-500ms', -500, setModalState, theme, isSolid),
                        _buildStepperBtn('-100ms', -100, setModalState, theme, isSolid),
                        _buildStepperBtn('+100ms', 100, setModalState, theme, isSolid),
                        _buildStepperBtn('+500ms', 500, setModalState, theme, isSolid),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Slider Fine Adjustment (-3000ms to +3000ms)
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: primary,
                        inactiveTrackColor: StudioSurfaceTheme.surfaceContainerHigh(ctx, isSolid: isSolid),
                        thumbColor: primary,
                        overlayColor: primary.withValues(alpha: 0.15),
                        trackHeight: 3,
                      ),
                      child: Slider(
                        value: offsetMs.clamp(-3000, 3000).toDouble(),
                        min: -3000,
                        max: 3000,
                        divisions: 60,
                        label: '${offsetMs}ms',
                        onChanged: (val) {
                          _updateTimingOffset(Duration(milliseconds: val.round()));
                          setModalState(() {});
                        },
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'Adjust offset if vocals start ahead or behind the highlighted line',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStepperBtn(
    String label,
    int deltaMs,
    StateSetter setModalState,
    ThemeData theme,
    bool isSolid,
  ) {
    return OutlinedButton(
      onPressed: () {
        final newMs = _timingOffset.inMilliseconds + deltaMs;
        _updateTimingOffset(Duration(milliseconds: newMs));
        setModalState(() {});
      },
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  Widget _buildSourceBadge(
    BuildContext context,
    LyricsSource source,
    bool isSynced,
    Color primary,
    ThemeData theme,
    bool isSolid,
  ) {
    String label;
    dynamic icon;
    Color color = primary;

    switch (source) {
      case LyricsSource.embedded:
        label = isSynced ? 'EMBEDDED LRC' : 'EMBEDDED TXT';
        icon = HugeIcons.strokeRoundedSparkles;
        color = const Color(0xFF00E676);
        break;
      case LyricsSource.sidecarFile:
        label = 'SIDECAR .LRC';
        icon = HugeIcons.strokeRoundedFolder01;
        color = const Color(0xFF00F0FF);
        break;
      case LyricsSource.onlineLrclib:
        label = isSynced ? 'LRCLIB SYNCED' : 'LRCLIB PLAIN';
        icon = HugeIcons.strokeRoundedCloudCheck;
        color = const Color(0xFFFF9F0A);
        break;
      case LyricsSource.cached:
        label = isSynced ? 'CACHED LRC' : 'CACHED TXT';
        icon = HugeIcons.strokeRoundedFolder01;
        color = theme.colorScheme.onSurface.withValues(alpha: 0.7);
        break;
      case LyricsSource.none:
        return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.tintedContainer(context, color, isSolid: isSolid, translucentAlpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSolid ? theme.colorScheme.outline : color.withValues(alpha: 0.35),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: icon, size: 10, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

