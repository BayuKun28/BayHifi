import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/app/theme/theme_mode_controller.dart';
import 'package:baydev_hifi/audio_engine/audio_cache_service.dart';
import 'package:baydev_hifi/core/database/local_persistence_service.dart';
import 'package:baydev_hifi/features/cloud_sync/data/cloud_sync_service.dart';
import 'package:baydev_hifi/features/cloud_sync/domain/user_profile.dart';
import 'package:baydev_hifi/features/cloud_sync/presentation/controllers/cloud_auth_controller.dart';
import 'package:baydev_hifi/features/pro_q_studio/domain/pro_q_rta_style.dart';
import 'package:baydev_hifi/features/settings/presentation/controllers/player_customization_controller.dart';

class MockCloudSyncService extends CloudSyncService {
  Map<String, dynamic>? mockRemoteSettings;
  List<Map<String, dynamic>> mockRemoteLogs = [];

  @override
  Future<Map<String, dynamic>> getSavedSession() async {
    return {
      'serverUrl': 'http://localhost:8111',
      'token': null,
      'user': null,
    };
  }

  @override
  Future<Map<String, dynamic>> login({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    if (username == 'user_audiophile' && password == 'password123') {
      return {
        'success': true,
        'token': 'jwt_mock_token_abc123',
        'user': UserProfile(
          id: 'user_audiophile',
          username: 'user_audiophile',
          email: 'audiophile@baydev.studio',
          createdAt: DateTime(2026, 1, 1),
        ),
      };
    }
    return {'success': false, 'message': 'Invalid credentials'};
  }

  @override
  Future<Map<String, dynamic>?> fetchUserSettings({
    required String serverUrl,
    required String token,
  }) async {
    return mockRemoteSettings;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchPlaybackLogs({
    required String serverUrl,
    required String token,
    int limit = 500,
  }) async {
    return mockRemoteLogs;
  }

  @override
  Future<bool> saveUserSettings({
    required String serverUrl,
    required String token,
    required Map<String, dynamic> settings,
  }) async {
    mockRemoteSettings = Map<String, dynamic>.from(settings);
    return true;
  }

  @override
  Future<int> syncPlaybackLogs({
    required String serverUrl,
    required String token,
    required List<Map<String, dynamic>> logs,
  }) async {
    mockRemoteLogs = List<Map<String, dynamic>>.from(logs);
    return logs.length;
  }

  @override
  Future<bool> syncDspProfile({
    required String serverUrl,
    required String token,
    required Map<String, dynamic> dspData,
  }) async {
    return true;
  }

  @override
  Future<void> clearSession() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bayhifi_user_isolation_test');
    await LocalPersistenceService.instance.init(customPath: '${tempDir.path}/test_storage.json');
    await LocalPersistenceService.instance.switchUser('guest');
    AudioCacheService.instance.setCacheDirForTesting(tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('LocalPersistenceService Multi-User Scoping & Partitioning Tests', () {
    test('Default user is guest and default RTA style is wireframe', () {
      expect(LocalPersistenceService.instance.activeUserId, 'guest');
      final rta = LocalPersistenceService.instance.getSetting<String>('pro_q_rta_style');
      expect(rta, isNull); // unconfigured fallback resolves to wireframe
      expect(ProQRtaStyle.fromString(rta), ProQRtaStyle.wireframe);
    });

    test('User A settings and favorites do not bleed into User B or Guest', () async {
      final storage = LocalPersistenceService.instance;

      // 1. Configure User A
      await storage.switchUser('user_a', cloneGuestIfEmpty: false);
      expect(storage.activeUserId, 'user_a');
      await storage.saveSetting('pro_q_rta_style', ProQRtaStyle.filledCurve.name);
      await storage.saveFavoriteTrackIds({'track_user_a_1', 'track_user_a_2'});
      await storage.saveCustomPlaylists([
        {'id': 'pl_a', 'name': 'User A Chill Playlist'}
      ]);

      expect(storage.getSetting<String>('pro_q_rta_style'), ProQRtaStyle.filledCurve.name);
      expect(storage.getFavoriteTrackIds(), ['track_user_a_1', 'track_user_a_2']);
      expect(storage.getCustomPlaylists().first['name'], 'User A Chill Playlist');

      // 2. Switch to User B
      await storage.switchUser('user_b', cloneGuestIfEmpty: false);
      expect(storage.activeUserId, 'user_b');
      expect(storage.getSetting<String>('pro_q_rta_style'), isNull);
      expect(storage.getFavoriteTrackIds(), isEmpty);
      expect(storage.getCustomPlaylists(), isEmpty);

      // Configure User B with different preferences
      await storage.saveSetting('pro_q_rta_style', ProQRtaStyle.bars.name);
      await storage.saveFavoriteTrackIds({'track_user_b_jazz'});
      await storage.saveCustomPlaylists([
        {'id': 'pl_b', 'name': 'User B Jazz Masters'}
      ]);

      expect(storage.getSetting<String>('pro_q_rta_style'), ProQRtaStyle.bars.name);
      expect(storage.getFavoriteTrackIds(), ['track_user_b_jazz']);
      expect(storage.getCustomPlaylists().first['name'], 'User B Jazz Masters');

      // 3. Switch back to User A and verify zero bleed / full preservation
      await storage.switchUser('user_a');
      expect(storage.activeUserId, 'user_a');
      expect(storage.getSetting<String>('pro_q_rta_style'), ProQRtaStyle.filledCurve.name);
      expect(storage.getFavoriteTrackIds(), ['track_user_a_1', 'track_user_a_2']);
      expect(storage.getCustomPlaylists().first['name'], 'User A Chill Playlist');

      // 4. Switch to Guest and verify cleanliness
      await storage.switchUser('guest');
      expect(storage.activeUserId, 'guest');
      expect(storage.getFavoriteTrackIds(), isEmpty);
    });

    test('Playback telemetry logs and Wrapped statistics are isolated per user', () async {
      final storage = LocalPersistenceService.instance;

      // Log sessions for User 1
      await storage.switchUser('user_1', cloneGuestIfEmpty: false);
      await storage.logPlaybackSession({
        'id': 'log_1',
        'trackTitle': 'Kind of Blue',
        'artist': 'Miles Davis',
        'durationMs': 180000,
        'playedAt': 1700000000,
      });

      expect(storage.getPlaybackHistoryLogs().length, 1);
      expect(storage.getPlaybackHistoryLogs().first['trackTitle'], 'Kind of Blue');

      // Switch to User 2
      await storage.switchUser('user_2', cloneGuestIfEmpty: false);
      expect(storage.getPlaybackHistoryLogs(), isEmpty);

      await storage.logPlaybackSession({
        'id': 'log_2',
        'trackTitle': 'Time Out',
        'artist': 'Dave Brubeck',
        'durationMs': 210000,
        'playedAt': 1700001000,
      });

      expect(storage.getPlaybackHistoryLogs().length, 1);
      expect(storage.getPlaybackHistoryLogs().first['trackTitle'], 'Time Out');

      // Switch back to User 1
      await storage.switchUser('user_1');
      expect(storage.getPlaybackHistoryLogs().length, 1);
      expect(storage.getPlaybackHistoryLogs().first['trackTitle'], 'Kind of Blue');
    });

    test('Global keys (music folders, library tracks, window geometry) remain shared', () async {
      final storage = LocalPersistenceService.instance;

      await storage.switchUser('user_x');
      await storage.saveMusicFolders(['/music/hi_res', '/music/dsd']);
      await storage.saveLibraryTracks([
        {'id': 'shared_track_1', 'title': 'Audiophile Reference 1'}
      ]);

      // Switch to User Y
      await storage.switchUser('user_y');
      expect(storage.getMusicFolders(), ['/music/hi_res', '/music/dsd']);
      expect(storage.getSavedLibraryTracks().length, 1);
      expect(storage.getSavedLibraryTracks().first['title'], 'Audiophile Reference 1');
    });

    test('Cloning on first user registration copies guest preferences', () async {
      final storage = LocalPersistenceService.instance;

      // Guest sets custom RTA style and theme
      await storage.switchUser('guest');
      await storage.saveSetting('pro_q_rta_style', ProQRtaStyle.peakDots.name);
      await storage.saveThemeSettings(
        paletteId: 'gold_sunburst',
        themeModeIndex: 1, // light
        customAccentColorValue: 0xFFFFD700,
        dynamicAlbumArtEnabled: true,
      );

      // New user logs in with cloneGuestIfEmpty: true
      await storage.switchUser('brand_new_user', cloneGuestIfEmpty: true);
      expect(storage.getSetting<String>('pro_q_rta_style'), ProQRtaStyle.peakDots.name);
      final theme = storage.getThemeSettings();
      expect(theme['palette_id'], 'gold_sunburst');

      // Brand new user modifies their settings
      await storage.saveSetting('pro_q_rta_style', ProQRtaStyle.laserBeam.name);
      expect(storage.getSetting<String>('pro_q_rta_style'), ProQRtaStyle.laserBeam.name);

      // Guest remains unaffected
      await storage.switchUser('guest');
      expect(storage.getSetting<String>('pro_q_rta_style'), ProQRtaStyle.peakDots.name);
    });

    test('exportCurrentUserSettings and importCurrentUserSettings works accurately', () async {
      final storage = LocalPersistenceService.instance;
      await storage.switchUser('export_user', cloneGuestIfEmpty: false);

      await storage.saveSetting('pro_q_rta_style', ProQRtaStyle.m3Pillars.name);
      await storage.saveFavoriteTrackIds({'fav_1', 'fav_2'});

      final bundle = storage.exportCurrentUserSettings();
      expect(bundle['pro_q_rta_style'], ProQRtaStyle.m3Pillars.name);
      expect(bundle['favorite_track_ids'], ['fav_1', 'fav_2']);

      // Switch to target user and import bundle
      await storage.switchUser('import_user', cloneGuestIfEmpty: false);
      expect(storage.getSetting<String>('pro_q_rta_style'), isNull);

      await storage.importCurrentUserSettings(bundle);
      expect(storage.getSetting<String>('pro_q_rta_style'), ProQRtaStyle.m3Pillars.name);
      expect(storage.getFavoriteTrackIds(), ['fav_1', 'fav_2']);
    });

    test('importPlaybackLogs deduplicates logs by log ID', () async {
      final storage = LocalPersistenceService.instance;
      await storage.switchUser('logs_user', cloneGuestIfEmpty: false);

      await storage.logPlaybackSession({'id': 'log_A', 'trackTitle': 'A', 'playedAt': 100});
      expect(storage.getPlaybackHistoryLogs().length, 1);

      // Import batch containing log_A duplicate and new log_B
      await storage.importPlaybackLogs([
        {'id': 'log_A', 'trackTitle': 'A (duplicate)', 'playedAt': 100},
        {'id': 'log_B', 'trackTitle': 'B', 'playedAt': 200},
      ]);

      final allLogs = storage.getPlaybackHistoryLogs();
      expect(allLogs.length, 2);
      expect(allLogs.map((l) => l['id']).toList(), ['log_A', 'log_B']);
    });
  });

  group('CloudAuthController Login/Logout and Auto-Apply Dynamic Verification', () {
    test('Login auto-applies remote settings into active controllers and theme', () async {
      final mockService = MockCloudSyncService();
      mockService.mockRemoteSettings = {
        'pro_q_rta_style': ProQRtaStyle.filledCurve.name,
        'favorite_track_ids': ['remote_fav_1', 'remote_fav_2'],
        'theme_settings': {
          'palette_id': 'namida_cyan',
          'theme_mode': 2,
          'custom_accent': 0xFF00E5FF,
          'dynamic_album_art': false,
          'surface_fill_style': 'solid',
        },
      };
      mockService.mockRemoteLogs = [
        {'id': 'remote_log_1', 'trackTitle': 'Cloud Hi-Res Track', 'playedAt': 1700000000}
      ];

      final container = ProviderContainer(
        overrides: [
          cloudSyncServiceProvider.overrideWithValue(mockService),
        ],
      );
      addTearDown(container.dispose);

      final authNotifier = container.read(cloudAuthControllerProvider.notifier);

      // Verify initial guest state
      expect(container.read(cloudAuthControllerProvider).isGuest, isTrue);
      expect(container.read(playerCustomizationProvider).proQRtaStyle, ProQRtaStyle.wireframe);

      // Execute login
      final success = await authNotifier.login(
        serverUrl: 'http://localhost:8111',
        username: 'user_audiophile',
        password: 'password123',
      );

      expect(success, isTrue);
      expect(container.read(cloudAuthControllerProvider).isAuthenticated, isTrue);
      expect(LocalPersistenceService.instance.activeUserId, 'user_audiophile');

      // Verify that playerCustomizationProvider auto-applied the remote pro_q_rta_style
      expect(container.read(playerCustomizationProvider).proQRtaStyle, ProQRtaStyle.filledCurve);

      // Verify that remote logs were imported
      final logs = LocalPersistenceService.instance.getPlaybackHistoryLogs();
      expect(logs.length, 1);
      expect(logs.first['trackTitle'], 'Cloud Hi-Res Track');

      // Verify that themeControllerProvider auto-applied the remote theme
      final activeTheme = container.read(themeControllerProvider);
      expect(activeTheme.surfaceFillStyle, SurfaceFillStyle.solid);

      // Execute logout
      await authNotifier.logout();

      // Verify that active partition reverted to guest
      expect(container.read(cloudAuthControllerProvider).isGuest, isTrue);
      expect(LocalPersistenceService.instance.activeUserId, 'guest');
      // Guest state auto-reloads clean preferences
      expect(container.read(playerCustomizationProvider).proQRtaStyle, ProQRtaStyle.wireframe);
    });
  });
}
