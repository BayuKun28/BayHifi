import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/audio_engine/audio_cache_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bayhifi_cache_lru_test_');
    AudioCacheService.instance.setCacheDirForTesting(tempDir);
  });

  tearDown(() async {
    if (tempDir.existsSync()) {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    }
  });

  group('AudioCacheService LRU Eviction Tests', () {
    test('enforces quota by evicting oldest modified cache files down to 85% threshold', () async {
      final service = AudioCacheService.instance;
      // Set test ceiling to 300 KB
      service.maxCacheSizeBytes = 300 * 1024;

      // Create 4 mock cache files of 100 KB each (total 400 KB > 300 KB quota)
      final file1 = File('${tempDir.path}/track1.ogg');
      final file2 = File('${tempDir.path}/track2.ogg');
      final file3 = File('${tempDir.path}/track3.ogg');
      final file4 = File('${tempDir.path}/track4.ogg');

      await file1.writeAsBytes(List.filled(100 * 1024, 1));
      await file1.setLastModified(DateTime.now().subtract(const Duration(minutes: 40)));

      await file2.writeAsBytes(List.filled(100 * 1024, 2));
      await file2.setLastModified(DateTime.now().subtract(const Duration(minutes: 30)));

      await file3.writeAsBytes(List.filled(100 * 1024, 3));
      await file3.setLastModified(DateTime.now().subtract(const Duration(minutes: 20)));

      await file4.writeAsBytes(List.filled(100 * 1024, 4));
      await file4.setLastModified(DateTime.now().subtract(const Duration(minutes: 10)));

      await service.scanCache();

      // Target limit is 85% of 300 KB = 255 KB.
      // Total was 400 KB. Evicting track1 (100KB) leaves 300KB (still > 255KB).
      // Evicting track2 (100KB) leaves 200KB (<= 255KB).
      expect(file1.existsSync(), isFalse);
      expect(file2.existsSync(), isFalse);
      expect(file3.existsSync(), isTrue);
      expect(file4.existsSync(), isTrue);

      expect(service.isCached('track1'), isFalse);
      expect(service.isCached('track2'), isFalse);
      expect(service.isCached('track3'), isTrue);
      expect(service.isCached('track4'), isTrue);
      expect(service.totalCacheSizeBytes, equals(200 * 1024));
    });

    test('getCachedFilePath touches modified timestamp to protect active tracks from eviction', () async {
      final service = AudioCacheService.instance;
      service.maxCacheSizeBytes = 250 * 1024;

      final fileOld = File('${tempDir.path}/old_track.ogg');
      final fileActive = File('${tempDir.path}/active_track.ogg');
      final fileNew = File('${tempDir.path}/new_track.ogg');

      await fileOld.writeAsBytes(List.filled(100 * 1024, 1));
      await fileOld.setLastModified(DateTime.now().subtract(const Duration(minutes: 50)));

      await fileActive.writeAsBytes(List.filled(100 * 1024, 2));
      await fileActive.setLastModified(DateTime.now().subtract(const Duration(minutes: 40)));

      await fileNew.writeAsBytes(List.filled(100 * 1024, 3));
      await fileNew.setLastModified(DateTime.now().subtract(const Duration(minutes: 10)));

      // Refresh cache
      await service.scanCache();

      // Access active_track via getCachedFilePath, touching timestamp to now
      final path = service.getCachedFilePath('active_track');
      expect(path, isNotNull);

      // Trigger eviction
      await service.evictLruIfNeeded();

      // old_track was oldest and should be evicted, while active_track was touched and survives
      expect(fileOld.existsSync(), isFalse);
      expect(fileActive.existsSync(), isTrue);
      expect(fileNew.existsSync(), isTrue);
    });
  });
}
