// ignore_for_file: avoid_print
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/features/hardware_dac/data/drivers/kiwi_ears_kt_driver.dart';
import 'package:baydev_hifi/features/hardware_dac/data/transports/linux_hidraw_transport.dart';

void main() {
  test('Live LinuxHidRawTransport with Kiwi Ears AD1', () async {
    if (!Platform.isLinux) return;

    final devices = await LinuxHidRawTransport.enumerateDevices();
    if (devices.isEmpty) {
      return;
    }

    final transport = LinuxHidRawTransport();
    final connected = await transport.connect(specificDevice: devices.first);
    expect(connected, isNotNull);
    expect(transport.isConnected, isTrue);

    final driver = KiwiEarsKtDriver(transport: transport);
    final initialized = await driver.initialize();
    expect(initialized, isTrue);

    final bands = await driver.readAllBands();
    expect(bands.length, 5);

    final eqEnabled = await driver.getEqEnabled();
    expect(eqEnabled, isNotNull);

    await driver.dispose();
  });
}

