import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../settings/presentation/sub_screens/audio_hardware_settings_screen.dart';
import '../../../pro_q_studio/presentation/controllers/eq_controller.dart';
import '../../../player/presentation/controllers/player_controller.dart';

class EngineTelemetryBentoCard extends ConsumerWidget {
  const EngineTelemetryBentoCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isSolid = ref.isSolidStyle;
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
        AppHaptics.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AudioHardwareSettingsScreen()),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: StudioSurfaceTheme.cardDecoration(
          context: context,
          isSolid: isSolid,
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
                          color: StudioCategoryColors.audioEngine.withValues(alpha: isSolid ? 0.18 : 0.14),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          LucideIcons.cpu,
                          size: 16,
                          color: StudioCategoryColors.audioEngine,
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
                    color: StudioCategoryColors.bitPerfect.withValues(alpha: isSolid ? 0.18 : 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: StudioCategoryColors.bitPerfect,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      const Text(
                        'BIT-PERFECT DIRECT',
                        style: TextStyle(
                          color: StudioCategoryColors.bitPerfect,
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
                    isSolid: isSolid,
                    label: 'SOURCE SPEC',
                    value: '$formatStr $bitDepthStr',
                    color: StudioCategoryColors.hiResGold,
                    sub: sampleRateStr,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    context,
                    isSolid: isSolid,
                    label: 'ENGINE BUFFER',
                    value: 'Low-Latency',
                    color: StudioCategoryColors.bitPerfect,
                    sub: 'Direct Stream',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    context,
                    isSolid: isSolid,
                    label: 'HEADROOM',
                    value: preampStr,
                    color: StudioCategoryColors.proQEqualizer,
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
    required bool isSolid,
    required String label,
    required String value,
    required Color color,
    required String sub,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
        borderRadius: BorderRadius.circular(12),
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
