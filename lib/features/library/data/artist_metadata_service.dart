import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../../core/database/local_persistence_service.dart';

/// Service for fetching online artist artwork with persistent caching and offline fallback
class ArtistMetadataService {
  static final ArtistMetadataService instance = ArtistMetadataService._();
  ArtistMetadataService._();

  final Map<String, String> _memoryCache = {};
  final HttpClient _httpClient = HttpClient()..connectionTimeout = const Duration(seconds: 4);

  Future<dynamic> _fetchJson(Uri uri) async {
    try {
      final request = await _httpClient.getUrl(uri);
      final response = await request.close().timeout(const Duration(seconds: 4));
      if (response.statusCode == HttpStatus.ok) {
        final body = await response.transform(utf8.decoder).join();
        return jsonDecode(body);
      }
    } catch (e) {
      debugPrint('[ArtistMetadataService] Network fetch error for $uri: $e');
    }
    return null;
  }

  /// Get artist image URL from cache or query public search API (Deezer/iTunes)
  Future<String?> getArtistImageUrl(String artistName) async {
    final cleanName = artistName.trim();
    if (cleanName.isEmpty || cleanName.toLowerCase() == 'unknown artist') {
      return null;
    }

    final key = cleanName.toLowerCase();
    final cacheKey = 'artist_art_$key';

    // 1. Check in-memory cache
    if (_memoryCache.containsKey(key)) {
      final cached = _memoryCache[key];
      return (cached == '__none__' || cached == null || cached.isEmpty) ? null : cached;
    }

    // 2. Check local persistence
    try {
      final savedUrl = LocalPersistenceService.instance.getSetting<String>(cacheKey, '');
      if (savedUrl != null && savedUrl.isNotEmpty) {
        _memoryCache[key] = savedUrl;
        return savedUrl == '__none__' ? null : savedUrl;
      }
    } catch (_) {}

    // 3. Query online API (Deezer public API, free, no API key required)
    try {
      final uri = Uri.parse(
        'https://api.deezer.com/search/artist?q=${Uri.encodeComponent(cleanName)}&limit=1',
      );
      final data = await _fetchJson(uri);

      if (data is Map && data['data'] is List && (data['data'] as List).isNotEmpty) {
        final first = (data['data'] as List).first as Map;
        final pictureUrl = first['picture_big'] ?? first['picture_medium'] ?? first['picture'];
        if (pictureUrl is String && pictureUrl.isNotEmpty) {
          _memoryCache[key] = pictureUrl;
          try {
            LocalPersistenceService.instance.saveSetting(cacheKey, pictureUrl);
          } catch (_) {}
          return pictureUrl;
        }
      }
    } catch (e) {
      debugPrint('[ArtistMetadataService] Deezer query error for $cleanName: $e');
    }

    // 4. Fallback query (iTunes public search API)
    try {
      final uri = Uri.parse(
        'https://itunes.apple.com/search?term=${Uri.encodeComponent(cleanName)}&entity=musicArtist&limit=1',
      );
      final data = await _fetchJson(uri);

      if (data is Map && data['results'] is List && (data['results'] as List).isNotEmpty) {
        // If iTunes returned an artist, query their top track artwork
        final trackUri = Uri.parse(
          'https://itunes.apple.com/search?term=${Uri.encodeComponent(cleanName)}&entity=song&limit=1',
        );
        final trackData = await _fetchJson(trackUri);
        if (trackData is Map && trackData['results'] is List && (trackData['results'] as List).isNotEmpty) {
          final artUrl = (trackData['results'] as List).first['artworkUrl100'] as String?;
          if (artUrl != null && artUrl.isNotEmpty) {
            final highResUrl = artUrl.replaceAll('100x100bb', '600x600bb');
            _memoryCache[key] = highResUrl;
            try {
              LocalPersistenceService.instance.saveSetting(cacheKey, highResUrl);
            } catch (_) {}
            return highResUrl;
          }
        }
      }
    } catch (e) {
      debugPrint('[ArtistMetadataService] iTunes query error for $cleanName: $e');
    }

    // 5. If no artwork found, record negative result so we don't query network repeatedly
    _memoryCache[key] = '__none__';
    try {
      LocalPersistenceService.instance.saveSetting(cacheKey, '__none__');
    } catch (_) {}

    return null;
  }
}
