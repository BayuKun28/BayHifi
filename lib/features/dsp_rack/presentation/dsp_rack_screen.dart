import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../../core/widgets/two_tone_header.dart';
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
import '../../../../core/widgets/meta_tracking_label.dart';

/// DSP Unit Category Filter for Clean Uncluttered Navigation
enum DspCategoryFilter {
  all('All Modules (10)', LucideIcons.slidersHorizontal),
  dynamics('Dynamics', LucideIcons.audioLines),
  tone('Tone & EQ', LucideIcons.sliders),
  spatial('Spatial & Tube', LucideIcons.speaker);

  final String label;
  final IconData icon;
  const DspCategoryFilter(this.label, this.icon);
}

/// Halaman Mastering DSP Studio Rack (10+ Modul Hardware Audio)
class DspRackScreen extends ConsumerStatefulWidget {
  const DspRackScreen({super.key});

  @override
  ConsumerState<DspRackScreen> createState() => _DspRackScreenState();
}

class _DspRackScreenState extends ConsumerState<DspRackScreen> {
  DspCategoryFilter _selectedFilter = DspCategoryFilter.all;

  @override
  Widget build(BuildContext context) {
    final dspState = ref.watch(dspRackControllerProvider);
    final controller = ref.read(dspRackControllerProvider.notifier);
    final currentTrack =
        ref.watch(playerControllerProvider.select((s) => s.currentTrack));
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isSolid = ref.isSolidStyle;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 18,
        title: const TwoToneHeader(
          primaryText: 'MASTERING',
          accentText: 'DSP',
          fontSize: 18,
        ),
        actions: [
          // Save Custom DSP Profile Button
          IconButton(
            icon: Icon(
              LucideIcons.save,
              size: 20,
              color: primaryColor,
            ),
            tooltip: 'Save Custom DSP Profile',
            onPressed: () => _showSaveProfileDialog(context, controller, isSolid),
          ),
          // Reset Rack Button with Confirmation Modal
          IconButton(
            icon: const Icon(
              LucideIcons.refreshCw,
              size: 20,
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
          // 0. DUAL QUICK LAUNCHERS (PRO-Q & HARDWARE DAC)
          _buildStudioLaunchersRow(context, isSolid, primaryColor),
          const SizedBox(height: 12),

          // 1. UNIFIED COMPACT MASTER CONTROL DECK
          _buildMasterSection(
            context,
            dspState,
            controller,
            isSolid,
            currentTrack: currentTrack,
          ),
          const SizedBox(height: 14),

          // 2. CATEGORY FILTER BAR (All / Dynamics / Tone & EQ / Spatial & Tube)
          _buildCategoryFilterRow(context, primaryColor, isSolid),
          const SizedBox(height: 16),

          // UNIT 01: PRE-AMP GAIN STAGE (Dynamics)
          if (_selectedFilter == DspCategoryFilter.all || _selectedFilter == DspCategoryFilter.dynamics)
            RackUnitCard(
              unitNumber: '01',
              title: 'Pre-Amp Gain Stage',
              subtitle: 'Headroom Input Level & Digital Protection',
              isActive: !dspState.isBypassed,
              initiallyExpanded: dspState.preampDb != 0.0,
              onToggle: () {},
              accentColor: primaryColor,
            headerTrailing: TextButton.icon(
              onPressed: () => controller.setPreamp(0.0),
              icon: const Icon(
                LucideIcons.refreshCw,
                size: 14,
              ),
              label: const Text('0 dB', style: TextStyle(fontSize: 11)),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
            ),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RepaintBoundary(
                  child: VuLevelMeter(
                    levelDb: dspState.isBypassed ? 0.0 : dspState.preampDb,
                  ),
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
                  accentColor: primaryColor,
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

          // UNIT 02: DYNAMIC BASS BOOST (Tone & EQ)
          if (_selectedFilter == DspCategoryFilter.all || _selectedFilter == DspCategoryFilter.tone)
            RackUnitCard(
            unitNumber: '02',
            title: 'Dynamic Bass Boost',
            subtitle: 'Psychoacoustic Sub-Bass Impact (40 - 160 Hz)',
            isActive: !dspState.isBypassed && dspState.bassBoostEnabled,
            initiallyExpanded: dspState.bassBoostEnabled,
            onToggle: () => controller.toggleBassBoost(),
            accentColor: primaryColor,
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
                  accentColor: primaryColor,
                ),
                const SizedBox(height: 8),
                RackKnobSlider(
                  label: 'Boost Mix (Wet/Dry)',
                  value: dspState.bassBoostWet,
                  min: 0.0,
                  max: 1.0,
                  formattedValue: '${(dspState.bassBoostWet * 100).toInt()}%',
                  onChanged: (val) => controller.setBassBoostWet(val),
                  accentColor: primaryColor,
                ),
              ],
            ),
          ),

          // UNIT 03: TUBE EXCITER / TRIODE SATURATION (Spatial & Tube)
          if (_selectedFilter == DspCategoryFilter.all || _selectedFilter == DspCategoryFilter.spatial)
            RackUnitCard(
            unitNumber: '03',
            title: 'Tube Harmonic Exciter',
            subtitle: 'Analog Triode Saturation y = tanh(k · x)',
            isActive: !dspState.isBypassed && dspState.tubeExciterEnabled,
            initiallyExpanded: dspState.tubeExciterEnabled,
            onToggle: () => controller.toggleTubeExciter(),
            accentColor: primaryColor,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RepaintBoundary(
                  child: TubeGlowIndicator(
                    drive: dspState.tubeDrive,
                    warmth: dspState.tubeWarmth,
                    isActive: !dspState.isBypassed && dspState.tubeExciterEnabled,
                  ),
                ),
                const SizedBox(height: 12),
                RackKnobSlider(
                  label: 'Tube Drive',
                  value: dspState.tubeDrive,
                  min: 0.0,
                  max: 10.0,
                  formattedValue: '${dspState.tubeDrive.toStringAsFixed(1)}x',
                  onChanged: (val) => controller.setTubeDrive(val),
                  accentColor: primaryColor,
                ),
                const SizedBox(height: 8),
                RackKnobSlider(
                  label: 'Harmonic Warmth',
                  value: dspState.tubeWarmth,
                  min: 0.0,
                  max: 1.0,
                  formattedValue: '${(dspState.tubeWarmth * 100).toInt()}%',
                  onChanged: (val) => controller.setTubeWarmth(val),
                  accentColor: primaryColor,
                ),
                const SizedBox(height: 8),
                RackKnobSlider(
                  label: 'Saturation Mix',
                  value: dspState.tubeMix,
                  min: 0.0,
                  max: 1.0,
                  formattedValue: '${(dspState.tubeMix * 100).toInt()}%',
                  onChanged: (val) => controller.setTubeMix(val),
                  accentColor: primaryColor,
                ),
              ],
            ),
          ),

          // UNIT 04: DYNAMIC COMPRESSOR (Dynamics)
          if (_selectedFilter == DspCategoryFilter.all || _selectedFilter == DspCategoryFilter.dynamics)
            RackUnitCard(
            unitNumber: '04',
            title: 'Dynamic Compressor',
            subtitle: 'Studio Dynamic Range Transient Sculptor',
            isActive: !dspState.isBypassed && dspState.compressorEnabled,
            initiallyExpanded: dspState.compressorEnabled,
            onToggle: () => controller.toggleCompressor(),
            accentColor: primaryColor,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RepaintBoundary(
                  child: GainReductionMeter(
                    gainReductionDb:
                        (!dspState.isBypassed && dspState.compressorEnabled)
                        ? (dspState.compThreshold * 0.4).clamp(-20.0, 0.0)
                        : 0.0,
                    isActive: !dspState.isBypassed && dspState.compressorEnabled,
                  ),
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
                  accentColor: primaryColor,
                ),
                const SizedBox(height: 8),
                RackKnobSlider(
                  label: 'Compression Ratio',
                  value: dspState.compRatio,
                  min: 1.0,
                  max: 10.0,
                  formattedValue: '${dspState.compRatio.toStringAsFixed(1)}:1',
                  onChanged: (val) => controller.setCompRatio(val),
                  accentColor: primaryColor,
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
                        accentColor: primaryColor,
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
                        accentColor: primaryColor,
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
                  accentColor: primaryColor,
                ),
              ],
            ),
          ),

          // UNIT 05: STEREO WIDTH (Spatial & Tube)
          if (_selectedFilter == DspCategoryFilter.all || _selectedFilter == DspCategoryFilter.spatial)
            RackUnitCard(
            unitNumber: '05',
            title: 'Mid-Side Stereo Widener',
            subtitle: 'Soundstage Matrix M = (L+R)/2, S = (L-R)/2',
            isActive: !dspState.isBypassed && dspState.stereoWidthEnabled,
            initiallyExpanded: dspState.stereoWidthEnabled,
            onToggle: () => controller.toggleStereoWidth(),
            accentColor: primaryColor,
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                RepaintBoundary(
                  child: SoundstageWidthVisualizer(
                    widthFactor: dspState.stereoWidth,
                    isActive: !dspState.isBypassed && dspState.stereoWidthEnabled,
                  ),
                ),
                const SizedBox(height: 12),
                RackKnobSlider(
                  label: 'Soundstage Width Factor',
                  value: dspState.stereoWidth,
                  min: 0.0,
                  max: 3.0,
                  formattedValue: '${(dspState.stereoWidth * 100).toInt()}%',
                  onChanged: (val) => controller.setStereoWidth(val),
                  accentColor: primaryColor,
                ),
                const SizedBox(height: 8),
                RackKnobSlider(
                  label: 'Center Mid-Gain',
                  value: dspState.stereoMidGain,
                  min: 0.0,
                  max: 2.0,
                  formattedValue: '${(dspState.stereoMidGain * 100).toInt()}%',
                  onChanged: (val) => controller.setStereoMidGain(val),
                  accentColor: primaryColor,
                ),
              ],
            ),
          ),

          // UNIT 06: BINAURAL CROSSFEED (Spatial & Tube)
          if (_selectedFilter == DspCategoryFilter.all || _selectedFilter == DspCategoryFilter.spatial)
            RackUnitCard(
            unitNumber: '06',
            title: 'Bauer Binaural Crossfeed',
            subtitle: 'Acoustic Headphone Simulation (Reduces Fatigue)',
            isActive: !dspState.isBypassed && dspState.crossfeedEnabled,
            initiallyExpanded: dspState.crossfeedEnabled,
            onToggle: () => controller.toggleCrossfeed(),
            accentColor: primaryColor,
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
                  accentColor: primaryColor,
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
                  accentColor: primaryColor,
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
                  accentColor: primaryColor,
                ),
              ],
            ),
          ),

          // UNIT 07: SPATIAL STUDIO REVERB (Spatial & Tube)
          if (_selectedFilter == DspCategoryFilter.all || _selectedFilter == DspCategoryFilter.spatial)
            RackUnitCard(
            unitNumber: '07',
            title: 'Spatial Studio Reverb',
            subtitle: 'Freeverb 3D Acoustic Space & Room Reflection',
            isActive: !dspState.isBypassed && dspState.reverbEnabled,
            initiallyExpanded: dspState.reverbEnabled,
            onToggle: () => controller.toggleReverb(),
            accentColor: primaryColor,
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
                  accentColor: primaryColor,
                ),
                const SizedBox(height: 8),
                RackKnobSlider(
                  label: 'High-Freq Damping',
                  value: dspState.reverbDamp,
                  min: 0.0,
                  max: 1.0,
                  formattedValue: '${(dspState.reverbDamp * 100).toInt()}%',
                  onChanged: (val) => controller.setReverbDamp(val),
                  accentColor: primaryColor,
                ),
                const SizedBox(height: 8),
                RackKnobSlider(
                  label: 'Wet Space Mix',
                  value: dspState.reverbWet,
                  min: 0.0,
                  max: 1.0,
                  formattedValue: '${(dspState.reverbWet * 100).toInt()}%',
                  onChanged: (val) => controller.setReverbWet(val),
                  accentColor: primaryColor,
                ),
              ],
            ),
          ),

          // UNIT 08: PITCH SHIFTER ENGINE (Tone & EQ)
          if (_selectedFilter == DspCategoryFilter.all || _selectedFilter == DspCategoryFilter.tone)
            RackUnitCard(
            unitNumber: '08',
            title: 'Granular Pitch Shifter',
            subtitle: 'Real-Time Chromatic Pitch Shift (Tempo Invariant)',
            isActive: !dspState.isBypassed && dspState.pitchShiftEnabled,
            initiallyExpanded: dspState.pitchShiftEnabled,
            onToggle: () => controller.togglePitchShift(),
            accentColor: primaryColor,
            headerTrailing: TextButton.icon(
              onPressed: () => controller.setPitchSemitones(0.0),
              icon: const Icon(
                LucideIcons.refreshCw,
                size: 14,
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
                  accentColor: primaryColor,
                ),
              ],
            ),
          ),

          // UNIT 09: PEAK BRICKWALL LIMITER (Dynamics)
          if (_selectedFilter == DspCategoryFilter.all || _selectedFilter == DspCategoryFilter.dynamics)
            RackUnitCard(
            unitNumber: '09',
            title: 'Peak Brickwall Limiter',
            subtitle: 'Zero-Overshoot Anti-Clipping Lookahead Safety',
            isActive: !dspState.isBypassed && dspState.limiterEnabled,
            initiallyExpanded: dspState.limiterEnabled,
            onToggle: () => controller.toggleLimiter(),
            accentColor: primaryColor,
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
                  accentColor: primaryColor,
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
                  accentColor: primaryColor,
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
                  accentColor: primaryColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Master Header Strip dengan preset switcher, bypass capsule, dan wet/dry blend
  Widget _buildMasterSection(
    BuildContext context,
    DspRackState state,
    DspRackController controller,
    bool isSolid, {
    Track? currentTrack,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.primary;

    final studioPresets = DspPreset.studioPresets;
    final customPresets = controller.customPresets;

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

    final displayName = activePreset?.name ?? 'Manual Tuning (Customized)';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16181F) : theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF262936) : theme.colorScheme.outlineVariant,
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Row 1: Preset Pill & Bypass Switch ──
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const MetaTrackingLabel(
                      'MASTERING DSP ENGINE',
                      fontSize: 10,
                      letterSpacing: 1.2,
                    ),
                    const SizedBox(height: 4),
                    // Preset Selector Dropdown Button
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
                      offset: const Offset(0, 36),
                      onSelected: (val) {
                        if (val is DspPreset) {
                          controller.applyPreset(val);
                        } else if (val == '__SAVE_NEW__') {
                          _showSaveProfileDialog(context, controller, isSolid);
                        }
                      },
                      itemBuilder: (context) {
                        final items = <PopupMenuEntry<dynamic>>[];
                        items.add(
                          PopupMenuItem<dynamic>(
                            value: '__SAVE_NEW__',
                            child: Row(
                              children: [
                                Icon(
                                  LucideIcons.save,
                                  size: 14,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                const Text(
                                  '+ Save Current Profile...',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        );
                        items.add(const PopupMenuDivider());
                        for (final p in customPresets) {
                          items.add(PopupMenuItem<dynamic>(
                            value: p,
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text('Custom: ${p.name}', style: const TextStyle(fontSize: 12)),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    LucideIcons.trash2,
                                    size: 13,
                                    color: Colors.redAccent,
                                  ),
                                  tooltip: 'Delete Profile',
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                    _showDeleteProfileDialog(context, controller, p, isSolid);
                                  },
                                ),
                              ],
                            ),
                          ));
                        }
                        for (final p in studioPresets) {
                          items.add(PopupMenuItem<dynamic>(
                            value: p,
                            child: Text(p.name, style: const TextStyle(fontSize: 12)),
                          ));
                        }
                        return items;
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.3),
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.sparkles,
                              size: 13,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                displayName,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.onSurface,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              LucideIcons.chevronDown,
                              size: 13,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 10),

              // Master Bypass Button
              InkWell(
                onTap: () => controller.toggleBypass(),
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: state.isBypassed
                        ? (isDark ? const Color(0xFF1E212B) : theme.colorScheme.surfaceContainerHighest)
                        : (isDark ? const Color(0xFF252834) : theme.colorScheme.primaryContainer),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: state.isBypassed
                          ? (isDark ? const Color(0xFF262936) : theme.colorScheme.outlineVariant)
                          : (isDark ? const Color(0xFF383D50) : theme.colorScheme.primary.withValues(alpha: 0.5)),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        state.isBypassed
                            ? LucideIcons.ban
                            : LucideIcons.checkCircle2,
                        size: 14,
                        color: state.isBypassed
                            ? (isDark ? const Color(0xFF64748B) : theme.colorScheme.onSurfaceVariant)
                            : (isDark ? Colors.white : theme.colorScheme.onPrimaryContainer),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        state.isBypassed ? 'BYPASSED' : 'DSP ACTIVE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: state.isBypassed
                              ? (isDark ? const Color(0xFF94A3B8) : theme.colorScheme.onSurfaceVariant)
                              : (isDark ? Colors.white : theme.colorScheme.onPrimaryContainer),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Row 2: Master Wet/Dry Blend Slider & Quick Actions ──
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: RackKnobSlider(
                  label: 'Master Wet / Dry',
                  value: state.masterWet,
                  min: 0.0,
                  max: 1.0,
                  formattedValue: '${(state.masterWet * 100).toInt()}% WET',
                  onChanged: (val) => controller.setMasterWet(val),
                  accentColor: primaryColor,
                ),
              ),
              const SizedBox(width: 10),
              // Genre Rules shortcut aligned with slider track baseline
              Padding(
                padding: const EdgeInsets.only(bottom: 4.0),
                child: Tooltip(
                  message: 'Auto Genre Rules',
                  child: InkWell(
                    onTap: () => GenreRulesConfigModal.show(context),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      width: 38,
                      height: 38,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                          width: 0.8,
                        ),
                      ),
                      child: Icon(
                        LucideIcons.slidersHorizontal,
                        size: 16,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // ── Row 3: Active Playing Track Status (if available) ──
          if (currentTrack != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.music,
                    size: 13,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Tuning: ${currentTrack.title} — ${currentTrack.artist}',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  InkWell(
                    onTap: () => StudioTrackDspPresetSheet.show(context, currentTrack),
                    borderRadius: BorderRadius.circular(4),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        'PIN / EDIT',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Category filter pills row for clean and breathable rack navigation
  Widget _buildCategoryFilterRow(BuildContext context, Color primaryColor, bool isSolid) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: DspCategoryFilter.values.map((filter) {
          final isSelected = _selectedFilter == filter;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: InkWell(
              onTap: () {
                AppHaptics.selectionClick();
                setState(() => _selectedFilter = filter);
              },
              borderRadius: BorderRadius.circular(20),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? const Color(0xFF252834) : theme.colorScheme.primaryContainer)
                      : (isDark ? const Color(0xFF16181F) : theme.colorScheme.surfaceContainer),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? (isDark ? const Color(0xFF383D50) : theme.colorScheme.primary.withValues(alpha: 0.4))
                        : (isDark ? const Color(0xFF262936) : theme.colorScheme.outlineVariant),
                    width: 0.8,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      filter.icon,
                      size: 13,
                      color: isSelected
                          ? (isDark ? Colors.white : theme.colorScheme.onPrimaryContainer)
                          : (isDark ? const Color(0xFF94A3B8) : theme.colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      filter.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected
                            ? (isDark ? Colors.white : theme.colorScheme.onPrimaryContainer)
                            : (isDark ? const Color(0xFF94A3B8) : theme.colorScheme.onSurfaceVariant),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }


  Widget _buildStudioLaunchersRow(BuildContext context, bool isSolid, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: _buildLauncherCard(
              context: context,
              title: 'PRO-Q EQ',
              subtitle: '10-Band Parametric',
              icon: LucideIcons.sliders,
              accentColor: primaryColor,
              isSolid: isSolid,
              onTap: () {
                AppHaptics.lightImpact();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProQStudioScreen()),
                );
              },
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _buildLauncherCard(
              context: context,
              title: 'HARDWARE DAC',
              subtitle: 'USB Bridge & Flash',
              icon: LucideIcons.cpu,
              accentColor: primaryColor,
              isSolid: isSolid,
              onTap: () {
                AppHaptics.lightImpact();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const HardwareDacStudioScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLauncherCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required bool isSolid,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: StudioSurfaceTheme.surface(context, isSolid: isSolid),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: accentColor.withValues(alpha: 0.18),
              width: 1.0,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Icon(icon, color: accentColor, size: 18),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                        color: accentColor,
                        letterSpacing: 0.6,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 9.5,
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
        icon: const Icon(
          LucideIcons.alertTriangle,
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
              child: Icon(
                LucideIcons.save,
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
