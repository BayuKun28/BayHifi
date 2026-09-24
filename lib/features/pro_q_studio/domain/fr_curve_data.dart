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
      if (line.isEmpty || line.startsWith('*') || line.startsWith('#')) {
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
      if (line.isEmpty || line.startsWith('*') || line.startsWith('#')) {
        continue;
      }

      final parts = line.split(',');
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
}
