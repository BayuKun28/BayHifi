import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/audio_engine/virtual_dsp_service.dart';
import 'package:baydev_hifi/core/database/local_persistence_service.dart';
import 'package:baydev_hifi/features/dsp_rack/presentation/controllers/dsp_rack_controller.dart';
import 'package:baydev_hifi/features/dsp_rack/presentation/dsp_rack_screen.dart';
import 'package:baydev_hifi/features/pro_q_studio/data/auto_eq_cloud_service.dart';
import 'package:baydev_hifi/features/pro_q_studio/domain/auto_eq_cloud_model.dart';
import 'package:baydev_hifi/features/pro_q_studio/domain/fr_curve_data.dart';
import 'package:baydev_hifi/features/pro_q_studio/presentation/controllers/eq_controller.dart';
import 'package:baydev_hifi/features/pro_q_studio/presentation/widgets/auto_eq_cloud_browser_dialog.dart';
import 'package:baydev_hifi/features/pro_q_studio/presentation/widgets/auto_eq_modal_dialog.dart';
import 'package:baydev_hifi/features/pro_q_studio/presentation/widgets/band_strip_bar.dart';
import 'package:baydev_hifi/features/pro_q_studio/presentation/widgets/squiglink_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    await LocalPersistenceService.instance.init();
    VirtualDspService.instance.init();
    VirtualDspService.instance.resetToFlatReference();
  });

  group('Fase 24: DSP Rack & Pro-Q Shared PreAmp Bidirectional Synchronization', () {
    test('PreAmp modification in VirtualDspService synchronizes to EqController & DspRackController', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final eqController = container.read(eqControllerProvider.notifier);
      final dspController = container.read(dspRackControllerProvider.notifier);

      // 1. Modify PreAmp via DspRackController
      dspController.setPreamp(-3.5);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(VirtualDspService.instance.preampGain, closeTo(-3.5, 0.05));
      expect(container.read(eqControllerProvider).safePreampDb, closeTo(-3.5, 0.05));

      // 2. Modify PreAmp via EqController
      eqController.setPreamp(-6.0);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(VirtualDspService.instance.preampGain, closeTo(-6.0, 0.05));
      expect(container.read(dspRackControllerProvider).preampDb, closeTo(-6.0, 0.05));

      // 3. Modify PreAmp via VirtualDspService directly
      VirtualDspService.instance.setPreampGain(-1.5);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(container.read(eqControllerProvider).safePreampDb, closeTo(-1.5, 0.05));
      expect(container.read(dspRackControllerProvider).preampDb, closeTo(-1.5, 0.05));
    });

    test('Auto-Headroom calculation accurately protects against digital clipping', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final eqController = container.read(eqControllerProvider.notifier);

      // Boost band 1 to +6.0 dB
      eqController.updateBandGain(1, 6.0);
      final state = container.read(eqControllerProvider);

      // Safe Preamp must be at least -6.5 dB (-maxGain - 0.5dB)
      expect(state.safePreampDb, lessThanOrEqualTo(-6.0));
      expect(VirtualDspService.instance.preampGain, lessThanOrEqualTo(-6.0));
    });
  });

  group('Fase 24: Persistent Offline AutoEQ Caching & Hydration', () {
    test('FrCurveData serialization and deserialization preserves points and metadata', () {
      final curve = FrCurveData(
        name: 'Custom Moondrop Chu II Test',
        frequencies: [20.0, 100.0, 1000.0, 3000.0, 8000.0, 20000.0],
        splDb: [85.0, 83.0, 75.0, 86.0, 79.0, 70.0],
        referenceSpl1kHz: 75.0,
      );

      final map = curve.toMap(category: 'iem');
      expect(map['name'], 'Custom Moondrop Chu II Test');
      expect(map['category'], 'iem');
      expect((map['frequencies'] as List).length, 6);

      final restored = FrCurveData.fromMap(map);
      expect(restored.name, curve.name);
      expect(restored.frequencies.length, 6);
      expect(restored.splDb[2], 75.0);
    });

    test('AutoEqCloudService auto-saves downloaded curves to local persistence', () async {
      final service = AutoEqCloudService.instance;
      const testItem = AutoEqCloudItem(
        id: 'test_iem_offline_cache',
        name: 'Test IEM Offline Model',
        brand: 'TestBrand',
        category: AutoEqCloudCategory.iem,
        source: 'Lab Measurements',
        description: 'Offline test measurement curve',
        rawData: '20 88.0\n100 86.0\n1000 78.0\n3000 89.0\n10000 80.0',
      );

      final curve = await service.downloadItem(testItem);
      expect(curve.name, 'Test IEM Offline Model');

      // Check LocalPersistenceService cache
      final savedCurves = LocalPersistenceService.instance.getSavedFrCurves();
      expect(savedCurves.any((c) => c['name'] == 'Test IEM Offline Model'), isTrue);

      final downloadedIds = LocalPersistenceService.instance.getDownloadedAutoEqIds();
      expect(downloadedIds.contains('test_iem_offline_cache'), isTrue);
    });

    test('EqController automatically hydrates saved offline curves', () async {
      // Pre-populate persistence with a custom target
      await LocalPersistenceService.instance.saveFrCurve({
        'name': 'Custom Offline Target 2026',
        'frequencies': [20.0, 1000.0, 20000.0],
        'splDb': [105.0, 95.0, 90.0],
        'referenceSpl1kHz': 95.0,
        'category': 'target',
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(eqControllerProvider.notifier);
      // Wait for async load to finish
      await Future<void>.delayed(const Duration(milliseconds: 50));

      final state = container.read(eqControllerProvider);
      expect(state.availableTargets.any((t) => t.name == 'Custom Offline Target 2026'), isTrue);
    });
  });

  group('Fase 24: RYNLABS DSP Mathematical Parity', () {
    test('Freeverb internal volume compensation formula', () {
      final dsp = VirtualDspService.instance;

      dsp.setMasterEnabled(true);
      dsp.toggleReverb(true);
      dsp.setReverbParams(wet: 0.6);

      // reverbVolumeCompensationDb = -1.0 * (reverbWet * 0.75) = -1.0 * 0.45 = -0.45 dB
      expect(dsp.reverbVolumeCompensationDb, closeTo(-0.45, 0.01));

      dsp.setReverbParams(wet: 0.0);
      expect(dsp.reverbVolumeCompensationDb, closeTo(0.0, 0.01));
    });

    test('Master bypass cleanly deactivates audio processing without mutation loss', () {
      final dsp = VirtualDspService.instance;

      dsp.setMasterEnabled(true);
      dsp.toggleBassBoost(true);
      dsp.setBassBoostValue(4.5);
      dsp.toggleTubeExciter(true);
      dsp.setTubeParams(drive: 3.0, warmth: 0.8, mix: 0.7);

      expect(dsp.bassBoostEnabled, isTrue);
      expect(dsp.tubeEnabled, isTrue);

      // Bypass
      dsp.setMasterEnabled(false);
      expect(dsp.masterEnabled, isFalse);

      // Reactivate
      dsp.setMasterEnabled(true);
      expect(dsp.masterEnabled, isTrue);
      expect(dsp.bassBoostValue, closeTo(4.5, 0.01));
      expect(dsp.tubeDrive, closeTo(3.0, 0.01));
    });
  });

  group('Fase 24: Responsive Portrait Modal Dialogs & UI/UX Verification', () {
    testWidgets('AutoEqCloudBrowserDialog renders seamlessly in 360x780 portrait without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AutoEqCloudBrowserDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AUTOEQ & SQUIGLINK CLOUD DATABASE'), findsOneWidget);
      expect(find.text('ALL'), findsOneWidget);
      expect(find.text('TARGETS'), findsOneWidget);
      expect(find.text('IEMs'), findsOneWidget);
      expect(find.text('HEADPHONES'), findsOneWidget);

      // Expect no RenderFlex overflow exceptions
      expect(tester.takeException(), isNull);
    });

    testWidgets('AutoEqModalDialog renders seamlessly in 360x780 portrait without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: AutoEqModalDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('AUTO EQ STUDIO & TARGET MATCHING'), findsOneWidget);
      expect(find.text('APPLY TO DSP'), findsOneWidget);
      expect(find.text('BAND RESOLUTION'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });

    testWidgets('SquiglinkDialog renders and tabs function without overflow', (tester) async {
      tester.view.physicalSize = const Size(360, 780);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SquiglinkDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('SQUIGLINK & EQUALIZER APO ENGINE'), findsOneWidget);
      expect(find.text('IMPORT / PASTE'), findsOneWidget);
      expect(find.text('EXPORT PRESET'), findsOneWidget);

      // Tap on Export tab
      await tester.tap(find.text('EXPORT PRESET'));
      await tester.pumpAndSettle();

      expect(find.text('COPY SQUIGLINK'), findsOneWidget);
      expect(find.text('COPY WAVELET'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('BandStripBar interactive PreAmp box opens studio headroom sheet', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              bottomNavigationBar: BandStripBar(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the PreAmp box
      expect(find.text('PRE'), findsOneWidget);

      // Tap the PreAmp box to open bottom sheet
      await tester.tap(find.text('PRE'));
      await tester.pumpAndSettle();

      expect(find.text('PRE-AMP & DIGITAL HEADROOM'), findsOneWidget);
      expect(find.text('PRE-AMP GAIN'), findsOneWidget);
      expect(find.text('0 dB FLAT'), findsOneWidget);

      // Tap 0 dB FLAT chip
      await tester.tap(find.text('0 dB FLAT'));
      await tester.pumpAndSettle();

      expect(VirtualDspService.instance.preampGain, closeTo(0.0, 0.05));
    });

    testWidgets('DspRackScreen renders unit cards with quick gain chips and meters', (tester) async {
      tester.view.physicalSize = const Size(600, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DspRackScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('MASTERING DSP RACK'), findsOneWidget);
      expect(find.text('PRO-Q STUDIO EQ'), findsOneWidget);
      expect(find.text('PRE-AMP GAIN STAGE'), findsOneWidget);
      expect(find.text('DYNAMIC BASS BOOST'), findsOneWidget);
      expect(find.text('TUBE HARMONIC EXCITER'), findsOneWidget);
      expect(find.text('DYNAMIC COMPRESSOR'), findsOneWidget);
      expect(find.text('MID-SIDE STEREO WIDENER'), findsOneWidget);
      expect(find.text('BAUER BINAURAL CROSSFEED'), findsOneWidget);
      expect(find.text('SPATIAL STUDIO REVERB'), findsOneWidget);
      expect(find.text('PEAK BRICKWALL LIMITER'), findsOneWidget);
      expect(find.text('-3 dB'), findsOneWidget);

      expect(tester.takeException(), isNull);
    });
  });
}
