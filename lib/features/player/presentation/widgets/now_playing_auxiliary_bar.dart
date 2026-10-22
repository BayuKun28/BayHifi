import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../dsp_rack/presentation/controllers/dsp_rack_controller.dart';
import '../../../dsp_rack/presentation/dsp_rack_screen.dart';
import '../../../pro_q_studio/presentation/controllers/eq_state.dart';
import '../../../pro_q_studio/presentation/widgets/auto_eq_modal_dialog.dart';
import '../../domain/track.dart';
import 'audio_file_inspector_sheet.dart';

/// Studio Auxiliary Action Bar
/// Provides solid pill buttons for Audio Specs Inspector, Pro-Q Studio EQ,
/// AutoEQ Target Matching, DSP Rack, and Lyrics Toggle.
class NowPlayingAuxiliaryBar extends ConsumerWidget {
  final Track? track;
  final EqState eqState;
  final VoidCallback onOpenProQStudio;
  final VoidCallback? onOpenDspRack;
  final bool isTablet;
  final bool showLyrics;
  final VoidCallback? onToggleLyrics;

  const NowPlayingAuxiliaryBar({
    super.key,
    required this.track,
    required this.eqState,
    required this.onOpenProQStudio,
    this.onOpenDspRack,
    this.isTablet = false,
    this.showLyrics = false,
    this.onToggleLyrics,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primary = theme.colorScheme.primary;
    final elevatedContainer =
        isDark ? const Color(0xFF1E212B) : theme.colorScheme.surfaceContainerHigh;
    final outlineBorder =
        isDark ? const Color(0xFF2E3242) : theme.colorScheme.outlineVariant;
    final subtleColor = theme.colorScheme.onSurfaceVariant;

    final hasDriver = eqState.driverFr != null;
    final hasTarget = eqState.targetFr != null;
    final isAutoActive = eqState.isAutoEqActive || hasDriver;
    final autoEqTooltip = hasDriver
        ? 'AutoEQ: ${eqState.driverFr!.name}${hasTarget ? ' → ${eqState.targetFr!.name}' : ''}'
        : 'AutoEQ Studio & Target Matching';

    final dspState = ref.watch(dspRackControllerProvider);
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
    final dspTooltip = isDspActive
        ? 'Mastering DSP Rack ($activeDspCount Active)'
        : (dspState.isBypassed
            ? 'Mastering DSP Rack (Bypassed)'
            : 'Mastering DSP Rack (Flat)');

    // Extra specs string for tablet view
    String extraSpecs = '';
    if (track != null) {
      if (track!.bitDepth != null && track!.bitDepth! > 0) {
        extraSpecs = ' • ${track!.bitDepth}bit';
      } else if (track!.bitrate != null && track!.bitrate! > 0) {
        extraSpecs = ' • ${(track!.bitrate! / 1000).round()}kbps';
      }
    }

    if (isTablet) {
      return Row(
        children: [
          // 1. Audio Specs Chip (Clickable for Inspector)
          if (track != null)
            InkWell(
              onTap: () {
                AppHaptics.lightImpact();
                AudioFileInspectorSheet.show(context, track!);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: elevatedContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: outlineBorder, width: 1.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      track!.format.name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: primary,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${track!.sampleRate != null ? (track!.sampleRate! / 1000).toStringAsFixed(1) : '44.1'}kHz$extraSpecs',
                      style: TextStyle(
                        fontFeatures: AppTypography.audioFigures,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 3),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 11,
                      color: subtleColor,
                    ),
                  ],
                ),
              ),
            ),

          const Spacer(),

          // 2. Pro-Q Action Pill
          Tooltip(
            message: eqState.isEnabled
                ? 'Pro-Q Studio Spectrum (Active)'
                : 'Pro-Q Studio Spectrum (Off)',
            child: InkWell(
              onTap: () {
                AppHaptics.selectionClick();
                onOpenProQStudio();
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 9),
                decoration: BoxDecoration(
                  color: eqState.isEnabled
                      ? primary.withValues(alpha: 0.16)
                      : elevatedContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: eqState.isEnabled ? primary : outlineBorder,
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.audioLines,
                      size: 13,
                      color: eqState.isEnabled
                          ? primary
                          : theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'PRO-Q',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: eqState.isEnabled
                            ? primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(width: 6),

          // 3. AutoEQ Action Pill
          Tooltip(
            message: autoEqTooltip,
            child: InkWell(
              onTap: () {
                AppHaptics.selectionClick();
                AutoEqModalDialog.show(context);
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 9),
                decoration: BoxDecoration(
                  color: isAutoActive
                      ? primary.withValues(alpha: 0.16)
                      : elevatedContainer,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isAutoActive ? primary : outlineBorder,
                    width: 1.0,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      LucideIcons.sparkles,
                      size: 13,
                      color: isAutoActive
                          ? primary
                          : theme.colorScheme.onSurface,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'AUTO-EQ',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: isAutoActive
                            ? primary
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    // Mobile Portrait Layout
    return Center(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Audio Specs Tag
            if (track != null) ...[
              InkWell(
                onTap: () {
                  AppHaptics.lightImpact();
                  AudioFileInspectorSheet.show(context, track!);
                },
                borderRadius: BorderRadius.circular(9),
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: elevatedContainer,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: outlineBorder, width: 1.0),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        track!.format.name.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w900,
                          color: primary,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${track!.sampleRate != null ? (track!.sampleRate! / 1000).toStringAsFixed(1) : '44.1'}kHz',
                        style: TextStyle(
                          fontFeatures: AppTypography.audioFigures,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],

            // 2. Pro-Q Studio EQ Icon Button
            Tooltip(
              message: eqState.isEnabled
                  ? 'Pro-Q Studio Spectrum (Active)'
                  : 'Pro-Q Studio Spectrum (Off)',
              child: InkWell(
                onTap: () {
                  AppHaptics.selectionClick();
                  onOpenProQStudio();
                },
                borderRadius: BorderRadius.circular(9),
                child: Container(
                  width: 38,
                  height: 34,
                  decoration: BoxDecoration(
                    color: eqState.isEnabled
                        ? primary.withValues(alpha: 0.16)
                        : elevatedContainer,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: eqState.isEnabled ? primary : outlineBorder,
                      width: 1.0,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      LucideIcons.audioLines,
                      size: 16,
                      color: eqState.isEnabled
                          ? primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // 3. AutoEQ Shortcut Icon Button
            Tooltip(
              message: autoEqTooltip,
              child: InkWell(
                onTap: () {
                  AppHaptics.selectionClick();
                  AutoEqModalDialog.show(context);
                },
                borderRadius: BorderRadius.circular(9),
                child: Container(
                  width: 38,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isAutoActive
                        ? primary.withValues(alpha: 0.16)
                        : elevatedContainer,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: isAutoActive ? primary : outlineBorder,
                      width: 1.0,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      LucideIcons.sparkles,
                      size: 16,
                      color: isAutoActive
                          ? primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // 4. Mastering DSP Rack Shortcut Icon Button
            Tooltip(
              message: dspTooltip,
              child: InkWell(
                onTap: () {
                  AppHaptics.selectionClick();
                  if (onOpenDspRack != null) {
                    onOpenDspRack!();
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const DspRackScreen(),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(9),
                child: Container(
                  width: 38,
                  height: 34,
                  decoration: BoxDecoration(
                    color: isDspActive
                        ? primary.withValues(alpha: 0.16)
                        : elevatedContainer,
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(
                      color: isDspActive ? primary : outlineBorder,
                      width: 1.0,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      LucideIcons.slidersHorizontal,
                      size: 16,
                      color: isDspActive
                          ? primary
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // 5. Lyrics Toggle Button
            if (onToggleLyrics != null)
              Tooltip(
                message: showLyrics
                    ? 'Hide Synchronized Lyrics'
                    : 'Show Synchronized Lyrics',
                child: InkWell(
                  onTap: () {
                    AppHaptics.lightImpact();
                    onToggleLyrics!();
                  },
                  borderRadius: BorderRadius.circular(9),
                  child: Container(
                    height: 34,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: showLyrics
                          ? primary.withValues(alpha: 0.16)
                          : elevatedContainer,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(
                        color: showLyrics ? primary : outlineBorder,
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.quote,
                          size: 14,
                          color: showLyrics
                              ? primary
                              : theme.colorScheme.onSurface,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'LYRICS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: showLyrics
                                ? primary
                                : theme.colorScheme.onSurface,
                          ),
                        ),
                      ],
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
