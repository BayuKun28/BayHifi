import 'dart:async';
import 'dart:js_interop';
import 'dart:js_interop_unsafe';
import 'dart:typed_data';
import '../../domain/models/dac_device.dart';
import 'dac_transport.dart';

/// Real WebHID Transport for Web browsers (Chrome, Edge, Chromium).
/// Directly controls physical USB DSP DACs (Kiwi Ears AD1, KTMicro KT0211L, KT1132L)
/// using W3C WebHID API.
class WebHidTransport implements DacTransport {
  WebHidTransport() {
    _initBridge();
  }

  DacDevice? _device;
  bool _isConnected = false;
  void Function()? _onDisconnected;
  final StreamController<Uint8List> _inputReportController =
      StreamController<Uint8List>.broadcast();

  JSFunction? _unregisterInput;
  JSFunction? _unregisterDisconnect;

  static JSObject? get _bridge => globalContext['bayHifiWebHid'] as JSObject?;

  static bool get isSupported {
    final b = _bridge;
    if (b == null) return false;
    final res = b.callMethod('isSupported'.toJS) as JSBoolean?;
    return res?.toDart ?? false;
  }

  static DacChipset _resolveChipset(int vid, int pid, String name) {
    if (vid == 0x3302 || vid == 0x31B2) {
      if (pid == 0x12C3) {
        return DacChipset.kt1132l;
      }
      return DacChipset.kt0211l;
    }
    final lower = name.toLowerCase();
    if (lower.contains('kt1132') || lower.contains('allegro')) {
      return DacChipset.kt1132l;
    }
    return DacChipset.kt0211l;
  }

  static DacDevice _buildDacDevice(JSObject obj) {
    final id = (obj['id'] as JSString?)?.toDart ?? 'webhid_device';
    final vid = (obj['vendorId'] as JSNumber?)?.toDartInt ?? 0x31B2;
    final pid = (obj['productId'] as JSNumber?)?.toDartInt ?? 0x0111;
    final name = (obj['productName'] as JSString?)?.toDart ?? 'Kiwi Ears AD1';
    final chipset = _resolveChipset(vid, pid, name);

    return DacDevice(
      id: id,
      vendorId: vid,
      productId: pid,
      productName: name,
      chipset: chipset,
      maxBands: chipset.defaultBands,
      isConnected: true,
      isEqEnabled: true,
      globalGainDb: 0.0,
      firmwareVersion: 'v1.0.0 (WebHID)',
    );
  }

  /// Lists already paired devices that have persistent permission in the browser
  static Future<List<DacDevice>> enumerateDevices() async {
    final b = _bridge;
    if (b == null) return [];
    try {
      final promise = b.callMethod('getPairedDevices'.toJS) as JSPromise;
      final jsResult = await promise.toDart;
      if (jsResult == null) return [];
      final list = (jsResult as JSArray).toDart;
      return list.map((item) => _buildDacDevice(item as JSObject)).toList();
    } catch (_) {
      return [];
    }
  }

  /// Requests user permission for a physical USB DAC via native browser prompt
  static Future<DacDevice?> requestDevice() async {
    final b = _bridge;
    if (b == null) return null;
    try {
      final promise = b.callMethod('requestDevice'.toJS) as JSPromise;
      final jsResult = await promise.toDart;
      if (jsResult == null) return null;
      return _buildDacDevice(jsResult as JSObject);
    } catch (_) {
      return null;
    }
  }

  void _initBridge() {
    final b = _bridge;
    if (b == null) return;

    final onInput = ((JSNumber reportIdNum, JSArray jsBytes) {
      final reportId = reportIdNum.toDartInt;
      final rawList = jsBytes.toDart;
      final bytes = Uint8List(rawList.length);
      for (int i = 0; i < rawList.length; i++) {
        bytes[i] = (rawList[i] as JSNumber).toDartInt;
      }
      // Add to broadcast stream with report ID prepended so packet decoder receives standard HID payload
      final fullPacket = Uint8List(bytes.length + 1);
      fullPacket[0] = reportId;
      fullPacket.setRange(1, fullPacket.length, bytes);
      _inputReportController.add(fullPacket);
    }).toJS;

    final onDisc = (() {
      _isConnected = false;
      _device = null;
      _onDisconnected?.call();
    }).toJS;

    _unregisterInput = b.callMethod('registerInputReportCallback'.toJS, onInput) as JSFunction?;
    _unregisterDisconnect = b.callMethod('registerDisconnectCallback'.toJS, onDisc) as JSFunction?;
  }

  @override
  DacDevice? get currentDevice => _isConnected ? _device : null;

  @override
  bool get isConnected => _isConnected && _device != null;

  @override
  void setOnDisconnectListener(void Function() onDisconnected) {
    _onDisconnected = onDisconnected;
  }

  @override
  Future<DacDevice?> connect({DacDevice? specificDevice}) async {
    final b = _bridge;
    if (b == null) return null;

    try {
      JSPromise promise;
      if (specificDevice != null) {
        promise = b.callMethod(
          'connect'.toJS,
          specificDevice.vendorId.toJS,
          specificDevice.productId.toJS,
        ) as JSPromise;
      } else {
        promise = b.callMethod('connect'.toJS) as JSPromise;
      }

      final jsResult = await promise.toDart;
      if (jsResult == null) {
        _isConnected = false;
        _device = null;
        return null;
      }

      _device = _buildDacDevice(jsResult as JSObject);
      _isConnected = true;
      return _device;
    } catch (_) {
      _isConnected = false;
      _device = null;
      return null;
    }
  }

  @override
  Future<void> disconnect() async {
    _unregisterInput?.callAsFunction();
    _unregisterDisconnect?.callAsFunction();
    _unregisterInput = null;
    _unregisterDisconnect = null;

    final b = _bridge;
    if (b != null) {
      try {
        final promise = b.callMethod('disconnect'.toJS) as JSPromise;
        await promise.toDart;
      } catch (_) {}
    }
    _isConnected = false;
    _device = null;
    _onDisconnected?.call();
  }

  @override
  Future<void> sendOutputReport(int reportId, Uint8List data) async {
    final b = _bridge;
    if (b == null || !_isConnected) {
      throw StateError('Physical USB DAC is not connected');
    }

    final jsArray = [for (final byte in data) byte.toJS].toJS;
    final promise = b.callMethod('sendReport'.toJS, reportId.toJS, jsArray) as JSPromise;
    await promise.toDart;
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
    if (!_isConnected) {
      throw StateError('Physical USB DAC is not connected');
    }

    final completer = Completer<Uint8List>();
    late final StreamSubscription<Uint8List> sub;

    sub = _inputReportController.stream.listen((bytes) {
      if (bytes.length > 1) {
        final payload = bytes.sublist(1);
        // Match register byte if payload is large enough
        if (data.isNotEmpty && payload.isNotEmpty && payload[0] == data[0]) {
          if (!completer.isCompleted) {
            completer.complete(payload);
          }
        }
      }
    });

    try {
      await sendOutputReport(reportId, data);
      final response = await completer.future.timeout(timeout);
      return response;
    } on TimeoutException {
      final reg = data.isNotEmpty ? data[0] : 0xFF;
      throw TimeoutException('DAC response timed out on register 0x${reg.toRadixString(16)}');
    } finally {
      await sub.cancel();
    }
  }

  @override
  StreamSubscription<Uint8List> listenInputReports(DacInputReportCallback onData) {
    return _inputReportController.stream.listen((bytes) {
      if (bytes.isNotEmpty) {
        final reportId = bytes[0];
        final payload = bytes.length > 1 ? bytes.sublist(1) : Uint8List(0);
        onData(payload, reportId);
      }
    });
  }
}
