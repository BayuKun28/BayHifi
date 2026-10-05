import 'dart:async';
import 'dart:typed_data';
import '../../domain/models/dac_device.dart';
import '../protocols/dac_packet_encoder.dart';
import 'dac_transport.dart';

/// Simulated USB DAC Transport for unit testing and offline development.
/// Emulates the internal register bank and EEPROM flash of a Kiwi Ears AD1 (KT0211L).
class MockDacTransport implements DacTransport {
  MockDacTransport({
    DacDevice? mockDevice,
    bool autoConnect = true,
  }) : _device = mockDevice ??
            const DacDevice(
              id: 'mock_usb_kiwi_ad1',
              vendorId: 0x31B2,
              productId: 0x0111,
              productName: 'Kiwi Ears AD1 (Simulated)',
              chipset: DacChipset.kt0211l,
              maxBands: 5,
              isConnected: true,
              isEqEnabled: true,
              globalGainDb: 0.0,
              firmwareVersion: 'v1.0.4',
            ) {
    _isConnected = autoConnect;
    _initializeDefaultRegisters();
  }

  DacDevice? _device;
  bool _isConnected = false;
  void Function()? _onDisconnect;
  final _inputReportController = StreamController<Uint8List>.broadcast();

  // Emulated 256-byte RAM registers and EEPROM flash
  final Map<int, Uint8List> _ramRegisters = {};
  final Map<int, Uint8List> _eepromRegisters = {};

  void _initializeDefaultRegisters() {
    const encoder = DacPacketEncoder();

    // Default Enable Register (0x24): 1 (Active)
    _ramRegisters[Kt0211Registers.allEnable] =
        encoder.encodeKtWriteEnable(registerAddress: Kt0211Registers.allEnable, enabled: true);

    // Default 5 Kiwi Ears factory bands
    final defaultFrequencies = [28.0, 84.0, 680.0, 4300.0, 14500.0];
    for (int i = 0; i < 5; i++) {
      final freqReg = Kt0211Registers.freqRegForBand(i);
      final qReg = Kt0211Registers.qRegForBand(i);

      _ramRegisters[freqReg] = encoder.encodeKtWriteFreqGain(
        registerAddress: freqReg,
        frequencyHz: defaultFrequencies[i],
        gainDb: 0.0,
      );

      _ramRegisters[qReg] = encoder.encodeKtWriteQ(
        registerAddress: qReg,
        qFactor: 0.70,
      );
    }

    // Default Global Gain (0x3B): 0.0 dB
    _ramRegisters[Kt0211Registers.dacVol] = encoder.encodeKtWriteGlobalGain(
      registerAddress: Kt0211Registers.dacVol,
      gainDb: 0.0,
    );

    // Copy initial RAM to EEPROM
    _ramRegisters.forEach((k, v) {
      _eepromRegisters[k] = Uint8List.fromList(v);
    });
  }

  @override
  DacDevice? get currentDevice => _isConnected ? _device : null;

  @override
  bool get isConnected => _isConnected;

  @override
  Future<DacDevice?> connect({DacDevice? specificDevice}) async {
    _isConnected = true;
    _device = specificDevice ?? _device;
    return _device;
  }

  @override
  Future<void> disconnect() async {
    _isConnected = false;
    _onDisconnect?.call();
  }

  @override
  Future<void> sendOutputReport(int reportId, Uint8List data) async {
    if (!_isConnected) throw StateError('Mock DAC is disconnected');
    _processPacket(data);
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
    if (!_isConnected) throw StateError('Mock DAC is disconnected');
    final response = _processPacket(data);
    return response;
  }

  Uint8List _processPacket(Uint8List packet) {
    if (packet.length < 5) return packet;

    final reg = packet[0];
    final cmd = packet[4];

    if (cmd == KtCommands.writeReg) { // 0x57 ('W')
      // Save 4 payload bytes into RAM register
      final entry = Uint8List(10);
      entry.setRange(0, 10, packet);
      _ramRegisters[reg] = entry;

      // Echo back with FLAG_OK in byte 6
      final ack = Uint8List.fromList(packet);
      ack[6] = KtCommands.flagOkKt0211;
      _inputReportController.add(ack);
      return ack;
    } else if (cmd == KtCommands.readReg) { // 0x52 ('R')
      final stored = _ramRegisters[reg] ?? Uint8List(10);
      final response = Uint8List.fromList(stored);
      response[0] = reg;
      response[4] = KtCommands.readReg;
      _inputReportController.add(response);
      return response;
    } else if (cmd == KtCommands.saveReg) { // 0x53 ('S')
      _ramRegisters.forEach((k, v) {
        _eepromRegisters[k] = Uint8List.fromList(v);
      });
      final ack = Uint8List(10);
      ack[4] = KtCommands.saveReg;
      ack[6] = KtCommands.flagOkKt0211;
      _inputReportController.add(ack);
      return ack;
    } else if (cmd == KtCommands.clearReg) { // 0x43 ('C')
      _initializeDefaultRegisters();
      final ack = Uint8List(10);
      ack[4] = KtCommands.clearReg;
      ack[6] = KtCommands.flagOkKt0211;
      _inputReportController.add(ack);
      return ack;
    }

    return packet;
  }

  @override
  StreamSubscription<Uint8List> listenInputReports(DacInputReportCallback onData) {
    return _inputReportController.stream.listen((data) {
      onData(data, 0x4B);
    });
  }

  @override
  void setOnDisconnectListener(void Function() onDisconnected) {
    _onDisconnect = onDisconnected;
  }

  void dispose() {
    _inputReportController.close();
  }
}
