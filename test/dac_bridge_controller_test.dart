import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/features/hardware_dac/data/drivers/kiwi_ears_kt_driver.dart';
import 'package:baydev_hifi/features/hardware_dac/data/transports/mock_dac_transport.dart';
import 'package:baydev_hifi/features/hardware_dac/domain/models/dac_device.dart';
import 'package:baydev_hifi/features/hardware_dac/domain/services/auto_eq_to_hardware_fitter.dart';
import 'package:baydev_hifi/features/hardware_dac/presentation/controllers/dac_bridge_controller.dart';
import 'package:baydev_hifi/features/hardware_dac/presentation/controllers/dac_bridge_state.dart';
import 'package:baydev_hifi/features/pro_q_studio/domain/eq_band.dart';

void main() {
  group('DacBridgeController StateNotifier Tests', () {
    late MockDacTransport transport;
    late KiwiEarsKtDriver driver;
    late AutoEqToHardwareFitter fitter;
    late DacBridgeController controller;

    setUp(() {
      transport = MockDacTransport();
      driver = KiwiEarsKtDriver(transport: transport, chipset: DacChipset.kt0211l);
      fitter = const AutoEqToHardwareFitter();
      controller = DacBridgeController(driver: driver, fitter: fitter);
    });

    tearDown(() {
      transport.dispose();
    });

    test('Auto-connects to mock DAC on initialization', () async {
      await controller.scanAndConnect();

      expect(controller.state.status, equals(DacBridgeStatus.connected));
      expect(controller.state.isConnected, isTrue);
      expect(controller.state.device?.productName, contains('Kiwi Ears AD1'));
      expect(controller.state.bands.length, equals(5));
      expect(controller.state.isEqEnabled, isTrue);
    });

    test('Updates individual band frequency & gain and marks flash as dirty', () async {
      await controller.scanAndConnect();

      final updated = await controller.updateBand(0, frequency: 55.0, gainDb: 4.0, qFactor: 0.90);
      expect(updated, isTrue);

      expect(controller.state.bands[0].frequency, closeTo(55.0, 0.1));
      expect(controller.state.bands[0].gainDb, closeTo(4.0, 0.1));
      expect(controller.state.hasUnsavedFlashChanges, isTrue);
    });

    test('Imports multi-band curve from AutoEQ and updates hardware', () async {
      await controller.scanAndConnect();

      final sourceBands = [
        const EqBand(index: 1, frequency: 50.0, gainDb: 5.0, q: 0.7, type: FilterType.lowShelf, isEnabled: true, color: Colors.blue),
        const EqBand(index: 2, frequency: 3000.0, gainDb: 3.0, q: 1.4, type: FilterType.peaking, isEnabled: true, color: Colors.green),
      ];

      final importOk = await controller.importFromAutoEq(sourceBands, name: 'Test AutoEQ');
      expect(importOk, isTrue);
      expect(controller.state.currentProfile.name, equals('Test AutoEQ'));
      expect(controller.state.hasUnsavedFlashChanges, isTrue);
    });

    test('Burns changes to Flash and resets dirty flag', () async {
      await controller.scanAndConnect();
      await controller.updateBand(1, gainDb: -3.0);
      expect(controller.state.hasUnsavedFlashChanges, isTrue);

      final burnOk = await controller.burnToFlash();
      expect(burnOk, isTrue);
      expect(controller.state.hasUnsavedFlashChanges, isFalse);
    });

    test('Restores factory defaults via clearFlash', () async {
      await controller.scanAndConnect();
      await controller.updateBand(0, gainDb: 6.0);

      final clearOk = await controller.clearFlash();
      expect(clearOk, isTrue);
      expect(controller.state.bands[0].gainDb, closeTo(0.0, 0.1));
      expect(controller.state.hasUnsavedFlashChanges, isFalse);
    });
  });
}
