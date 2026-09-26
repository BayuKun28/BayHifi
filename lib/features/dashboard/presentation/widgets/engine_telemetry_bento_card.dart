import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../settings/presentation/sub_screens/audio_hardware_settings_screen.dart';
import '../../../pro_q_studio/presentation/controllers/eq_controller.dart';
import '../../../player/presentation/controllers/player_controller.dart';

class EngineTelemetryBentoCard extends ConsumerWidget {
  const EngineTelemetryBentoCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final eqState = ref.watch(eqControllerProvider);
    final playback = ref.watch(playerControllerProvider);
    final currentTrack = playback.currentTrack;

    final sampleRateStr = currentTrack?.sampleRate != null
        ? '${(currentTrack!.sampleRate! / 1000).toStringAsFixed(1)} kHz'
        : '96.0 kHz';
    final bitDepthStr = currentTrack?.bitDepth != null ? '${currentTrack!.bitDepth}-bit' : '24-bit';
    final formatStr = currentTrack != null ? currentTrack.format.name.toUpperCase() : 'FLAC';
    final preampStr = '${eqState.safePreampDb.toStringAsFixed(1)} dB';

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AudioHardwareSettingsScreen()),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.6),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Header Badge & Bit-Perfect Indicator
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedCpu,
                          size: 16,
                          color: primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'C++ SOLOUD AUDIO ENGINE',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'Direct Hardware Master Stream',
                              style: TextStyle(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                                fontSize: 9.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: primary.withValues(alpha: 0.35),
                      width: 0.8,
                    ),
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
                      const SizedBox(width: 5),
                      Text(
                        'BIT-PERFECT DIRECT',
                        style: TextStyle(
                          color: primary,
                          fontSize: 9,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Metrics Bento Strip
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    context,
                    label: 'SOURCE SPEC',
                    value: '$formatStr $bitDepthStr',
                    color: primary,
                    sub: sampleRateStr,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    context,
                    label: 'ENGINE BUFFER',
                    value: 'Low-Latency',
                    color: theme.colorScheme.secondary,
                    sub: 'Direct Stream',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    context,
                    label: 'HEADROOM',
                    value: preampStr,
                    color: theme.colorScheme.tertiary,
                    sub: 'Safe Pre-Amp',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(
    BuildContext context, {
    required String label,
    required String value,
    required Color color,
    required String sub,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
              fontSize: 8.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(
              fontFeatures: AppTypography.audioFigures,
              color: color,
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),
          Text(
            sub,
            style: TextStyle(
              fontFeatures: AppTypography.audioFigures,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
