import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/core/database/local_persistence_service.dart';
import 'package:baydev_hifi/features/hardware_dac/data/drivers/kiwi_ears_kt_driver.dart';
import 'package:baydev_hifi/features/hardware_dac/data/transports/mock_dac_transport.dart';
import 'package:baydev_hifi/features/hardware_dac/domain/models/dac_band_config.dart';
import 'package:baydev_hifi/features/hardware_dac/domain/models/dac_peq_profile.dart';
import 'package:baydev_hifi/features/hardware_dac/domain/services/auto_eq_to_hardware_fitter.dart';
import 'package:baydev_hifi/features/hardware_dac/presentation/controllers/dac_bridge_controller.dart';
import 'package:baydev_hifi/features/hardware_dac/presentation/widgets/dac_profile_manager_modal.dart';
import 'package:baydev_hifi/features/hardware_dac/presentation/widgets/save_dac_profile_dialog.dart';
import 'package:baydev_hifi/features/pro_q_studio/domain/fr_curve_data.dart';
import 'package:baydev_hifi/features/pro_q_studio/presentation/widgets/saved_curves_library_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;
  late LocalPersistenceService storage;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bayhifi_curves_dac_test');
    final dbFile = File('${tempDir.path}/test_storage.json');
    storage = LocalPersistenceService.instance;
    await storage.init(customPath: dbFile.path);
    await storage.switchUser('guest');
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('FrCurveData Model & Export Tests', () {
    test('FrCurveData serialization and deserialization with metadata', () {
      final now = DateTime.now();
      final curve = FrCurveData(
        id: 'curve_kz_test',
        name: 'KZ Castor Studio Spec',
        category: 'driver',
        frequencies: [20.0, 1000.0, 10000.0],
        splDb: [85.5, 78.0, 80.2],
        referenceSpl1kHz: 78.0,
        importedAt: now,
        sourceFileName: 'kz_castor.txt',
      );

      final map = curve.toMap();
      expect(map['id'], 'curve_kz_test');
      expect(map['name'], 'KZ Castor Studio Spec');
      expect(map['category'], 'driver');
      expect(map['sourceFileName'], 'kz_castor.txt');

      final fromMap = FrCurveData.fromMap(map);
      expect(fromMap.id, 'curve_kz_test');
      expect(fromMap.name, 'KZ Castor Studio Spec');
      expect(fromMap.category, 'driver');
      expect(fromMap.frequencies.length, 3);
      expect(fromMap.isDefault, isFalse);
    });

    test('FrCurveData exports valid REW V5 tab-separated text', () {
      const curve = FrCurveData(
        name: 'My Custom IEM',
        category: 'driver',
        frequencies: [20.0, 1000.0, 8000.0],
        splDb: [84.2, 75.0, 81.3],
      );

      final rewText = curve.exportToRewText();
      expect(rewText, contains('* Name: My Custom IEM'));
      expect(rewText, contains('Freq\tSPL'));
      expect(rewText, contains('20.0\t84.20'));
      expect(rewText, contains('1000.0\t75.00'));
    });

    test('FrCurveData exports valid Squiglink comma-separated CSV text', () {
      const curve = FrCurveData(
        name: 'Studio Bass Target',
        category: 'target',
        frequencies: [20.0, 1000.0, 10000.0],
        splDb: [105.0, 95.0, 90.0],
      );

      final csvText = curve.exportToSquiglinkCsv();
      expect(csvText, contains('Freq,SPL'));
      expect(csvText, contains('20.0,105.00'));
      expect(csvText, contains('1000.0,95.00'));
    });
  });

  group('DacPeqProfile Model & Export/Import Tests', () {
    test('DacPeqProfile JSON export and import round-trip', () {
      final profile = DacPeqProfile(
        id: 'custom_dac_1',
        name: 'Vocal Clarity Plus',
        description: 'Tuned for acoustic vocals',
        preampGainDb: -3.0,
        bands: [
          const DacBandConfig(bandIndex: 0, frequency: 100.0, gainDb: 2.0, qFactor: 1.0),
          const DacBandConfig(bandIndex: 1, frequency: 1200.0, gainDb: 3.5, qFactor: 1.4),
        ],
        createdAt: DateTime(2026, 10, 15),
      );

      final jsonStr = profile.exportToJsonString();
      expect(jsonStr, contains('Vocal Clarity Plus'));
      expect(jsonStr, contains('-3.0'));

      final imported = DacPeqProfile.importFromJsonString(jsonStr);
      expect(imported, isNotNull);
      expect(imported!.id, 'custom_dac_1');
      expect(imported.name, 'Vocal Clarity Plus');
      expect(imported.preampGainDb, -3.0);
      expect(imported.bands.length, 2);
      expect(imported.isBuiltIn, isFalse);
    });

    test('isBuiltIn returns true for factory presets', () {
      expect(DacPeqProfile.flatDefault.isBuiltIn, isTrue);
      expect(DacPeqProfile.warmVocal.isBuiltIn, isTrue);
      expect(DacPeqProfile.harmanIemTarget.isBuiltIn, isTrue);
      expect(DacPeqProfile.acousticClarity.isBuiltIn, isTrue);
    });
  });

  group('LocalPersistenceService Multi-User Scoping for Curves & DAC Profiles', () {
    test('Saved FR curves and DAC profiles are strictly isolated per user', () async {
      // 1. User A stores a custom driver curve and DAC profile
      await storage.switchUser('user_alice');
      await storage.saveFrCurve(
        const FrCurveData(
          id: 'driver_alice_iem',
          name: 'Alice Custom IEM',
          category: 'driver',
          frequencies: [20.0, 1000.0],
          splDb: [85.0, 75.0],
        ).toMap(),
      );
      await storage.saveDacProfile(
        const DacPeqProfile(
          id: 'dac_alice_tune',
          name: 'Alice DAC Warm',
          bands: [],
          preampGainDb: -1.5,
        ).toJson(),
      );

      expect(storage.getSavedFrCurves().length, 1);
      expect(storage.getSavedDacProfiles().length, 1);

      // 2. Switch to User B -> should be empty
      await storage.switchUser('user_bob', cloneGuestIfEmpty: false);
      expect(storage.getSavedFrCurves(), isEmpty);
      expect(storage.getSavedDacProfiles(), isEmpty);

      // 3. User B stores their own curve
      await storage.saveFrCurve(
        const FrCurveData(
          id: 'target_bob_curve',
          name: 'Bob Bass Target',
          category: 'target',
          frequencies: [20.0, 1000.0],
          splDb: [100.0, 95.0],
        ).toMap(),
      );
      expect(storage.getSavedFrCurves().length, 1);
      expect(storage.getSavedFrCurves(category: 'target').length, 1);
      expect(storage.getSavedFrCurves(category: 'driver').length, 0);

      // 4. Switch back to User A -> Alice curves and DAC profile are intact
      await storage.switchUser('user_alice');
      final aliceCurves = storage.getSavedFrCurves();
      final aliceDac = storage.getSavedDacProfiles();
      expect(aliceCurves.length, 1);
      expect(aliceCurves.first['name'], 'Alice Custom IEM');
      expect(aliceDac.length, 1);
      expect(aliceDac.first['name'], 'Alice DAC Warm');

      // 5. Test deletion
      await storage.deleteFrCurve('Alice Custom IEM');
      expect(storage.getSavedFrCurves(), isEmpty);
      await storage.deleteDacProfile('dac_alice_tune');
      expect(storage.getSavedDacProfiles(), isEmpty);
    });
  });

  group('DacBridgeController Profile Lifecycle Tests', () {
    test('DacBridgeController saves and deletes custom profiles', () async {
      final mockTransport = MockDacTransport(autoConnect: false);
      final driver = KiwiEarsKtDriver(transport: mockTransport);
      final controller = DacBridgeController(
        driver: driver,
        fitter: const AutoEqToHardwareFitter(),
        enableHotplugWatcher: false,
      );

      // Initial state has 4 built-in presets
      expect(controller.state.availablePresets.length, 4);

      // Save active tuning as a profile
      final saved = await controller.saveCurrentAsProfile(
        name: 'Studio Master Tuning',
        description: 'Smooth treble curve',
      );

      expect(saved.name, 'Studio Master Tuning');
      expect(controller.state.availablePresets.length, 5);
      expect(controller.state.currentProfile.name, 'Studio Master Tuning');

      // Delete custom profile
      final deleted = await controller.deleteCustomProfile(saved.id);
      expect(deleted, isTrue);
      expect(controller.state.availablePresets.length, 4);
    });

    test('DacBridgeController imports profile from JSON string', () async {
      final mockTransport = MockDacTransport(autoConnect: false);
      final driver = KiwiEarsKtDriver(transport: mockTransport);
      final controller = DacBridgeController(
        driver: driver,
        fitter: const AutoEqToHardwareFitter(),
        enableHotplugWatcher: false,
      );

      final profileJson = const DacPeqProfile(
        id: 'imported_test_dac',
        name: 'Imported Bass Boost',
        bands: [
          DacBandConfig(bandIndex: 0, frequency: 50.0, gainDb: 4.0, qFactor: 0.7),
        ],
        preampGainDb: -4.0,
      ).exportToJsonString();

      final imported = await controller.importProfileFromJson(profileJson);
      expect(imported, isNotNull);
      expect(imported!.name, 'Imported Bass Boost');
      expect(controller.state.availablePresets.any((p) => p.name == 'Imported Bass Boost'), isTrue);
    });
  });

  group('Widget Tests: SavedCurvesLibrarySheet & Dac Profile Dialogs', () {
    testWidgets('SavedCurvesLibrarySheet renders tabs and curve items', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SavedCurvesLibrarySheet(initialCategory: 'driver'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('FR CURVE LIBRARY'), findsOneWidget);
      expect(find.text('Drivers / IEMs'), findsOneWidget);
      expect(find.text('Target Curves'), findsOneWidget);
      expect(find.text('KZ CASTOR BLACK DUDU R'), findsOneWidget);
      expect(find.text('ACTIVE'), findsOneWidget);

      // Switch to Targets tab
      await tester.tap(find.text('Target Curves'));
      await tester.pumpAndSettle();
      expect(find.text('HBB Target'), findsOneWidget);
      expect(find.text('LOAD'), findsWidgets);
    });

    testWidgets('SaveDacProfileDialog validates empty name and accepts input', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockTransport = MockDacTransport(autoConnect: false);
      final driver = KiwiEarsKtDriver(transport: mockTransport);
      final controller = DacBridgeController(
        driver: driver,
        fitter: const AutoEqToHardwareFitter(),
        enableHotplugWatcher: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dacBridgeControllerProvider.overrideWith((ref) => controller),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SaveDacProfileDialog(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Save DAC Profile'), findsOneWidget);
      expect(find.text('SAVE PROFILE'), findsOneWidget);

      // Tap SAVE PROFILE without filling name -> validation error
      await tester.tap(find.text('SAVE PROFILE'));
      await tester.pumpAndSettle();
      expect(find.text('Please enter a profile name'), findsOneWidget);

      // Enter profile name
      final nameField = find.byType(TextField).first;
      await tester.enterText(nameField, 'My Audiophile DAC');
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pump();

      // Tap SAVE PROFILE and allow async file I/O to complete inside real async zone
      await tester.runAsync(() async {
        await tester.tap(find.text('SAVE PROFILE'));
        await tester.pump();
        for (var i = 0; i < 20; i++) {
          if (controller.state.availablePresets.any((p) => p.name == 'My Audiophile DAC')) {
            break;
          }
          await Future.delayed(const Duration(milliseconds: 50));
        }
      });
      await tester.pump();

      expect(controller.state.availablePresets.any((p) => p.name == 'My Audiophile DAC'), isTrue);
    });

    testWidgets('DacProfileManagerModal renders factory presets and custom sections', (tester) async {
      tester.view.physicalSize = const Size(1200, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final mockTransport = MockDacTransport(autoConnect: false);
      final driver = KiwiEarsKtDriver(transport: mockTransport);
      final controller = DacBridgeController(
        driver: driver,
        fitter: const AutoEqToHardwareFitter(),
        enableHotplugWatcher: false,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dacBridgeControllerProvider.overrideWith((ref) => controller),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: DacProfileManagerModal(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('DAC PROFILE LIBRARY'), findsOneWidget);
      expect(find.text('USER CUSTOM PROFILES'), findsOneWidget);
      expect(find.text('FACTORY STOCK PRESETS'), findsOneWidget);
      expect(find.text('Factory Flat'), findsOneWidget);
      expect(find.text('Warm Studio & Vocals'), findsOneWidget);
      expect(find.text('Harman 2019 IEM Target'), findsOneWidget);
      expect(find.text('LOAD TO DAC'), findsWidgets);
    });
  });
}
