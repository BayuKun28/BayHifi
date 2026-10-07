import 'package:flutter/foundation.dart';

/// Single logged playback session entry recorded by PlaybackAnalyticsService
@immutable
class PlaybackLogEntry {
  final String id;
  final String trackId;
  final String title;
  final String artist;
  final String album;
  final String genre;
  final int durationPlayedMs;
  final int trackDurationMs;
  final String format; // 'flac', 'wav', 'mp3', 'aac', 'opus', etc.
  final int sampleRate; // e.g. 44100, 96000, 192000
  final int bitDepth; // e.g. 16, 24, 32
  final DateTime timestamp;
  final String? driverName;
  final String? targetName;
  final bool isAutoEqActive;
  final int activeDspCount;
  final String? dacDeviceName;

  const PlaybackLogEntry({
    required this.id,
    required this.trackId,
    required this.title,
    required this.artist,
    required this.album,
    required this.genre,
    required this.durationPlayedMs,
    required this.trackDurationMs,
    required this.format,
    required this.sampleRate,
    required this.bitDepth,
    required this.timestamp,
    this.driverName,
    this.targetName,
    this.isAutoEqActive = false,
    this.activeDspCount = 0,
    this.dacDeviceName,
  });

  bool get isHiRes => bitDepth >= 24 || sampleRate >= 88200;
  bool get isLossless => format.toLowerCase() == 'flac' || format.toLowerCase() == 'wav' || format.toLowerCase() == 'alac';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'trackId': trackId,
      'title': title,
      'artist': artist,
      'album': album,
      'genre': genre,
      'durationPlayedMs': durationPlayedMs,
      'trackDurationMs': trackDurationMs,
      'format': format,
      'sampleRate': sampleRate,
      'bitDepth': bitDepth,
      'timestamp': timestamp.toIso8601String(),
      'driverName': driverName,
      'targetName': targetName,
      'isAutoEqActive': isAutoEqActive,
      'activeDspCount': activeDspCount,
      'dacDeviceName': dacDeviceName,
    };
  }

  factory PlaybackLogEntry.fromMap(Map<String, dynamic> map) {
    return PlaybackLogEntry(
      id: map['id'] as String? ?? '',
      trackId: map['trackId'] as String? ?? '',
      title: map['title'] as String? ?? 'Unknown Title',
      artist: map['artist'] as String? ?? 'Unknown Artist',
      album: map['album'] as String? ?? 'Unknown Album',
      genre: map['genre'] as String? ?? 'Acoustic',
      durationPlayedMs: (map['durationPlayedMs'] as num?)?.toInt() ?? 0,
      trackDurationMs: (map['trackDurationMs'] as num?)?.toInt() ?? 0,
      format: (map['format'] as String?) ?? 'flac',
      sampleRate: (map['sampleRate'] as num?)?.toInt() ?? 44100,
      bitDepth: (map['bitDepth'] as num?)?.toInt() ?? 16,
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ?? DateTime.now(),
      driverName: map['driverName'] as String?,
      targetName: map['targetName'] as String?,
      isAutoEqActive: map['isAutoEqActive'] as bool? ?? false,
      activeDspCount: (map['activeDspCount'] as num?)?.toInt() ?? 0,
      dacDeviceName: map['dacDeviceName'] as String?,
    );
  }
}
