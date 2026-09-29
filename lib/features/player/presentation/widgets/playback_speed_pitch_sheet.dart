import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../settings/presentation/controllers/playback_settings_controller.dart';
import '../controllers/player_controller.dart';

/// Modal Bottom Sheet Studio untuk pengaturan Real-Time Playback Speed & Pitch (Fase 16)
class PlaybackSpeedPitchSheet extends ConsumerWidget {
  const PlaybackSpeedPitchSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const PlaybackSpeedPitchSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isSolid = ref.isSolidStyle;
    final playback = ref.watch(playerControllerProvider);
    final settingsNotifier = ref.read(playbackSettingsProvider.notifier);
    final playerNotifier = ref.read(playerControllerProvider.notifier);

    final speed = playback.playbackSpeed;
    final pitch = playback.pitchSemitones;
    final cents = playback.pitchFineCents;
    final isLinked = playback.linkSpeedAndPitch;

    return Container(
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surface(context, isSolid: isSolid),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: StudioSurfaceTheme.outline(context, isSolid: isSolid),
          width: 1.0,
        ),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 38,
              height: 4.5,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                      icon: HugeIcons.strokeRoundedDashboardSpeed01,
                      size: 20,
                      color: primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SPEED & PITCH ENGINE',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'High-precision independent time-stretch & semitones',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedCancel01,
                  size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // ─── PLAYBACK SPEED SECTION ─────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedDashboardSpeed01,
                          size: 16,
                          color: primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'PLAYBACK SPEED',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${speed.toStringAsFixed(2)}x',
                      style: TextStyle(
                        fontFeatures: AppTypography.audioFigures,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: primary,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3.5,
                    activeTrackColor: primary,
                    thumbColor: primary,
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  ),
                  child: Slider(
                    value: speed.clamp(0.25, 3.0),
                    min: 0.25,
                    max: 3.0,
                    divisions: 55,
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      playerNotifier.setPlaybackSpeed(val);
                      settingsNotifier.setPlaybackSpeed(val);
                    },
                  ),
                ),
                // Quick preset chips
                Wrap(
                  spacing: 6,
                  children: [0.75, 1.0, 1.25, 1.5, 2.0].map((s) {
                    final isSel = (speed - s).abs() < 0.01;
                    return InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        playerNotifier.setPlaybackSpeed(s);
                        settingsNotifier.setPlaybackSpeed(s);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isSel
                              ? StudioSurfaceTheme.tintedContainer(context, primary, isSolid: isSolid, translucentAlpha: 0.2)
                              : StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSel
                                ? (isSolid ? theme.colorScheme.outline : primary)
                                : StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          '${s}x',
                          style: TextStyle(
                            fontFeatures: AppTypography.audioFigures,
                            fontSize: 10.5,
                            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                            color: isSel ? primary : theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ─── PITCH SEMITONES SECTION ────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                width: 1.0,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedMusicNote01,
                          size: 16,
                          color: theme.colorScheme.secondary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'PITCH SHIFT',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      '${pitch >= 0 ? '+' : ''}${pitch.toStringAsFixed(1)} st',
                      style: TextStyle(
                        fontFeatures: AppTypography.audioFigures,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3.5,
                    activeTrackColor: theme.colorScheme.secondary,
                    thumbColor: theme.colorScheme.secondary,
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                  ),
                  child: Slider(
                    value: pitch.clamp(-12.0, 12.0),
                    min: -12.0,
                    max: 12.0,
                    divisions: 48, // 0.5 st steps
                    onChanged: (val) {
                      HapticFeedback.selectionClick();
                      playerNotifier.setPitch(val, cents: cents);
                      settingsNotifier.setPitchSemitones(val);
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Fine cents
                    Text(
                      'Fine Tuning: ${cents >= 0 ? '+' : ''}${cents.toStringAsFixed(0)} cents',
                      style: TextStyle(
                        fontFeatures: AppTypography.audioFigures,
                        fontSize: 10.5,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        playerNotifier.setPitch(0.0, cents: 0.0);
                        settingsNotifier.setPitchSemitones(0.0);
                        settingsNotifier.setPitchFineCents(0.0);
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Text(
                          'RESET PITCH',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            color: primary,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ─── LINK SPEED & PITCH SWITCH ──────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isLinked
                    ? (isSolid ? theme.colorScheme.outline : primary.withValues(alpha: 0.5))
                    : StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedLink01,
                      size: 16,
                      color: isLinked ? primary : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'LINK SPEED & PITCH',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          isLinked
                              ? 'Pitch shifts with speed (Tape / Vinyl speed style)'
                              : 'Independent pitch preserving time-stretch',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Switch(
                  value: isLinked,
                  activeThumbColor: primary,
                  onChanged: (val) {
                    HapticFeedback.lightImpact();
                    playerNotifier.toggleLinkSpeedAndPitch();
                    settingsNotifier.toggleLinkSpeedAndPitch(val);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
