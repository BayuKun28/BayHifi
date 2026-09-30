import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../dsp_rack/presentation/controllers/dsp_rack_controller.dart';
import '../../../dsp_rack/presentation/dsp_rack_screen.dart';
import '../../../pro_q_studio/presentation/controllers/eq_controller.dart';
import '../../../pro_q_studio/presentation/widgets/auto_eq_modal_dialog.dart';

/// Ultra-Compact Studio Slim Chips Module for NowPlayingScreen (Option 2).
/// Displays two centered, micro-height (28px) tactile chips:
/// [ 🎧 AutoEQ • Sony IER ]    [ 🎛️ DSP Rack (2) ]
class StudioDspBentoCapsule extends ConsumerWidget {
  const StudioDspBentoCapsule({super.key});

  String _decodeClean(String? s) {
    if (s == null || s.trim().isEmpty) return '';
    try {
      return Uri.decodeComponent(s).replaceAll('_', ' ');
    } catch (_) {
      return s.replaceAll('%20', ' ').replaceAll('_', ' ');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isSolid = ref.isSolidStyle;
    final eqState = ref.watch(eqControllerProvider);
    final dspState = ref.watch(dspRackControllerProvider);

    final rawDriver = _decodeClean(eqState.driverFr?.name);
    final driverName = rawDriver.isNotEmpty ? rawDriver : 'Direct';

    final rawTarget = _decodeClean(eqState.targetFr?.name);
    final targetName = rawTarget.isNotEmpty ? rawTarget : 'Harman 2019';

    final isAutoActive = eqState.isAutoEqActive;

    // Calculate active DSP modules count
    int activeDspCount = 0;
    if (!dspState.isBypassed) {
      if (dspState.tubeExciterEnabled) activeDspCount++;
      if (dspState.bassBoostEnabled) activeDspCount++;
      if (dspState.compressorEnabled) activeDspCount++;
      if (dspState.stereoWidthEnabled) activeDspCount++;
      if (dspState.crossfeedEnabled) activeDspCount++;
      if (dspState.reverbEnabled) activeDspCount++;
      if (dspState.pitchShiftEnabled) activeDspCount++;
      if (dspState.limiterEnabled) activeDspCount++;
    }
    final isDspActive = !dspState.isBypassed && activeDspCount > 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // ─── CHIP 1 (LEFT): AutoEQ Slim Chip ──────────────────────────
        Flexible(
          child: Tooltip(
            message: 'AutoEQ Tuning Profile: $driverName ($targetName)',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  AppHaptics.lightImpact();
                  AutoEqModalDialog.show(context);
                },
                child: Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isAutoActive
                        ? StudioCategoryColors.autoEq.withValues(alpha: isSolid ? 0.18 : 0.15)
                        : StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid, translucentAlpha: 0.35),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedHeadphones,
                        size: 13,
                        color: StudioCategoryColors.autoEq,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          isAutoActive ? 'AutoEQ • $driverName' : 'AutoEQ Profile',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isAutoActive
                                ? StudioCategoryColors.autoEq
                                : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // ─── CHIP 2 (RIGHT): Mastering DSP Rack Slim Chip ─────────────
        Flexible(
          child: Tooltip(
            message:
                'Mastering DSP Rack (${activeDspCount > 0 ? '$activeDspCount Modules Active' : 'Off / Flat'})',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
                onTap: () {
                  AppHaptics.lightImpact();
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const DspRackScreen(),
                    ),
                  );
                },
                child: Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDspActive
                        ? StudioCategoryColors.dspMastering.withValues(alpha: isSolid ? 0.18 : 0.15)
                        : StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid, translucentAlpha: 0.35),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedSlidersVertical,
                        size: 13,
                        color: isDspActive ? StudioCategoryColors.dspMastering : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          isDspActive ? 'DSP Rack ($activeDspCount)' : 'DSP Rack Flat',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isDspActive ? StudioCategoryColors.dspMastering : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

