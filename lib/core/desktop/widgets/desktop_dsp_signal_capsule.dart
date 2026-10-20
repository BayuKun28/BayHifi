import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:baydev_hifi/app/theme/app_haptics.dart';
import 'package:baydev_hifi/app/theme/studio_surface_theme.dart';
import 'package:baydev_hifi/features/dsp_rack/presentation/controllers/dsp_rack_controller.dart';
import 'package:baydev_hifi/features/dsp_rack/presentation/dsp_rack_screen.dart';
import 'package:baydev_hifi/features/hardware_dac/presentation/controllers/dac_bridge_controller.dart';
import 'package:baydev_hifi/features/hardware_dac/presentation/screens/hardware_dac_studio_screen.dart';
import 'package:baydev_hifi/features/player/presentation/widgets/studio_dsp_bento_capsule.dart';
import 'package:baydev_hifi/features/pro_q_studio/presentation/controllers/eq_controller.dart';
import 'package:baydev_hifi/features/pro_q_studio/presentation/widgets/auto_eq_modal_dialog.dart';

/// Desktop Master Transport Deck Studio Signal Flow Chain Capsule
/// Provides instant 1-tap desktop access to [ AutoEQ ] -> [ DSP Rack ] -> [ Hardware DAC ]
class DesktopDspSignalCapsule extends ConsumerWidget {
  const DesktopDspSignalCapsule({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final eqState = ref.watch(eqControllerProvider);
    final dspState = ref.watch(dspRackControllerProvider);
    final dacState = ref.watch(dacBridgeControllerProvider);

    // 1. AutoEQ State
    final rawDriver = eqState.driverFr?.name;
    final isAutoActive = eqState.isAutoEqActive && rawDriver != null && rawDriver.isNotEmpty;
    final autoEqLabel = isAutoActive ? StudioDspBentoCapsule.formatAutoEqLabel(rawDriver) : 'AutoEQ';

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
    final dspLabel = isDspActive ? 'DSP ($activeDspCount)' : 'DSP';

    // 3. Hardware DAC State
    final isDacConnected = dacState.isConnected && dacState.device != null;
    final dacLabel = isDacConnected ? StudioDspBentoCapsule.formatDacLabel(dacState.device) : 'DAC';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.20),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. AutoEQ Chip
          Tooltip(
            message: 'AutoEQ Target: ${rawDriver ?? 'Direct'} (Click to adjust)',
            child: InkWell(
              onTap: () {
                AppHaptics.lightImpact();
                AutoEqModalDialog.show(context);
              },
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isAutoActive
                      ? StudioSurfaceTheme.tintedContainer(
                          context,
                          theme.colorScheme.primary,
                          isSolid: true,
                          solidBlendAlpha: 0.25,
                        )
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isAutoActive
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.slidersHorizontal,
                      color: isAutoActive
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurfaceVariant,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      autoEqLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isAutoActive ? FontWeight.w800 : FontWeight.w700,
                        color: isAutoActive
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Inter-stage divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              LucideIcons.chevronRight,
              size: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
            ),
          ),

          // 2. DSP Rack Chip
          Tooltip(
            message: 'Mastering DSP Rack (${isDspActive ? '$activeDspCount active' : 'Bypassed'})',
            child: InkWell(
              onTap: () {
                AppHaptics.lightImpact();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const DspRackScreen()),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDspActive
                      ? StudioSurfaceTheme.tintedContainer(
                          context,
                          theme.colorScheme.tertiary,
                          isSolid: true,
                          solidBlendAlpha: 0.25,
                        )
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDspActive
                        ? theme.colorScheme.tertiary
                        : theme.colorScheme.outline.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.slidersHorizontal,
                      color: isDspActive
                          ? theme.colorScheme.tertiary
                          : theme.colorScheme.onSurfaceVariant,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dspLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isDspActive ? FontWeight.w800 : FontWeight.w700,
                        color: isDspActive
                            ? theme.colorScheme.tertiary
                            : theme.colorScheme.onSurface,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Inter-stage divider
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Icon(
              LucideIcons.chevronRight,
              size: 12,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.25),
            ),
          ),

          // 3. Hardware DAC Chip
          Tooltip(
            message: 'Hardware DAC (${isDacConnected ? dacState.device?.productName : 'Direct'})',
            child: InkWell(
              onTap: () {
                AppHaptics.lightImpact();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HardwareDacStudioScreen()),
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDacConnected
                      ? StudioSurfaceTheme.tintedContainer(
                          context,
                          const Color(0xFF10B981),
                          isSolid: true,
                          solidBlendAlpha: 0.25,
                        )
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDacConnected
                        ? const Color(0xFF10B981)
                        : theme.colorScheme.outline.withValues(alpha: 0.15),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.usb,
                      color: isDacConnected
                          ? const Color(0xFF10B981)
                          : theme.colorScheme.onSurfaceVariant,
                      size: 13,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      dacLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isDacConnected ? FontWeight.w800 : FontWeight.w700,
                        color: isDacConnected
                            ? const Color(0xFF10B981)
                            : theme.colorScheme.onSurface,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
