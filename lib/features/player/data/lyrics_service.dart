import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../core/database/local_persistence_service.dart';
import '../domain/lyrics_line.dart';
import '../domain/track.dart';

enum LyricsSource {
  embedded,
  sidecarFile,
  cached,
  onlineLrclib,
  none,
}

class LyricsResult {
  final String rawLyrics;
  final List<LyricsLine> lines;
  final bool isSynced;
  final LyricsSource source;
  final String? trackName;
  final String? artistName;

  const LyricsResult({
    required this.rawLyrics,
    required this.lines,
    required this.isSynced,
    required this.source,
    this.trackName,
    this.artistName,
  });

  const LyricsResult.empty()
      : rawLyrics = '',
        lines = const [],
        isSynced = false,
        source = LyricsSource.none,
        trackName = null,
        artistName = null;

  bool get isEmpty => rawLyrics.isEmpty && lines.isEmpty;
  bool get isNotEmpty => !isEmpty;
}

/// Service for fetching, parsing, and caching synchronized LRC and plain lyrics.
class LyricsService {
  static LyricsService? _instance;
  static LyricsService get instance => _instance ??= LyricsService._();

  LyricsService._({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: 'https://lrclib.net/api',
                connectTimeout: const Duration(seconds: 6),
                receiveTimeout: const Duration(seconds: 6),
                headers: {
                  'User-Agent': 'BaydevHiFi/1.0.0 (https://github.com/baydev/baydev_hifi)',
                },
              ),
            );

  final Dio _dio;
  final Set<String> _negativeCache = {};

  /// Resolves lyrics for a track with a 4-tier fallback:
  /// 1. Embedded track metadata (`track.lyrics`)
  /// 2. Sidecar `.lrc` file beside the audio track
  /// 3. Locally cached lyrics in `LocalPersistenceService`
  /// 4. Online LRCLIB database query (`/api/get` -> `/api/search`)
  Future<LyricsResult> getLyricsForTrack(Track track) async {
    // 1. Embedded metadata
    if (track.lyrics != null && track.lyrics!.trim().isNotEmpty) {
      final text = track.lyrics!.trim();
      final parsed = LrcParser.parse(text);
      final isSynced = parsed.isNotEmpty;
      return LyricsResult(
        rawLyrics: text,
        lines: parsed,
        isSynced: isSynced,
        source: LyricsSource.embedded,
        trackName: track.title,
        artistName: track.artist,
      );
    }

    // 2. Sidecar .lrc file
    if (track.filePath != null && track.filePath!.isNotEmpty) {
      try {
        final audioFile = File(track.filePath!);
        final parent = audioFile.parent;
        final baseName = audioFile.uri.pathSegments.last.replaceAll(
          RegExp(r'\.[a-zA-Z0-9]+$'),
          '',
        );
        final lrcFile = File('${parent.path}${Platform.pathSeparator}$baseName.lrc');
        if (await lrcFile.exists()) {
          final content = await lrcFile.readAsString();
          if (content.trim().isNotEmpty) {
            final parsed = LrcParser.parse(content);
            return LyricsResult(
              rawLyrics: content,
              lines: parsed,
              isSynced: parsed.isNotEmpty,
              source: LyricsSource.sidecarFile,
              trackName: track.title,
              artistName: track.artist,
            );
          }
        }
      } catch (e) {
        debugPrint('[LyricsService] Sidecar check error: $e');
      }
    }

    // 3. Local persistence cache
    final cacheKey = 'lyrics_cache_${track.id}';
    final cached = LocalPersistenceService.instance.getSetting<String>(cacheKey);
    if (cached != null && cached.trim().isNotEmpty) {
      final parsed = LrcParser.parse(cached);
      return LyricsResult(
        rawLyrics: cached,
        lines: parsed,
        isSynced: parsed.isNotEmpty,
        source: LyricsSource.cached,
        trackName: track.title,
        artistName: track.artist,
      );
    }

    // 4. Check negative cache
    if (_negativeCache.contains(track.id)) {
      return const LyricsResult.empty();
    }

    // 5. Query online LRCLIB
    try {
      final onlineResult = await _fetchFromLrclib(track);
      if (onlineResult != null && onlineResult.isNotEmpty) {
        // Cache to persistence
        await LocalPersistenceService.instance.saveSetting(
          cacheKey,
          onlineResult.rawLyrics,
        );
        return onlineResult;
      }
    } catch (e) {
      debugPrint('[LyricsService] Online LRCLIB fetch error for ${track.title}: $e');
    }

    _negativeCache.add(track.id);
    return const LyricsResult.empty();
  }

  Future<LyricsResult?> _fetchFromLrclib(Track track) async {
    final cleanTitle = _sanitizeQuery(track.title);
    final cleanArtist = _sanitizeQuery(track.artist);
    final cleanAlbum = _sanitizeQuery(track.album);

    if (cleanTitle.isEmpty || cleanTitle.toLowerCase() == 'unknown') {
      return null;
    }

    // Attempt 1: Exact GET
    try {
      final queryParams = <String, dynamic>{
        'track_name': cleanTitle,
        'artist_name': cleanArtist,
      };
      if (cleanAlbum.isNotEmpty && cleanAlbum.toLowerCase() != 'unknown') {
        queryParams['album_name'] = cleanAlbum;
      }
      if (track.duration.inSeconds > 0) {
        queryParams['duration'] = track.duration.inSeconds;
      }

      final response = await _dio.get(
        '/get',
        queryParameters: queryParams,
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode == 200 && response.data is Map) {
        final data = response.data as Map<String, dynamic>;
        final parsed = _extractLyricsData(data);
        if (parsed != null) return parsed;
      }
    } catch (e) {
      debugPrint('[LyricsService] Direct GET attempt failed: $e');
    }

    // Attempt 2: Search fallback
    try {
      final searchQuery = cleanArtist.isNotEmpty && cleanArtist.toLowerCase() != 'unknown'
          ? '$cleanArtist $cleanTitle'
          : cleanTitle;

      final searchResponse = await _dio.get(
        '/search',
        queryParameters: {'q': searchQuery},
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (searchResponse.statusCode == 200 && searchResponse.data is List) {
        final list = searchResponse.data as List;
        if (list.isNotEmpty && list.first is Map) {
          final bestMatch = list.first as Map<String, dynamic>;
          final parsed = _extractLyricsData(bestMatch);
          if (parsed != null) return parsed;
        }
      }
    } catch (e) {
      debugPrint('[LyricsService] Search fallback failed: $e');
    }

    return null;
  }

  LyricsResult? _extractLyricsData(Map<String, dynamic> data) {
    final synced = data['syncedLyrics'] as String?;
    final plain = data['plainLyrics'] as String?;
    final trackName = data['trackName'] as String? ?? data['name'] as String?;
    final artistName = data['artistName'] as String?;

    if (synced != null && synced.trim().isNotEmpty) {
      final parsed = LrcParser.parse(synced);
      return LyricsResult(
        rawLyrics: synced,
        lines: parsed,
        isSynced: parsed.isNotEmpty,
        source: LyricsSource.onlineLrclib,
        trackName: trackName,
        artistName: artistName,
      );
    }

    if (plain != null && plain.trim().isNotEmpty) {
      // Create faux lines or empty timed lines for plain reader
      final rawLines = plain.split('\n');
      final lines = <LyricsLine>[];
      for (int i = 0; i < rawLines.length; i++) {
        final line = rawLines[i].trim();
        if (line.isNotEmpty) {
          lines.add(LyricsLine(timestamp: Duration(seconds: i * 4), text: line));
        }
      }
      return LyricsResult(
        rawLyrics: plain,
        lines: lines,
        isSynced: false,
        source: LyricsSource.onlineLrclib,
        trackName: trackName,
        artistName: artistName,
      );
    }

    return null;
  }

  String _sanitizeQuery(String input) {
    var s = input.trim();
    // Remove (feat. ...), [Official Video], etc.
    s = s.replaceAll(RegExp(r'\((feat\.|ft\.|official|audio|remaster).*?\)', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'\[(feat\.|ft\.|official|audio|flac|wav|remaster).*?\]', caseSensitive: false), '');
    s = s.replaceAll(RegExp(r'\.(mp3|flac|wav|ogg|opus|m4a|dsd)$', caseSensitive: false), '');
    return s.trim();
  }

  void clearCacheForTrack(String trackId) {
    _negativeCache.remove(trackId);
    LocalPersistenceService.instance.saveSetting('lyrics_cache_$trackId', null);
  }
}
