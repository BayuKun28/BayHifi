import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/features/dashboard/presentation/dashboard_screen.dart';
import 'package:baydev_hifi/features/library/domain/library_collection_models.dart';
import 'package:baydev_hifi/features/library/presentation/controllers/library_controller.dart';
import 'package:baydev_hifi/features/library/presentation/unified_library_screen.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/youtube_music/presentation/controllers/youtube_music_controller.dart';
import 'package:baydev_hifi/features/youtube_music/presentation/youtube_discovery_screen.dart';

class _MockYouTubeMusicController extends YouTubeMusicController {
  _MockYouTubeMusicController(YouTubeMusicState initialState, Ref ref) : super(ref) {
    state = initialState;
  }

  @override
  void onQueryChanged(String newQuery) {}

  @override
  Future<void> fetchTrending({bool force = false}) async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final List<Track> mockTracks = [
    const Track(
      id: 'mock_local_1',
      title: 'Studio Master Track',
      artist: 'Studio Artist',
      album: 'Reference Album',
      duration: Duration(minutes: 4, seconds: 12),
      filePath: '/music/track1.flac',
      format: AudioFormat.flac,
      bitDepth: 24,
      sampleRate: 96000,
    ),
  ];

  group('YouTube Music HiFi Library & Dashboard Integration Tests', () {
    testWidgets('UnifiedLibraryScreen renders YouTube HiFi tab and navigates to YouTube tab when tapped', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      late UnifiedLibraryController controller;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            unifiedLibraryProvider.overrideWith((ref) {
              controller = UnifiedLibraryController();
              controller.state = controller.state.copyWith(
                tracks: mockTracks,
                currentTab: CollectionTab.tracks,
              );
              return controller;
            }),
            youtubeMusicControllerProvider.overrideWith(
              (ref) => _MockYouTubeMusicController(
                const YouTubeMusicState(trendingTracks: []),
                ref,
              ),
            ),
          ],
          child: const MaterialApp(
            home: UnifiedLibraryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Verify YouTube HiFi tab exists and tap it
      final youtubeTabFinder = find.text('YouTube HiFi');
      expect(youtubeTabFinder, findsOneWidget);

      await tester.tap(youtubeTabFinder);
      await tester.pumpAndSettle();

      // 2. Verify state tab switched to CollectionTab.youtube
      expect(controller.state.currentTab, CollectionTab.youtube);
      expect(find.byType(YouTubeDiscoveryScreen), findsOneWidget);
    });

    testWidgets('DashboardScreen renders Quick YouTube Music HiFi Launcher Capsule and navigates to YouTubeDiscoveryScreen', (tester) async {
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            unifiedLibraryProvider.overrideWith((ref) {
              final notifier = UnifiedLibraryController();
              notifier.state = notifier.state.copyWith(tracks: mockTracks);
              return notifier;
            }),
            youtubeMusicControllerProvider.overrideWith(
              (ref) => _MockYouTubeMusicController(
                const YouTubeMusicState(trendingTracks: []),
                ref,
              ),
            ),
          ],
          child: const MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify YouTube Launcher Capsule
      final ytLauncherFinder = find.textContaining('YouTube Music HiFi');
      expect(ytLauncherFinder, findsOneWidget);

      // Tap launcher to navigate to YouTubeDiscoveryScreen
      await tester.tap(ytLauncherFinder);
      await tester.pumpAndSettle();

      expect(find.byType(YouTubeDiscoveryScreen), findsOneWidget);
    });
  });
}
