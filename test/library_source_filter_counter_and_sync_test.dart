import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/core/database/local_persistence_service.dart';
import 'package:baydev_hifi/features/cloud_sync/data/cloud_sync_service.dart';
import 'package:baydev_hifi/features/cloud_sync/domain/user_profile.dart';
import 'package:baydev_hifi/features/cloud_sync/presentation/controllers/cloud_auth_controller.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/library/presentation/controllers/library_controller.dart';
import 'package:baydev_hifi/features/library/presentation/unified_library_screen.dart';
import 'package:baydev_hifi/features/settings/presentation/controllers/player_customization_controller.dart';
import 'package:baydev_hifi/features/pro_q_studio/domain/pro_q_rta_style.dart';

class MockCloudSyncServiceForTests extends CloudSyncService {
  Map<String, dynamic>? mockRemoteSettings;
  List<Map<String, dynamic>> mockRemoteLogs = [];
  Map<String, dynamic>? mockRemoteDsp;

  bool didPushLogs = false;
  bool didPushDsp = false;
  bool didPushSettings = false;

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
    if (username == 'sync_user' && password == 'pass123') {
      return {
        'success': true,
        'token': 'mock_jwt_token_456',
        'user': UserProfile(
          id: 'sync_user',
          username: 'sync_user',
          email: 'sync_user@baydev.studio',
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
  Future<Map<String, dynamic>?> fetchDspProfile({
    required String serverUrl,
    required String token,
  }) async {
    return mockRemoteDsp;
  }

  @override
  Future<int> syncPlaybackLogs({
    required String serverUrl,
    required String token,
    required List<Map<String, dynamic>> logs,
  }) async {
    didPushLogs = true;
    return logs.length;
  }

  @override
  Future<bool> syncDspProfile({
    required String serverUrl,
    required String token,
    required Map<String, dynamic> dspData,
  }) async {
    didPushDsp = true;
    return true;
  }

  @override
  Future<bool> saveUserSettings({
    required String serverUrl,
    required String token,
    required Map<String, dynamic> settings,
  }) async {
    didPushSettings = true;
    return true;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Library Source Filter Counter Chips Tests', () {
    testWidgets('Tracks category chip reflects filtered tracks count when source filter is applied',
        (tester) async {
      final testTracks = [
        Track(
          id: 'local_1',
          title: 'Offline FLAC Song',
          artist: 'Offline Artist',
          album: 'Offline Album',
          filePath: '/storage/music/song1.flac',
          duration: const Duration(minutes: 3),
        ),
        Track(
          id: 'local_2',
          title: 'Offline WAV Song',
          artist: 'Offline Artist 2',
          album: 'Offline Album 2',
          filePath: '/storage/music/song2.wav',
          duration: const Duration(minutes: 4),
        ),
        Track(
          id: 'spotify_cloud_1',
          title: 'Cloud Stream Song',
          artist: 'Cloud Artist',
          album: 'Cloud Album',
          filePath: null,
          remoteUrl: 'https://stream.baydev.studio/cloud1.opus',
          duration: const Duration(minutes: 5),
        ),
      ];

      final container = ProviderContainer(
        overrides: [
          unifiedLibraryProvider.overrideWith((ref) {
            final c = UnifiedLibraryController();
            c.saveLibraryTracks(testTracks);
            return c;
          }),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: UnifiedLibraryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initially, with LibrarySourceFilter.all: 3 tracks total
      final controller = container.read(unifiedLibraryProvider.notifier);
      expect(container.read(unifiedLibraryProvider).selectedFilter, LibrarySourceFilter.all);
      expect(container.read(unifiedLibraryProvider).filteredTracks.length, 3);
      expect(find.text('Tracks'), findsOneWidget);
      expect(find.text('3'), findsAtLeastNWidgets(1));

      // Now switch source filter to cloud (e.g. via FAB or controller)
      controller.setFilter(LibrarySourceFilter.cloud);
      await tester.pumpAndSettle();

      // Under cloud filter, only 1 track and 1 album should match
      expect(container.read(unifiedLibraryProvider).filteredTracks.length, 1);
      expect(find.text('Tracks'), findsOneWidget);
      expect(find.text('1'), findsAtLeastNWidgets(1));

      // Switch back to offline local
      controller.setFilter(LibrarySourceFilter.offline);
      await tester.pumpAndSettle();

      // Under offline filter, 2 tracks and 2 albums match
      expect(container.read(unifiedLibraryProvider).filteredTracks.length, 2);
      expect(find.text('Tracks'), findsOneWidget);
      expect(find.text('2'), findsAtLeastNWidgets(1));

      // Switch back to all
      controller.setFilter(LibrarySourceFilter.all);
      await tester.pumpAndSettle();
      expect(container.read(unifiedLibraryProvider).filteredTracks.length, 3);
      expect(find.text('3'), findsAtLeastNWidgets(1));
    });
  });

  group('CloudAuthController Bidirectional Sync on Login Tests', () {
    test('Login immediately pulls remote settings, logs, and DSP profile, then pushes and syncs', () async {
      final mock = MockCloudSyncServiceForTests();
      mock.mockRemoteSettings = {
        'pro_q_rta_style': ProQRtaStyle.filledCurve.name,
        'favorite_track_ids': ['cloud_fav_1', 'cloud_fav_2'],
      };
      mock.mockRemoteLogs = [
        {'id': 'cloud_log_1', 'trackTitle': 'Hi-Res Remote FLAC', 'playedAt': 1705000000}
      ];
      mock.mockRemoteDsp = {
        'activePresetName': 'Harman Target 2026',
        'safePreampDb': -3.0,
        'bands': [
          {'freq': 63.0, 'gain': 2.5, 'q': 1.414, 'type': 'peaking'},
          {'freq': 2500.0, 'gain': -1.8, 'q': 2.0, 'type': 'peaking'},
        ],
        'dspToggles': {
          'tubeEnabled': true,
          'limiterEnabled': true,
        },
      };

      final container = ProviderContainer(
        overrides: [
          cloudSyncServiceProvider.overrideWithValue(mock),
        ],
      );
      addTearDown(container.dispose);

      final authNotifier = container.read(cloudAuthControllerProvider.notifier);

      // Execute login
      final success = await authNotifier.login(
        serverUrl: 'http://localhost:8111',
        username: 'sync_user',
        password: 'pass123',
      );

      expect(success, isTrue);
      expect(container.read(cloudAuthControllerProvider).isAuthenticated, isTrue);

      // Verify that remote settings were applied
      expect(container.read(playerCustomizationProvider).proQRtaStyle, ProQRtaStyle.filledCurve);

      // Verify remote logs were imported
      final logs = LocalPersistenceService.instance.getPlaybackHistoryLogs();
      expect(logs.any((l) => l['id'] == 'cloud_log_1'), isTrue);

      // Verify remote DSP profile was imported
      final eq = LocalPersistenceService.instance.getActiveEqState();
      expect(eq?['activePresetName'], 'Harman Target 2026');
      expect((eq?['bands'] as List).length, 2);

      // Verify push occurred during login
      expect(mock.didPushLogs, isTrue);
      expect(mock.didPushDsp, isTrue);
      expect(mock.didPushSettings, isTrue);
    });

    test('syncNow performs bidirectional get and push', () async {
      final mock = MockCloudSyncServiceForTests();
      mock.mockRemoteSettings = {
        'pro_q_rta_style': ProQRtaStyle.m3Pillars.name,
      };

      final container = ProviderContainer(
        overrides: [
          cloudSyncServiceProvider.overrideWithValue(mock),
        ],
      );
      addTearDown(container.dispose);

      final authNotifier = container.read(cloudAuthControllerProvider.notifier);

      // Login first
      await authNotifier.login(
        serverUrl: 'http://localhost:8111',
        username: 'sync_user',
        password: 'pass123',
      );

      mock.didPushLogs = false;
      mock.didPushDsp = false;
      mock.didPushSettings = false;

      // Trigger syncNow explicitly
      await authNotifier.syncNow();

      expect(mock.didPushLogs, isTrue);
      expect(mock.didPushDsp, isTrue);
      expect(mock.didPushSettings, isTrue);
      expect(container.read(cloudAuthControllerProvider).lastSyncedAt, isNotNull);
    });
  });
}
