import 'dart:async';
import 'dart:typed_data';
import '../../domain/models/dac_device.dart';

/// Callback type for incoming USB HID input reports.
typedef DacInputReportCallback = void Function(Uint8List data, int reportId);

/// Callback type for device connection status changes.
typedef DacConnectionChangeCallback = void Function(bool isConnected);

/// Abstract transport interface for communicating with USB DAC hardware over HID.
abstract class DacTransport {
  /// Currently connected device metadata, or null if disconnected.
  DacDevice? get currentDevice;

  /// Whether the transport is actively connected to a hardware device.
  bool get isConnected;

  /// Scans and connects to an authorized USB DAC matching supported VIDs/PIDs.
  Future<DacDevice?> connect({DacDevice? specificDevice});

  /// Disconnects and releases the USB interface.
  Future<void> disconnect();

  /// Sends a raw output report packet to the DAC's HID endpoint.
  Future<void> sendOutputReport(int reportId, Uint8List data);

  /// Sends a raw output report and awaits the corresponding response matching target register and command.
  Future<Uint8List> sendCommandWithResponse(
    int reportId,
    Uint8List data, {
    Duration timeout = const Duration(seconds: 4),
    bool verifyFlag = false,
    int flagIndex = 6,
    int expectedFlag = 0x03,
  });

  /// Subscribes to incoming asynchronous input reports from the DAC.
  StreamSubscription<Uint8List> listenInputReports(DacInputReportCallback onData);

  /// Sets a callback for unexpected disconnection events.
  void setOnDisconnectListener(void Function() onDisconnected);
}
