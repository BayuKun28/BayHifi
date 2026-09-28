import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '../../player/domain/track.dart';
import 'webm_to_ogg_remuxer.dart';

/// Service for YouTube & YouTube Music audio streaming, search, and metadata extraction.
/// Integrates with Baydev HiFi's C++ SoLoud DSP mastering engine and AudioCacheService.
class YouTubeMusicService {
  YouTubeMusicService._();
  static final YouTubeMusicService instance = YouTubeMusicService._();

  YoutubeExplode? _yt;
  YoutubeExplode get _client => _yt ??= YoutubeExplode();

  /// Cache of recently resolved audio stream URLs: videoId -> (url, expiryTimestamp)
  final Map<String, ({String url, DateTime expiresAt})> _urlCache = {};

  /// Parses string durations like "3:45" or "1:24:10" to Duration.
  Duration _parseDuration(String? durStr) {
    if (durStr == null || durStr.trim().isEmpty) return Duration.zero;
    final parts = durStr.trim().split(':').map((p) => int.tryParse(p) ?? 0).toList();
    if (parts.length == 2) {
      return Duration(minutes: parts[0], seconds: parts[1]);
    } else if (parts.length == 3) {
      return Duration(hours: parts[0], minutes: parts[1], seconds: parts[2]);
    }
    return Duration.zero;
  }

  /// Searches YouTube Music for songs, videos, and music content.
  Future<List<Track>> search(String query, {int limit = 25}) async {
    if (query.trim().isEmpty) return [];

    try {
      final tracks = <Track>[];
      final seenIds = <String>{};

      // 1. Try searchContent which returns SearchResultItem without uploadDate format errors
      try {
        final contentResults = await _client.search.searchContent(query);
        for (final item in contentResults) {
          if (tracks.length >= limit) break;
          if (item is SearchVideo) {
            if (seenIds.add(item.id.value)) {
              tracks.add(_mapSearchVideoToTrack(item));
            }
          } else if (item is SearchPlaylist) {
            try {
              int count = 0;
              await for (final v in _client.playlists.getVideos(item.id)) {
                if (seenIds.add(v.id.value)) {
                  tracks.add(_mapVideoToTrack(v));
                  count++;
                }
                if (count >= 4 || tracks.length >= limit) break;
              }
            } catch (_) {}
          }
        }
      } catch (contentErr) {
        debugPrint('[YouTubeMusicService] searchContent notice: $contentErr');
      }

      if (tracks.isNotEmpty) {
        return tracks;
      }

      // 2. Fallback to basic search if searchContent was empty
      final searchResults = await _client.search.search(query);
      for (final video in searchResults) {
        if (tracks.length >= limit) break;
        if (seenIds.add(video.id.value)) {
          tracks.add(_mapVideoToTrack(video));
        }
      }
      return tracks;
    } catch (e, st) {
      debugPrint('[YouTubeMusicService] Search error: $e\n$st');
      return [];
    }
  }

  /// Resolves the highest quality direct audio stream URL (Opus 160kbps or AAC 256kbps).
  Future<String?> getAudioStreamUrl(String videoIdOrTrackId) async {
    final videoId = videoIdOrTrackId.replaceFirst('yt_', '');

    // Check memory cache (stream URLs are valid for ~6 hours)
    final cached = _urlCache[videoId];
    if (cached != null && DateTime.now().isBefore(cached.expiresAt)) {
      return cached.url;
    }

    try {
      final manifest = await _client.videos.streamsClient.getManifest(videoId);
      final audioStreams = manifest.audioOnly;

      if (audioStreams.isEmpty) {
        debugPrint('[YouTubeMusicService] No audio-only streams found for $videoId');
        return null;
      }

      // Prioritize Opus (WebM) audio stream for highest fidelity and SoLoud compatibility
      AudioStreamInfo? bestStream;
      try {
        final opusStreams = audioStreams.where((s) => s.audioCodec.toLowerCase().contains('opus'));
        if (opusStreams.isNotEmpty) {
          bestStream = opusStreams.withHighestBitrate();
        }
      } catch (_) {}

      // Fallback to highest bitrate audio stream
      bestStream ??= audioStreams.withHighestBitrate();

      final streamUrl = bestStream.url.toString();
      _urlCache[videoId] = (
        url: streamUrl,
        expiresAt: DateTime.now().add(const Duration(hours: 4)),
      );

      return streamUrl;
    } catch (e, st) {
      debugPrint('[YouTubeMusicService] Error extracting audio stream URL for $videoId: $e\n$st');
      return null;
    }
  }

  /// Returns a live `Stream<List<int>>` of audio chunks using YoutubeExplode streamsClient
  Future<Stream<List<int>>?> getAudioByteStream(String videoIdOrTrackId) async {
    final videoId = videoIdOrTrackId.replaceFirst('yt_', '');
    try {
      final manifest = await _client.videos.streamsClient.getManifest(videoId);
      final audioStreams = manifest.audioOnly;
      if (audioStreams.isEmpty) return null;

      AudioStreamInfo? bestStream;
      try {
        final opusStreams = audioStreams.where((s) => s.audioCodec.toLowerCase().contains('opus'));
        if (opusStreams.isNotEmpty) {
          bestStream = opusStreams.withHighestBitrate();
        }
      } catch (_) {}
      bestStream ??= audioStreams.withHighestBitrate();

      return _client.videos.streamsClient.get(bestStream);
    } catch (e, st) {
      debugPrint('[YouTubeMusicService] Error getting audio stream for $videoId: $e\n$st');
      return null;
    }
  }

  /// Returns a live `Stream<Uint8List>` of Ogg Opus audio chunks, remuxed in real-time from WebM Opus.
  /// This allows direct, low-latency streaming into flutter_soloud's C++ audio decoding engine.
  Future<Stream<Uint8List>?> getOggOpusAudioByteStream(String videoIdOrTrackId) async {
    final videoId = videoIdOrTrackId.replaceFirst('yt_', '');
    try {
      final manifest = await _client.videos.streamsClient.getManifest(videoId);
      final audioStreams = manifest.audioOnly;
      if (audioStreams.isEmpty) return null;

      AudioStreamInfo? bestStream;
      try {
        final opusStreams = audioStreams.where((s) => s.audioCodec.toLowerCase().contains('opus'));
        if (opusStreams.isNotEmpty) {
          bestStream = opusStreams.withHighestBitrate();
        }
      } catch (_) {}
      bestStream ??= audioStreams.withHighestBitrate();

      final rawStream = _client.videos.streamsClient.get(bestStream);
      final isOpusOrWebm = bestStream.audioCodec.toLowerCase().contains('opus') ||
          bestStream.container.name.toLowerCase().contains('webm');

      if (isOpusOrWebm) {
        return WebmToOggRemuxer.remuxStream(rawStream);
      } else {
        return rawStream.map((chunk) => chunk is Uint8List ? chunk : Uint8List.fromList(chunk));
      }
    } catch (e, st) {
      debugPrint('[YouTubeMusicService] Error getting Ogg Opus audio stream for $videoId: $e\n$st');
      return null;
    }
  }

  /// Downloads audio directly using YoutubeExplode streamsClient into targetFile,
  /// remuxing WebM Opus to standard Ogg Opus on the fly for native SoLoud compatibility.
  Future<String?> downloadAudio(
    String videoIdOrTrackId,
    File targetFile, {
    void Function(double progress)? onProgress,
  }) async {
    final videoId = videoIdOrTrackId.replaceFirst('yt_', '');
    try {
      final manifest = await _client.videos.streamsClient.getManifest(videoId);
      final audioStreams = manifest.audioOnly;
      if (audioStreams.isEmpty) {
        debugPrint('[YouTubeMusicService] No audio streams found for $videoId');
        return null;
      }

      AudioStreamInfo? bestStream;
      try {
        final opusStreams = audioStreams.where((s) => s.audioCodec.toLowerCase().contains('opus'));
        if (opusStreams.isNotEmpty) {
          bestStream = opusStreams.withHighestBitrate();
        }
      } catch (_) {}
      bestStream ??= audioStreams.withHighestBitrate();

      final rawStream = _client.videos.streamsClient.get(bestStream);
      final totalBytes = bestStream.size.totalBytes;
      int received = 0;

      if (!await targetFile.parent.exists()) {
        await targetFile.parent.create(recursive: true);
      }
      if (await targetFile.exists()) {
        await targetFile.delete();
      }

      final isOpusOrWebm = bestStream.audioCodec.toLowerCase().contains('opus') ||
          bestStream.container.name.toLowerCase().contains('webm');

      final streamToSave = isOpusOrWebm
          ? WebmToOggRemuxer.remuxStream(rawStream)
          : rawStream.map((chunk) => chunk is Uint8List ? chunk : Uint8List.fromList(chunk));

      final sink = targetFile.openWrite();
      await for (final chunk in streamToSave) {
        sink.add(chunk);
        received += chunk.length;
        if (totalBytes > 0) {
          onProgress?.call((received / totalBytes).clamp(0.0, 1.0));
        }
      }
      await sink.flush();
      await sink.close();

      if (await targetFile.exists() && await targetFile.length() > 0) {
        return targetFile.path;
      }
      return null;
    } catch (e, st) {
      debugPrint('[YouTubeMusicService] Download error for $videoId: $e\n$st');
      return null;
    }
  }

  /// Fetches tracks from a YouTube Music or YouTube playlist URL/ID.
  Future<List<Track>> getPlaylistTracks(String playlistIdOrUrl, {int limit = 100}) async {
    final playlistId = _extractPlaylistId(playlistIdOrUrl);
    if (playlistId == null) return [];

    try {
      final tracks = <Track>[];
      await for (final video in _client.playlists.getVideos(playlistId)) {
        if (tracks.length >= limit) break;
        tracks.add(_mapVideoToTrack(video));
      }
      return tracks;
    } catch (e, st) {
      debugPrint('[YouTubeMusicService] Error fetching playlist $playlistId: $e\n$st');
      return [];
    }
  }

  /// Generates a Smart Track Radio queue by querying related songs.
  Future<List<Track>> getRelatedTracks(String videoIdOrTrackId, {int limit = 20}) async {
    final videoId = videoIdOrTrackId.replaceFirst('yt_', '');

    try {
      final video = await _client.videos.get(videoId);
      final related = await _client.videos.getRelatedVideos(video);

      if (related == null || related.isEmpty) {
        // Fallback to searching with artist name + music
        return await search('${video.author} music', limit: limit);
      }

      final tracks = <Track>[];
      for (final rel in related) {
        if (tracks.length >= limit) break;
        tracks.add(_mapVideoToTrack(rel));
      }
      return tracks;
    } catch (e, st) {
      debugPrint('[YouTubeMusicService] Error fetching related tracks for $videoId: $e\n$st');
      return [];
    }
  }

  /// Fetches top trending / popular music charts.
  Future<List<Track>> getTrendingMusic({int limit = 30}) async {
    try {
      final queries = [
        'Top Hits 2026',
        'Global Top Music',
        'Trending Music',
        'Official Music Video',
      ];

      final tracks = <Track>[];
      final seenIds = <String>{};

      for (final q in queries) {
        try {
          final res = await _client.search.searchContent(q);
          for (final item in res) {
            if (tracks.length >= limit) break;
            if (item is SearchVideo) {
              if (seenIds.add(item.id.value)) {
                tracks.add(_mapSearchVideoToTrack(item));
              }
            } else if (item is SearchPlaylist) {
              try {
                int count = 0;
                await for (final v in _client.playlists.getVideos(item.id)) {
                  if (seenIds.add(v.id.value)) {
                    tracks.add(_mapVideoToTrack(v));
                    count++;
                  }
                  if (count >= 4 || tracks.length >= limit) break;
                }
              } catch (_) {}
            }
          }
        } catch (queryErr) {
          debugPrint('[YouTubeMusicService] Trending query error on "$q": $queryErr');
        }
        if (tracks.length >= limit) break;
      }

      return tracks;
    } catch (e, st) {
      debugPrint('[YouTubeMusicService] Error fetching trending music: $e\n$st');
      return [];
    }
  }

  /// Maps a YouTube Explode SearchVideo object to Baydev HiFi's Track domain entity.
  Track _mapSearchVideoToTrack(SearchVideo video) {
    final parsed = cleanMetadata(video.title, video.author);
    final thumb = video.thumbnails.isNotEmpty
        ? video.thumbnails.last.url.toString()
        : 'https://i.ytimg.com/vi/${video.id.value}/hqdefault.jpg';

    return Track(
      id: 'yt_${video.id.value}',
      title: parsed.title,
      artist: parsed.artist,
      album: 'YouTube Music',
      duration: _parseDuration(video.duration),
      albumArtUrl: thumb,
      format: AudioFormat.opus,
      sampleRate: 48000,
      bitDepth: 16,
      bitrate: 160000,
      genre: 'Streaming',
    );
  }

  /// Maps a YouTube Explode Video object to Baydev HiFi's Track domain entity.
  Track _mapVideoToTrack(Video video) {
    final parsed = cleanMetadata(video.title, video.author);

    return Track(
      id: 'yt_${video.id.value}',
      title: parsed.title,
      artist: parsed.artist,
      album: 'YouTube Music',
      duration: video.duration ?? Duration.zero,
      albumArtUrl: video.thumbnails.highResUrl,
      format: AudioFormat.opus,
      sampleRate: 48000,
      bitDepth: 16,
      bitrate: 160000,
      genre: 'Streaming',
    );
  }

  /// Sanitizes YouTube video titles and extracts clean Artist and Track Title.
  static ({String artist, String title}) cleanMetadata(String rawTitle, String channelName) {
    String clean = rawTitle;

    // Remove noise in brackets and parentheses
    clean = clean.replaceAll(
      RegExp(r'\[[^\]]*?(Official|Music|Video|Audio|Lyric|Lyrics|HD|HQ|4K|Remaster|Visualizer|MV|Performance)[^\]]*?\]',
          caseSensitive: false),
      '',
    );
    clean = clean.replaceAll(
      RegExp(r'\([^\)]*?(Official|Music|Video|Audio|Lyric|Lyrics|HD|HQ|4K|Remaster|Visualizer|MV|Performance)[^\)]*?\)',
          caseSensitive: false),
      '',
    );
    clean = clean.replaceAll(RegExp(r'\[\s*\]|\(\s*\)'), '');

    // Check if title has "Artist - Title" format
    if (clean.contains(' - ')) {
      final parts = clean.split(' - ');
      final artistPart = parts[0].trim();
      final titlePart = parts.sublist(1).join(' - ').trim();

      if (artistPart.isNotEmpty && titlePart.isNotEmpty) {
        return (
          artist: _stripChannelSuffixes(artistPart),
          title: _cleanTrackTitle(titlePart),
        );
      }
    }

    // Check if title has "Artist : Title" format
    if (clean.contains(' : ')) {
      final parts = clean.split(' : ');
      final artistPart = parts[0].trim();
      final titlePart = parts.sublist(1).join(' : ').trim();

      if (artistPart.isNotEmpty && titlePart.isNotEmpty) {
        return (
          artist: _stripChannelSuffixes(artistPart),
          title: _cleanTrackTitle(titlePart),
        );
      }
    }

    return (
      artist: _stripChannelSuffixes(channelName),
      title: _cleanTrackTitle(clean),
    );
  }

  static String _stripChannelSuffixes(String name) {
    return name
        .replaceAll(RegExp(r' - Topic$', caseSensitive: false), '')
        .replaceAll(RegExp(r'VEVO$', caseSensitive: false), '')
        .replaceAll(RegExp(r'Official Channel$', caseSensitive: false), '')
        .trim();
  }

  static String _cleanTrackTitle(String title) {
    return title
        .replaceAll(RegExp(r'^\d+[\.\-\s]+'), '') // strip leading numbers like "01. "
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  static String? _extractPlaylistId(String input) {
    final trimmed = input.trim();
    if (!trimmed.contains('http')) return trimmed;

    final uri = Uri.tryParse(trimmed);
    if (uri != null && uri.queryParameters.containsKey('list')) {
      return uri.queryParameters['list'];
    }
    return null;
  }

  void dispose() {
    _yt?.close();
    _yt = null;
    _urlCache.clear();
  }
}
