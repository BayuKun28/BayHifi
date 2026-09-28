import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../features/player/domain/track.dart';

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
    return File('${_cacheDir!.path}/$sanitized.cache');
  }

  File _getTempFile(String trackId) {
    final sanitized = _sanitizeId(trackId);
    return File('${_cacheDir!.path}/$sanitized.tmp');
  }

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
        if (entity is File && entity.path.endsWith('.cache')) {
          final size = entity.lengthSync();
          if (size > 0) {
            bytes += size;
            final fileName = entity.uri.pathSegments.last;
            final trackId = fileName.substring(0, fileName.length - '.cache'.length);
            _cachedTrackIds.add(trackId);
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
        if (entity is File && entity.path.endsWith('.cache')) {
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

    final streamUrl = track.streamUrl;
    if (streamUrl == null || streamUrl.isEmpty) {
      return null;
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
    if (nextTrack.streamUrl == null || isCached(nextTrack.id)) return;
    if (_downloadProgress.containsKey(nextTrack.id)) return;

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
