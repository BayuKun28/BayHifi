import 'dart:typed_data';
import '../../domain/models/dac_band_config.dart';

/// Commands for KTmicro chipset family (KT_0211L, KT_1132L, KT_3016L).
abstract final class KtCommands {
  static const int writeReg = 0x57; // 87 ('W')
  static const int readReg = 0x52;  // 82 ('R')
  static const int saveReg = 0x53;  // 83 ('S')
  static const int clearReg = 0x43; // 67 ('C')
  static const int flagOkKt0211 = 0x03;
  static const int flagOkKt1132 = 0x4F; // 79 ('O')
}

/// Register definitions for KTmicro KT0211L (Kiwi Ears AD1).
abstract final class Kt0211Registers {
  static const int allEnable = 0x24; // 36
  static const int band0Freq = 0x26;  // 38
  static const int band0Q = 0x27;     // 39
  static const int band1Freq = 0x28;  // 40
  static const int band1Q = 0x29;     // 41
  static const int band2Freq = 0x2A;  // 42
  static const int band2Q = 0x2B;     // 43
  static const int band3Freq = 0x2C;  // 44
  static const int band3Q = 0x2D;     // 45
  static const int band4Freq = 0x2E;  // 46
  static const int band4Q = 0x2F;     // 47
  static const int dacVol = 0x3B;     // 59

  static int freqRegForBand(int bandIndex) => band0Freq + (bandIndex * 2);
  static int qRegForBand(int bandIndex) => band0Q + (bandIndex * 2);
}

/// Commands for CB Series DACs (CB-5000X, CB-3000S).
abstract final class CbCommands {
  static const int configWrite = 0xC1; // 193
  static const int configRead = 0xC2;  // 194
  static const int batchWrite = 0xC3;  // 195
  static const int presetSave = 0xC4;  // 196
  static const int presetLoad = 0xC5;  // 197
  static const int statusQuery = 0xC6; // 198
  static const int flagOk = 0xAA;      // 170
}

/// Assembles fixed-length binary HID report packets for USB DACs.
class DacPacketEncoder {
  const DacPacketEncoder();

  // ---------------------------------------------------------------------------
  // KTmicro Encoding (10-Byte Packets)
  // ---------------------------------------------------------------------------

  /// Encodes a 10-byte packet to write Frequency and Gain to a KTmicro band register.
  /// Formula:
  ///   Freq LE = round(freqHz * 10) (Uint16)
  ///   Gain LE = round(gainDb * 10) (Int16 signed)
  Uint8List encodeKtWriteFreqGain({
    required int registerAddress,
    required double frequencyHz,
    required double gainDb,
  }) {
    final packet = Uint8List(10);
    packet[0] = registerAddress & 0xFF;
    packet[1] = 0x00;
    packet[2] = 0x00;
    packet[3] = 0x00;
    packet[4] = KtCommands.writeReg; // 0x57
    packet[5] = 0x00;

    // Gain * 10 (Int16 Little-Endian, signed two's complement in bytes 6..7)
    final gainInt = (gainDb * 10).round().clamp(-120, 120);
    final gainUint16 = gainInt < 0 ? (65536 + gainInt) : gainInt;
    packet[6] = gainUint16 & 0xFF;
    packet[7] = (gainUint16 >> 8) & 0xFF;

    // Freq in direct Hz (Uint16 Little-Endian in bytes 8..9)
    final freqInt = frequencyHz.round().clamp(20, 20000);
    packet[8] = freqInt & 0xFF;
    packet[9] = (freqInt >> 8) & 0xFF;

    return packet;
  }

  /// Encodes a 10-byte packet to write Q-Factor to a KTmicro band register.
  /// Formula: Q LE = round(Q * 1000) (Uint16)
  Uint8List encodeKtWriteQ({
    required int registerAddress,
    required double qFactor,
  }) {
    final packet = Uint8List(10);
    packet[0] = registerAddress & 0xFF;
    packet[1] = 0x00;
    packet[2] = 0x00;
    packet[3] = 0x00;
    packet[4] = KtCommands.writeReg; // 0x57
    packet[5] = 0x00;

    // Q * 1000 (Uint16 Little-Endian)
    final qInt = (qFactor * 1000).round().clamp(100, 10000);
    packet[6] = qInt & 0xFF;
    packet[7] = (qInt >> 8) & 0xFF;
    packet[8] = 0x00;
    packet[9] = 0x00;

    return packet;
  }

  /// Encodes a 10-byte packet to enable or bypass Hardware EQ on KTmicro DACs.
  Uint8List encodeKtWriteEnable({
    required int registerAddress,
    required bool enabled,
  }) {
    final packet = Uint8List(10);
    packet[0] = registerAddress & 0xFF;
    packet[1] = 0x00;
    packet[2] = 0x00;
    packet[3] = 0x00;
    packet[4] = KtCommands.writeReg;
    packet[5] = 0x00;

    // 32-bit uint: 1 for active, 0 for bypass
    packet[6] = enabled ? 0x01 : 0x00;
    packet[7] = 0x00;
    packet[8] = 0x00;
    packet[9] = 0x00;

    return packet;
  }

  /// Encodes a 10-byte packet to save active RAM registers to non-volatile EEPROM/Flash.
  Uint8List encodeKtSaveFlash() {
    final packet = Uint8List(10);
    packet[0] = 0x00;
    packet[1] = 0x00;
    packet[2] = 0x00;
    packet[3] = 0x00;
    packet[4] = KtCommands.saveReg; // 0x53 ('S')
    packet[5] = 0x00;
    packet[6] = 0x00;
    packet[7] = 0x00;
    packet[8] = 0x00;
    packet[9] = 0x00;
    return packet;
  }

  /// Encodes a 10-byte packet to reset/clear EEPROM flash to factory defaults.
  Uint8List encodeKtClearFlash() {
    final packet = Uint8List(10);
    packet[0] = 0x00;
    packet[1] = 0x00;
    packet[2] = 0x00;
    packet[3] = 0x00;
    packet[4] = KtCommands.clearReg; // 0x43 ('C')
    packet[5] = 0x00;
    packet[6] = 0x00;
    packet[7] = 0x00;
    packet[8] = 0x00;
    packet[9] = 0x00;
    return packet;
  }

  /// Encodes a 10-byte packet to read a register from the KTmicro DAC.
  Uint8List encodeKtReadRegister(int registerAddress) {
    final packet = Uint8List(10);
    packet[0] = registerAddress & 0xFF;
    packet[1] = 0x00;
    packet[2] = 0x00;
    packet[3] = 0x00;
    packet[4] = KtCommands.readReg; // 0x52 ('R')
    packet[5] = 0x00;
    packet[6] = 0x00;
    packet[7] = 0x00;
    packet[8] = 0x00;
    packet[9] = 0x00;
    return packet;
  }

  /// Encodes a 10-byte packet to write Global Master Preamp Gain to register 0x3B.
  /// Formula for KT02H20 / KT0211L:
  ///   Gain LE = round(gainDb * 20) (signed Int16 in 0.05 dB steps, e.g. -3.0 dB -> -60 -> 0xFFC4)
  Uint8List encodeKtWriteGlobalGain({
    required int registerAddress,
    required double gainDb,
  }) {
    final packet = Uint8List(10);
    packet[0] = registerAddress & 0xFF;
    packet[1] = 0x00;
    packet[2] = 0x00;
    packet[3] = 0x00;
    packet[4] = KtCommands.writeReg; // 0x57 ('W')
    packet[5] = 0x00;

    // Gain in 0.05 dB steps (gainDb * 20, signed Int16 Little-Endian)
    final gainInt = (gainDb * 20).round().clamp(-360, 60);
    final gainUint16 = gainInt < 0 ? (65536 + gainInt) : gainInt;
    packet[6] = gainUint16 & 0xFF;
    packet[7] = (gainUint16 >> 8) & 0xFF;
    packet[8] = 0x00;
    packet[9] = 0x00;

    return packet;
  }

  // ---------------------------------------------------------------------------
  // CB Series Encoding (11-Byte Packets)
  // ---------------------------------------------------------------------------

  /// Encodes a packet to configure a band on a CB-Series DAC.
  Uint8List encodeCbWriteBand({
    required int registerAddress,
    required double frequencyHz,
    required double gainDb,
    required double qFactor,
  }) {
    final packet = Uint8List(11);
    packet[0] = CbCommands.configWrite;
    packet[1] = registerAddress & 0xFF;
    final freqInt = frequencyHz.round().clamp(20, 20000);
    packet[2] = (freqInt >> 8) & 0xFF; // Freq High
    packet[3] = freqInt & 0xFF;        // Freq Low
    packet[4] = gainDb.round().clamp(-12, 12) & 0xFF;
    packet[5] = (qFactor * 10).round().clamp(1, 100) & 0xFF;
    return packet;
  }

  /// Encodes a packet to set the filter shape type on a CB-Series DAC.
  Uint8List encodeCbWriteFilterType({
    required int registerAddress,
    required DacFilterType filterType,
  }) {
    final packet = Uint8List(11);
    packet[0] = CbCommands.configWrite;
    packet[1] = registerAddress & 0xFF;
    packet[2] = filterType.code & 0xFF;
    return packet;
  }

  /// Encodes a packet to save presets on a CB-Series DAC.
  Uint8List encodeCbSaveFlash() {
    final packet = Uint8List(11);
    packet[0] = CbCommands.presetSave;
    return packet;
  }
}
