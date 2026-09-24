import 'dart:io';
import 'dart:typed_data';
import '../features/player/domain/track.dart';

/// Helper untuk identifikasi format audio secara presisi berdasarkan magic bytes dan ekstensi file.
class AudioFormatDetector {
  AudioFormatDetector._();

  /// Mendeteksi format audio dan membaca informasi bitrate/depth jika tersedia
  static Future<TrackMetadataInfo> inspectFile(String filePath) async {
    final file = File(filePath);
    if (!await file.exists()) {
      return const TrackMetadataInfo(format: AudioFormat.unknown);
    }

    final ext = filePath.split('.').last.toLowerCase();
    RandomAccessFile? raf;

    try {
      raf = await file.open(mode: FileMode.read);
      final header = await raf.read(64);

      // 1. Cek FLAC (Magic: 'fLaC')
      if (_hasMagic(header, [0x66, 0x4C, 0x61, 0x43])) {
        final flacInfo = _parseFlacStreamInfo(header);
        return TrackMetadataInfo(
          format: AudioFormat.flac,
          sampleRate: flacInfo.sampleRate ?? 44100,
          bitDepth: flacInfo.bitDepth ?? 16,
        );
      }

      // 2. Cek WAV (RIFF .... WAVE)
      if (header.length >= 12 &&
          _hasMagic(header, [0x52, 0x49, 0x46, 0x46]) && // RIFF
          _hasSubMagic(header, 8, [0x57, 0x41, 0x56, 0x45])) { // WAVE
        return const TrackMetadataInfo(
          format: AudioFormat.wav,
          sampleRate: 44100,
          bitDepth: 16,
        );
      }

      // 3. Cek DSD (Magic: 'DSD ')
      if (_hasMagic(header, [0x44, 0x53, 0x44, 0x20])) {
        return const TrackMetadataInfo(
          format: AudioFormat.dsd,
          sampleRate: 2822400, // DSD64 2.8 MHz
          bitDepth: 1,
        );
      }

      // 4. Cek OGG
      if (_hasMagic(header, [0x4F, 0x67, 0x67, 0x53])) {
        if (ext == 'opus') {
          return const TrackMetadataInfo(
            format: AudioFormat.opus,
            sampleRate: 48000,
            bitDepth: 16,
          );
        }
        return const TrackMetadataInfo(
          format: AudioFormat.ogg,
          sampleRate: 44100,
          bitDepth: 16,
        );
      }

      // 5. Fallback ke ekstensi
      if (ext == 'flac') {
        return const TrackMetadataInfo(format: AudioFormat.flac, sampleRate: 96000, bitDepth: 24);
      } else if (ext == 'mp3') {
        return const TrackMetadataInfo(format: AudioFormat.mp3, sampleRate: 44100, bitDepth: 16);
      } else if (ext == 'wav') {
        return const TrackMetadataInfo(format: AudioFormat.wav, sampleRate: 44100, bitDepth: 16);
      } else if (ext == 'alac' || ext == 'm4a') {
        return const TrackMetadataInfo(format: AudioFormat.alac, sampleRate: 44100, bitDepth: 16);
      } else if (ext == 'dsf' || ext == 'dff') {
        return const TrackMetadataInfo(format: AudioFormat.dsd, sampleRate: 2822400, bitDepth: 1);
      }

      return const TrackMetadataInfo(format: AudioFormat.unknown);
    } catch (_) {
      return const TrackMetadataInfo(format: AudioFormat.unknown);
    } finally {
      await raf?.close();
    }
  }

  static bool _hasMagic(Uint8List bytes, List<int> magic) {
    if (bytes.length < magic.length) return false;
    for (int i = 0; i < magic.length; i++) {
      if (bytes[i] != magic[i]) return false;
    }
    return true;
  }

  static bool _hasSubMagic(Uint8List bytes, int offset, List<int> magic) {
    if (bytes.length < offset + magic.length) return false;
    for (int i = 0; i < magic.length; i++) {
      if (bytes[offset + i] != magic[i]) return false;
    }
    return true;
  }

  static ({int? sampleRate, int? bitDepth}) _parseFlacStreamInfo(Uint8List header) {
    // STREAMINFO block dimulai di offset 8 jika header normal
    if (header.length >= 26) {
      // Byte 18-20: sample rate (20 bits)
      // Byte 20: bit depth (5 bits: bits 20..24)
      final b18 = header[18];
      final b19 = header[19];
      final b20 = header[20];
      final b21 = header[21];

      final sampleRate = (b18 << 12) | (b19 << 4) | (b20 >> 4);
      final bitDepth = (((b20 & 0x01) << 4) | (b21 >> 4)) + 1;

      return (
        sampleRate: sampleRate > 0 ? sampleRate : null,
        bitDepth: (bitDepth >= 8 && bitDepth <= 32) ? bitDepth : null,
      );
    }
    return (sampleRate: null, bitDepth: null);
  }
}

class TrackMetadataInfo {
  final AudioFormat format;
  final int? sampleRate;
  final int? bitDepth;

  const TrackMetadataInfo({
    required this.format,
    this.sampleRate,
    this.bitDepth,
  });
}
