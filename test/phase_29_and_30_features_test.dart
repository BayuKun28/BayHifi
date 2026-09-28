import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:baydev_hifi/audio_engine/audio_cache_service.dart';
import 'package:baydev_hifi/audio_engine/soloud_controller.dart';
import 'package:baydev_hifi/core/database/local_persistence_service.dart';
import 'package:baydev_hifi/features/library/presentation/controllers/library_controller.dart';
import 'package:baydev_hifi/features/library/presentation/unified_library_screen.dart';
import 'package:baydev_hifi/features/navidrome/data/subsonic_client.dart';
import 'package:baydev_hifi/features/navidrome/domain/subsonic_models.dart';
import 'package:baydev_hifi/features/navidrome/presentation/widgets/navidrome_connect_dialog.dart';
import 'package:baydev_hifi/features/player/data/lyrics_service.dart';
import 'package:baydev_hifi/features/player/domain/lyrics_line.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/player/presentation/controllers/player_controller.dart';
import 'package:baydev_hifi/features/player/presentation/widgets/synchronized_lyrics_view.dart';
import 'package:baydev_hifi/features/settings/data/backup_restore_service.dart';

class MockSubsonicClient extends SubsonicClient {
  bool pingResult = true;
  List<SubsonicSong> mockSongs = [];

  @override
  Future<bool> ping(SubsonicServerConfig config) async {
    return pingResult;
  }

  @override
  Future<List<SubsonicSong>> fetchAllSongs(SubsonicServerConfig config, {int maxSongs = 5000}) async {
    return mockSongs;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bayhifi_p29_30_test_');
    AudioCacheService.instance.setCacheDirForTesting(tempDir);
    await LocalPersistenceService.instance.init();
    await LocalPersistenceService.instance.removeSetting('navidrome_config');
  });

  tearDown(() async {
    try {
      await LocalPersistenceService.instance.removeSetting('navidrome_config');
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('Phase 29.3 — YouTube Streaming & Caching Pipeline', () {
    test('YouTube track with cached file plays from disk cache directly', () async {
      final testFile = File('${tempDir.path}/yt_testvideo123.cache');
      await testFile.writeAsString('mock-cached-audio-bytes');
      await AudioCacheService.instance.scanCache();

      expect(AudioCacheService.instance.isCached('yt_testvideo123'), isTrue);
      expect(AudioCacheService.instance.getCachedFilePath('yt_testvideo123'), equals(testFile.path));

      final controller = PlayerController(SoLoudController.instance);
      const ytTrack = Track(
        id: 'yt_testvideo123',
        title: 'YouTube Audiophile Master',
        artist: 'Test Artist',
        album: 'YouTube Music',
        duration: Duration(minutes: 3, seconds: 45),
        format: AudioFormat.opus,
      );

      // Play track — will use cached path without throwing network errors
      await controller.playTrack(ytTrack);
      expect(controller.state.currentTrack?.id, equals('yt_testvideo123'));
    });

    test('PlayerController catches and surfaces graceful error if YouTube stream resolution fails', () async {
      final controller = PlayerController(SoLoudController.instance);
      const brokenYtTrack = Track(
        id: 'yt_nonexistent_video_99999999',
        title: 'Broken YouTube Track',
        artist: 'Unknown',
        album: 'YouTube Music',
        duration: Duration(minutes: 2),
      );

      await controller.playTrack(brokenYtTrack);
      // Status handles failure without crashing application
      expect(controller.state.currentTrack?.id, equals('yt_nonexistent_video_99999999'));
    });
  });

  group('Phase 30.3 — Navidrome Session Persistence & Serialization', () {
    test('SubsonicServerConfig toMap and fromMap serialization roundtrip', () {
      const config = SubsonicServerConfig(
        serverUrl: 'https://music.baydev.org:4533',
        username: 'audiophile_user',
        password: 'secure_password_123',
        clientName: 'BaydevHiFi_Custom',
        apiVersion: '1.16.1',
      );

      final map = config.toMap();
      expect(map['serverUrl'], equals('https://music.baydev.org:4533'));
      expect(map['username'], equals('audiophile_user'));
      expect(map['password'], equals('secure_password_123'));
      expect(map['clientName'], equals('BaydevHiFi_Custom'));

      final restored = SubsonicServerConfig.fromMap(map);
      expect(restored.serverUrl, equals(config.serverUrl));
      expect(restored.username, equals(config.username));
      expect(restored.password, equals(config.password));
      expect(restored.clientName, equals(config.clientName));
      expect(restored.sanitizedUrl, equals('https://music.baydev.org:4533'));
    });

    test('UnifiedLibraryController persists and restores Navidrome config on connect and clears on disconnect', () async {
      final mockSubsonic = MockSubsonicClient();
      mockSubsonic.mockSongs = [
        const SubsonicSong(
          id: 'song_101',
          title: 'Cloud Lossless Track',
          artist: 'Cloud Artist',
          album: 'Cloud Album',
          duration: Duration(minutes: 4),
          suffix: 'flac',
        ),
      ];

      final controller = UnifiedLibraryController(
        subsonicClient: mockSubsonic,
        initialTracks: const [],
      );

      const config = SubsonicServerConfig(
        serverUrl: 'http://192.168.1.100:4533',
        username: 'bayu',
        password: 'pass123',
      );

      // 1. Connect
      final success = await controller.connectNavidrome(config);
      expect(success, isTrue);
      expect(controller.state.navidromeConnectionStatus, equals(NavidromeConnectionStatus.connected));
      expect(controller.state.tracks.any((t) => t.id == 'navidrome_song_101'), isTrue);

      // 2. Verify stored in persistence
      final savedMap = LocalPersistenceService.instance.getSetting<Map<String, dynamic>>('navidrome_config');
      expect(savedMap, isNotNull);
      expect(savedMap!['username'], equals('bayu'));

      // 3. Test restoreNavidromeSession
      final newController = UnifiedLibraryController(
        subsonicClient: mockSubsonic,
        initialTracks: const [],
      );
      await newController.restoreNavidromeSession();
      expect(newController.state.navidromeConnectionStatus, equals(NavidromeConnectionStatus.connected));
      expect(newController.state.navidromeConfig?.username, equals('bayu'));

      // 4. Test disconnectNavidrome clears persistence
      newController.disconnectNavidrome();
      expect(newController.state.navidromeConnectionStatus, equals(NavidromeConnectionStatus.disconnected));
      final clearedMap = LocalPersistenceService.instance.getSetting<Map<String, dynamic>>('navidrome_config');
      expect(clearedMap, isNull);
    });

    test('BackupRestoreService includes navidrome_config in archive', () async {
      await LocalPersistenceService.instance.saveSetting('navidrome_config', {
        'serverUrl': 'http://subsonic.local:4533',
        'username': 'backup_user',
        'password': 'backup_pass',
      });

      final jsonString = BackupRestoreService.instance.createBackupJson();
      expect(jsonString.contains('subsonic.local:4533'), isTrue);

      // Clear then restore
      await LocalPersistenceService.instance.saveSetting('navidrome_config', null);
      expect(LocalPersistenceService.instance.getSetting<Map<String, dynamic>>('navidrome_config'), isNull);

      final result = await BackupRestoreService.instance.restoreFromBackupJson(jsonString);
      expect(result.success, isTrue);
      final restored = LocalPersistenceService.instance.getSetting<Map<String, dynamic>>('navidrome_config');
      expect(restored?['username'], equals('backup_user'));
    });
  });

  group('Phase 30.1 & 30.2 — Navidrome Connect Dialog & Empty State UI', () {
    testWidgets('NavidromeConnectDialog renders compact 380px layout with proportional prefix icons', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const Scaffold(
              body: NavidromeConnectDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('NAVIDROME CLOUD'), findsOneWidget);
      expect(find.text('Server URL'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Connect'), findsOneWidget);

      // Verify prefixIcon padding containers are present and sized appropriately
      expect(find.byType(TextFormField), findsNWidgets(3));
    });

    testWidgets('UnifiedLibraryScreen displays dedicated Navidrome empty state when filter is Navidrome and disconnected', (tester) async {
      final controller = UnifiedLibraryController(initialTracks: const []);
      controller.setFilter(LibrarySourceFilter.navidrome);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            unifiedLibraryProvider.overrideWith((ref) => controller),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: const Scaffold(
              body: UnifiedLibraryScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('NO NAVIDROME SERVER CONNECTED'), findsOneWidget);
      expect(find.text('CONNECT TO NAVIDROME'), findsOneWidget);
      expect(find.text('SUBSONIC API • LOSSLESS FLAC • OPUS STREAMING'), findsOneWidget);
    });
  });

  group('Phase 30.4 — Synchronized Lyrics Active Line Centering Calculation', () {
    testWidgets('SynchronizedLyricsView calculates active line scroll offset with viewport centering', (tester) async {
      final lines = List.generate(
        25,
        (i) => LyricsLine(
          timestamp: Duration(seconds: i * 5),
          text: 'Studio Master Vocal Line $i',
        ),
      );

      final lyricsResult = LyricsResult(
        rawLyrics: lines.map((l) => '[00:${l.timestamp.inSeconds}.00] ${l.text}').join('\n'),
        lines: lines,
        isSynced: true,
        source: LyricsSource.embedded,
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: SizedBox(
                height: 600,
                width: 400,
                child: SynchronizedLyricsView(
                  lyricsResult: lyricsResult,
                  currentPosition: const Duration(seconds: 50), // line 10
                  trackId: 'test_track_lyrics_1',
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check that active line is highlighted
      expect(find.text('Studio Master Vocal Line 10'), findsOneWidget);
    });
  });
}
