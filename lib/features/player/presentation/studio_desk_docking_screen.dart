import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../app/theme/app_typography.dart';
import '../../dsp_rack/domain/dsp_models.dart';
import '../../dsp_rack/presentation/controllers/dsp_rack_controller.dart';
import '../../dsp_rack/presentation/widgets/vu_level_meter.dart';
import '../domain/playback_state.dart';
import '../domain/track.dart';
import 'controllers/player_controller.dart';
import 'widgets/audio_file_inspector_sheet.dart';
import 'widgets/spectrum_visualizer.dart';

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
  bool _showVuMeters = true;

  @override
  void initState() {
    super.initState();
    // Keep clock updated every second
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _currentTime = DateTime.now());
      }
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
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

  @override
  Widget build(BuildContext context) {
    final playback = ref.watch(playerControllerProvider);
    final playerNotifier = ref.read(playerControllerProvider.notifier);
    final dspState = ref.watch(dspRackControllerProvider);
    final dspNotifier = ref.read(dspRackControllerProvider.notifier);
    final track = playback.currentTrack;

    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFF07090D),
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
                  _buildStudioTopBar(context, primary, track, isLandscape),
                  const SizedBox(height: 10),

                  // ─── 2. MAIN CENTER BODY (LANDSCAPE OR PORTRAIT) ──────────
                  Expanded(
                    child: isLandscape
                        ? _buildLandscapeBody(context, playback, playerNotifier, dspState, dspNotifier, primary)
                        : _buildPortraitBody(context, playback, playerNotifier, dspState, dspNotifier, primary),
                  ),

                  const SizedBox(height: 8),

                  // ─── 3. BOTTOM GLANCEABLE PRESET & MASTER STRIP ───────────
                  _buildBottomDspPresetsStrip(context, dspState, dspNotifier, playback, playerNotifier, primary, isLandscape),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── STUDIO TOP BAR ───────────────────────────────────────────────────────
  Widget _buildStudioTopBar(BuildContext context, Color primary, Track? track, bool isLandscape) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.6), width: 1.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left: Exit Docking Button
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () {
                  HapticFeedback.mediumImpact();
                  Navigator.of(context).pop();
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.6), width: 0.8),
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
              if (isLandscape && track != null) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: () => AudioFileInspectorSheet.show(context, track),
                  borderRadius: BorderRadius.circular(6),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: primary.withValues(alpha: 0.4), width: 0.8),
                    ),
                    child: Text(
                      '${track.format.name.toUpperCase()} • ${track.sampleRate != null ? (track.sampleRate! / 1000).toStringAsFixed(1) : 44.1}kHz / ${track.bitDepth ?? 16}bit',
                      style: TextStyle(
                        fontFeatures: AppTypography.audioFigures,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: primary,
                      ),
                    ),
                  ),
                ),
              ],
            ],
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
                          fontSize: isLandscape ? 16 : 13.5,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
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
                  style: const TextStyle(
                    fontSize: 8.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7A8B9E),
                    letterSpacing: 0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // Right: Visualizer Mode Toggle & Keep Awake
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() => _showVuMeters = !_showVuMeters);
                },
                borderRadius: BorderRadius.circular(6),
                child: Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161B26),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFF2D3748), width: 0.8),
                  ),
                  child: HugeIcon(
                    icon: _showVuMeters ? HugeIcons.strokeRoundedSlidersVertical : HugeIcons.strokeRoundedAudioWaveform,
                    size: 14,
                    color: primary,
                  ),
                ),
              ),
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFF00E676), width: 0.6),
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
          ),
        ],
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
    Color primary,
  ) {
    final track = playback.currentTrack;

    return Row(
      children: [
        // Left Column: Big Album Art / VU Meter & Track Info
        Expanded(
          flex: 5,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF0C0F16),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF1E2533), width: 1.0),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_showVuMeters) ...[
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('L-CH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primary)),
                              const Text('ANALOG VU MONITOR', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF6B7C93))),
                              Text('R-CH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primary)),
                            ],
                          ),
                          const SizedBox(height: 6),
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
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: Center(
                      child: Container(
                        width: 160,
                        height: 160,
                        decoration: BoxDecoration(
                          color: const Color(0xFF141923),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(
                            color: playback.isPlaying ? primary.withValues(alpha: 0.5) : const Color(0xFF283142),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (playback.isPlaying ? primary : Colors.black).withValues(alpha: 0.3),
                              blurRadius: 30,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Center(
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedAlbum01,
                            size: 64,
                            color: playback.isPlaying ? primary : const Color(0xFF5A6A80),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const SpectrumVisualizer(height: 32),
                ],
                const SizedBox(height: 10),
                Text(
                  track?.title ?? 'No Track Playing',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  track != null ? '${track.artist} • ${track.album}' : 'Select music from library',
                  style: const TextStyle(
                    fontSize: 12.5,
                    color: Color(0xFF8E9EB2),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 14),

        // Right Column: Oversized Seekbar & Massive Playback Controls
        Expanded(
          flex: 6,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: const Color(0xFF0C0F16),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF1E2533), width: 1.0),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Seekbar & Tabular Timestamps
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 5,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                    activeTrackColor: primary,
                    inactiveTrackColor: const Color(0xFF1F2837),
                    thumbColor: primary,
                  ),
                  child: Slider(
                    value: playback.duration.inMilliseconds > 0
                        ? (playback.position.inMilliseconds / playback.duration.inMilliseconds).clamp(0.0, 1.0)
                        : 0.0,
                    onChanged: (val) {
                      final newMs = (val * playback.duration.inMilliseconds).toInt();
                      playerNotifier.seek(Duration(milliseconds: newMs));
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatDuration(playback.position),
                        style: TextStyle(
                          fontFeatures: AppTypography.audioFigures,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: primary,
                        ),
                      ),
                      Text(
                        _formatDuration(playback.duration),
                        style: const TextStyle(
                          fontFeatures: AppTypography.audioFigures,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF7A8B9E),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Giant Glanceable Playback Controls
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Shuffle
                    IconButton(
                      iconSize: 26,
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        playerNotifier.toggleShuffle();
                      },
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedShuffle,
                        size: 24,
                        color: playback.isShuffle ? primary : const Color(0xFF6B7C93),
                      ),
                    ),

                    // Previous Track (Oversized)
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFF141924),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF253042), width: 1.0),
                      ),
                      child: IconButton(
                        iconSize: 30,
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          playerNotifier.skipPrevious();
                        },
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedPrevious,
                          size: 26,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    // Massive Glowing Play/Pause Centerpiece
                    Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primary,
                        boxShadow: [
                          BoxShadow(
                            color: primary.withValues(alpha: 0.5),
                            blurRadius: 24,
                            spreadRadius: 2,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: IconButton(
                        iconSize: 38,
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          playerNotifier.togglePlayPause();
                        },
                        icon: playback.isLoading
                            ? const SizedBox(
                                width: 32,
                                height: 32,
                                child: CircularProgressIndicator(
                                  strokeWidth: 3.2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                ),
                              )
                            : HugeIcon(
                                icon: playback.isPlaying ? HugeIcons.strokeRoundedPause : HugeIcons.strokeRoundedPlay,
                                color: Colors.black,
                                size: 34,
                              ),
                        tooltip: playback.isLoading ? 'Buffering...' : (playback.isPlaying ? 'Pause' : 'Play'),
                      ),
                    ),

                    // Next Track (Oversized)
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFF141924),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFF253042), width: 1.0),
                      ),
                      child: IconButton(
                        iconSize: 30,
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          playerNotifier.skipNext();
                        },
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedNext,
                          size: 26,
                          color: Colors.white,
                        ),
                      ),
                    ),

                    // Repeat
                    IconButton(
                      iconSize: 26,
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        playerNotifier.toggleRepeatMode();
                      },
                      icon: HugeIcon(
                        icon: playback.repeatMode == PlaybackRepeatMode.one
                            ? HugeIcons.strokeRoundedRepeatOne01
                            : HugeIcons.strokeRoundedRepeat,
                        size: 24,
                        color: playback.repeatMode != PlaybackRepeatMode.off ? primary : const Color(0xFF6B7C93),
                      ),
                    ),
                  ],
                ),
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
    Color primary,
  ) {
    final track = playback.currentTrack;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0F16),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E2533), width: 1.0),
      ),
      child: Column(
        children: [
          // Upper Visualizer Area
          Expanded(
            child: _showVuMeters
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('L-CH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primary)),
                            const Text('ANALOG STEREO MONITOR', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF6B7C93))),
                            Text('R-CH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: primary)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        VuLevelMeter(
                          levelDb: playback.isPlaying ? (playback.preAmpDb - 2.5) : -24.0,
                          peakDb: playback.isPlaying ? playback.preAmpDb : -24.0,
                          height: 28,
                        ),
                        const SizedBox(height: 10),
                        VuLevelMeter(
                          levelDb: playback.isPlaying ? (playback.preAmpDb - 3.2) : -24.0,
                          peakDb: playback.isPlaying ? (playback.preAmpDb - 0.5) : -24.0,
                          height: 28,
                        ),
                      ],
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: const Color(0xFF141923),
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(
                            color: playback.isPlaying ? primary.withValues(alpha: 0.5) : const Color(0xFF283142),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: (playback.isPlaying ? primary : Colors.black).withValues(alpha: 0.3),
                              blurRadius: 36,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedAlbum01,
                            size: 72,
                            color: playback.isPlaying ? primary : const Color(0xFF5A6A80),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const SpectrumVisualizer(height: 38),
                    ],
                  ),
          ),

          const SizedBox(height: 12),

          // High Contrast Track Information
          Text(
            track?.title ?? 'No Track Playing',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            track != null ? '${track.artist} • ${track.album}' : 'Tap library to begin playback',
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF8E9EB2),
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),

          // Seekbar & Timestamps
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 5,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              activeTrackColor: primary,
              inactiveTrackColor: const Color(0xFF1F2837),
              thumbColor: primary,
            ),
            child: Slider(
              value: playback.duration.inMilliseconds > 0
                  ? (playback.position.inMilliseconds / playback.duration.inMilliseconds).clamp(0.0, 1.0)
                  : 0.0,
              onChanged: (val) {
                final newMs = (val * playback.duration.inMilliseconds).toInt();
                playerNotifier.seek(Duration(milliseconds: newMs));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(playback.position),
                  style: TextStyle(
                    fontFeatures: AppTypography.audioFigures,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: primary,
                  ),
                ),
                Text(
                  _formatDuration(playback.duration),
                  style: const TextStyle(
                    fontFeatures: AppTypography.audioFigures,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF7A8B9E),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Giant Playback Deck
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  playerNotifier.toggleShuffle();
                },
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedShuffle,
                  size: 22,
                  color: playback.isShuffle ? primary : const Color(0xFF6B7C93),
                ),
              ),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF141924),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF253042), width: 1.0),
                ),
                child: IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    playerNotifier.skipPrevious();
                  },
                  icon: const HugeIcon(icon: HugeIcons.strokeRoundedPrevious, size: 24, color: Colors.white),
                ),
              ),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary,
                  boxShadow: [
                    BoxShadow(
                      color: primary.withValues(alpha: 0.5),
                      blurRadius: 24,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    playerNotifier.togglePlayPause();
                  },
                  icon: playback.isLoading
                      ? const SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            strokeWidth: 3.0,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                          ),
                        )
                      : HugeIcon(
                          icon: playback.isPlaying ? HugeIcons.strokeRoundedPause : HugeIcons.strokeRoundedPlay,
                          color: Colors.black,
                          size: 32,
                        ),
                  tooltip: playback.isLoading ? 'Buffering...' : (playback.isPlaying ? 'Pause' : 'Play'),
                ),
              ),
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: const Color(0xFF141924),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFF253042), width: 1.0),
                ),
                child: IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    playerNotifier.skipNext();
                  },
                  icon: const HugeIcon(icon: HugeIcons.strokeRoundedNext, size: 24, color: Colors.white),
                ),
              ),
              IconButton(
                onPressed: () {
                  HapticFeedback.selectionClick();
                  playerNotifier.toggleRepeatMode();
                },
                icon: HugeIcon(
                  icon: playback.repeatMode == PlaybackRepeatMode.one
                      ? HugeIcons.strokeRoundedRepeatOne01
                      : HugeIcons.strokeRoundedRepeat,
                  size: 22,
                  color: playback.repeatMode != PlaybackRepeatMode.off ? primary : const Color(0xFF6B7C93),
                ),
              ),
            ],
          ),
        ],
      ),
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
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF0F131C),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF222B38), width: 1.0),
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
                        HapticFeedback.selectionClick();
                        dspNotifier.applyPreset(preset);
                      },
                      borderRadius: BorderRadius.circular(7),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected ? primary.withValues(alpha: 0.2) : const Color(0xFF161C26),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(
                            color: isSelected ? primary : const Color(0xFF2A3444),
                            width: isSelected ? 1.0 : 0.7,
                          ),
                        ),
                        child: Text(
                          preset.name,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? primary : const Color(0xFF94A3B8),
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
            color: const Color(0xFF7A8B9E),
          ),
          SizedBox(
            width: isLandscape ? 80 : 60,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 3,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
              ),
              child: Slider(
                value: playback.volume,
                min: 0.0,
                max: 1.0,
                activeColor: primary,
                inactiveColor: const Color(0xFF222B38),
                onChanged: (v) => playerNotifier.setVolume(v),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
