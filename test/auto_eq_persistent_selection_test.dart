import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/core/database/local_persistence_service.dart';
import 'package:baydev_hifi/features/pro_q_studio/domain/fr_curve_data.dart';
import 'package:baydev_hifi/features/pro_q_studio/presentation/controllers/eq_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('bayhifi_autoeq_pers_test_');
    await LocalPersistenceService.instance.init(customPath: '${tempDir.path}/test_storage.json');
  });

  tearDown(() {
    try {
      if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('AutoEQ & Pro-Q Driver/Target Persistent Selection Tests', () {
    test('LocalPersistenceService stores and returns last selected curve names', () async {
      final initial = LocalPersistenceService.instance.getLastSelectedAutoEqCurves();
      expect(initial['driverName'], isNull);
      expect(initial['targetName'], isNull);

      await LocalPersistenceService.instance.saveActiveEqState(
        bands: [],
        preampDb: -1.5,
        activePresetName: 'Custom EQ',
        lastDriverName: 'Moondrop Chu II',
        lastTargetName: 'Harman In-Ear 2019 v2',
      );

      final loaded = LocalPersistenceService.instance.getLastSelectedAutoEqCurves();
      expect(loaded['driverName'], 'Moondrop Chu II');
      expect(loaded['targetName'], 'Harman In-Ear 2019 v2');
    });

    test('EqController persists driver and target selections and rehydrates across instances', () async {
      // Create custom curves
      const customDriver = FrCurveData(
        name: 'Truthear Zero Red',
        frequencies: [20.0, 1000.0, 10000.0],
        splDb: [80.0, 85.0, 82.0],
      );
      const customTarget = FrCurveData(
        name: 'Crinacle 2023 Target',
        frequencies: [20.0, 1000.0, 10000.0],
        splDb: [82.0, 85.0, 80.0],
      );

      // Save custom curves to persistence
      await LocalPersistenceService.instance.saveFrCurve(customDriver.toMap(category: 'driver'));
      await LocalPersistenceService.instance.saveFrCurve(customTarget.toMap(category: 'target'));

      // 1. First Controller Instance: Select Driver and Target
      final controller1 = EqController();
      controller1.selectDriver(customDriver);
      controller1.selectTarget(customTarget);

      expect(controller1.state.driverFr?.name, 'Truthear Zero Red');
      expect(controller1.state.targetFr?.name, 'Crinacle 2023 Target');

      await Future.delayed(const Duration(milliseconds: 50));
      controller1.dispose();

      // 2. Second Controller Instance (Simulating app restart / new session)
      final controller2 = EqController();
      // Wait for async _loadSampleCurves to finish
      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller2.state.driverFr, isNotNull);
      expect(controller2.state.driverFr!.name, 'Truthear Zero Red');
      expect(controller2.state.targetFr, isNotNull);
      expect(controller2.state.targetFr!.name, 'Crinacle 2023 Target');

      controller2.dispose();
    });

    test('EqController rehydrates built-in models like Moondrop Chu II and Harman In-Ear 2019v2 without offline save', () async {
      // 1. First Controller Instance: Select built-in Driver and Target
      final chu2 = FrCurveData.defaultDrivers.firstWhere((d) => d.name == 'Moondrop Chu II');
      final harman = FrCurveData.defaultTargets.firstWhere((t) => t.name == 'Harman In-Ear 2019v2');

      final controller1 = EqController();
      controller1.selectDriver(chu2);
      controller1.selectTarget(harman);

      expect(controller1.state.driverFr?.name, 'Moondrop Chu II');
      expect(controller1.state.targetFr?.name, 'Harman In-Ear 2019v2');

      await Future.delayed(const Duration(milliseconds: 50));
      controller1.dispose();

      // 2. Second Controller Instance (Simulating Android kill recent app & restart)
      final controller2 = EqController();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller2.state.driverFr, isNotNull);
      expect(controller2.state.driverFr!.name, 'Moondrop Chu II');
      expect(controller2.state.targetFr, isNotNull);
      expect(controller2.state.targetFr!.name, 'Harman In-Ear 2019v2');

      controller2.dispose();
    });

    test('EqController rehydrates custom curve from serialized curve map fallback', () async {
      // Direct raw write to persistence with serialized curve map but not in saved_fr_curves list
      await LocalPersistenceService.instance.saveActiveEqState(
        bands: [],
        preampDb: -2.0,
        activePresetName: 'Custom Mode',
        lastDriverName: 'Rare Unique Headphone',
        lastDriverCurve: const FrCurveData(
          name: 'Rare Unique Headphone',
          frequencies: [20.0, 1000.0, 15000.0],
          splDb: [85.0, 80.0, 75.0],
        ).toMap(category: 'driver'),
      );

      final controller = EqController();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(controller.state.driverFr, isNotNull);
      expect(controller.state.driverFr!.name, 'Rare Unique Headphone');
      expect(controller.state.driverFr!.frequencies, [20.0, 1000.0, 15000.0]);

      controller.dispose();
    });

    test('EqController clears persistent driver/target selection on delete and clear', () async {
      const customDriver = FrCurveData(
        name: 'Tangzu Waner',
        frequencies: [20.0, 1000.0, 10000.0],
        splDb: [80.0, 85.0, 82.0],
      );
      await LocalPersistenceService.instance.saveFrCurve(customDriver.toMap(category: 'driver'));

      final controller = EqController();
      controller.selectDriver(customDriver);
      expect(controller.state.driverFr?.name, 'Tangzu Waner');

      controller.deleteDriver();
      expect(controller.state.driverFr, isNull);

      final saved = LocalPersistenceService.instance.getLastSelectedAutoEqCurves();
      expect(saved['driverName'], isNull);

      await Future.delayed(const Duration(milliseconds: 50));
      controller.dispose();
    });
  });
}
