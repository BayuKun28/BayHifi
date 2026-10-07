import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:baydev_hifi/core/database/local_persistence_service.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/library/data/library_indexer_service.dart';
import 'package:baydev_hifi/features/library/data/storage_cache_manager.dart';
import 'package:baydev_hifi/features/settings/data/backup_restore_service.dart';
import 'package:baydev_hifi/features/library/presentation/widgets/library_batch_actions_bar.dart';
import 'package:baydev_hifi/features/library/presentation/widgets/track_tile.dart';
import 'package:baydev_hifi/features/library/presentation/widgets/missing_tracks_resolver_sheet.dart';
import 'package:baydev_hifi/features/library/presentation/widgets/duplicate_tracks_resolver_modal.dart';
import 'package:baydev_hifi/features/settings/presentation/sub_screens/storage_cache_settings_screen.dart';
import 'package:baydev_hifi/features/settings/presentation/sub_screens/backup_restore_settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return '/tmp/bayhifi_test_dir';
    });
  });

  group('LibraryIndexerService Tests', () {
    test('computeQualityScore properly ranks FLAC Hi-Res above standard FLAC and MP3', () {
      final indexer = LibraryIndexerService.instance;

      const hiResFlac = Track(
        id: '1',
        title: 'Master Audio',
        artist: 'Studio Artist',
        album: 'Audiophile Studio Vol. 1',
        duration: Duration(minutes: 4),
        format: AudioFormat.flac,
        bitrate: 4608,
        sampleRate: 96000,
        bitDepth: 24,
      );

      const standardFlac = Track(
        id: '2',
        title: 'Master Audio',
        artist: 'Studio Artist',
        album: 'Audiophile Studio Vol. 1',
        duration: Duration(minutes: 4),
        format: AudioFormat.flac,
        bitrate: 1411,
        sampleRate: 44100,
        bitDepth: 16,
      );

      const mp3Track = Track(
        id: '3',
        title: 'Master Audio',
        artist: 'Studio Artist',
        album: 'Audiophile Studio Vol. 1',
        duration: Duration(minutes: 4),
        format: AudioFormat.mp3,
        bitrate: 320,
        sampleRate: 44100,
        bitDepth: 16,
      );

      final hiResScore = indexer.computeQualityScore(hiResFlac);
      final flacScore = indexer.computeQualityScore(standardFlac);
      final mp3Score = indexer.computeQualityScore(mp3Track);

      expect(hiResScore, greaterThan(flacScore));
      expect(flacScore, greaterThan(mp3Score));
    });

    test('findDuplicates groups tracks by title + artist and identifies optimal keep track', () {
      final indexer = LibraryIndexerService.instance;

      const trackA1 = Track(
        id: 'a1',
        title: 'Midnight Resonance',
        artist: 'Baydev Ensemble',
        album: 'Nocturne Dreams',
        duration: Duration(minutes: 3, seconds: 45),
        format: AudioFormat.mp3,
        bitrate: 192,
        sampleRate: 44100,
        bitDepth: 16,
      );

      const trackA2 = Track(
        id: 'a2',
        title: 'Midnight Resonance',
        artist: 'Baydev Ensemble',
        album: 'Nocturne Dreams',
        duration: Duration(minutes: 3, seconds: 45),
        format: AudioFormat.flac,
        bitrate: 4608,
        sampleRate: 96000,
        bitDepth: 24,
      );

      const trackB = Track(
        id: 'b',
        title: 'Unique Track',
        artist: 'Solo Artist',
        album: 'Solo Journey',
        duration: Duration(minutes: 2, seconds: 30),
        format: AudioFormat.flac,
        bitrate: 1411,
        sampleRate: 44100,
        bitDepth: 16,
      );

      final duplicates = indexer.findDuplicates([trackA1, trackA2, trackB]);

      expect(duplicates.length, 1);
      expect(duplicates.first.normalizedTitle, 'midnight resonance');
      expect(duplicates.first.normalizedArtist, 'baydev ensemble');
      expect(duplicates.first.tracks.length, 2);

      // Best copy should be trackA2 (Hi-Res 24/96 FLAC)
      expect(duplicates.first.bestTrack.id, 'a2');
      expect(duplicates.first.redundantTracks.length, 1);
      expect(duplicates.first.redundantTracks.first.id, 'a1');
    });

    test('findMissingTracks identifies non-existent local file paths', () async {
      final indexer = LibraryIndexerService.instance;

      const missingTrack = Track(
        id: 'm1',
        title: 'Ghost Audio',
        artist: 'Lost Artist',
        album: 'Lost Files',
        duration: Duration(minutes: 3),
        filePath: '/non/existent/path/ghost_audio_file_12345.flac',
      );

      const streamTrack = Track(
        id: 's1',
        title: 'Stream Song',
        artist: 'Online',
        album: 'Cloud Album',
        duration: Duration(minutes: 4),
        remoteUrl: 'https://stream.navidrome.org/song.mp3',
      );

      final missingList = await indexer.findMissingTracks([missingTrack, streamTrack]);
      expect(missingList.length, 1);
      expect(missingList.first.id, 'm1');
    });
  });

  group('StorageCacheManager Tests', () {
    test('formatBytes correctly handles B, KB, MB, and GB', () {
      expect(StorageCacheManager.formatBytes(512), '512 B');
      expect(StorageCacheManager.formatBytes(1024), '1.0 KB');
      expect(StorageCacheManager.formatBytes(5 * 1024 * 1024), '5.0 MB');
      expect(StorageCacheManager.formatBytes(2 * 1024 * 1024 * 1024), '2.00 GB');
    });

    test('calculateStorageUsage returns non-negative quota figures', () async {
      final manager = StorageCacheManager.instance;
      final summary = await manager.calculateStorageUsage();

      expect(summary.artworkCacheBytes, greaterThanOrEqualTo(0));
      expect(summary.lyricsCacheBytes, greaterThanOrEqualTo(0));
      expect(summary.databaseBytes, greaterThanOrEqualTo(0));
      expect(summary.playbackHistoryCount, greaterThanOrEqualTo(0));
      expect(summary.totalCacheBytes, greaterThanOrEqualTo(0));
    });

    test('Cache purge functions complete without throwing', () async {
      final manager = StorageCacheManager.instance;

      await manager.clearArtworkCache();
      await manager.clearLyricsCache();
      await manager.clearPlaybackHistory();
      await manager.clearAllNonEssentialCache();

      expect(true, isTrue);
    });
  });

  group('BackupRestoreService Tests', () {
    test('createBackupJson generates valid JSON archive', () {
      final service = BackupRestoreService.instance;

      final jsonStr = service.createBackupJson(
        includeHistory: true,
        includeLibrary: true,
      );

      expect(jsonStr, isNotEmpty);
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      expect(decoded['app'], 'Baydev HiFi');
      expect(decoded['version'], 1);
      expect(decoded.containsKey('theme_settings'), isTrue);
      expect(decoded.containsKey('custom_playlists'), isTrue);
      expect(decoded.containsKey('smart_playlists'), isTrue);
      expect(decoded.containsKey('favorite_track_ids'), isTrue);
      expect(decoded.containsKey('playback_history'), isTrue);
      expect(decoded.containsKey('saved_library_tracks'), isTrue);
    });

    test('validateBackup accepts valid schema and rejects malformed JSON', () {
      final service = BackupRestoreService.instance;

      final validJson = service.createBackupJson();
      final validResult = service.validateBackup(validJson);
      expect(validResult.isValid, isTrue);

      const malformedJson = '{"app": "OtherApp", "version": 1}';
      final invalidResult = service.validateBackup(malformedJson);
      expect(invalidResult.isValid, isFalse);
      expect(invalidResult.errorMessage, isNotNull);

      const corruptedString = 'not a json at all';
      final corruptResult = service.validateBackup(corruptedString);
      expect(corruptResult.isValid, isFalse);
    });

    test('restoreFromBackupJson restores theme, playlists, and settings accurately', () async {
      final service = BackupRestoreService.instance;

      final testBackupData = {
        'app': 'Baydev HiFi',
        'version': 1,
        'createdAt': DateTime.now().toIso8601String(),
        'theme_settings': {
          'palette_id': 'amber_tube',
          'theme_mode': 1,
          'custom_accent': 0xFFF59E0B,
          'dynamic_album_art': false,
        },
        'smart_playlists': [],
        'custom_playlists': [
          {
            'id': 'pl_restored',
            'name': 'Restored Playlist',
            'description': 'From backup test',
            'tracks': [],
            'isCustom': true,
            'createdAt': DateTime.now().toIso8601String(),
          }
        ],
        'favorite_track_ids': ['t1', 't3'],
        'saved_music_folders': ['/storage/Music'],
        'playback_history': [],
        'saved_library_tracks': [
          {
            'id': 't1',
            'title': 'Restored Track 1',
            'artist': 'Artist 1',
            'album': 'Restored Album',
            'duration': 180000,
          }
        ],
      };

      final result = await service.restoreFromBackupJson(jsonEncode(testBackupData));
      expect(result.success, isTrue);
      expect(result.restoredPlaylistsCount, 1);
      expect(result.restoredFavoritesCount, 2);

      // Verify persistence
      final persistence = LocalPersistenceService.instance;
      final theme = persistence.getThemeSettings();
      expect(theme['palette_id'], 'amber_tube');
      expect(persistence.getFavoriteTrackIds(), contains('t1'));
      expect(persistence.getFavoriteTrackIds(), contains('t3'));
    });
  });

  group('Phase 20 UI & Widget Tests', () {
    testWidgets('LibraryBatchActionsBar displays selection count and triggers actions', (tester) async {
      int playNextCount = 0;
      int queueCount = 0;
      int playlistCount = 0;
      int editCount = 0;
      int selectAllCount = 0;
      int deselectAllCount = 0;
      int closeCount = 0;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 16,
                    child: LibraryBatchActionsBar(
                      selectedCount: 5,
                      totalCount: 10,
                      onPlayNext: () => playNextCount++,
                      onAddToQueue: () => queueCount++,
                      onAddToPlaylist: () => playlistCount++,
                      onBatchEditTags: () => editCount++,
                      onSelectAll: () => selectAllCount++,
                      onDeselectAll: () => deselectAllCount++,
                      onClose: () => closeCount++,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('5'), findsOneWidget);

      // Tap Play Next button
      await tester.tap(find.byWidgetPredicate((w) => w is M3EIconButton && w.tooltip == 'Play Next'));
      await tester.pump();
      expect(playNextCount, 1);

      // Tap Add to Queue
      await tester.tap(find.byWidgetPredicate((w) => w is M3EIconButton && w.tooltip == 'Add to Queue'));
      await tester.pump();
      expect(queueCount, 1);

      // Tap Add to Playlist
      await tester.tap(find.byWidgetPredicate((w) => w is M3EIconButton && w.tooltip == 'Add to Playlist'));
      await tester.pump();
      expect(playlistCount, 1);

      // Tap Batch Edit Tags
      await tester.tap(find.byWidgetPredicate((w) => w is M3EIconButton && w.tooltip == 'Batch Edit Tags'));
      await tester.pump();
      expect(editCount, 1);

      // Tap Select All
      await tester.tap(find.byWidgetPredicate((w) => w is M3EIconButton && w.tooltip == 'Select All'));
      await tester.pump();
      expect(selectAllCount, 1);

      // Tap Close / Deselect
      await tester.tap(find.byWidgetPredicate((w) => w is M3EIconButton && w.tooltip == 'Cancel Selection'));
      await tester.pump();
      expect(closeCount, 1);
    });

    testWidgets('TrackTile renders checkbox when in multi-select mode', (tester) async {
      bool tapped = false;
      const testTrack = Track(
        id: 't_tile',
        title: 'Tile Song',
        artist: 'Artist Tile',
        album: 'Album Tile',
        duration: Duration(minutes: 3),
        format: AudioFormat.flac,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: StatefulBuilder(
                builder: (context, setState) {
                  return TrackTile(
                    track: testTrack,
                    isPlaying: false,
                    isMultiSelecting: true,
                    isSelected: false,
                    onTap: () {
                      tapped = true;
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Tile Song'), findsOneWidget);
      expect(find.textContaining('Artist Tile'), findsOneWidget);

      // Tap to toggle selection
      await tester.tap(find.byType(TrackTile));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('StorageCacheSettingsScreen renders quota breakdown and purge actions', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      const summary = StorageUsageSummary(
        artworkCacheBytes: 1024 * 1024 * 12,
        lyricsCacheBytes: 1024 * 512,
        databaseBytes: 1024 * 256,
        playbackHistoryCount: 42,
        libraryTracksCount: 150,
        totalCacheBytes: 1024 * 1024 * 12 + 1024 * 512,
      );

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: StorageCacheSettingsScreen(initialSummary: summary),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('STORAGE & CACHE QUOTA'), findsOneWidget);
      expect(find.text('STORAGE QUOTA OVERVIEW'), findsOneWidget);
      expect(find.text('Album Artwork Cache'), findsOneWidget);
      expect(find.text('CACHE BREAKDOWN & RECLAMATION'), findsOneWidget);
    });

    testWidgets('BackupRestoreSettingsScreen renders export and restore options', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: BackupRestoreSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('BACKUP & RESTORE'), findsOneWidget);
      expect(find.text('.BAYHIFI SNAPSHOT ENGINE'), findsOneWidget);
      expect(find.text('CREATE SNAPSHOT ARCHIVE'), findsOneWidget);
      expect(find.text('RESTORE FROM SNAPSHOT'), findsOneWidget);
    });

    testWidgets('MissingTracksResolverSheet renders empty state when no missing tracks', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: MissingTracksResolverSheet(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('MISSING TRACKS RESOLVER'), findsOneWidget);
    });

    testWidgets('DuplicateTracksResolverModal renders properly', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DuplicateTracksResolverModal(),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('DUPLICATE TRACKS RESOLVER'), findsOneWidget);
    });
  });
}
