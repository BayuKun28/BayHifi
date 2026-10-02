import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../domain/spotify_models.dart';

/// Service to extract rich Spotify metadata (tracks, albums, playlists) without user authentication.
/// Uses Spotify's public embed data, oEmbed, and REST API endpoints.
class SpotifyMetadataService {
  SpotifyMetadataService._();
  static final SpotifyMetadataService instance = SpotifyMetadataService._();

  String? _cachedToken;
  DateTime? _tokenExpiry;

  final Map<String, String> _defaultHeaders = {
    'User-Agent':
        'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Accept': 'text/html,application/xhtml+xml,application/xml;q=0.9,application/json,*/*;q=0.8',
    'Accept-Language': 'en-US,en;q=0.9',
  };

  /// Retrieves an anonymous bearer access token if available.
  Future<String?> getAnonymousAccessToken() async {
    if (_cachedToken != null &&
        _tokenExpiry != null &&
        DateTime.now().isBefore(_tokenExpiry!)) {
      return _cachedToken;
    }

    try {
      final response = await http.get(
        Uri.parse(
            'https://open.spotify.com/get_access_token?reason=transport&productType=web_player'),
        headers: _defaultHeaders,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final token = data['accessToken'] as String?;
        final expiryMs = data['accessTokenExpirationTimestampMs'] as int?;

        if (token != null && token.isNotEmpty) {
          _cachedToken = token;
          if (expiryMs != null) {
            _tokenExpiry = DateTime.fromMillisecondsSinceEpoch(expiryMs)
                .subtract(const Duration(minutes: 2));
          } else {
            _tokenExpiry = DateTime.now().add(const Duration(minutes: 50));
          }
          return _cachedToken;
        }
      }
    } catch (e) {
      debugPrint('[SpotifyMetadataService] Token fetch note: $e');
    }

    return null;
  }

  /// Resolves any Spotify URL/URI into a UniversalImportPreview with tracklist.
  Future<UniversalImportPreview?> resolveUrl(String input) async {
    final parsed = SpotifyParsedUrl.parse(input);
    if (parsed == null || !parsed.isValid) return null;

    switch (parsed.type) {
      case SpotifyItemType.track:
        final track = await getTrack(parsed.id);
        if (track == null) return null;
        return UniversalImportPreview(
          type: SpotifyItemType.track,
          title: track.title,
          subtitle: '${track.artist} • ${track.album}',
          coverUrl: track.albumArtUrl,
          trackCount: 1,
          totalDuration: track.duration,
          tracks: [track],
          rawUrl: parsed.rawUrl,
        );

      case SpotifyItemType.album:
        final album = await getAlbum(parsed.id);
        if (album == null) return null;
        final totalDur = album.tracks.fold<Duration>(
          Duration.zero,
          (prev, t) => prev + t.duration,
        );
        return UniversalImportPreview(
          type: SpotifyItemType.album,
          title: album.title,
          subtitle: '${album.artist} • ${album.releaseYear ?? ''} (${album.tracks.length} tracks)',
          coverUrl: album.albumArtUrl,
          trackCount: album.tracks.length,
          totalDuration: totalDur,
          tracks: album.tracks,
          rawUrl: parsed.rawUrl,
        );

      case SpotifyItemType.playlist:
        final playlist = await getPlaylist(parsed.id);
        if (playlist == null) return null;
        final totalDur = playlist.tracks.fold<Duration>(
          Duration.zero,
          (prev, t) => prev + t.duration,
        );
        return UniversalImportPreview(
          type: SpotifyItemType.playlist,
          title: playlist.title,
          subtitle: 'By ${playlist.owner} • ${playlist.tracks.length} tracks',
          coverUrl: playlist.albumArtUrl,
          trackCount: playlist.tracks.length,
          totalDuration: totalDur,
          tracks: playlist.tracks,
          rawUrl: parsed.rawUrl,
        );

      default:
        return null;
    }
  }

  /// Fetches track metadata by Spotify Track ID (Embed parser -> Web API -> oEmbed fallback)
  Future<SpotifyTrack?> getTrack(String trackId) async {
    // 1. Primary Strategy: Spotify Embed HTML Scraper (Zero Auth, Most Reliable)
    final embedTrack = await _fetchTrackFromEmbed(trackId);
    if (embedTrack != null) return embedTrack;

    // 2. Secondary Strategy: Spotify Web API (if token valid)
    final token = await getAnonymousAccessToken();
    if (token != null) {
      try {
        final response = await http.get(
          Uri.parse('https://api.spotify.com/v1/tracks/$trackId'),
          headers: {
            ..._defaultHeaders,
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          return SpotifyTrack.fromJson(data);
        }
      } catch (e) {
        debugPrint('[SpotifyMetadataService] Web API track error: $e');
      }
    }

    // 3. Fallback: oEmbed
    return _fetchTrackFallback(trackId);
  }

  /// Fetches album metadata and all tracks by Spotify Album ID
  Future<SpotifyAlbum?> getAlbum(String albumId) async {
    // 1. Primary: Embed HTML Scraper
    final embedAlbum = await _fetchAlbumFromEmbed(albumId);
    if (embedAlbum != null && embedAlbum.tracks.isNotEmpty) return embedAlbum;

    // 2. Secondary: Spotify Web API
    final token = await getAnonymousAccessToken();
    if (token != null) {
      try {
        final response = await http.get(
          Uri.parse('https://api.spotify.com/v1/albums/$albumId'),
          headers: {
            ..._defaultHeaders,
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final album = SpotifyAlbum.fromJson(data);
          return album;
        }
      } catch (e) {
        debugPrint('[SpotifyMetadataService] Web API album error: $e');
      }
    }

    // 3. Fallback: oEmbed basic representation
    return _fetchAlbumFallback(albumId);
  }

  /// Fetches playlist metadata and all tracks by Spotify Playlist ID
  Future<SpotifyPlaylist?> getPlaylist(String playlistId) async {
    // 1. Primary Strategy: Spotify Embed HTML Scraper (Zero Auth, Full Tracklist)
    final embedPlaylist = await _fetchPlaylistFromEmbed(playlistId);
    if (embedPlaylist != null && embedPlaylist.tracks.isNotEmpty) {
      return embedPlaylist;
    }

    // 2. Secondary Strategy: Spotify Web API
    final token = await getAnonymousAccessToken();
    if (token != null) {
      try {
        final response = await http.get(
          Uri.parse('https://api.spotify.com/v1/playlists/$playlistId'),
          headers: {
            ..._defaultHeaders,
            'Authorization': 'Bearer $token',
          },
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final playlist = SpotifyPlaylist.fromJson(data);
          return playlist;
        }
      } catch (e) {
        debugPrint('[SpotifyMetadataService] Web API playlist error: $e');
      }
    }

    // 3. Fallback: oEmbed
    return _fetchPlaylistFallback(playlistId);
  }

  // ==========================================
  // EMBED HTML EXTRACTION ENGINE (Zero Auth)
  // ==========================================

  Future<SpotifyPlaylist?> _fetchPlaylistFromEmbed(String playlistId) async {
    try {
      final url = 'https://open.spotify.com/embed/playlist/$playlistId';
      final response = await http.get(Uri.parse(url), headers: _defaultHeaders);
      if (response.statusCode != 200) return null;

      final entity = _extractEntityFromEmbedHtml(response.body);
      if (entity == null) return null;

      final title = entity['title'] as String? ??
          entity['name'] as String? ??
          'Spotify Playlist';
      final owner = entity['subtitle'] as String? ?? 'Spotify User';
      final description = entity['description'] as String? ?? '';
      final coverUrl = _extractCoverFromEntity(entity);

      final rawTracks = entity['trackList'] as List<dynamic>? ?? [];
      final List<SpotifyTrack> parsedTracks = [];

      for (int i = 0; i < rawTracks.length; i++) {
        final item = rawTracks[i];
        if (item is! Map<String, dynamic>) continue;

        final uri = item['uri'] as String? ?? '';
        final trackId = uri.contains(':') ? uri.split(':').last : 'track_$i';
        final trackTitle = item['title'] as String? ?? item['name'] as String? ?? 'Unknown Title';
        final trackArtist = item['subtitle'] as String? ?? 'Unknown Artist';
        final durationMs = item['duration'] as int? ?? 0;

        parsedTracks.add(
          SpotifyTrack(
            id: trackId,
            title: trackTitle,
            artist: trackArtist,
            artists: [trackArtist],
            album: title,
            duration: Duration(milliseconds: durationMs),
            albumArtUrl: coverUrl,
            trackNumber: i + 1,
          ),
        );
      }

      // Concurrently enrich tracks with their distinct album cover art via oEmbed
      final enrichedTracks = await _enrichPlaylistTracksArtwork(parsedTracks, coverUrl);

      return SpotifyPlaylist(
        id: playlistId,
        title: title,
        owner: owner,
        description: description,
        albumArtUrl: coverUrl,
        totalTracks: enrichedTracks.length,
        tracks: enrichedTracks,
      );
    } catch (e) {
      debugPrint('[SpotifyMetadataService] Embed playlist parser error: $e');
      return null;
    }
  }

  /// Concurrently fetches individual track cover art in small batches
  Future<List<SpotifyTrack>> _enrichPlaylistTracksArtwork(
    List<SpotifyTrack> tracks,
    String? fallbackCoverUrl,
  ) async {
    const batchSize = 10;
    final List<SpotifyTrack> results = [];

    for (int i = 0; i < tracks.length; i += batchSize) {
      final end = (i + batchSize > tracks.length) ? tracks.length : i + batchSize;
      final chunk = tracks.sublist(i, end);
      final chunkResults = await Future.wait(
        chunk.map((t) async {
          if (t.id.isNotEmpty && !t.id.startsWith('track_')) {
            try {
              final trackArt = await fetchTrackCoverUrl(t.id);
              if (trackArt != null && trackArt.isNotEmpty) {
                return t.copyWith(albumArtUrl: trackArt);
              }
            } catch (_) {}
          }
          return t;
        }),
      );
      results.addAll(chunkResults);
    }
    return results;
  }

  /// Fetches track artwork directly via Spotify oEmbed endpoint without auth
  Future<String?> fetchTrackCoverUrl(String trackId) async {
    try {
      final oembedUrl =
          'https://open.spotify.com/oembed?url=https://open.spotify.com/track/$trackId';
      final response = await http
          .get(Uri.parse(oembedUrl), headers: _defaultHeaders)
          .timeout(const Duration(seconds: 4));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final thumb = data['thumbnail_url'] as String?;
        if (thumb != null && thumb.isNotEmpty) {
          return thumb;
        }
      }
    } catch (_) {}
    return null;
  }

  Future<SpotifyAlbum?> _fetchAlbumFromEmbed(String albumId) async {
    try {
      final url = 'https://open.spotify.com/embed/album/$albumId';
      final response = await http.get(Uri.parse(url), headers: _defaultHeaders);
      if (response.statusCode != 200) return null;

      final entity = _extractEntityFromEmbedHtml(response.body);
      if (entity == null) return null;

      final title = entity['title'] as String? ??
          entity['name'] as String? ??
          'Spotify Album';
      final artist = entity['subtitle'] as String? ?? 'Various Artists';
      final coverUrl = _extractCoverFromEntity(entity);

      int? releaseYear;
      final releaseDateObj = entity['releaseDate'];
      if (releaseDateObj is Map && releaseDateObj['isoString'] != null) {
        final dt = DateTime.tryParse(releaseDateObj['isoString'] as String);
        if (dt != null) releaseYear = dt.year;
      }

      final rawTracks = entity['trackList'] as List<dynamic>? ?? [];
      final List<SpotifyTrack> parsedTracks = [];

      for (int i = 0; i < rawTracks.length; i++) {
        final item = rawTracks[i];
        if (item is! Map<String, dynamic>) continue;

        final uri = item['uri'] as String? ?? '';
        final trackId = uri.contains(':') ? uri.split(':').last : 'album_track_$i';
        final trackTitle = item['title'] as String? ?? item['name'] as String? ?? 'Unknown Title';
        final trackArtist = item['subtitle'] as String? ?? artist;
        final durationMs = item['duration'] as int? ?? 0;

        parsedTracks.add(
          SpotifyTrack(
            id: trackId,
            title: trackTitle,
            artist: trackArtist,
            artists: [trackArtist],
            album: title,
            duration: Duration(milliseconds: durationMs),
            albumArtUrl: coverUrl,
            trackNumber: i + 1,
            releaseYear: releaseYear,
          ),
        );
      }

      return SpotifyAlbum(
        id: albumId,
        title: title,
        artist: artist,
        albumArtUrl: coverUrl,
        releaseYear: releaseYear,
        totalTracks: parsedTracks.length,
        tracks: parsedTracks,
      );
    } catch (e) {
      debugPrint('[SpotifyMetadataService] Embed album parser error: $e');
      return null;
    }
  }

  Future<SpotifyTrack?> _fetchTrackFromEmbed(String trackId) async {
    try {
      final url = 'https://open.spotify.com/embed/track/$trackId';
      final response = await http.get(Uri.parse(url), headers: _defaultHeaders);
      if (response.statusCode != 200) return null;

      final entity = _extractEntityFromEmbedHtml(response.body);
      if (entity == null) return null;

      final title = entity['title'] as String? ?? entity['name'] as String? ?? 'Unknown Title';
      
      final List<String> artists = [];
      if (entity['artists'] is List) {
        for (final a in entity['artists']) {
          if (a is Map && a['name'] != null) {
            artists.add(a['name'] as String);
          }
        }
      }
      if (artists.isEmpty && entity['subtitle'] != null) {
        artists.add(entity['subtitle'] as String);
      }

      final primaryArtist = artists.isNotEmpty ? artists.first : 'Unknown Artist';
      final coverUrl = _extractCoverFromEntity(entity);
      final durationMs = entity['duration'] as int? ?? 0;

      int? releaseYear;
      final releaseDateObj = entity['releaseDate'];
      if (releaseDateObj is Map && releaseDateObj['isoString'] != null) {
        final dt = DateTime.tryParse(releaseDateObj['isoString'] as String);
        if (dt != null) releaseYear = dt.year;
      }

      return SpotifyTrack(
        id: trackId,
        title: title,
        artist: primaryArtist,
        artists: artists.isNotEmpty ? artists : [primaryArtist],
        album: 'Spotify Single',
        duration: Duration(milliseconds: durationMs),
        albumArtUrl: coverUrl,
        releaseYear: releaseYear,
      );
    } catch (e) {
      debugPrint('[SpotifyMetadataService] Embed track parser error: $e');
      return null;
    }
  }

  Map<String, dynamic>? _extractEntityFromEmbedHtml(String html) {
    try {
      final match = RegExp(
        r'<script id="__NEXT_DATA__"[^>]*>(.*?)</script>',
        dotAll: true,
      ).firstMatch(html);

      if (match == null) return null;
      final jsonStr = match.group(1);
      if (jsonStr == null || jsonStr.isEmpty) return null;

      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      final pageProps = map['props']?['pageProps'] as Map<String, dynamic>?;
      if (pageProps == null) return null;

      // Extract access token if present
      final sessionToken =
          pageProps['state']?['settings']?['session']?['accessToken'] as String?;
      if (sessionToken != null && sessionToken.isNotEmpty) {
        _cachedToken = sessionToken;
        _tokenExpiry = DateTime.now().add(const Duration(minutes: 50));
      }

      final entity = pageProps['state']?['data']?['entity'] as Map<String, dynamic>?;
      return entity;
    } catch (e) {
      debugPrint('[SpotifyMetadataService] HTML script extraction error: $e');
      return null;
    }
  }

  String? _extractCoverFromEntity(Map<String, dynamic> entity) {
    if (entity['visualIdentity'] is Map) {
      final images = entity['visualIdentity']['image'] as List<dynamic>?;
      if (images != null && images.isNotEmpty) {
        for (final img in images) {
          if (img is Map && img['url'] != null) {
            return img['url'] as String;
          }
        }
      }
    }
    if (entity['coverArt'] is Map) {
      final sources = entity['coverArt']['sources'] as List<dynamic>?;
      if (sources != null && sources.isNotEmpty) {
        for (final s in sources) {
          if (s is Map && s['url'] != null) {
            return s['url'] as String;
          }
        }
      }
    }
    return null;
  }

  // ==========================================
  // OEMBED FALLBACK HELPERS
  // ==========================================

  Future<SpotifyTrack?> _fetchTrackFallback(String trackId) async {
    try {
      final oembedUrl = 'https://open.spotify.com/oembed?url=https://open.spotify.com/track/$trackId';
      final response = await http.get(Uri.parse(oembedUrl), headers: _defaultHeaders);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final title = data['title'] as String? ?? 'Unknown Title';
        final thumbnail = data['thumbnail_url'] as String?;

        String parsedTitle = title;
        String parsedArtist = 'Unknown Artist';
        if (title.contains(' - ')) {
          final parts = title.split(' - ');
          parsedTitle = parts[0].trim();
          parsedArtist = parts.sublist(1).join(' - ').trim();
        }

        return SpotifyTrack(
          id: trackId,
          title: parsedTitle,
          artist: parsedArtist,
          artists: [parsedArtist],
          album: 'Spotify Single',
          duration: Duration.zero,
          albumArtUrl: thumbnail,
        );
      }
    } catch (e) {
      debugPrint('[SpotifyMetadataService] Fallback oEmbed track error: $e');
    }
    return null;
  }

  Future<SpotifyAlbum?> _fetchAlbumFallback(String albumId) async {
    try {
      final oembedUrl = 'https://open.spotify.com/oembed?url=https://open.spotify.com/album/$albumId';
      final response = await http.get(Uri.parse(oembedUrl), headers: _defaultHeaders);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final title = data['title'] as String? ?? 'Spotify Album';
        final thumbnail = data['thumbnail_url'] as String?;

        return SpotifyAlbum(
          id: albumId,
          title: title,
          artist: 'Various Artists',
          albumArtUrl: thumbnail,
          totalTracks: 0,
          tracks: const [],
        );
      }
    } catch (e) {
      debugPrint('[SpotifyMetadataService] Fallback oEmbed album error: $e');
    }
    return null;
  }

  Future<SpotifyPlaylist?> _fetchPlaylistFallback(String playlistId) async {
    try {
      final oembedUrl = 'https://open.spotify.com/oembed?url=https://open.spotify.com/playlist/$playlistId';
      final response = await http.get(Uri.parse(oembedUrl), headers: _defaultHeaders);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final title = data['title'] as String? ?? 'Spotify Playlist';
        final thumbnail = data['thumbnail_url'] as String?;

        return SpotifyPlaylist(
          id: playlistId,
          title: title,
          owner: 'Spotify User',
          description: '',
          albumArtUrl: thumbnail,
          totalTracks: 0,
          tracks: const [],
        );
      }
    } catch (e) {
      debugPrint('[SpotifyMetadataService] Fallback oEmbed playlist error: $e');
    }
    return null;
  }
}

