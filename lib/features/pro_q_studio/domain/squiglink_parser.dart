import 'package:flutter/foundation.dart';
import 'biquad_math.dart';
import 'eq_band.dart';

/// Hasil parsing file / teks format Squiglink atau Equalizer APO
@immutable
class SquiglinkParseResult {
  final double? preampDb;
  final List<EqBand> bands;
  final String rawText;

  const SquiglinkParseResult({
    this.preampDb,
    required this.bands,
    required this.rawText,
  });
}

/// Parser dan Exporter untuk format teks Squiglink EQ, Equalizer APO, dan Wavelet
class SquiglinkParser {
  /// Membaca teks Squiglink / Equalizer APO:
  /// Contoh:
  /// Preamp: -4.3 dB
  /// Filter 1: ON PK Fc 63 Hz Gain -1.1 dB Q 1.414
  /// Filter 2: ON LSQ Fc 105 Hz Gain 3.2 dB Q 0.707
  static SquiglinkParseResult parse(String text) {
    final lines = text.split('\n');
    double? parsedPreamp;
    final bands = <EqBand>[];

    final preampRegex = RegExp(
      r'Preamp:\s*([+-]?\d+(?:\.\d+)?)\s*dB',
      caseSensitive: false,
    );

    // Regex untuk: Filter 1: ON PK Fc 63 Hz Gain -1.1 dB Q 1.414
    // Mendukung variasi seperti: Filter: ON PK Fc 63.5 Hz Gain -1.1 dB Q 1.41
    final filterRegex = RegExp(
      r'Filter\s*(?:\d+)?:\s*(ON|OFF)\s+([A-Za-z0-9_]+)\s+Fc\s+([0-9.]+)\s*Hz\s+Gain\s+([+-]?[0-9.]+)\s*dB\s+Q\s+([0-9.]+)',
      caseSensitive: false,
    );

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty || line.startsWith('#') || line.startsWith('*')) {
        continue;
      }

      // Cek baris Preamp
      final preampMatch = preampRegex.firstMatch(line);
      if (preampMatch != null) {
        parsedPreamp = double.tryParse(preampMatch.group(1)!);
        continue;
      }

      // Cek baris Filter
      final filterMatch = filterRegex.firstMatch(line);
      if (filterMatch != null) {
        final onOff = filterMatch.group(1)!.toUpperCase();
        final typeStr = filterMatch.group(2)!.toUpperCase();
        final freqStr = filterMatch.group(3)!;
        final gainStr = filterMatch.group(4)!;
        final qStr = filterMatch.group(5)!;

        final isEnabled = onOff == 'ON';
        final freq = double.tryParse(freqStr) ?? 1000.0;
        final gain = double.tryParse(gainStr) ?? 0.0;
        final q = double.tryParse(qStr) ?? 1.414;

        final filterType = _parseFilterType(typeStr);
        final index = bands.length + 1;
        final color = EqBand.bandPalette[(index - 1) % EqBand.bandPalette.length];

        bands.add(EqBand(
          index: index,
          frequency: freq.clamp(20.0, 20000.0),
          gainDb: gain.clamp(-24.0, 24.0),
          q: q.clamp(0.1, 18.0),
          type: filterType,
          color: color,
          isEnabled: isEnabled,
        ));
      }
    }

    return SquiglinkParseResult(
      preampDb: parsedPreamp,
      bands: bands,
      rawText: text,
    );
  }

  /// Mengekspor daftar band EQ saat ini ke format teks standar Squiglink / Equalizer APO
  static String exportToSquiglink(List<EqBand> bands, {double? preampDb}) {
    final buffer = StringBuffer();
    final effectivePreamp = preampDb ?? BiquadMath.calculateSafePreamp(bands);

    buffer.writeln('Preamp: ${effectivePreamp.toStringAsFixed(1)} dB');

    for (int i = 0; i < bands.length; i++) {
      final b = bands[i];
      final onStr = b.isEnabled ? 'ON' : 'OFF';
      final typeStr = _filterTypeToSquiglink(b.type);
      final freqStr = b.frequency >= 100
          ? b.frequency.round().toString()
          : b.frequency.toStringAsFixed(1);
      final gainStr = b.gainDb >= 0
          ? '+${b.gainDb.toStringAsFixed(1)}'
          : b.gainDb.toStringAsFixed(1);
      final qStr = b.q.toStringAsFixed(3);

      buffer.writeln(
        'Filter ${i + 1}: $onStr $typeStr Fc $freqStr Hz Gain $gainStr dB Q $qStr',
      );
    }

    return buffer.toString().trim();
  }

  /// Mengekspor ke format Wavelet (GraphicEQ format yang populer di Android)
  static String exportToWavelet(List<EqBand> bands) {
    // Wavelet GraphicEQ format: GraphicEQ: 20 0.0; 25 0.5; ...
    final sampleFreqs = [
      20.0, 25.0, 31.5, 40.0, 50.0, 63.0, 80.0, 100.0, 125.0, 160.0,
      200.0, 250.0, 315.0, 400.0, 500.0, 630.0, 800.0, 1000.0, 1250.0, 1600.0,
      2000.0, 2500.0, 3150.0, 4000.0, 5000.0, 6300.0, 8000.0, 10000.0, 12500.0, 16000.0,
      20000.0,
    ];

    final buffer = StringBuffer('GraphicEQ: ');
    for (int i = 0; i < sampleFreqs.length; i++) {
      final f = sampleFreqs[i];
      final gain = BiquadMath.calculateCompositeGainDb(bands, f);
      final fStr = f >= 100 ? f.round().toString() : f.toStringAsFixed(1);
      buffer.write('$fStr ${gain.toStringAsFixed(1)}');
      if (i < sampleFreqs.length - 1) {
        buffer.write('; ');
      }
    }

    return buffer.toString();
  }

  static FilterType _parseFilterType(String typeStr) {
    switch (typeStr) {
      case 'PK':
      case 'PEAK':
      case 'PEAKING':
        return FilterType.peaking;
      case 'LSQ':
      case 'LSC':
      case 'LS':
      case 'LOWSHELF':
        return FilterType.lowShelf;
      case 'HSQ':
      case 'HSC':
      case 'HS':
      case 'HIGHSHELF':
        return FilterType.highShelf;
      case 'LP':
      case 'LPQ':
      case 'LOWPASS':
        return FilterType.lowPass;
      case 'HP':
      case 'HPQ':
      case 'HIGHPASS':
        return FilterType.highPass;
      case 'NO':
      case 'NOTCH':
        return FilterType.notch;
      default:
        return FilterType.peaking;
    }
  }

  static String _filterTypeToSquiglink(FilterType type) {
    switch (type) {
      case FilterType.peaking:
        return 'PK';
      case FilterType.lowShelf:
        return 'LSQ';
      case FilterType.highShelf:
        return 'HSQ';
      case FilterType.lowPass:
        return 'LP';
      case FilterType.highPass:
        return 'HP';
      case FilterType.notch:
        return 'NO';
    }
  }
}
