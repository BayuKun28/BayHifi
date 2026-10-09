import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/youtube_music/presentation/controllers/youtube_music_controller.dart';
import 'package:baydev_hifi/features/youtube_music/presentation/widgets/youtube_import_playlist_dialog.dart';
import 'package:baydev_hifi/features/youtube_music/presentation/youtube_discovery_screen.dart';

void main() {
  group('YouTubeDiscoveryScreen & Import Dialog Widget Tests', () {
    testWidgets('YouTubeDiscoveryScreen renders search bar, filters, and SoLoud DSP telemetry',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            youtubeMusicControllerProvider.overrideWith(
              (ref) => _MockYouTubeMusicController(
                const YouTubeMusicState(trendingTracks: []),
                ref,
              ),
            ),
          ],
          child: const MaterialApp(
            home: YouTubeDiscoveryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('YOUTUBE MUSIC HIFI'), findsOneWidget);
      expect(find.textContaining('SOLOUD C++ DSP'), findsOneWidget);

      // Verify Search Bar & Quick Filters
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Top 100 Charts'), findsOneWidget);
      expect(find.text('Audiophile Masters'), findsOneWidget);
      expect(find.text('Acoustic Live'), findsOneWidget);
      expect(find.text('Hi-Res Mixes'), findsOneWidget);

      // Verify Bento Hero Feature Tags
      expect(find.text('C++ SOLOUD AUDIO PIPELINE'), findsOneWidget);
      expect(find.text('Pro-Q 10-Band EQ'), findsOneWidget);
      expect(find.text('AutoEQ IEM Calibration'), findsOneWidget);
      expect(find.text('Analog Tube Warmth'), findsOneWidget);
    });

    testWidgets('Selecting a filter chip updates search field and triggers query',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            youtubeMusicControllerProvider.overrideWith(
              (ref) => _MockYouTubeMusicController(
                const YouTubeMusicState(trendingTracks: []),
                ref,
              ),
            ),
          ],
          child: const MaterialApp(
            home: YouTubeDiscoveryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap on 'Top 100 Charts' filter chip
      await tester.tap(find.widgetWithText(ChoiceChip, 'Top 100 Charts'));
      await tester.pump(const Duration(milliseconds: 500));

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.controller?.text, equals('Top 100 Charts'));
    });

    testWidgets('YouTubeImportPlaylistDialog renders input field, actions and buttons',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: YouTubeImportPlaylistDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('IMPORT PLAYLIST'), findsOneWidget);
      expect(find.text('YouTube & YouTube Music'), findsOneWidget);
      expect(find.text('Add to Queue'), findsOneWidget);
      expect(find.text('Play All'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('YouTubeDiscoveryScreen displays search results correctly with OPUS format badges',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final mockTrack = Track(
        id: 'yt_test123',
        title: 'Bohemian Rhapsody',
        artist: 'Queen',
        album: 'YouTube Music',
        duration: const Duration(minutes: 5, seconds: 55),
        format: AudioFormat.opus,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            youtubeMusicControllerProvider.overrideWith(
              (ref) => _MockYouTubeMusicController(
                YouTubeMusicState(
                  query: 'Queen',
                  searchResults: [mockTrack],
                  isSearching: false,
                ),
                ref,
              ),
            ),
          ],
          child: const MaterialApp(
            home: YouTubeDiscoveryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('1 RESULTS FOUND'), findsOneWidget);
      expect(find.text('Bohemian Rhapsody'), findsOneWidget);
      expect(find.text('Queen'), findsOneWidget);
      expect(find.text('OPUS'), findsOneWidget);
      expect(find.text('Play All'), findsOneWidget);
    });

    testWidgets('YouTubeDiscoveryScreen quick filter chips have showCheckmark set to false',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            youtubeMusicControllerProvider.overrideWith(
              (ref) => _MockYouTubeMusicController(
                const YouTubeMusicState(trendingTracks: []),
                ref,
              ),
            ),
          ],
          child: const MaterialApp(
            home: YouTubeDiscoveryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip));
      expect(chips, isNotEmpty);
      for (final chip in chips) {
        expect(chip.showCheckmark, isFalse, reason: 'Chip ${chip.label} should not display a checkmark');
      }
    });
  });
}

class _MockYouTubeMusicController extends YouTubeMusicController {
  _MockYouTubeMusicController(YouTubeMusicState initialState, Ref ref) : super(ref) {
    state = initialState;
  }

  @override
  void onQueryChanged(String newQuery) {}

  @override
  Future<void> fetchTrending({bool force = false}) async {}
}
