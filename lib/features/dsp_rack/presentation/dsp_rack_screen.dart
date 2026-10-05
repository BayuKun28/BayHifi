import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../../core/widgets/studio_artwork_widget.dart';
import '../../player/domain/track.dart';
import '../../player/presentation/controllers/player_controller.dart';
import '../domain/dsp_models.dart';
import 'controllers/dsp_rack_controller.dart';
import 'widgets/genre_rules_config_modal.dart';
import 'widgets/studio_track_dsp_preset_sheet.dart';
import '../../pro_q_studio/presentation/pro_q_studio_screen.dart';
import '../../hardware_dac/presentation/screens/hardware_dac_studio_screen.dart';
import 'widgets/gain_reduction_meter.dart';
import 'widgets/rack_knob_slider.dart';
import 'widgets/rack_unit_card.dart';
import 'widgets/soundstage_width_visualizer.dart';
import 'widgets/tube_glow_indicator.dart';
import 'widgets/vu_level_meter.dart';

/// Halaman Mastering DSP Studio Rack (10+ Modul Hardware Audio)
class DspRackScreen extends ConsumerWidget {
  const DspRackScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dspState = ref.watch(dspRackControllerProvider);
    final controller = ref.read(dspRackControllerProvider.notifier);
    final playerState = ref.watch(playerControllerProvider);
    final currentTrack = playerState.currentTrack;
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isSolid = ref.isSolidStyle;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: StudioSurfaceTheme.tintedContainer(
                  context,
                  primaryColor,
                  isSolid: isSolid,
                  translucentAlpha: 0.15,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedSlidersVertical,
                color: primaryColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'MASTERING DSP RACK',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'C++ Low-Latency Processing Engine',
                    style: TextStyle(
                      fontSize: 10,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Save Custom DSP Profile Button
          IconButton(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedFloppyDisk,
              size: 20,
              color: primaryColor,
            ),
            tooltip: 'Save Custom DSP Profile',
            onPressed: () => _showSaveProfileDialog(context, controller, isSolid),
          ),
          // Reset Rack Button with Confirmation Modal
          IconButton(
            icon: const HugeIcon(
              icon: HugeIcons.strokeRoundedRefresh,
              size: 20,
              color: null,
            ),
            tooltip: 'Reset to Flat Reference',
            onPressed: () => _showResetConfirmationDialog(context, controller, isSolid),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          // 0. PRO-Q STUDIO EQ LAUNCHER BANNER
          _buildProQStudioBanner(context, isSolid),

          // 0.1 HARDWARE DAC BRIDGE & FLASHER BANNER
          _buildHardwareDacBanner(context, isSolid),

          // 1. MASTER HEADER & A/B COMPARISON STRIP
          _buildMasterSection(context, dspState, controller, isSolid),
          const SizedBox(height: 16),

          // 2. STUDIO PRESETS SELECTOR
          _buildPresetsSelector(
            context,
            dspState,
            controller,
            isSolid,
            currentTrack: currentTrack,
          ),
          const SizedBox(height: 20),

          // UNIT 01: PRE-AMP GAIN STAGE
          RackUnitCard(
            unitNumber: '01',
            title: 'Pre-Amp Gain Stage',
            subtitle: 'Headroom Input Level & Digital Protection',
            isActive: !dspState.isBypassed,
            onToggle: () {},
            accentColor: StudioCategoryColors.bitPerfect,
            headerTrailing: TextButton.icon(
              onPressed: () => controller.setPreamp(0.0),
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedRefresh,
                size: 14,
                color: null,
              ),
              label: const Text('0 dB', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                VuLevelMeter(
                  levelDb: dspState.isBypassed ? 0.0 : dspState.preampDb,
                ),
                const SizedBox(height: 12),
                RackKnobSlider(
                  label: 'Input Gain',
                  value: dspState.preampDb,
                  min: -24.0,
                  max: 12.0,
                  formattedValue:
                      '${dspState.preampDb >= 0 ? '+' : ''}${dspState.preampDb.toStringAsFixed(1)} dB',
                  onChanged: (val) => controller.setPreamp(val),
                  accentColor: StudioCategoryColors.bitPerfect,
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildQuickGainChip(context, '-12 dB', -12.0, dspState.preampDb, controller, isSolid),
                      const SizedBox(width: 6),
                      _buildQuickGainChip(context, '-6 dB', -6.0, dspState.preampDb, controller, isSolid),
                      const SizedBox(width: 6),
                      _buildQuickGainChip(context, '-3 dB', -3.0, dspState.preampDb, controller, isSolid),
                      const SizedBox(width: 6),
                      _buildQuickGainChip(context, '-1 dB', -1.0, dspState.preampDb, controller, isSolid),
                      const SizedBox(width: 6),
                      _buildQuickGainChip(context, '0 dB (Flat)', 0.0, dspState.preampDb, controller, isSolid),
                      const SizedBox(width: 6),
                      _buildQuickGainChip(context, '+3 dB', 3.0, dspState.preampDb, controller, isSolid),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // UNIT 02: DYNAMIC BASS BOOST
          RackUnitCard(
            unitNumber: '02',
            title: 'Dynamic Bass Boost',
            subtitle: 'Psychoacoustic Sub-Bass Impact (40 - 160 Hz)',
            isActive: !dspState.isBypassed && dspState.bassBoostEnabled,
            onToggle: () => controller.toggleBassBoost(),
            accentColor: StudioCategoryColors.proQEqualizer,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RackKnobSlider(
                  label: 'Bass Boost Intensity',
                  value: dspState.bassBoostAmount,
                  min: 0.0,
                  max: 10.0,
                  formattedValue:
                      '${dspState.bassBoostAmount.toStringAsFixed(1)}x',
                  onChanged: (val) => controller.setBassBoostAmount(val),
                  accentColor: StudioCategoryColors.proQEqualizer,
                ),
                const SizedBox(height: 8),
                RackKnobSlider(
                  label: 'Boost Mix (Wet/Dry)',
                  value: dspState.bassBoostWet,
                  min: 0.0,
                  max: 1.0,
                  formattedValue: '${(dspState.bassBoostWet * 100).toInt()}%',
                  onChanged: (val) => controller.setBassBoostWet(val),
                  accentColor: StudioCategoryColors.proQEqualizer,
                ),
              ],
            ),
          ),

          // UNIT 03: TUBE EXCITER / TRIODE SATURATION
          RackUnitCard(
            unitNumber: '03',
            title: 'Tube Harmonic Exciter',
            subtitle: 'Analog Triode Saturation y = tanh(k · x)',
            isActive: !dspState.isBypassed && dspState.tubeExciterEnabled,
            onToggle: () => controller.toggleTubeExciter(),
            accentColor: StudioCategoryColors.dspTubeWarmth,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TubeGlowIndicator(
                  drive: dspState.tubeDrive,
                  warmth: dspState.tubeWarmth,
                  isActive: !dspState.isBypassed && dspState.tubeExciterEnabled,
                ),
                const SizedBox(height: 12),
                RackKnobSlider(
                  label: 'Tube Drive',
                  value: dspState.tubeDrive,
                  min: 0.0,
                  max: 10.0,
                  formattedValue: '${dspState.tubeDrive.toStringAsFixed(1)}x',
                  onChanged: (val) => controller.setTubeDrive(val),
                  accentColor: StudioCategoryColors.dspTubeWarmth,
                ),
                const SizedBox(height: 8),
                RackKnobSlider(
                  label: 'Harmonic Warmth',
                  value: dspState.tubeWarmth,
                  min: 0.0,
                  max: 1.0,
                  formattedValue: '${(dspState.tubeWarmth * 100).toInt()}%',
                  onChanged: (val) => controller.setTubeWarmth(val),
                  accentColor: StudioCategoryColors.dspTubeWarmth,
                ),
                const SizedBox(height: 8),
                RackKnobSlider(
                  label: 'Saturation Mix',
                  value: dspState.tubeMix,
                  min: 0.0,
                  max: 1.0,
                  formattedValue: '${(dspState.tubeMix * 100).toInt()}%',
                  onChanged: (val) => controller.setTubeMix(val),
                  accentColor: StudioCategoryColors.dspTubeWarmth,
                ),
              ],
            ),
          ),

          // UNIT 04: DYNAMIC COMPRESSOR
          RackUnitCard(
            unitNumber: '04',
            title: 'Dynamic Compressor',
            subtitle: 'Studio Dynamic Range Transient Sculptor',
            isActive: !dspState.isBypassed && dspState.compressorEnabled,
            onToggle: () => controller.toggleCompressor(),
            accentColor: StudioCategoryColors.dspCompressor,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GainReductionMeter(
                  gainReductionDb:
                      (!dspState.isBypassed && dspState.compressorEnabled)
                      ? (dspState.compThreshold * 0.4).clamp(-20.0, 0.0)
                      : 0.0,
                  isActive: !dspState.isBypassed && dspState.compressorEnabled,
                ),
                const SizedBox(height: 12),
                RackKnobSlider(
                  label: 'Threshold',
                  value: dspState.compThreshold,
                  min: -80.0,
                  max: 0.0,
                  formattedValue:
                      '${dspState.compThreshold.toStringAsFixed(1)} dB',
                  onChanged: (val) => controller.setCompThreshold(val),
                  accentColor: StudioCategoryColors.dspCompressor,
                ),
                const SizedBox(height: 8),
                RackKnobSlider(
                  label: 'Compression Ratio',
                  value: dspState.compRatio,
                  min: 1.0,
                  max: 10.0,
                  formattedValue: '${dspState.compRatio.toStringAsFixed(1)}:1',
                  onChanged: (val) => controller.setCompRatio(val),
                  accentColor: StudioCategoryColors.dspCompressor,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: RackKnobSlider(
                        label: 'Attack',
                        value: dspState.compAttack,
                        min: 0.1,
                        max: 100.0,
                        formattedValue:
                            '${dspState.compAttack.toStringAsFixed(0)} ms',
                        onChanged: (val) => controller.setCompAttack(val),
                        accentColor: StudioCategoryColors.dspCompressor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RackKnobSlider(
                        label: 'Release',
                        value: dspState.compRelease,
                        min: 10.0,
                        max: 1000.0,
                        formattedValue:
                            '${dspState.compRelease.toStringAsFixed(0)} ms',
                        onChanged: (val) => controller.setCompRelease(val),
                        accentColor: StudioCategoryColors.dspCompressor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                RackKnobSlider(
                  label: 'Make-up Gain',
                  value: dspState.compMakeup,
                  min: -40.0,
                  max: 40.0,
                  formattedValue:
                      '${dspState.compMakeup >= 0 ? '+' : ''}${dspState.compMakeup.toStringAsFixed(1)} dB',
                  onChanged: (val) => controller.setCompMakeup(val),
                  accentColor: StudioCategoryColors.dspCompressor,
                ),
              ],
            ),
          ),

          // UNIT 05: STEREO WIDTH (MID-SIDE MATRIX)
          RackUnitCard(
            unitNumber: '05',
            title: 'Mid-Side Stereo Widener',
            subtitle: 'Soundstage Matrix M = (L+R)/2, S = (L-R)/2',
            isActive: !dspState.isBypassed && dspState.stereoWidthEnabled,
            onToggle: () => controller.toggleStereoWidth(),
            accentColor: StudioCategoryColors.themingPalettes,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SoundstageWidthVisualizer(
                  widthFactor: dspState.stereoWidth,
                  isActive: !dspState.isBypassed && dspState.stereoWidthEnabled,
                ),
                const SizedBox(height: 12),
                RackKnobSlider(
                  label: 'Soundstage Width Factor',
                  value: dspState.stereoWidth,
                  min: 0.0,
                  max: 3.0,
                  formattedValue: '${(dspState.stereoWidth * 100).toInt()}%',
                  onChanged: (val) => controller.setStereoWidth(val),
                  accentColor: StudioCategoryColors.themingPalettes,
                ),
                const SizedBox(height: 8),
                RackKnobSlider(
                  label: 'Center Mid-Gain',
                  value: dspState.stereoMidGain,
                  min: 0.0,
                  max: 2.0,
                  formattedValue: '${(dspState.stereoMidGain * 100).toInt()}%',
                  onChanged: (val) => controller.setStereoMidGain(val),
                  accentColor: StudioCategoryColors.themingPalettes,
                ),
              ],
            ),
          ),

          // UNIT 06: BINAURAL CROSSFEED
          RackUnitCard(
            unitNumber: '06',
            title: 'Bauer Binaural Crossfeed',
            subtitle: 'Acoustic Headphone Simulation (Reduces Fatigue)',
            isActive: !dspState.isBypassed && dspState.crossfeedEnabled,
            onToggle: () => controller.toggleCrossfeed(),
            accentColor: StudioCategoryColors.autoEq,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RackKnobSlider(
                  label: 'Cutoff Frequency',
                  value: dspState.crossfeedCutoff,
                  min: 200.0,
                  max: 2000.0,
                  formattedValue:
                      '${dspState.crossfeedCutoff.toStringAsFixed(0)} Hz',
                  onChanged: (val) => controller.setCrossfeedCutoff(val),
                  accentColor: StudioCategoryColors.autoEq,
                ),
                const SizedBox(height: 8),
                RackKnobSlider(
                  label: 'Crosstalk Feed Level',
                  value: dspState.crossfeedFeed,
                  min: -24.0,
                  max: 0.0,
                  formattedValue:
                      '${dspState.crossfeedFeed.toStringAsFixed(1)} dB',
                  onChanged: (val) => controller.setCrossfeedFeed(val),
                  accentColor: StudioCategoryColors.autoEq,
                ),
                const SizedBox(height: 8),
                RackKnobSlider(
                  label: 'Interaural Time Delay',
                  value: dspState.crossfeedDelayMs,
                  min: 0.05,
                  max: 1.0,
                  formattedValue:
                      '${(dspState.crossfeedDelayMs * 1000).toStringAsFixed(0)} µs',
                  onChanged: (val) => controller.setCrossfeedDelay(val),
                  accentColor: StudioCategoryColors.autoEq,
                ),
              ],
            ),
          ),

          // UNIT 07: SPATIAL STUDIO REVERB
          RackUnitCard(
            unitNumber: '07',
            title: 'Spatial Studio Reverb',
            subtitle: 'Freeverb 3D Acoustic Space & Room Reflection',
            isActive: !dspState.isBypassed && dspState.reverbEnabled,
            onToggle: () => controller.toggleReverb(),
            accentColor: StudioCategoryColors.storageCache,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RackKnobSlider(
                  label: 'Room Size',
                  value: dspState.reverbRoomSize,
                  min: 0.0,
                  max: 1.0,
                  formattedValue: '${(dspState.reverbRoomSize * 100).toInt()}%',
                  onChanged: (val) => controller.setReverbRoomSize(val),
                  accentColor: StudioCategoryColors.storageCache,
                ),
                const SizedBox(height: 8),
                RackKnobSlider(
                  label: 'High-Freq Damping',
                  value: dspState.reverbDamp,
                  min: 0.0,
                  max: 1.0,
                  formattedValue: '${(dspState.reverbDamp * 100).toInt()}%',
                  onChanged: (val) => controller.setReverbDamp(val),
                  accentColor: StudioCategoryColors.storageCache,
                ),
                const SizedBox(height: 8),
                RackKnobSlider(
                  label: 'Wet Space Mix',
                  value: dspState.reverbWet,
                  min: 0.0,
                  max: 1.0,
                  formattedValue: '${(dspState.reverbWet * 100).toInt()}%',
                  onChanged: (val) => controller.setReverbWet(val),
                  accentColor: StudioCategoryColors.storageCache,
                ),
              ],
            ),
          ),

          // UNIT 08: PITCH SHIFTER ENGINE
          RackUnitCard(
            unitNumber: '08',
            title: 'Granular Pitch Shifter',
            subtitle: 'Real-Time Chromatic Pitch Shift (Tempo Invariant)',
            isActive: !dspState.isBypassed && dspState.pitchShiftEnabled,
            onToggle: () => controller.togglePitchShift(),
            accentColor: StudioCategoryColors.lyricsMagenta,
            headerTrailing: TextButton.icon(
              onPressed: () => controller.setPitchSemitones(0.0),
              icon: const HugeIcon(
                icon: HugeIcons.strokeRoundedRefresh,
                size: 14,
                color: StudioCategoryColors.lyricsMagenta,
              ),
              label: const Text('Reset', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RackKnobSlider(
                  label: 'Semitones Offset',
                  value: dspState.pitchSemitones,
                  min: -12.0,
                  max: 12.0,
                  divisions: 24,
                  formattedValue:
                      '${dspState.pitchSemitones >= 0 ? '+' : ''}${dspState.pitchSemitones.toStringAsFixed(1)} st',
                  onChanged: (val) => controller.setPitchSemitones(val),
                  accentColor: StudioCategoryColors.lyricsMagenta,
                ),
              ],
            ),
          ),

          // UNIT 09: PEAK BRICKWALL LIMITER
          RackUnitCard(
            unitNumber: '09',
            title: 'Peak Brickwall Limiter',
            subtitle: 'Zero-Overshoot Anti-Clipping Lookahead Safety',
            isActive: !dspState.isBypassed && dspState.limiterEnabled,
            onToggle: () => controller.toggleLimiter(),
            accentColor: StudioCategoryColors.dspLimiter,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RackKnobSlider(
                  label: 'Threshold / Drive',
                  value: dspState.limiterThreshold,
                  min: -60.0,
                  max: 0.0,
                  formattedValue:
                      '${dspState.limiterThreshold.toStringAsFixed(1)} dB',
                  onChanged: (val) => controller.setLimiterThreshold(val),
                  accentColor: StudioCategoryColors.dspLimiter,
                ),
                const SizedBox(height: 8),
                RackKnobSlider(
                  label: 'Output Ceiling (True Peak)',
                  value: dspState.limiterOutputCeiling,
                  min: -60.0,
                  max: 0.0,
                  formattedValue:
                      '${dspState.limiterOutputCeiling.toStringAsFixed(1)} dBFS',
                  onChanged: (val) => controller.setLimiterCeiling(val),
                  accentColor: StudioCategoryColors.dspLimiter,
                ),
                const SizedBox(height: 8),
                RackKnobSlider(
                  label: 'Release Recovery',
                  value: dspState.limiterRelease,
                  min: 1.0,
                  max: 1000.0,
                  formattedValue:
                      '${dspState.limiterRelease.toStringAsFixed(0)} ms',
                  onChanged: (val) => controller.setLimiterRelease(val),
                  accentColor: StudioCategoryColors.dspLimiter,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Master Header Strip dengan A/B comparison switch dan Master Wet/Dry
  Widget _buildMasterSection(
    BuildContext context,
    DspRackState state,
    DspRackController controller,
    bool isSolid,
  ) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surface(context, isSolid: isSolid),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isSolid
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MASTER DSP CHAIN',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      state.isBypassed
                          ? 'Bypassed (Pure Bit-Perfect Direct Audio)'
                          : 'Mastering Chain Active',
                      style: TextStyle(
                        fontSize: 11,
                        color: state.isBypassed
                            ? theme.colorScheme.secondary
                            : primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Master DSP Status & Bypass Switch
              InkWell(
                onTap: () => controller.toggleBypass(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: state.isBypassed
                        ? StudioSurfaceTheme.tintedContainer(
                            context,
                            const Color(0xFFFF3B30),
                            isSolid: isSolid,
                            translucentAlpha: 0.12,
                          )
                        : StudioSurfaceTheme.tintedContainer(
                            context,
                            const Color(0xFF34C759),
                            isSolid: isSolid,
                            translucentAlpha: 0.12,
                          ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: state.isBypassed
                            ? HugeIcons.strokeRoundedCancel01
                            : HugeIcons.strokeRoundedCheckmarkCircle01,
                        size: 16,
                        color: state.isBypassed
                            ? const Color(0xFFFF3B30)
                            : const Color(0xFF34C759),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        state.isBypassed
                            ? 'BYPASSED (FLAT)'
                            : 'DSP ACTIVE',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: state.isBypassed
                              ? const Color(0xFFFF3B30)
                              : const Color(0xFF34C759),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Master Wet/Dry Slider
          RackKnobSlider(
            label: 'Master Wet / Dry Blend',
            value: state.masterWet,
            min: 0.0,
            max: 1.0,
            formattedValue: '${(state.masterWet * 100).toInt()}% WET',
            onChanged: (val) => controller.setMasterWet(val),
          ),
        ],
      ),
    );
  }

  /// Preset selector Studio Combo Box / Dropdown
  Widget _buildPresetsSelector(
    BuildContext context,
    DspRackState state,
    DspRackController controller,
    bool isSolid, {
    Track? currentTrack,
  }) {
    final theme = Theme.of(context);
    final studioPresets = DspPreset.studioPresets;
    final genrePresets = studioPresets.where((p) => p.id.startsWith('genre_')).toList();
    final referencePresets = studioPresets.where((p) => !p.id.startsWith('genre_')).toList();
    final customPresets = controller.customPresets;

    // Find active preset if any
    DspPreset? activePreset;
    for (final p in customPresets) {
      if (p.id == state.activePresetId) {
        activePreset = p;
        break;
      }
    }
    if (activePreset == null) {
      for (final p in studioPresets) {
        if (p.id == state.activePresetId) {
          activePreset = p;
          break;
        }
      }
    }

    final isCustomActive = activePreset != null &&
        customPresets.any((p) => p.id == activePreset!.id);
    final isGenrePreset = activePreset != null && activePreset.id.startsWith('genre_');

    final displayName = activePreset?.name ?? 'Manual Tuning (Customized)';

    // Active track resolution status
    final isTrackPinned = currentTrack != null && controller.isTrackPinned(currentTrack.id);
    final trackResolution = currentTrack != null ? controller.resolvePresetForTrack(currentTrack) : null;

    return Container(
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surfaceContainerHigh(
          context,
          isSolid: isSolid,
          translucentAlpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedSparkles,
                      size: 15,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'MASTERING PRESET & PROFILE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // Genre Auto-Apply Rules Button
              InkWell(
                onTap: () => GenreRulesConfigModal.show(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: StudioSurfaceTheme.tintedContainer(
                      context,
                      theme.colorScheme.secondary,
                      isSolid: isSolid,
                      translucentAlpha: 0.12,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedSlidersHorizontal,
                        size: 13,
                        color: theme.colorScheme.secondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'GENRE RULES',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Save Profile Button
              InkWell(
                onTap: () => _showSaveProfileDialog(context, controller, isSolid),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: StudioSurfaceTheme.tintedContainer(
                      context,
                      theme.colorScheme.primary,
                      isSolid: isSolid,
                      translucentAlpha: 0.12,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedFloppyDisk,
                        size: 13,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'SAVE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ─── ACTIVE PLAYING TRACK STATUS BANNER ───────────────────────────
          if (currentTrack != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isTrackPinned
                      ? theme.colorScheme.primary.withValues(alpha: 0.4)
                      : theme.colorScheme.outline.withValues(alpha: 0.15),
                  width: 0.8,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: StudioArtworkWidget(
                      track: currentTrack,
                      borderRadius: BorderRadius.circular(5),
                      fallbackIconSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                currentTrack.title,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: isTrackPinned
                                    ? theme.colorScheme.primary.withValues(alpha: 0.15)
                                    : (trackResolution?.source == DspResolutionSource.genreAuto
                                        ? theme.colorScheme.tertiary.withValues(alpha: 0.15)
                                        : theme.colorScheme.outline.withValues(alpha: 0.1)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isTrackPinned
                                    ? 'PINNED'
                                    : (trackResolution?.source == DspResolutionSource.genreAuto
                                        ? 'AUTO: ${trackResolution?.matchedGenre?.toUpperCase() ?? "GENRE"}'
                                        : 'GLOBAL'),
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: isTrackPinned
                                      ? theme.colorScheme.primary
                                      : (trackResolution?.source == DspResolutionSource.genreAuto
                                          ? theme.colorScheme.tertiary
                                          : theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                        Text(
                          '${currentTrack.artist}${currentTrack.genre != null && currentTrack.genre!.isNotEmpty ? " • ${currentTrack.genre}" : ""}',
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () => StudioTrackDspPresetSheet.show(context, currentTrack),
                    borderRadius: BorderRadius.circular(6),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isTrackPinned ? 'MANAGE' : 'PIN TO TRACK',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 10),

          // COMBO BOX / DROPDOWN SELECTOR
          PopupMenuButton<dynamic>(
            color: StudioSurfaceTheme.surface(context, isSolid: isSolid),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: StudioSurfaceTheme.outline(context, isSolid: isSolid),
                width: 1.0,
              ),
            ),
            elevation: 8,
            offset: const Offset(0, 52),
            onSelected: (val) {
              if (val is DspPreset) {
                controller.applyPreset(val);
              } else if (val == '__SAVE_NEW__') {
                _showSaveProfileDialog(context, controller, isSolid);
              }
            },
            itemBuilder: (context) {
              final items = <PopupMenuEntry<dynamic>>[];

              // Action: Save Current Setup
              items.add(
                PopupMenuItem<dynamic>(
                  value: '__SAVE_NEW__',
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: StudioSurfaceTheme.tintedContainer(
                            context,
                            theme.colorScheme.primary,
                            isSolid: isSolid,
                            translucentAlpha: 0.15,
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedFloppyDisk,
                          size: 14,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        '+ Save Current as New Profile...',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );

              items.add(const PopupMenuDivider());

              // Section 1: Custom User Profiles
              if (customPresets.isNotEmpty) {
                items.add(
                  PopupMenuItem<dynamic>(
                    enabled: false,
                    height: 28,
                    child: Text(
                      'USER SAVED PROFILES (${customPresets.length})',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                );

                for (final p in customPresets) {
                  final isSelected = state.activePresetId == p.id;
                  items.add(
                    PopupMenuItem<dynamic>(
                      value: p,
                      child: Row(
                        children: [
                          HugeIcon(
                            icon: isSelected
                                ? HugeIcons.strokeRoundedCheckmarkCircle02
                                : HugeIcons.strokeRoundedBookmark02,
                            size: 15,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  p.name,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (p.description.isNotEmpty)
                                  Text(
                                    p.description,
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const HugeIcon(
                              icon: HugeIcons.strokeRoundedDelete02,
                              size: 14,
                              color: Colors.redAccent,
                            ),
                            tooltip: 'Delete Profile',
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            onPressed: () {
                              Navigator.of(context).pop();
                              _showDeleteProfileDialog(context, controller, p, isSolid);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                }

                items.add(const PopupMenuDivider());
              }

              // Section 2: Genre Mastering Presets
              items.add(
                PopupMenuItem<dynamic>(
                  enabled: false,
                  height: 28,
                  child: Text(
                    'GENRE MASTERING PRESETS (${genrePresets.length})',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
              );

              for (final p in genrePresets) {
                final isSelected = state.activePresetId == p.id;
                items.add(
                  PopupMenuItem<dynamic>(
                    value: p,
                    child: Row(
                      children: [
                        HugeIcon(
                          icon: isSelected
                              ? HugeIcons.strokeRoundedCheckmarkCircle02
                              : HugeIcons.strokeRoundedSparkles,
                          size: 15,
                          color: isSelected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                p.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected
                                      ? theme.colorScheme.primary
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                p.description,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
                );
              }

              items.add(const PopupMenuDivider());

              // Section 3: Studio Reference Presets
              items.add(
                PopupMenuItem<dynamic>(
                  enabled: false,
                  height: 28,
                  child: Text(
                    'STUDIO REFERENCE PRESETS (${referencePresets.length})',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                ),
              );

              for (final p in referencePresets) {
                final isSelected = state.activePresetId == p.id;
                items.add(
                  PopupMenuItem<dynamic>(
                    value: p,
                    child: Row(
                      children: [
                        HugeIcon(
                          icon: isSelected
                              ? HugeIcons.strokeRoundedCheckmarkCircle02
                              : HugeIcons.strokeRoundedSlidersVertical,
                          size: 15,
                          color: isSelected
                              ? theme.colorScheme.secondary
                              : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                p.name,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected
                                      ? theme.colorScheme.secondary
                                      : theme.colorScheme.onSurface,
                                ),
                              ),
                              Text(
                                p.description,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
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
                );
              }

              return items;
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: StudioSurfaceTheme.surface(context, isSolid: isSolid),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: StudioSurfaceTheme.tintedContainer(
                        context,
                        (activePreset != null ? theme.colorScheme.primary : theme.colorScheme.onSurface),
                        isSolid: isSolid,
                        translucentAlpha: 0.12,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: HugeIcon(
                      icon: isCustomActive
                          ? HugeIcons.strokeRoundedBookmark02
                          : (isGenrePreset
                              ? HugeIcons.strokeRoundedSparkles
                              : (activePreset != null
                                  ? HugeIcons.strokeRoundedSlidersVertical
                                  : HugeIcons.strokeRoundedAudioWaveform)),
                      size: 16,
                      color: activePreset != null
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                displayName,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: StudioSurfaceTheme.tintedContainer(
                                  context,
                                  (isCustomActive
                                      ? const Color(0xFF00E676)
                                      : (isGenrePreset
                                          ? theme.colorScheme.tertiary
                                          : (activePreset != null
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.outline))),
                                  isSolid: isSolid,
                                  translucentAlpha: 0.15,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                isCustomActive
                                    ? 'CUSTOM'
                                    : (isGenrePreset ? 'GENRE' : (activePreset != null ? 'PRESET' : 'MANUAL')),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                  color: isCustomActive
                                      ? const Color(0xFF00E676)
                                      : (isGenrePreset
                                          ? theme.colorScheme.tertiary
                                          : (activePreset != null
                                              ? theme.colorScheme.primary
                                              : theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          activePreset?.description ?? 'Custom dialed hardware parameters',
                          style: TextStyle(
                            fontSize: 10.5,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isCustomActive)
                    IconButton(
                      icon: const HugeIcon(
                        icon: HugeIcons.strokeRoundedDelete02,
                        size: 15,
                        color: Colors.redAccent,
                      ),
                      tooltip: 'Delete Profile',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => _showDeleteProfileDialog(context, controller, activePreset!, isSolid),
                    ),
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowDown01,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProQStudioBanner(BuildContext context, bool isSolid) {
    final theme = Theme.of(context);
    final proQColor = StudioCategoryColors.proQEqualizer;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surface(context, isSolid: isSolid),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isSolid
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            AppHaptics.lightImpact();
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const ProQStudioScreen()));
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: StudioSurfaceTheme.tintedContainer(
                      context,
                      proQColor,
                      isSolid: isSolid,
                      translucentAlpha: 0.16,
                      solidBlendAlpha: 0.2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedSlidersVertical,
                      color: proQColor,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: proQColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'PRO-Q STUDIO EQ',
                            style: TextStyle(
                              color: proQColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '10-Band Biquad Parametric Equalizer',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: StudioSurfaceTheme.tintedContainer(
                      context,
                      proQColor,
                      isSolid: isSolid,
                      translucentAlpha: 0.16,
                      solidBlendAlpha: 0.2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'OPEN',
                        style: TextStyle(
                          color: proQColor,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.6,
                        ),
                      ),
                      const SizedBox(width: 4),
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowRight01,
                        size: 13,
                        color: proQColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHardwareDacBanner(BuildContext context, bool isSolid) {
    final theme = Theme.of(context);
    final dacAccentColor = theme.colorScheme.tertiary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surface(context, isSolid: isSolid),
        borderRadius: BorderRadius.circular(16),
        boxShadow: isSolid
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            AppHaptics.lightImpact();
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const HardwareDacStudioScreen(),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: StudioSurfaceTheme.tintedContainer(
                      context,
                      dacAccentColor,
                      isSolid: isSolid,
                      translucentAlpha: 0.16,
                      solidBlendAlpha: 0.2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedUsb,
                      color: dacAccentColor,
                      size: 24,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: dacAccentColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'HARDWARE DAC BRIDGE',
                              style: TextStyle(
                                color: dacAccentColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Kiwi Ears AD1 & Universal DSP Flasher',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Direct USB HID 5-band hardware tuning & flash',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: StudioSurfaceTheme.tintedContainer(
                      context,
                      dacAccentColor,
                      isSolid: isSolid,
                      translucentAlpha: 0.16,
                      solidBlendAlpha: 0.2,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'CONNECT',
                        style: TextStyle(
                          color: dacAccentColor,
                          fontSize: 10.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 3),
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowRight01,
                        size: 12,
                        color: dacAccentColor,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showResetConfirmationDialog(
    BuildContext context,
    DspRackController controller,
    bool isSolid,
  ) {
    final theme = Theme.of(context);

    AppHaptics.lightImpact();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: StudioSurfaceTheme.surface(dialogCtx, isSolid: isSolid),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        icon: const HugeIcon(
          icon: HugeIcons.strokeRoundedAlert02,
          size: 28,
          color: Color(0xFFFF9500),
        ),
        title: Text(
          'RESET DSP RACK',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.8,
            color: theme.colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        content: Text(
          'Are you sure you want to reset all 10+ mastering modules (Pre-Amp, Tube Exciter, Dynamic Compressor, Bass Boost, Crossfeed, Limiter) back to 0 dB flat studio reference?',
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            height: 1.4,
          ),
          textAlign: TextAlign.center,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(
              'CANCEL',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
              ),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFFF9500),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              AppHaptics.mediumImpact();
              Navigator.of(dialogCtx).pop();
              controller.resetToDefaults();
            },
            child: const Text(
              'RESET ALL',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickGainChip(
    BuildContext context,
    String label,
    double gainDb,
    double currentDb,
    DspRackController controller,
    bool isSolid,
  ) {
    final isSelected = (currentDb - gainDb).abs() < 0.05;
    final theme = Theme.of(context);
    final accent = const Color(0xFF00E676);

    return InkWell(
      onTap: () {
        AppHaptics.selectionClick();
        controller.setPreamp(gainDb);
      },
      borderRadius: BorderRadius.circular(6),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? StudioSurfaceTheme.tintedContainer(
                  context,
                  accent,
                  isSolid: isSolid,
                  translucentAlpha: 0.18,
                  solidBlendAlpha: 0.2,
                )
              : StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? accent : theme.colorScheme.onSurface.withValues(alpha: 0.75),
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }

  void _showSaveProfileDialog(
    BuildContext context,
    DspRackController controller,
    bool isSolid,
  ) {
    final textController = TextEditingController(text: 'My Studio Mastering');
    final descController = TextEditingController();
    final theme = Theme.of(context);

    AppHaptics.lightImpact();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: StudioSurfaceTheme.surface(dialogCtx, isSolid: isSolid),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: StudioSurfaceTheme.outline(dialogCtx, isSolid: isSolid), width: 1.0),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: StudioSurfaceTheme.tintedContainer(
                  dialogCtx,
                  theme.colorScheme.primary,
                  isSolid: isSolid,
                  translucentAlpha: 0.15,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: HugeIcon(
                icon: HugeIcons.strokeRoundedFloppyDisk,
                size: 18,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Save DSP Profile',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Save your active hardware module chain (Pre-Amp, Tube, Bass, Compressor, Stereo Width, Reverb, Limiter).',
              style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurface.withValues(alpha: 0.7)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: textController,
              autofocus: true,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              decoration: InputDecoration(
                labelText: 'Profile Name',
                hintText: 'e.g. Warm Tube Acoustic',
                isDense: true,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('CANCEL'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final name = textController.text.trim();
              if (name.isNotEmpty) {
                await controller.saveCustomProfile(name, description: descController.text.trim());
                if (context.mounted) {
                  Navigator.of(dialogCtx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('DSP Profile "$name" saved successfully!'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                }
              }
            },
            child: const Text('SAVE PROFILE', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteProfileDialog(
    BuildContext context,
    DspRackController controller,
    DspPreset preset,
    bool isSolid,
  ) {
    AppHaptics.lightImpact();
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: StudioSurfaceTheme.surface(dialogCtx, isSolid: isSolid),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: StudioSurfaceTheme.outline(dialogCtx, isSolid: isSolid), width: 1.0),
        ),
        title: const Text('Delete DSP Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete "${preset.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('CANCEL'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFFF3B30)),
            onPressed: () async {
              await controller.deleteCustomProfile(preset.id);
              if (context.mounted) {
                Navigator.of(dialogCtx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Profile "${preset.name}" deleted.'),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: const Text('DELETE'),
          ),
        ],
      ),
    );
  }
}
