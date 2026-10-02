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
