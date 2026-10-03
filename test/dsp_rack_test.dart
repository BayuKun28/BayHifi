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
      expect(state.preampDb, -1.5);
      expect(state.tubeExciterEnabled, true);
      expect(state.stereoWidthEnabled, true);
      // Limiter must be enabled by default for zero-overshoot anti-clipping
      expect(state.limiterEnabled, true);
      expect(state.limiterOutputCeiling, -0.5);

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
      expect(controller.state.preampDb, 6.0);
      controller.setPreamp(-40.0); // should clamp to -24.0
      expect(controller.state.preampDb, -24.0);

      // Test Dynamic Bass Boost
      controller.toggleBassBoost();
      expect(controller.state.bassBoostEnabled, true);
      controller.setBassBoostAmount(2.2);
      expect(controller.state.bassBoostAmount, 2.2);
      controller.setBassBoostWet(0.55);
      expect(controller.state.bassBoostWet, 0.55);

      // Test Tube Exciter
      controller.toggleTubeExciter();
      expect(controller.state.tubeExciterEnabled, false);
      controller.toggleTubeExciter();
      expect(controller.state.tubeExciterEnabled, true);
      controller.setTubeDrive(3.5);
      expect(controller.state.tubeDrive, 3.5);
      controller.setTubeWarmth(0.7);
      expect(controller.state.tubeWarmth, 0.7);

      // Test Dynamic Compressor
      controller.toggleCompressor();
      expect(controller.state.compressorEnabled, true);
      controller.setCompThreshold(-18.0);
      expect(controller.state.compThreshold, -18.0);
      controller.setCompRatio(4.0);
      expect(controller.state.compRatio, 4.0);

      // Test Stereo Width Matrix
      controller.toggleStereoWidth();
      expect(controller.state.stereoWidthEnabled, false);
      controller.toggleStereoWidth();
      expect(controller.state.stereoWidthEnabled, true);
      controller.setStereoWidth(1.8);
      expect(controller.state.stereoWidth, 1.8);

      // Test Binaural Crossfeed
      controller.toggleCrossfeed();
      expect(controller.state.crossfeedEnabled, true);
      controller.setCrossfeedCutoff(650.0);
      expect(controller.state.crossfeedCutoff, 650.0);

      // Test Freeverb Spatial Reverb
      controller.toggleReverb();
      expect(controller.state.reverbEnabled, true);
      controller.setReverbRoomSize(0.65);
      expect(controller.state.reverbRoomSize, 0.65);

      // Test Granular Pitch Shifter
      controller.togglePitchShift();
      expect(controller.state.pitchShiftEnabled, true);
      controller.setPitchSemitones(2.0);
      expect(controller.state.pitchSemitones, 2.0);

      // Test Peak Brickwall Limiter
      controller.setLimiterCeiling(-0.5);
      expect(controller.state.limiterOutputCeiling, -0.5);

      // Test Master Bypass A/B Comparison
      controller.toggleBypass();
      expect(controller.state.isBypassed, true);
      controller.toggleBypass();
      expect(controller.state.isBypassed, false);

      // Test Reset Rack to Warmth Defaults
      controller.resetToDefaults();
      expect(controller.state.bassBoostEnabled, false);
      expect(controller.state.tubeExciterEnabled, true);
      expect(controller.state.stereoWidthEnabled, true);
      expect(controller.state.preampDb, -1.5);
      expect(controller.state.limiterEnabled, true);

      // Test Reset Rack to Bit-Perfect
      controller.resetToBitPerfect();
      expect(controller.state.tubeExciterEnabled, false);
      expect(controller.state.stereoWidthEnabled, false);
      expect(controller.state.preampDb, 0.0);
    });

    test('4.10 Presets Application and override tracking', () {
      final controller = DspRackController();
      final tubePreset = DspPreset.studioPresets.firstWhere((p) => p.id == 'warm_tube');

      controller.applyPreset(tubePreset);
      expect(controller.state.activePresetId, 'warm_tube');
      expect(controller.state.tubeExciterEnabled, true);
      expect(controller.state.tubeDrive, 2.8);

      // Modifying a parameter should clear active preset identifier
      controller.setTubeDrive(5.0);
      expect(controller.state.activePresetId, isNull);
      expect(controller.state.tubeDrive, 5.0);
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
      expect(find.text('DSP ACTIVE'), findsOneWidget);

      // Verify Rack Units
      expect(find.text('01'), findsOneWidget); // Pre-Amp
      expect(find.text('PRE-AMP GAIN STAGE'), findsOneWidget);

      expect(find.text('02'), findsOneWidget); // Bass Boost
      expect(find.text('DYNAMIC BASS BOOST'), findsOneWidget);

      expect(find.text('03'), findsOneWidget); // Tube Exciter
      expect(find.text('TUBE HARMONIC EXCITER'), findsOneWidget);

      expect(find.text('04'), findsOneWidget); // Compressor
      expect(find.text('DYNAMIC COMPRESSOR'), findsOneWidget);

      // Verify Studio Preset & Profile Selector Combo Box
      expect(find.text('MASTERING PRESET & PROFILE'), findsOneWidget);
      expect(find.text('SAVE'), findsOneWidget);
      expect(find.text('GENRE RULES'), findsOneWidget);

      // Tap combo box to open dropdown
      await tester.tap(find.text('MASTERING PRESET & PROFILE'));
      await tester.pumpAndSettle();

      // Tap bypass comparison switch
      await tester.tap(find.text('DSP ACTIVE'));
      await tester.pumpAndSettle();
      expect(find.text('BYPASSED (FLAT)'), findsOneWidget);
    });
  });
}
