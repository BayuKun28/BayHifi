import 'package:flutter/foundation.dart';

/// Supported filter shapes in hardware DSP DACs.
enum DacFilterType {
  peaking(displayName: 'Peaking', code: 0),
  lowShelf(displayName: 'Low Shelf', code: 1),
  highShelf(displayName: 'High Shelf', code: 2),
  lowPass(displayName: 'Low Pass', code: 3),
  highPass(displayName: 'High Pass', code: 4);

  const DacFilterType({
    required this.displayName,
    required this.code,
  });

  final String displayName;
  final int code;

  static DacFilterType fromCode(int code) {
    return DacFilterType.values.firstWhere(
      (type) => type.code == code,
      orElse: () => DacFilterType.peaking,
    );
  }
}

/// Represents the hardware configuration of a single biquad PEQ filter band.
@immutable
class DacBandConfig {
  const DacBandConfig({
    required this.bandIndex,
    required this.frequency,
    required this.gainDb,
    this.qFactor = 0.707,
    this.filterType = DacFilterType.peaking,
    this.isBypassed = false,
  });

  /// Zero-based band index (0 to maxBands - 1).
  final int bandIndex;

  /// Center or cutoff frequency in Hertz (20.0 Hz to 20,000.0 Hz).
  final double frequency;

  /// Filter gain in decibels (-12.0 dB to +12.0 dB).
  final double gainDb;

  /// Quality factor / bandwidth Q (0.10 to 10.00).
  final double qFactor;

  /// Filter topology type.
  final DacFilterType filterType;

  /// Whether this individual band is currently bypassed.
  final bool isBypassed;

  /// Returns the frequency safely clamped to the DAC's operating range (20 Hz - 20 kHz).
  double get clampedFrequency => frequency.clamp(20.0, 20000.0);

  /// Returns the gain safely clamped to the DAC's operating range (-12 dB - +12 dB).
  double get clampedGainDb => gainDb.clamp(-12.0, 12.0);

  /// Returns the Q factor safely clamped (0.10 - 10.00).
  double get clampedQFactor => qFactor.clamp(0.10, 10.00);

  /// Formatted frequency string (e.g. "80 Hz" or "4.3 kHz").
  String get formattedFrequency {
    if (frequency >= 1000) {
      final khz = frequency / 1000.0;
      return khz >= 10 ? '${khz.round()} kHz' : '${khz.toStringAsFixed(1)} kHz';
    }
    return '${frequency.round()} Hz';
  }

  /// Formatted gain string (e.g. "+3.5 dB" or "-2.0 dB").
  String get formattedGain {
    final prefix = gainDb > 0 ? '+' : '';
    return '$prefix${gainDb.toStringAsFixed(1)} dB';
  }

  /// Formatted Q-factor string (e.g. "Q 0.71").
  String get formattedQ => 'Q ${qFactor.toStringAsFixed(2)}';

  DacBandConfig copyWith({
    int? bandIndex,
    double? frequency,
    double? gainDb,
    double? qFactor,
    DacFilterType? filterType,
    bool? isBypassed,
  }) {
    return DacBandConfig(
      bandIndex: bandIndex ?? this.bandIndex,
      frequency: frequency ?? this.frequency,
      gainDb: gainDb ?? this.gainDb,
      qFactor: qFactor ?? this.qFactor,
      filterType: filterType ?? this.filterType,
      isBypassed: isBypassed ?? this.isBypassed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bandIndex': bandIndex,
      'frequency': frequency,
      'gainDb': gainDb,
      'qFactor': qFactor,
      'filterType': filterType.name,
      'isBypassed': isBypassed,
    };
  }

  factory DacBandConfig.fromJson(Map<String, dynamic> json) {
    return DacBandConfig(
      bandIndex: json['bandIndex'] as int? ?? 0,
      frequency: (json['frequency'] as num?)?.toDouble() ?? 1000.0,
      gainDb: (json['gainDb'] as num?)?.toDouble() ?? 0.0,
      qFactor: (json['qFactor'] as num?)?.toDouble() ?? 0.707,
      filterType: json['filterType'] != null
          ? DacFilterType.values.firstWhere(
              (e) => e.name == json['filterType'],
              orElse: () => DacFilterType.peaking,
            )
          : DacFilterType.peaking,
      isBypassed: json['isBypassed'] as bool? ?? false,
    );
  }

  /// Default flat 5-band configuration matching Kiwi Ears AD1 factory defaults.
  static List<DacBandConfig> get defaultKiwiEars5Bands => const [
        DacBandConfig(bandIndex: 0, frequency: 28.0, gainDb: 0.0, qFactor: 0.70),
        DacBandConfig(bandIndex: 1, frequency: 84.0, gainDb: 0.0, qFactor: 0.70),
        DacBandConfig(bandIndex: 2, frequency: 680.0, gainDb: 0.0, qFactor: 0.70),
        DacBandConfig(bandIndex: 3, frequency: 4300.0, gainDb: 0.0, qFactor: 0.70),
        DacBandConfig(bandIndex: 4, frequency: 14500.0, gainDb: 0.0, qFactor: 0.70),
      ];

  /// Standard audiophile default 5-band PEQ setup.
  static List<DacBandConfig> get defaultStandard5Bands => const [
        DacBandConfig(bandIndex: 0, frequency: 60.0, gainDb: 0.0, qFactor: 0.707, filterType: DacFilterType.lowShelf),
        DacBandConfig(bandIndex: 1, frequency: 250.0, gainDb: 0.0, qFactor: 1.00),
        DacBandConfig(bandIndex: 2, frequency: 1000.0, gainDb: 0.0, qFactor: 1.00),
        DacBandConfig(bandIndex: 3, frequency: 4000.0, gainDb: 0.0, qFactor: 1.00),
        DacBandConfig(bandIndex: 4, frequency: 10000.0, gainDb: 0.0, qFactor: 0.707, filterType: DacFilterType.highShelf),
      ];

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DacBandConfig &&
        other.bandIndex == bandIndex &&
        other.frequency == frequency &&
        other.gainDb == gainDb &&
        other.qFactor == qFactor &&
        other.filterType == filterType &&
        other.isBypassed == isBypassed;
  }

  @override
  int get hashCode => Object.hash(
        bandIndex,
        frequency,
        gainDb,
        qFactor,
        filterType,
        isBypassed,
      );

  @override
  String toString() =>
      'DacBandConfig(Band #$bandIndex: $formattedFrequency, $formattedGain, $formattedQ, ${filterType.displayName})';
}
