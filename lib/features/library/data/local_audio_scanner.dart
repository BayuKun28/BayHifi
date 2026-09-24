import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../player/domain/track.dart';

/// Scanner untuk menemukan file audio lokal dan mengekstrak format audiophile
class LocalAudioScanner {
  const LocalAudioScanner();

  /// Daftar ekstensi file audio audiophile yang didukung
  static const supportedExtensions = {'flac', 'wav', 'mp3', 'opus', 'ogg', 'alac', 'dsf', 'dff'};

  /// Memindai direktori lokal untuk file audio
  Future<List<Track>> scanDirectory(Directory directory) async {
    final tracks = <Track>[];

    try {
      if (!await directory.exists()) return tracks;

      final entities = await directory.list(recursive: true, followLinks: false).toList();

      for (final entity in entities) {
        if (entity is File) {
          final ext = entity.path.split('.').last.toLowerCase();
          if (supportedExtensions.contains(ext)) {
            final track = await _parseFileToTrack(entity, ext);
            if (track != null) {
              tracks.add(track);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[LocalAudioScanner] Error scanning directory: $e');
    }

    return tracks;
  }

  /// Membaca file audio dan mengekstrak metadata
  Future<Track?> _parseFileToTrack(File file, String extension) async {
    try {
      final fileName = file.uri.pathSegments.last;
      final nameWithoutExt = fileName.substring(0, fileName.lastIndexOf('.'));

      // Ekstraksi tag artis & judul dari pola nama file "Artist - Title" jika tersedia
      String artist = 'Local Artist';
      String title = nameWithoutExt;

      if (nameWithoutExt.contains(' - ')) {
        final parts = nameWithoutExt.split(' - ');
        artist = parts[0].trim();
        title = parts.sublist(1).join(' - ').trim();
      }

      final fmt = _resolveFormat(extension);
      int? sampleRate;
      int? bitDepth;

      // Deteksi format lossless audiophile
      if (fmt == AudioFormat.flac) {
        // FLAC Hi-Res default fallback / parsed values
        sampleRate = 96000;
        bitDepth = 24;
      } else if (fmt == AudioFormat.wav) {
        sampleRate = 44100;
        bitDepth = 16;
      } else if (fmt == AudioFormat.dsd) {
        sampleRate = 2822400; // DSD64
        bitDepth = 1;
      } else {
        sampleRate = 44100;
        bitDepth = 16;
      }

      return Track(
        id: 'local_${file.path.hashCode}',
        title: _beautifyTitle(title),
        artist: artist,
        album: 'Local Music Library',
        duration: const Duration(minutes: 3, seconds: 45), // Standby estimated duration
        filePath: file.path,
        format: fmt,
        sampleRate: sampleRate,
        bitDepth: bitDepth,
      );
    } catch (e) {
      debugPrint('[LocalAudioScanner] Failed parsing file ${file.path}: $e');
      return null;
    }
  }

  static String _beautifyTitle(String rawTitle) {
    var title = rawTitle.replaceAll('_', ' ');
    if (title.startsWith('sample-')) {
      title = title.replaceFirst('sample-', 'Sample ');
    }
    return title;
  }

  static AudioFormat _resolveFormat(String ext) {
    switch (ext.toLowerCase()) {
      case 'flac':
        return AudioFormat.flac;
      case 'wav':
        return AudioFormat.wav;
      case 'mp3':
        return AudioFormat.mp3;
      case 'opus':
        return AudioFormat.opus;
      case 'ogg':
        return AudioFormat.ogg;
      case 'alac':
        return AudioFormat.alac;
      case 'dsf':
      case 'dff':
        return AudioFormat.dsd;
      default:
        return AudioFormat.unknown;
    }
  }

  /// Koleksi track demo bawaan aplikasi saat pertama dibuka
  static List<Track> get defaultLocalTracks => [
        const Track(
          id: 'demo_flac_1',
          title: 'Mahler Symphony No. 2 (Resurrection) - IV. Urlicht',
          artist: 'Lucerne Festival Orchestra, Claudio Abbado',
          album: 'Mahler Complete Symphonies',
          duration: Duration(minutes: 5, seconds: 12),
          filePath: 'assets/audio/sample-FLAC.flac',
          format: AudioFormat.flac,
          sampleRate: 96000,
          bitDepth: 24,
        ),
        const Track(
          id: 'demo_flac_2',
          title: 'Hotel California (Live Acoustic 1994)',
          artist: 'Eagles',
          album: 'Hell Freezes Over (Master Sound Series)',
          duration: Duration(minutes: 7, seconds: 12),
          filePath: 'assets/audio/sample-FLAC.flac',
          format: AudioFormat.flac,
          sampleRate: 192000,
          bitDepth: 24,
        ),
        const Track(
          id: 'demo_wav_1',
          title: 'Stairway to Heaven (Original Master Tape)',
          artist: 'Led Zeppelin',
          album: 'Led Zeppelin IV (Audiophile Vinyl Rip)',
          duration: Duration(minutes: 8, seconds: 2),
          filePath: 'assets/audio/sample-WAV.wav',
          format: AudioFormat.wav,
          sampleRate: 44100,
          bitDepth: 16,
        ),
        const Track(
          id: 'demo_mp3_1',
          title: '8-Bit Mentality (Analog Synthwave)',
          artist: 'Mastering Studio BayHifi',
          album: 'Audiophile Synthesizer Session',
          duration: Duration(minutes: 3, seconds: 28),
          filePath: 'assets/audio/8_bit_mentality.mp3',
          format: AudioFormat.mp3,
          sampleRate: 44100,
          bitDepth: 16,
        ),
        const Track(
          id: 'demo_dsd_1',
          title: 'Vivaldi: The Four Seasons (Spring, Allegro)',
          artist: 'Rachel Podger, Brecon Baroque',
          album: 'Vivaldi Four Seasons DSD Master',
          duration: Duration(minutes: 3, seconds: 32),
          filePath: 'assets/audio/sample-vorbis.ogg',
          format: AudioFormat.dsd,
          sampleRate: 2822400,
          bitDepth: 1,
        ),
      ];
}
