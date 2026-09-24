import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/dsp_models.dart';
import 'controllers/dsp_rack_controller.dart';
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
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: primaryColor.withValues(alpha: 0.4)),
              ),
              child: Icon(Icons.tune_rounded, color: primaryColor, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'MASTERING DSP RACK',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                Text(
                  'C++ Low-Latency Processing Engine',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Reset Rack Button
          IconButton(
            icon: const Icon(Icons.restart_alt_rounded),
            tooltip: 'Reset to Flat Reference',
            onPressed: () => controller.resetToDefaults(),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
        children: [
          // 1. MASTER HEADER & A/B COMPARISON STRIP
          _buildMasterSection(context, dspState, controller),
          const SizedBox(height: 16),

          // 2. STUDIO PRESETS SELECTOR
          _buildPresetsSelector(context, dspState, controller),
          const SizedBox(height: 20),

          // UNIT 01: PRE-AMP GAIN STAGE
          RackUnitCard(
            unitNumber: '01',
            title: 'Pre-Amp Gain Stage',
            subtitle: 'Headroom Input Level & Digital Protection',
            isActive: !dspState.isBypassed,
            onToggle: () {},
            accentColor: const Color(0xFF00E676),
            headerTrailing: TextButton.icon(
              onPressed: () => controller.setPreamp(0.0),
              icon: const Icon(Icons.refresh, size: 14),
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
                  formattedValue: '${dspState.preampDb >= 0 ? '+' : ''}${dspState.preampDb.toStringAsFixed(1)} dB',
                  onChanged: (val) => controller.setPreamp(val),
                  accentColor: const Color(0xFF00E676),
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
            accentColor: const Color(0xFF00F0FF),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RackKnobSlider(
                  label: 'Bass Boost Intensity',
                  value: dspState.bassBoostAmount,
                  min: 0.0,
                  max: 10.0,
                  formattedValue: '${dspState.bassBoostAmount.toStringAsFixed(1)}x',
                  onChanged: (val) => controller.setBassBoostAmount(val),
                  accentColor: const Color(0xFF00F0FF),
                ),
                const SizedBox(height: 8),
                RackKnobSlider(
                  label: 'Boost Mix (Wet/Dry)',
                  value: dspState.bassBoostWet,
                  min: 0.0,
                  max: 1.0,
                  formattedValue: '${(dspState.bassBoostWet * 100).toInt()}%',
                  onChanged: (val) => controller.setBassBoostWet(val),
                  accentColor: const Color(0xFF00F0FF),
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
            accentColor: const Color(0xFFFF9F0A),
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
                  accentColor: const Color(0xFFFF9F0A),
                ),
                const SizedBox(height: 8),
                RackKnobSlider(
                  label: 'Harmonic Warmth',
                  value: dspState.tubeWarmth,
                  min: 0.0,
                  max: 1.0,
                  formattedValue: '${(dspState.tubeWarmth * 100).toInt()}%',
                  onChanged: (val) => controller.setTubeWarmth(val),
                  accentColor: const Color(0xFFFF9F0A),
                ),
                const SizedBox(height: 8),
                RackKnobSlider(
                  label: 'Saturation Mix',
                  value: dspState.tubeMix,
                  min: 0.0,
                  max: 1.0,
                  formattedValue: '${(dspState.tubeMix * 100).toInt()}%',
                  onChanged: (val) => controller.setTubeMix(val),
                  accentColor: const Color(0xFFFF9F0A),
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
            accentColor: const Color(0xFFFFB300),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                GainReductionMeter(
                  gainReductionDb: (!dspState.isBypassed && dspState.compressorEnabled)
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
                  formattedValue: '${dspState.compThreshold.toStringAsFixed(1)} dB',
                  onChanged: (val) => controller.setCompThreshold(val),
                  accentColor: const Color(0xFFFFB300),
                ),
                const SizedBox(height: 8),
                RackKnobSlider(
                  label: 'Compression Ratio',
                  value: dspState.compRatio,
                  min: 1.0,
                  max: 10.0,
                  formattedValue: '${dspState.compRatio.toStringAsFixed(1)}:1',
                  onChanged: (val) => controller.setCompRatio(val),
                  accentColor: const Color(0xFFFFB300),
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
                        formattedValue: '${dspState.compAttack.toStringAsFixed(0)} ms',
                        onChanged: (val) => controller.setCompAttack(val),
                        accentColor: const Color(0xFFFFB300),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RackKnobSlider(
                        label: 'Release',
                        value: dspState.compRelease,
                        min: 10.0,
                        max: 1000.0,
                        formattedValue: '${dspState.compRelease.toStringAsFixed(0)} ms',
                        onChanged: (val) => controller.setCompRelease(val),
                        accentColor: const Color(0xFFFFB300),
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
                  formattedValue: '${dspState.compMakeup >= 0 ? '+' : ''}${dspState.compMakeup.toStringAsFixed(1)} dB',
                  onChanged: (val) => controller.setCompMakeup(val),
                  accentColor: const Color(0xFFFFB300),
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
            accentColor: const Color(0xFFBF5AF2),
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
                  accentColor: const Color(0xFFBF5AF2),
                ),
                const SizedBox(height: 8),
                RackKnobSlider(
                  label: 'Center Mid-Gain',
                  value: dspState.stereoMidGain,
                  min: 0.0,
                  max: 2.0,
                  formattedValue: '${(dspState.stereoMidGain * 100).toInt()}%',
                  onChanged: (val) => controller.setStereoMidGain(val),
                  accentColor: const Color(0xFFBF5AF2),
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
            accentColor: const Color(0xFF00E676),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RackKnobSlider(
                  label: 'Cutoff Frequency',
                  value: dspState.crossfeedCutoff,
                  min: 200.0,
                  max: 2000.0,
                  formattedValue: '${dspState.crossfeedCutoff.toStringAsFixed(0)} Hz',
                  onChanged: (val) => controller.setCrossfeedCutoff(val),
                  accentColor: const Color(0xFF00E676),
                ),
                const SizedBox(height: 8),
                RackKnobSlider(
                  label: 'Crosstalk Feed Level',
                  value: dspState.crossfeedFeed,
                  min: -24.0,
                  max: 0.0,
                  formattedValue: '${dspState.crossfeedFeed.toStringAsFixed(1)} dB',
                  onChanged: (val) => controller.setCrossfeedFeed(val),
                  accentColor: const Color(0xFF00E676),
                ),
                const SizedBox(height: 8),
                RackKnobSlider(
                  label: 'Interaural Time Delay',
                  value: dspState.crossfeedDelayMs,
                  min: 0.05,
                  max: 1.0,
                  formattedValue: '${(dspState.crossfeedDelayMs * 1000).toStringAsFixed(0)} µs',
                  onChanged: (val) => controller.setCrossfeedDelay(val),
                  accentColor: const Color(0xFF00E676),
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
            accentColor: const Color(0xFF64B5F6),
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
                  accentColor: const Color(0xFF64B5F6),
                ),
                const SizedBox(height: 8),
                RackKnobSlider(
                  label: 'High-Freq Damping',
                  value: dspState.reverbDamp,
                  min: 0.0,
                  max: 1.0,
                  formattedValue: '${(dspState.reverbDamp * 100).toInt()}%',
                  onChanged: (val) => controller.setReverbDamp(val),
                  accentColor: const Color(0xFF64B5F6),
                ),
                const SizedBox(height: 8),
                RackKnobSlider(
                  label: 'Wet Space Mix',
                  value: dspState.reverbWet,
                  min: 0.0,
                  max: 1.0,
                  formattedValue: '${(dspState.reverbWet * 100).toInt()}%',
                  onChanged: (val) => controller.setReverbWet(val),
                  accentColor: const Color(0xFF64B5F6),
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
            accentColor: const Color(0xFFE040FB),
            headerTrailing: TextButton.icon(
              onPressed: () => controller.setPitchSemitones(0.0),
              icon: const Icon(Icons.refresh, size: 14),
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
                  formattedValue: '${dspState.pitchSemitones >= 0 ? '+' : ''}${dspState.pitchSemitones.toStringAsFixed(1)} st',
                  onChanged: (val) => controller.setPitchSemitones(val),
                  accentColor: const Color(0xFFE040FB),
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
            accentColor: const Color(0xFFFF3B30),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RackKnobSlider(
                  label: 'Threshold / Drive',
                  value: dspState.limiterThreshold,
                  min: -60.0,
                  max: 0.0,
                  formattedValue: '${dspState.limiterThreshold.toStringAsFixed(1)} dB',
                  onChanged: (val) => controller.setLimiterThreshold(val),
                  accentColor: const Color(0xFFFF3B30),
                ),
                const SizedBox(height: 8),
                RackKnobSlider(
                  label: 'Output Ceiling (True Peak)',
                  value: dspState.limiterOutputCeiling,
                  min: -60.0,
                  max: 0.0,
                  formattedValue: '${dspState.limiterOutputCeiling.toStringAsFixed(1)} dBFS',
                  onChanged: (val) => controller.setLimiterCeiling(val),
                  accentColor: const Color(0xFFFF3B30),
                ),
                const SizedBox(height: 8),
                RackKnobSlider(
                  label: 'Release Recovery',
                  value: dspState.limiterRelease,
                  min: 1.0,
                  max: 1000.0,
                  formattedValue: '${dspState.limiterRelease.toStringAsFixed(0)} ms',
                  onChanged: (val) => controller.setLimiterRelease(val),
                  accentColor: const Color(0xFFFF3B30),
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
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161A22) : const Color(0xFFE9EDF5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: state.isBypassed
              ? (isDark ? Colors.white10 : Colors.black12)
              : primaryColor.withValues(alpha: 0.5),
          width: 1.5,
        ),
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
                            ? Colors.orangeAccent
                            : const Color(0xFF00E676),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // A/B Comparison Switch
              InkWell(
                onTap: () => controller.toggleBypass(),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: state.isBypassed
                        ? Colors.orange.withValues(alpha: 0.15)
                        : const Color(0xFF00E676).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: state.isBypassed
                          ? Colors.orangeAccent
                          : const Color(0xFF00E676),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        state.isBypassed ? Icons.block_rounded : Icons.check_circle_rounded,
                        size: 16,
                        color: state.isBypassed ? Colors.orangeAccent : const Color(0xFF00E676),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        state.isBypassed ? 'A: RAW (BYPASSED)' : 'B: DSP ACTIVE',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: state.isBypassed ? Colors.orangeAccent : const Color(0xFF00E676),
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

  /// Preset selector horizontal chips
  Widget _buildPresetsSelector(
    BuildContext context,
    DspRackState state,
    DspRackController controller,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final presets = DspPreset.studioPresets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.auto_awesome,
              size: 14,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 6),
            Text(
              'STUDIO PRESETS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: presets.map((p) {
              final isSelected = state.activePresetId == p.id;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  selected: isSelected,
                  label: Text(p.name),
                  labelStyle: TextStyle(
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected
                        ? (isDark ? Colors.white : Colors.black)
                        : theme.colorScheme.onSurface.withValues(alpha: 0.75),
                  ),
                  onSelected: (_) => controller.applyPreset(p),
                  selectedColor: theme.colorScheme.primary.withValues(alpha: 0.25),
                  side: BorderSide(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : (isDark ? Colors.white12 : Colors.black12),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
