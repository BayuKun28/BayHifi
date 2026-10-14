import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../features/player/domain/track.dart';
import '../features/spotify_importer/data/audio_matcher_service.dart';
import '../features/youtube_music/data/youtube_music_service.dart';

/// Spotify-grade Audio Caching & Next-Track Prefetch Service
/// Memungkinkan pemutaran instan 0ms dari disk cache lokal untuk remote stream tracks.
class AudioCacheService extends ChangeNotifier {
  static final AudioCacheService _instance = AudioCacheService._internal();
  static AudioCacheService get instance => _instance;

  AudioCacheService._internal();

  Dio _dio = Dio();
  Directory? _cacheDir;
  final Set<String> _cachedTrackIds = {};
  final Map<String, double> _downloadProgress = {};
  int _totalCacheBytes = 0;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;
  Set<String> get cachedTrackIds => Set.unmodifiable(_cachedTrackIds);
  int get totalCachedTracksCount => _cachedTrackIds.length;
  int get totalCacheSizeBytes => _totalCacheBytes;

  @visibleForTesting
  void setDioForTesting(Dio testDio) {
    _dio = testDio;
  }

  @visibleForTesting
  void setCacheDirForTesting(Directory dir) {
    _cacheDir = dir;
    _scanCacheSync();
    _isInitialized = true;
  }

  /// Inisialisasi direktori cache audio dan indeksasi file
  Future<void> init() async {
    if (kIsWeb) return;
    if (_isInitialized && _cacheDir != null) return;

    try {
      final docDir = await getApplicationDocumentsDirectory();
      _cacheDir = Directory('${docDir.path}/audio_cache');
      if (!await _cacheDir!.exists()) {
        await _cacheDir!.create(recursive: true);
      }

      await scanCache();
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('[AudioCacheService] Init error: $e');
    }
  }

  String _sanitizeId(String trackId) {
    return trackId.replaceAll(RegExp(r'[^\w\.-]'), '_');
  }

  File _getCacheFile(String trackId) {
    final sanitized = _sanitizeId(trackId);
    final oggFile = File('${_cacheDir!.path}/$sanitized.ogg');
    if (oggFile.existsSync()) return oggFile;
    final legacyFile = File('${_cacheDir!.path}/$sanitized.cache');
    if (legacyFile.existsSync()) return legacyFile;
    return oggFile;
  }

  File _getTempFile(String trackId) {
    final sanitized = _sanitizeId(trackId);
    return File('${_cacheDir!.path}/$sanitized.tmp.ogg');
  }

  /// Returns cache file for a track ID
  File getCacheFile(String trackId) => _getCacheFile(trackId);

  /// Returns temp file for a track ID
  File getTempFile(String trackId) => _getTempFile(trackId);

  /// Memeriksa apakah track telah tersimpan di cache lokal
  bool isCached(String trackId) {
    return _cachedTrackIds.contains(trackId);
  }

  /// Mendapatkan path file lokal track yang telah ter-cache
  String? getCachedFilePath(String trackId) {
    if (!isCached(trackId) || _cacheDir == null) return null;
    final file = _getCacheFile(trackId);
    if (file.existsSync() && file.lengthSync() > 0) {
      return file.path;
    }
    _cachedTrackIds.remove(trackId);
    return null;
  }

  /// Mendapatkan progress pengunduhan saat ini (0.0 s/d 1.0)
  double? getDownloadProgress(String trackId) {
    return _downloadProgress[trackId];
  }

  /// Memindai direktori cache untuk menghitung ukuran dan daftar ID
  Future<void> scanCache() async {
    if (_cacheDir == null) return;
    try {
      _cachedTrackIds.clear();
      int bytes = 0;

      final entities = _cacheDir!.listSync();
      for (final entity in entities) {
        if (entity is File) {
          final p = entity.path;
          if (p.endsWith('.ogg') && !p.endsWith('.tmp.ogg')) {
            final size = entity.lengthSync();
            if (size > 0) {
              bytes += size;
              final fileName = entity.uri.pathSegments.last;
              final trackId = fileName.substring(0, fileName.length - '.ogg'.length);
              _cachedTrackIds.add(trackId);
            }
          } else if (p.endsWith('.cache')) {
            final size = entity.lengthSync();
            if (size > 0) {
              bytes += size;
              final fileName = entity.uri.pathSegments.last;
              final trackId = fileName.substring(0, fileName.length - '.cache'.length);
              _cachedTrackIds.add(trackId);
            }
          }
        }
      }

      _totalCacheBytes = bytes;
      notifyListeners();
    } catch (e) {
      debugPrint('[AudioCacheService] Scan cache error: $e');
    }
  }

  void _scanCacheSync() {
    if (_cacheDir == null) return;
    _cachedTrackIds.clear();
    int bytes = 0;
    if (_cacheDir!.existsSync()) {
      for (final entity in _cacheDir!.listSync()) {
        if (entity is File) {
          final p = entity.path;
          if (p.endsWith('.ogg') && !p.endsWith('.tmp.ogg')) {
            final size = entity.lengthSync();
            if (size > 0) {
              bytes += size;
              final fileName = entity.uri.pathSegments.last;
              final trackId = fileName.substring(0, fileName.length - '.ogg'.length);
              _cachedTrackIds.add(trackId);
            }
          } else if (p.endsWith('.cache')) {
            final size = entity.lengthSync();
            if (size > 0) {
              bytes += size;
              final fileName = entity.uri.pathSegments.last;
              final trackId = fileName.substring(0, fileName.length - '.cache'.length);
              _cachedTrackIds.add(trackId);
            }
          }
        }
      }
    }
    _totalCacheBytes = bytes;
  }

  /// Mengunduh dan menyimpan track ke cache lokal di background
  Future<String?> cacheTrack(
    Track track, {
    void Function(double progress)? onProgress,
  }) async {
    if (!_isInitialized || _cacheDir == null) {
      await init();
    }

    if (isCached(track.id)) {
      return getCachedFilePath(track.id);
    }

    if (_downloadProgress.containsKey(track.id)) {
      // Already downloading in background
      return null;
    }

    _downloadProgress[track.id] = 0.0;
    notifyListeners();

    final targetFile = _getCacheFile(track.id);
    final tempFile = _getTempFile(track.id);

    try {
      if (await tempFile.exists()) {
        await tempFile.delete();
      }

      if (track.id.startsWith('yt_')) {
        // Direct authenticated stream chunking using YoutubeExplode
        final downloadedPath = await YouTubeMusicService.instance.downloadAudio(
          track.id,
          tempFile,
          onProgress: (p) {
            _downloadProgress[track.id] = p;
            onProgress?.call(p);
            notifyListeners();
          },
        );

        if (downloadedPath == null) {
          _downloadProgress.remove(track.id);
          notifyListeners();
          return null;
        }
      } else if (track.id.startsWith('spotify_') ||
          (track.remoteUrl?.startsWith('spotify:') ?? false)) {
        // Spotify streaming track: match to YouTube stream on the fly
        final matched = await AudioMatcherService.instance.matchTrack(track);
        if (matched == null) {
          debugPrint('[AudioCacheService] No audio match found for Spotify track: ${track.title} by ${track.artist}');
          _downloadProgress.remove(track.id);
          notifyListeners();
          return null;
        }

        final downloadedPath = await YouTubeMusicService.instance.downloadAudio(
          'yt_${matched.videoId}',
          tempFile,
          onProgress: (p) {
            _downloadProgress[track.id] = p;
            onProgress?.call(p);
            notifyListeners();
          },
        );

        if (downloadedPath == null) {
          _downloadProgress.remove(track.id);
          notifyListeners();
          return null;
        }
      } else {
        final streamUrl = track.streamUrl ?? track.remoteUrl;
        if (streamUrl == null || streamUrl.isEmpty || !streamUrl.startsWith('http')) {
          _downloadProgress.remove(track.id);
          notifyListeners();
          return null;
        }

        await _dio.download(
          streamUrl,
          tempFile.path,
          onReceiveProgress: (received, total) {
            if (total > 0) {
              final progress = (received / total).clamp(0.0, 1.0);
              _downloadProgress[track.id] = progress;
              onProgress?.call(progress);
              notifyListeners();
            }
          },
        );
      }


      if (await tempFile.exists() && await tempFile.length() > 0) {
        if (await targetFile.exists()) {
          await targetFile.delete();
        }
        await tempFile.rename(targetFile.path);
        _cachedTrackIds.add(track.id);
        _totalCacheBytes += await targetFile.length();
        debugPrint('[AudioCacheService] Track cached: ${track.title} -> ${targetFile.path}');
        return targetFile.path;
      }
      return null;
    } catch (e) {
      debugPrint('[AudioCacheService] Error caching track ${track.id}: $e');
      if (await tempFile.exists()) {
        try {
          await tempFile.delete();
        } catch (_) {}
      }
      return null;
    } finally {
      _downloadProgress.remove(track.id);
      notifyListeners();
    }
  }

  /// Smart Prefetching: Unduh lagu berikutnya di antrean secara hening di latar belakang
  Future<void> prefetchNextTrack(Track? nextTrack) async {
    if (nextTrack == null) return;
    if (isCached(nextTrack.id)) return;
    if (_downloadProgress.containsKey(nextTrack.id)) return;

    // Allow YouTube tracks (yt_) through — they use YoutubeExplode internally.
    // For non-YouTube tracks, require a streamUrl or remoteUrl.
    final hasUrl = (nextTrack.streamUrl != null && nextTrack.streamUrl!.isNotEmpty) ||
        (nextTrack.remoteUrl != null && nextTrack.remoteUrl!.isNotEmpty);
    if (!nextTrack.id.startsWith('yt_') && !hasUrl) return;

    debugPrint('[AudioCacheService] Prefetching next track in background: ${nextTrack.title}');
    try {
      await cacheTrack(nextTrack);
    } catch (e) {
      debugPrint('[AudioCacheService] Prefetch error: $e');
    }
  }

  /// Menghapus file track tertentu dari cache
  Future<void> deleteCachedTrack(String trackId) async {
    if (_cacheDir == null) return;
    final file = _getCacheFile(trackId);
    if (await file.exists()) {
      final size = await file.length();
      await file.delete();
      _totalCacheBytes = (_totalCacheBytes - size).clamp(0, double.infinity).toInt();
      _cachedTrackIds.remove(trackId);
      notifyListeners();
    }
  }

  /// Membersihkan seluruh cache audio
  Future<void> purgeCache() async {
    if (_cacheDir == null) return;
    try {
      final entities = _cacheDir!.listSync();
      for (final entity in entities) {
        if (entity is File) {
          await entity.delete();
        }
      }
      _cachedTrackIds.clear();
      _totalCacheBytes = 0;
      notifyListeners();
    } catch (e) {
      debugPrint('[AudioCacheService] Purge error: $e');
    }
  }
}
