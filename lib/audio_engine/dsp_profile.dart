import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dsp_defaults.dart';

@immutable
class DspProfile {
  const DspProfile({
    this.id,
    this.name = 'Default Studio Profile',
    this.isDefault = false,
    this.eqEnabled = false,
    this.eqGains = const [0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0],
    this.eqFilterTypes = const [
      'bell', 'bell', 'bell', 'bell', 'bell',
      'bell', 'bell', 'bell', 'bell', 'bell'
    ],
    this.eqQFactors = const [
      1.411, 1.411, 1.411, 1.411, 1.411,
      1.411, 1.411, 1.411, 1.411, 1.411
    ],
    this.eqFreqs = const [
      30.0, 60.0, 120.0, 250.0, 500.0,
      1000.0, 2000.0, 4000.0, 8000.0, 16000.0
    ],
    this.bassBoostEnabled = false,
    this.bassBoostValue = 1.0,
    this.compEnabled = false,
    this.compAttack = 0.01,
    this.compRelease = 0.2,
    this.compThreshold = -20.0,
    this.compRatio = 4.0,
    this.compKnee = 6.0,
    this.compMakeup = 0.0,
    this.limiterEnabled = false,
    this.limiterThreshold = -1.0,
    this.limiterAttack = 0.005,
    this.limiterRelease = 0.1,
    this.limiterOutputCeiling = -1.3,
    this.reverbEnabled = false,
    this.reverbRoomSize = 0.6,
    this.reverbDamp = 0.5,
    this.reverbWet = 0.3,
    this.reverbWidth = 1.0,
    this.pitchShiftEnabled = false,
    this.pitchValue = 1.0,
    this.crossfeedEnabled = false,
    this.crossfeedCutoff = 700.0,
    this.crossfeedFeed = -6.0,
    this.crossfeedDelayMs = 0.35,
    this.crossfeedWet = 1.0,
    this.tubeEnabled = false,
    this.tubeDrive = 1.5,
    this.tubeWarmth = 0.4,
    this.tubeMix = 0.5,
    this.stereoWidthEnabled = false,
    this.stereoWidthFactor = 1.25,
    this.stereoMidGain = 1.0,
    this.stereoWidthWet = 1.0,
    this.preampGain = 0.0,
  });

  final int? id;
  final String name;
  final bool isDefault;

  // 1. Parametric EQ
  final bool eqEnabled;
  final List<double> eqGains;
  final List<String> eqFilterTypes;
  final List<double> eqQFactors;
  final List<double> eqFreqs;

  // 2. Bass Boost
  final bool bassBoostEnabled;
  final double bassBoostValue;

  // 3. Compressor
  final bool compEnabled;
  final double compAttack;
  final double compRelease;
  final double compThreshold;
  final double compRatio;
  final double compKnee;
  final double compMakeup;

  // 4. Limiter
  final bool limiterEnabled;
  final double limiterThreshold;
  final double limiterAttack;
  final double limiterRelease;
  final double limiterOutputCeiling;

  // 5. Spatial Reverb
  final bool reverbEnabled;
  final double reverbRoomSize;
  final double reverbDamp;
  final double reverbWet;
  final double reverbWidth;

  // 6. Pitch Shift
  final bool pitchShiftEnabled;
  final double pitchValue;

  // 7. Binaural Crossfeed
  final bool crossfeedEnabled;
  final double crossfeedCutoff;
  final double crossfeedFeed;
  final double crossfeedDelayMs;
  final double crossfeedWet;

  // 8. Tube Exciter
  final bool tubeEnabled;
  final double tubeDrive;
  final double tubeWarmth;
  final double tubeMix;

  // 9. Stereo Width
  final bool stereoWidthEnabled;
  final double stereoWidthFactor;
  final double stereoMidGain;
  final double stereoWidthWet;

  // 10. Preamp Gain
  final double preampGain;

  /// Default flat studio profile
  static DspProfile get flatReference => DspProfile(
        name: 'Flat Studio Reference',
        isDefault: true,
        eqEnabled: false,
        bassBoostEnabled: false,
        compEnabled: false,
        tubeEnabled: false,
        stereoWidthEnabled: false,
        crossfeedEnabled: false,
        reverbEnabled: false,
        pitchShiftEnabled: false,
        limiterEnabled: false,
        limiterOutputCeiling: -1.3,
        preampGain: 0.0,
      );

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'is_default': isDefault ? 1 : 0,
      'eq_enabled': eqEnabled ? 1 : 0,
      'eq_gains': eqGains.map((e) => e.toString()).join(','),
      'eq_filter_types': eqFilterTypes.join(','),
      'eq_q_factors': eqQFactors.map((e) => e.toString()).join(','),
      'eq_freqs': eqFreqs.map((e) => e.toString()).join(','),
      'bass_boost_enabled': bassBoostEnabled ? 1 : 0,
      'bass_boost_value': bassBoostValue,
      'comp_enabled': compEnabled ? 1 : 0,
      'comp_attack': compAttack,
      'comp_release': compRelease,
      'comp_threshold': compThreshold,
      'comp_ratio': compRatio,
      'comp_knee': compKnee,
      'comp_makeup': compMakeup,
      'limiter_enabled': limiterEnabled ? 1 : 0,
      'limiter_threshold': limiterThreshold,
      'limiter_attack': limiterAttack,
      'limiter_release': limiterRelease,
      'limiter_output_ceiling': limiterOutputCeiling,
      'reverb_enabled': reverbEnabled ? 1 : 0,
      'reverb_room_size': reverbRoomSize,
      'reverb_damp': reverbDamp,
      'reverb_wet': reverbWet,
      'reverb_width': reverbWidth,
      'pitch_shift_enabled': pitchShiftEnabled ? 1 : 0,
      'pitch_value': pitchValue,
      'crossfeed_enabled': crossfeedEnabled ? 1 : 0,
      'crossfeed_cutoff': crossfeedCutoff,
      'crossfeed_feed': crossfeedFeed,
      'crossfeed_delay_ms': crossfeedDelayMs,
      'crossfeed_wet': crossfeedWet,
      'tube_enabled': tubeEnabled ? 1 : 0,
      'tube_drive': tubeDrive,
      'tube_warmth': tubeWarmth,
      'tube_mix': tubeMix,
      'stereo_width_enabled': stereoWidthEnabled ? 1 : 0,
      'stereo_width_factor': stereoWidthFactor,
      'stereo_mid_gain': stereoMidGain,
      'stereo_width_wet': stereoWidthWet,
      'preamp_gain': preampGain,
    };
  }

  factory DspProfile.fromMap(Map<String, dynamic> map) {
    List<double> parseDoubles(dynamic val, List<double> fallback) {
      if (val == null) return fallback;
      if (val is List) return val.map((e) => (e as num).toDouble()).toList();
      if (val is String && val.trim().isNotEmpty) {
        return val.split(',').map((e) => double.tryParse(e.trim()) ?? 0.0).toList();
      }
      return fallback;
    }

    List<String> parseStrings(dynamic val, List<String> fallback) {
      if (val == null) return fallback;
      if (val is List) return val.map((e) => e.toString()).toList();
      if (val is String && val.trim().isNotEmpty) {
        return val.split(',').map((e) => e.trim()).toList();
      }
      return fallback;
    }

    return DspProfile(
      id: map['id'] as int?,
      name: map['name'] as String? ?? 'Custom Profile',
      isDefault: (map['is_default'] as int? ?? 0) == 1,
      eqEnabled: (map['eq_enabled'] as int? ?? 0) == 1,
      eqGains: parseDoubles(map['eq_gains'], DspDefaults.eqGains),
      eqFilterTypes: parseStrings(map['eq_filter_types'], DspDefaults.eqFilterTypes),
      eqQFactors: parseDoubles(map['eq_q_factors'], DspDefaults.eqQFactors),
      eqFreqs: parseDoubles(map['eq_freqs'], DspDefaults.eqFreqs),
      bassBoostEnabled: (map['bass_boost_enabled'] as int? ?? 0) == 1,
      bassBoostValue: (map['bass_boost_value'] as num?)?.toDouble() ?? DspDefaults.bassBoostValue,
      compEnabled: (map['comp_enabled'] as int? ?? 0) == 1,
      compAttack: (map['comp_attack'] as num?)?.toDouble() ?? DspDefaults.compAttack,
      compRelease: (map['comp_release'] as num?)?.toDouble() ?? DspDefaults.compRelease,
      compThreshold: (map['comp_threshold'] as num?)?.toDouble() ?? DspDefaults.compThreshold,
      compRatio: (map['comp_ratio'] as num?)?.toDouble() ?? DspDefaults.compRatio,
      compKnee: (map['comp_knee'] as num?)?.toDouble() ?? DspDefaults.compKnee,
      compMakeup: (map['comp_makeup'] as num?)?.toDouble() ?? 0.0,
      limiterEnabled: (map['limiter_enabled'] as int? ?? 1) == 1,
      limiterThreshold: (map['limiter_threshold'] as num?)?.toDouble() ?? DspDefaults.limiterThreshold,
      limiterAttack: (map['limiter_attack'] as num?)?.toDouble() ?? DspDefaults.limiterAttack,
      limiterRelease: (map['limiter_release'] as num?)?.toDouble() ?? DspDefaults.limiterRelease,
      limiterOutputCeiling: (map['limiter_output_ceiling'] as num?)?.toDouble() ?? DspDefaults.limiterOutputCeiling,
      reverbEnabled: (map['reverb_enabled'] as int? ?? 0) == 1,
      reverbRoomSize: (map['reverb_room_size'] as num?)?.toDouble() ?? DspDefaults.reverbRoomSize,
      reverbDamp: (map['reverb_damp'] as num?)?.toDouble() ?? DspDefaults.reverbDamp,
      reverbWet: (map['reverb_wet'] as num?)?.toDouble() ?? DspDefaults.reverbWet,
      reverbWidth: (map['reverb_width'] as num?)?.toDouble() ?? 1.0,
      pitchShiftEnabled: (map['pitch_shift_enabled'] as int? ?? 0) == 1,
      pitchValue: (map['pitch_value'] as num?)?.toDouble() ?? DspDefaults.pitchValue,
      crossfeedEnabled: (map['crossfeed_enabled'] as int? ?? 0) == 1,
      crossfeedCutoff: (map['crossfeed_cutoff'] as num?)?.toDouble() ?? DspDefaults.crossfeedCutoff,
      crossfeedFeed: (map['crossfeed_feed'] as num?)?.toDouble() ?? DspDefaults.crossfeedFeed,
      crossfeedDelayMs: (map['crossfeed_delay_ms'] as num?)?.toDouble() ?? DspDefaults.crossfeedDelayMs,
      crossfeedWet: (map['crossfeed_wet'] as num?)?.toDouble() ?? DspDefaults.crossfeedWet,
      tubeEnabled: (map['tube_enabled'] as int? ?? 0) == 1,
      tubeDrive: (map['tube_drive'] as num?)?.toDouble() ?? DspDefaults.tubeDrive,
      tubeWarmth: (map['tube_warmth'] as num?)?.toDouble() ?? DspDefaults.tubeWarmth,
      tubeMix: (map['tube_mix'] as num?)?.toDouble() ?? DspDefaults.tubeMix,
      stereoWidthEnabled: (map['stereo_width_enabled'] as int? ?? 0) == 1,
      stereoWidthFactor: (map['stereo_width_factor'] as num?)?.toDouble() ?? DspDefaults.stereoWidthFactor,
      stereoMidGain: (map['stereo_mid_gain'] as num?)?.toDouble() ?? DspDefaults.stereoMidGain,
      stereoWidthWet: (map['stereo_width_wet'] as num?)?.toDouble() ?? DspDefaults.stereoWidthWet,
      preampGain: (map['preamp_gain'] as num?)?.toDouble() ?? DspDefaults.preampGain,
    );
  }

  String toJson() => jsonEncode(toMap());
  factory DspProfile.fromJson(String source) => DspProfile.fromMap(jsonDecode(source) as Map<String, dynamic>);

  DspProfile copyWith({
    int? id,
    String? name,
    bool? isDefault,
    bool? eqEnabled,
    List<double>? eqGains,
    List<String>? eqFilterTypes,
    List<double>? eqQFactors,
    List<double>? eqFreqs,
    bool? bassBoostEnabled,
    double? bassBoostValue,
    bool? compEnabled,
    double? compAttack,
    double? compRelease,
    double? compThreshold,
    double? compRatio,
    double? compKnee,
    double? compMakeup,
    bool? limiterEnabled,
    double? limiterThreshold,
    double? limiterAttack,
    double? limiterRelease,
    double? limiterOutputCeiling,
    bool? reverbEnabled,
    double? reverbRoomSize,
    double? reverbDamp,
    double? reverbWet,
    double? reverbWidth,
    bool? pitchShiftEnabled,
    double? pitchValue,
    bool? crossfeedEnabled,
    double? crossfeedCutoff,
    double? crossfeedFeed,
    double? crossfeedDelayMs,
    double? crossfeedWet,
    bool? tubeEnabled,
    double? tubeDrive,
    double? tubeWarmth,
    double? tubeMix,
    bool? stereoWidthEnabled,
    double? stereoWidthFactor,
    double? stereoMidGain,
    double? stereoWidthWet,
    double? preampGain,
  }) {
    return DspProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      isDefault: isDefault ?? this.isDefault,
      eqEnabled: eqEnabled ?? this.eqEnabled,
      eqGains: eqGains ?? this.eqGains,
      eqFilterTypes: eqFilterTypes ?? this.eqFilterTypes,
      eqQFactors: eqQFactors ?? this.eqQFactors,
      eqFreqs: eqFreqs ?? this.eqFreqs,
      bassBoostEnabled: bassBoostEnabled ?? this.bassBoostEnabled,
      bassBoostValue: bassBoostValue ?? this.bassBoostValue,
      compEnabled: compEnabled ?? this.compEnabled,
      compAttack: compAttack ?? this.compAttack,
      compRelease: compRelease ?? this.compRelease,
      compThreshold: compThreshold ?? this.compThreshold,
      compRatio: compRatio ?? this.compRatio,
      compKnee: compKnee ?? this.compKnee,
      compMakeup: compMakeup ?? this.compMakeup,
      limiterEnabled: limiterEnabled ?? this.limiterEnabled,
      limiterThreshold: limiterThreshold ?? this.limiterThreshold,
      limiterAttack: limiterAttack ?? this.limiterAttack,
      limiterRelease: limiterRelease ?? this.limiterRelease,
      limiterOutputCeiling: limiterOutputCeiling ?? this.limiterOutputCeiling,
      reverbEnabled: reverbEnabled ?? this.reverbEnabled,
      reverbRoomSize: reverbRoomSize ?? this.reverbRoomSize,
      reverbDamp: reverbDamp ?? this.reverbDamp,
      reverbWet: reverbWet ?? this.reverbWet,
      reverbWidth: reverbWidth ?? this.reverbWidth,
      pitchShiftEnabled: pitchShiftEnabled ?? this.pitchShiftEnabled,
      pitchValue: pitchValue ?? this.pitchValue,
      crossfeedEnabled: crossfeedEnabled ?? this.crossfeedEnabled,
      crossfeedCutoff: crossfeedCutoff ?? this.crossfeedCutoff,
      crossfeedFeed: crossfeedFeed ?? this.crossfeedFeed,
      crossfeedDelayMs: crossfeedDelayMs ?? this.crossfeedDelayMs,
      crossfeedWet: crossfeedWet ?? this.crossfeedWet,
      tubeEnabled: tubeEnabled ?? this.tubeEnabled,
      tubeDrive: tubeDrive ?? this.tubeDrive,
      tubeWarmth: tubeWarmth ?? this.tubeWarmth,
      tubeMix: tubeMix ?? this.tubeMix,
      stereoWidthEnabled: stereoWidthEnabled ?? this.stereoWidthEnabled,
      stereoWidthFactor: stereoWidthFactor ?? this.stereoWidthFactor,
      stereoMidGain: stereoMidGain ?? this.stereoMidGain,
      stereoWidthWet: stereoWidthWet ?? this.stereoWidthWet,
      preampGain: preampGain ?? this.preampGain,
    );
  }
}
