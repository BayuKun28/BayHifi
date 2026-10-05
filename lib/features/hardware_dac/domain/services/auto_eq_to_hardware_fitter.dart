import 'dart:math' as math;
import '../../../../features/pro_q_studio/domain/eq_band.dart';
import '../models/dac_band_config.dart';
import '../models/dac_device.dart';
import '../models/dac_peq_profile.dart';

/// Intelligent curve fitting engine that downsamples multi-band software EQ (AutoEQ / Pro-Q Studio)
/// into a 5-band hardware parametric equalizer tailored for DSP DAC chips.
class AutoEqToHardwareFitter {
  const AutoEqToHardwareFitter();

  /// Standard target center frequencies for 5-band hardware fitting.
  static const List<double> defaultAnchorFrequencies = [
    60.0,    // Sub-bass region
    250.0,   // Lower midrange / mud control
    2400.0,  // Pinna gain / ear canal resonance
    6000.0,  // Sibilance control / presence
    12500.0, // Air & brilliance
  ];

  /// Converts a multi-band Pro-Q Studio / AutoEQ list of [EqBand]s into a 5-band [DacPeqProfile].
  DacPeqProfile fitFromEqBands(
    List<EqBand> sourceBands, {
    String name = 'AutoEQ Hardware Profile',
    String description = 'Imported and fitted from Pro-Q Studio / AutoEQ',
    DacChipset targetChipset = DacChipset.kt0211l,
    int targetBandCount = 5,
  }) {
    final activeBands = sourceBands.where((b) => b.isEnabled).toList();

    if (activeBands.isEmpty) {
      return DacPeqProfile(
        id: 'fitted_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        description: description,
        bands: DacBandConfig.defaultKiwiEars5Bands,
        preampGainDb: 0.0,
        targetChipset: targetChipset,
      );
    }

    // If source already has <= targetBandCount bands, direct-map each band
    if (activeBands.length <= targetBandCount) {
      final List<DacBandConfig> fittedBands = [];
      for (int i = 0; i < targetBandCount; i++) {
        if (i < activeBands.length) {
          final b = activeBands[i];
          fittedBands.add(DacBandConfig(
            bandIndex: i,
            frequency: b.frequency.clamp(20.0, 20000.0),
            gainDb: b.gainDb.clamp(-12.0, 12.0),
            qFactor: b.q.clamp(0.10, 10.00),
            filterType: _mapFilterType(b.type),
            isBypassed: !b.isEnabled,
          ));
        } else {
          // Fill remaining slots with default frequencies and 0dB gain
          fittedBands.add(DacBandConfig(
            bandIndex: i,
            frequency: defaultAnchorFrequencies[i],
            gainDb: 0.0,
            qFactor: 0.707,
            filterType: i == 0
                ? DacFilterType.lowShelf
                : (i == targetBandCount - 1
                    ? DacFilterType.highShelf
                    : DacFilterType.peaking),
          ));
        }
      }

      final safePreamp = _calculateSafePreamp(fittedBands);
      return DacPeqProfile(
        id: 'fitted_${DateTime.now().millisecondsSinceEpoch}',
        name: name,
        description: description,
        bands: fittedBands,
        preampGainDb: safePreamp,
        targetChipset: targetChipset,
        createdAt: DateTime.now(),
      );
    }

    // For 6+ bands (e.g. 10 or 20 band AutoEQ profiles), perform multi-region energy clustering
    final fittedBands = _clusterMultiBands(activeBands, targetBandCount);
    final safePreamp = _calculateSafePreamp(fittedBands);

    return DacPeqProfile(
      id: 'fitted_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      bands: fittedBands,
      preampGainDb: safePreamp,
      targetChipset: targetChipset,
      createdAt: DateTime.now(),
    );
  }

  /// Converts a discrete frequency-to-gain curve map into 5 hardware bands.
  DacPeqProfile fitFromFrequencyGainMap(
    Map<double, double> curvePoints, {
    String name = 'Fitted Curve Profile',
    String description = 'Fitted from raw frequency response curve',
    DacChipset targetChipset = DacChipset.kt0211l,
    int targetBandCount = 5,
  }) {
    final List<DacBandConfig> fittedBands = [];

    for (int i = 0; i < targetBandCount; i++) {
      final anchorFreq = defaultAnchorFrequencies[i];
      final gainAtAnchor = _sampleGainAtFrequency(curvePoints, anchorFreq);

      fittedBands.add(DacBandConfig(
        bandIndex: i,
        frequency: anchorFreq,
        gainDb: gainAtAnchor.clamp(-12.0, 12.0),
        qFactor: i == 0 || i == targetBandCount - 1 ? 0.707 : 1.20,
        filterType: i == 0
            ? DacFilterType.lowShelf
            : (i == targetBandCount - 1
                ? DacFilterType.highShelf
                : DacFilterType.peaking),
      ));
    }

    final safePreamp = _calculateSafePreamp(fittedBands);
    return DacPeqProfile(
      id: 'fitted_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      bands: fittedBands,
      preampGainDb: safePreamp,
      targetChipset: targetChipset,
      createdAt: DateTime.now(),
    );
  }

  /// Clusters multi-band EQ into 5 target zones using weighted energy centroids.
  List<DacBandConfig> _clusterMultiBands(List<EqBand> bands, int targetBandCount) {
    // 5 Frequency Zone Boundaries:
    // Zone 0: Sub-bass (20 - 120 Hz)
    // Zone 1: Mid-bass / Lower mids (120 - 800 Hz)
    // Zone 2: Midrange / Ear gain (800 - 4000 Hz)
    // Zone 3: Presence / Treble (4000 - 9000 Hz)
    // Zone 4: Air / Upper treble (9000 - 20000 Hz)
    final zones = <List<EqBand>>[
      [],
      [],
      [],
      [],
      [],
    ];

    for (final band in bands) {
      final f = band.frequency;
      if (f < 120) {
        zones[0].add(band);
      } else if (f < 800) {
        zones[1].add(band);
      } else if (f < 4000) {
        zones[2].add(band);
      } else if (f < 9000) {
        zones[3].add(band);
      } else {
        zones[4].add(band);
      }
    }

    final List<DacBandConfig> result = [];

    for (int i = 0; i < targetBandCount; i++) {
      final zoneBands = zones[i];

      if (zoneBands.isEmpty) {
        result.add(DacBandConfig(
          bandIndex: i,
          frequency: defaultAnchorFrequencies[i],
          gainDb: 0.0,
          qFactor: 0.707,
          filterType: i == 0
              ? DacFilterType.lowShelf
              : (i == targetBandCount - 1
                  ? DacFilterType.highShelf
                  : DacFilterType.peaking),
        ));
        continue;
      }

      // Compute weighted frequency centroid and dominant gain
      double totalWeight = 0.0;
      double weightedLogFreq = 0.0;
      double maxAbsGain = 0.0;
      double dominantGain = 0.0;
      double avgQ = 0.0;

      for (final b in zoneBands) {
        final weight = math.max(0.2, b.gainDb.abs());
        totalWeight += weight;
        weightedLogFreq += math.log(b.frequency) * weight;

        if (b.gainDb.abs() > maxAbsGain) {
          maxAbsGain = b.gainDb.abs();
          dominantGain = b.gainDb;
        }
        avgQ += b.q;
      }

      final centerFreq = math.exp(weightedLogFreq / totalWeight);
      final finalQ = (avgQ / zoneBands.length).clamp(0.40, 4.00);

      result.add(DacBandConfig(
        bandIndex: i,
        frequency: centerFreq.clamp(20.0, 20000.0),
        gainDb: dominantGain.clamp(-12.0, 12.0),
        qFactor: finalQ,
        filterType: i == 0
            ? DacFilterType.lowShelf
            : (i == targetBandCount - 1
                ? DacFilterType.highShelf
                : DacFilterType.peaking),
      ));
    }

    return result;
  }

  double _sampleGainAtFrequency(Map<double, double> points, double targetFreq) {
    if (points.isEmpty) return 0.0;
    if (points.containsKey(targetFreq)) return points[targetFreq]!;

    final sortedKeys = points.keys.toList()..sort();
    if (targetFreq <= sortedKeys.first) return points[sortedKeys.first]!;
    if (targetFreq >= sortedKeys.last) return points[sortedKeys.last]!;

    // Linear interpolation in log-frequency space
    for (int i = 0; i < sortedKeys.length - 1; i++) {
      final f0 = sortedKeys[i];
      final f1 = sortedKeys[i + 1];
      if (targetFreq >= f0 && targetFreq <= f1) {
        final log0 = math.log(f0);
        final log1 = math.log(f1);
        final logT = math.log(targetFreq);
        final t = (logT - log0) / (log1 - log0);
        final g0 = points[f0]!;
        final g1 = points[f1]!;
        return g0 + (g1 - g0) * t;
      }
    }

    return 0.0;
  }

  double _calculateSafePreamp(List<DacBandConfig> bands) {
    double maxGain = 0.0;
    for (final b in bands) {
      if (!b.isBypassed && b.gainDb > maxGain) {
        maxGain = b.gainDb;
      }
    }
    return maxGain > 0 ? -maxGain - 0.5 : 0.0;
  }

  DacFilterType _mapFilterType(FilterType type) {
    switch (type) {
      case FilterType.peaking:
        return DacFilterType.peaking;
      case FilterType.lowShelf:
        return DacFilterType.lowShelf;
      case FilterType.highShelf:
        return DacFilterType.highShelf;
      case FilterType.lowPass:
        return DacFilterType.lowPass;
      case FilterType.highPass:
        return DacFilterType.highPass;
      case FilterType.notch:
        return DacFilterType.peaking;
    }
  }
}
