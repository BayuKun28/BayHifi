import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/app/theme/theme_mode_controller.dart';
import 'package:baydev_hifi/audio_engine/audio_cache_service.dart';
import 'package:baydev_hifi/core/database/local_persistence_service.dart';
import 'package:baydev_hifi/features/pro_q_studio/domain/eq_band.dart';
import 'package:baydev_hifi/features/pro_q_studio/domain/pro_q_rta_style.dart';
import 'package:baydev_hifi/features/pro_q_studio/presentation/controllers/eq_controller.dart';
import 'package:baydev_hifi/features/pro_q_studio/presentation/pro_q_studio_screen.dart';
import 'package:baydev_hifi/features/pro_q_studio/presentation/widgets/eq_curve_painter.dart';
import 'package:baydev_hifi/features/pro_q_studio/presentation/widgets/interactive_eq_canvas.dart';
import 'package:baydev_hifi/features/settings/presentation/controllers/player_customization_controller.dart';
import 'package:baydev_hifi/features/settings/presentation/sub_screens/visualizer_settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bayhifi_pro_q_rta_test');
    await LocalPersistenceService.instance.init(customPath: '${tempDir.path}/test_storage.json');
    AudioCacheService.instance.setCacheDirForTesting(tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('ProQRtaStyle Domain & Persistence Tests', () {
    test('ProQRtaStyle.fromString converts all enum names and handles fallbacks', () {
      expect(ProQRtaStyle.fromString('bars'), ProQRtaStyle.bars);
      expect(ProQRtaStyle.fromString('filledCurve'), ProQRtaStyle.filledCurve);
      expect(ProQRtaStyle.fromString('wireframe'), ProQRtaStyle.wireframe);
      expect(ProQRtaStyle.fromString('m3Pillars'), ProQRtaStyle.m3Pillars);
      expect(ProQRtaStyle.fromString('peakDots'), ProQRtaStyle.peakDots);
      expect(ProQRtaStyle.fromString('laserBeam'), ProQRtaStyle.laserBeam);
      expect(ProQRtaStyle.fromString('unknown_style'), ProQRtaStyle.wireframe);
      expect(ProQRtaStyle.fromString(null), ProQRtaStyle.wireframe);
    });

    test('PlayerCustomizationNotifier updates and persists proQRtaStyle', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(playerCustomizationProvider.notifier);
      expect(container.read(playerCustomizationProvider).proQRtaStyle, ProQRtaStyle.wireframe);

      await notifier.setProQRtaStyle(ProQRtaStyle.filledCurve);
      expect(container.read(playerCustomizationProvider).proQRtaStyle, ProQRtaStyle.filledCurve);

      final saved = LocalPersistenceService.instance.getSetting<String>('pro_q_rta_style');
      expect(saved, 'filledCurve');
    });

    test('EqController updates and persists rtaStyle', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(eqControllerProvider.notifier);
      expect(container.read(eqControllerProvider).rtaStyle, ProQRtaStyle.wireframe);

      notifier.setRtaStyle(ProQRtaStyle.laserBeam);
      expect(container.read(eqControllerProvider).rtaStyle, ProQRtaStyle.laserBeam);

      final saved = LocalPersistenceService.instance.getSetting<String>('pro_q_rta_style');
      expect(saved, 'laserBeam');
    });
  });

  group('EqCurvePainter Multi-Style RTA Rendering Tests', () {
    final mockSpectrum = List.generate(48, (i) => (i % 6) / 6.0);

    for (final style in ProQRtaStyle.values) {
      testWidgets('EqCurvePainter renders style $style without exception', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: CustomPaint(
                size: const Size(800, 400),
                painter: EqCurvePainter(
                  bands: EqBand.default10Bands,
                  selectedBandIndex: 1,
                  isEnabled: true,
                  showFrCurves: true,
                  isRtaEnabled: true,
                  rtaStyle: style,
                  rtaSpectrum: mockSpectrum,
                  driverFr: null,
                  targetFr: null,
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        expect(find.byType(CustomPaint), findsWidgets);
      });
    }

    testWidgets('InteractiveEqCanvas integrates rtaStyle cleanly', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 800,
                height: 400,
                child: InteractiveEqCanvas(),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.byType(InteractiveEqCanvas), findsOneWidget);
    });
  });

  group('Settings & Pro-Q Screen UI Tests', () {
    testWidgets('VisualizerSettingsScreen displays PRO-Q STUDIO selector and updates style', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.binding.setSurfaceSize(const Size(800, 1400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppThemeBuilder.buildTheme(AppPalette.namidaCyan, isDark: true),
            home: const VisualizerSettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('PRO-Q STUDIO REALTIME SPECTRUM GRAPH'), findsOneWidget);
      expect(find.text(ProQRtaStyle.wireframe.label), findsOneWidget);
    });

    testWidgets('ProQStudioScreen renders RTA quick group and menu items', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.binding.setSurfaceSize(const Size(1280, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppThemeBuilder.buildTheme(AppPalette.namidaCyan, isDark: true),
            home: const ProQStudioScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Legend 'RTA' + Button 'RTA'
      expect(find.text('RTA'), findsNWidgets(2));
      // LINE short label should be displayed by default
      expect(find.text('LINE'), findsOneWidget);

      // Open RTA popup menu
      await tester.tap(find.text('LINE'));
      await tester.pumpAndSettle();

      // Check header and options inside popup menu
      expect(find.text('RTA SPECTRUM STYLE'), findsOneWidget);
      expect(find.text('Smooth Spectral Fill'), findsOneWidget);
      expect(find.text('Precision Line Contour'), findsOneWidget);
      expect(find.text('Studio Laser Trace'), findsOneWidget);

      // Select 'Smooth Spectral Fill'
      await tester.tap(find.text('Smooth Spectral Fill'));
      await tester.pumpAndSettle();

      expect(container.read(eqControllerProvider).rtaStyle, ProQRtaStyle.filledCurve);
      expect(container.read(playerCustomizationProvider).proQRtaStyle, ProQRtaStyle.filledCurve);
      expect(find.text('FILL'), findsOneWidget);
    });

    testWidgets('Changing proQRtaStyle in settings immediately updates InteractiveEqCanvas', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppThemeBuilder.buildTheme(AppPalette.namidaCyan, isDark: true),
            home: const Scaffold(
              body: SizedBox(
                width: 800,
                height: 400,
                child: InteractiveEqCanvas(),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Change in playerCustomizationProvider via runAsync for file IO
      await tester.runAsync(() async {
        await container.read(playerCustomizationProvider.notifier).setProQRtaStyle(ProQRtaStyle.bars);
      });
      await tester.pump();

      final customPaint = tester.widget<CustomPaint>(
        find.descendant(
          of: find.byType(InteractiveEqCanvas),
          matching: find.byType(CustomPaint),
        ),
      );
      expect((customPaint.painter as EqCurvePainter).rtaStyle, ProQRtaStyle.bars);
    });
  });
}
