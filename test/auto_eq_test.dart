import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/features/pro_q_studio/domain/auto_eq_optimizer.dart';
import 'package:baydev_hifi/features/pro_q_studio/domain/biquad_math.dart';
import 'package:baydev_hifi/features/pro_q_studio/domain/eq_band.dart';
import 'package:baydev_hifi/features/pro_q_studio/domain/fr_curve_data.dart';
import 'package:baydev_hifi/features/pro_q_studio/domain/squiglink_parser.dart';

void main() {
  group('3.1 & 3.2 Parser Tests', () {
    test('Parse REW V5 KZ Castor Driver measurement file', () {
      final file = File('assets/samples/drivers/KZ_CASTOR_BLACK_DUDU_R.txt');
      expect(file.existsSync(), isTrue);

      final content = file.readAsStringSync();
      final data = FrCurveData.parseRewV5(content, name: 'KZ Castor Black');

      expect(data.name, equals('KZ Castor Black'));
      expect(data.frequencies.length, greaterThan(400));
      expect(data.splDb.length, equals(data.frequencies.length));
      expect(data.frequencies.first, closeTo(20.0, 0.5));
      expect(data.frequencies.last, greaterThan(19000.0));
      // Reference at 1 kHz should be normalized
      expect(data.interpolateSpl(1000.0), closeTo(0.0, 0.2));
    });

    test('Parse Squiglink CSV HBB Target curve file', () {
      final file = File('assets/samples/targets/HBB_Target.txt');
      expect(file.existsSync(), isTrue);

      final content = file.readAsStringSync();
      final data = FrCurveData.parseSquiglinkCsv(content, name: 'HBB Target');

      expect(data.name, equals('HBB Target'));
      expect(data.frequencies.length, greaterThan(400));
      expect(data.splDb.length, equals(data.frequencies.length));
      expect(data.frequencies.first, closeTo(20.0, 0.5));
      expect(data.frequencies.last, greaterThan(19000.0));
      expect(data.interpolateSpl(1000.0), closeTo(0.0, 0.2));
    });

    test('Auto-detection parser handles both formats seamlessly', () {
      const rewText = '''* Measurement
* Freq(Hz) SPL(dB)
20.0 80.0
1000.0 75.0
10000.0 70.0''';

      const csvText = '''20,105.0
1000,95.0
10000,90.0''';

      final rewResult = FrCurveData.autoDetectAndParse(rewText, name: 'REW');
      expect(rewResult.frequencies.length, equals(3));
      expect(rewResult.interpolateSpl(1000.0), closeTo(0.0, 0.01));

      final csvResult = FrCurveData.autoDetectAndParse(csvText, name: 'CSV');
      expect(csvResult.frequencies.length, equals(3));
      expect(csvResult.interpolateSpl(1000.0), closeTo(0.0, 0.01));
    });
  });

  group('3.3 & 3.4 AutoEQ Biquad Optimizer Solver Tests', () {
    late FrCurveData driver;
    late FrCurveData target;

    setUp(() {
      final driverFile = File('assets/samples/drivers/KZ_CASTOR_BLACK_DUDU_R.txt');
      final targetFile = File('assets/samples/targets/HBB_Target.txt');
      driver = FrCurveData.parseRewV5(driverFile.readAsStringSync(), name: 'KZ Castor Black');
      target = FrCurveData.parseSquiglinkCsv(targetFile.readAsStringSync(), name: 'HBB Target');
    });

    test('Delta calculation returns expected deviations', () {
      final delta1k = AutoEqOptimizer.calculateDeltaSpl(1000.0, driverFr: driver, targetFr: target);
      expect(delta1k.abs(), lessThan(0.5)); // Both normalized at 1 kHz

      final deltaSubBass = AutoEqOptimizer.calculateDeltaSpl(63.0, driverFr: driver, targetFr: target);
      expect(deltaSubBass.isFinite, isTrue);
    });

    test('Optimize 10-Band resolution (Matching Screenshot 1 & 2)', () {
      final result = AutoEqOptimizer.optimize(
        driverFr: driver,
        targetFr: target,
        resolution: BandResolution.b10,
        mode: TuningMode.normal,
      );

      expect(result.bands.length, equals(10));
      expect(result.safePreampDb, lessThan(0.0)); // Negative preamp for headroom
      expect(result.bands.first.frequency, closeTo(31.5, 5.0));
      expect(result.bands.last.frequency, greaterThan(12000.0));
    });

    test('Optimize across all band resolutions: 5B, 10B, 16B, 20B, 32B', () {
      for (final res in BandResolution.values) {
        final result = AutoEqOptimizer.optimize(
          driverFr: driver,
          targetFr: target,
          resolution: res,
          mode: TuningMode.normal,
        );

        expect(result.bands.length, equals(res.count),
            reason: 'Resolution ${res.label} should produce exactly ${res.count} bands');
        expect(result.safePreampDb, lessThanOrEqualTo(0.0));
      }
    });

    test('Safe Mode clamps max boost at +6.0 dB', () {
      final safeResult = AutoEqOptimizer.optimize(
        driverFr: driver,
        targetFr: target,
        resolution: BandResolution.b10,
        mode: TuningMode.safe,
      );

      for (final band in safeResult.bands) {
        expect(band.gainDb, lessThanOrEqualTo(6.01),
            reason: 'Band ${band.index} gain ${band.gainDb} must be clamped at +6.0 dB in Safe Mode');
        expect(band.gainDb, greaterThanOrEqualTo(-12.01));
      }
    });
  });

  group('3.6 Squiglink Parser & Exporter Tests', () {
    test('Parse standard Squiglink text format', () {
      const squigText = '''Preamp: -4.3 dB
Filter 1: ON PK Fc 63 Hz Gain -1.1 dB Q 1.414
Filter 2: ON PK Fc 226 Hz Gain 4.4 dB Q 1.800
Filter 3: ON LSQ Fc 105 Hz Gain 3.0 dB Q 0.707
Filter 4: OFF HSQ Fc 10000 Hz Gain -2.0 dB Q 0.707''';

      final result = SquiglinkParser.parse(squigText);
      expect(result.preampDb, equals(-4.3));
      expect(result.bands.length, equals(4));

      expect(result.bands[0].frequency, equals(63.0));
      expect(result.bands[0].gainDb, equals(-1.1));
      expect(result.bands[0].q, equals(1.414));
      expect(result.bands[0].type, equals(FilterType.peaking));
      expect(result.bands[0].isEnabled, isTrue);

      expect(result.bands[1].frequency, equals(226.0));
      expect(result.bands[1].gainDb, equals(4.4));
      expect(result.bands[1].q, equals(1.800));

      expect(result.bands[2].type, equals(FilterType.lowShelf));
      expect(result.bands[3].type, equals(FilterType.highShelf));
      expect(result.bands[3].isEnabled, isFalse);
    });

    test('Export and re-parse roundtrip consistency', () {
      final originalBands = EqBand.default10Bands;
      final exported = SquiglinkParser.exportToSquiglink(originalBands, preampDb: -4.3);

      expect(exported, contains('Preamp: -4.3 dB'));
      expect(exported, contains('Filter 1:'));
      expect(exported, contains('Filter 10:'));

      final parsedAgain = SquiglinkParser.parse(exported);
      expect(parsedAgain.bands.length, equals(10));
      expect(parsedAgain.preampDb, equals(-4.3));
      expect(parsedAgain.bands[0].frequency, closeTo(originalBands[0].frequency, 1.0));
    });

    test('Export Wavelet GraphicEQ format produces valid string', () {
      final wavelet = SquiglinkParser.exportToWavelet(EqBand.default10Bands);
      expect(wavelet, startsWith('GraphicEQ: '));
      expect(wavelet, contains('1000 '));
      expect(wavelet, contains('20000 '));
    });
  });

  group('3.7 A/B Comparison Logic', () {
    test('calculateCompositeGainDb evaluates zero when all bands flat', () {
      final flatBands = EqBand.default10Bands.map((b) => b.copyWith(gainDb: 0.0)).toList();
      final gain1k = BiquadMath.calculateCompositeGainDb(flatBands, 1000.0);
      expect(gain1k, closeTo(0.0, 0.01));
    });
  });
}
