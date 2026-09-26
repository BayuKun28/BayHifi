import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../../features/player/domain/track.dart';

@immutable
class AudioTechnicalDetails {
  final String title;
  final String artist;
  final String album;
  final String containerFormat;
  final String codecProfile;
  final int sampleRate;
  final int bitDepth;
  final int channels;
  final int bitrateKbps;
  final int fileSizeBytes;
  final String formattedFileSize;
  final String magicBytesHex;
  final String magicBytesAscii;
  final String? md5Checksum;
  final String location;
  final bool isHiRes;
  final bool isLocal;

  const AudioTechnicalDetails({
    required this.title,
    required this.artist,
    required this.album,
    required this.containerFormat,
    required this.codecProfile,
    required this.sampleRate,
    required this.bitDepth,
    required this.channels,
    required this.bitrateKbps,
    required this.fileSizeBytes,
    required this.formattedFileSize,
    required this.magicBytesHex,
    required this.magicBytesAscii,
    this.md5Checksum,
    required this.location,
    required this.isHiRes,
    required this.isLocal,
  });
}

class AudioFileInspector {
  static Future<AudioTechnicalDetails> inspectTrack(Track track) async {
    final isLocal = track.filePath != null && track.filePath!.isNotEmpty;
    final path = track.filePath ?? track.remoteUrl ?? 'Unknown Location';

    int sizeBytes = 0;
    String magicHex = 'N/A';
    String magicAscii = 'N/A';
    String? md5Hash;

    if (isLocal) {
      try {
        final file = File(track.filePath!);
        if (await file.exists()) {
          sizeBytes = await file.length();

          // Read header bytes (first 8 bytes)
          final raf = await file.open(mode: FileMode.read);
          final headerBytes = await raf.read(8);
          await raf.close();

          if (headerBytes.isNotEmpty) {
            magicHex = headerBytes
                .map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase())
                .join(' ');
            magicAscii = headerBytes
                .map((b) => (b >= 32 && b <= 126) ? String.fromCharCode(b) : '.')
                .join('');
          }

          // Compute MD5 hash in isolate for files < 100MB
          if (sizeBytes > 0 && sizeBytes < 100 * 1024 * 1024) {
            final bytes = await file.readAsBytes();
            md5Hash = md5.convert(bytes).toString();
          } else {
            md5Hash = 'File too large for fast hash';
          }
        }
      } catch (e) {
        debugPrint('[AudioFileInspector] File read error: $e');
      }
    }

    final formatName = track.format.name.toUpperCase();
    final sampleRate = track.sampleRate ?? (track.format == AudioFormat.flac ? 96000 : 44100);
    final bitDepth = track.bitDepth ?? (track.format == AudioFormat.flac ? 24 : 16);
    final channels = 2; // Default stereo

    // Calculate approximate bitrate
    int bitrate = 0;
    if (sizeBytes > 0 && track.duration.inSeconds > 0) {
      bitrate = ((sizeBytes * 8) / track.duration.inSeconds / 1000).round();
    } else {
      bitrate = switch (track.format) {
        AudioFormat.flac => (sampleRate * bitDepth * channels / 1000 * 0.6).round(),
        AudioFormat.wav => (sampleRate * bitDepth * channels / 1000).round(),
        AudioFormat.mp3 => 320,
        AudioFormat.opus => 160,
        AudioFormat.ogg => 256,
        AudioFormat.dsd => 5644,
        _ => 320,
      };
    }

    final codecDesc = switch (track.format) {
      AudioFormat.flac => 'Free Lossless Audio Codec (PCM Reference)',
      AudioFormat.wav => 'Linear PCM Uncompressed Waveform',
      AudioFormat.mp3 => 'MPEG-1 Audio Layer III (Perceptual Lossy)',
      AudioFormat.opus => 'IETF Opus Interactive Audio Codec',
      AudioFormat.ogg => 'Ogg Vorbis Compressed Audio',
      AudioFormat.alac => 'Apple Lossless Audio Codec (ALAC)',
      AudioFormat.dsd => 'Direct Stream Digital (1-bit Delta-Sigma)',
      AudioFormat.unknown => 'Standard PCM Audio Stream',
    };

    return AudioTechnicalDetails(
      title: track.title,
      artist: track.artist,
      album: track.album,
      containerFormat: formatName,
      codecProfile: codecDesc,
      sampleRate: sampleRate,
      bitDepth: bitDepth,
      channels: channels,
      bitrateKbps: bitrate,
      fileSizeBytes: sizeBytes,
      formattedFileSize: _formatFileSize(sizeBytes),
      magicBytesHex: magicHex,
      magicBytesAscii: magicAscii,
      md5Checksum: md5Hash,
      location: path,
      isHiRes: track.isHiRes,
      isLocal: isLocal,
    );
  }

  static String _formatFileSize(int bytes) {
    if (bytes <= 0) return 'Remote Stream';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    final mb = (bytes / (1024 * 1024)).toStringAsFixed(2);
    final formattedInt = _formatIntWithCommas(bytes);
    return '$mb MB ($formattedInt bytes)';
  }

  static String _formatIntWithCommas(int n) {
    return n.toString().replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
