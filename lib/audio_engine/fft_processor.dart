import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'soloud_controller.dart';

/// Provider data RTA spektrum audio real-time terdistribusi logaritmik (20Hz - 20kHz).
final rtaSpectrumProvider = StreamProvider<List<double>>((ref) {
  final processor = FftProcessor(bandCount: 48);
  return SoLoudController.instance.visualizationEvents
      .map((data) => processor.processFft(data));
});

/// Processor untuk mengkonversi raw FFT bins menjadi RTA bars berdistribusi logaritmik.
class FftProcessor {
  final int bandCount;
  final double minFreq;
  final double maxFreq;
  final double sampleRate;

  final Float64List _smoothedValues;
  final Float64List _peakValues;

  FftProcessor({
    this.bandCount = 48,
    this.minFreq = 20.0,
    this.maxFreq = 20000.0,
    this.sampleRate = 48000.0,
  })  : _smoothedValues = Float64List(bandCount),
        _peakValues = Float64List(bandCount);

  List<double> processFft(AudioVisualizationData data) {
    final rawFft = data.fftData;
    if (rawFft == null || rawFft.isEmpty) {
      // Decay perlahan ke nol saat hening
      for (int i = 0; i < bandCount; i++) {
        _smoothedValues[i] *= 0.85;
      }
      return Float64List.fromList(_smoothedValues);
    }

    final fftSize = rawFft.length;
    final nyquist = sampleRate / 2.0;

    for (int i = 0; i < bandCount; i++) {
      // Hitung batas frekuensi logaritmik untuk band i
      final fLow = minFreq * math.pow(maxFreq / minFreq, i / bandCount);
      final fHigh = minFreq * math.pow(maxFreq / minFreq, (i + 1) / bandCount);

      final binLow = ((fLow / nyquist) * fftSize).floor().clamp(0, fftSize - 1);
      final binHigh = ((fHigh / nyquist) * fftSize).ceil().clamp(binLow + 1, fftSize);

      double sum = 0.0;
      int count = 0;
      for (int b = binLow; b < binHigh; b++) {
        sum += rawFft[b];
        count++;
      }

      final avgMagnitude = count > 0 ? sum / count : 0.0;

      // Konversi magnitude ke nilai ternormalisasi [0.0, 1.0] dengan boost responsif
      final normalized = (avgMagnitude * 2.5).clamp(0.0, 1.0);

      // Smooth decay (Peak attack cepat, release lembut)
      if (normalized > _smoothedValues[i]) {
        _smoothedValues[i] = normalized; // instant attack
      } else {
        _smoothedValues[i] = _smoothedValues[i] * 0.82 + normalized * 0.18; // smooth release
      }

      if (_smoothedValues[i] > _peakValues[i]) {
        _peakValues[i] = _smoothedValues[i];
      } else {
        _peakValues[i] *= 0.95;
      }
    }

    return Float64List.fromList(_smoothedValues);
  }
}
