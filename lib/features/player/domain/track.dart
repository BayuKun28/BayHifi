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
  final int? bitrate;
  final AudioFormat format;
  final String? genre;
  final int? year;
  final int? trackNumber;
  final int? trackTotal;
  final int? discNumber;
  final int? discTotal;
  final String? albumArtist;
  final String? lyrics;
  final int? lastModifiedMs;
  final int? fileSize;
  final double? replayGainTrackDb;
  final double? replayGainTrackPeak;
  final double? replayGainAlbumDb;
  final double? replayGainAlbumPeak;

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
    this.bitrate,
    this.format = AudioFormat.unknown,
    this.genre,
    this.year,
    this.trackNumber,
    this.trackTotal,
    this.discNumber,
    this.discTotal,
    this.albumArtist,
    this.lyrics,
    this.lastModifiedMs,
    this.fileSize,
    this.replayGainTrackDb,
    this.replayGainTrackPeak,
    this.replayGainAlbumDb,
    this.replayGainAlbumPeak,
  });

  String? get streamUrl => remoteUrl;

  bool get isHiRes =>
      (bitDepth != null && bitDepth! >= 24) ||
      (sampleRate != null && sampleRate! >= 88200) ||
      format == AudioFormat.dsd;

  /// Check if the track lacks proper metadata (unknown artist/album, generic title, or missing artwork)
  bool get isUntagged {
    final a = artist.trim().toLowerCase();
    final alb = album.trim().toLowerCase();
    final tit = title.trim().toLowerCase();
    final isUnknownArtist =
        a.isEmpty || a == 'unknown artist' || a == 'unknown' || a == '<unknown>';
    final isUnknownAlbum =
        alb.isEmpty || alb == 'unknown album' || alb == 'unknown' || alb == '<unknown>';
    final isGenericTitle = tit.isEmpty ||
        tit.startsWith('track ') ||
        tit.startsWith('track_') ||
        tit.startsWith('track-') ||
        tit.endsWith('.mp3') ||
        tit.endsWith('.flac') ||
        tit.endsWith('.wav') ||
        tit.endsWith('.m4a') ||
        tit.endsWith('.ogg');
    final hasNoArt = (albumArtUrl == null || albumArtUrl!.isEmpty) &&
        (albumArtBytes == null || albumArtBytes!.isEmpty);
    return isUnknownArtist || isUnknownAlbum || isGenericTitle || hasNoArt;
  }

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
    int? bitrate,
    AudioFormat? format,
    String? genre,
    int? year,
    int? trackNumber,
    int? trackTotal,
    int? discNumber,
    int? discTotal,
    String? albumArtist,
    String? lyrics,
    int? lastModifiedMs,
    int? fileSize,
    double? replayGainTrackDb,
    double? replayGainTrackPeak,
    double? replayGainAlbumDb,
    double? replayGainAlbumPeak,
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
      bitrate: bitrate ?? this.bitrate,
      format: format ?? this.format,
      genre: genre ?? this.genre,
      year: year ?? this.year,
      trackNumber: trackNumber ?? this.trackNumber,
      trackTotal: trackTotal ?? this.trackTotal,
      discNumber: discNumber ?? this.discNumber,
      discTotal: discTotal ?? this.discTotal,
      albumArtist: albumArtist ?? this.albumArtist,
      lyrics: lyrics ?? this.lyrics,
      lastModifiedMs: lastModifiedMs ?? this.lastModifiedMs,
      fileSize: fileSize ?? this.fileSize,
      replayGainTrackDb: replayGainTrackDb ?? this.replayGainTrackDb,
      replayGainTrackPeak: replayGainTrackPeak ?? this.replayGainTrackPeak,
      replayGainAlbumDb: replayGainAlbumDb ?? this.replayGainAlbumDb,
      replayGainAlbumPeak: replayGainAlbumPeak ?? this.replayGainAlbumPeak,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'album': album,
      'durationMs': duration.inMilliseconds,
      'filePath': filePath,
      'remoteUrl': remoteUrl,
      'albumArtUrl': albumArtUrl,
      'sampleRate': sampleRate,
      'bitDepth': bitDepth,
      'bitrate': bitrate,
      'format': format.name,
      'genre': genre,
      'year': year,
      'trackNumber': trackNumber,
      'trackTotal': trackTotal,
      'discNumber': discNumber,
      'discTotal': discTotal,
      'albumArtist': albumArtist,
      'lyrics': lyrics,
      'lastModifiedMs': lastModifiedMs,
      'fileSize': fileSize,
      'replayGainTrackDb': replayGainTrackDb,
      'replayGainTrackPeak': replayGainTrackPeak,
      'replayGainAlbumDb': replayGainAlbumDb,
      'replayGainAlbumPeak': replayGainAlbumPeak,
    };
  }

  factory Track.fromMap(Map<String, dynamic> map) {
    AudioFormat parseFormat(String? name) {
      if (name == null) return AudioFormat.unknown;
      return AudioFormat.values.firstWhere(
        (e) => e.name == name,
        orElse: () => AudioFormat.unknown,
      );
    }

    return Track(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? 'Unknown Title',
      artist: map['artist'] as String? ?? 'Unknown Artist',
      album: map['album'] as String? ?? 'Unknown Album',
      duration: Duration(milliseconds: (map['durationMs'] as num?)?.toInt() ?? 0),
      filePath: map['filePath'] as String?,
      remoteUrl: map['remoteUrl'] as String?,
      albumArtUrl: map['albumArtUrl'] as String?,
      sampleRate: (map['sampleRate'] as num?)?.toInt(),
      bitDepth: (map['bitDepth'] as num?)?.toInt(),
      bitrate: (map['bitrate'] as num?)?.toInt(),
      format: parseFormat(map['format'] as String?),
      genre: map['genre'] as String?,
      year: (map['year'] as num?)?.toInt(),
      trackNumber: (map['trackNumber'] as num?)?.toInt(),
      trackTotal: (map['trackTotal'] as num?)?.toInt(),
      discNumber: (map['discNumber'] as num?)?.toInt(),
      discTotal: (map['discTotal'] as num?)?.toInt(),
      albumArtist: map['albumArtist'] as String?,
      lyrics: map['lyrics'] as String?,
      lastModifiedMs: (map['lastModifiedMs'] as num?)?.toInt(),
      fileSize: (map['fileSize'] as num?)?.toInt(),
      replayGainTrackDb: (map['replayGainTrackDb'] as num?)?.toDouble(),
      replayGainTrackPeak: (map['replayGainTrackPeak'] as num?)?.toDouble(),
      replayGainAlbumDb: (map['replayGainAlbumDb'] as num?)?.toDouble(),
      replayGainAlbumPeak: (map['replayGainAlbumPeak'] as num?)?.toDouble(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Track && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
