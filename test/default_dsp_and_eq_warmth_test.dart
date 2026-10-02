import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/audio_engine/virtual_dsp_service.dart';
import 'package:baydev_hifi/core/database/local_persistence_service.dart';
import 'package:baydev_hifi/features/dsp_rack/domain/dsp_models.dart';
import 'package:baydev_hifi/features/dsp_rack/presentation/controllers/dsp_rack_controller.dart';
import 'package:baydev_hifi/features/pro_q_studio/domain/biquad_math.dart';
import 'package:baydev_hifi/features/pro_q_studio/domain/eq_band.dart';
import 'package:baydev_hifi/features/pro_q_studio/presentation/controllers/eq_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bayhifi_warmth_test_');
    await LocalPersistenceService.instance.init(
      customPath: '${tempDir.path}/test_storage.json',
    );
    VirtualDspService.instance.init();
    VirtualDspService.instance.resetToFlatReference();
  });

  tearDown(() async {
    try {
      if (tempDir.existsSync()) {
        await tempDir.delete(recursive: true);
      }
    } catch (_) {}
  });

  group('Phase 53: Out-of-the-Box Studio Audiophile Warmth Defaults', () {
    test('EqBand.default10Bands contains calibrated warmth curve', () {
      final bands = EqBand.default10Bands;
      expect(bands.length, 10);

      // Sub-bass band (48 Hz) should have gentle boost (+1.8 dB)
      final subBass = bands.firstWhere((b) => b.frequency == 48.0);
      expect(subBass.gainDb, 1.8);

      // Mid-bass punch band (110 Hz) should have +0.8 dB
      final midBass = bands.firstWhere((b) => b.frequency == 110.0);
      expect(midBass.gainDb, 0.8);

      // Low-mid mud cut band (280 Hz) should have gentle dip (-0.8 dB)
      final lowMid = bands.firstWhere((b) => b.frequency == 280.0);
      expect(lowMid.gainDb, -0.8);

      // Sibilance control band (8200 Hz) should have gentle dip (-0.6 dB)
      final sibilance = bands.firstWhere((b) => b.frequency == 8200.0);
      expect(sibilance.gainDb, -0.6);

      // Air sparkle band (16000 Hz) should have subtle high shelf (+1.6 dB)
      final air = bands.firstWhere((b) => b.frequency == 16000.0);
      expect(air.gainDb, 1.6);
    });

    test('EqBand.flatBands contains 0.0 dB across all 10 bands', () {
      final flat = EqBand.flatBands;
      expect(flat.length, 10);
      for (final band in flat) {
        expect(band.gainDb, 0.0);
      }
    });

    test('BiquadMath.calculateSafePreamp calculates safe digital headroom', () {
      final warmthBands = EqBand.default10Bands;
      final safePreamp = BiquadMath.calculateSafePreamp(warmthBands);
      // Mathematical composite curve maximum + 0.5dB margin yields -2.3 dB
      expect(safePreamp, closeTo(-2.3, 0.05));

      final flatBands = EqBand.flatBands;
      final flatSafePreamp = BiquadMath.calculateSafePreamp(flatBands);
      expect(flatSafePreamp, 0.0);
    });

    test('DspRackState defaults to Studio Audiophile Warmth profile', () {
      const state = DspRackState();
      expect(state.isBypassed, isFalse);
      expect(state.tubeExciterEnabled, isTrue);
      expect(state.tubeDrive, 1.2);
      expect(state.tubeWarmth, 0.45);
      expect(state.tubeMix, 0.18);
      expect(state.stereoWidthEnabled, isTrue);
      expect(state.stereoWidth, 1.15);
      expect(state.stereoMidGain, 1.05);
      expect(state.limiterEnabled, isTrue);
      expect(state.limiterThreshold, -2.5);
      expect(state.limiterOutputCeiling, -0.5);
      expect(state.preampDb, -1.5);
      expect(state.activePresetId, 'studio_warmth');
    });

    test('EqController initializes with Studio Audiophile Warmth and safe preamp', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final eqState = container.read(eqControllerProvider);
      expect(eqState.activePresetName, 'Studio Audiophile Warmth');
      expect(eqState.bands.length, 10);
      expect(eqState.safePreampDb, closeTo(-2.0, 0.5));
      expect(eqState.bands.first.gainDb, 1.8);
    });

    test('EqController switches cleanly to Flat / Bit-Perfect preset and back', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(eqControllerProvider.notifier);

      // Apply Flat / Bit-Perfect
      controller.applyPreset('Audiophile Bit-Perfect (Flat)');
      var eqState = container.read(eqControllerProvider);
      expect(eqState.activePresetName, 'Audiophile Bit-Perfect (Flat)');
      for (final b in eqState.bands) {
        expect(b.gainDb, 0.0);
      }
      expect(eqState.safePreampDb, 0.0);

      // Reset to Default Warmth
      controller.resetToDefault();
      eqState = container.read(eqControllerProvider);
      expect(eqState.activePresetName, 'Studio Audiophile Warmth');
      expect(eqState.bands.first.gainDb, 1.8);

      // Reset to Bit-Perfect
      controller.resetToBitPerfect();
      eqState = container.read(eqControllerProvider);
      expect(eqState.activePresetName, 'Audiophile Bit-Perfect (Flat)');
      expect(eqState.bands.first.gainDb, 0.0);
    });

    test('EqController applies curated presets suite correctly', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(eqControllerProvider.notifier);

      // Harman 2019 Reference
      controller.applyPreset('Harman 2019 Reference');
      var state = container.read(eqControllerProvider);
      expect(state.activePresetName, 'Harman 2019 Reference');
      expect(state.bands.first.gainDb, 4.5);

      // Vocal & Acoustic Intimacy
      controller.applyPreset('Vocal & Acoustic Intimacy');
      state = container.read(eqControllerProvider);
      expect(state.activePresetName, 'Vocal & Acoustic Intimacy');
      expect(state.bands.firstWhere((b) => b.frequency == 1500.0).gainDb, 1.8);

      // Deep Bass & Club Drive
      controller.applyPreset('Deep Bass & Club Drive');
      state = container.read(eqControllerProvider);
      expect(state.activePresetName, 'Deep Bass & Club Drive');
      expect(state.bands.first.gainDb, 5.2);

      // Air & High-Res Sparkle
      controller.applyPreset('Air & High-Res Sparkle');
      state = container.read(eqControllerProvider);
      expect(state.activePresetName, 'Air & High-Res Sparkle');
      expect(state.bands.last.gainDb, 3.5);
    });

    test('DspRackController applies Pure Direct Bit-Perfect and Studio Warmth presets', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(dspRackControllerProvider.notifier);

      // 1. Initial State should be Studio Warmth
      var state = container.read(dspRackControllerProvider);
      expect(state.tubeExciterEnabled, isTrue);
      expect(state.stereoWidthEnabled, isTrue);

      // 2. Reset to Bit-Perfect (Pure Direct)
      controller.resetToBitPerfect();
      state = container.read(dspRackControllerProvider);
      expect(state.activePresetId, 'pure_direct');
      expect(state.tubeExciterEnabled, isFalse);
      expect(state.stereoWidthEnabled, isFalse);
      expect(state.preampDb, 0.0);

      // 3. Reset to Defaults (Warmth)
      controller.resetToDefaults();
      state = container.read(dspRackControllerProvider);
      expect(state.activePresetId, 'studio_warmth');
      expect(state.tubeExciterEnabled, isTrue);
      expect(state.stereoWidthEnabled, isTrue);
      expect(state.preampDb, -1.5);
    });

    test('Active EQ state persists and hydrates correctly across restarts', () async {
      // 1. Create modified state and persist
      final customBands = EqBand.default10Bands.map((b) {
        if (b.index == 1) return b.copyWith(gainDb: 3.2);
        return b;
      }).toList();

      await LocalPersistenceService.instance.saveActiveEqState(
        bands: customBands.map((b) => b.toMap()).toList(),
        preampDb: -3.4,
        activePresetName: 'Custom My Warmth',
      );

      // 2. Verify read back
      final saved = LocalPersistenceService.instance.getActiveEqState();
      expect(saved, isNotNull);
      expect(saved!['activePresetName'], 'Custom My Warmth');
      expect(saved['preampDb'], -3.4);

      // 3. Hydrate in new EqController instance
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final state = container.read(eqControllerProvider);
      expect(state.activePresetName, 'Custom My Warmth');
      expect(state.bands.first.gainDb, 3.2);
    });
  });
}
