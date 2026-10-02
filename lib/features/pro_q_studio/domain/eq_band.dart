import 'package:flutter/material.dart';

enum FilterType {
  peaking,
  lowShelf,
  highShelf,
  lowPass,
  highPass,
  notch;

  String get displayName {
    switch (this) {
      case FilterType.peaking:
        return 'Bell / Peaking';
      case FilterType.lowShelf:
        return 'Low Shelf';
      case FilterType.highShelf:
        return 'High Shelf';
      case FilterType.lowPass:
        return 'Low Pass';
      case FilterType.highPass:
        return 'High Pass';
      case FilterType.notch:
        return 'Notch';
    }
  }

  String get shortName {
    switch (this) {
      case FilterType.peaking:
        return 'PK';
      case FilterType.lowShelf:
        return 'LS';
      case FilterType.highShelf:
        return 'HS';
      case FilterType.lowPass:
        return 'LP';
      case FilterType.highPass:
        return 'HP';
      case FilterType.notch:
        return 'NO';
    }
  }
}

@immutable
class EqBand {
  final int index; // 1-indexed (1, 2, ..., 10)
  final double frequency; // 20 Hz - 20,000 Hz
  final double gainDb; // -24 dB to +24 dB
  final double q; // 0.1 to 18.0
  final FilterType type;
  final bool isEnabled;
  final Color color;

  const EqBand({
    required this.index,
    required this.frequency,
    required this.gainDb,
    this.q = 1.414,
    this.type = FilterType.peaking,
    this.isEnabled = true,
    this.color = const Color(0xFFFF9F0A),
  });

  String get formattedFreq {
    if (frequency >= 1000) {
      final k = frequency / 1000.0;
      return '${k.toStringAsFixed(k >= 10 ? 0 : 1)}k';
    }
    return '${frequency.round()}';
  }

  String get formattedGain {
    final prefix = gainDb > 0 ? '+' : '';
    return '$prefix${gainDb.toStringAsFixed(1)}';
  }

  EqBand copyWith({
    int? index,
    double? frequency,
    double? gainDb,
    double? q,
    FilterType? type,
    bool? isEnabled,
    Color? color,
  }) {
    return EqBand(
      index: index ?? this.index,
      frequency: frequency ?? this.frequency,
      gainDb: gainDb ?? this.gainDb,
      q: q ?? this.q,
      type: type ?? this.type,
      isEnabled: isEnabled ?? this.isEnabled,
      color: color ?? this.color,
    );
  }

  static const List<Color> bandPalette = [
    Color(0xFF26C6DA), // B1 Cyan
    Color(0xFFEC407A), // B2 Pink
    Color(0xFFFFCA28), // B3 Amber/Yellow
    Color(0xFF66BB6A), // B4 Mint Green
    Color(0xFFAB47BC), // B5 Purple
    Color(0xFFFF7043), // B6 Coral/Orange
    Color(0xFF26A69A), // B7 Teal
    Color(0xFFEF5350), // B8 Red
    Color(0xFF29B6F6), // B9 Sky Blue
    Color(0xFFD4E157), // B10 Lime
  ];

  static List<EqBand> get default10Bands => audiophileWarmthBands;

  /// Studio Audiophile Warmth (Baydev Signature Reference Curve)
  static List<EqBand> get audiophileWarmthBands => [
        const EqBand(
          index: 1,
          frequency: 48.0,
          gainDb: 1.8,
          q: 0.70,
          type: FilterType.lowShelf,
          color: Color(0xFF26C6DA),
        ),
        const EqBand(
          index: 2,
          frequency: 110.0,
          gainDb: 0.8,
          q: 1.10,
          type: FilterType.peaking,
          color: Color(0xFFEC407A),
        ),
        const EqBand(
          index: 3,
          frequency: 280.0,
          gainDb: -0.8,
          q: 1.25,
          type: FilterType.peaking,
          color: Color(0xFFFFCA28),
        ),
        const EqBand(
          index: 4,
          frequency: 650.0,
          gainDb: 0.0,
          q: 1.41,
          type: FilterType.peaking,
          color: Color(0xFF66BB6A),
        ),
        const EqBand(
          index: 5,
          frequency: 1500.0,
          gainDb: 0.4,
          q: 1.41,
          type: FilterType.peaking,
          color: Color(0xFFAB47BC),
        ),
        const EqBand(
          index: 6,
          frequency: 3200.0,
          gainDb: 1.2,
          q: 1.00,
          type: FilterType.peaking,
          color: Color(0xFFFF7043),
        ),
        const EqBand(
          index: 7,
          frequency: 5500.0,
          gainDb: 0.0,
          q: 1.41,
          type: FilterType.peaking,
          color: Color(0xFF26A69A),
        ),
        const EqBand(
          index: 8,
          frequency: 8200.0,
          gainDb: -0.6,
          q: 1.80,
          type: FilterType.peaking,
          color: Color(0xFFEF5350),
        ),
        const EqBand(
          index: 9,
          frequency: 12000.0,
          gainDb: 1.2,
          q: 1.00,
          type: FilterType.peaking,
          color: Color(0xFF29B6F6),
        ),
        const EqBand(
          index: 10,
          frequency: 16000.0,
          gainDb: 1.6,
          q: 0.70,
          type: FilterType.highShelf,
          color: Color(0xFFD4E157),
        ),
      ];

  /// Audiophile Bit-Perfect (Pure Flat 0.0 dB Passthrough)
  static List<EqBand> get flatBands => [
        const EqBand(index: 1, frequency: 31.0, gainDb: 0.0, q: 1.41, type: FilterType.peaking, color: Color(0xFF26C6DA)),
        const EqBand(index: 2, frequency: 63.0, gainDb: 0.0, q: 1.41, type: FilterType.peaking, color: Color(0xFFEC407A)),
        const EqBand(index: 3, frequency: 125.0, gainDb: 0.0, q: 1.41, type: FilterType.peaking, color: Color(0xFFFFCA28)),
        const EqBand(index: 4, frequency: 250.0, gainDb: 0.0, q: 1.41, type: FilterType.peaking, color: Color(0xFF66BB6A)),
        const EqBand(index: 5, frequency: 500.0, gainDb: 0.0, q: 1.41, type: FilterType.peaking, color: Color(0xFFAB47BC)),
        const EqBand(index: 6, frequency: 1000.0, gainDb: 0.0, q: 1.41, type: FilterType.peaking, color: Color(0xFFFF7043)),
        const EqBand(index: 7, frequency: 2000.0, gainDb: 0.0, q: 1.41, type: FilterType.peaking, color: Color(0xFF26A69A)),
        const EqBand(index: 8, frequency: 4000.0, gainDb: 0.0, q: 1.41, type: FilterType.peaking, color: Color(0xFFEF5350)),
        const EqBand(index: 9, frequency: 8000.0, gainDb: 0.0, q: 1.41, type: FilterType.peaking, color: Color(0xFF29B6F6)),
        const EqBand(index: 10, frequency: 16000.0, gainDb: 0.0, q: 1.41, type: FilterType.peaking, color: Color(0xFFD4E157)),
      ];

  /// Harman 2019 In-Ear Target Acoustic Reference
  static List<EqBand> get harmanTargetBands => [
        const EqBand(index: 1, frequency: 45.0, gainDb: 4.5, q: 0.70, type: FilterType.lowShelf, color: Color(0xFF26C6DA)),
        const EqBand(index: 2, frequency: 105.0, gainDb: 2.0, q: 1.20, type: FilterType.peaking, color: Color(0xFFEC407A)),
        const EqBand(index: 3, frequency: 220.0, gainDb: -0.5, q: 1.41, type: FilterType.peaking, color: Color(0xFFFFCA28)),
        const EqBand(index: 4, frequency: 650.0, gainDb: 0.0, q: 1.41, type: FilterType.peaking, color: Color(0xFF66BB6A)),
        const EqBand(index: 5, frequency: 1400.0, gainDb: 1.0, q: 1.41, type: FilterType.peaking, color: Color(0xFFAB47BC)),
        const EqBand(index: 6, frequency: 3000.0, gainDb: 3.2, q: 1.00, type: FilterType.peaking, color: Color(0xFFFF7043)),
        const EqBand(index: 7, frequency: 5800.0, gainDb: 0.5, q: 1.41, type: FilterType.peaking, color: Color(0xFF26A69A)),
        const EqBand(index: 8, frequency: 8000.0, gainDb: -1.2, q: 1.60, type: FilterType.peaking, color: Color(0xFFEF5350)),
        const EqBand(index: 9, frequency: 12000.0, gainDb: 1.0, q: 1.00, type: FilterType.peaking, color: Color(0xFF29B6F6)),
        const EqBand(index: 10, frequency: 16000.0, gainDb: 1.8, q: 0.70, type: FilterType.highShelf, color: Color(0xFFD4E157)),
      ];

  /// Vocal & Acoustic Intimacy
  static List<EqBand> get vocalAcousticBands => [
        const EqBand(index: 1, frequency: 50.0, gainDb: 0.5, q: 0.70, type: FilterType.lowShelf, color: Color(0xFF26C6DA)),
        const EqBand(index: 2, frequency: 120.0, gainDb: 0.0, q: 1.41, type: FilterType.peaking, color: Color(0xFFEC407A)),
        const EqBand(index: 3, frequency: 250.0, gainDb: -1.2, q: 1.30, type: FilterType.peaking, color: Color(0xFFFFCA28)),
        const EqBand(index: 4, frequency: 600.0, gainDb: 0.5, q: 1.41, type: FilterType.peaking, color: Color(0xFF66BB6A)),
        const EqBand(index: 5, frequency: 1500.0, gainDb: 1.8, q: 1.20, type: FilterType.peaking, color: Color(0xFFAB47BC)),
        const EqBand(index: 6, frequency: 3500.0, gainDb: 2.8, q: 1.10, type: FilterType.peaking, color: Color(0xFFFF7043)),
        const EqBand(index: 7, frequency: 6000.0, gainDb: 0.8, q: 1.41, type: FilterType.peaking, color: Color(0xFF26A69A)),
        const EqBand(index: 8, frequency: 8500.0, gainDb: -0.5, q: 1.60, type: FilterType.peaking, color: Color(0xFFEF5350)),
        const EqBand(index: 9, frequency: 12000.0, gainDb: 1.5, q: 1.00, type: FilterType.peaking, color: Color(0xFF29B6F6)),
        const EqBand(index: 10, frequency: 16000.0, gainDb: 2.0, q: 0.70, type: FilterType.highShelf, color: Color(0xFFD4E157)),
      ];

  /// Deep Bass & Club Sub-Impact
  static List<EqBand> get deepBassBands => [
        const EqBand(index: 1, frequency: 45.0, gainDb: 5.2, q: 0.70, type: FilterType.lowShelf, color: Color(0xFF26C6DA)),
        const EqBand(index: 2, frequency: 100.0, gainDb: 3.0, q: 1.10, type: FilterType.peaking, color: Color(0xFFEC407A)),
        const EqBand(index: 3, frequency: 250.0, gainDb: -1.0, q: 1.41, type: FilterType.peaking, color: Color(0xFFFFCA28)),
        const EqBand(index: 4, frequency: 500.0, gainDb: -0.5, q: 1.41, type: FilterType.peaking, color: Color(0xFF66BB6A)),
        const EqBand(index: 5, frequency: 1200.0, gainDb: 0.0, q: 1.41, type: FilterType.peaking, color: Color(0xFFAB47BC)),
        const EqBand(index: 6, frequency: 3000.0, gainDb: 1.0, q: 1.20, type: FilterType.peaking, color: Color(0xFFFF7043)),
        const EqBand(index: 7, frequency: 6000.0, gainDb: 0.5, q: 1.41, type: FilterType.peaking, color: Color(0xFF26A69A)),
        const EqBand(index: 8, frequency: 8000.0, gainDb: -0.5, q: 1.60, type: FilterType.peaking, color: Color(0xFFEF5350)),
        const EqBand(index: 9, frequency: 11000.0, gainDb: 1.8, q: 1.00, type: FilterType.peaking, color: Color(0xFF29B6F6)),
        const EqBand(index: 10, frequency: 16000.0, gainDb: 2.2, q: 0.70, type: FilterType.highShelf, color: Color(0xFFD4E157)),
      ];

  /// Air & High-Res Micro-Detail
  static List<EqBand> get airSparkleBands => [
        const EqBand(index: 1, frequency: 45.0, gainDb: 1.0, q: 0.70, type: FilterType.lowShelf, color: Color(0xFF26C6DA)),
        const EqBand(index: 2, frequency: 110.0, gainDb: 0.0, q: 1.41, type: FilterType.peaking, color: Color(0xFFEC407A)),
        const EqBand(index: 3, frequency: 280.0, gainDb: -0.8, q: 1.41, type: FilterType.peaking, color: Color(0xFFFFCA28)),
        const EqBand(index: 4, frequency: 650.0, gainDb: 0.0, q: 1.41, type: FilterType.peaking, color: Color(0xFF66BB6A)),
        const EqBand(index: 5, frequency: 1500.0, gainDb: 0.5, q: 1.41, type: FilterType.peaking, color: Color(0xFFAB47BC)),
        const EqBand(index: 6, frequency: 3800.0, gainDb: 1.8, q: 1.10, type: FilterType.peaking, color: Color(0xFFFF7043)),
        const EqBand(index: 7, frequency: 7000.0, gainDb: 2.2, q: 1.20, type: FilterType.peaking, color: Color(0xFF26A69A)),
        const EqBand(index: 8, frequency: 10000.0, gainDb: 2.8, q: 1.00, type: FilterType.peaking, color: Color(0xFFEF5350)),
        const EqBand(index: 9, frequency: 13500.0, gainDb: 3.2, q: 0.90, type: FilterType.peaking, color: Color(0xFF29B6F6)),
        const EqBand(index: 10, frequency: 17000.0, gainDb: 3.5, q: 0.70, type: FilterType.highShelf, color: Color(0xFFD4E157)),
      ];

  Map<String, dynamic> toMap() => {
        'index': index,
        'frequency': frequency,
        'gainDb': gainDb,
        'q': q,
        'type': type.name,
        'isEnabled': isEnabled,
      };

  static EqBand fromMap(Map<String, dynamic> map, {int fallbackIndex = 1}) {
    final typeStr = map['type'] as String? ?? 'peaking';
    final filterType = FilterType.values.firstWhere(
      (t) => t.name == typeStr,
      orElse: () => FilterType.peaking,
    );
    final idx = (map['index'] as int?) ?? fallbackIndex;
    final color = EqBand.bandPalette[(idx - 1).clamp(0, bandPalette.length - 1)];
    return EqBand(
      index: idx,
      frequency: (map['frequency'] as num? ?? 1000.0).toDouble(),
      gainDb: (map['gainDb'] as num? ?? 0.0).toDouble(),
      q: (map['q'] as num? ?? 1.414).toDouble(),
      type: filterType,
      isEnabled: map['isEnabled'] as bool? ?? true,
      color: color,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EqBand &&
          runtimeType == other.runtimeType &&
          index == other.index &&
          frequency == other.frequency &&
          gainDb == other.gainDb &&
          q == other.q &&
          type == other.type &&
          isEnabled == other.isEnabled;

  @override
  int get hashCode => Object.hash(index, frequency, gainDb, q, type, isEnabled);
}

