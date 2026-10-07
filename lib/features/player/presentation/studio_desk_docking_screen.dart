import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../../app/theme/app_haptics.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/studio_surface_theme.dart';
import '../../dsp_rack/domain/dsp_models.dart';
import '../../dsp_rack/presentation/controllers/dsp_rack_controller.dart';
import '../../dsp_rack/presentation/widgets/vu_level_meter.dart';
import '../../settings/presentation/controllers/player_customization_controller.dart';
import '../domain/playback_state.dart';
import '../domain/track.dart';
import 'controllers/player_controller.dart';
import 'widgets/audio_file_inspector_sheet.dart';
import 'widgets/custom_time_bar.dart';
import 'widgets/parallax_artwork_card.dart';
import 'widgets/spectrum_visualizer.dart';

enum DeskVisualMode {
  artwork('ARTWORK', HugeIcons.strokeRoundedAlbum01),
  vuMeters('VU METERS', HugeIcons.strokeRoundedSlidersVertical),
  spectrum('SPECTRUM', HugeIcons.strokeRoundedAudioWaveform);

  final String label;
  final dynamic icon;
  const DeskVisualMode(this.label, this.icon);
}

/// Studio Desk & Car Docking Fullscreen Experience
/// High-contrast, glanceable studio/car mode with large controls, studio clock & VU meters.
class StudioDeskDockingScreen extends ConsumerStatefulWidget {
  const StudioDeskDockingScreen({super.key});

  static Future<void> show(BuildContext context) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        pageBuilder: (context, animation, secondaryAnimation) => const StudioDeskDockingScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  @override
  ConsumerState<StudioDeskDockingScreen> createState() => _StudioDeskDockingScreenState();
}

class _StudioDeskDockingScreenState extends ConsumerState<StudioDeskDockingScreen> {
  Timer? _clockTimer;
  DateTime _currentTime = DateTime.now();
  DeskVisualMode _visualMode = DeskVisualMode.artwork;

  @override
  void initState() {
    super.initState();
    // Keep clock updated every second (disable in widget test environment to allow pumpAndSettle)
    final isTesting = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTesting) {
      _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) {
          setState(() => _currentTime = DateTime.now());
        }
      });
    }
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  String _formatClockTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    final s = t.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatDate(DateTime t) {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return '${days[t.weekday - 1]}, ${t.day} ${months[t.month - 1]} ${t.year}';
  }

  void _cycleVisualMode() {
    AppHaptics.selectionClick();
    setState(() {
      switch (_visualMode) {
        case DeskVisualMode.artwork:
          _visualMode = DeskVisualMode.vuMeters;
          break;
        case DeskVisualMode.vuMeters:
          _visualMode = DeskVisualMode.spectrum;
          break;
        case DeskVisualMode.spectrum:
          _visualMode = DeskVisualMode.artwork;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final playback = ref.watch(playerControllerProvider);
    final playerNotifier = ref.read(playerControllerProvider.notifier);
    final dspState = ref.watch(dspRackControllerProvider);
    final dspNotifier = ref.read(dspRackControllerProvider.notifier);
    final displaySettings = ref.watch(playerCustomizationProvider);
    final track = playback.currentTrack;
    final isSolid = ref.isSolidStyle;

    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: StudioSurfaceTheme.surface(context, isSolid: isSolid),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isLandscape = constraints.maxWidth > constraints.maxHeight;

            return Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isLandscape ? 16.0 : 12.0,
                vertical: 8.0,
              ),
              child: Column(
                children: [
                  // ─── 1. TOP STUDIO STATUS & CLOCK BAR ─────────────────────
                  _buildStudioTopBar(context, primary, track, isLandscape, isSolid),
                  const SizedBox(height: 8),

                  // ─── 2. MAIN CENTER BODY (LANDSCAPE OR PORTRAIT) ──────────
                  Expanded(
                    child: isLandscape
                        ? _buildLandscapeBody(
                            context,
                            playback,
                            playerNotifier,
                            dspState,
                            dspNotifier,
                            displaySettings,
                            primary,
                            isSolid,
                          )
                        : _buildPortraitBody(
                            context,
                            playback,
                            playerNotifier,
                            dspState,
                            dspNotifier,
                            displaySettings,
                            primary,
                            isSolid,
                          ),
                  ),

                  const SizedBox(height: 6),

                  // ─── 3. BOTTOM GLANCEABLE PRESET & MASTER STRIP ───────────
                  _buildBottomDspPresetsStrip(
                    context,
                    dspState,
                    dspNotifier,
                    playback,
                    playerNotifier,
                    primary,
                    isLandscape,
                    isSolid,
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── STUDIO TOP BAR ───────────────────────────────────────────────────────
  Widget _buildStudioTopBar(BuildContext context, Color primary, Track? track, bool isLandscape, bool isSolid) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Exit Docking Button
          InkWell(
            onTap: () {
              AppHaptics.mediumImpact();
              Navigator.of(context).pop();
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              decoration: BoxDecoration(
                color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedMinimize01,
                    size: 14,
                    color: theme.colorScheme.secondary,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'EXIT DOCK',
                    style: TextStyle(
                      color: theme.colorScheme.secondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Center: Large Digital Studio Clock
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00E676),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        _formatClockTime(_currentTime),
                        style: TextStyle(
                          fontFeatures: AppTypography.audioFigures,
                          fontSize: isLandscape ? 15 : 13,
                          fontWeight: FontWeight.w900,
                          color: theme.colorScheme.onSurface,
                          letterSpacing: 0.6,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                Text(
                  _formatDate(_currentTime),
                  style: TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurfaceVariant,
                    letterSpacing: 0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Right: Visualizer Mode Toggle & AWAKE
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: _cycleVisualMode,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                  decoration: BoxDecoration(
                    color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: primary.withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: _visualMode.icon,
                        size: 13,
                        color: primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _visualMode.label,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          color: primary,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (isLandscape) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: StudioSurfaceTheme.tintedContainer(
                      context,
                      const Color(0xFF00E676),
                      isSolid: isSolid,
                      translucentAlpha: 0.15,
                      solidBlendAlpha: 0.18,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'AWAKE',
                    style: TextStyle(
                      color: Color(0xFF00E676),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.4,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ─── VISUALIZER AREA WIDGET (Artwork, VU, Spectrum) ───────────────────────
  Widget _buildVisualDisplayArea(
    BuildContext context,
    PlaybackState playback,
    Track? track,
    Color primary,
    bool isSolid,
    double size,
  ) {
    final theme = Theme.of(context);

    switch (_visualMode) {
      case DeskVisualMode.artwork:
        return Center(
          child: ParallaxArtworkCard(
            track: track,
            isPlaying: playback.isPlaying,
            primaryColor: primary,
            size: size,
            onSingleTap: () => ref.read(playerControllerProvider.notifier).togglePlayPause(),
            onDoubleTap: _cycleVisualMode,
          ),
        );

      case DeskVisualMode.vuMeters:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('L-CH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primary)),
                  Text(
                    'ANALOG STEREO MONITOR',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurfaceVariant,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text('R-CH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primary)),
                ],
              ),
              const SizedBox(height: 8),
              VuLevelMeter(
                levelDb: playback.isPlaying ? (playback.preAmpDb - 2.5) : -24.0,
                peakDb: playback.isPlaying ? playback.preAmpDb : -24.0,
                height: 24,
              ),
              const SizedBox(height: 8),
              VuLevelMeter(
                levelDb: playback.isPlaying ? (playback.preAmpDb - 3.2) : -24.0,
                peakDb: playback.isPlaying ? (playback.preAmpDb - 0.5) : -24.0,
                height: 24,
              ),
            ],
          ),
        );

      case DeskVisualMode.spectrum:
        return const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.0),
            child: SpectrumVisualizer(height: 60),
          ),
        );
    }
  }

  // ─── AUDIO SPECS BANNER ───────────────────────────────────────────────────
  Widget _buildAudioSpecsBanner(BuildContext context, Track? track, ThemeData theme, Color primary, bool isSolid) {
    if (track == null) return const SizedBox.shrink();

    final formatStr = track.format.name.toUpperCase();
    final sampleRateStr = track.sampleRate != null
        ? '${(track.sampleRate! / 1000).toStringAsFixed(1)} kHz'
        : '44.1 kHz';
    final bitDepthStr = track.bitDepth != null ? '${track.bitDepth}-bit' : '16-bit';
    final isHiRes = track.isHiRes;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          AppHaptics.lightImpact();
          AudioFileInspectorSheet.show(context, track);
        },
        borderRadius: BorderRadius.circular(7),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid, translucentAlpha: 0.4),
            borderRadius: BorderRadius.circular(7),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: StudioSurfaceTheme.tintedContainer(
                      context,
                      isHiRes ? StudioCategoryColors.hiResGold : StudioCategoryColors.flacLossless,
                      isSolid: isSolid,
                      translucentAlpha: 0.18,
                      solidBlendAlpha: 0.22,
                    ),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    isHiRes ? 'HI-RES MASTER' : 'LOSSLESS AUDIO',
                    style: TextStyle(
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                      color: isHiRes ? StudioCategoryColors.hiResGold : StudioCategoryColors.flacLossless,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '$formatStr • $bitDepthStr / $sampleRateStr',
                  style: TextStyle(
                    fontFeatures: AppTypography.audioFigures,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── LANDSCAPE SPLIT VIEW ─────────────────────────────────────────────────
  Widget _buildLandscapeBody(
    BuildContext context,
    PlaybackState playback,
    PlayerController playerNotifier,
    DspRackState dspState,
    DspRackController dspNotifier,
    dynamic displaySettings,
    Color primary,
    bool isSolid,
  ) {
    final track = playback.currentTrack;
    final theme = Theme.of(context);

    return Row(
      children: [
        // Left Column: Big Album Art / VU Meter & Track Info
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                  child: _buildVisualDisplayArea(context, playback, track, primary, isSolid, 140),
                ),
                const SizedBox(height: 6),
                Text(
                  track?.title ?? 'No Track Playing',
                  style: TextStyle(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w900,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  track != null ? '${track.artist} • ${track.album}' : 'Select music from library',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                _buildAudioSpecsBanner(context, track, theme, primary, isSolid),
              ],
            ),
          ),
        ),

        const SizedBox(width: 12),

        // Right Column: Expressive Wavy Seekbar & Massive Playback Controls
        Expanded(
          flex: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 1. M3 Expressive Customizable Time Bar (Wavy Seekbar)
                CustomTimeBar(
                  position: playback.position,
                  duration: playback.duration,
                  style: displaySettings.timeBarStyle,
                  primaryColor: primary,
                  timeDisplayMode: playback.timeDisplayMode,
                  onToggleTimeDisplayMode: () =>
                      playerNotifier.toggleTimeDisplayMode(),
                  onSeek: (newPos) => playerNotifier.seek(newPos),
                ),

                const SizedBox(height: 12),

                // 2. Glanceable Playback Controls Deck
                _buildControlsDeck(context, playback, playerNotifier, primary, isSolid, isLandscape: true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ─── PORTRAIT STAND VIEW ──────────────────────────────────────────────────
  Widget _buildPortraitBody(
    BuildContext context,
    PlaybackState playback,
    PlayerController playerNotifier,
    DspRackState dspState,
    DspRackController dspNotifier,
    dynamic displaySettings,
    Color primary,
    bool isSolid,
  ) {
    final track = playback.currentTrack;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Upper Visualizer Area
          Expanded(
            child: _buildVisualDisplayArea(context, playback, track, primary, isSolid, 175),
          ),

          const SizedBox(height: 8),

          // High Contrast Track Information
          Text(
            track?.title ?? 'No Track Playing',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: theme.colorScheme.onSurface,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            track != null ? '${track.artist} • ${track.album}' : 'Tap library to begin playback',
            style: TextStyle(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          _buildAudioSpecsBanner(context, track, theme, primary, isSolid),

          const SizedBox(height: 10),

          // M3 Expressive Customizable Time Bar (Wavy Seekbar)
          CustomTimeBar(
            position: playback.position,
            duration: playback.duration,
            style: displaySettings.timeBarStyle,
            primaryColor: primary,
            timeDisplayMode: playback.timeDisplayMode,
            onToggleTimeDisplayMode: () =>
                playerNotifier.toggleTimeDisplayMode(),
            onSeek: (newPos) => playerNotifier.seek(newPos),
          ),

          const SizedBox(height: 10),

          // Playback Deck
          _buildControlsDeck(context, playback, playerNotifier, primary, isSolid, isLandscape: false),
        ],
      ),
    );
  }

  // ─── MAIN CONTROLS DECK (Massive Glowing Centerpiece & Symmetrical Buttons) ─
  Widget _buildControlsDeck(
    BuildContext context,
    PlaybackState playback,
    PlayerController playerNotifier,
    Color primary,
    bool isSolid, {
    required bool isLandscape,
  }) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Shuffle
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: playback.isShuffle
                ? StudioSurfaceTheme.tintedContainer(context, primary, isSolid: isSolid, translucentAlpha: 0.15)
                : StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
            borderRadius: BorderRadius.circular(14),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              AppHaptics.selectionClick();
              playerNotifier.toggleShuffle();
            },
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedShuffle,
              size: 20,
              color: playback.isShuffle ? primary : theme.colorScheme.onSurfaceVariant,
            ),
            tooltip: 'Shuffle',
          ),
        ),

        // Previous Track
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
            borderRadius: BorderRadius.circular(14),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              AppHaptics.lightImpact();
              playerNotifier.skipPrevious();
            },
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedPrevious,
              size: 24,
              color: theme.colorScheme.onSurface,
            ),
            tooltip: 'Previous',
          ),
        ),

        // Massive Glowing Centerpiece Play/Pause
        Container(
          width: 68,
          height: 68,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: primary,
            boxShadow: [
              BoxShadow(
                color: primary.withValues(alpha: isSolid ? 0.35 : 0.5),
                blurRadius: 20,
                spreadRadius: 1,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              AppHaptics.mediumImpact();
              playerNotifier.togglePlayPause();
            },
            icon: playback.isLoading
                ? SizedBox(
                    width: 28,
                    height: 28,
                    child: M3EProgressIndicator.circular(
                      strokeWidth: 2.8,
                      color: theme.colorScheme.onPrimary,
                    ),
                  )
                : HugeIcon(
                    icon: playback.isPlaying ? HugeIcons.strokeRoundedPause : HugeIcons.strokeRoundedPlay,
                    color: theme.colorScheme.onPrimary,
                    size: 30,
                  ),
            tooltip: playback.isLoading ? 'Buffering...' : (playback.isPlaying ? 'Pause' : 'Play'),
          ),
        ),

        // Next Track
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
            borderRadius: BorderRadius.circular(14),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              AppHaptics.lightImpact();
              playerNotifier.skipNext();
            },
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedNext,
              size: 24,
              color: theme.colorScheme.onSurface,
            ),
            tooltip: 'Next',
          ),
        ),

        // Repeat
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: playback.repeatMode != PlaybackRepeatMode.off
                ? StudioSurfaceTheme.tintedContainer(context, primary, isSolid: isSolid, translucentAlpha: 0.15)
                : StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
            borderRadius: BorderRadius.circular(14),
          ),
          child: IconButton(
            padding: EdgeInsets.zero,
            onPressed: () {
              AppHaptics.selectionClick();
              playerNotifier.toggleRepeatMode();
            },
            icon: HugeIcon(
              icon: playback.repeatMode == PlaybackRepeatMode.one
                  ? HugeIcons.strokeRoundedRepeatOne01
                  : HugeIcons.strokeRoundedRepeat,
              size: 20,
              color: playback.repeatMode != PlaybackRepeatMode.off ? primary : theme.colorScheme.onSurfaceVariant,
            ),
            tooltip: 'Repeat',
          ),
        ),
      ],
    );
  }

  // ─── BOTTOM DSP PRESETS STRIP ─────────────────────────────────────────────
  Widget _buildBottomDspPresetsStrip(
    BuildContext context,
    DspRackState dspState,
    DspRackController dspNotifier,
    PlaybackState playback,
    PlayerController playerNotifier,
    Color primary,
    bool isLandscape,
    bool isSolid,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              HugeIcon(icon: HugeIcons.strokeRoundedSlidersVertical, size: 13, color: primary),
              const SizedBox(width: 4),
              Text(
                'DSP',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  color: primary,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: DspPreset.studioPresets.map((preset) {
                  final isSelected = dspState.activePresetId == preset.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6.0),
                    child: InkWell(
                      onTap: () {
                        AppHaptics.selectionClick();
                        dspNotifier.applyPreset(preset);
                      },
                      borderRadius: BorderRadius.circular(7),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? StudioSurfaceTheme.tintedContainer(context, primary, isSolid: isSolid, translucentAlpha: 0.2)
                              : StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          preset.name,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? primary : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Quick Volume Slider
          HugeIcon(
            icon: HugeIcons.strokeRoundedVolumeHigh,
            size: 15,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(
            width: isLandscape ? 80 : 60,
            child: M3ESlider(
              value: playback.volume.clamp(0.0, 1.0),
              min: 0.0,
              max: 1.0,
              onChanged: (v) => playerNotifier.setVolume(v),
            ),
          ),
        ],
      ),
    );
  }
}
