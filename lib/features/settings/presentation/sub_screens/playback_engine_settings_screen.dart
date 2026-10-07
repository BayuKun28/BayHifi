import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/player_playback_settings.dart';
import '../controllers/playback_settings_controller.dart';

/// Studio Settings Sub-Screen: Advanced Playback Engine & Interruption Policies (Fase 16)
class PlaybackEngineSettingsScreen extends ConsumerWidget {
  const PlaybackEngineSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final settings = ref.watch(playbackSettingsProvider);
    final notifier = ref.read(playbackSettingsProvider.notifier);
    final isSolid = ref.isSolidStyle;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('PLAYBACK ENGINE & INTERRUPTION'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          // ─── 1. STATUS HERO BANNER ──────────────────────────────────────
          _buildStatusHero(context, theme, primary, settings, isSolid),
          const SizedBox(height: 18),

          // ─── 2. SMOOTH PLAY / PAUSE VOLUME FADE ────────────────────────
          _buildCardHeader(
            theme,
            icon: HugeIcons.strokeRoundedVolumeHigh,
            color: primary,
            title: 'SMOOTH VOLUME FADE TRANSITIONS',
            subtitle: 'Prevents sudden audio clicks or volume snaps on play & pause',
          ),
          const SizedBox(height: 8),
          _buildVolumeFadeCard(context, theme, primary, settings, notifier, isSolid),
          const SizedBox(height: 20),

          // ─── 3. AUDIO DEVICE INTERRUPTION & HEADPHONE POLICIES ──────────
          _buildCardHeader(
            theme,
            icon: HugeIcons.strokeRoundedHeadphones,
            color: theme.colorScheme.secondary,
            title: 'AUDIO DEVICE INTERRUPTION POLICIES',
            subtitle: 'Auto-pause and intelligent auto-resume for DACs, earphones & Bluetooth',
          ),
          const SizedBox(height: 8),
          _buildInterruptionPolicyCard(context, theme, primary, settings, notifier, isSolid),
          const SizedBox(height: 20),

          // ─── 4. SPEED & PITCH SEMITONE ENGINE ───────────────────────────
          _buildCardHeader(
            theme,
            icon: HugeIcons.strokeRoundedDashboardSpeed01,
            color: theme.colorScheme.tertiary,
            title: 'SPEED & PITCH SEMITONE ENGINE',
            subtitle: 'Granular time-stretch and semitone tuning with lock linkage',
          ),
          const SizedBox(height: 8),
          _buildSpeedPitchCard(context, theme, primary, settings, notifier, isSolid),
          const SizedBox(height: 20),

          // ─── 5. REPLAYGAIN NORMALIZATION & SKIP SILENCE ─────────────────
          _buildCardHeader(
            theme,
            icon: HugeIcons.strokeRoundedSlidersHorizontal,
            color: primary,
            title: 'REPLAYGAIN & SILENCE MANAGEMENT',
            subtitle: 'Loudness normalization standard (-18 LUFS) & silent intro trimming',
          ),
          const SizedBox(height: 8),
          _buildReplayGainCard(context, theme, primary, settings, notifier, isSolid),
          const SizedBox(height: 20),

          // ─── 6. CUSTOM SEEK STEPPER & TIME DISPLAY MODES ────────────────
          _buildCardHeader(
            theme,
            icon: HugeIcons.strokeRoundedHourglass,
            color: theme.colorScheme.secondary,
            title: 'SEEK STEPPER & TIME DISPLAY MODES',
            subtitle: 'Configure fast forward/rewind jump step and countdown format',
          ),
          const SizedBox(height: 8),
          _buildSeekStepperCard(context, theme, primary, settings, notifier, isSolid),
          const SizedBox(height: 24),

          // ─── 7. RESET TO DEFAULTS ───────────────────────────────────────
          M3EButton.outlined(
            onPressed: () {
              AppHaptics.mediumImpact();
              _showResetConfirmation(context, notifier, isSolid);
            },
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedRotateLeft01,
              size: 16,
              color: theme.colorScheme.error,
            ),
            label: Text(
              'RESET PLAYBACK ENGINE TO DEFAULTS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: theme.colorScheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── STATUS HERO BANNER ───────────────────────────────────────────────────
  Widget _buildStatusHero(
    BuildContext context,
    ThemeData theme,
    Color primary,
    PlayerPlaybackSettings settings,
    bool isSolid,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: StudioSurfaceTheme.cardDecoration(
        context: context,
        isSolid: isSolid,
        radius: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: StudioSurfaceTheme.tintedContainer(
                    context,
                    primary,
                    isSolid: isSolid,
                    translucentAlpha: 0.12,
                    solidBlendAlpha: 0.16,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedActivity01,
                  size: 18,
                  color: primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'STUDIO PLAYBACK POLICIES',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Bit-perfect transitions, device watchers & loudness calibration',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusPill(
                context,
                theme,
                label: settings.enableSmoothFade
                    ? 'Fade: ${settings.fadeInDurationMs}ms / ${settings.fadeOutDurationMs}ms'
                    : 'Fade: Instant',
                isActive: settings.enableSmoothFade,
                color: primary,
                isSolid: isSolid,
              ),
              _buildStatusPill(
                context,
                theme,
                label: settings.pauseOnHeadphoneUnplug ? 'Unplug Guard: ON' : 'Unplug Guard: OFF',
                isActive: settings.pauseOnHeadphoneUnplug,
                color: theme.colorScheme.secondary,
                isSolid: isSolid,
              ),
              _buildStatusPill(
                context,
                theme,
                label: 'ReplayGain: ${settings.replayGainMode.label}',
                isActive: settings.replayGainMode != ReplayGainMode.off,
                color: theme.colorScheme.tertiary,
                isSolid: isSolid,
              ),
              _buildStatusPill(
                context,
                theme,
                label: 'Speed: ${settings.playbackSpeed.toStringAsFixed(2)}x',
                isActive: settings.playbackSpeed != 1.0,
                color: primary,
                isSolid: isSolid,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(
    BuildContext context,
    ThemeData theme, {
    required String label,
    required bool isActive,
    required Color color,
    required bool isSolid,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: isActive
            ? StudioSurfaceTheme.tintedContainer(
                context,
                color,
                isSolid: isSolid,
                translucentAlpha: 0.12,
                solidBlendAlpha: 0.16,
              )
            : StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid, translucentAlpha: 0.4),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFeatures: AppTypography.audioFigures,
          fontSize: 10,
          fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
          color: isActive ? color : theme.colorScheme.onSurface.withValues(alpha: 0.6),
        ),
      ),
    );
  }

  // ─── CARD HEADER HELPER ───────────────────────────────────────────────────
  Widget _buildCardHeader(
    ThemeData theme, {
    required dynamic icon,
    required Color color,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        HugeIcon(icon: icon, size: 15, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: theme.colorScheme.onSurface,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                  fontSize: 9.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─── 2. SMOOTH VOLUME FADE CARD ───────────────────────────────────────────
  Widget _buildVolumeFadeCard(
    BuildContext context,
    ThemeData theme,
    Color primary,
    PlayerPlaybackSettings settings,
    PlaybackSettingsController notifier,
    bool isSolid,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: StudioSurfaceTheme.cardDecoration(
        context: context,
        isSolid: isSolid,
        radius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Smooth Volume Fade',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  Text(
                    'Applies gradual ramp on Play and Pause',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                    ),
                  ),
                ],
              ),
              M3ESwitch(
                value: settings.enableSmoothFade,
                onChanged: (val) {
                  AppHaptics.lightImpact();
                  notifier.toggleSmoothFade(val);
                },
              ),
            ],
          ),
          if (settings.enableSmoothFade) ...[
            const Divider(height: 20),
            // Fade In Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fade-In on Play',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  '${settings.fadeInDurationMs} ms',
                  style: TextStyle(
                    fontFeatures: AppTypography.audioFigures,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            M3ESlider(
              value: settings.fadeInDurationMs.toDouble().clamp(100.0, 1500.0),
              min: 100.0,
              max: 1500.0,
              divisions: 28,
              onChanged: (val) {
                notifier.setFadeInDurationMs(val.toInt());
              },
            ),

            // Fade Out Slider
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Fade-Out on Pause',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  '${settings.fadeOutDurationMs} ms',
                  style: TextStyle(
                    fontFeatures: AppTypography.audioFigures,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            M3ESlider(
              value: settings.fadeOutDurationMs.toDouble().clamp(100.0, 1500.0),
              min: 100.0,
              max: 1500.0,
              divisions: 28,
              onChanged: (val) {
                notifier.setFadeOutDurationMs(val.toInt());
              },
            ),
          ],
        ],
      ),
    );
  }

  // ─── 3. INTERRUPTION POLICIES CARD ────────────────────────────────────────
  Widget _buildInterruptionPolicyCard(
    BuildContext context,
    ThemeData theme,
    Color primary,
    PlayerPlaybackSettings settings,
    PlaybackSettingsController notifier,
    bool isSolid,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: StudioSurfaceTheme.cardDecoration(
        context: context,
        isSolid: isSolid,
        radius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Auto-pause on unplug
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auto-Pause on Headphone Disconnect',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Pauses instantly when wired headphones, USB DAC, or Bluetooth disconnects',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              M3ESwitch(
                value: settings.pauseOnHeadphoneUnplug,
                onChanged: (val) {
                  AppHaptics.lightImpact();
                  notifier.togglePauseOnHeadphoneUnplug(val);
                },
              ),
            ],
          ),
          const Divider(height: 20),

          // Auto-resume on reconnect
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auto-Resume on Reconnect',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Resumes audio if earphones/DAC reconnect within timeout limit',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              M3ESwitch(
                value: settings.resumeOnHeadphonePlug,
                onChanged: (val) {
                  AppHaptics.lightImpact();
                  notifier.toggleResumeOnHeadphonePlug(val);
                },
              ),
            ],
          ),

          if (settings.resumeOnHeadphonePlug) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reconnect Timeout Limit',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  '${settings.headphoneReconnectTimeoutSec} seconds',
                  style: TextStyle(
                    fontFeatures: AppTypography.audioFigures,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            M3ESlider(
              value: settings.headphoneReconnectTimeoutSec.toDouble().clamp(3.0, 60.0),
              min: 3.0,
              max: 60.0,
              divisions: 19,
              onChanged: (val) {
                notifier.setHeadphoneReconnectTimeoutSec(val.toInt());
              },
            ),
          ],

          const Divider(height: 20),

          // Auto-pause on zero volume
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Auto-Pause on Zero Device Volume',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Suspends playback when media volume reaches zero to save CPU & battery',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              M3ESwitch(
                value: settings.pauseOnZeroVolume,
                onChanged: (val) {
                  AppHaptics.lightImpact();
                  notifier.togglePauseOnZeroVolume(val);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 4. SPEED & PITCH CARD ────────────────────────────────────────────────
  Widget _buildSpeedPitchCard(
    BuildContext context,
    ThemeData theme,
    Color primary,
    PlayerPlaybackSettings settings,
    PlaybackSettingsController notifier,
    bool isSolid,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: StudioSurfaceTheme.cardDecoration(
        context: context,
        isSolid: isSolid,
        radius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Default Playback Speed',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                '${settings.playbackSpeed.toStringAsFixed(2)}x',
                style: TextStyle(
                  fontFeatures: AppTypography.audioFigures,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          M3ESlider(
            value: settings.playbackSpeed.clamp(0.25, 3.0),
            min: 0.25,
            max: 3.0,
            divisions: 55,
            onChanged: (val) => notifier.setPlaybackSpeed(val),
          ),
          const SizedBox(height: 6),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pitch Shift Semitones',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                '${settings.pitchSemitones >= 0 ? '+' : ''}${settings.pitchSemitones.toStringAsFixed(1)} st',
                style: TextStyle(
                  fontFeatures: AppTypography.audioFigures,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          M3ESlider(
            value: settings.pitchSemitones.clamp(-12.0, 12.0),
            min: -12.0,
            max: 12.0,
            divisions: 48,
            onChanged: (val) => notifier.setPitchSemitones(val),
          ),

          const Divider(height: 16),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Link Speed & Pitch',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      settings.linkSpeedAndPitch
                          ? 'Pitch shifts synchronously with speed (Analog tape/turntable)'
                          : 'Independent pitch preserving high-quality time-stretch',
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              M3ESwitch(
                value: settings.linkSpeedAndPitch,
                onChanged: (val) {
                  AppHaptics.lightImpact();
                  notifier.toggleLinkSpeedAndPitch(val);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── 5. REPLAYGAIN & SILENCE CARD ─────────────────────────────────────────
  Widget _buildReplayGainCard(
    BuildContext context,
    ThemeData theme,
    Color primary,
    PlayerPlaybackSettings settings,
    PlaybackSettingsController notifier,
    bool isSolid,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: StudioSurfaceTheme.cardDecoration(
        context: context,
        isSolid: isSolid,
        radius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBentoDropdownSelector<ReplayGainMode>(
            context: context,
            title: 'REPLAYGAIN LOUDNESS NORMALIZATION',
            currentValue: settings.replayGainMode,
            items: ReplayGainMode.values,
            itemLabel: (m) => m.label,
            itemDescription: (m) => m.description,
            itemIcon: (m) {
              switch (m) {
                case ReplayGainMode.off:
                  return HugeIcons.strokeRoundedCancel01;
                case ReplayGainMode.track:
                  return HugeIcons.strokeRoundedMusicNote01;
                case ReplayGainMode.album:
                  return HugeIcons.strokeRoundedDisc;
              }
            },
            onChanged: (val) {
              if (val != null) {
                AppHaptics.selectionClick();
                notifier.setReplayGainMode(val);
              }
            },
            isSolid: isSolid,
          ),
          const SizedBox(height: 14),

          // ReplayGain Preamp Slider
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ReplayGain Preamp',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: isSolid
                      ? theme.colorScheme.surfaceContainerHighest
                      : StudioSurfaceTheme.tintedContainer(context, primary, isSolid: false, translucentAlpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${settings.replayGainPreampDb >= 0 ? '+' : ''}${settings.replayGainPreampDb.toStringAsFixed(1)} dB',
                  style: TextStyle(
                    fontFeatures: AppTypography.audioFigures,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          M3ESlider(
            value: settings.replayGainPreampDb.clamp(-12.0, 12.0),
            min: -12.0,
            max: 12.0,
            divisions: 48,
            onChanged: (val) => notifier.setReplayGainPreampDb(val),
          ),

          // Prevent clipping switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Prevent Digital Clipping',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Attenuates gain if track peak would exceed 0 dBFS',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              M3ESwitch(
                value: settings.replayGainPreventClipping,
                onChanged: (val) {
                  AppHaptics.lightImpact();
                  notifier.toggleReplayGainPreventClipping(val);
                },
              ),
            ],
          ),

          const Divider(height: 20),

          // Skip silence switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Skip Silence Engine',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Fast-forwards past leading silent intro periods',
                      style: TextStyle(
                        fontSize: 9.5,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
              M3ESwitch(
                value: settings.enableSkipSilence,
                onChanged: (val) {
                  AppHaptics.lightImpact();
                  notifier.toggleEnableSkipSilence(val);
                },
              ),
            ],
          ),

          if (settings.enableSkipSilence) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Silence Threshold',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSolid
                        ? theme.colorScheme.surfaceContainerHighest
                        : StudioSurfaceTheme.tintedContainer(context, primary, isSolid: false, translucentAlpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${settings.silenceThresholdDb.toStringAsFixed(0)} dBFS',
                    style: TextStyle(
                      fontFeatures: AppTypography.audioFigures,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            M3ESlider(
              value: settings.silenceThresholdDb.clamp(-70.0, -40.0),
              min: -70.0,
              max: -40.0,
              divisions: 30,
              onChanged: (val) => notifier.setSilenceThresholdDb(val),
            ),
          ],
        ],
      ),
    );
  }

  // ─── 6. CUSTOM SEEK STEPPER CARD ──────────────────────────────────────────
  Widget _buildSeekStepperCard(
    BuildContext context,
    ThemeData theme,
    Color primary,
    PlayerPlaybackSettings settings,
    PlaybackSettingsController notifier,
    bool isSolid,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: StudioSurfaceTheme.cardDecoration(
        context: context,
        isSolid: isSolid,
        radius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBentoDropdownSelector<SeekStepMode>(
            context: context,
            title: 'SEEK STEPPER JUMP MODE',
            currentValue: settings.seekStepMode,
            items: SeekStepMode.values,
            itemLabel: (s) => s.label,
            itemDescription: (s) => s.description,
            itemIcon: (s) {
              switch (s) {
                case SeekStepMode.constantSeconds:
                  return HugeIcons.strokeRoundedHourglass;
                case SeekStepMode.percentage:
                  return HugeIcons.strokeRoundedPieChart;
              }
            },
            onChanged: (val) {
              if (val != null) {
                AppHaptics.selectionClick();
                notifier.setSeekStepMode(val);
              }
            },
            isSolid: isSolid,
          ),
          const SizedBox(height: 14),

          if (settings.seekStepMode == SeekStepMode.constantSeconds) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Seek Step Duration',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSolid
                        ? theme.colorScheme.surfaceContainerHighest
                        : StudioSurfaceTheme.tintedContainer(context, primary, isSolid: false, translucentAlpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${settings.seekStepSeconds} s',
                    style: TextStyle(
                      fontFeatures: AppTypography.audioFigures,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            M3ESlider(
              value: settings.seekStepSeconds.toDouble().clamp(5.0, 60.0),
              min: 5.0,
              max: 60.0,
              divisions: 11,
              onChanged: (val) => notifier.setSeekStepSeconds(val.toInt()),
            ),
          ] else ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Seek Step Percentage',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSolid
                        ? theme.colorScheme.surfaceContainerHighest
                        : StudioSurfaceTheme.tintedContainer(context, primary, isSolid: false, translucentAlpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${(settings.seekStepPercent * 100).toStringAsFixed(0)} %',
                    style: TextStyle(
                      fontFeatures: AppTypography.audioFigures,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            M3ESlider(
              value: settings.seekStepPercent.clamp(0.01, 0.20),
              min: 0.01,
              max: 0.20,
              divisions: 19,
              onChanged: (val) => notifier.setSeekStepPercent(val),
            ),
          ],

          const Divider(height: 20),

          // Time Display Mode Bento ComboBox
          _buildBentoDropdownSelector<TimeDisplayMode>(
            context: context,
            title: 'TIME BAR DISPLAY MODE',
            currentValue: settings.timeDisplayMode,
            items: TimeDisplayMode.values,
            itemLabel: (t) => t.label,
            itemDescription: (t) => t.description,
            itemIcon: (t) {
              switch (t) {
                case TimeDisplayMode.remaining:
                  return HugeIcons.strokeRoundedHourglass;
                case TimeDisplayMode.total:
                  return HugeIcons.strokeRoundedClock01;
              }
            },
            onChanged: (val) {
              if (val != null) {
                AppHaptics.selectionClick();
                notifier.setTimeDisplayMode(val);
              }
            },
            isSolid: isSolid,
          ),
        ],
      ),
    );
  }

  // ─── REUSABLE BENTO DROPDOWN SELECTOR HELPER ─────────────────────────────
  Widget _buildBentoDropdownSelector<T>({
    required BuildContext context,
    required String title,
    required T currentValue,
    required List<T> items,
    required String Function(T) itemLabel,
    required String Function(T) itemDescription,
    required dynamic Function(T) itemIcon,
    required ValueChanged<T?> onChanged,
    required bool isSolid,
  }) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isSolid
            ? theme.colorScheme.surfaceContainerHighest
            : StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: false),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: theme.colorScheme.onSurfaceVariant,
              fontSize: 9.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: currentValue,
              isExpanded: true,
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedArrowDown01,
                size: 15,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              dropdownColor: isSolid
                  ? theme.colorScheme.surfaceContainerHigh
                  : theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(12),
              items: items.map((item) {
                final isSelected = item == currentValue;
                return DropdownMenuItem<T>(
                  value: item,
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: itemIcon(item),
                        size: 16,
                        color: isSelected ? primary : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          itemLabel(item),
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? primary : theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            itemDescription(currentValue),
            style: TextStyle(
              fontSize: 10,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation(BuildContext context, PlaybackSettingsController notifier, bool isSolid) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: StudioSurfaceTheme.surface(dialogCtx, isSolid: isSolid),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: StudioSurfaceTheme.outline(dialogCtx, isSolid: isSolid)),
        ),
        title: const Text('Reset Playback Engine'),
        content: const Text(
          'Are you sure you want to reset all playback transitions, interruption policies, ReplayGain settings, and speed/pitch parameters to factory studio defaults?',
        ),
        actions: [
          M3EButton.text(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('CANCEL'),
          ),
          M3EButton.filled(
            onPressed: () {
              notifier.resetToDefaults();
              Navigator.of(dialogCtx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Playback engine reset to studio defaults'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            label: const Text('RESET ALL'),
          ),
        ],
      ),
    );
  }
}
