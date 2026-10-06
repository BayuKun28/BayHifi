import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../dsp_rack/presentation/controllers/dsp_rack_controller.dart';
import '../../../dsp_rack/presentation/dsp_rack_screen.dart';
import '../../../hardware_dac/presentation/controllers/dac_bridge_controller.dart';
import '../../../hardware_dac/presentation/screens/hardware_dac_studio_screen.dart';
import '../../../pro_q_studio/presentation/controllers/eq_controller.dart';
import '../../../pro_q_studio/presentation/widgets/auto_eq_modal_dialog.dart';

/// Unified Studio Audio Signal Flow Chain Capsule for NowPlayingScreen.
/// Displays an interconnected, 3-stage tactile pipeline:
/// [ 🎧 AutoEQ ] ➔ [ 🎛️ DSP Rack ] ➔ [ ⚡ Hardware DAC ]
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
    final colorScheme = theme.colorScheme;
    final isSolid = ref.isSolidStyle;

    final eqState = ref.watch(eqControllerProvider);
    final dspState = ref.watch(dspRackControllerProvider);
    final dacState = ref.watch(dacBridgeControllerProvider);

    // 1. AutoEQ State
    final rawDriver = _decodeClean(eqState.driverFr?.name);
    final driverName = rawDriver.isNotEmpty ? rawDriver : 'Direct';
    final rawTarget = _decodeClean(eqState.targetFr?.name);
    final targetName = rawTarget.isNotEmpty ? rawTarget : 'Harman 2019';
    final isAutoActive = eqState.isAutoEqActive;

    // 2. DSP Rack State
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

    // 3. Hardware DAC State
    final isDacConnected = dacState.isConnected && dacState.device != null;
    final dacName = isDacConnected
        ? (dacState.device?.productName.replaceAll('Kiwi Ears', '').trim() ?? 'DAC')
        : 'Direct';
    const mintColor = Color(0xFF10B981);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ─── STAGE 1: AutoEQ Profile ──────────────────────────────
            Tooltip(
              message: 'Stage 1: AutoEQ Target Curve ($driverName • $targetName)',
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isAutoActive
                          ? StudioCategoryColors.autoEq.withValues(alpha: isSolid ? 0.18 : 0.14)
                          : StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid, translucentAlpha: 0.35),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isAutoActive
                            ? StudioCategoryColors.autoEq.withValues(alpha: 0.4)
                            : colorScheme.outlineVariant.withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const HugeIcon(
                          icon: HugeIcons.strokeRoundedHeadphones,
                          size: 12,
                          color: StudioCategoryColors.autoEq,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isAutoActive ? 'AutoEQ • $driverName' : 'AutoEQ',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: isAutoActive
                                ? StudioCategoryColors.autoEq
                                : colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ─── CONNECTOR 1 ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                size: 11,
                color: colorScheme.outline.withValues(alpha: 0.6),
              ),
            ),

            // ─── STAGE 2: Mastering DSP Rack ──────────────────────────
            Tooltip(
              message: 'Stage 2: Mastering DSP Rack (${activeDspCount > 0 ? '$activeDspCount Units Active' : 'Flat'})',
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
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDspActive
                          ? StudioCategoryColors.dspMastering.withValues(alpha: isSolid ? 0.18 : 0.14)
                          : StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid, translucentAlpha: 0.35),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDspActive
                            ? StudioCategoryColors.dspMastering.withValues(alpha: 0.4)
                            : colorScheme.outlineVariant.withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedSlidersVertical,
                          size: 12,
                          color: isDspActive ? StudioCategoryColors.dspMastering : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isDspActive ? 'DSP ($activeDspCount)' : 'DSP Rack',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                            color: isDspActive
                                ? StudioCategoryColors.dspMastering
                                : colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ─── CONNECTOR 2 ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4.0),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedArrowRight01,
                size: 11,
                color: colorScheme.outline.withValues(alpha: 0.6),
              ),
            ),

            // ─── STAGE 3: Hardware DAC Bridge ─────────────────────────
            Tooltip(
              message: isDacConnected
                  ? 'Stage 3: Hardware DAC Bridge (${dacState.device?.productName} Connected & Active)'
                  : 'Stage 3: Hardware DAC Bridge (Direct Audio Output)',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    AppHaptics.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const HardwareDacStudioScreen(),
                      ),
                    );
                  },
                  child: Container(
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDacConnected
                          ? mintColor.withValues(alpha: isSolid ? 0.20 : 0.15)
                          : StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid, translucentAlpha: 0.35),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDacConnected
                            ? mintColor.withValues(alpha: 0.5)
                            : colorScheme.outlineVariant.withValues(alpha: 0.3),
                        width: isDacConnected ? 1.0 : 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isDacConnected) ...[
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: mintColor,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ] else ...[
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedUsb,
                            size: 12,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          isDacConnected ? 'DAC • $dacName' : 'DAC Direct',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: isDacConnected ? FontWeight.w800 : FontWeight.w700,
                            color: isDacConnected
                                ? mintColor
                                : colorScheme.onSurface.withValues(alpha: 0.8),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
