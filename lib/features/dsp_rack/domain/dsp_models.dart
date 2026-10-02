import 'package:flutter/foundation.dart';

/// Preset kurasi audiophile untuk DSP Mastering Rack
@immutable
class DspPreset {
  const DspPreset({
    required this.id,
    required this.name,
    required this.description,
    required this.state,
  });

  final String id;
  final String name;
  final String description;
  final DspRackState state;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'state': state.toMap(),
    };
  }

  factory DspPreset.fromMap(Map<String, dynamic> map) {
    return DspPreset(
      id: map['id'] as String? ?? 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: map['name'] as String? ?? 'Custom Preset',
      description: map['description'] as String? ?? '',
      state: DspRackState.fromMap(Map<String, dynamic>.from(map['state'] as Map? ?? {})),
    );
  }

  /// Curated studio presets collection
  static List<DspPreset> get studioPresets => [
        DspPreset(
          id: 'studio_warmth',
          name: 'Studio Audiophile Warmth',
          description: 'Baydev Signature Reference: Analog tube saturation & expansive soundstage.',
          state: const DspRackState(
            isBypassed: false,
            masterWet: 1.0,
            preampDb: -1.5,
            tubeExciterEnabled: true,
            tubeDrive: 1.2,
            tubeWarmth: 0.45,
            tubeMix: 0.18,
            stereoWidthEnabled: true,
            stereoWidth: 1.15,
            stereoMidGain: 1.05,
            stereoWet: 0.70,
            limiterEnabled: true,
            limiterThreshold: -2.5,
            limiterOutputCeiling: -0.5,
            activePresetId: 'studio_warmth',
          ),
        ),
        DspPreset(
          id: 'pure_direct',
          name: 'Audiophile Bit-Perfect',
          description: 'Direct passthrough without audio coloration (Flat Reference).',
          state: const DspRackState(
            isBypassed: false,
            masterWet: 1.0,
            preampDb: 0.0,
            tubeExciterEnabled: false,
            stereoWidthEnabled: false,
            limiterEnabled: true,
            limiterThreshold: -1.0,
            limiterOutputCeiling: -0.2,
            activePresetId: 'pure_direct',
          ),
        ),
        DspPreset(
          id: 'warm_tube',
          name: 'Warm Analog Tube Acoustic',
          description: 'Triode tube harmonic saturation with gentle analog warmth.',
          state: const DspRackState(
            isBypassed: false,
            masterWet: 1.0,
            preampDb: -1.5,
            tubeExciterEnabled: true,
            tubeDrive: 2.8,
            tubeWarmth: 0.65,
            tubeMix: 0.45,
            stereoWidthEnabled: false,
            limiterEnabled: true,
            limiterThreshold: -3.0,
            limiterOutputCeiling: -1.0,
            activePresetId: 'warm_tube',
          ),
        ),
        DspPreset(
          id: 'deep_bass',
          name: 'Deep Bass Sub-Impact',
          description: 'Psychoacoustic sub-bass impact with dynamic compressor control.',
          state: const DspRackState(
            isBypassed: false,
            masterWet: 1.0,
            preampDb: -2.5,
            tubeExciterEnabled: false,
            stereoWidthEnabled: false,
            bassBoostEnabled: true,
            bassBoostAmount: 3.8,
            bassBoostWet: 0.85,
            compressorEnabled: true,
            compThreshold: -12.0,
            compRatio: 2.5,
            compAttack: 20.0,
            compRelease: 120.0,
            compMakeup: 1.5,
            limiterEnabled: true,
            limiterThreshold: -3.0,
            limiterOutputCeiling: -1.0,
            activePresetId: 'deep_bass',
          ),
        ),
        DspPreset(
          id: 'spacious_cinema',
          name: 'Spacious Cinema Holographic',
          description: 'Holographic 3D soundstage with stereo crossfeed and concert hall reverb.',
          state: const DspRackState(
            isBypassed: false,
            masterWet: 1.0,
            preampDb: -2.0,
            tubeExciterEnabled: false,
            stereoWidthEnabled: true,
            stereoWidth: 1.55,
            crossfeedEnabled: true,
            crossfeedCutoff: 700.0,
            crossfeedFeed: -6.0,
            crossfeedDelayMs: 0.35,
            reverbEnabled: true,
            reverbRoomSize: 0.38,
            reverbDamp: 0.6,
            reverbWidth: 1.0,
            reverbWet: 0.22,
            limiterEnabled: true,
            limiterThreshold: -3.0,
            limiterOutputCeiling: -1.0,
            activePresetId: 'spacious_cinema',
          ),
        ),
        DspPreset(
          id: 'vocal_clarity',
          name: 'Mastering Vocal Clarity',
          description: 'Midrange vocal presence with transparent compression and Mid-channel boost.',
          state: const DspRackState(
            isBypassed: false,
            masterWet: 1.0,
            preampDb: -1.0,
            tubeExciterEnabled: false,
            stereoWidthEnabled: true,
            stereoWidth: 1.1,
            stereoMidGain: 1.3,
            compressorEnabled: true,
            compThreshold: -16.0,
            compRatio: 3.2,
            compAttack: 12.0,
            compRelease: 90.0,
            compMakeup: 2.0,
            limiterEnabled: true,
            limiterThreshold: -2.5,
            limiterOutputCeiling: -0.8,
            activePresetId: 'vocal_clarity',
          ),
        ),
        DspPreset(
          id: 'late_night_headphone',
          name: 'Late-Night Headphone Anti-Fatigue',
          description: 'Bauer Crossfeed speaker simulation to eliminate headphone ear fatigue.',
          state: const DspRackState(
            isBypassed: false,
            masterWet: 1.0,
            preampDb: -1.0,
            stereoWidthEnabled: false,
            crossfeedEnabled: true,
            crossfeedCutoff: 650.0,
            crossfeedFeed: -7.0,
            crossfeedDelayMs: 0.38,
            tubeExciterEnabled: true,
            tubeDrive: 1.2,
            tubeWarmth: 0.5,
            tubeMix: 0.25,
            limiterEnabled: true,
            limiterThreshold: -3.0,
            limiterOutputCeiling: -1.0,
            activePresetId: 'late_night_headphone',
          ),
        ),
        // ─── CURATED GENRE MASTERING PRESETS ───────────────────────────────────
        DspPreset(
          id: 'genre_rock',
          name: 'Dynamic Rock & Alternative',
          description: 'Punchy transient attack, crisp electric guitar bite & tight analog drive.',
          state: const DspRackState(
            isBypassed: false,
            masterWet: 1.0,
            preampDb: -1.5,
            tubeExciterEnabled: true,
            tubeDrive: 1.6,
            tubeWarmth: 0.35,
            tubeMix: 0.25,
            compressorEnabled: true,
            compThreshold: -10.0,
            compRatio: 3.0,
            compAttack: 15.0,
            compRelease: 85.0,
            compMakeup: 1.2,
            bassBoostEnabled: true,
            bassBoostAmount: 2.2,
            bassBoostWet: 0.75,
            stereoWidthEnabled: true,
            stereoWidth: 1.15,
            stereoMidGain: 1.05,
            stereoWet: 0.70,
            limiterEnabled: true,
            limiterThreshold: -2.5,
            limiterOutputCeiling: -0.5,
            activePresetId: 'genre_rock',
          ),
        ),
        DspPreset(
          id: 'genre_pop',
          name: 'Modern Pop & Commercial',
          description: 'High vocal presence, wide stereo soundstage, polished master compression.',
          state: const DspRackState(
            isBypassed: false,
            masterWet: 1.0,
            preampDb: -1.0,
            tubeExciterEnabled: true,
            tubeDrive: 1.1,
            tubeWarmth: 0.25,
            tubeMix: 0.15,
            compressorEnabled: true,
            compThreshold: -14.0,
            compRatio: 2.8,
            compAttack: 12.0,
            compRelease: 70.0,
            compMakeup: 1.5,
            stereoWidthEnabled: true,
            stereoWidth: 1.30,
            stereoMidGain: 1.20,
            stereoWet: 0.85,
            limiterEnabled: true,
            limiterThreshold: -2.5,
            limiterOutputCeiling: -0.5,
            activePresetId: 'genre_pop',
          ),
        ),
        DspPreset(
          id: 'genre_edm',
          name: 'Electronic & Club Impact',
          description: 'Deep sub-bass impact, aggressive compressor pump & ultra-wide stereo field.',
          state: const DspRackState(
            isBypassed: false,
            masterWet: 1.0,
            preampDb: -2.5,
            bassBoostEnabled: true,
            bassBoostAmount: 4.5,
            bassBoostWet: 0.90,
            compressorEnabled: true,
            compThreshold: -12.0,
            compRatio: 4.0,
            compAttack: 25.0,
            compRelease: 110.0,
            compMakeup: 2.0,
            stereoWidthEnabled: true,
            stereoWidth: 1.45,
            stereoMidGain: 1.0,
            stereoWet: 0.90,
            limiterEnabled: true,
            limiterThreshold: -3.0,
            limiterOutputCeiling: -0.5,
            activePresetId: 'genre_edm',
          ),
        ),
        DspPreset(
          id: 'genre_hiphop',
          name: 'Hip-Hop & Urban Sub',
          description: 'Deep psychoacoustic 808 sub-bass, centered punchy vocal presence.',
          state: const DspRackState(
            isBypassed: false,
            masterWet: 1.0,
            preampDb: -2.0,
            bassBoostEnabled: true,
            bassBoostAmount: 3.8,
            bassBoostWet: 0.85,
            compressorEnabled: true,
            compThreshold: -15.0,
            compRatio: 3.5,
            compAttack: 18.0,
            compRelease: 95.0,
            compMakeup: 1.8,
            stereoWidthEnabled: true,
            stereoWidth: 1.10,
            stereoMidGain: 1.25,
            stereoWet: 0.70,
            limiterEnabled: true,
            limiterThreshold: -3.0,
            limiterOutputCeiling: -0.8,
            activePresetId: 'genre_hiphop',
          ),
        ),
        DspPreset(
          id: 'genre_jazz',
          name: 'Warm Analog Jazz & Soul',
          description: 'Warm triode tube saturation, binaural crossfeed & organic room acoustics.',
          state: const DspRackState(
            isBypassed: false,
            masterWet: 1.0,
            preampDb: -1.5,
            tubeExciterEnabled: true,
            tubeDrive: 2.2,
            tubeWarmth: 0.65,
            tubeMix: 0.38,
            crossfeedEnabled: true,
            crossfeedCutoff: 650.0,
            crossfeedFeed: -6.5,
            crossfeedDelayMs: 0.36,
            crossfeedWet: 0.80,
            reverbEnabled: true,
            reverbRoomSize: 0.28,
            reverbDamp: 0.65,
            reverbWidth: 0.9,
            reverbWet: 0.15,
            limiterEnabled: true,
            limiterThreshold: -2.0,
            limiterOutputCeiling: -0.5,
            activePresetId: 'genre_jazz',
          ),
        ),
        DspPreset(
          id: 'genre_classical',
          name: 'Holographic Classical & Score',
          description: 'Expansive concert hall spatial reverb, uncompressed bit-perfect dynamics.',
          state: const DspRackState(
            isBypassed: false,
            masterWet: 1.0,
            preampDb: -1.0,
            crossfeedEnabled: true,
            crossfeedCutoff: 700.0,
            crossfeedFeed: -5.5,
            crossfeedDelayMs: 0.38,
            crossfeedWet: 0.85,
            reverbEnabled: true,
            reverbRoomSize: 0.42,
            reverbDamp: 0.50,
            reverbWidth: 1.1,
            reverbWet: 0.22,
            stereoWidthEnabled: true,
            stereoWidth: 1.25,
            stereoMidGain: 1.0,
            stereoWet: 0.75,
            limiterEnabled: true,
            limiterThreshold: -2.0,
            limiterOutputCeiling: -0.3,
            activePresetId: 'genre_classical',
          ),
        ),
        DspPreset(
          id: 'genre_acoustic',
          name: 'Acoustic & Intimate Folk',
          description: 'Mid-frequency string intimacy, gentle analog warmth & fatigue reduction.',
          state: const DspRackState(
            isBypassed: false,
            masterWet: 1.0,
            preampDb: -1.0,
            tubeExciterEnabled: true,
            tubeDrive: 1.4,
            tubeWarmth: 0.50,
            tubeMix: 0.25,
            crossfeedEnabled: true,
            crossfeedCutoff: 680.0,
            crossfeedFeed: -7.0,
            crossfeedDelayMs: 0.35,
            crossfeedWet: 0.75,
            stereoWidthEnabled: true,
            stereoWidth: 1.15,
            stereoMidGain: 1.15,
            stereoWet: 0.65,
            limiterEnabled: true,
            limiterThreshold: -2.0,
            limiterOutputCeiling: -0.5,
            activePresetId: 'genre_acoustic',
          ),
        ),
        DspPreset(
          id: 'genre_rnb',
          name: 'Smooth R&B & Neo-Soul',
          description: 'Lush vocal presence, smooth low-end compression & warm stereophonic field.',
          state: const DspRackState(
            isBypassed: false,
            masterWet: 1.0,
            preampDb: -1.5,
            tubeExciterEnabled: true,
            tubeDrive: 1.3,
            tubeWarmth: 0.45,
            tubeMix: 0.22,
            bassBoostEnabled: true,
            bassBoostAmount: 2.6,
            bassBoostWet: 0.75,
            compressorEnabled: true,
            compThreshold: -13.0,
            compRatio: 2.6,
            compAttack: 15.0,
            compRelease: 100.0,
            compMakeup: 1.4,
            stereoWidthEnabled: true,
            stereoWidth: 1.22,
            stereoMidGain: 1.15,
            stereoWet: 0.80,
            limiterEnabled: true,
            limiterThreshold: -2.5,
            limiterOutputCeiling: -0.6,
            activePresetId: 'genre_rnb',
          ),
        ),
        DspPreset(
          id: 'genre_metal',
          name: 'High-Gain Heavy Metal',
          description: 'Fast transient attack, tight bass roll-off & high-gain harmonic definition.',
          state: const DspRackState(
            isBypassed: false,
            masterWet: 1.0,
            preampDb: -2.0,
            tubeExciterEnabled: true,
            tubeDrive: 2.0,
            tubeWarmth: 0.30,
            tubeMix: 0.30,
            compressorEnabled: true,
            compThreshold: -9.0,
            compRatio: 3.8,
            compAttack: 8.0,
            compRelease: 60.0,
            compMakeup: 1.2,
            stereoWidthEnabled: true,
            stereoWidth: 1.20,
            stereoMidGain: 1.05,
            stereoWet: 0.75,
            limiterEnabled: true,
            limiterThreshold: -3.0,
            limiterOutputCeiling: -0.5,
            activePresetId: 'genre_metal',
          ),
        ),
        DspPreset(
          id: 'genre_lofi',
          name: 'Lo-Fi & Chillhop Vintage',
          description: 'Heavy analog triode tube saturation, soft vinyl warmth & cozy acoustic space.',
          state: const DspRackState(
            isBypassed: false,
            masterWet: 1.0,
            preampDb: -1.5,
            tubeExciterEnabled: true,
            tubeDrive: 3.2,
            tubeWarmth: 0.75,
            tubeMix: 0.50,
            crossfeedEnabled: true,
            crossfeedCutoff: 600.0,
            crossfeedFeed: -6.0,
            crossfeedDelayMs: 0.40,
            crossfeedWet: 0.85,
            reverbEnabled: true,
            reverbRoomSize: 0.25,
            reverbDamp: 0.70,
            reverbWidth: 0.8,
            reverbWet: 0.18,
            limiterEnabled: true,
            limiterThreshold: -3.0,
            limiterOutputCeiling: -0.8,
            activePresetId: 'genre_lofi',
          ),
        ),
      ];
}

/// State lengkap untuk modul-modul DSP Mastering Studio Rack
@immutable
class DspRackState {
  const DspRackState({
    this.isBypassed = false,
    this.masterWet = 1.0,
    this.preampDb = -1.5,

    // Dynamic Bass Boost
    this.bassBoostEnabled = false,
    this.bassBoostAmount = 2.0,
    this.bassBoostWet = 1.0,

    // Tube Exciter / Triode Saturation
    this.tubeExciterEnabled = true,
    this.tubeDrive = 1.2,
    this.tubeWarmth = 0.45,
    this.tubeMix = 0.18,

    // Dynamic Compressor
    this.compressorEnabled = false,
    this.compThreshold = -6.0,
    this.compRatio = 3.0,
    this.compAttack = 10.0,
    this.compRelease = 100.0,
    this.compMakeup = 0.0,
    this.compKnee = 2.0,
    this.compWet = 1.0,

    // Stereo Width (Mid-Side Matrix)
    this.stereoWidthEnabled = true,
    this.stereoWidth = 1.15,
    this.stereoMidGain = 1.05,
    this.stereoWet = 0.70,

    // Binaural Crossfeed (Bauer / Meier)
    this.crossfeedEnabled = false,
    this.crossfeedCutoff = 700.0,
    this.crossfeedFeed = -6.0,
    this.crossfeedDelayMs = 0.35,
    this.crossfeedWet = 1.0,

    // Spatial Studio Reverb (Freeverb)
    this.reverbEnabled = false,
    this.reverbRoomSize = 0.5,
    this.reverbDamp = 0.5,
    this.reverbWidth = 1.0,
    this.reverbFreeze = false,
    this.reverbWet = 0.25,

    // Pitch Shifter
    this.pitchShiftEnabled = false,
    this.pitchSemitones = 0.0,
    this.pitchWet = 1.0,

    // Peak Brickwall Limiter
    this.limiterEnabled = true,
    this.limiterThreshold = -2.5,
    this.limiterOutputCeiling = -0.5,
    this.limiterAttack = 1.0,
    this.limiterRelease = 100.0,
    this.limiterKnee = 2.0,
    this.limiterWet = 1.0,

    this.activePresetId = 'studio_warmth',
    this.revision = 0,
  });

  final bool isBypassed;
  final double masterWet;
  final double preampDb;
  final int revision;

  // Bass Boost
  final bool bassBoostEnabled;
  final double bassBoostAmount;
  final double bassBoostWet;

  // Tube Exciter
  final bool tubeExciterEnabled;
  final double tubeDrive;
  final double tubeWarmth;
  final double tubeMix;

  // Compressor
  final bool compressorEnabled;
  final double compThreshold;
  final double compRatio;
  final double compAttack;
  final double compRelease;
  final double compMakeup;
  final double compKnee;
  final double compWet;

  // Stereo Width
  final bool stereoWidthEnabled;
  final double stereoWidth;
  final double stereoMidGain;
  final double stereoWet;

  // Binaural Crossfeed
  final bool crossfeedEnabled;
  final double crossfeedCutoff;
  final double crossfeedFeed;
  final double crossfeedDelayMs;
  final double crossfeedWet;

  // Reverb
  final bool reverbEnabled;
  final double reverbRoomSize;
  final double reverbDamp;
  final double reverbWidth;
  final bool reverbFreeze;
  final double reverbWet;

  // Pitch Shifter
  final bool pitchShiftEnabled;
  final double pitchSemitones;
  final double pitchWet;

  // Limiter
  final bool limiterEnabled;
  final double limiterThreshold;
  final double limiterOutputCeiling;
  final double limiterAttack;
  final double limiterRelease;
  final double limiterKnee;
  final double limiterWet;

  final String? activePresetId;

  DspRackState copyWith({
    bool? isBypassed,
    double? masterWet,
    double? preampDb,
    bool? bassBoostEnabled,
    double? bassBoostAmount,
    double? bassBoostWet,
    bool? tubeExciterEnabled,
    double? tubeDrive,
    double? tubeWarmth,
    double? tubeMix,
    bool? compressorEnabled,
    double? compThreshold,
    double? compRatio,
    double? compAttack,
    double? compRelease,
    double? compMakeup,
    double? compKnee,
    double? compWet,
    bool? stereoWidthEnabled,
    double? stereoWidth,
    double? stereoMidGain,
    double? stereoWet,
    bool? crossfeedEnabled,
    double? crossfeedCutoff,
    double? crossfeedFeed,
    double? crossfeedDelayMs,
    double? crossfeedWet,
    bool? reverbEnabled,
    double? reverbRoomSize,
    double? reverbDamp,
    double? reverbWidth,
    bool? reverbFreeze,
    double? reverbWet,
    bool? pitchShiftEnabled,
    double? pitchSemitones,
    double? pitchWet,
    bool? limiterEnabled,
    double? limiterThreshold,
    double? limiterOutputCeiling,
    double? limiterAttack,
    double? limiterRelease,
    double? limiterKnee,
    double? limiterWet,
    String? activePresetId,
    int? revision,
    bool clearPreset = false,
  }) {
    return DspRackState(
      isBypassed: isBypassed ?? this.isBypassed,
      masterWet: masterWet ?? this.masterWet,
      preampDb: preampDb ?? this.preampDb,
      revision: revision ?? this.revision,
      bassBoostEnabled: bassBoostEnabled ?? this.bassBoostEnabled,
      bassBoostAmount: bassBoostAmount ?? this.bassBoostAmount,
      bassBoostWet: bassBoostWet ?? this.bassBoostWet,
      tubeExciterEnabled: tubeExciterEnabled ?? this.tubeExciterEnabled,
      tubeDrive: tubeDrive ?? this.tubeDrive,
      tubeWarmth: tubeWarmth ?? this.tubeWarmth,
      tubeMix: tubeMix ?? this.tubeMix,
      compressorEnabled: compressorEnabled ?? this.compressorEnabled,
      compThreshold: compThreshold ?? this.compThreshold,
      compRatio: compRatio ?? this.compRatio,
      compAttack: compAttack ?? this.compAttack,
      compRelease: compRelease ?? this.compRelease,
      compMakeup: compMakeup ?? this.compMakeup,
      compKnee: compKnee ?? this.compKnee,
      compWet: compWet ?? this.compWet,
      stereoWidthEnabled: stereoWidthEnabled ?? this.stereoWidthEnabled,
      stereoWidth: stereoWidth ?? this.stereoWidth,
      stereoMidGain: stereoMidGain ?? this.stereoMidGain,
      stereoWet: stereoWet ?? this.stereoWet,
      crossfeedEnabled: crossfeedEnabled ?? this.crossfeedEnabled,
      crossfeedCutoff: crossfeedCutoff ?? this.crossfeedCutoff,
      crossfeedFeed: crossfeedFeed ?? this.crossfeedFeed,
      crossfeedDelayMs: crossfeedDelayMs ?? this.crossfeedDelayMs,
      crossfeedWet: crossfeedWet ?? this.crossfeedWet,
      reverbEnabled: reverbEnabled ?? this.reverbEnabled,
      reverbRoomSize: reverbRoomSize ?? this.reverbRoomSize,
      reverbDamp: reverbDamp ?? this.reverbDamp,
      reverbWidth: reverbWidth ?? this.reverbWidth,
      reverbFreeze: reverbFreeze ?? this.reverbFreeze,
      reverbWet: reverbWet ?? this.reverbWet,
      pitchShiftEnabled: pitchShiftEnabled ?? this.pitchShiftEnabled,
      pitchSemitones: pitchSemitones ?? this.pitchSemitones,
      pitchWet: pitchWet ?? this.pitchWet,
      limiterEnabled: limiterEnabled ?? this.limiterEnabled,
      limiterThreshold: limiterThreshold ?? this.limiterThreshold,
      limiterOutputCeiling: limiterOutputCeiling ?? this.limiterOutputCeiling,
      limiterAttack: limiterAttack ?? this.limiterAttack,
      limiterRelease: limiterRelease ?? this.limiterRelease,
      limiterKnee: limiterKnee ?? this.limiterKnee,
      limiterWet: limiterWet ?? this.limiterWet,
      activePresetId: clearPreset ? null : (activePresetId ?? this.activePresetId),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isBypassed': isBypassed,
      'masterWet': masterWet,
      'preampDb': preampDb,
      'bassBoostEnabled': bassBoostEnabled,
      'bassBoostAmount': bassBoostAmount,
      'bassBoostWet': bassBoostWet,
      'tubeExciterEnabled': tubeExciterEnabled,
      'tubeDrive': tubeDrive,
      'tubeWarmth': tubeWarmth,
      'tubeMix': tubeMix,
      'compressorEnabled': compressorEnabled,
      'compThreshold': compThreshold,
      'compRatio': compRatio,
      'compAttack': compAttack,
      'compRelease': compRelease,
      'compMakeup': compMakeup,
      'compKnee': compKnee,
      'compWet': compWet,
      'stereoWidthEnabled': stereoWidthEnabled,
      'stereoWidth': stereoWidth,
      'stereoMidGain': stereoMidGain,
      'stereoWet': stereoWet,
      'crossfeedEnabled': crossfeedEnabled,
      'crossfeedCutoff': crossfeedCutoff,
      'crossfeedFeed': crossfeedFeed,
      'crossfeedDelayMs': crossfeedDelayMs,
      'crossfeedWet': crossfeedWet,
      'reverbEnabled': reverbEnabled,
      'reverbRoomSize': reverbRoomSize,
      'reverbDamp': reverbDamp,
      'reverbWidth': reverbWidth,
      'reverbFreeze': reverbFreeze,
      'reverbWet': reverbWet,
      'pitchShiftEnabled': pitchShiftEnabled,
      'pitchSemitones': pitchSemitones,
      'pitchWet': pitchWet,
      'limiterEnabled': limiterEnabled,
      'limiterThreshold': limiterThreshold,
      'limiterOutputCeiling': limiterOutputCeiling,
      'limiterAttack': limiterAttack,
      'limiterRelease': limiterRelease,
      'limiterKnee': limiterKnee,
      'limiterWet': limiterWet,
      'activePresetId': activePresetId,
    };
  }

  factory DspRackState.fromMap(Map<String, dynamic> map) {
    return DspRackState(
      isBypassed: map['isBypassed'] as bool? ?? false,
      masterWet: (map['masterWet'] as num?)?.toDouble() ?? 1.0,
      preampDb: (map['preampDb'] as num?)?.toDouble() ?? 0.0,
      bassBoostEnabled: map['bassBoostEnabled'] as bool? ?? false,
      bassBoostAmount: (map['bassBoostAmount'] as num?)?.toDouble() ?? 2.0,
      bassBoostWet: (map['bassBoostWet'] as num?)?.toDouble() ?? 1.0,
      tubeExciterEnabled: map['tubeExciterEnabled'] as bool? ?? false,
      tubeDrive: (map['tubeDrive'] as num?)?.toDouble() ?? 1.0,
      tubeWarmth: (map['tubeWarmth'] as num?)?.toDouble() ?? 0.4,
      tubeMix: (map['tubeMix'] as num?)?.toDouble() ?? 0.35,
      compressorEnabled: map['compressorEnabled'] as bool? ?? false,
      compThreshold: (map['compThreshold'] as num?)?.toDouble() ?? -6.0,
      compRatio: (map['compRatio'] as num?)?.toDouble() ?? 3.0,
      compAttack: (map['compAttack'] as num?)?.toDouble() ?? 10.0,
      compRelease: (map['compRelease'] as num?)?.toDouble() ?? 100.0,
      compMakeup: (map['compMakeup'] as num?)?.toDouble() ?? 0.0,
      compKnee: (map['compKnee'] as num?)?.toDouble() ?? 2.0,
      compWet: (map['compWet'] as num?)?.toDouble() ?? 1.0,
      stereoWidthEnabled: map['stereoWidthEnabled'] as bool? ?? false,
      stereoWidth: (map['stereoWidth'] as num?)?.toDouble() ?? 1.35,
      stereoMidGain: (map['stereoMidGain'] as num?)?.toDouble() ?? 1.0,
      stereoWet: (map['stereoWet'] as num?)?.toDouble() ?? 1.0,
      crossfeedEnabled: map['crossfeedEnabled'] as bool? ?? false,
      crossfeedCutoff: (map['crossfeedCutoff'] as num?)?.toDouble() ?? 700.0,
      crossfeedFeed: (map['crossfeedFeed'] as num?)?.toDouble() ?? -6.0,
      crossfeedDelayMs: (map['crossfeedDelayMs'] as num?)?.toDouble() ?? 0.35,
      crossfeedWet: (map['crossfeedWet'] as num?)?.toDouble() ?? 1.0,
      reverbEnabled: map['reverbEnabled'] as bool? ?? false,
      reverbRoomSize: (map['reverbRoomSize'] as num?)?.toDouble() ?? 0.5,
      reverbDamp: (map['reverbDamp'] as num?)?.toDouble() ?? 0.5,
      reverbWidth: (map['reverbWidth'] as num?)?.toDouble() ?? 1.0,
      reverbFreeze: map['reverbFreeze'] as bool? ?? false,
      reverbWet: (map['reverbWet'] as num?)?.toDouble() ?? 0.25,
      pitchShiftEnabled: map['pitchShiftEnabled'] as bool? ?? false,
      pitchSemitones: (map['pitchSemitones'] as num?)?.toDouble() ?? 0.0,
      pitchWet: (map['pitchWet'] as num?)?.toDouble() ?? 1.0,
      limiterEnabled: map['limiterEnabled'] as bool? ?? true,
      limiterThreshold: (map['limiterThreshold'] as num?)?.toDouble() ?? -3.0,
      limiterOutputCeiling: (map['limiterOutputCeiling'] as num?)?.toDouble() ?? -1.0,
      limiterAttack: (map['limiterAttack'] as num?)?.toDouble() ?? 1.0,
      limiterRelease: (map['limiterRelease'] as num?)?.toDouble() ?? 100.0,
      limiterKnee: (map['limiterKnee'] as num?)?.toDouble() ?? 2.0,
      limiterWet: (map['limiterWet'] as num?)?.toDouble() ?? 1.0,
      activePresetId: map['activePresetId'] as String?,
    );
  }
}

/// Track DSP override binding record
@immutable
class DspTrackOverride {
  final String trackId;
  final String presetId;
  final String presetName;
  final DateTime assignedAt;

  const DspTrackOverride({
    required this.trackId,
    required this.presetId,
    required this.presetName,
    required this.assignedAt,
  });

  Map<String, dynamic> toMap() => {
        'trackId': trackId,
        'presetId': presetId,
        'presetName': presetName,
        'assignedAt': assignedAt.toIso8601String(),
      };

  factory DspTrackOverride.fromMap(Map<String, dynamic> map) => DspTrackOverride(
        trackId: map['trackId'] as String? ?? '',
        presetId: map['presetId'] as String? ?? '',
        presetName: map['presetName'] as String? ?? 'Custom Preset',
        assignedAt: DateTime.tryParse(map['assignedAt'] as String? ?? '') ?? DateTime.now(),
      );
}

/// Genre mapping definition
@immutable
class DspGenreMapping {
  final String genreKey;
  final String displayName;
  final List<String> keywords;
  final String targetPresetId;

  const DspGenreMapping({
    required this.genreKey,
    required this.displayName,
    required this.keywords,
    required this.targetPresetId,
  });

  Map<String, dynamic> toMap() => {
        'genreKey': genreKey,
        'displayName': displayName,
        'keywords': keywords,
        'targetPresetId': targetPresetId,
      };

  factory DspGenreMapping.fromMap(Map<String, dynamic> map) => DspGenreMapping(
        genreKey: map['genreKey'] as String? ?? '',
        displayName: map['displayName'] as String? ?? '',
        keywords: List<String>.from(map['keywords'] as List? ?? []),
        targetPresetId: map['targetPresetId'] as String? ?? 'studio_warmth',
      );
}

/// Resolution source indicator for UI feedback
enum DspResolutionSource {
  trackOverride,
  genreAuto,
  manual,
}

@immutable
class DspResolutionResult {
  final DspPreset preset;
  final DspResolutionSource source;
  final String? matchedGenre;
  final String? trackTitle;

  const DspResolutionResult({
    required this.preset,
    required this.source,
    this.matchedGenre,
    this.trackTitle,
  });
}

/// Match result for genre evaluator
@immutable
class GenreMatchResult {
  final String genreKey;
  final String targetPresetId;
  final String matchedKeyword;

  const GenreMatchResult({
    required this.genreKey,
    required this.targetPresetId,
    required this.matchedKeyword,
  });
}

/// Fuzzy Genre Matching & Evaluation Engine for DSP auto-application
class GenrePresetMatcher {
  const GenrePresetMatcher._();

  /// Default studio genre mappings
  static const List<DspGenreMapping> defaultGenreMappings = [
    DspGenreMapping(
      genreKey: 'rock',
      displayName: 'Rock & Alternative',
      keywords: [
        'rock',
        'hard rock',
        'alt rock',
        'alternative rock',
        'alternative',
        'punk',
        'punk rock',
        'grunge',
        'indie rock',
        'post-rock',
        'garage rock',
        'progressive rock',
        'prog rock',
        'psychedelic rock',
        'classic rock',
        'southern rock',
      ],
      targetPresetId: 'genre_rock',
    ),
    DspGenreMapping(
      genreKey: 'metal',
      displayName: 'Metal & Heavy',
      keywords: [
        'metal',
        'heavy metal',
        'metalcore',
        'death metal',
        'thrash metal',
        'black metal',
        'nu metal',
        'nu-metal',
        'power metal',
        'doom metal',
        'deathcore',
        'post-hardcore',
        'hardcore',
        'grindcore',
        'djent',
      ],
      targetPresetId: 'genre_metal',
    ),
    DspGenreMapping(
      genreKey: 'pop',
      displayName: 'Pop & Commercial',
      keywords: [
        'pop',
        'synthpop',
        'synth-pop',
        'dance-pop',
        'electropop',
        'electro-pop',
        'k-pop',
        'kpop',
        'j-pop',
        'jpop',
        'indie pop',
        'c-pop',
        'hyperpop',
        'eurodance',
        'teen pop',
        'chamber pop',
      ],
      targetPresetId: 'genre_pop',
    ),
    DspGenreMapping(
      genreKey: 'edm',
      displayName: 'Electronic & Dance',
      keywords: [
        'electronic',
        'electronica',
        'edm',
        'dance',
        'house',
        'techno',
        'trance',
        'dubstep',
        'electro',
        'drum and bass',
        'dnb',
        'drum & bass',
        'synthwave',
        'club',
        'hardstyle',
        'hard dance',
        'progressive house',
        'deep house',
        'tech house',
        'future bass',
        'trap edm',
      ],
      targetPresetId: 'genre_edm',
    ),
    DspGenreMapping(
      genreKey: 'hiphop',
      displayName: 'Hip-Hop & Urban',
      keywords: [
        'hip hop',
        'hip-hop',
        'hiphop',
        'rap',
        'trap',
        'boom bap',
        'drill',
        'urban',
        'gangsta rap',
        'east coast rap',
        'west coast rap',
        'southern hip hop',
      ],
      targetPresetId: 'genre_hiphop',
    ),
    DspGenreMapping(
      genreKey: 'rnb',
      displayName: 'R&B & Neo-Soul',
      keywords: [
        'r&b',
        'rnb',
        'contemporary r&b',
        'neo-soul',
        'neo soul',
        'funk',
        'motown',
        'disco',
        'groove',
        'soul',
      ],
      targetPresetId: 'genre_rnb',
    ),
    DspGenreMapping(
      genreKey: 'jazz',
      displayName: 'Jazz & Blues',
      keywords: [
        'jazz',
        'bebop',
        'smooth jazz',
        'jazz fusion',
        'fusion',
        'blues',
        'chicago blues',
        'delta blues',
        'swing',
        'bossa nova',
        'big band',
        'dixieland',
        'cool jazz',
      ],
      targetPresetId: 'genre_jazz',
    ),
    DspGenreMapping(
      genreKey: 'classical',
      displayName: 'Classical & Orchestral',
      keywords: [
        'classical',
        'orchestral',
        'orchestra',
        'symphonic',
        'symphony',
        'soundtrack',
        'score',
        'film score',
        'instrumental',
        'chamber',
        'opera',
        'baroque',
        'romantic',
        'contemporary classical',
        'ost',
        'piano solo',
      ],
      targetPresetId: 'genre_classical',
    ),
    DspGenreMapping(
      genreKey: 'acoustic',
      displayName: 'Acoustic & Folk',
      keywords: [
        'acoustic',
        'folk',
        'singer-songwriter',
        'singer songwriter',
        'country',
        'bluegrass',
        'americana',
        'indie folk',
        'unplugged',
        'acoustic guitar',
      ],
      targetPresetId: 'genre_acoustic',
    ),
    DspGenreMapping(
      genreKey: 'lofi',
      displayName: 'Lo-Fi & Ambient',
      keywords: [
        'lo-fi',
        'lofi',
        'chillhop',
        'chill hop',
        'ambient',
        'downtempo',
        'lounge',
        'chillout',
        'trip hop',
        'trip-hop',
        'meditation',
        'vaporwave',
      ],
      targetPresetId: 'genre_lofi',
    ),
  ];

  /// Evaluates a raw genre tag string and returns matching result if any
  static GenreMatchResult? match(
    String? rawGenre, {
    Map<String, String>? customMappingOverrides,
    List<DspGenreMapping>? customMappings,
  }) {
    if (rawGenre == null || rawGenre.trim().isEmpty) return null;

    final mappings = customMappings ?? defaultGenreMappings;
    final normalized = _cleanString(rawGenre);
    if (normalized.isEmpty) return null;

    // 1. Split raw genre string by typical separators (/, ;, ,, |, &, and)
    final tokens = normalized
        .split(RegExp(r'[/;,|&+]|\band\b'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    // In case no split occurred, tokens will contain [normalized]
    if (tokens.isEmpty) {
      tokens.add(normalized);
    }

    // First check exact keyword matches against tokens
    for (final token in tokens) {
      for (final mapping in mappings) {
        for (final kw in mapping.keywords) {
          final cleanKw = _cleanString(kw);
          if (token == cleanKw) {
            final targetPreset = customMappingOverrides?[mapping.genreKey] ?? mapping.targetPresetId;
            return GenreMatchResult(
              genreKey: mapping.genreKey,
              targetPresetId: targetPreset,
              matchedKeyword: kw,
            );
          }
        }
      }
    }

    // Then check substring containment (e.g. "japanese rock" contains "rock")
    // Sort keywords by length descending to match specific keywords first (e.g. "metalcore" before "metal")
    final sortedRules = <_SortedRule>[];
    for (final mapping in mappings) {
      for (final kw in mapping.keywords) {
        sortedRules.add(_SortedRule(
          mapping: mapping,
          keyword: kw,
          cleanKeyword: _cleanString(kw),
        ));
      }
    }
    sortedRules.sort((a, b) => b.cleanKeyword.length.compareTo(a.cleanKeyword.length));

    for (final rule in sortedRules) {
      // Check if any token contains the keyword or full normalized string contains it
      final isMatch = tokens.any((t) => t.contains(rule.cleanKeyword)) ||
          normalized.contains(rule.cleanKeyword);

      if (isMatch) {
        final targetPreset =
            customMappingOverrides?[rule.mapping.genreKey] ?? rule.mapping.targetPresetId;
        return GenreMatchResult(
          genreKey: rule.mapping.genreKey,
          targetPresetId: targetPreset,
          matchedKeyword: rule.keyword,
        );
      }
    }

    return null;
  }

  static String _cleanString(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[\(\)\[\]\{\}\-_]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _SortedRule {
  final DspGenreMapping mapping;
  final String keyword;
  final String cleanKeyword;

  const _SortedRule({
    required this.mapping,
    required this.keyword,
    required this.cleanKeyword,
  });
}

