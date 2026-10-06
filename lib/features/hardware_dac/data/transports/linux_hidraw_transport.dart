import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import '../../domain/models/dac_device.dart';
import 'dac_transport.dart';

/// Real Linux Desktop USB HID transport that interfaces directly with `/dev/hidraw*` devices.
class LinuxHidRawTransport implements DacTransport {
  LinuxHidRawTransport({
    this.customDevicePath,
  });

  final String? customDevicePath;

  DacDevice? _device;
  RandomAccessFile? _writeRaf;
  RandomAccessFile? _readRaf;
  final StreamController<Uint8List> _inputReportController =
      StreamController<Uint8List>.broadcast();

  void Function()? _onDisconnected;

  @override
  DacDevice? get currentDevice => _device;

  @override
  bool get isConnected {
    if (_device == null || _writeRaf == null || _readRaf == null) return false;
    final file = File(_device!.id);
    return file.existsSync();
  }

  @override
  void setOnDisconnectListener(void Function() onDisconnected) {
    _onDisconnected = onDisconnected;
  }

  /// Scans Linux `/sys/class/hidraw` to locate supported USB DSP DACs.
  static Future<List<DacDevice>> enumerateDevices() async {
    final devices = <DacDevice>[];
    if (!Platform.isLinux) return devices;

    final hidrawDir = Directory('/sys/class/hidraw');
    if (!hidrawDir.existsSync()) return devices;

    try {
      final entries = hidrawDir.listSync();
      for (final entry in entries) {
        if (entry is Directory) {
          final hidName = entry.path.split('/').last; // e.g. "hidraw3"
          final devPath = '/dev/$hidName';
          final ueventFile = File('${entry.path}/device/uevent');

          if (ueventFile.existsSync()) {
            final content = await ueventFile.readAsString();
            final device = _parseUevent(content, devPath);
            if (device != null) {
              devices.add(device);
            }
          }
        }
      }
    } catch (_) {
      // Gracefully handle permission or filesystem variations
    }
    return devices;
  }

  static DacDevice? _parseUevent(String ueventContent, String devPath) {
    int? vid;
    int? pid;
    String name = 'USB Audio DAC';

    final lines = ueventContent.split('\n');
    for (final line in lines) {
      if (line.startsWith('HID_ID=')) {
        // e.g. HID_ID=0003:00003302:000020E3
        final parts = line.substring(7).split(':');
        if (parts.length >= 3) {
          vid = int.tryParse(parts[1], radix: 16);
          pid = int.tryParse(parts[2], radix: 16);
        }
      } else if (line.startsWith('HID_NAME=')) {
        name = line.substring(9).trim();
      }
    }

    if (vid == null || pid == null) return null;

    // Check known DAC signatures
    DacChipset? chipset;
    if (vid == 0x3302 || vid == 0x31B2) {
      if (pid == 0x12C3) {
        chipset = DacChipset.kt1132l;
      } else {
        chipset = DacChipset.kt0211l;
      }
    } else if (name.toLowerCase().contains('kiwi') ||
        name.toLowerCase().contains('ad1') ||
        name.toLowerCase().contains('allegro')) {
      chipset = DacChipset.kt0211l;
    }

    if (chipset != null) {
      return DacDevice(
        id: devPath,
        vendorId: vid,
        productId: pid,
        productName: name,
        chipset: chipset,
        maxBands: chipset.defaultBands,
      );
    }
    return null;
  }

  @override
  Future<DacDevice?> connect({DacDevice? specificDevice}) async {
    await disconnect();

    if (!Platform.isLinux) return null;

    DacDevice? target = specificDevice;
    if (target == null) {
      final available = await enumerateDevices();
      if (available.isNotEmpty) {
        target = available.first;
      }
    }

    if (target == null) return null;

    try {
      final file = File(target.id);
      if (!file.existsSync()) return null;

      _writeRaf = await file.open(mode: FileMode.append);
      _readRaf = await file.open(mode: FileMode.read);

      _device = target.copyWith(isConnected: true);
      return _device;
    } catch (_) {
      await disconnect();
      return null;
    }
  }

  @override
  Future<void> sendOutputReport(int reportId, Uint8List data) async {
    if (!isConnected || _writeRaf == null) {
      throw StateError('Linux HID transport not connected');
    }

    // Prepend report ID (11 bytes total: [reportId, ...10 data bytes])
    final packet = Uint8List(data.length + 1);
    packet[0] = reportId;
    packet.setRange(1, packet.length, data);

    try {
      await _writeRaf!.writeFrom(packet);
    } catch (e) {
      await disconnect();
      throw StateError('Failed to write to Linux HID transport: $e');
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
    if (!isConnected || _writeRaf == null || _readRaf == null) {
      throw StateError('Linux HID transport not connected');
    }

    final packet = Uint8List(data.length + 1);
    packet[0] = reportId;
    packet.setRange(1, packet.length, data);

    try {
      await _writeRaf!.writeFrom(packet);
    } catch (e) {
      await disconnect();
      throw StateError('Failed to write command to Linux HID transport: $e');
    }

    try {
      final buffer = Uint8List(64);
      final bytesRead = await _readRaf!.readInto(buffer).timeout(timeout);
      if (bytesRead > 0) {
        final rawResponse = Uint8List.fromList(buffer.sublist(0, bytesRead));
        _inputReportController.add(rawResponse);

        // Strip byte 0 (Report ID) to provide clean 10-byte payload to decoder
        if (bytesRead > 1) {
          return Uint8List.fromList(buffer.sublist(1, bytesRead));
        }
        return rawResponse;
      }
      return Uint8List(0);
    } on TimeoutException {
      final reg = data.isNotEmpty ? data[0] : 0xFF;
      throw TimeoutException(
          'DAC response timed out on register 0x${reg.toRadixString(16)}');
    } catch (e) {
      await disconnect();
      rethrow;
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

  @override
  Future<void> disconnect() async {
    final wasConnected = isConnected;
    _device = null;

    try {
      await _writeRaf?.close();
    } catch (_) {}
    _writeRaf = null;

    try {
      await _readRaf?.close();
    } catch (_) {}
    _readRaf = null;

    if (wasConnected) {
      _onDisconnected?.call();
    }
  }
}
