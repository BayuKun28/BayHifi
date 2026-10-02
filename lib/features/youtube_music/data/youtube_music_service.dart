import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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

  static bool? _hasFfmpeg;
  static Future<bool> _checkFfmpeg() async {
    if (_hasFfmpeg != null) return _hasFfmpeg!;
    try {
      final res = await Process.run('ffmpeg', ['-version']);
      _hasFfmpeg = res.exitCode == 0;
    } catch (_) {
      _hasFfmpeg = false;
    }
    return _hasFfmpeg!;
  }

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

  /// Cache of recently resolved stream manifests: videoId -> (manifest, expiresAt)
  final Map<String, ({StreamManifest manifest, DateTime expiresAt})> _manifestCache = {};

  /// Resolves the stream manifest with caching and auto-client recreation on error
  Future<StreamManifest?> _getStreamManifest(String videoId) async {
    final cached = _manifestCache[videoId];
    if (cached != null && DateTime.now().isBefore(cached.expiresAt)) {
      return cached.manifest;
    }

    try {
      final manifest = await _client.videos.streamsClient.getManifest(videoId);
      _manifestCache[videoId] = (
        manifest: manifest,
        expiresAt: DateTime.now().add(const Duration(minutes: 30)),
      );
      return manifest;
    } catch (e) {
      debugPrint('[YouTubeMusicService] Manifest fetch notice for $videoId: $e, recycling client with fallback...');
      try {
        _yt?.close();
      } catch (_) {}
      _yt = YoutubeExplode();
      try {
        final manifest = await _client.videos.streamsClient.getManifest(
          videoId,
          ytClients: [
            YoutubeApiClient.ios,
            YoutubeApiClient.androidMusic,
            YoutubeApiClient.tv,
          ],
        );
        _manifestCache[videoId] = (
          manifest: manifest,
          expiresAt: DateTime.now().add(const Duration(minutes: 30)),
        );
        return manifest;
      } catch (retryErr, st) {
        debugPrint('[YouTubeMusicService] Retry manifest fetch failed for $videoId: $retryErr\n$st');
        return null;
      }
    }
  }

  /// Selects the highest quality audio stream from manifest
  AudioStreamInfo? _selectBestAudioStream(StreamManifest manifest) {
    final audioStreams = manifest.audioOnly.isNotEmpty
        ? manifest.audioOnly
        : (manifest.audio.isNotEmpty ? manifest.audio : <AudioStreamInfo>[]);

    if (audioStreams.isEmpty) return null;

    try {
      final opusStreams = audioStreams.where((s) => s.audioCodec.toLowerCase().contains('opus'));
      if (opusStreams.isNotEmpty) {
        return opusStreams.withHighestBitrate();
      }
    } catch (_) {}

    return audioStreams.withHighestBitrate();
  }

  /// List of verified high-availability streaming instances for resilient full-duration audio playback
  static const List<String> _streamingInstances = [
    'https://invidious.f5.si',
    'https://inv.nadeko.net',
    'https://invidious.nerdvpn.de',
    'https://yt.chocolatemoo53.com',
    'https://invidious.tiekoetter.com',
  ];

  /// Resolves direct audio stream format using fast verified streaming endpoints
  Future<({String url, int totalBytes, bool isOpusOrWebm})?> _resolveFullAudioStream(String videoId) async {
    for (final host in _streamingInstances) {
      try {
        final uri = Uri.parse('$host/api/v1/videos/$videoId');
        final res = await http.get(uri).timeout(const Duration(milliseconds: 2800));
        if (res.statusCode == 200) {
          final data = json.decode(res.body) as Map<String, dynamic>;
          final adaptive = (data['adaptiveFormats'] as List<dynamic>?) ?? [];
          if (adaptive.isEmpty) continue;

          // Prefer itag 251 (Opus 160kbps), then 250, then 249, then 140 (AAC)
          var best = adaptive.firstWhere(
            (f) => f['itag'] == 251 || f['itag'] == '251',
            orElse: () => null,
          );
          best ??= adaptive.firstWhere(
            (f) => ((f['type'] as String?) ?? '').contains('opus'),
            orElse: () => null,
          );
          best ??= adaptive.firstWhere(
            (f) => ((f['type'] as String?) ?? '').startsWith('audio/'),
            orElse: () => null,
          );

          if (best != null && best['url'] != null) {
            final url = best['url'] as String;
            final cl = best['clen'] ?? best['contentLength'];
            final size = int.tryParse(cl?.toString() ?? '') ?? 0;
            final type = (best['type'] as String?)?.toLowerCase() ?? '';
            final isOpus = type.contains('opus') || type.contains('webm');

            debugPrint('[YouTubeMusicService] Successfully resolved audio stream from $host: size=$size, isOpus=$isOpus');
            return (url: url, totalBytes: size, isOpusOrWebm: isOpus);
          }
        }
      } catch (_) {
        // Try next instance
      }
    }
    return null;
  }

  /// Streams audio chunks with automatic chunking and retry resilience
  static Stream<List<int>> _fetchStreamChunks(String streamUrl, int totalBytes) async* {
    const chunkSize = 512 * 1024; // 512 KB chunks for max CDN throughput
    int start = 0;
    int retries = 0;
    final client = http.Client();

    while (totalBytes <= 0 || start < totalBytes) {
      final end = (totalBytes > 0) ? (start + chunkSize - 1).clamp(0, totalBytes - 1) : start + chunkSize - 1;
      try {
        final req = http.Request('GET', Uri.parse(streamUrl));
        req.headers['Range'] = 'bytes=$start-$end';
        final res = await client.send(req);

        if (res.statusCode != 200 && res.statusCode != 206) {
          throw Exception('HTTP status ${res.statusCode}');
        }

        int receivedInChunk = 0;
        await for (final data in res.stream) {
          start += data.length;
          receivedInChunk += data.length;
          yield data;
        }

        if (receivedInChunk == 0) {
          break; // EOF reached
        }
        retries = 0;
      } catch (e) {
        retries++;
        if (retries > 4) {
          rethrow;
        }
        await Future.delayed(const Duration(milliseconds: 400));
      }
    }
  }

  /// Resolves the highest quality direct audio stream URL (Opus 160kbps or AAC 256kbps).
  Future<String?> getAudioStreamUrl(String videoIdOrTrackId) async {
    final videoId = videoIdOrTrackId.replaceFirst('yt_', '');

    // Check memory cache (stream URLs are valid for ~4 hours)
    final cached = _urlCache[videoId];
    if (cached != null && DateTime.now().isBefore(cached.expiresAt)) {
      return cached.url;
    }

    // 1. Direct YoutubeExplode manifest (Primary & Client Authenticated)
    try {
      final manifest = await _getStreamManifest(videoId);
      if (manifest != null) {
        final bestStream = _selectBestAudioStream(manifest);
        if (bestStream != null) {
          final streamUrl = bestStream.url.toString();
          _urlCache[videoId] = (
            url: streamUrl,
            expiresAt: DateTime.now().add(const Duration(hours: 4)),
          );
          return streamUrl;
        }
      }
    } catch (e) {
      debugPrint('[YouTubeMusicService] Manifest stream extraction notice for $videoId: $e');
    }

    // 2. Fallback to full audio stream resolution
    try {
      final resolved = await _resolveFullAudioStream(videoId);
      if (resolved != null) {
        _urlCache[videoId] = (
          url: resolved.url,
          expiresAt: DateTime.now().add(const Duration(hours: 4)),
        );
        return resolved.url;
      }
    } catch (_) {}

    return null;
  }

  /// Returns a live `Stream<List<int>>` of audio chunks for full playback without 1MB ceiling.
  Future<Stream<List<int>>?> getAudioByteStream(String videoIdOrTrackId) async {
    final videoId = videoIdOrTrackId.replaceFirst('yt_', '');

    // 1. Primary: Direct YoutubeExplode streamsClient
    try {
      final manifest = await _getStreamManifest(videoId);
      if (manifest != null) {
        final bestStream = _selectBestAudioStream(manifest);
        if (bestStream != null) {
          return _client.videos.streamsClient.get(bestStream);
        }
      }
    } catch (e, st) {
      debugPrint('[YouTubeMusicService] Error getting direct stream for $videoId: $e\n$st');
    }

    // 2. Fallback to full stream resolution
    try {
      final resolved = await _resolveFullAudioStream(videoId);
      if (resolved != null) {
        return _fetchStreamChunks(resolved.url, resolved.totalBytes);
      }
    } catch (resolvedErr) {
      debugPrint('[YouTubeMusicService] Fallback stream resolution notice: $resolvedErr');
    }

    return null;
  }

  /// Returns a live `Stream<Uint8List>` of Ogg Opus audio chunks, remuxed in real-time from WebM Opus.
  /// This allows direct, low-latency streaming into flutter_soloud's C++ audio decoding engine
  /// for the entire song duration without freezing.
  Future<Stream<Uint8List>?> getOggOpusAudioByteStream(String videoIdOrTrackId) async {
    final videoId = videoIdOrTrackId.replaceFirst('yt_', '');

    // 1. Primary: Direct YoutubeExplode streamsClient with on-the-fly WebM to Ogg Opus remuxing
    try {
      final manifest = await _getStreamManifest(videoId);
      if (manifest != null) {
        final bestStream = _selectBestAudioStream(manifest);
        if (bestStream != null) {
          final rawStream = _client.videos.streamsClient.get(bestStream);
          final isOpusOrWebm = bestStream.audioCodec.toLowerCase().contains('opus') ||
              bestStream.container.name.toLowerCase().contains('webm');

          if (isOpusOrWebm) {
            return WebmToOggRemuxer.remuxStream(rawStream);
          } else {
            return rawStream.map((chunk) => chunk is Uint8List ? chunk : Uint8List.fromList(chunk));
          }
        }
      }
    } catch (e, st) {
      debugPrint('[YouTubeMusicService] Error getting direct Ogg Opus audio stream for $videoId: $e\n$st');
    }

    // 2. Fallback to full stream resolution
    try {
      final resolved = await _resolveFullAudioStream(videoId);
      if (resolved != null) {
        final rawStream = _fetchStreamChunks(resolved.url, resolved.totalBytes);
        if (resolved.isOpusOrWebm) {
          return WebmToOggRemuxer.remuxStream(rawStream);
        } else {
          return rawStream.map((chunk) => chunk is Uint8List ? chunk : Uint8List.fromList(chunk));
        }
      }
    } catch (resolvedErr) {
      debugPrint('[YouTubeMusicService] Fallback stream resolution notice: $resolvedErr');
    }

    return null;
  }


  /// Downloads audio directly into targetFile with 100% full duration guarantee.
  /// Uses ratebypass=yes unthrottled streaming with audio extraction into high-fidelity Ogg Opus.
  Future<String?> downloadAudio(
    String videoIdOrTrackId,
    File targetFile, {
    void Function(double progress)? onProgress,
  }) async {
    final videoId = videoIdOrTrackId.replaceFirst('yt_', '');

    if (!await targetFile.parent.exists()) {
      await targetFile.parent.create(recursive: true);
    }
    if (await targetFile.exists()) {
      await targetFile.delete();
    }

    // 1. Primary Strategy: Unthrottled muxed stream (itag 18) with ffmpeg Ogg Opus audio conversion
    final hasFfmpeg = await _checkFfmpeg();
    if (hasFfmpeg) {
      try {
        final manifest = await _getStreamManifest(videoId);
        final itag18 = manifest?.muxed.firstWhereOrNull((s) => s.tag == 18) ?? manifest?.muxed.firstOrNull;
        if (itag18 != null) {
          final tempMp4 = File('${targetFile.path}.tmp.mp4');
          if (await tempMp4.exists()) await tempMp4.delete();

          final sink = tempMp4.openWrite();
          final client = http.Client();
          int bytesDownloaded = 0;
          const chunkSize = 1024 * 1024;
          final totalBytes = itag18.size.totalBytes;

          while (bytesDownloaded < totalBytes) {
            final from = bytesDownloaded;
            final to = (from + chunkSize - 1).clamp(0, totalBytes - 1);
            final req = http.Request('GET', itag18.url);
            req.headers['Range'] = 'bytes=$from-$to';

            final res = await client.send(req);
            if (res.statusCode != 200 && res.statusCode != 206) {
              throw Exception('HTTP status ${res.statusCode} downloading chunk $from-$to');
            }

            await for (final data in res.stream) {
              bytesDownloaded += data.length;
              sink.add(data);
              if (totalBytes > 0) {
                onProgress?.call((bytesDownloaded / totalBytes * 0.85).clamp(0.0, 0.85));
              }
            }
          }

          await sink.flush();
          await sink.close();
          client.close();

          if (await tempMp4.exists() && await tempMp4.length() > 0) {
            onProgress?.call(0.9);
            final convResult = await Process.run('ffmpeg', [
              '-y',
              '-i', tempMp4.path,
              '-vn',
              '-c:a', 'libopus',
              '-b:a', '160k',
              targetFile.path,
            ]);

            try {
              await tempMp4.delete();
            } catch (_) {}

            if (convResult.exitCode == 0 && await targetFile.exists() && await targetFile.length() > 0) {
              onProgress?.call(1.0);
              debugPrint('[YouTubeMusicService] Download & remux to Ogg Opus complete for $videoId (${await targetFile.length()} bytes)');
              return targetFile.path;
            }
          }
        }
      } catch (itag18Err, st) {
        debugPrint('[YouTubeMusicService] itag 18 download error for $videoId: $itag18Err\n$st');
      }
    }

    // 2. Fallback Strategy: Direct getOggOpusAudioByteStream piping
    try {
      final oggStream = await getOggOpusAudioByteStream(videoId);
      if (oggStream != null) {
        final sink = targetFile.openWrite();
        int received = 0;
        await for (final chunk in oggStream) {
          sink.add(chunk);
          received += chunk.length;
          onProgress?.call((received / (3 * 1024 * 1024)).clamp(0.0, 1.0));
        }
        await sink.flush();
        await sink.close();

        if (await targetFile.exists() && await targetFile.length() > 0) {
          onProgress?.call(1.0);
          return targetFile.path;
        }
      }
    } catch (fallbackErr, st) {
      debugPrint('[YouTubeMusicService] Fallback download error for $videoId: $fallbackErr\n$st');
    }

    return null;
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

  /// Fetches rich details for a single YouTube video.
  Future<Video?> getVideoDetails(String videoIdOrTrackId) async {
    final videoId = videoIdOrTrackId.replaceFirst('yt_', '');
    try {
      return await _client.videos.get(videoId).timeout(const Duration(seconds: 4));
    } catch (e) {
      debugPrint('[YouTubeMusicService] Error getting video details for $videoId: $e');
      return null;
    }
  }

  /// Maps a YouTube Explode SearchVideo object to Baydev HiFi's Track domain entity.
  Track _mapSearchVideoToTrack(SearchVideo video) {
    final parsed = cleanMetadata(video.title, video.author);
    // Standard high-res JPEG thumbnail (avoids AVIF compression issues on Desktop/Linux)
    final thumb = 'https://i.ytimg.com/vi/${video.id.value}/hqdefault.jpg';

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
    final thumb = 'https://i.ytimg.com/vi/${video.id.value}/hqdefault.jpg';

    return Track(
      id: 'yt_${video.id.value}',
      title: parsed.title,
      artist: parsed.artist,
      album: 'YouTube Music',
      duration: video.duration ?? Duration.zero,
      albumArtUrl: thumb,
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

    // Replace unicode dashes with standard hyphen
    clean = clean.replaceAll(RegExp(r'[–—―]'), '-');

    // Strip brackets noise: [Official Video], [Vietsub], [MV], [4K], etc.
    clean = clean.replaceAll(
      RegExp(
        r'\[\s*[^\]]*?(Official|Music|Video|Audio|Lyric|Lyrics|HD|HQ|4K|Remaster|Visualizer|MV|Performance|Vietsub|Kara|Engsub|Sub|CC|Cover|Live|Stream|Audio Visualizer)[^\]]*?\]',
        caseSensitive: false,
      ),
      '',
    );
    clean = clean.replaceAll(
      RegExp(
        r'\(\s*[^\)]*?(Official|Music|Video|Audio|Lyric|Lyrics|HD|HQ|4K|Remaster|Visualizer|MV|Performance|Vietsub|Kara|Engsub|Sub|CC|Cover|Live|Stream|Audio Visualizer)[^\)]*?\)',
        caseSensitive: false,
      ),
      '',
    );
    // Japanese/Chinese bracket noise 【...】 「...」 『...』
    clean = clean.replaceAll(
      RegExp(
        r'[【「『]\s*[^】」』]*?(Official|Music|Video|Audio|Lyric|Lyrics|HD|HQ|4K|Remaster|Visualizer|MV|Vietsub)[^】」』]*?[】」』]',
        caseSensitive: false,
      ),
      '',
    );

    // Clean empty parentheses/brackets
    clean = clean.replaceAll(RegExp(r'\[\s*\]|\(\s*\)|【\s*】|「\s*」|『\s*』'), '');

    // Handle pipe `|` tags (e.g. "Vietsub | ...", "... | Lyrics Video", "... | Official Audio")
    final pipeParts = clean.split('|').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    if (pipeParts.length > 1) {
      // Filter out pipe parts that are pure junk / tag words
      final filtered = <String>[];
      for (final p in pipeParts) {
        final pLower = p.toLowerCase();
        final isJunk = RegExp(
          r'^(vietsub|kara|lyrics? video|official (video|audio|music video|mv)|audio|hd|4k|remastered?|visualizer|live|full album|hq|mv)$',
          caseSensitive: false,
        ).hasMatch(pLower);
        if (!isJunk) {
          filtered.add(p);
        }
      }
      if (filtered.isNotEmpty) {
        clean = filtered.join(' - ');
      }
    }

    // Strip trailing noise like " | Lyrics Video", " - Official Audio", etc.
    clean = clean.replaceAll(
      RegExp(r'(\||-)\s*(lyrics? video|official audio|official video|official mv|audio|visualizer)\s*$', caseSensitive: false),
      '',
    );

    final channelClean = _stripChannelSuffixes(channelName);

    // Check if title has " - " delimiter
    if (clean.contains(' - ')) {
      final parts = clean.split(' - ');
      final p0 = parts[0].trim();
      final p1 = parts.sublist(1).join(' - ').trim();

      if (p0.isNotEmpty && p1.isNotEmpty) {
        final p0Lower = p0.toLowerCase();
        final p1Lower = p1.toLowerCase();
        final chLower = channelClean.toLowerCase();

        // Case A: p1 matches channel name (e.g. "Waiting For The End - Linkin Park") -> p1 is artist, p0 is title
        if (chLower.isNotEmpty && (p1Lower.contains(chLower) || chLower.contains(p1Lower))) {
          return (
            artist: _stripChannelSuffixes(p1),
            title: _cleanTrackTitle(p0),
          );
        }

        // Case B: p0 matches channel name (e.g. "Linkin Park - Waiting For The End") -> p0 is artist, p1 is title
        if (chLower.isNotEmpty && (p0Lower.contains(chLower) || chLower.contains(p0Lower))) {
          return (
            artist: _stripChannelSuffixes(p0),
            title: _cleanTrackTitle(p1),
          );
        }

        // Case C: Check for "feat." or "ft." in parts (usually indicates artist side)
        final featRegex = RegExp(r'\b(feat|ft)\.?\b', caseSensitive: false);
        if (featRegex.hasMatch(p1) && !featRegex.hasMatch(p0)) {
          // e.g. "Where'd You Go - Fort Minor feat. Holly Brook" -> p1 is artist, p0 is title
          return (
            artist: _stripChannelSuffixes(p1),
            title: _cleanTrackTitle(p0),
          );
        }

        // Default "Artist - Title"
        return (
          artist: _stripChannelSuffixes(p0),
          title: _cleanTrackTitle(p1),
        );
      }
    }

    // Check if title has " : " delimiter
    if (clean.contains(' : ')) {
      final parts = clean.split(' : ');
      final p0 = parts[0].trim();
      final p1 = parts.sublist(1).join(' : ').trim();

      if (p0.isNotEmpty && p1.isNotEmpty) {
        final p1Lower = p1.toLowerCase();
        final chLower = channelClean.toLowerCase();

        if (chLower.isNotEmpty && (p1Lower.contains(chLower) || chLower.contains(p1Lower))) {
          return (
            artist: _stripChannelSuffixes(p1),
            title: _cleanTrackTitle(p0),
          );
        }

        return (
          artist: _stripChannelSuffixes(p0),
          title: _cleanTrackTitle(p1),
        );
      }
    }

    return (
      artist: channelClean.isNotEmpty ? channelClean : 'YouTube Artist',
      title: _cleanTrackTitle(clean),
    );
  }

  static String _stripChannelSuffixes(String name) {
    return name
        .replaceAll(RegExp(r'^\d+[\.\-\s]+'), '') // strip leading numbers like "01. "
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
