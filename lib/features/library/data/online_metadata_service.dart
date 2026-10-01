import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../player/domain/track.dart';
import 'metadata_tagger_service.dart';

/// Source provider for online metadata candidate
enum MetadataSource {
  iTunes,
  musicBrainz,
  deezer,
  lrclib,
}

/// A matched online metadata candidate
class OnlineMetadataCandidate {
  final String title;
  final String artist;
  final String album;
  final String? albumArtist;
  final String? genre;
  final int? year;
  final int? trackNumber;
  final int? trackTotal;
  final int? discNumber;
  final int? discTotal;
  final String? artworkUrl;
  final MetadataSource source;
  final int? durationSeconds;
  final double confidenceScore;
  final String? lyrics;
  final bool hasSyncedLyrics;

  const OnlineMetadataCandidate({
    required this.title,
    required this.artist,
    required this.album,
    this.albumArtist,
    this.genre,
    this.year,
    this.trackNumber,
    this.trackTotal,
    this.discNumber,
    this.discTotal,
    this.artworkUrl,
    required this.source,
    this.durationSeconds,
    this.confidenceScore = 0.0,
    this.lyrics,
    this.hasSyncedLyrics = false,
  });

  /// Convert candidate into AudioTagData ready for applying & writing to file
  AudioTagData toAudioTagData({Uint8List? downloadedArtwork, String? artworkMime}) {
    return AudioTagData(
      title: title,
      artist: artist,
      album: album,
      albumArtist: albumArtist ?? artist,
      genre: genre,
      year: year,
      trackNumber: trackNumber,
      trackTotal: trackTotal,
      discNumber: discNumber,
      discTotal: discTotal,
      lyrics: lyrics,
      artworkBytes: downloadedArtwork,
      artworkMimeType: artworkMime ?? 'image/jpeg',
    );
  }

  OnlineMetadataCandidate copyWith({
    String? title,
    String? artist,
    String? album,
    String? albumArtist,
    String? genre,
    int? year,
    int? trackNumber,
    int? trackTotal,
    int? discNumber,
    int? discTotal,
    String? artworkUrl,
    MetadataSource? source,
    int? durationSeconds,
    double? confidenceScore,
    String? lyrics,
    bool? hasSyncedLyrics,
  }) {
    return OnlineMetadataCandidate(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      albumArtist: albumArtist ?? this.albumArtist,
      genre: genre ?? this.genre,
      year: year ?? this.year,
      trackNumber: trackNumber ?? this.trackNumber,
      trackTotal: trackTotal ?? this.trackTotal,
      discNumber: discNumber ?? this.discNumber,
      discTotal: discTotal ?? this.discTotal,
      artworkUrl: artworkUrl ?? this.artworkUrl,
      source: source ?? this.source,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      lyrics: lyrics ?? this.lyrics,
      hasSyncedLyrics: hasSyncedLyrics ?? this.hasSyncedLyrics,
    );
  }
}

/// Result of downloaded artwork image
class DownloadedArtwork {
  final Uint8List bytes;
  final String mimeType;

  const DownloadedArtwork({
    required this.bytes,
    required this.mimeType,
  });
}

/// Helper for cleaning and sanitizing dirty queries & filenames
class QuerySanitizer {
  const QuerySanitizer._();

  static final RegExp _extensionRegex = RegExp(r'\.(mp3|flac|wav|m4a|ogg|opus|aac|alac|aiff|dsd)$', caseSensitive: false);
  static final RegExp _leadingTrackNumRegex = RegExp(r'^\s*(track[\s._\-]*\d{1,3}|\d{1,3})[\s._\-]+', caseSensitive: false);
  static final RegExp _bracketInfoRegex = RegExp(
    r'(\[|\()(official\s*(audio|video|music\s*video|lyric\s*video)?|320\s*kbps|flac|hi-res|remaster(ed)?(\s*\d{4})?|hq|hd|audio|explicit|clean)(\]|\))',
    caseSensitive: false,
  );
  static final RegExp _trailingGarbageRegex = RegExp(r'[-_\s]+$');

  /// Clean dirty track titles or filenames into clean search query
  static String cleanQuery(String input) {
    if (input.trim().isEmpty) return '';

    var s = input.replaceAll(_extensionRegex, '');
    s = s.replaceAll(_bracketInfoRegex, ' ');
    s = s.replaceAll(_leadingTrackNumRegex, ' ');
    s = s.replaceAll('_', ' ');
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    s = s.replaceAll(_trailingGarbageRegex, '').trim();

    return s;
  }

  /// Try parsing artist and title from common filename patterns like "Artist - Title"
  static ({String? artist, String? title}) extractArtistAndTitle(String rawName) {
    final cleaned = cleanQuery(rawName);
    final parts = cleaned.split(RegExp(r'\s+-\s+'));
    if (parts.length >= 2) {
      final potentialArtist = parts[0].trim();
      final potentialTitle = parts.sublist(1).join(' - ').trim();
      if (potentialArtist.isNotEmpty && potentialTitle.isNotEmpty) {
        return (artist: potentialArtist, title: potentialTitle);
      }
    }
    return (artist: null, title: cleaned.isNotEmpty ? cleaned : null);
  }
}

/// Core service for searching online metadata, high-res covers, and lyrics
class OnlineMetadataService {
  final Dio _dio;

  OnlineMetadataService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 10),
                headers: {
                  'User-Agent': 'BaydevHiFi/1.0.0 (https://github.com/BayuKun28/BayHifi)',
                  'Accept': 'application/json',
                },
              ),
            );

  /// Search online metadata candidates across multiple providers (iTunes, MusicBrainz, Deezer)
  Future<List<OnlineMetadataCandidate>> searchCandidates({
    required String query,
    String? artistHint,
    String? albumHint,
    int? targetDurationSeconds,
    int limit = 15,
  }) async {
    final cleanQ = QuerySanitizer.cleanQuery(query);
    if (cleanQ.trim().isEmpty) return const [];

    final searchQuery = (artistHint != null &&
            artistHint.isNotEmpty &&
            !cleanQ.toLowerCase().contains(artistHint.toLowerCase()))
        ? '$artistHint $cleanQ'
        : cleanQ;

    final candidates = <OnlineMetadataCandidate>[];

    // Execute queries in parallel with fault-tolerance
    final futures = <Future<List<OnlineMetadataCandidate>>>[
      _searchITunes(searchQuery, targetDurationSeconds: targetDurationSeconds),
      _searchDeezer(searchQuery, targetDurationSeconds: targetDurationSeconds),
      _searchMusicBrainz(searchQuery, targetDurationSeconds: targetDurationSeconds),
    ];

    final results = await Future.wait(futures.map((f) => f.catchError((e) {
          debugPrint('[OnlineMetadataService] Provider search error: $e');
          return <OnlineMetadataCandidate>[];
        })));

    for (final list in results) {
      candidates.addAll(list);
    }

    // Deduplicate & score candidates
    final scored = _deduplicateAndScoreCandidates(
      candidates,
      cleanQuery: cleanQ,
      artistHint: artistHint,
      targetDurationSeconds: targetDurationSeconds,
    );

    return scored.take(limit).toList();
  }

  /// Search candidates for an existing Track domain object
  Future<List<OnlineMetadataCandidate>> searchCandidatesForTrack(
    Track track, {
    int limit = 15,
  }) async {
    String searchQuery;
    String? artistHint;

    if (track.filePath != null && track.filePath!.isNotEmpty) {
      final fileName = File(track.filePath!).uri.pathSegments.last;
      final extracted = QuerySanitizer.extractArtistAndTitle(fileName);
      if (extracted.artist != null && extracted.title != null) {
        searchQuery = '${extracted.artist} ${extracted.title}';
        artistHint = extracted.artist;
      } else {
        searchQuery = extracted.title ?? track.title;
      }
    } else {
      searchQuery = track.title;
      if (track.artist.isNotEmpty && track.artist.toLowerCase() != 'unknown artist') {
        artistHint = track.artist;
        searchQuery = '${track.artist} ${track.title}';
      }
    }

    final durationSec = track.duration.inSeconds > 0 ? track.duration.inSeconds : null;

    return searchCandidates(
      query: searchQuery,
      artistHint: artistHint,
      albumHint: track.album.isNotEmpty && track.album.toLowerCase() != 'unknown album' ? track.album : null,
      targetDurationSeconds: durationSec,
      limit: limit,
    );
  }

  /// 1. Query iTunes Search API (Ultra-fast, 1400x1400 artwork, rich track/disc data)
  Future<List<OnlineMetadataCandidate>> _searchITunes(
    String query, {
    int? targetDurationSeconds,
  }) async {
    try {
      final encoded = Uri.encodeComponent(query.trim());
      final url = 'https://itunes.apple.com/search?term=$encoded&entity=song&limit=10';
      final response = await _dio.get(url);

      if (response.statusCode != 200 || response.data == null) return const [];

      final data = response.data is String ? jsonDecode(response.data as String) : response.data;
      if (data is! Map<String, dynamic> || data['results'] is! List) return const [];

      final results = data['results'] as List;
      final list = <OnlineMetadataCandidate>[];

      for (final item in results) {
        if (item is! Map<String, dynamic>) continue;

        final trackName = item['trackName'] as String? ?? '';
        final artistName = item['artistName'] as String? ?? '';
        final collectionName = item['collectionName'] as String? ?? '';
        if (trackName.isEmpty || artistName.isEmpty) continue;

        // Upgrade iTunes artwork from 100x100 to 1400x1400
        String? artUrl = item['artworkUrl100'] as String?;
        if (artUrl != null && artUrl.isNotEmpty) {
          artUrl = artUrl.replaceAll('100x100bb', '1400x1400bb');
        }

        int? year;
        final releaseDate = item['releaseDate'] as String?;
        if (releaseDate != null && releaseDate.length >= 4) {
          year = int.tryParse(releaseDate.substring(0, 4));
        }

        int? durationSec;
        final millis = item['trackTimeMillis'] as num?;
        if (millis != null) {
          durationSec = (millis / 1000).round();
        }

        list.add(
          OnlineMetadataCandidate(
            title: trackName,
            artist: artistName,
            album: collectionName.isNotEmpty ? collectionName : trackName,
            albumArtist: item['collectionArtistName'] as String? ?? artistName,
            genre: item['primaryGenreName'] as String?,
            year: year,
            trackNumber: item['trackNumber'] as int?,
            trackTotal: item['trackCount'] as int?,
            discNumber: item['discNumber'] as int?,
            discTotal: item['discCount'] as int?,
            artworkUrl: artUrl,
            source: MetadataSource.iTunes,
            durationSeconds: durationSec,
          ),
        );
      }

      return list;
    } catch (e) {
      debugPrint('[OnlineMetadataService] iTunes search error: $e');
      return const [];
    }
  }

  /// 2. Query Deezer Search API (Great global & regional coverage, cover_xl 1000x1000)
  Future<List<OnlineMetadataCandidate>> _searchDeezer(
    String query, {
    int? targetDurationSeconds,
  }) async {
    try {
      final encoded = Uri.encodeComponent(query.trim());
      final url = 'https://api.deezer.com/search?q=$encoded&limit=8';
      final response = await _dio.get(url);

      if (response.statusCode != 200 || response.data == null) return const [];

      final data = response.data is String ? jsonDecode(response.data as String) : response.data;
      if (data is! Map<String, dynamic> || data['data'] is! List) return const [];

      final results = data['data'] as List;
      final list = <OnlineMetadataCandidate>[];

      for (final item in results) {
        if (item is! Map<String, dynamic>) continue;

        final trackName = item['title'] as String? ?? item['title_short'] as String? ?? '';
        final artistObj = item['artist'] as Map<String, dynamic>?;
        final albumObj = item['album'] as Map<String, dynamic>?;

        final artistName = artistObj?['name'] as String? ?? '';
        final albumName = albumObj?['title'] as String? ?? '';
        if (trackName.isEmpty || artistName.isEmpty) continue;

        final artUrl = albumObj?['cover_xl'] as String? ??
            albumObj?['cover_big'] as String? ??
            albumObj?['cover_medium'] as String?;

        final durationSec = item['duration'] as int?;

        list.add(
          OnlineMetadataCandidate(
            title: trackName,
            artist: artistName,
            album: albumName.isNotEmpty ? albumName : trackName,
            albumArtist: artistName,
            artworkUrl: artUrl,
            source: MetadataSource.deezer,
            durationSeconds: durationSec,
          ),
        );
      }

      return list;
    } catch (e) {
      debugPrint('[OnlineMetadataService] Deezer search error: $e');
      return const [];
    }
  }

  /// 3. Query MusicBrainz API + Cover Art Archive
  Future<List<OnlineMetadataCandidate>> _searchMusicBrainz(
    String query, {
    int? targetDurationSeconds,
  }) async {
    try {
      final encoded = Uri.encodeComponent(query.trim());
      final url = 'https://musicbrainz.org/ws/2/recording/?query=$encoded&fmt=json&limit=6';
      final response = await _dio.get(url);

      if (response.statusCode != 200 || response.data == null) return const [];

      final data = response.data is String ? jsonDecode(response.data as String) : response.data;
      if (data is! Map<String, dynamic> || data['recordings'] is! List) return const [];

      final recordings = data['recordings'] as List;
      final list = <OnlineMetadataCandidate>[];

      for (final rec in recordings) {
        if (rec is! Map<String, dynamic>) continue;

        final title = rec['title'] as String? ?? '';
        final artistCredits = rec['artist-credit'] as List?;
        final artistName = (artistCredits != null && artistCredits.isNotEmpty)
            ? (artistCredits.first['name'] as String? ?? '')
            : '';

        if (title.isEmpty || artistName.isEmpty) continue;

        String albumName = title;
        int? year;
        String? releaseId;
        int? trackNum;
        int? trackTot;

        final releases = rec['releases'] as List?;
        if (releases != null && releases.isNotEmpty) {
          final rel = releases.first as Map<String, dynamic>;
          albumName = rel['title'] as String? ?? title;
          releaseId = rel['id'] as String?;
          final date = rel['date'] as String?;
          if (date != null && date.length >= 4) {
            year = int.tryParse(date.substring(0, 4));
          }
          final media = rel['media'] as List?;
          if (media != null && media.isNotEmpty) {
            final med = media.first as Map<String, dynamic>;
            trackTot = med['track-count'] as int?;
          }
        }

        String? artUrl;
        if (releaseId != null) {
          artUrl = 'https://coverartarchive.org/release/$releaseId/front-500.jpg';
        }

        int? durationSec;
        final lengthMs = rec['length'] as num?;
        if (lengthMs != null) {
          durationSec = (lengthMs / 1000).round();
        }

        list.add(
          OnlineMetadataCandidate(
            title: title,
            artist: artistName,
            album: albumName,
            albumArtist: artistName,
            year: year,
            trackNumber: trackNum,
            trackTotal: trackTot,
            artworkUrl: artUrl,
            source: MetadataSource.musicBrainz,
            durationSeconds: durationSec,
          ),
        );
      }

      return list;
    } catch (e) {
      debugPrint('[OnlineMetadataService] MusicBrainz search error: $e');
      return const [];
    }
  }

  /// Download high-res artwork bytes directly from artwork URL
  Future<DownloadedArtwork?> downloadArtwork(String artworkUrl) async {
    try {
      final response = await _dio.get<List<int>>(
        artworkUrl,
        options: Options(
          responseType: ResponseType.bytes,
          followRedirects: true,
          validateStatus: (status) => status != null && status < 400,
        ),
      );

      if (response.data != null && response.data!.isNotEmpty) {
        final bytes = Uint8List.fromList(response.data!);
        final isPng = artworkUrl.toLowerCase().contains('.png') ||
            (bytes.length > 8 && bytes[0] == 0x89 && bytes[1] == 0x50);
        return DownloadedArtwork(
          bytes: bytes,
          mimeType: isPng ? 'image/png' : 'image/jpeg',
        );
      }
    } catch (e) {
      debugPrint('[OnlineMetadataService] Artwork download failed ($artworkUrl): $e');
    }
    return null;
  }

  /// Query LRCLIB for synced (.lrc) or plain text lyrics
  Future<({String? lyrics, bool isSynced})> fetchLyrics({
    required String title,
    required String artist,
    String? album,
    int? durationSeconds,
  }) async {
    try {
      final params = <String, dynamic>{
        'track_name': title,
        'artist_name': artist,
      };
      if (album != null && album.isNotEmpty) {
        params['album_name'] = album;
      }
      if (durationSeconds != null && durationSeconds > 0) {
        params['duration'] = durationSeconds;
      }

      final response = await _dio.get(
        'https://lrclib.net/api/get',
        queryParameters: params,
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final data = response.data as Map<String, dynamic>;
        final synced = data['syncedLyrics'] as String?;
        if (synced != null && synced.trim().isNotEmpty) {
          return (lyrics: synced.trim(), isSynced: true);
        }
        final plain = data['plainLyrics'] as String?;
        if (plain != null && plain.trim().isNotEmpty) {
          return (lyrics: plain.trim(), isSynced: false);
        }
      }

      // Fallback search query on LRCLIB
      final searchRes = await _dio.get(
        'https://lrclib.net/api/search',
        queryParameters: {'q': '$artist $title'},
      );

      if (searchRes.statusCode == 200 && searchRes.data is List && (searchRes.data as List).isNotEmpty) {
        final first = (searchRes.data as List).first as Map<String, dynamic>;
        final synced = first['syncedLyrics'] as String?;
        if (synced != null && synced.trim().isNotEmpty) {
          return (lyrics: synced.trim(), isSynced: true);
        }
        final plain = first['plainLyrics'] as String?;
        if (plain != null && plain.trim().isNotEmpty) {
          return (lyrics: plain.trim(), isSynced: false);
        }
      }
    } catch (e) {
      debugPrint('[OnlineMetadataService] LRCLIB lyrics query notice: $e');
    }
    return (lyrics: null, isSynced: false);
  }

  /// Deduplicate and calculate match confidence score for candidates
  List<OnlineMetadataCandidate> _deduplicateAndScoreCandidates(
    List<OnlineMetadataCandidate> candidates, {
    required String cleanQuery,
    String? artistHint,
    int? targetDurationSeconds,
  }) {
    final seen = <String, OnlineMetadataCandidate>{};

    for (final c in candidates) {
      final key = '${c.title.trim().toLowerCase()}__${c.artist.trim().toLowerCase()}__${c.album.trim().toLowerCase()}';
      final score = _calculateConfidence(
        c,
        cleanQuery: cleanQuery,
        artistHint: artistHint,
        targetDurationSeconds: targetDurationSeconds,
      );

      final scoredCandidate = c.copyWith(confidenceScore: score);

      if (!seen.containsKey(key) || (seen[key]!.confidenceScore < score)) {
        seen[key] = scoredCandidate;
      }
    }

    final list = seen.values.toList();
    list.sort((a, b) => b.confidenceScore.compareTo(a.confidenceScore));
    return list;
  }

  /// Calculate confidence score from 0.0 to 1.0
  double _calculateConfidence(
    OnlineMetadataCandidate c, {
    required String cleanQuery,
    String? artistHint,
    int? targetDurationSeconds,
  }) {
    double score = 0.5; // Base confidence

    final qLower = cleanQuery.toLowerCase();
    final tLower = c.title.toLowerCase();
    final aLower = c.artist.toLowerCase();

    // Exact or substring title match
    if (tLower == qLower) {
      score += 0.30;
    } else if (qLower.contains(tLower) || tLower.contains(qLower)) {
      score += 0.18;
    }

    // Artist hint match
    if (artistHint != null && artistHint.isNotEmpty) {
      final artLower = artistHint.toLowerCase();
      if (aLower == artLower) {
        score += 0.25;
      } else if (aLower.contains(artLower) || artLower.contains(aLower)) {
        score += 0.12;
      }
    } else if (qLower.contains(aLower)) {
      score += 0.15;
    }

    // Duration proximity tolerance (+/- 5 seconds)
    if (targetDurationSeconds != null && c.durationSeconds != null) {
      final diff = (targetDurationSeconds - c.durationSeconds!).abs();
      if (diff <= 3) {
        score += 0.20;
      } else if (diff <= 7) {
        score += 0.10;
      } else if (diff > 25) {
        score -= 0.15;
      }
    }

    // Bonus if artwork is available
    if (c.artworkUrl != null && c.artworkUrl!.isNotEmpty) {
      score += 0.05;
    }

    return score.clamp(0.10, 1.0);
  }
}
