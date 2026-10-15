import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/features/dashboard/presentation/widgets/studio_hero_showcase_carousel.dart';
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
    testWidgets('UnifiedLibraryScreen renders YouTube Quick Ribbon and navigates to YouTube tab when tapped', (tester) async {
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

      // 1. Scroll until YouTube tab is visible and verify it exists
      final youtubeTabFinder = find.text('YouTube');
      await tester.scrollUntilVisible(
        youtubeTabFinder,
        100.0,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(youtubeTabFinder, findsOneWidget);

      // 2. Tap YouTube tab
      await tester.tap(youtubeTabFinder);
      await tester.pumpAndSettle();

      // 3. Verify state tab switched to CollectionTab.youtube
      expect(controller.state.currentTab, CollectionTab.youtube);
      expect(find.byType(YouTubeDiscoveryScreen), findsOneWidget);
    });

    testWidgets('StudioHeroShowcaseCarousel renders YouTube Music HiFi showcase item and DISCOVER button', (tester) async {
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
            home: Scaffold(
              body: SingleChildScrollView(
                child: StudioHeroShowcaseCarousel(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Swipe to page 1 to see YouTube showcase
      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      // Verify YouTube showcase content
      expect(find.text('YouTube Music HiFi'), findsOneWidget);
      expect(find.text('OPUS 160K • DSP MASTER'), findsOneWidget);
      expect(find.text('DISCOVER'), findsOneWidget);

      // Tap DISCOVER to navigate to YouTubeDiscoveryScreen
      await tester.tap(find.text('DISCOVER'), warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.byType(YouTubeDiscoveryScreen), findsOneWidget);
    });
  });
}
