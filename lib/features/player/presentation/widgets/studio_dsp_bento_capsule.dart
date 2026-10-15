import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../dsp_rack/presentation/controllers/dsp_rack_controller.dart';
import '../../../dsp_rack/presentation/dsp_rack_screen.dart';
import '../../../hardware_dac/domain/models/dac_device.dart';
import '../../../hardware_dac/presentation/controllers/dac_bridge_controller.dart';
import '../../../hardware_dac/presentation/screens/hardware_dac_studio_screen.dart';
import '../../../pro_q_studio/presentation/controllers/eq_controller.dart';
import '../../../pro_q_studio/presentation/widgets/auto_eq_modal_dialog.dart';
import '../controllers/player_controller.dart';

/// Unified Studio Audio Signal Flow Chain Capsule for NowPlayingScreen.
/// Displays an interconnected, 1-row compact 3-stage tactile pipeline with live signal flow animation:
/// [ AutoEQ ] -> [ DSP Rack ] -> [ Hardware DAC ]
class StudioDspBentoCapsule extends ConsumerStatefulWidget {
  const StudioDspBentoCapsule({super.key});

  /// Formats AutoEQ driver names cleanly (e.g. "KZ Castor Bass Black Dudu R" -> "KZ CASTOR...")
  static String formatAutoEqLabel(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'AutoEQ';
    String clean = raw.replaceAll('_', ' ').replaceAll('%20', ' ').trim();
    try {
      clean = Uri.decodeComponent(clean);
    } catch (_) {}

    final words = clean.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return 'AutoEQ';

    if (words.length == 1) {
      final w = words[0].toUpperCase();
      return w.length > 10 ? '${w.substring(0, 8)}...' : w;
    }

    // Combine first two principal tokens (e.g. "KZ CASTOR", "CHU II", "HD 600")
    final primary = '${words[0]} ${words[1]}'.toUpperCase();
    if (words.length > 2 || primary.length > 13) {
      if (primary.length > 13) {
        return '${primary.substring(0, 11).trim()}...';
      }
      return '$primary...';
    }
    return primary;
  }

  /// Formats Hardware DAC names with Brand & Model cleanly (e.g. "Kiwi Ears AD1" -> "KIWI AD1")
  static String formatDacLabel(DacDevice? device) {
    if (device == null) return 'DAC Direct';
    String name = device.productName.trim();
    if (name.isEmpty) return 'DAC Active';

    name = name.replaceAll('Kiwi Ears', 'KIWI').trim();
    final upper = name.toUpperCase();
    if (upper.length > 12) {
      return 'DAC • ${upper.substring(0, 9)}...';
    }
    return 'DAC • $upper';
  }

  @override
  ConsumerState<StudioDspBentoCapsule> createState() => _StudioDspBentoCapsuleState();
}

class _StudioDspBentoCapsuleState extends ConsumerState<StudioDspBentoCapsule>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flowController;

  @override
  void initState() {
    super.initState();
    _flowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
  }

  @override
  void dispose() {
    _flowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final eqState = ref.watch(eqControllerProvider);
    final dspState = ref.watch(dspRackControllerProvider);
    final dacState = ref.watch(dacBridgeControllerProvider);
    final isPlaying = ref.watch(playerControllerProvider.select((s) => s.isPlaying));

    if (isPlaying) {
      if (!_flowController.isAnimating) {
        _flowController.repeat();
      }
    } else {
      if (_flowController.isAnimating) {
        _flowController.stop();
        _flowController.value = 0.0;
      }
    }

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
    final dspLabel = isDspActive ? 'DSP ($activeDspCount)' : 'DSP Rack';

    // 3. Hardware DAC State
    final isDacConnected = dacState.isConnected && dacState.device != null;
    final dacLabel = isDacConnected ? StudioDspBentoCapsule.formatDacLabel(dacState.device) : 'DAC Direct';
    final primary = colorScheme.primary;

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
              message: 'Stage 1: AutoEQ Target Curve (${rawDriver ?? 'Direct'})',
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(20),
                  onTap: () {
                    AppHaptics.lightImpact();
                    AutoEqModalDialog.show(context);
                  },
                  child: Container(
                    height: 27,
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: isAutoActive
                          ? StudioSurfaceTheme.tintedContainer(
                              context,
                              primary,
                              isSolid: true,
                              solidBlendAlpha: 0.25,
                            )
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isAutoActive
                            ? primary
                            : colorScheme.outline.withValues(alpha: 0.20),
                        width: isAutoActive ? 1.0 : 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedHeadphones,
                          size: 11.5,
                          color: isAutoActive
                              ? primary
                              : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          autoEqLabel,
                          style: TextStyle(
                            fontSize: 9.0,
                            fontWeight: isAutoActive ? FontWeight.w800 : FontWeight.w700,
                            letterSpacing: 0.2,
                            color: isAutoActive
                                ? primary
                                : colorScheme.onSurface,
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

            // ─── CONNECTOR 1: Flow Animation ──────────────────────────
            _AnimatedSignalConnector(
              animation: _flowController,
              isPlaying: isPlaying,
              color: isAutoActive ? primary : colorScheme.outline,
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
                    height: 27,
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: isDspActive
                          ? StudioSurfaceTheme.tintedContainer(
                              context,
                              primary,
                              isSolid: true,
                              solidBlendAlpha: 0.25,
                            )
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDspActive
                            ? primary
                            : colorScheme.outline.withValues(alpha: 0.20),
                        width: isDspActive ? 1.0 : 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedSlidersVertical,
                          size: 11.5,
                          color: isDspActive ? primary : colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          dspLabel,
                          style: TextStyle(
                            fontSize: 9.0,
                            fontWeight: isDspActive ? FontWeight.w800 : FontWeight.w700,
                            letterSpacing: 0.2,
                            color: isDspActive
                                ? primary
                                : colorScheme.onSurface,
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

            // ─── CONNECTOR 2: Flow Animation ──────────────────────────
            _AnimatedSignalConnector(
              animation: _flowController,
              isPlaying: isPlaying,
              color: isDspActive ? primary : (isDacConnected ? primary : colorScheme.outline),
            ),

            // ─── STAGE 3: Hardware DAC Bridge ─────────────────────────
            Tooltip(
              message: isDacConnected
                  ? 'Stage 3: Hardware DAC Bridge (${dacState.device?.productName} Active)'
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
                    height: 27,
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: isDacConnected
                          ? StudioSurfaceTheme.tintedContainer(
                              context,
                              primary,
                              isSolid: true,
                              solidBlendAlpha: 0.25,
                            )
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDacConnected
                            ? primary
                            : colorScheme.outline.withValues(alpha: 0.20),
                        width: isDacConnected ? 1.0 : 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isDacConnected) ...[
                          Container(
                            width: 5.5,
                            height: 5.5,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primary,
                            ),
                          ),
                          const SizedBox(width: 4),
                        ] else ...[
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedUsb,
                            size: 11.5,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(width: 4),
                        ],
                        Text(
                          dacLabel,
                          style: TextStyle(
                            fontSize: 9.0,
                            fontWeight: isDacConnected ? FontWeight.w800 : FontWeight.w700,
                            letterSpacing: 0.2,
                            color: isDacConnected
                                ? primary
                                : colorScheme.onSurface,
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

/// Compact micro signal flow connector with traveling wave pulse animation.
class _AnimatedSignalConnector extends StatelessWidget {
  const _AnimatedSignalConnector({
    required this.animation,
    required this.isPlaying,
    required this.color,
  });

  final Animation<double> animation;
  final bool isPlaying;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (!isPlaying) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3.0),
        child: HugeIcon(
          icon: HugeIcons.strokeRoundedArrowRight01,
          size: 10,
          color: color.withValues(alpha: 0.35),
        ),
      );
    }

    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final progress = animation.value;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(2, (index) {
              final phase = (progress - (index * 0.35)) % 1.0;
              final wave = (1.0 - (phase - 0.5).abs() * 2.0).clamp(0.0, 1.0);
              final alpha = 0.25 + (wave * 0.75);

              return Opacity(
                opacity: alpha,
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedArrowRight01,
                  size: 9.0,
                  color: color,
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
