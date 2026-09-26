import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/audio_engine/dsp_defaults.dart';
import 'package:baydev_hifi/audio_engine/dsp_profile.dart';
import 'package:baydev_hifi/audio_engine/virtual_dsp_service.dart';
import 'package:baydev_hifi/features/pro_q_studio/domain/auto_eq_optimizer.dart';
import 'package:baydev_hifi/features/pro_q_studio/domain/biquad_math.dart';
import 'package:baydev_hifi/features/pro_q_studio/domain/eq_band.dart';
import 'package:baydev_hifi/features/pro_q_studio/domain/fr_curve_data.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Fase 14: DSP Audio Engine Fusion & SoLoud RYNLABS Logic Tests', () {
    late VirtualDspService dspService;

    setUp(() {
      dspService = VirtualDspService.instance;
      dspService.resetToFlatReference();
    });

    test('14.1 DspDefaults and DspProfile serialization and fallback integrity', () {
      expect(DspDefaults.limiterOutputCeiling, -1.3);
      expect(DspDefaults.compAttack, 0.01); // 10ms in seconds
      expect(DspDefaults.compRelease, 0.2); // 200ms in seconds

      final profile = DspProfile.flatReference;
      expect(profile.limiterOutputCeiling, -1.3);
      expect(profile.preampGain, 0.0);
      expect(profile.eqEnabled, isFalse);

      final map = profile.toMap();
      final restored = DspProfile.fromMap(map);
      expect(restored.name, profile.name);
      expect(restored.limiterOutputCeiling, -1.3);
    });

    test('14.2 Auto-Headroom Safe Preamp Formula Verification', () {
      // Test when there is no positive boost
      final flatGains = [0.0, -2.0, -4.0, 0.0];
      expect(dspService.calculateSafePreamp(flatGains), 0.0);

      // Test when there is a +6 dB boost
      final boostedGains = [0.0, 6.0, 2.0, 0.0];
      // Formula: -6.0 - 0.5 = -6.5 dB
      expect(dspService.calculateSafePreamp(boostedGains), -6.5);

      // Test with +10.2 dB boost
      final highBoost = [10.2, 3.0, 0.0];
      expect(dspService.calculateSafePreamp(highBoost), -10.7);
    });

    test('14.3 VirtualDspService state mutation and mastering parameter updates', () {
      dspService.setMasterEnabled(true);
      expect(dspService.masterEnabled, isTrue);

      // PEQ mutation
      dspService.toggleEq(true);
      expect(dspService.eqEnabled, isTrue);
      dspService.setEqBand(
        bandIndex: 0,
        freq: 60.0,
        gainDb: 4.0,
        q: 1.41,
        filterType: 'low_shelf',
      );
      expect(dspService.eqGains[0], 4.0);
      expect(dspService.eqFilterTypes[0], 'low_shelf');
      expect(dspService.preampGain, -4.5); // Auto-headroom: -4.0 - 0.5 = -4.5 dB

      // Compressor mutation
      dspService.toggleCompressor(true);
      dspService.setCompressorParams(
        threshold: -18.0,
        ratio: 4.0,
        attackMs: 15.0,
        releaseMs: 150.0,
      );
      expect(dspService.compressorEnabled, isTrue);
      expect(dspService.compThreshold, -18.0);
      expect(dspService.compRatio, 4.0);
      expect(dspService.compAttack, 0.015); // 15ms in seconds
      expect(dspService.compRelease, 0.15); // 150ms in seconds

      // Limiter mutation
      dspService.toggleLimiter(true);
      dspService.setLimiterParams(threshold: -2.5, attackMs: 2.0, releaseMs: 80.0);
      expect(dspService.limiterEnabled, isTrue);
      expect(dspService.limiterThreshold, -2.5);
      expect(dspService.limiterOutputCeiling, -1.3); // Strictly locked to -1.3 dBFS

      // Tube Exciter mutation
      dspService.toggleTubeExciter(true);
      dspService.setTubeParams(drive: 2.5, warmth: 0.6, mix: 0.4);
      expect(dspService.tubeEnabled, isTrue);
      expect(dspService.tubeDrive, 2.5);
      expect(dspService.tubeWarmth, 0.6);
      expect(dspService.tubeMix, 0.4);

      // Reverb and volume compensation
      dspService.toggleReverb(true);
      dspService.setReverbParams(roomSize: 0.5, damp: 0.4, wet: 0.3);
      expect(dspService.reverbEnabled, isTrue);
      expect(dspService.reverbVolumeCompensationDb, lessThan(0.0));
    });

    test('14.4 Biquad Filter Mathematics & RBJ Cookbook Validation', () {
      const sampleRate = 48000.0;
      final peakingBand = EqBand(
        index: 1,
        frequency: 1000.0,
        gainDb: 6.0,
        q: 1.414,
        type: FilterType.peaking,
        color: const Color(0xFFF59E0B),
      );

      final coeff = BiquadMath.calculateCoefficients(peakingBand, sampleRate: sampleRate);
      expect(coeff.b0, isNotNull);
      expect(coeff.a1, isNotNull);

      // Response at center frequency (1 kHz) should equal approximately +6.0 dB
      final centerGain = coeff.evaluateGainDb(1000.0, sampleRate);
      expect((centerGain - 6.0).abs(), lessThan(0.2));

      // Response far away (20 Hz) should approach 0 dB
      final bassGain = coeff.evaluateGainDb(20.0, sampleRate);
      expect(bassGain.abs(), lessThan(0.2));
    });

    test('14.5 AutoEQ Optimizer & Weighted RMSE Calculation Test', () {
      final freqs = [20.0, 100.0, 1000.0, 4000.0, 10000.0, 20000.0];
      final driverSpls = [80.0, 82.0, 85.0, 78.0, 84.0, 75.0];
      final targetSpls = [86.0, 85.0, 85.0, 82.0, 80.0, 75.0];

      final driver = FrCurveData(name: 'Mock IEM', frequencies: freqs, splDb: driverSpls, referenceSpl1kHz: 85.0);
      final target = FrCurveData(name: 'Mock Target', frequencies: freqs, splDb: targetSpls, referenceSpl1kHz: 85.0);

      final result = AutoEqOptimizer.optimize(
        driverFr: driver,
        targetFr: target,
        resolution: BandResolution.b10,
        mode: TuningMode.normal,
      );

      expect(result.bands.length, 10);
      expect(result.safePreampDb, lessThanOrEqualTo(0.0));
      expect(result.weightedRmseBefore, isNotNull);
      expect(result.weightedRmseAfter, isNotNull);
      expect(result.weightedRmseAfter, lessThan(result.weightedRmseBefore));
    });
  });
}
