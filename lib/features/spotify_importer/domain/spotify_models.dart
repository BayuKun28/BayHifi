import 'package:flutter/foundation.dart';
import '../../player/domain/track.dart';

/// Supported Spotify content types
enum SpotifyItemType {
  track,
  album,
  playlist,
  artist,
  unknown;

  static SpotifyItemType fromString(String type) {
    switch (type.toLowerCase().trim()) {
      case 'track':
        return SpotifyItemType.track;
      case 'album':
        return SpotifyItemType.album;
      case 'playlist':
        return SpotifyItemType.playlist;
      case 'artist':
        return SpotifyItemType.artist;
      default:
        return SpotifyItemType.unknown;
    }
  }
}

/// Parsed Spotify URL details
@immutable
class SpotifyParsedUrl {
  final SpotifyItemType type;
  final String id;
  final String rawUrl;

  const SpotifyParsedUrl({
    required this.type,
    required this.id,
    required this.rawUrl,
  });

  bool get isValid => type != SpotifyItemType.unknown && id.isNotEmpty;

  /// Parses various Spotify URL / URI formats:
  /// - `https://open.spotify.com/track/4cOdK2wGLETKBW3PvgPWqT?si=...`
  /// - `https://open.spotify.com/album/4m2880jivSbbyEGAKfITCa`
  /// - `https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M`
  /// - `spotify:track:4cOdK2wGLETKBW3PvgPWqT`
  /// - `spotify:album:...`
  /// - `spotify:playlist:...`
  static SpotifyParsedUrl? parse(String input) {
    final clean = input.trim();
    if (clean.isEmpty) return null;

    // 1. Check URI format: spotify:track:xxx
    final uriRegExp = RegExp(r'^spotify:(track|album|playlist|artist):([a-zA-Z0-9]+)');
    final uriMatch = uriRegExp.firstMatch(clean);
    if (uriMatch != null) {
      final typeStr = uriMatch.group(1)!;
      final idStr = uriMatch.group(2)!;
      return SpotifyParsedUrl(
        type: SpotifyItemType.fromString(typeStr),
        id: idStr,
        rawUrl: clean,
      );
    }

    // 2. Check HTTP URL format: https://open.spotify.com/track/xxx?...
    final urlRegExp = RegExp(
      r'https?:\/\/(?:open\.)?spotify\.com\/(intl-[a-z]+\/)?(track|album|playlist|artist)\/([a-zA-Z0-9]+)',
      caseSensitive: false,
    );
    final urlMatch = urlRegExp.firstMatch(clean);
    if (urlMatch != null) {
      final typeStr = urlMatch.group(2)!;
      final idStr = urlMatch.group(3)!;
      return SpotifyParsedUrl(
        type: SpotifyItemType.fromString(typeStr),
        id: idStr,
        rawUrl: clean,
      );
    }

    return null;
  }
}

/// Individual Spotify Track metadata
@immutable
class SpotifyTrack {
  final String id;
  final String title;
  final String artist;
  final List<String> artists;
  final String album;
  final Duration duration;
  final String? albumArtUrl;
  final String? isrc;
  final int? trackNumber;
  final int? discNumber;
  final int? releaseYear;
  final String? spotifyUrl;

  const SpotifyTrack({
    required this.id,
    required this.title,
    required this.artist,
    required this.artists,
    required this.album,
    required this.duration,
    this.albumArtUrl,
    this.isrc,
    this.trackNumber,
    this.discNumber,
    this.releaseYear,
    this.spotifyUrl,
  });

  SpotifyTrack copyWith({
    String? id,
    String? title,
    String? artist,
    List<String>? artists,
    String? album,
    Duration? duration,
    String? albumArtUrl,
    String? isrc,
    int? trackNumber,
    int? discNumber,
    int? releaseYear,
    String? spotifyUrl,
  }) {
    return SpotifyTrack(
      id: id ?? this.id,
      title: title ?? this.title,
      artist: artist ?? this.artist,
      artists: artists ?? this.artists,
      album: album ?? this.album,
      duration: duration ?? this.duration,
      albumArtUrl: albumArtUrl ?? this.albumArtUrl,
      isrc: isrc ?? this.isrc,
      trackNumber: trackNumber ?? this.trackNumber,
      discNumber: discNumber ?? this.discNumber,
      releaseYear: releaseYear ?? this.releaseYear,
      spotifyUrl: spotifyUrl ?? this.spotifyUrl,
    );
  }

  /// Convert to Baydev HiFi Track model with streaming remote placeholder
  Track toTrack({String? matchedYouTubeId, String? matchedRemoteUrl}) {
    return Track(
      id: 'spotify_$id',
      title: title,
      artist: artist,
      album: album,
      duration: duration,
      albumArtUrl: albumArtUrl,
      albumArtist: artists.isNotEmpty ? artists.first : artist,
      trackNumber: trackNumber,
      discNumber: discNumber,
      year: releaseYear,
      remoteUrl: matchedRemoteUrl ?? 'spotify://track/$id',
      format: AudioFormat.opus,
    );
  }

  factory SpotifyTrack.fromJson(Map<String, dynamic> json, {String? defaultAlbumName, String? defaultAlbumArtUrl, int? defaultYear}) {
    final id = json['id'] as String? ?? '';
    final name = json['name'] as String? ?? 'Unknown Title';
    
    // Artists
    final artistsList = <String>[];
    if (json['artists'] is List) {
      for (final a in json['artists']) {
        if (a is Map && a['name'] != null) {
          artistsList.add(a['name'].toString());
        }
      }
    }
    final primaryArtist = artistsList.isNotEmpty ? artistsList.join(', ') : 'Unknown Artist';

    // Album & Art
    String albumName = defaultAlbumName ?? '';
    String? artUrl = defaultAlbumArtUrl;
    int? year = defaultYear;

    if (json['album'] is Map) {
      final alb = json['album'] as Map<String, dynamic>;
      albumName = alb['name'] as String? ?? albumName;
      if (alb['images'] is List && (alb['images'] as List).isNotEmpty) {
        artUrl = alb['images'][0]['url'] as String?;
      }
      final releaseDate = alb['release_date'] as String?;
      if (releaseDate != null && releaseDate.length >= 4) {
        year = int.tryParse(releaseDate.substring(0, 4)) ?? year;
      }
    }

    final durationMs = json['duration_ms'] as int? ?? 0;
    final externalIds = json['external_ids'] as Map<String, dynamic>?;
    final isrc = externalIds?['isrc'] as String?;
    final trackNumber = json['track_number'] as int?;
    final discNumber = json['disc_number'] as int?;
    final externalUrls = json['external_urls'] as Map<String, dynamic>?;
    final spotifyUrl = externalUrls?['spotify'] as String?;

    return SpotifyTrack(
      id: id,
      title: name,
      artist: primaryArtist,
      artists: artistsList.isNotEmpty ? artistsList : [primaryArtist],
      album: albumName.isNotEmpty ? albumName : 'Single',
      duration: Duration(milliseconds: durationMs),
      albumArtUrl: artUrl,
      isrc: isrc,
      trackNumber: trackNumber,
      discNumber: discNumber,
      releaseYear: year,
      spotifyUrl: spotifyUrl,
    );
  }
}

/// Spotify Album Metadata
@immutable
class SpotifyAlbum {
  final String id;
  final String title;
  final String artist;
  final String? albumArtUrl;
  final int? releaseYear;
  final int totalTracks;
  final List<SpotifyTrack> tracks;

  const SpotifyAlbum({
    required this.id,
    required this.title,
    required this.artist,
    this.albumArtUrl,
    this.releaseYear,
    required this.totalTracks,
    required this.tracks,
  });

  factory SpotifyAlbum.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final title = json['name'] as String? ?? 'Unknown Album';
    
    // Artists
    final artistsList = <String>[];
    if (json['artists'] is List) {
      for (final a in json['artists']) {
        if (a is Map && a['name'] != null) {
          artistsList.add(a['name'].toString());
        }
      }
    }
    final artist = artistsList.isNotEmpty ? artistsList.join(', ') : 'Unknown Artist';

    String? artUrl;
    if (json['images'] is List && (json['images'] as List).isNotEmpty) {
      artUrl = json['images'][0]['url'] as String?;
    }

    int? year;
    final releaseDate = json['release_date'] as String?;
    if (releaseDate != null && releaseDate.length >= 4) {
      year = int.tryParse(releaseDate.substring(0, 4));
    }

    final tracksList = <SpotifyTrack>[];
    if (json['tracks'] is Map && json['tracks']['items'] is List) {
      for (final t in json['tracks']['items']) {
        if (t is Map<String, dynamic>) {
          tracksList.add(
            SpotifyTrack.fromJson(
              t,
              defaultAlbumName: title,
              defaultAlbumArtUrl: artUrl,
              defaultYear: year,
            ),
          );
        }
      }
    }

    return SpotifyAlbum(
      id: id,
      title: title,
      artist: artist,
      albumArtUrl: artUrl,
      releaseYear: year,
      totalTracks: json['total_tracks'] as int? ?? tracksList.length,
      tracks: tracksList,
    );
  }
}

/// Spotify Playlist Metadata
@immutable
class SpotifyPlaylist {
  final String id;
  final String title;
  final String owner;
  final String? description;
  final String? albumArtUrl;
  final int totalTracks;
  final List<SpotifyTrack> tracks;

  const SpotifyPlaylist({
    required this.id,
    required this.title,
    required this.owner,
    this.description,
    this.albumArtUrl,
    required this.totalTracks,
    required this.tracks,
  });

  factory SpotifyPlaylist.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? '';
    final title = json['name'] as String? ?? 'Spotify Playlist';
    final ownerMap = json['owner'] as Map<String, dynamic>?;
    final owner = ownerMap?['display_name'] as String? ?? 'Spotify';
    final description = json['description'] as String?;

    String? artUrl;
    if (json['images'] is List && (json['images'] as List).isNotEmpty) {
      artUrl = json['images'][0]['url'] as String?;
    }

    final tracksList = <SpotifyTrack>[];
    if (json['tracks'] is Map && json['tracks']['items'] is List) {
      for (final item in json['tracks']['items']) {
        if (item is Map && item['track'] is Map) {
          final t = item['track'] as Map<String, dynamic>;
          tracksList.add(SpotifyTrack.fromJson(t));
        }
      }
    }

    final total = (json['tracks'] is Map) ? (json['tracks']['total'] as int? ?? tracksList.length) : tracksList.length;

    return SpotifyPlaylist(
      id: id,
      title: title,
      owner: owner,
      description: description,
      albumArtUrl: artUrl,
      totalTracks: total,
      tracks: tracksList,
    );
  }
}

/// Unified preview item for Universal Import Dialog
@immutable
class UniversalImportPreview {
  final SpotifyItemType type;
  final String title;
  final String subtitle;
  final String? coverUrl;
  final int trackCount;
  final Duration totalDuration;
  final List<SpotifyTrack> tracks;
  final String rawUrl;

  const UniversalImportPreview({
    required this.type,
    required this.title,
    required this.subtitle,
    this.coverUrl,
    required this.trackCount,
    required this.totalDuration,
    required this.tracks,
    required this.rawUrl,
  });
}
