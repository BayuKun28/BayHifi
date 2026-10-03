import 'dart:math' as math;

/// Model data untuk kurva respons frekuensi (Driver IEM atau Target Respons)
class FrCurveData {
  final String name;
  final List<double> frequencies; // Hz (20 - 20000)
  final List<double> splDb; // Raw SPL atau Normalized SPL (dB)
  final double referenceSpl1kHz;

  const FrCurveData({
    required this.name,
    required this.frequencies,
    required this.splDb,
    this.referenceSpl1kHz = 0.0,
  });

  FrCurveData copyWith({
    String? name,
    List<double>? frequencies,
    List<double>? splDb,
    double? referenceSpl1kHz,
  }) {
    return FrCurveData(
      name: name ?? this.name,
      frequencies: frequencies ?? this.frequencies,
      splDb: splDb ?? this.splDb,
      referenceSpl1kHz: referenceSpl1kHz ?? this.referenceSpl1kHz,
    );
  }

  /// Mengambil nilai SPL ternormalisasi (0 dB pada 1000 Hz) pada frekuensi f dengan interpolasi logaritmik
  double interpolateSpl(double freq) {
    if (frequencies.isEmpty) return 0.0;
    if (freq <= frequencies.first) return splDb.first - referenceSpl1kHz;
    if (freq >= frequencies.last) return splDb.last - referenceSpl1kHz;

    int low = 0;
    int high = frequencies.length - 1;

    while (high - low > 1) {
      final mid = (low + high) >> 1;
      if (frequencies[mid] >= freq) {
        high = mid;
      } else {
        low = mid;
      }
    }

    final fLow = frequencies[low];
    final fHigh = frequencies[high];
    final splLow = splDb[low] - referenceSpl1kHz;
    final splHigh = splDb[high] - referenceSpl1kHz;

    // Interpolasi logaritmik terhadap frekuensi
    final t = (math.log(freq) - math.log(fLow)) /
        (math.log(fHigh) - math.log(fLow));
    return splLow + t * (splHigh - splLow);
  }

  /// Parser untuk file REW V5 Measurement (contoh: KZ CASTOR BLACK DUDU R.txt)
  static FrCurveData parseRewV5(String content, {String name = 'Driver FR'}) {
    final lines = content.split('\n');
    final freqs = <double>[];
    final spls = <double>[];

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('*') || line.startsWith('#') || line.startsWith(';')) {
        continue;
      }

      final parts = line.split(RegExp(r'\s+'));
      if (parts.length >= 2) {
        final f = double.tryParse(parts[0]);
        final spl = double.tryParse(parts[1]);
        if (f != null && spl != null && f >= 15.0 && f <= 22000.0) {
          freqs.add(f);
          spls.add(spl);
        }
      }
    }

    final ref1k = _findSplAt1k(freqs, spls);
    return FrCurveData(
      name: name,
      frequencies: freqs,
      splDb: spls,
      referenceSpl1kHz: ref1k,
    );
  }

  /// Parser untuk file Squiglink / CSV Target (contoh: HBB Target.txt)
  static FrCurveData parseSquiglinkCsv(
    String content, {
    String name = 'Target',
  }) {
    final lines = content.split('\n');
    final freqs = <double>[];
    final spls = <double>[];

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('*') || line.startsWith('#') || line.startsWith(';')) {
        continue;
      }

      // Deteksi separator koma atau semicolon
      final delimiter = line.contains(';') ? ';' : ',';
      final parts = line.split(delimiter);
      if (parts.length >= 2) {
        final f = double.tryParse(parts[0].trim());
        final spl = double.tryParse(parts[1].trim());
        if (f != null && spl != null && f >= 15.0 && f <= 22000.0) {
          freqs.add(f);
          spls.add(spl);
        }
      }
    }

    final ref1k = _findSplAt1k(freqs, spls);
    return FrCurveData(
      name: name,
      frequencies: freqs,
      splDb: spls,
      referenceSpl1kHz: ref1k,
    );
  }

  /// Otomatis deteksi format (REW V5 whitespace vs CSV Squiglink)
  static FrCurveData autoDetectAndParse(String content, {String name = 'Measurement'}) {
    final lines = content.split('\n');
    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('*') || line.startsWith('#')) continue;
      if (line.contains(',') || line.contains(';')) {
        return parseSquiglinkCsv(content, name: name);
      } else {
        return parseRewV5(content, name: name);
      }
    }
    return parseRewV5(content, name: name);
  }

  static double _findSplAt1k(List<double> freqs, List<double> spls) {
    if (freqs.isEmpty) return 0.0;
    int closestIdx = 0;
    double minDiff = double.infinity;

    for (int i = 0; i < freqs.length; i++) {
      final diff = (freqs[i] - 1000.0).abs();
      if (diff < minDiff) {
        minDiff = diff;
        closestIdx = i;
      }
    }

    return spls[closestIdx];
  }

  Map<String, dynamic> toMap({String? category}) {
    final map = <String, dynamic>{
      'name': name,
      'frequencies': frequencies,
      'splDb': splDb,
      'referenceSpl1kHz': referenceSpl1kHz,
    };
    if (category != null) {
      map['category'] = category;
    }
    return map;
  }

  factory FrCurveData.fromMap(Map<String, dynamic> map) {
    return FrCurveData(
      name: map['name'] as String? ?? 'Curve',
      frequencies: (map['frequencies'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      splDb: (map['splDb'] as List<dynamic>?)
              ?.map((e) => (e as num).toDouble())
              .toList() ??
          [],
      referenceSpl1kHz: (map['referenceSpl1kHz'] as num?)?.toDouble() ?? 0.0,
    );
  }

  /// Koleksi kurva IEM/Headphone bawaan studio (Single Source of Truth)
  static final List<FrCurveData> defaultDrivers = [
    const FrCurveData(
      name: 'KZ CASTOR BLACK DUDU R',
      frequencies: [20, 100, 1000, 3000, 8000, 20000],
      splDb: [87.7, 86.5, 78.0, 88.5, 82.0, 72.0],
      referenceSpl1kHz: 78.0,
    ),
    const FrCurveData(
      name: 'Moondrop Chu II',
      frequencies: [20, 100, 1000, 3000, 8000, 20000],
      splDb: [85.0, 83.0, 75.0, 86.0, 79.0, 70.0],
      referenceSpl1kHz: 75.0,
    ),
    const FrCurveData(
      name: 'Sennheiser HD600',
      frequencies: [20, 100, 1000, 3000, 8000, 20000],
      splDb: [78.0, 80.0, 80.0, 88.0, 82.0, 74.0],
      referenceSpl1kHz: 80.0,
    ),
    const FrCurveData(
      name: 'Tangzu Wan\'er S.G',
      frequencies: [20, 100, 1000, 3000, 8000, 20000],
      splDb: [86.0, 84.0, 76.0, 87.0, 80.0, 71.0],
      referenceSpl1kHz: 76.0,
    ),
    const FrCurveData(
      name: '7Hz Zero:2',
      frequencies: [20, 100, 1000, 3000, 8000, 20000],
      splDb: [87.0, 85.0, 77.0, 87.5, 81.0, 72.0],
      referenceSpl1kHz: 77.0,
    ),
  ];

  /// Koleksi kurva Target Respons bawaan studio (Single Source of Truth)
  static final List<FrCurveData> defaultTargets = [
    const FrCurveData(
      name: 'HBB Target',
      frequencies: [20, 100, 1000, 3000, 8000, 20000],
      splDb: [107.5, 105.0, 95.0, 102.5, 96.0, 90.0],
      referenceSpl1kHz: 95.0,
    ),
    const FrCurveData(
      name: 'Harman In-Ear 2019v2',
      frequencies: [20, 100, 1000, 3000, 8000, 20000],
      splDb: [108.0, 106.0, 95.0, 104.0, 98.0, 88.0],
      referenceSpl1kHz: 95.0,
    ),
    const FrCurveData(
      name: 'IEF Neutral Target',
      frequencies: [20, 100, 1000, 3000, 8000, 20000],
      splDb: [95.0, 95.0, 95.0, 103.0, 97.0, 90.0],
      referenceSpl1kHz: 95.0,
    ),
    const FrCurveData(
      name: 'Harman Over-Ear 2018',
      frequencies: [20, 100, 1000, 3000, 8000, 20000],
      splDb: [104.5, 102.0, 95.0, 103.0, 96.5, 85.0],
      referenceSpl1kHz: 95.0,
    ),
  ];
}

