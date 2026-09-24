import 'package:flutter/foundation.dart';
import 'biquad_math.dart';
import 'eq_band.dart';
import 'fr_curve_data.dart';

/// Pilihan resolusi jumlah filter band untuk AutoEQ
enum BandResolution {
  b5(5, '5 B'),
  b10(10, '10 B'),
  b16(16, '16 B'),
  b20(20, '20 B'),
  b32(32, '32 B');

  final int count;
  final String label;
  const BandResolution(this.count, this.label);
}

/// Mode tuning: Normal (full dynamics) vs Safe (batasi boost untuk cegah distorsi)
enum TuningMode {
  normal('⚡ Normal', 'Full range compensation up to +12 dB boost'),
  safe('🛡️ Safe', 'Conservative compensation clamped at +6 dB boost');

  final String label;
  final String description;
  const TuningMode(this.label, this.description);
}

/// Mode perbandingan A/B: A (suara murni headphone tanpa EQ) vs B (suara dengan EQ aktif)
enum AbComparisonMode {
  aRaw('🎚️ A: RAW', 'Bypassed flat audio (direct driver sound)'),
  bActive('🎚️ B: ACTIVE', 'Equalized tuned audio (target compensation)');

  final String label;
  final String description;
  const AbComparisonMode(this.label, this.description);
}

/// Hasil komputasi AutoEQ
@immutable
class AutoEqResult {
  final List<EqBand> bands;
  final double safePreampDb;
  final double maxBoostDb;
  final double maxCutDb;
  final double target1kHzReference;

  const AutoEqResult({
    required this.bands,
    required this.safePreampDb,
    required this.maxBoostDb,
    required this.maxCutDb,
    required this.target1kHzReference,
  });
}

/// Engine pengoptimalan biquad filter untuk mencocokkan kurva driver IEM ke kurva target
class AutoEqOptimizer {
  // Frekuensi standar ISO center frequencies untuk masing-masing resolusi
  static const List<double> centers5B = [63.0, 250.0, 1000.0, 4000.0, 12000.0];

  static const List<double> centers10B = [
    31.5, 63.0, 125.0, 250.0, 500.0, 1000.0, 2000.0, 4000.0, 8000.0, 16000.0,
  ];

  static const List<double> centers16B = [
    25.0, 40.0, 63.0, 100.0, 160.0, 250.0, 400.0, 630.0,
    1000.0, 1600.0, 2500.0, 4000.0, 6300.0, 10000.0, 14000.0, 18000.0,
  ];

  static const List<double> centers20B = [
    25.0, 35.0, 50.0, 71.0, 100.0, 140.0, 200.0, 280.0, 400.0, 560.0,
    800.0, 1120.0, 1600.0, 2240.0, 3150.0, 4500.0, 6300.0, 9000.0, 12500.0, 18000.0,
  ];

  static const List<double> centers32B = [
    20.0, 25.0, 31.5, 40.0, 50.0, 63.0, 80.0, 100.0, 125.0, 160.0,
    200.0, 250.0, 315.0, 400.0, 500.0, 630.0, 800.0, 1000.0, 1250.0, 1600.0,
    2000.0, 2500.0, 3150.0, 4000.0, 5000.0, 6300.0, 8000.0, 10000.0, 12500.0, 16000.0,
    18000.0, 20000.0,
  ];

  /// Menghitung delta curve: ΔSPL(f) = SPL_target(f) - SPL_driver(f)
  static double calculateDeltaSpl(
    double freq, {
    required FrCurveData driverFr,
    required FrCurveData targetFr,
  }) {
    final driverNorm = driverFr.interpolateSpl(freq);
    final targetNorm = targetFr.interpolateSpl(freq);
    return targetNorm - driverNorm;
  }

  /// Menjalankan optimasi AutoEQ
  static AutoEqResult optimize({
    required FrCurveData driverFr,
    required FrCurveData targetFr,
    required BandResolution resolution,
    required TuningMode mode,
  }) {
    final List<double> baseCenters = switch (resolution) {
      BandResolution.b5 => centers5B,
      BandResolution.b10 => centers10B,
      BandResolution.b16 => centers16B,
      BandResolution.b20 => centers20B,
      BandResolution.b32 => centers32B,
    };

    final double defaultQ = switch (resolution) {
      BandResolution.b5 => 1.0,
      BandResolution.b10 => 1.414,
      BandResolution.b16 => 2.0,
      BandResolution.b20 => 2.8,
      BandResolution.b32 => 4.3,
    };

    final maxBoost = mode == TuningMode.safe ? 6.0 : 12.0;
    final maxCut = mode == TuningMode.safe ? -12.0 : -18.0;

    final bands = <EqBand>[];
    double actualMaxBoost = 0.0;
    double actualMaxCut = 0.0;

    for (int i = 0; i < baseCenters.length; i++) {
      final centerFreq = baseCenters[i];

      // Deteksi deviasi ekstrem di sekitar center frequency
      final (optimalFreq, rawGain) = _findOptimalPeakOrDip(
        centerFreq,
        driverFr: driverFr,
        targetFr: targetFr,
      );

      // Batasi gain sesuai mode tuning
      final clampedGain = rawGain.clamp(maxCut, maxBoost);
      final roundedGain = (clampedGain * 10.0).round() / 10.0;
      final roundedFreq = (optimalFreq * 10.0).round() / 10.0;

      if (roundedGain > actualMaxBoost) actualMaxBoost = roundedGain;
      if (roundedGain < actualMaxCut) actualMaxCut = roundedGain;

      final color = EqBand.bandPalette[i % EqBand.bandPalette.length];

      bands.add(EqBand(
        index: i + 1,
        frequency: roundedFreq,
        gainDb: roundedGain,
        q: defaultQ,
        type: FilterType.peaking,
        color: color,
        isEnabled: true,
      ));
    }

    final safePreamp = BiquadMath.calculateSafePreamp(bands);

    return AutoEqResult(
      bands: bands,
      safePreampDb: safePreamp,
      maxBoostDb: actualMaxBoost,
      maxCutDb: actualMaxCut,
      target1kHzReference: targetFr.referenceSpl1kHz,
    );
  }

  /// Mencari frekuensi dengan nilai selisih deviasi absolut terbesar di dalam band frekuensi
  static (double freq, double gain) _findOptimalPeakOrDip(
    double baseFreq, {
    required FrCurveData driverFr,
    required FrCurveData targetFr,
  }) {
    // Cari 5 titik sampling di sekitar baseFreq: 0.92, 0.96, 1.0, 1.04, 1.08
    final ratios = [0.92, 0.96, 1.0, 1.04, 1.08];
    double bestFreq = baseFreq;
    double maxDeviation = calculateDeltaSpl(baseFreq, driverFr: driverFr, targetFr: targetFr);

    for (final r in ratios) {
      final testFreq = (baseFreq * r).clamp(20.0, 20000.0);
      final testDelta = calculateDeltaSpl(testFreq, driverFr: driverFr, targetFr: targetFr);

      if (testDelta.abs() > maxDeviation.abs()) {
        maxDeviation = testDelta;
        bestFreq = testFreq;
      }
    }

    return (bestFreq, maxDeviation);
  }
}
