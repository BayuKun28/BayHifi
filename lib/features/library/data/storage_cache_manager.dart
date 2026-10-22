import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../../../core/database/local_persistence_service.dart';
import 'artist_metadata_service.dart';

/// Comprehensive snapshot of Baydev HiFi storage usage & cache breakdown
class StorageUsageSummary {
  final int artworkCacheBytes;
  final int lyricsCacheBytes;
  final int databaseBytes;
  final int playbackHistoryCount;
  final int libraryTracksCount;
  final int totalCacheBytes;

  const StorageUsageSummary({
    required this.artworkCacheBytes,
    required this.lyricsCacheBytes,
    required this.databaseBytes,
    required this.playbackHistoryCount,
    required this.libraryTracksCount,
    required this.totalCacheBytes,
  });

  String get formattedArtworkCache => formatBytes(artworkCacheBytes);
  String get formattedLyricsCache => formatBytes(lyricsCacheBytes);
  String get formattedDatabaseSize => formatBytes(databaseBytes);
  String get formattedTotalCache => formatBytes(totalCacheBytes);

  static String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }
}

/// Disk Quota & Cache Maintenance Manager
class StorageCacheManager {
  static StorageCacheManager? _instance;
  static StorageCacheManager get instance => _instance ??= StorageCacheManager._();

  StorageCacheManager._();

  static String formatBytes(int bytes) => StorageUsageSummary.formatBytes(bytes);

  /// Calculate disk usage across artwork, lyrics, database, and temporary files
  Future<StorageUsageSummary> calculateStorageUsage() async {
    int artworkBytes = 0;
    int lyricsBytes = 0;
    int dbBytes = 0;
    int historyCount = 0;
    int tracksCount = 0;

    try {
      final appDocDir = await getApplicationDocumentsDirectory();

      // 1. Artwork Cache & Artist Covers
      final artworkDir = Directory('${appDocDir.path}/artwork_cache');
      if (await artworkDir.exists()) {
        artworkBytes += await _getDirectorySize(artworkDir);
      }
      final artistCoversDir = Directory('${appDocDir.path}/artist_covers');
      if (await artistCoversDir.exists()) {
        artworkBytes += await _getDirectorySize(artistCoversDir);
      }

      // 2. Lyrics Cache
      final lyricsDir = Directory('${appDocDir.path}/lyrics_cache');
      if (await lyricsDir.exists()) {
        lyricsBytes += await _getDirectorySize(lyricsDir);
      }

      // Also check temp directory for cached images
      try {
        final tempDir = await getTemporaryDirectory();
        if (await tempDir.exists()) {
          final tempArtDir = Directory('${tempDir.path}/artwork_cache');
          if (await tempArtDir.exists()) {
            artworkBytes += await _getDirectorySize(tempArtDir);
          }
        }
      } catch (_) {}

      // 3. Database Size
      final dbFile = File('${appDocDir.path}/baydev_hifi_storage.json');
      if (await dbFile.exists()) {
        dbBytes = await dbFile.length();
      }

      // 4. Persistence metrics
      historyCount = LocalPersistenceService.instance.getPlaybackHistory().length;
      tracksCount = LocalPersistenceService.instance.getSavedLibraryTracks().length;
    } catch (e) {
      debugPrint('[StorageCacheManager] Error calculating storage usage: $e');
    }

    final totalBytes = artworkBytes + lyricsBytes;

    return StorageUsageSummary(
      artworkCacheBytes: artworkBytes,
      lyricsCacheBytes: lyricsBytes,
      databaseBytes: dbBytes,
      playbackHistoryCount: historyCount,
      libraryTracksCount: tracksCount,
      totalCacheBytes: totalBytes,
    );
  }

  /// Purge all cached album artwork thumbnails
  Future<void> clearArtworkCache() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final artworkDir = Directory('${appDocDir.path}/artwork_cache');
      if (await artworkDir.exists()) {
        await artworkDir.delete(recursive: true);
      }

      final artistCoversDir = Directory('${appDocDir.path}/artist_covers');
      if (await artistCoversDir.exists()) {
        await artistCoversDir.delete(recursive: true);
      }
      ArtistMetadataService.instance.clearMemoryCache();

      try {
        final tempDir = await getTemporaryDirectory();
        final tempArtDir = Directory('${tempDir.path}/artwork_cache');
        if (await tempArtDir.exists()) {
          await tempArtDir.delete(recursive: true);
        }
      } catch (_) {}
    } catch (e) {
      debugPrint('[StorageCacheManager] Error clearing artwork cache: $e');
    }
  }

  /// Purge all locally cached lyrics files
  Future<void> clearLyricsCache() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final lyricsDir = Directory('${appDocDir.path}/lyrics_cache');
      if (await lyricsDir.exists()) {
        await lyricsDir.delete(recursive: true);
      }
    } catch (e) {
      debugPrint('[StorageCacheManager] Error clearing lyrics cache: $e');
    }
  }

  /// Clear playback history entries from persistent storage
  Future<void> clearPlaybackHistory() async {
    await LocalPersistenceService.instance.clearPlaybackHistory();
  }

  /// 1-Click Clear all non-essential temporary caches
  Future<void> clearAllNonEssentialCache() async {
    await clearArtworkCache();
    await clearLyricsCache();
  }

  Future<int> _getDirectorySize(Directory dir) async {
    int size = 0;
    try {
      await for (final entity in dir.list(recursive: true, followLinks: false)) {
        if (entity is File) {
          size += await entity.length();
        }
      }
    } catch (e) {
      debugPrint('[StorageCacheManager] Directory size read notice: $e');
    }
    return size;
  }
}
