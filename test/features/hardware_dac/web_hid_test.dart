import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/features/hardware_dac/data/drivers/kiwi_ears_kt_driver.dart';
import 'package:baydev_hifi/features/hardware_dac/data/transports/mock_dac_transport.dart';
import 'package:baydev_hifi/features/hardware_dac/data/transports/web_hid_transport.dart';
import 'package:baydev_hifi/features/hardware_dac/domain/services/auto_eq_to_hardware_fitter.dart';
import 'package:baydev_hifi/features/hardware_dac/presentation/controllers/dac_bridge_controller.dart';
import 'package:baydev_hifi/features/hardware_dac/presentation/controllers/dac_bridge_state.dart';

void main() {
  group('WebHID & Hardware DAC Bridge Tests', () {
    test('WebHidTransport stub safely handles non-web calls', () async {
      final transport = WebHidTransport();
      expect(WebHidTransport.isSupported, isFalse);
      expect(await WebHidTransport.enumerateDevices(), isEmpty);
      expect(await WebHidTransport.requestDevice(), isNull);
      expect(transport.currentDevice, isNull);
      expect(transport.isConnected, isFalse);
    });

    test('DacBridgeController initializes and handles connection state', () async {
      final mockTransport = MockDacTransport(autoConnect: false);
      final driver = KiwiEarsKtDriver(transport: mockTransport);
      const fitter = AutoEqToHardwareFitter();

      final controller = DacBridgeController(
        driver: driver,
        fitter: fitter,
        enableHotplugWatcher: false,
      );

      // Await initial connection attempt
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(
        controller.state.status == DacBridgeStatus.connected ||
            controller.state.status == DacBridgeStatus.disconnected,
        isTrue,
      );
    });
  });
}
