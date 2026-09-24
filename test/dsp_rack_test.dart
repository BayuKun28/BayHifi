import 'package:baydev_hifi/app/theme/theme_mode_controller.dart';
import 'package:baydev_hifi/features/dsp_rack/domain/dsp_models.dart';
import 'package:baydev_hifi/features/dsp_rack/presentation/controllers/dsp_rack_controller.dart';
import 'package:baydev_hifi/features/dsp_rack/presentation/dsp_rack_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Fase 4: DSP Mastering Rack Domain & State Tests', () {
    test('4.1 - 4.10 DspRackState defaults and safety limits', () {
      const state = DspRackState();

      expect(state.isBypassed, false);
      expect(state.masterWet, 1.0);
      expect(state.preampDb, 0.0);
      // Limiter must be enabled by default for zero-overshoot anti-clipping
      expect(state.limiterEnabled, true);
      expect(state.limiterOutputCeiling, -1.0);

      // Verify parameter clamping
      final modified = state.copyWith(
        preampDb: 25.0, // should clamp or test bounds
        bassBoostAmount: 15.0,
      );
      expect(modified.preampDb, 25.0); // copyWith holds value, controller clamps
    });

    test('4.10 Studio Presets completeness and integrity', () {
      final presets = DspPreset.studioPresets;
      expect(presets.length, greaterThanOrEqualTo(6));

      for (final preset in presets) {
        expect(preset.id.isNotEmpty, true);
        expect(preset.name.isNotEmpty, true);
        expect(preset.description.isNotEmpty, true);
        // All presets should have Limiter enabled for audio equipment safety
        expect(preset.state.limiterEnabled, true);
        expect(preset.state.limiterOutputCeiling, lessThanOrEqualTo(0.0));
      }
    });

    test('4.1 - 4.10 DspRackController parameter manipulation', () {
      final controller = DspRackController();

      // Test Preamp
      controller.setPreamp(6.0);
      expect(controller.debugState.preampDb, 6.0);
      controller.setPreamp(-40.0); // should clamp to -24.0
      expect(controller.debugState.preampDb, -24.0);

      // Test Dynamic Bass Boost
      controller.toggleBassBoost();
      expect(controller.debugState.bassBoostEnabled, true);
      controller.setBassBoostAmount(4.5);
      expect(controller.debugState.bassBoostAmount, 4.5);

      // Test Tube Exciter
      controller.toggleTubeExciter();
      expect(controller.debugState.tubeExciterEnabled, true);
      controller.setTubeDrive(3.5);
      expect(controller.debugState.tubeDrive, 3.5);
      controller.setTubeWarmth(0.7);
      expect(controller.debugState.tubeWarmth, 0.7);

      // Test Dynamic Compressor
      controller.toggleCompressor();
      expect(controller.debugState.compressorEnabled, true);
      controller.setCompThreshold(-18.0);
      expect(controller.debugState.compThreshold, -18.0);
      controller.setCompRatio(4.0);
      expect(controller.debugState.compRatio, 4.0);

      // Test Stereo Width Matrix
      controller.toggleStereoWidth();
      expect(controller.debugState.stereoWidthEnabled, true);
      controller.setStereoWidth(1.8);
      expect(controller.debugState.stereoWidth, 1.8);

      // Test Binaural Crossfeed
      controller.toggleCrossfeed();
      expect(controller.debugState.crossfeedEnabled, true);
      controller.setCrossfeedCutoff(650.0);
      expect(controller.debugState.crossfeedCutoff, 650.0);

      // Test Freeverb Spatial Reverb
      controller.toggleReverb();
      expect(controller.debugState.reverbEnabled, true);
      controller.setReverbRoomSize(0.65);
      expect(controller.debugState.reverbRoomSize, 0.65);

      // Test Granular Pitch Shifter
      controller.togglePitchShift();
      expect(controller.debugState.pitchShiftEnabled, true);
      controller.setPitchSemitones(2.0);
      expect(controller.debugState.pitchSemitones, 2.0);

      // Test Peak Brickwall Limiter
      controller.setLimiterCeiling(-0.5);
      expect(controller.debugState.limiterOutputCeiling, -0.5);

      // Test Master Bypass A/B Comparison
      controller.toggleBypass();
      expect(controller.debugState.isBypassed, true);
      controller.toggleBypass();
      expect(controller.debugState.isBypassed, false);

      // Test Reset Rack
      controller.resetToDefaults();
      expect(controller.debugState.bassBoostEnabled, false);
      expect(controller.debugState.tubeExciterEnabled, false);
      expect(controller.debugState.preampDb, 0.0);
      expect(controller.debugState.limiterEnabled, true);
    });

    test('4.10 Presets Application and override tracking', () {
      final controller = DspRackController();
      final tubePreset = DspPreset.studioPresets.firstWhere((p) => p.id == 'warm_tube');

      controller.applyPreset(tubePreset);
      expect(controller.debugState.activePresetId, 'warm_tube');
      expect(controller.debugState.tubeExciterEnabled, true);
      expect(controller.debugState.tubeDrive, 2.8);

      // Modifying a parameter should clear active preset identifier
      controller.setTubeDrive(5.0);
      expect(controller.debugState.activePresetId, isNull);
      expect(controller.debugState.tubeDrive, 5.0);
    });
  });

  group('Fase 4: DspRackScreen Widget Smoke Tests', () {
    testWidgets('Renders all mastering rack units and responds to interactions', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppThemeBuilder.buildTheme(AppPalette.namidaCyan, isDark: true),
            home: const DspRackScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Header & Master Section
      expect(find.text('MASTERING DSP RACK'), findsOneWidget);
      expect(find.text('MASTER DSP CHAIN'), findsOneWidget);
      expect(find.text('B: DSP ACTIVE'), findsOneWidget);

      // Verify Rack Units
      expect(find.text('01'), findsOneWidget); // Pre-Amp
      expect(find.text('PRE-AMP GAIN STAGE'), findsOneWidget);

      expect(find.text('02'), findsOneWidget); // Bass Boost
      expect(find.text('DYNAMIC BASS BOOST'), findsOneWidget);

      expect(find.text('03'), findsOneWidget); // Tube Exciter
      expect(find.text('TUBE HARMONIC EXCITER'), findsOneWidget);

      expect(find.text('04'), findsOneWidget); // Compressor
      expect(find.text('DYNAMIC COMPRESSOR'), findsOneWidget);

      // Verify Studio Preset Chips
      expect(find.text('Audiophile Bit-Perfect'), findsOneWidget);
      expect(find.text('Warm Analog Tube Acoustic'), findsOneWidget);

      // Tap preset chip
      await tester.tap(find.text('Warm Analog Tube Acoustic'));
      await tester.pumpAndSettle();

      // Tap A/B comparison switch
      await tester.tap(find.text('B: DSP ACTIVE'));
      await tester.pumpAndSettle();
      expect(find.text('A: RAW (BYPASSED)'), findsOneWidget);
    });
  });
}
