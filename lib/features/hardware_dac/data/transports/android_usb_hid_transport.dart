import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import '../../domain/models/dac_device.dart';
import 'dac_transport.dart';

/// Real Android USB HID Transport that interfaces directly with Android USB Host API via MethodChannel.
class AndroidUsbHidTransport implements DacTransport {
  AndroidUsbHidTransport({
    MethodChannel? channel,
    bool? isAndroid,
  })  : _channel = channel ?? const MethodChannel('com.baydev.baydev_hifi/usb_hid'),
        isAndroidPlatform = isAndroid ?? Platform.isAndroid {
    _initChannelCallbacks();
  }

  final MethodChannel _channel;
  final bool isAndroidPlatform;
  DacDevice? _device;
  bool _isConnected = false;
  void Function()? _onDisconnected;
  void Function()? _onDeviceAttached;
  final StreamController<Uint8List> _inputReportController =
      StreamController<Uint8List>.broadcast();

  void _initChannelCallbacks() {
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'onDeviceDetached') {
        final detachedName = call.arguments is Map ? call.arguments['deviceName'] as String? : null;
        if (detachedName == null || _device?.id == detachedName) {
          await disconnect();
        }
      } else if (call.method == 'onDeviceAttached' || call.method == 'onPermissionGranted') {
        _onDeviceAttached?.call();
      }
    });
  }

  @override
  DacDevice? get currentDevice => _device;

  @override
  bool get isConnected => _isConnected && _device != null;

  @override
  void setOnDisconnectListener(void Function() onDisconnected) {
    _onDisconnected = onDisconnected;
  }

  /// Sets a callback for device attached and permission granted events.
  void setOnDeviceAttachedListener(void Function() onAttached) {
    _onDeviceAttached = onAttached;
  }

  /// Queries Android UsbManager via MethodChannel to locate connected USB DSP DACs.
  static Future<List<DacDevice>> enumerateDevices({
    MethodChannel channel = const MethodChannel('com.baydev.baydev_hifi/usb_hid'),
    bool? isAndroid,
  }) async {
    if (!(isAndroid ?? Platform.isAndroid)) return [];

    try {
      final List<dynamic>? rawList =
          await channel.invokeListMethod<dynamic>('enumerateDevices');
      if (rawList == null) return [];

      final devices = <DacDevice>[];
      for (final raw in rawList) {
        if (raw is Map) {
          final id = raw['id'] as String? ?? 'unknown';
          final vid = raw['vendorId'] as int? ?? 0;
          final pid = raw['productId'] as int? ?? 0;
          final productName = raw['productName'] as String? ?? 'USB Audio DAC';

          final chipset = _detectChipset(vid, pid, productName);
          if (chipset != null) {
            devices.add(DacDevice(
              id: id,
              vendorId: vid,
              productId: pid,
              productName: productName,
              chipset: chipset,
              maxBands: chipset.defaultBands,
            ));
          }
        }
      }
      return devices;
    } catch (_) {
      return [];
    }
  }

  static DacChipset? _detectChipset(int vid, int pid, String name) {
    final lowerName = name.toLowerCase();
    if (vid == 0x3302 || vid == 0x31B2) {
      if (pid == 0x12C3) {
        return DacChipset.kt1132l;
      }
      return DacChipset.kt0211l;
    } else if (lowerName.contains('kiwi') ||
        lowerName.contains('ad1') ||
        lowerName.contains('allegro') ||
        lowerName.contains('coda')) {
      return DacChipset.kt0211l;
    } else if (lowerName.contains('cb-5000') || lowerName.contains('cb5000')) {
      return DacChipset.cb5000x;
    } else if (lowerName.contains('cb-3000') || lowerName.contains('cb3000')) {
      return DacChipset.cb3000s;
    }
    return null;
  }

  @override
  Future<DacDevice?> connect({DacDevice? specificDevice}) async {
    await disconnect();

    if (!isAndroidPlatform) return null;

    DacDevice? target = specificDevice;
    if (target == null) {
      final available = await enumerateDevices(channel: _channel, isAndroid: isAndroidPlatform);
      if (available.isNotEmpty) {
        target = available.first;
      }
    }

    if (target == null) return null;

    try {
      // 1. Request USB Permission
      final bool hasPerm = await _channel.invokeMethod<bool>(
            'requestPermission',
            {'deviceName': target.id},
          ) ??
          false;
      if (!hasPerm) return null;

      // 2. Open Device
      final bool opened = await _channel.invokeMethod<bool>(
            'openDevice',
            {'deviceName': target.id},
          ) ??
          false;
      if (!opened) return null;

      _isConnected = true;
      _device = target.copyWith(isConnected: true);
      return _device;
    } catch (_) {
      await disconnect();
      return null;
    }
  }

  @override
  Future<void> sendOutputReport(int reportId, Uint8List data) async {
    if (!isConnected) {
      throw StateError('Android USB HID transport not connected');
    }

    try {
      final bool success = await _channel.invokeMethod<bool>('sendOutputReport', {
            'reportId': reportId,
            'data': data,
          }) ??
          false;

      if (!success) {
        await disconnect();
        throw StateError('Failed to send output report on Android USB HID');
      }
    } catch (e) {
      await disconnect();
      rethrow;
    }
  }

  @override
  Future<Uint8List> sendCommandWithResponse(
    int reportId,
    Uint8List data, {
    Duration timeout = const Duration(seconds: 4),
    bool verifyFlag = false,
    int flagIndex = 6,
    int expectedFlag = 0x03,
  }) async {
    if (!isConnected) {
      throw StateError('Android USB HID transport not connected');
    }

    try {
      final Uint8List? response = await _channel.invokeMethod<Uint8List>(
        'sendCommandWithResponse',
        {
          'reportId': reportId,
          'data': data,
          'timeoutMs': timeout.inMilliseconds,
        },
      );

      if (response != null && response.isNotEmpty) {
        _inputReportController.add(response);
        return response;
      }

      throw StateError('No response received from Android USB HID');
    } catch (e) {
      await disconnect();
      rethrow;
    }
  }

  @override
  StreamSubscription<Uint8List> listenInputReports(DacInputReportCallback onData) {
    return _inputReportController.stream.listen((bytes) {
      onData(bytes, 0x4B);
    });
  }

  @override
  Future<void> disconnect() async {
    final wasConnected = _isConnected;
    _isConnected = false;
    _device = null;

    try {
      await _channel.invokeMethod('closeDevice');
    } catch (_) {}

    if (wasConnected) {
      _onDisconnected?.call();
    }
  }

  void dispose() {
    _inputReportController.close();
  }
}
