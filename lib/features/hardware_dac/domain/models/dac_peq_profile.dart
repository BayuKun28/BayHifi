import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dac_band_config.dart';
import 'dac_device.dart';

/// Represents a complete Parametric EQ preset configured for hardware DSP DAC flashing.
@immutable
class DacPeqProfile {
  const DacPeqProfile({
    required this.id,
    required this.name,
    this.description = '',
    required this.bands,
    this.preampGainDb = 0.0,
    this.targetChipset = DacChipset.kt0211l,
    this.createdAt,
  });

  /// Unique identifier for this preset profile.
  final String id;

  /// User-facing profile name (e.g. "Harman Target 2019", "Warm Studio Bass").
  final String name;

  /// Detailed description or source attribution.
  final String description;

  /// List of hardware biquad band configurations (typically 5 bands).
  final List<DacBandConfig> bands;

  /// Safe pre-amp attenuation gain in dB (<= 0.0 dB) to prevent DAC clipping.
  final double preampGainDb;

  /// Target chipset family.
  final DacChipset targetChipset;

  /// Creation timestamp.
  final DateTime? createdAt;

  /// Returns true if this profile is one of the built-in factory stock presets.
  bool get isBuiltIn => builtInPresets.any((p) => p.id == id);

  /// Returns true if all bands in the profile have 0 dB gain.
  bool get isFlat => bands.every((band) => band.gainDb == 0.0);

  /// Exports this profile to a formatted JSON string for file sharing/backup.
  String exportToJsonString() {
    const encoder = JsonEncoder.withIndent('  ');
    return encoder.convert(toJson());
  }

  /// Parses and imports a DacPeqProfile from a JSON string.
  static DacPeqProfile? importFromJsonString(String jsonStr) {
    try {
      final map = jsonDecode(jsonStr);
      if (map is Map<String, dynamic>) {
        return DacPeqProfile.fromJson(map);
      } else if (map is Map) {
        return DacPeqProfile.fromJson(Map<String, dynamic>.from(map));
      }
    } catch (_) {}
    return null;
  }

  /// Computes safe pre-amp headroom based on maximum positive filter gain.
  double get calculatedSafePreamp {
    double maxPositiveGain = 0.0;
    for (final band in bands) {
      if (!band.isBypassed && band.gainDb > maxPositiveGain) {
        maxPositiveGain = band.gainDb;
      }
    }
    return maxPositiveGain > 0 ? -maxPositiveGain : 0.0;
  }

  DacPeqProfile copyWith({
    String? id,
    String? name,
    String? description,
    List<DacBandConfig>? bands,
    double? preampGainDb,
    DacChipset? targetChipset,
    DateTime? createdAt,
  }) {
    return DacPeqProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      bands: bands ?? this.bands,
      preampGainDb: preampGainDb ?? this.preampGainDb,
      targetChipset: targetChipset ?? this.targetChipset,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'bands': bands.map((b) => b.toJson()).toList(),
      'preampGainDb': preampGainDb,
      'targetChipset': targetChipset.name,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  factory DacPeqProfile.fromJson(Map<String, dynamic> json) {
    return DacPeqProfile(
      id: json['id'] as String? ?? 'custom_preset',
      name: json['name'] as String? ?? 'Custom Preset',
      description: json['description'] as String? ?? '',
      bands: (json['bands'] as List<dynamic>?)
              ?.map((e) => DacBandConfig.fromJson(e as Map<String, dynamic>))
              .toList() ??
          DacBandConfig.defaultKiwiEars5Bands,
      preampGainDb: (json['preampGainDb'] as num?)?.toDouble() ?? 0.0,
      targetChipset: json['targetChipset'] != null
          ? DacChipset.values.firstWhere(
              (c) => c.name == json['targetChipset'],
              orElse: () => DacChipset.kt0211l,
            )
          : DacChipset.kt0211l,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
    );
  }

  /// Factory preset: Flat / Bypass profile.
  static DacPeqProfile get flatDefault => DacPeqProfile(
        id: 'kiwi_flat_default',
        name: 'Factory Flat',
        description: 'Kiwi Ears stock flat response with 0dB gain across all bands.',
        bands: DacBandConfig.defaultKiwiEars5Bands,
        preampGainDb: 0.0,
      );

  /// Factory preset: Warm Studio Bass & Vocal Focus.
  static DacPeqProfile get warmVocal => const DacPeqProfile(
        id: 'preset_warm_vocal',
        name: 'Warm Studio & Vocals',
        description: 'Smooth sub-bass lift with enhanced vocal midrange presence.',
        bands: [
          DacBandConfig(bandIndex: 0, frequency: 60.0, gainDb: 2.5, qFactor: 0.70, filterType: DacFilterType.lowShelf),
          DacBandConfig(bandIndex: 1, frequency: 220.0, gainDb: -1.0, qFactor: 1.20),
          DacBandConfig(bandIndex: 2, frequency: 1200.0, gainDb: 1.5, qFactor: 1.00),
          DacBandConfig(bandIndex: 3, frequency: 4500.0, gainDb: -1.5, qFactor: 1.40),
          DacBandConfig(bandIndex: 4, frequency: 12000.0, gainDb: 2.0, qFactor: 0.70, filterType: DacFilterType.highShelf),
        ],
        preampGainDb: -2.5,
      );

  /// Factory preset: Harman 2019 IEM Target Approximation.
  static DacPeqProfile get harmanIemTarget => const DacPeqProfile(
        id: 'preset_harman_iem_2019',
        name: 'Harman 2019 IEM Target',
        description: 'Audiophile industry-standard target with clean sub-bass shelf and pinna gain.',
        bands: [
          DacBandConfig(bandIndex: 0, frequency: 50.0, gainDb: 4.5, qFactor: 0.65, filterType: DacFilterType.lowShelf),
          DacBandConfig(bandIndex: 1, frequency: 300.0, gainDb: -1.5, qFactor: 1.00),
          DacBandConfig(bandIndex: 2, frequency: 2800.0, gainDb: 3.0, qFactor: 1.40),
          DacBandConfig(bandIndex: 3, frequency: 6000.0, gainDb: -2.0, qFactor: 2.00),
          DacBandConfig(bandIndex: 4, frequency: 13500.0, gainDb: 1.5, qFactor: 0.70, filterType: DacFilterType.highShelf),
        ],
        preampGainDb: -4.5,
      );

  /// Factory preset: Acoustic & Classical Transparency.
  static DacPeqProfile get acousticClarity => const DacPeqProfile(
        id: 'preset_acoustic_clarity',
        name: 'Acoustic & Classical Clarity',
        description: 'Linear midrange with subtle air sparkle for acoustic instruments and orchestral tracks.',
        bands: [
          DacBandConfig(bandIndex: 0, frequency: 40.0, gainDb: 1.0, qFactor: 0.70),
          DacBandConfig(bandIndex: 1, frequency: 400.0, gainDb: -0.5, qFactor: 1.00),
          DacBandConfig(bandIndex: 2, frequency: 2000.0, gainDb: 1.0, qFactor: 1.20),
          DacBandConfig(bandIndex: 3, frequency: 5500.0, gainDb: 0.5, qFactor: 1.00),
          DacBandConfig(bandIndex: 4, frequency: 15000.0, gainDb: 2.5, qFactor: 0.70, filterType: DacFilterType.highShelf),
        ],
        preampGainDb: -2.5,
      );

  /// Standard factory presets list.
  static List<DacPeqProfile> get builtInPresets => [
        flatDefault,
        warmVocal,
        harmanIemTarget,
        acousticClarity,
      ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DacPeqProfile &&
        other.id == id &&
        other.name == name &&
        other.description == description &&
        other.preampGainDb == preampGainDb &&
        other.targetChipset == targetChipset &&
        listEquals(other.bands, bands);
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        description,
        preampGainDb,
        targetChipset,
        Object.hashAll(bands),
      );

  @override
  String toString() =>
      'DacPeqProfile($name, bands: ${bands.length}, preamp: ${preampGainDb}dB)';
}
