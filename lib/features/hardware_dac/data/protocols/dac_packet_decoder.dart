import 'dart:typed_data';
import 'dac_packet_encoder.dart';

/// Decodes binary response buffers received from USB DSP DACs.
class DacPacketDecoder {
  const DacPacketDecoder();

  // ---------------------------------------------------------------------------
  // KTmicro Decoders
  // ---------------------------------------------------------------------------

  /// Parses a 10-byte frequency & gain register response from KTmicro.
  /// Byte layout:
  ///   Byte 6..7 : Little-endian Int16 representing Gain * 10
  ///   Byte 8..9 : Little-endian UInt16 representing Frequency in direct Hz
  Map<String, double>? parseKtFrequencyGainResponse(Uint8List response) {
    if (response.length < 10) return null;

    final gainLow = response[6];
    final gainHigh = response[7];
    var rawGain = (gainHigh << 8) | gainLow;
    if (rawGain > 32767) {
      rawGain -= 65536; // Convert two's complement to negative
    }
    final gainDb = rawGain / 10.0;

    final freqLow = response[8];
    final freqHigh = response[9];
    final rawFreq = (freqHigh << 8) | freqLow;
    final frequencyHz = rawFreq.toDouble();

    return {
      'frequency': frequencyHz.clamp(20.0, 20000.0),
      'gainDb': gainDb.clamp(-12.0, 12.0),
    };
  }

  /// Parses a 10-byte Q-factor register response from KTmicro.
  /// Byte layout:
  ///   Byte 6..7 : Little-endian UInt16 representing Q * 1000
  double? parseKtQResponse(Uint8List response) {
    if (response.length < 8) return null;

    final qLow = response[6];
    final qHigh = response[7];
    final rawQ = (qHigh << 8) | qLow;
    final qVal = rawQ / 1000.0;

    return qVal.clamp(0.10, 10.00);
  }

  /// Parses a 10-byte hardware EQ enable/bypass register response.
  bool? parseKtEnableResponse(Uint8List response) {
    if (response.length < 10) return null;

    final byte6 = response[6];
    final byte7 = response[7];
    final byte8 = response[8];
    final byte9 = response[9];
    final rawVal = (byte9 << 24) | (byte8 << 16) | (byte7 << 8) | byte6;

    return rawVal != 0;
  }

  /// Parses a 10-byte global gain register response (register 0x3B, `DacAnaGain_ALL`).
  ///
  /// Format:
  ///   Byte 6..9: Little-Endian 32-bit uint holding 4-bit step index (bits 0..3: 0..15).
  ///   Step index 13 represents 0.0 dB (Unity gain), with 1.5 dB per step.
  double? parseKtGlobalGainResponse(Uint8List response) {
    if (response.length < 7) return null;

    final byte6 = response[6];
    final byte7 = response.length > 7 ? response[7] : 0;
    final byte8 = response.length > 8 ? response[8] : 0;
    final byte9 = response.length > 9 ? response[9] : 0;
    final rawVal = (byte9 << 24) | (byte8 << 16) | (byte7 << 8) | byte6;
    final stepIndex = rawVal & 0x0F;

    return DacPacketEncoder.ktStepIndexToGainDb(stepIndex);
  }

  /// Verifies acknowledgment or status flag in response buffer.
  bool verifyKtSuccessFlag(
    Uint8List response, {
    int expectedFlag = KtCommands.flagOkKt0211,
    int flagIndex = 6,
  }) {
    if (response.length <= flagIndex) return false;
    return response[flagIndex] == expectedFlag;
  }

  // ---------------------------------------------------------------------------
  // CB-Series Decoders
  // ---------------------------------------------------------------------------

  /// Parses a CB-Series band configuration response.
  Map<String, dynamic>? parseCbBandResponse(Uint8List response) {
    if (response.length < 6) return null;

    final freqHigh = response[2];
    final freqLow = response[3];
    final freqHz = ((freqHigh << 8) | freqLow).toDouble();

    final rawGain = response[4];
    final gainDb = (rawGain > 127 ? rawGain - 256 : rawGain).toDouble();

    final rawQ = response[5];
    final qVal = rawQ / 10.0;

    return {
      'frequency': freqHz.clamp(20.0, 20000.0),
      'gainDb': gainDb.clamp(-12.0, 12.0),
      'qFactor': qVal.clamp(0.10, 10.00),
    };
  }
}
