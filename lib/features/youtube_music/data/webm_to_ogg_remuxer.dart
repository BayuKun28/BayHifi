import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

/// Ogg CRC32 table calculator according to RFC 3533 / RFC 7845.
class OggCrc {
  static final List<int> _table = () {
    final t = List<int>.filled(256, 0);
    for (int i = 0; i < 256; i++) {
      int r = i << 24;
      for (int j = 0; j < 8; j++) {
        if ((r & 0x80000000) != 0) {
          r = ((r << 1) ^ 0x04c11db7) & 0xFFFFFFFF;
        } else {
          r = (r << 1) & 0xFFFFFFFF;
        }
      }
      t[i] = r;
    }
    return t;
  }();

  static int compute(Uint8List data, [int initialCrc = 0]) {
    int crc = initialCrc;
    for (int i = 0; i < data.length; i++) {
      final byte = data[i];
      final idx = ((crc >> 24) ^ byte) & 0xFF;
      crc = ((crc << 8) ^ _table[idx]) & 0xFFFFFFFF;
    }
    return crc;
  }
}

/// Helper for constructing standard Ogg pages.
class OggPageBuilder {
  final int serialNumber;
  int _sequenceNumber = 0;
  final int _granulePos = 0;

  OggPageBuilder({int? serialNumber})
      : serialNumber = serialNumber ?? math.Random().nextInt(0x7FFFFFFF) + 1;

  int get sequenceNumber => _sequenceNumber;
  int get granulePos => _granulePos;

  Uint8List buildPage({
    required int headerType,
    required int granulePos,
    required List<Uint8List> packets,
  }) {
    final segmentTable = <int>[];
    int totalPayloadSize = 0;
    for (final pkt in packets) {
      int len = pkt.length;
      totalPayloadSize += len;
      while (len >= 255) {
        segmentTable.add(255);
        len -= 255;
      }
      segmentTable.add(len);
    }

    final pageLength = 27 + segmentTable.length + totalPayloadSize;
    final page = Uint8List(pageLength);
    final bdata = ByteData.sublistView(page);

    // 0..3: 'OggS'
    page[0] = 0x4F;
    page[1] = 0x67;
    page[2] = 0x67;
    page[3] = 0x53;
    // 4: Stream structure version 0
    page[4] = 0;
    // 5: Header type flag (0x02 = BOS, 0x04 = EOS, 0x00 = normal)
    page[5] = headerType;

    // 6..13: Granule position (64-bit unsigned int little-endian)
    bdata.setUint32(6, granulePos & 0xFFFFFFFF, Endian.little);
    bdata.setUint32(10, (granulePos >> 32) & 0xFFFFFFFF, Endian.little);

    // 14..17: Serial number
    bdata.setUint32(14, serialNumber, Endian.little);

    // 18..21: Page sequence number
    bdata.setUint32(18, _sequenceNumber++, Endian.little);

    // 22..25: CRC Checksum (initially 0)
    bdata.setUint32(22, 0, Endian.little);

    // 26: Page segments count
    page[26] = segmentTable.length;
    for (int i = 0; i < segmentTable.length; i++) {
      page[27 + i] = segmentTable[i];
    }

    // 27+segments: Payloads
    int offset = 27 + segmentTable.length;
    for (final pkt in packets) {
      page.setRange(offset, offset + pkt.length, pkt);
      offset += pkt.length;
    }

    // Calculate & write CRC32
    final crc = OggCrc.compute(page);
    bdata.setUint32(22, crc, Endian.little);

    return page;
  }

  static Uint8List createDefaultOpusHead({
    int channels = 2,
    int preSkip = 312,
    int sampleRate = 48000,
    int outputGain = 0,
  }) {
    final head = Uint8List(19);
    // 'OpusHead'
    head.setRange(0, 8, [0x4F, 0x70, 0x75, 0x73, 0x48, 0x65, 0x61, 0x64]);
    head[8] = 1; // Version
    head[9] = channels;
    final bdata = ByteData.sublistView(head);
    bdata.setUint16(10, preSkip, Endian.little);
    bdata.setUint32(12, sampleRate, Endian.little);
    bdata.setUint16(16, outputGain, Endian.little);
    head[18] = 0; // Channel mapping family 0 (mono/stereo)
    return head;
  }

  static Uint8List createDefaultOpusTags({String vendor = 'BaydevHiFi'}) {
    final vendorBytes = utf8.encode(vendor);
    final length = 8 + 4 + vendorBytes.length + 4;
    final tags = Uint8List(length);
    // 'OpusTags'
    tags.setRange(0, 8, [0x4F, 0x70, 0x75, 0x73, 0x54, 0x61, 0x67, 0x73]);
    final bdata = ByteData.sublistView(tags);
    bdata.setUint32(8, vendorBytes.length, Endian.little);
    tags.setRange(12, 12 + vendorBytes.length, vendorBytes);
    bdata.setUint32(12 + vendorBytes.length, 0, Endian.little); // 0 user comments
    return tags;
  }
}

/// Calculate Opus frame duration in samples at 48kHz from the packet TOC byte (RFC 6716).
int getOpusPacketSamples(Uint8List packet) {
  if (packet.isEmpty) return 960;
  final toc = packet[0];
  final config = (toc >> 3) & 0x1F;
  final frameCountCode = toc & 0x03;

  int samplesPerFrame;
  if (config >= 16) {
    // CELT modes
    switch (config % 4) {
      case 0:
        samplesPerFrame = 120; // 2.5 ms
        break;
      case 1:
        samplesPerFrame = 240; // 5 ms
        break;
      case 2:
        samplesPerFrame = 480; // 10 ms
        break;
      case 3:
      default:
        samplesPerFrame = 960; // 20 ms
        break;
    }
  } else if (config >= 12) {
    // Hybrid modes
    samplesPerFrame = (config & 1) == 0 ? 480 : 960;
  } else {
    // SILK modes
    switch (config % 4) {
      case 0:
        samplesPerFrame = 480; // 10 ms
        break;
      case 1:
        samplesPerFrame = 960; // 20 ms
        break;
      case 2:
        samplesPerFrame = 1920; // 40 ms
        break;
      case 3:
      default:
        samplesPerFrame = 2880; // 60 ms
        break;
    }
  }

  if (frameCountCode == 0) {
    return samplesPerFrame;
  } else if (frameCountCode == 1 || frameCountCode == 2) {
    return samplesPerFrame * 2;
  } else {
    if (packet.length < 2) return samplesPerFrame;
    final count = packet[1] & 0x3F;
    return samplesPerFrame * math.max(1, count);
  }
}

/// A zero-copy / streaming WebM (Matroska) Opus to standard Ogg Opus remuxer.
/// Allows streaming YouTube WebM audio directly into flutter_soloud C++ engine.
class WebmToOggRemuxer extends StreamTransformerBase<List<int>, Uint8List> {
  final int? serialNumber;

  const WebmToOggRemuxer({this.serialNumber});

  @override
  Stream<Uint8List> bind(Stream<List<int>> stream) {
    return Stream<Uint8List>.eventTransformed(
      stream,
      (sink) => _WebmToOggSink(sink, serialNumber: serialNumber),
    );
  }

  /// Helper to convert a WebM stream to an Ogg Opus stream directly.
  static Stream<Uint8List> remuxStream(Stream<List<int>> stream, {int? serialNumber}) {
    return stream.transform(WebmToOggRemuxer(serialNumber: serialNumber));
  }
}

class _WebmToOggSink implements EventSink<List<int>> {
  final EventSink<Uint8List> _outputSink;
  final OggPageBuilder _pageBuilder;

  // Buffer state
  Uint8List _buffer = Uint8List(0);
  int _offset = 0;

  // Track metadata
  Uint8List? _opusHeadData;
  int _channels = 2;
  int _sampleRate = 48000;
  bool _headersSent = false;
  int _currentGranulePos = 0;
  bool _hasEmittedAnyPage = false;

  // Master elements in Matroska hierarchy that contain child elements
  static const Set<int> _masterElements = {
    0x1A45DFA3, // EBML
    0x18538067, // Segment
    0x1654AE6B, // Tracks
    0xAE,       // TrackEntry
    0xE1,       // Audio
    0x1F43B675, // Cluster
  };

  _WebmToOggSink(this._outputSink, {int? serialNumber})
      : _pageBuilder = OggPageBuilder(serialNumber: serialNumber);

  @override
  void add(List<int> chunk) {
    if (chunk.isEmpty) return;

    // Append new chunk to internal buffer
    if (_offset >= _buffer.length) {
      _buffer = chunk is Uint8List ? chunk : Uint8List.fromList(chunk);
      _offset = 0;
    } else {
      final remaining = _buffer.length - _offset;
      final newBuffer = Uint8List(remaining + chunk.length);
      newBuffer.setRange(0, remaining, _buffer, _offset);
      newBuffer.setRange(remaining, remaining + chunk.length, chunk);
      _buffer = newBuffer;
      _offset = 0;
    }

    _processBuffer();
  }

  void _processBuffer() {
    while (_offset < _buffer.length) {
      final startOffset = _offset;

      // 1. Read Element ID (VINT)
      final elementId = _readElementId();
      if (elementId == null) {
        _offset = startOffset;
        break;
      }

      // 2. Read Element Size (VINT)
      final elementSize = _readElementSize();
      if (elementSize == null) {
        _offset = startOffset;
        break;
      }

      // If it's a master element, we step inside it (size can be unknown/undefined = -1)
      if (_masterElements.contains(elementId) || elementSize == -1) {
        continue;
      }

      // Leaf element: verify if we have the entire element payload
      if (_offset + elementSize > _buffer.length) {
        _offset = startOffset;
        break;
      }

      final payloadStart = _offset;
      final payloadEnd = payloadStart + elementSize;

      _handleLeafElement(elementId, payloadStart, payloadEnd);
      _offset = payloadEnd;
    }

    // Compact buffer if needed
    if (_offset > 0) {
      if (_offset >= _buffer.length) {
        _buffer = Uint8List(0);
        _offset = 0;
      } else if (_offset > 65536) {
        final remaining = _buffer.length - _offset;
        final compact = Uint8List(remaining);
        compact.setRange(0, remaining, _buffer, _offset);
        _buffer = compact;
        _offset = 0;
      }
    }
  }

  void _handleLeafElement(int elementId, int start, int end) {
    switch (elementId) {
      case 0x63A2: // CodecPrivate
        final privateData = _buffer.sublist(start, end);
        if (privateData.length >= 8 &&
            privateData[0] == 0x4F &&
            privateData[1] == 0x70 &&
            privateData[2] == 0x75 &&
            privateData[3] == 0x73 &&
            privateData[4] == 0x48 &&
            privateData[5] == 0x65 &&
            privateData[6] == 0x61 &&
            privateData[7] == 0x64) {
          _opusHeadData = privateData;
        } else if (privateData.length >= 19) {
          _opusHeadData = privateData;
        }
        break;

      case 0x9F: // Channels
        if (end - start >= 1) {
          _channels = _buffer[start];
        }
        break;

      case 0xB5: // SamplingFrequency
        // float 4-byte or 8-byte
        if (end - start == 4) {
          _sampleRate = ByteData.sublistView(_buffer, start, end).getFloat32(0, Endian.big).toInt();
        } else if (end - start == 8) {
          _sampleRate = ByteData.sublistView(_buffer, start, end).getFloat64(0, Endian.big).toInt();
        }
        break;

      case 0xA3: // SimpleBlock
      case 0xA1: // Block
        _handleBlock(start, end);
        break;

      default:
        // Ignore other leaf elements (SeekHead, Info, Cues, Tags, etc.)
        break;
    }
  }

  void _ensureHeadersSent() {
    if (_headersSent) return;
    _headersSent = true;

    // 1. Page 0 (BOS): OpusHead
    final opusHead = _opusHeadData ??
        OggPageBuilder.createDefaultOpusHead(
          channels: _channels,
          sampleRate: _sampleRate,
        );

    final page0 = _pageBuilder.buildPage(
      headerType: 0x02, // BOS
      granulePos: 0,
      packets: [opusHead],
    );
    _outputSink.add(page0);
    _hasEmittedAnyPage = true;

    // 2. Page 1: OpusTags
    final opusTags = OggPageBuilder.createDefaultOpusTags();
    final page1 = _pageBuilder.buildPage(
      headerType: 0x00,
      granulePos: 0,
      packets: [opusTags],
    );
    _outputSink.add(page1);
  }

  void _handleBlock(int start, int end) {
    if (end - start < 4) return;

    _ensureHeadersSent();

    int pos = start;
    // 1. Track Number (VINT)
    final firstByte = _buffer[pos];
    int vintLen = 1;
    int mask = 0x80;
    while ((firstByte & mask) == 0 && vintLen < 8) {
      vintLen++;
      mask >>= 1;
    }
    pos += vintLen;
    if (pos + 3 > end) return;

    // 2. Timecode (2 bytes int16)
    pos += 2;

    // 3. Flags (1 byte)
    final flags = _buffer[pos++];
    final lacing = (flags >> 1) & 0x03;

    final packets = <Uint8List>[];

    if (lacing == 0) {
      // No lacing: remaining bytes are the single Opus packet
      if (pos < end) {
        packets.add(_buffer.sublist(pos, end));
      }
    } else if (lacing == 1) {
      // Xiph lacing
      if (pos < end) {
        final frameCount = _buffer[pos++] + 1;
        final sizes = <int>[];
        for (int i = 0; i < frameCount - 1; i++) {
          int size = 0;
          while (pos < end) {
            final b = _buffer[pos++];
            size += b;
            if (b < 255) break;
          }
          sizes.add(size);
        }
        int remainingBytes = end - pos;
        for (final sz in sizes) {
          if (pos + sz <= end) {
            packets.add(_buffer.sublist(pos, pos + sz));
            pos += sz;
            remainingBytes -= sz;
          }
        }
        if (remainingBytes > 0 && pos < end) {
          packets.add(_buffer.sublist(pos, end));
        }
      }
    } else if (lacing == 2) {
      // Fixed-size lacing
      if (pos < end) {
        final frameCount = _buffer[pos++] + 1;
        final frameSize = (end - pos) ~/ frameCount;
        for (int i = 0; i < frameCount; i++) {
          final frameEnd = (i == frameCount - 1) ? end : pos + frameSize;
          if (pos < frameEnd && frameEnd <= end) {
            packets.add(_buffer.sublist(pos, frameEnd));
            pos = frameEnd;
          }
        }
      }
    } else if (lacing == 3) {
      // EBML lacing
      if (pos < end) {
        final frameCount = _buffer[pos++] + 1;
        final sizes = <int>[];
        int lastSize = 0;
        for (int i = 0; i < frameCount - 1; i++) {
          if (i == 0) {
            final sz = _readVintAt(pos, end);
            if (sz == null) break;
            pos += sz.length;
            lastSize = sz.value;
            sizes.add(lastSize);
          } else {
            final diff = _readSignedVintAt(pos, end);
            if (diff == null) break;
            pos += diff.length;
            lastSize += diff.value;
            sizes.add(lastSize);
          }
        }
        int remainingBytes = end - pos;
        for (final sz in sizes) {
          if (pos + sz <= end) {
            packets.add(_buffer.sublist(pos, pos + sz));
            pos += sz;
            remainingBytes -= sz;
          }
        }
        if (remainingBytes > 0 && pos < end) {
          packets.add(_buffer.sublist(pos, end));
        }
      }
    }

    if (packets.isNotEmpty) {
      for (final pkt in packets) {
        final samples = getOpusPacketSamples(pkt);
        _currentGranulePos += samples;
        final oggPage = _pageBuilder.buildPage(
          headerType: 0x00,
          granulePos: _currentGranulePos,
          packets: [pkt],
        );
        _outputSink.add(oggPage);
      }
    }
  }

  int? _readElementId() {
    if (_offset >= _buffer.length) return null;
    final firstByte = _buffer[_offset];
    int len = 1;
    int mask = 0x80;
    while ((firstByte & mask) == 0 && len < 4) {
      len++;
      mask >>= 1;
    }
    if (_offset + len > _buffer.length) return null;

    int id = 0;
    for (int i = 0; i < len; i++) {
      id = (id << 8) | _buffer[_offset + i];
    }
    _offset += len;
    return id;
  }

  int? _readElementSize() {
    if (_offset >= _buffer.length) return null;
    final firstByte = _buffer[_offset];
    int len = 1;
    int mask = 0x80;
    while ((firstByte & mask) == 0 && len < 8) {
      len++;
      mask >>= 1;
    }
    if (_offset + len > _buffer.length) return null;

    int size = firstByte & (mask - 1);
    for (int i = 1; i < len; i++) {
      size = (size << 8) | _buffer[_offset + i];
    }

    // Check for undefined size (all 1s in value bits)
    int maxVal = (1 << (7 * len)) - 1;
    if (size == maxVal) {
      size = -1;
    }

    _offset += len;
    return size;
  }

  ({int value, int length})? _readVintAt(int start, int end) {
    if (start >= end) return null;
    final firstByte = _buffer[start];
    int len = 1;
    int mask = 0x80;
    while ((firstByte & mask) == 0 && len < 8) {
      len++;
      mask >>= 1;
    }
    if (start + len > end) return null;

    int val = firstByte & (mask - 1);
    for (int i = 1; i < len; i++) {
      val = (val << 8) | _buffer[start + i];
    }
    return (value: val, length: len);
  }

  ({int value, int length})? _readSignedVintAt(int start, int end) {
    final unsigned = _readVintAt(start, end);
    if (unsigned == null) return null;
    final bias = (1 << (7 * unsigned.length - 1)) - 1;
    return (value: unsigned.value - bias, length: unsigned.length);
  }

  @override
  void addError(Object error, [StackTrace? stackTrace]) {
    _outputSink.addError(error, stackTrace);
  }

  @override
  void close() {
    if (_hasEmittedAnyPage) {
      try {
        final eosPage = _pageBuilder.buildPage(
          headerType: 0x04, // EOS
          granulePos: _currentGranulePos,
          packets: const [],
        );
        _outputSink.add(eosPage);
      } catch (_) {}
    }
    _outputSink.close();
  }
}
