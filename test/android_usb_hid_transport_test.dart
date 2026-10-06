import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/features/hardware_dac/data/transports/android_usb_hid_transport.dart';
import 'package:baydev_hifi/features/hardware_dac/domain/models/dac_device.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AndroidUsbHidTransport Unit Tests', () {
    const channel = MethodChannel('com.baydev.baydev_hifi/usb_hid');
    final log = <MethodCall>[];

    setUp(() {
      log.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);
        switch (methodCall.method) {
          case 'enumerateDevices':
            return [
              {
                'id': '/dev/bus/usb/001/002',
                'vendorId': 0x3302,
                'productId': 0x20E3,
                'productName': 'Kiwi Ears AD1',
                'manufacturer': 'Kiwi Ears',
                'hasPermission': true,
              }
            ];
          case 'requestPermission':
            return true;
          case 'openDevice':
            return true;
          case 'closeDevice':
            return true;
          case 'sendOutputReport':
            return true;
          case 'sendCommandWithResponse':
            // Return 10-byte simulated ACK / response
            return Uint8List.fromList([0x26, 0, 0, 0, 0x52, 0, 0x00, 0x00, 0x50, 0x00]);
          default:
            return null;
        }
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('Initializes in disconnected state', () {
      final transport = AndroidUsbHidTransport(channel: channel, isAndroid: true);
      expect(transport.isConnected, isFalse);
      expect(transport.currentDevice, isNull);
    });

    test('Enumerates connected USB DACs', () async {
      final devices = await AndroidUsbHidTransport.enumerateDevices(
        channel: channel,
        isAndroid: true,
      );
      expect(devices.length, equals(1));
      expect(devices.first.productName, equals('Kiwi Ears AD1'));
      expect(devices.first.vendorId, equals(0x3302));
      expect(devices.first.productId, equals(0x20E3));
      expect(devices.first.chipset, equals(DacChipset.kt0211l));
    });

    test('Connects and claims USB device', () async {
      final transport = AndroidUsbHidTransport(channel: channel, isAndroid: true);
      const targetDevice = DacDevice(
        id: '/dev/bus/usb/001/002',
        vendorId: 0x3302,
        productId: 0x20E3,
        productName: 'Kiwi Ears AD1',
        chipset: DacChipset.kt0211l,
      );

      final connected = await transport.connect(specificDevice: targetDevice);
      expect(connected, isNotNull);
      expect(connected?.productName, equals('Kiwi Ears AD1'));
      expect(transport.isConnected, isTrue);

      expect(
        log.any((call) => call.method == 'requestPermission'),
        isTrue,
      );
      expect(
        log.any((call) => call.method == 'openDevice'),
        isTrue,
      );
    });

    test('Sends output report and receives response', () async {
      final transport = AndroidUsbHidTransport(channel: channel, isAndroid: true);
      const targetDevice = DacDevice(
        id: '/dev/bus/usb/001/002',
        vendorId: 0x3302,
        productId: 0x20E3,
        productName: 'Kiwi Ears AD1',
        chipset: DacChipset.kt0211l,
      );
      await transport.connect(specificDevice: targetDevice);

      final packet = Uint8List.fromList([0x26, 0, 0, 0, 0x52, 0, 0, 0, 0, 0]);
      final response = await transport.sendCommandWithResponse(0x4B, packet);

      expect(response.length, equals(10));
      expect(response[0], equals(0x26));
      expect(
        log.any((call) => call.method == 'sendCommandWithResponse'),
        isTrue,
      );
    });

    test('Disconnects and closes USB connection', () async {
      final transport = AndroidUsbHidTransport(channel: channel, isAndroid: true);
      const targetDevice = DacDevice(
        id: '/dev/bus/usb/001/002',
        vendorId: 0x3302,
        productId: 0x20E3,
        productName: 'Kiwi Ears AD1',
        chipset: DacChipset.kt0211l,
      );
      await transport.connect(specificDevice: targetDevice);

      bool disconnectNotified = false;
      transport.setOnDisconnectListener(() {
        disconnectNotified = true;
      });

      await transport.disconnect();
      expect(transport.isConnected, isFalse);
      expect(transport.currentDevice, isNull);
      expect(disconnectNotified, isTrue);
      expect(
        log.any((call) => call.method == 'closeDevice'),
        isTrue,
      );
    });

    test('Invokes onDeviceAttached listener when native sends event', () async {
      final transport = AndroidUsbHidTransport(channel: channel, isAndroid: true);
      bool attachedNotified = false;
      transport.setOnDeviceAttachedListener(() {
        attachedNotified = true;
      });

      // Simulate native MethodChannel event
      final byteData = const StandardMethodCodec().encodeMethodCall(
        const MethodCall('onPermissionGranted', {'deviceName': '/dev/bus/usb/001/002'}),
      );
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage('com.baydev.baydev_hifi/usb_hid', byteData, (_) {});

      expect(attachedNotified, isTrue);
    });
  });
}
