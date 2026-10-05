import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/features/hardware_dac/data/protocols/dac_packet_encoder.dart';
import 'package:baydev_hifi/features/hardware_dac/data/protocols/dac_packet_decoder.dart';

void main() {
  group('DacPacketEncoder & DacPacketDecoder Tests', () {
    const encoder = DacPacketEncoder();
    const decoder = DacPacketDecoder();

    test('Encodes and decodes positive Frequency and Gain correctly', () {
      // Frequency: 80 Hz -> 80 (0x0050) -> Low: 0x50, High: 0x00 in bytes 8..9
      // Gain: +3.5 dB -> 35 (0x0023) -> Low: 0x23, High: 0x00 in bytes 6..7
      final packet = encoder.encodeKtWriteFreqGain(
        registerAddress: Kt0211Registers.band0Freq,
        frequencyHz: 80.0,
        gainDb: 3.5,
      );

      expect(packet.length, equals(10));
      expect(packet[0], equals(0x26)); // Reg address
      expect(packet[4], equals(KtCommands.writeReg)); // 0x57 ('W')
      expect(packet[6], equals(0x23)); // Gain Low
      expect(packet[7], equals(0x00)); // Gain High
      expect(packet[8], equals(0x50)); // Freq Low
      expect(packet[9], equals(0x00)); // Freq High

      final decoded = decoder.parseKtFrequencyGainResponse(packet);
      expect(decoded, isNotNull);
      expect(decoded!['frequency'], closeTo(80.0, 0.01));
      expect(decoded['gainDb'], closeTo(3.5, 0.01));
    });

    test('Encodes and decodes negative Gain correctly (two complement)', () {
      // Frequency: 4500 Hz -> 4500 (0x1194) -> Low: 0x94, High: 0x11 in bytes 8..9
      // Gain: -2.5 dB -> -25 (65536 - 25 = 65511 = 0xFFE7) -> Low: 0xE7, High: 0xFF in bytes 6..7
      final packet = encoder.encodeKtWriteFreqGain(
        registerAddress: Kt0211Registers.band3Freq,
        frequencyHz: 4500.0,
        gainDb: -2.5,
      );

      expect(packet[0], equals(0x2C));
      expect(packet[6], equals(0xE7));
      expect(packet[7], equals(0xFF));
      expect(packet[8], equals(0x94));
      expect(packet[9], equals(0x11));

      final decoded = decoder.parseKtFrequencyGainResponse(packet);
      expect(decoded, isNotNull);
      expect(decoded!['frequency'], closeTo(4500.0, 0.01));
      expect(decoded['gainDb'], closeTo(-2.5, 0.01));
    });

    test('Encodes and decodes Q-Factor correctly', () {
      // Q: 0.707 -> 707 (0x02C3) -> Low: 0xC3, High: 0x02
      final packet = encoder.encodeKtWriteQ(
        registerAddress: Kt0211Registers.band0Q,
        qFactor: 0.707,
      );

      expect(packet.length, equals(10));
      expect(packet[0], equals(0x27));
      expect(packet[4], equals(KtCommands.writeReg));
      expect(packet[6], equals(0xC3));
      expect(packet[7], equals(0x02));

      final decodedQ = decoder.parseKtQResponse(packet);
      expect(decodedQ, isNotNull);
      expect(decodedQ, closeTo(0.707, 0.001));
    });

    test('Encodes and decodes Enable / Bypass state correctly', () {
      final activePacket = encoder.encodeKtWriteEnable(
        registerAddress: Kt0211Registers.allEnable,
        enabled: true,
      );
      expect(activePacket[0], equals(0x24));
      expect(activePacket[6], equals(0x01));
      expect(decoder.parseKtEnableResponse(activePacket), isTrue);

      final bypassPacket = encoder.encodeKtWriteEnable(
        registerAddress: Kt0211Registers.allEnable,
        enabled: false,
      );
      expect(bypassPacket[6], equals(0x00));
      expect(decoder.parseKtEnableResponse(bypassPacket), isFalse);
    });

    test('Encodes Save to Flash and Clear Flash packets correctly', () {
      final savePacket = encoder.encodeKtSaveFlash();
      expect(savePacket.length, equals(10));
      expect(savePacket[4], equals(0x53)); // 'S'

      final clearPacket = encoder.encodeKtClearFlash();
      expect(clearPacket.length, equals(10));
      expect(clearPacket[4], equals(0x43)); // 'C'
    });

    test('Encodes and decodes Global Gain correctly', () {
      // Gain: -3.0 dB -> raw = -3.0 * 20 = -60 (65536 - 60 = 65476 = 0xFFC4) -> Low: 0xC4, High: 0xFF
      final packet = encoder.encodeKtWriteGlobalGain(
        registerAddress: Kt0211Registers.dacVol,
        gainDb: -3.0,
      );

      expect(packet[0], equals(0x3B));
      expect(packet[6], equals(0xC4));
      expect(packet[7], equals(0xFF));

      final decodedGain = decoder.parseKtGlobalGainResponse(packet);
      expect(decodedGain, isNotNull);
      expect(decodedGain, closeTo(-3.0, 0.01));
    });

    test('Verifies Success Flag correctly', () {
      final okResponse = Uint8List.fromList([0x26, 0, 0, 0, 0x57, 0, 0x03, 0, 0, 0]);
      expect(decoder.verifyKtSuccessFlag(okResponse), isTrue);

      final failedResponse = Uint8List.fromList([0x26, 0, 0, 0, 0x57, 0, 0x00, 0, 0, 0]);
      expect(decoder.verifyKtSuccessFlag(failedResponse), isFalse);
    });
  });
}
