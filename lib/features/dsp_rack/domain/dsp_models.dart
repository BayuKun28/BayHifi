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

  /// Kumpulan preset studio terkurasi
  static List<DspPreset> get studioPresets => [
        DspPreset(
          id: 'pure_direct',
          name: 'Audiophile Bit-Perfect',
          description: 'Direct passthrough tanpa pewarnaan audio (Flat Reference).',
          state: const DspRackState(
            isBypassed: false,
            masterWet: 1.0,
            preampDb: 0.0,
            limiterEnabled: true,
            limiterThreshold: -1.0,
            limiterOutputCeiling: -0.2,
          ),
        ),
        DspPreset(
          id: 'warm_tube',
          name: 'Warm Analog Tube Acoustic',
          description: 'Saturasi harmonik tabung triode dengan kehangatan analog lembut.',
          state: const DspRackState(
            isBypassed: false,
            masterWet: 1.0,
            preampDb: -1.5,
            tubeExciterEnabled: true,
            tubeDrive: 2.8,
            tubeWarmth: 0.65,
            tubeMix: 0.45,
            limiterEnabled: true,
            limiterThreshold: -3.0,
            limiterOutputCeiling: -1.0,
          ),
        ),
        DspPreset(
          id: 'deep_bass',
          name: 'Deep Bass Sub-Impact',
          description: 'Penguatan sub-bass psychoacoustic dengan kontrol kompresor dinamik.',
          state: const DspRackState(
            isBypassed: false,
            masterWet: 1.0,
            preampDb: -2.5,
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
          ),
        ),
        DspPreset(
          id: 'spacious_cinema',
          name: 'Spacious Cinema Holographic',
          description: 'Soundstage 3D super lebar dengan stereo crossfeed dan reverb ruang konser.',
          state: const DspRackState(
            isBypassed: false,
            masterWet: 1.0,
            preampDb: -2.0,
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
          ),
        ),
        DspPreset(
          id: 'vocal_clarity',
          name: 'Mastering Vocal Clarity',
          description: 'Fokus midrange vokal dengan kompresor transparan dan penguatan Mid-channel.',
          state: const DspRackState(
            isBypassed: false,
            masterWet: 1.0,
            preampDb: -1.0,
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
          ),
        ),
        DspPreset(
          id: 'late_night_headphone',
          name: 'Late-Night Headphone Anti-Fatigue',
          description: 'Simulasi speaker stereo Bauer Crossfeed untuk mereduksi kelelahan telinga.',
          state: const DspRackState(
            isBypassed: false,
            masterWet: 1.0,
            preampDb: -1.0,
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
    this.preampDb = 0.0,

    // Dynamic Bass Boost
    this.bassBoostEnabled = false,
    this.bassBoostAmount = 2.0,
    this.bassBoostWet = 1.0,

    // Tube Exciter / Triode Saturation
    this.tubeExciterEnabled = false,
    this.tubeDrive = 1.0,
    this.tubeWarmth = 0.4,
    this.tubeMix = 0.35,

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
    this.stereoWidthEnabled = false,
    this.stereoWidth = 1.35,
    this.stereoMidGain = 1.0,
    this.stereoWet = 1.0,

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
    this.limiterThreshold = -3.0,
    this.limiterOutputCeiling = -1.0,
    this.limiterAttack = 1.0,
    this.limiterRelease = 100.0,
    this.limiterKnee = 2.0,
    this.limiterWet = 1.0,

    this.activePresetId,
  });

  final bool isBypassed;
  final double masterWet;
  final double preampDb;

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
    bool clearPreset = false,
  }) {
    return DspRackState(
      isBypassed: isBypassed ?? this.isBypassed,
      masterWet: masterWet ?? this.masterWet,
      preampDb: preampDb ?? this.preampDb,
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
