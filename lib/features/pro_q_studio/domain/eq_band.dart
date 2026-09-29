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

  static List<EqBand> get default10Bands => [
        const EqBand(
          index: 1,
          frequency: 63.0,
          gainDb: -1.1,
          q: 1.41,
          type: FilterType.peaking,
          color: Color(0xFF26C6DA),
        ),
        const EqBand(
          index: 2,
          frequency: 226.0,
          gainDb: 4.4,
          q: 1.41,
          type: FilterType.peaking,
          color: Color(0xFFEC407A),
        ),
        const EqBand(
          index: 3,
          frequency: 1100.0,
          gainDb: -0.9,
          q: 1.41,
          type: FilterType.peaking,
          color: Color(0xFFFFCA28),
        ),
        const EqBand(
          index: 4,
          frequency: 1700.0,
          gainDb: 0.8,
          q: 1.41,
          type: FilterType.peaking,
          color: Color(0xFF66BB6A),
        ),
        const EqBand(
          index: 5,
          frequency: 2800.0,
          gainDb: -1.6,
          q: 1.41,
          type: FilterType.peaking,
          color: Color(0xFFAB47BC),
        ),
        const EqBand(
          index: 6,
          frequency: 4600.0,
          gainDb: -3.1,
          q: 1.41,
          type: FilterType.peaking,
          color: Color(0xFFFF7043),
        ),
        const EqBand(
          index: 7,
          frequency: 7000.0,
          gainDb: 2.9,
          q: 1.41,
          type: FilterType.peaking,
          color: Color(0xFF26A69A),
        ),
        const EqBand(
          index: 8,
          frequency: 8600.0,
          gainDb: -5.0,
          q: 1.41,
          type: FilterType.peaking,
          color: Color(0xFFEF5350),
        ),
        const EqBand(
          index: 9,
          frequency: 13000.0,
          gainDb: -3.4,
          q: 1.41,
          type: FilterType.peaking,
          color: Color(0xFF29B6F6),
        ),
        const EqBand(
          index: 10,
          frequency: 18500.0,
          gainDb: 1.0,
          q: 1.41,
          type: FilterType.peaking,
          color: Color(0xFFD4E157),
        ),
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

