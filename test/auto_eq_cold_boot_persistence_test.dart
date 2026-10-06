import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/core/database/local_persistence_service.dart';
import 'package:baydev_hifi/features/pro_q_studio/domain/eq_band.dart';
import 'package:baydev_hifi/features/pro_q_studio/domain/fr_curve_data.dart';
import 'package:baydev_hifi/features/pro_q_studio/domain/auto_eq_optimizer.dart';
import 'package:baydev_hifi/features/pro_q_studio/presentation/controllers/eq_controller.dart';
import 'package:baydev_hifi/features/pro_q_studio/presentation/controllers/eq_state.dart';
import 'package:baydev_hifi/features/hardware_dac/presentation/controllers/dac_bridge_controller.dart';
import 'package:baydev_hifi/features/hardware_dac/presentation/controllers/dac_bridge_state.dart';
import 'package:baydev_hifi/features/player/presentation/controllers/player_controller.dart';
import 'package:baydev_hifi/features/player/domain/playback_state.dart';
import 'package:baydev_hifi/features/player/presentation/widgets/studio_dsp_bento_capsule.dart';

class _FakeDacController extends StateNotifier<DacBridgeState>
    implements DacBridgeController {
  _FakeDacController(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeEqController extends StateNotifier<EqState> implements EqController {
  _FakeEqController(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePlayerController extends StateNotifier<PlaybackState>
    implements PlayerController {
  _FakePlayerController(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late String dbPath;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('baydev_autoeq_persist_test_');
    dbPath = '${tempDir.path}/test_storage.json';
    await LocalPersistenceService.instance.init(customPath: dbPath);
  });

  tearDown(() async {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('AutoEQ Cold-Boot Persistence & Hydration Tests', () {
    test('LocalPersistenceService accurately stores and retrieves AutoEQ active state and curves', () async {
      final storage = LocalPersistenceService.instance;

      final testDriver = FrCurveData(
        name: 'KZ CASTOR BLACK DUDU R',
        frequencies: [20.0, 100.0, 1000.0, 10000.0],
        splDb: [80.0, 85.0, 90.0, 82.0],
      );
      final testTarget = FrCurveData(
        name: 'HBB Target',
        frequencies: [20.0, 100.0, 1000.0, 10000.0],
        splDb: [82.0, 84.0, 90.0, 80.0],
      );

      final customBands = EqBand.default10Bands.map((b) => b.copyWith(gainDb: 2.5)).toList();

      await storage.saveActiveEqState(
        bands: customBands.map((b) => b.toMap()).toList(),
        preampDb: -3.2,
        activePresetName: 'AutoEQ: KZ CASTOR BLACK DUDU R → HBB Target',
        lastDriverName: testDriver.name,
        lastTargetName: testTarget.name,
        lastDriverCurve: testDriver.toMap(category: 'driver'),
        lastTargetCurve: testTarget.toMap(category: 'target'),
        isAutoEqActive: true,
        isEnabled: true,
        bandResolution: BandResolution.b10.name,
        tuningMode: TuningMode.normal.name,
      );

      final retrieved = storage.getActiveEqState();
      expect(retrieved, isNotNull);
      expect(retrieved!['isAutoEqActive'], isTrue);
      expect(retrieved['isEnabled'], isTrue);
      expect(retrieved['lastDriverName'], 'KZ CASTOR BLACK DUDU R');
      expect(retrieved['lastTargetName'], 'HBB Target');
      expect(retrieved['bandResolution'], 'b10');
      expect(retrieved['tuningMode'], 'normal');

      final curves = storage.getLastSelectedAutoEqCurves();
      expect(curves['driverName'], 'KZ CASTOR BLACK DUDU R');
      expect(curves['targetName'], 'HBB Target');
      expect(curves['driverCurve'], isNotNull);
      expect(curves['targetCurve'], isNotNull);
    });

    test('EqController constructor synchronously hydrates driverFr, targetFr, and isAutoEqActive on cold boot', () async {
      final storage = LocalPersistenceService.instance;

      final testDriver = FrCurveData(
        name: 'KZ CASTOR BLACK DUDU R',
        frequencies: [20.0, 100.0, 1000.0, 10000.0],
        splDb: [80.0, 85.0, 90.0, 82.0],
      );
      final testTarget = FrCurveData(
        name: 'HBB Target',
        frequencies: [20.0, 100.0, 1000.0, 10000.0],
        splDb: [82.0, 84.0, 90.0, 80.0],
      );

      final customBands = EqBand.default10Bands.map((b) {
        if (b.index == 1) return b.copyWith(gainDb: 4.0);
        return b;
      }).toList();

      await storage.saveActiveEqState(
        bands: customBands.map((b) => b.toMap()).toList(),
        preampDb: -4.0,
        activePresetName: 'AutoEQ: KZ CASTOR BLACK DUDU R → HBB Target',
        lastDriverName: testDriver.name,
        lastTargetName: testTarget.name,
        lastDriverCurve: testDriver.toMap(category: 'driver'),
        lastTargetCurve: testTarget.toMap(category: 'target'),
        isAutoEqActive: true,
        isEnabled: true,
      );

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Read state immediately on cold boot
      final state = container.read(eqControllerProvider);

      expect(state.isAutoEqActive, isTrue);
      expect(state.isEnabled, isTrue);
      expect(state.driverFr, isNotNull);
      expect(state.driverFr!.name, 'KZ CASTOR BLACK DUDU R');
      expect(state.targetFr, isNotNull);
      expect(state.targetFr!.name, 'HBB Target');
      expect(state.bands.first.gainDb, 4.0);
      expect(state.safePreampDb, -4.0);
    });

    test('applyAutoEq accurately activates isAutoEqActive and writes changes to storage', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(eqControllerProvider.notifier);

      final driver = FrCurveData(
        name: 'KZ Castor Black',
        frequencies: [31.0, 62.0, 125.0, 250.0, 500.0, 1000.0, 2000.0, 4000.0, 8000.0, 16000.0],
        splDb: [80.0, 82.0, 83.0, 84.0, 85.0, 85.0, 86.0, 87.0, 88.0, 82.0],
      );
      final target = FrCurveData(
        name: 'Harman Target',
        frequencies: [31.0, 62.0, 125.0, 250.0, 500.0, 1000.0, 2000.0, 4000.0, 8000.0, 16000.0],
        splDb: [85.0, 84.0, 83.0, 82.0, 81.0, 80.0, 82.0, 84.0, 82.0, 80.0],
      );

      notifier.selectDriver(driver);
      notifier.selectTarget(target);

      final success = notifier.applyAutoEq();
      expect(success, isTrue);

      final state = container.read(eqControllerProvider);
      expect(state.isAutoEqActive, isTrue);
      expect(state.activePresetName, contains('AutoEQ: KZ Castor Black → Harman Target'));

      // Verify persisted state in storage
      final stored = LocalPersistenceService.instance.getActiveEqState();
      expect(stored, isNotNull);
      expect(stored!['isAutoEqActive'], isTrue);
      expect(stored['lastDriverName'], 'KZ Castor Black');
      expect(stored['lastTargetName'], 'Harman Target');
    });

    testWidgets('StudioDspBentoCapsule renders active abbreviated driver name on cold boot when isAutoEqActive is true', (tester) async {
      final hydratedState = EqState(
        bands: EqBand.default10Bands,
        isAutoEqActive: true,
        isEnabled: true,
        driverFr: const FrCurveData(
          name: 'KZ CASTOR BLACK DUDU R',
          frequencies: [20.0, 1000.0, 20000.0],
          splDb: [80.0, 90.0, 80.0],
        ),
      );

      final container = ProviderContainer(
        overrides: [
          eqControllerProvider.overrideWith(
            (ref) => _FakeEqController(hydratedState),
          ),
          dacBridgeControllerProvider.overrideWith(
            (ref) => _FakeDacController(const DacBridgeState()),
          ),
          playerControllerProvider.overrideWith(
            (ref) => _FakePlayerController(const PlaybackState(status: PlaybackStatus.paused)),
          ),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: StudioDspBentoCapsule(),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Check formatted driver label rendered in capsule
      final expectedLabel = StudioDspBentoCapsule.formatAutoEqLabel('KZ CASTOR BLACK DUDU R');
      expect(expectedLabel, 'KZ CASTOR...');
      expect(find.text('KZ CASTOR...'), findsOneWidget);
    });
  });
}
