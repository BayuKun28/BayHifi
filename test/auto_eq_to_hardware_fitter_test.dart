import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/features/hardware_dac/domain/services/auto_eq_to_hardware_fitter.dart';
import 'package:baydev_hifi/features/pro_q_studio/domain/eq_band.dart';

void main() {
  group('AutoEqToHardwareFitter Unit Tests', () {
    const fitter = AutoEqToHardwareFitter();

    test('Fits 5 or fewer bands directly to hardware bands', () {
      final sourceBands = [
        const EqBand(index: 1, frequency: 45.0, gainDb: 3.5, q: 0.7, type: FilterType.lowShelf, isEnabled: true, color: Colors.blue),
        const EqBand(index: 2, frequency: 1200.0, gainDb: -2.0, q: 1.4, type: FilterType.peaking, isEnabled: true, color: Colors.green),
        const EqBand(index: 3, frequency: 10000.0, gainDb: 2.0, q: 0.7, type: FilterType.highShelf, isEnabled: true, color: Colors.amber),
      ];

      final profile = fitter.fitFromEqBands(sourceBands, name: 'Direct 3 Band Test');
      expect(profile.bands.length, equals(5));
      expect(profile.bands[0].frequency, closeTo(45.0, 0.1));
      expect(profile.bands[0].gainDb, closeTo(3.5, 0.1));
      expect(profile.bands[1].frequency, closeTo(1200.0, 0.1));
      expect(profile.bands[1].gainDb, closeTo(-2.0, 0.1));
      expect(profile.bands[2].frequency, closeTo(10000.0, 0.1));
      expect(profile.bands[2].gainDb, closeTo(2.0, 0.1));

      // Safe preamp headroom: -(max positive 3.5) - 0.5 = -4.0 dB
      expect(profile.preampGainDb, closeTo(-4.0, 0.1));
    });

    test('Clusters 10-band AutoEQ profile into 5 balanced hardware zones', () {
      final tenBands = [
        const EqBand(index: 1, frequency: 32.0, gainDb: 5.0, q: 0.8, type: FilterType.lowShelf, isEnabled: true, color: Colors.red),
        const EqBand(index: 2, frequency: 64.0, gainDb: 4.0, q: 1.0, type: FilterType.peaking, isEnabled: true, color: Colors.red),
        const EqBand(index: 3, frequency: 125.0, gainDb: 1.5, q: 1.0, type: FilterType.peaking, isEnabled: true, color: Colors.orange),
        const EqBand(index: 4, frequency: 250.0, gainDb: -1.0, q: 1.0, type: FilterType.peaking, isEnabled: true, color: Colors.orange),
        const EqBand(index: 5, frequency: 500.0, gainDb: -2.5, q: 1.2, type: FilterType.peaking, isEnabled: true, color: Colors.yellow),
        const EqBand(index: 6, frequency: 1000.0, gainDb: 0.5, q: 1.0, type: FilterType.peaking, isEnabled: true, color: Colors.green),
        const EqBand(index: 7, frequency: 2000.0, gainDb: 3.0, q: 1.4, type: FilterType.peaking, isEnabled: true, color: Colors.teal),
        const EqBand(index: 8, frequency: 4000.0, gainDb: 4.5, q: 1.8, type: FilterType.peaking, isEnabled: true, color: Colors.blue),
        const EqBand(index: 9, frequency: 8000.0, gainDb: -3.0, q: 2.0, type: FilterType.peaking, isEnabled: true, color: Colors.indigo),
        const EqBand(index: 10, frequency: 16000.0, gainDb: 2.0, q: 0.7, type: FilterType.highShelf, isEnabled: true, color: Colors.purple),
      ];

      final profile = fitter.fitFromEqBands(tenBands, name: '10-Band Harman Fit');
      expect(profile.bands.length, equals(5));

      // Zone 0 (Sub-bass): 20 - 120 Hz
      expect(profile.bands[0].frequency, inInclusiveRange(20.0, 120.0));
      expect(profile.bands[0].gainDb, greaterThan(3.0));

      // Zone 1 (Mid-bass / Lower mids): 120 - 800 Hz
      expect(profile.bands[1].frequency, inInclusiveRange(120.0, 800.0));

      // Zone 2 (Ear gain): 800 - 4000 Hz
      expect(profile.bands[2].frequency, inInclusiveRange(800.0, 4000.0));

      // Zone 3 (Presence / Treble): 4000 - 9000 Hz
      expect(profile.bands[3].frequency, inInclusiveRange(4000.0, 9000.0));

      // Zone 4 (Air): 9000 - 20000 Hz
      expect(profile.bands[4].frequency, inInclusiveRange(9000.0, 20000.0));

      expect(profile.preampGainDb, lessThanOrEqualTo(0.0));
    });

    test('Fits from raw frequency-to-gain curve map', () {
      final curveMap = {
        20.0: 6.0,
        60.0: 4.5,
        250.0: -1.0,
        1000.0: 0.0,
        2500.0: 3.5,
        6000.0: -2.0,
        14000.0: 2.0,
      };

      final profile = fitter.fitFromFrequencyGainMap(curveMap, name: 'Raw Map Fit');
      expect(profile.bands.length, equals(5));
      expect(profile.bands[0].gainDb, closeTo(4.5, 0.5));
      expect(profile.bands[1].gainDb, closeTo(-1.0, 0.5));
    });
  });
}
