import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/database/local_persistence_service.dart';

/// Service for fetching online artist artwork with persistent disk file caching and offline fallback
class ArtistMetadataService {
  static final ArtistMetadataService instance = ArtistMetadataService._();
  ArtistMetadataService._();

  final Map<String, String> _memoryCache = {};
  final Map<String, String> _memoryFileCache = {};
  final Map<String, Future<String?>> _inFlightRequests = {};
  final HttpClient _httpClient = HttpClient()..connectionTimeout = const Duration(seconds: 4);

  Directory? _cachedCoversDirectory;

  @visibleForTesting
  Directory? testCoversDirectory;

  /// Clear runtime memory caches and cached directories (e.g. after user cache purge)
  void clearMemoryCache() {
    _memoryCache.clear();
    _memoryFileCache.clear();
    _inFlightRequests.clear();
    _cachedCoversDirectory = null;
  }

  Future<Directory> _getCoversDirectory() async {
    if (testCoversDirectory != null) {
      if (!testCoversDirectory!.existsSync()) {
        testCoversDirectory!.createSync(recursive: true);
      }
      return testCoversDirectory!;
    }
    if (_cachedCoversDirectory != null) {
      if (!_cachedCoversDirectory!.existsSync()) {
        _cachedCoversDirectory!.createSync(recursive: true);
      }
      return _cachedCoversDirectory!;
    }
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final dir = Directory('${appDocDir.path}/artist_covers');
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      _cachedCoversDirectory = dir;
      return dir;
    } catch (_) {
      final tempDir = Directory('${Directory.systemTemp.path}/bayhifi_artist_covers');
      if (!tempDir.existsSync()) {
        tempDir.createSync(recursive: true);
      }
      _cachedCoversDirectory = tempDir;
      return tempDir;
    }
  }

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

  /// Synchronously checks if an artist cover image file is cached locally on disk.
  /// Returns the absolute file path if valid and exists on disk, or null.
  String? getCachedArtistImagePathSync(String artistName) {
    final cleanName = artistName.trim();
    if (cleanName.isEmpty || cleanName.toLowerCase() == 'unknown artist') {
      return null;
    }

    final key = cleanName.toLowerCase();

    // 1. Check in-memory file cache
    if (_memoryFileCache.containsKey(key)) {
      final cachedPath = _memoryFileCache[key];
      if (cachedPath == null || cachedPath == '__none__' || cachedPath.isEmpty) {
        return null;
      }
      if (File(cachedPath).existsSync()) {
        return cachedPath;
      }
    }

    // 2. Check local persistence
    try {
      final savedPath = LocalPersistenceService.instance.getSetting<String>('artist_file_$key', '');
      if (savedPath != null && savedPath.isNotEmpty && savedPath != '__none__') {
        final file = File(savedPath);
        if (file.existsSync()) {
          _memoryFileCache[key] = savedPath;
          return savedPath;
        }
      }
    } catch (_) {}

    return null;
  }

  /// Manually save an artist cover image bytes to local disk cache
  Future<String?> saveArtistCoverBytes(String artistName, Uint8List bytes) async {
    final cleanName = artistName.trim();
    if (cleanName.isEmpty || bytes.isEmpty) return null;
    final key = cleanName.toLowerCase();
    try {
      final coversDir = await _getCoversDirectory();
      final targetFile = File('${coversDir.path}/art_${key.hashCode.abs()}.jpg');
      targetFile.writeAsBytesSync(bytes, flush: true);
      _memoryFileCache[key] = targetFile.path;
      try {
        LocalPersistenceService.instance.saveSetting('artist_file_$key', targetFile.path);
      } catch (_) {}
      return targetFile.path;
    } catch (e) {
      debugPrint('[ArtistMetadataService] Error saving manual cover bytes: $e');
      return null;
    }
  }

  /// Get artist image local file path or URL from cache or query public search API (Deezer/iTunes)
  Future<String?> getArtistImageUrl(String artistName) async {
    final cleanName = artistName.trim();
    if (cleanName.isEmpty || cleanName.toLowerCase() == 'unknown artist') {
      return null;
    }

    final key = cleanName.toLowerCase();

    // In-flight request de-duplication: return active future if already fetching
    if (_inFlightRequests.containsKey(key)) {
      return _inFlightRequests[key]!;
    }

    final future = _resolveArtistImage(cleanName, key);
    _inFlightRequests[key] = future;
    try {
      return await future;
    } finally {
      _inFlightRequests.remove(key);
    }
  }

  Future<String?> _resolveArtistImage(String cleanName, String key) async {
    final cacheKey = 'artist_art_$key';
    final cacheFileKey = 'artist_file_$key';

    // 1. Check synchronous disk cache first
    final syncPath = getCachedArtistImagePathSync(cleanName);
    if (syncPath != null) {
      return syncPath;
    }

    // 2. Check negative cache
    if (_memoryFileCache[key] == '__none__' || _memoryCache[key] == '__none__') {
      return null;
    }

    // 3. Check local persistence for negative cache
    try {
      final savedFile = LocalPersistenceService.instance.getSetting<String>(cacheFileKey, '');
      if (savedFile == '__none__') {
        _memoryFileCache[key] = '__none__';
        return null;
      }
    } catch (_) {}

    // 4. Check if we already have an online URL in memory or persistence
    String? onlineUrl = _memoryCache[key];
    if (onlineUrl == null || onlineUrl.isEmpty) {
      try {
        final savedUrl = LocalPersistenceService.instance.getSetting<String>(cacheKey, '');
        if (savedUrl != null && savedUrl.isNotEmpty) {
          if (savedUrl == '__none__') {
            _memoryCache[key] = '__none__';
            return null;
          }
          onlineUrl = savedUrl;
          _memoryCache[key] = onlineUrl;
        }
      } catch (_) {}
    }

    // 5. If online URL already known, download and cache image bytes to disk
    if (onlineUrl != null && onlineUrl.isNotEmpty && onlineUrl != '__none__') {
      final savedPath = await _downloadAndSaveImage(onlineUrl, key, cacheFileKey);
      if (savedPath != null) {
        return savedPath;
      }
      return onlineUrl; // Fallback to network URL if disk write failed
    }

    // 6. Query online API (Deezer public API, free, no API key required)
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

          final savedPath = await _downloadAndSaveImage(pictureUrl, key, cacheFileKey);
          if (savedPath != null) {
            return savedPath;
          }
          return pictureUrl;
        }
      }
    } catch (e) {
      debugPrint('[ArtistMetadataService] Deezer query error for $cleanName: $e');
    }

    // 7. Fallback query (iTunes public search API)
    try {
      final uri = Uri.parse(
        'https://itunes.apple.com/search?term=${Uri.encodeComponent(cleanName)}&entity=musicArtist&limit=1',
      );
      final data = await _fetchJson(uri);

      if (data is Map && data['results'] is List && (data['results'] as List).isNotEmpty) {
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

            final savedPath = await _downloadAndSaveImage(highResUrl, key, cacheFileKey);
            if (savedPath != null) {
              return savedPath;
            }
            return highResUrl;
          }
        }
      }
    } catch (e) {
      debugPrint('[ArtistMetadataService] iTunes query error for $cleanName: $e');
    }

    // 8. If no artwork found, record negative result so we don't query network repeatedly
    _memoryCache[key] = '__none__';
    _memoryFileCache[key] = '__none__';
    try {
      LocalPersistenceService.instance.saveSetting(cacheKey, '__none__');
      LocalPersistenceService.instance.saveSetting(cacheFileKey, '__none__');
    } catch (_) {}

    return null;
  }

  Future<String?> _downloadAndSaveImage(String imageUrl, String key, String cacheFileKey) async {
    try {
      final coversDir = await _getCoversDirectory();
      final targetFile = File('${coversDir.path}/art_${key.hashCode.abs()}.jpg');
      if (await targetFile.exists() && await targetFile.length() > 0) {
        _memoryFileCache[key] = targetFile.path;
        try {
          LocalPersistenceService.instance.saveSetting(cacheFileKey, targetFile.path);
        } catch (_) {}
        return targetFile.path;
      }

      final uri = Uri.parse(imageUrl);
      final request = await _httpClient.getUrl(uri);
      final response = await request.close().timeout(const Duration(seconds: 6));
      if (response.statusCode == HttpStatus.ok) {
        final bytesBuilder = BytesBuilder(copy: false);
        await for (final chunk in response) {
          bytesBuilder.add(chunk);
        }
        final bytes = bytesBuilder.takeBytes();
        if (bytes.isNotEmpty) {
          targetFile.writeAsBytesSync(bytes, flush: true);
          _memoryFileCache[key] = targetFile.path;
          try {
            LocalPersistenceService.instance.saveSetting(cacheFileKey, targetFile.path);
          } catch (_) {}
          return targetFile.path;
        }
      }
    } catch (e) {
      debugPrint('[ArtistMetadataService] Error caching artist cover to disk from $imageUrl: $e');
    }
    return null;
  }
}
