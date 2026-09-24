import 'dart:math' as math;
import 'eq_band.dart';

/// Koefisien biquad filter ternormalisasi (a0 = 1.0)
class BiquadCoefficients {
  final double b0;
  final double b1;
  final double b2;
  final double a1;
  final double a2;

  const BiquadCoefficients({
    required this.b0,
    required this.b1,
    required this.b2,
    required this.a1,
    required this.a2,
  });

  /// Evaluasi gain filter dalam dB pada frekuensi tertentu f (Hz)
  double evaluateGainDb(double freq, double sampleRate) {
    final omega = 2.0 * math.pi * freq / sampleRate;
    final cosW = math.cos(omega);
    final sinW = math.sin(omega);
    final cos2W = math.cos(2.0 * omega);
    final sin2W = math.sin(2.0 * omega);

    // Numerator: b0 + b1*z^-1 + b2*z^-2
    final numReal = b0 + b1 * cosW + b2 * cos2W;
    final numImag = -(b1 * sinW + b2 * sin2W);

    // Denominator: 1.0 + a1*z^-1 + a2*z^-2
    final denReal = 1.0 + a1 * cosW + a2 * cos2W;
    final denImag = -(a1 * sinW + a2 * sin2W);

    final numMagSq = numReal * numReal + numImag * numImag;
    final denMagSq = denReal * denReal + denImag * denImag;

    if (denMagSq <= 0.0) return 0.0;
    final magSq = numMagSq / denMagSq;
    if (magSq <= 0.0) return -60.0;

    return 10.0 * (math.log(magSq) / math.ln10);
  }
}

/// Mesin kalkulasi Biquad Cookbook Robert Bristow-Johnson (Pure Functions)
class BiquadMath {
  BiquadMath._();

  /// Menghitung koefisien biquad untuk sebuah EqBand
  static BiquadCoefficients calculateCoefficients(
    EqBand band, {
    double sampleRate = 48000.0,
  }) {
    final f0 = band.frequency.clamp(20.0, sampleRate / 2.0 - 100.0);
    final gainDb = band.gainDb;
    final q = band.q.clamp(0.1, 18.0);

    final w0 = 2.0 * math.pi * f0 / sampleRate;
    final cosW0 = math.cos(w0);
    final sinW0 = math.sin(w0);
    final alpha = sinW0 / (2.0 * q);
    final a = math.pow(10.0, gainDb / 40.0).toDouble(); // sqrt(10^(dB/20))

    double b0, b1, b2, a0, a1, a2;

    switch (band.type) {
      case FilterType.peaking:
        b0 = 1.0 + alpha * a;
        b1 = -2.0 * cosW0;
        b2 = 1.0 - alpha * a;
        a0 = 1.0 + alpha / a;
        a1 = -2.0 * cosW0;
        a2 = 1.0 - alpha / a;
        break;

      case FilterType.lowShelf:
        final twoSqrtAAlpha = 2.0 * math.sqrt(a) * alpha;
        b0 = a * ((a + 1.0) - (a - 1.0) * cosW0 + twoSqrtAAlpha);
        b1 = 2.0 * a * ((a - 1.0) - (a + 1.0) * cosW0);
        b2 = a * ((a + 1.0) - (a - 1.0) * cosW0 - twoSqrtAAlpha);
        a0 = (a + 1.0) + (a - 1.0) * cosW0 + twoSqrtAAlpha;
        a1 = -2.0 * ((a - 1.0) + (a + 1.0) * cosW0);
        a2 = (a + 1.0) + (a - 1.0) * cosW0 - twoSqrtAAlpha;
        break;

      case FilterType.highShelf:
        final twoSqrtAAlpha = 2.0 * math.sqrt(a) * alpha;
        b0 = a * ((a + 1.0) + (a - 1.0) * cosW0 + twoSqrtAAlpha);
        b1 = -2.0 * a * ((a - 1.0) + (a + 1.0) * cosW0);
        b2 = a * ((a + 1.0) + (a - 1.0) * cosW0 - twoSqrtAAlpha);
        a0 = (a + 1.0) - (a - 1.0) * cosW0 + twoSqrtAAlpha;
        a1 = 2.0 * ((a - 1.0) - (a + 1.0) * cosW0);
        a2 = (a + 1.0) - (a - 1.0) * cosW0 - twoSqrtAAlpha;
        break;

      case FilterType.lowPass:
        b0 = (1.0 - cosW0) / 2.0;
        b1 = 1.0 - cosW0;
        b2 = (1.0 - cosW0) / 2.0;
        a0 = 1.0 + alpha;
        a1 = -2.0 * cosW0;
        a2 = 1.0 - alpha;
        break;

      case FilterType.highPass:
        b0 = (1.0 + cosW0) / 2.0;
        b1 = -(1.0 + cosW0);
        b2 = (1.0 + cosW0) / 2.0;
        a0 = 1.0 + alpha;
        a1 = -2.0 * cosW0;
        a2 = 1.0 - alpha;
        break;

      case FilterType.notch:
        b0 = 1.0;
        b1 = -2.0 * cosW0;
        b2 = 1.0;
        a0 = 1.0 + alpha;
        a1 = -2.0 * cosW0;
        a2 = 1.0 - alpha;
        break;
    }

    // Normalisasi dengan a0
    return BiquadCoefficients(
      b0: b0 / a0,
      b1: b1 / a0,
      b2: b2 / a0,
      a1: a1 / a0,
      a2: a2 / a0,
    );
  }

  /// Menghitung total gain gabungan seluruh band aktif pada frekuensi tunggal
  static double calculateCompositeGainDb(
    List<EqBand> bands,
    double freq, {
    double sampleRate = 48000.0,
  }) {
    return evaluateCompositeCurve(bands, [freq], sampleRate: sampleRate).first;
  }

  /// Menghitung kurva gabungan seluruh band aktif pada daftar frekuensi
  static List<double> evaluateCompositeCurve(
    List<EqBand> bands,
    List<double> frequencies, {
    double sampleRate = 48000.0,
  }) {
    final activeCoeffs = bands
        .where((b) => b.isEnabled)
        .map((b) => calculateCoefficients(b, sampleRate: sampleRate))
        .toList();

    return frequencies.map((f) {
      double totalDb = 0.0;
      for (final coeff in activeCoeffs) {
        totalDb += coeff.evaluateGainDb(f, sampleRate);
      }
      return totalDb;
    }).toList();
  }

  /// Menghitung rekomendasi atenuasi pre-amp aman (Safe Headroom)
  static double calculateSafePreamp(
    List<EqBand> bands, {
    double sampleRate = 48000.0,
    int testPoints = 100,
  }) {
    if (bands.isEmpty) return 0.0;

    // Evaluasi 100 titik logaritmik antara 20 Hz dan 20,000 Hz
    double maxGain = 0.0;
    for (int i = 0; i < testPoints; i++) {
      final f = 20.0 * math.pow(1000.0, i / testPoints);
      double totalDb = 0.0;
      for (final band in bands.where((b) => b.isEnabled)) {
        final coeff = calculateCoefficients(band, sampleRate: sampleRate);
        totalDb += coeff.evaluateGainDb(f, sampleRate);
      }
      if (totalDb > maxGain) {
        maxGain = totalDb;
      }
    }

    if (maxGain <= 0.0) return 0.0;
    // Berikan margin 0.5 dB untuk mencegah inter-sample peaks
    return -((maxGain + 0.5) * 10).round() / 10.0;
  }
}
