import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
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

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('PLAYBACK ENGINE & INTERRUPTION'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          // ─── 1. STATUS HERO BANNER ──────────────────────────────────────
          _buildStatusHero(context, theme, primary, settings),
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
          _buildVolumeFadeCard(context, theme, primary, settings, notifier),
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
          _buildInterruptionPolicyCard(context, theme, primary, settings, notifier),
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
          _buildSpeedPitchCard(context, theme, primary, settings, notifier),
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
          _buildReplayGainCard(context, theme, primary, settings, notifier),
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
          _buildSeekStepperCard(context, theme, primary, settings, notifier),
          const SizedBox(height: 24),

          // ─── 7. RESET TO DEFAULTS ───────────────────────────────────────
          OutlinedButton.icon(
            onPressed: () {
              HapticFeedback.mediumImpact();
              _showResetConfirmation(context, notifier);
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
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(
                color: theme.colorScheme.error.withValues(alpha: 0.4),
                width: 1.0,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
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
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.4),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primary.withValues(alpha: 0.12),
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
                theme,
                label: settings.enableSmoothFade
                    ? 'Fade: ${settings.fadeInDurationMs}ms / ${settings.fadeOutDurationMs}ms'
                    : 'Fade: Instant',
                isActive: settings.enableSmoothFade,
                color: primary,
              ),
              _buildStatusPill(
                theme,
                label: settings.pauseOnHeadphoneUnplug ? 'Unplug Guard: ON' : 'Unplug Guard: OFF',
                isActive: settings.pauseOnHeadphoneUnplug,
                color: theme.colorScheme.secondary,
              ),
              _buildStatusPill(
                theme,
                label: 'ReplayGain: ${settings.replayGainMode.label}',
                isActive: settings.replayGainMode != ReplayGainMode.off,
                color: theme.colorScheme.tertiary,
              ),
              _buildStatusPill(
                theme,
                label: 'Speed: ${settings.playbackSpeed.toStringAsFixed(2)}x',
                isActive: settings.playbackSpeed != 1.0,
                color: primary,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(
    ThemeData theme, {
    required String label,
    required bool isActive,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: isActive
            ? color.withValues(alpha: 0.12)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive
              ? color.withValues(alpha: 0.4)
              : theme.dividerColor.withValues(alpha: 0.3),
          width: 0.8,
        ),
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
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.4),
          width: 1.0,
        ),
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
              Switch(
                value: settings.enableSmoothFade,
                activeThumbColor: primary,
                onChanged: (val) {
                  HapticFeedback.lightImpact();
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
            Slider(
              value: settings.fadeInDurationMs.toDouble().clamp(100.0, 1500.0),
              min: 100.0,
              max: 1500.0,
              divisions: 28,
              activeColor: primary,
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
            Slider(
              value: settings.fadeOutDurationMs.toDouble().clamp(100.0, 1500.0),
              min: 100.0,
              max: 1500.0,
              divisions: 28,
              activeColor: primary,
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
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.4),
          width: 1.0,
        ),
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
              Switch(
                value: settings.pauseOnHeadphoneUnplug,
                activeThumbColor: primary,
                onChanged: (val) {
                  HapticFeedback.lightImpact();
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
              Switch(
                value: settings.resumeOnHeadphonePlug,
                activeThumbColor: primary,
                onChanged: (val) {
                  HapticFeedback.lightImpact();
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
            Slider(
              value: settings.headphoneReconnectTimeoutSec.toDouble().clamp(3.0, 60.0),
              min: 3.0,
              max: 60.0,
              divisions: 19,
              activeColor: primary,
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
              Switch(
                value: settings.pauseOnZeroVolume,
                activeThumbColor: primary,
                onChanged: (val) {
                  HapticFeedback.lightImpact();
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
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.4),
          width: 1.0,
        ),
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
          Slider(
            value: settings.playbackSpeed.clamp(0.25, 3.0),
            min: 0.25,
            max: 3.0,
            divisions: 55,
            activeColor: primary,
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
          Slider(
            value: settings.pitchSemitones.clamp(-12.0, 12.0),
            min: -12.0,
            max: 12.0,
            divisions: 48,
            activeColor: theme.colorScheme.secondary,
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
              Switch(
                value: settings.linkSpeedAndPitch,
                activeThumbColor: primary,
                onChanged: (val) {
                  HapticFeedback.lightImpact();
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
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.4),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ReplayGain Loudness Mode',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<ReplayGainMode>(
            segments: const [
              ButtonSegment(value: ReplayGainMode.off, label: Text('Off')),
              ButtonSegment(value: ReplayGainMode.track, label: Text('Track')),
              ButtonSegment(value: ReplayGainMode.album, label: Text('Album')),
            ],
            selected: {settings.replayGainMode},
            onSelectionChanged: (val) {
              HapticFeedback.selectionClick();
              notifier.setReplayGainMode(val.first);
            },
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
              Text(
                '${settings.replayGainPreampDb >= 0 ? '+' : ''}${settings.replayGainPreampDb.toStringAsFixed(1)} dB',
                style: TextStyle(
                  fontFeatures: AppTypography.audioFigures,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: primary,
                ),
              ),
            ],
          ),
          Slider(
            value: settings.replayGainPreampDb.clamp(-12.0, 12.0),
            min: -12.0,
            max: 12.0,
            divisions: 48,
            activeColor: primary,
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
              Switch(
                value: settings.replayGainPreventClipping,
                activeThumbColor: primary,
                onChanged: (val) {
                  HapticFeedback.lightImpact();
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
              Switch(
                value: settings.enableSkipSilence,
                activeThumbColor: primary,
                onChanged: (val) {
                  HapticFeedback.lightImpact();
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
                Text(
                  '${settings.silenceThresholdDb.toStringAsFixed(0)} dBFS',
                  style: TextStyle(
                    fontFeatures: AppTypography.audioFigures,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: primary,
                  ),
                ),
              ],
            ),
            Slider(
              value: settings.silenceThresholdDb.clamp(-70.0, -40.0),
              min: -70.0,
              max: -40.0,
              divisions: 30,
              activeColor: primary,
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
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.4),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seek Stepper Mode',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<SeekStepMode>(
            segments: const [
              ButtonSegment(
                value: SeekStepMode.constantSeconds,
                label: Text('Fixed Seconds'),
              ),
              ButtonSegment(
                value: SeekStepMode.percentage,
                label: Text('Percentage'),
              ),
            ],
            selected: {settings.seekStepMode},
            onSelectionChanged: (val) {
              HapticFeedback.selectionClick();
              notifier.setSeekStepMode(val.first);
            },
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
                Text(
                  '${settings.seekStepSeconds} seconds',
                  style: TextStyle(
                    fontFeatures: AppTypography.audioFigures,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: primary,
                  ),
                ),
              ],
            ),
            Slider(
              value: settings.seekStepSeconds.toDouble().clamp(5.0, 60.0),
              min: 5.0,
              max: 60.0,
              divisions: 11,
              activeColor: primary,
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
                Text(
                  '${(settings.seekStepPercent * 100).toStringAsFixed(0)} %',
                  style: TextStyle(
                    fontFeatures: AppTypography.audioFigures,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: primary,
                  ),
                ),
              ],
            ),
            Slider(
              value: settings.seekStepPercent.clamp(0.01, 0.20),
              min: 0.01,
              max: 0.20,
              divisions: 19,
              activeColor: primary,
              onChanged: (val) => notifier.setSeekStepPercent(val),
            ),
          ],

          const Divider(height: 20),

          // Time Display Mode Toggle
          Text(
            'Default Time Bar Display Mode',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          SegmentedButton<TimeDisplayMode>(
            segments: const [
              ButtonSegment(
                value: TimeDisplayMode.remaining,
                label: Text('Remaining (-mm:ss)'),
              ),
              ButtonSegment(
                value: TimeDisplayMode.total,
                label: Text('Total (mm:ss)'),
              ),
            ],
            selected: {settings.timeDisplayMode},
            onSelectionChanged: (val) {
              HapticFeedback.selectionClick();
              notifier.setTimeDisplayMode(val.first);
            },
          ),
        ],
      ),
    );
  }

  void _showResetConfirmation(BuildContext context, PlaybackSettingsController notifier) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Reset Playback Engine'),
        content: const Text(
          'Are you sure you want to reset all playback transitions, interruption policies, ReplayGain settings, and speed/pitch parameters to factory studio defaults?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('CANCEL'),
          ),
          FilledButton(
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
            child: const Text('RESET ALL'),
          ),
        ],
      ),
    );
  }
}
