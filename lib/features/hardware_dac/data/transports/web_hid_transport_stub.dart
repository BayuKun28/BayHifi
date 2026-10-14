import 'dart:async';
import 'dart:typed_data';
import '../../domain/models/dac_device.dart';
import 'dac_transport.dart';

/// Stub implementation of WebHidTransport for non-web platforms (Linux, Android, Tests).
class WebHidTransport implements DacTransport {
  WebHidTransport();

  static bool get isSupported => false;

  static Future<List<DacDevice>> enumerateDevices() async {
    return [];
  }

  static Future<DacDevice?> requestDevice() async {
    return null;
  }

  @override
  DacDevice? get currentDevice => null;

  @override
  bool get isConnected => false;

  @override
  Future<DacDevice?> connect({DacDevice? specificDevice}) async {
    throw UnsupportedError('WebHID is only supported in web browsers.');
  }

  @override
  Future<void> disconnect() async {}

  @override
  Future<void> sendOutputReport(int reportId, Uint8List data) async {
    throw UnsupportedError('WebHID is only supported in web browsers.');
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
    throw UnsupportedError('WebHID is only supported in web browsers.');
  }

  @override
  StreamSubscription<Uint8List> listenInputReports(DacInputReportCallback onData) {
    return const Stream<Uint8List>.empty().listen((_) {});
  }

  @override
  void setOnDisconnectListener(void Function() onDisconnected) {}
}
