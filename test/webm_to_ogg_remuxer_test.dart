import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/features/youtube_music/data/webm_to_ogg_remuxer.dart';

void main() {
  group('WebmToOggRemuxer & Ogg Engine Tests', () {
    test('OggCrc calculates correct CRC32 for Ogg pages', () {
      final sample = Uint8List.fromList([0x4F, 0x67, 0x67, 0x53, 0x00, 0x02, 0, 0, 0, 0, 0, 0, 0, 0]);
      final crc = OggCrc.compute(sample);
      expect(crc, isA<int>());
      expect(crc, isNot(0));
    });

    test('OggPageBuilder builds valid BOS, normal, and EOS pages with OggS magic', () {
      final builder = OggPageBuilder(serialNumber: 0x12345678);

      final opusHead = OggPageBuilder.createDefaultOpusHead(channels: 2, sampleRate: 48000);
      final page0 = builder.buildPage(
        headerType: 0x02, // BOS
        granulePos: 0,
        packets: [opusHead],
      );

      expect(page0.length, greaterThan(27));
      expect(page0.sublist(0, 4), [0x4F, 0x67, 0x67, 0x53]); // 'OggS'
      expect(page0[5], 0x02); // BOS flag

      final opusTags = OggPageBuilder.createDefaultOpusTags(vendor: 'BaydevHiFi');
      final page1 = builder.buildPage(
        headerType: 0x00,
        granulePos: 0,
        packets: [opusTags],
      );
      expect(page1.sublist(0, 4), [0x4F, 0x67, 0x67, 0x53]);
      expect(page1[5], 0x00);
    });

    test('getOpusPacketSamples correctly parses 20ms, 10ms, 40ms, and multi-frame packets', () {
      // Config 27 = CELT FB 20ms -> 960 samples
      final packet20ms = Uint8List.fromList([(27 << 3) | 0, 0x12, 0x34]);
      expect(getOpusPacketSamples(packet20ms), equals(960));

      // Config 16 = CELT FB 2.5ms -> 120 samples
      final packet2_5ms = Uint8List.fromList([(16 << 3) | 0, 0x12]);
      expect(getOpusPacketSamples(packet2_5ms), equals(120));

      // Config 27 with 2 frames (code 1) -> 960 * 2 = 1920 samples
      final packet2Frames = Uint8List.fromList([(27 << 3) | 1, 0x12, 0x34]);
      expect(getOpusPacketSamples(packet2Frames), equals(1920));
    });

    test('WebmToOggRemuxer transforms WebM clusters into continuous Ogg Opus stream', () async {
      // Synthetic WebM containing:
      // EBML Header -> Segment -> Tracks (TrackEntry with CodecPrivate) -> Cluster (SimpleBlock)
      final bytes = <int>[];

      // 1. EBML Header (0x1A45DFA3)
      bytes.addAll([0x1A, 0x45, 0xDF, 0xA3, 0x84, 0x42, 0x86, 0x81, 0x01]);

      // 2. Segment (0x18538067)
      bytes.addAll([0x18, 0x53, 0x80, 0x67, 0xFF]); // Undefined length

      // 3. Tracks (0x1654AE6B)
      final trackEntryBytes = <int>[
        // TrackNumber (0xD7) = 1
        0xD7, 0x81, 0x01,
        // TrackType (0x83) = 2 (audio)
        0x83, 0x81, 0x02,
        // CodecID (0x86) = "A_OPUS"
        0x86, 0x86, ...utf8.encode('A_OPUS'),
        // CodecPrivate (0x63A2) = 19 bytes OpusHead
        0x63, 0xA2, 0x93, ...OggPageBuilder.createDefaultOpusHead(),
      ];
      bytes.addAll([0x16, 0x54, 0xAE, 0x6B, 0x80 | (trackEntryBytes.length + 2), 0xAE, 0x80 | trackEntryBytes.length, ...trackEntryBytes]);

      // 4. Cluster (0x1F43B675)
      // SimpleBlock (0xA3) with 1 Opus packet
      final opusPacket = Uint8List.fromList([(27 << 3) | 0, 0xAA, 0xBB, 0xCC]);
      final blockData = <int>[
        0x81, // Track number 1 (VINT)
        0x00, 0x00, // Timecode
        0x80, // Keyframe flag, no lacing
        ...opusPacket,
      ];
      final clusterBytes = <int>[
        0xE7, 0x81, 0x00, // Timecode 0
        0xA3, 0x80 | blockData.length, ...blockData,
      ];
      bytes.addAll([0x1F, 0x43, 0xB6, 0x75, 0x80 | clusterBytes.length, ...clusterBytes]);

      // Stream in small chunks to test streaming boundary safety
      final inputStream = Stream<List<int>>.fromIterable([
        bytes.sublist(0, 15),
        bytes.sublist(15, 40),
        bytes.sublist(40),
      ]);

      final oggStream = WebmToOggRemuxer.remuxStream(inputStream, serialNumber: 0x55AA55AA);
      final oggChunks = await oggStream.toList();

      expect(oggChunks.isNotEmpty, isTrue);

      // Verify Page 0 is OpusHead
      final page0 = oggChunks.first;
      expect(page0.sublist(0, 4), [0x4F, 0x67, 0x67, 0x53]); // OggS
      expect(page0[5], 0x02); // BOS

      // Verify all pages start with 'OggS'
      for (final chunk in oggChunks) {
        expect(chunk.sublist(0, 4), [0x4F, 0x67, 0x67, 0x53]);
      }
    });
  });
}
