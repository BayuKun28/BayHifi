import 'package:flutter/foundation.dart';

enum AudioFormat {
  flac,
  mp3,
  wav,
  ogg,
  opus,
  alac,
  dsd,
  unknown,
}

@immutable
class Track {
  final String id;
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final String? filePath;
  final String? remoteUrl;
  final Uint8List? albumArtBytes;
  final String? albumArtUrl;
  final int? sampleRate;
  final int? bitDepth;
  final AudioFormat format;

  const Track({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    this.filePath,
    this.remoteUrl,
    this.albumArtBytes,
    this.albumArtUrl,
    this.sampleRate,
    this.bitDepth,
    this.format = AudioFormat.unknown,
  });

  bool get isHiRes =>
      (bitDepth != null && bitDepth! >= 24) ||
      (sampleRate != null && sampleRate! >= 88200) ||
      format == AudioFormat.dsd;

  String get hiResBadgeText {
    if (format == AudioFormat.dsd) return 'DSD';
    final bits = bitDepth != null ? '$bitDepth-bit' : '';
    final rate = sampleRate != null ? '${(sampleRate! / 1000).toStringAsFixed(1)} kHz' : '';
    final fmt = format.name.toUpperCase();
    if (bits.isNotEmpty && rate.isNotEmpty) {
      return '$fmt $bits / $rate';
    }
    return fmt;
  }

  Track copyWith({
    String? id,
    String? title,
    String? artist,
    String? album,
    Duration? duration,
    String? filePath,
    String? remoteUrl,
    Uint8List? albumArtBytes,
    String? albumArtUrl,
    int? sampleRate,
    int? bitDepth,
    AudioFormat? format,
  }) {
    return Track(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      filePath: filePath ?? this.filePath,
      remoteUrl: remoteUrl ?? this.remoteUrl,
      albumArtBytes: albumArtBytes ?? this.albumArtBytes,
      albumArtUrl: albumArtUrl ?? this.albumArtUrl,
      sampleRate: sampleRate ?? this.sampleRate,
      bitDepth: bitDepth ?? this.bitDepth,
      format: format ?? this.format,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Track && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
