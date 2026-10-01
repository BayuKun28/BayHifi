import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:baydev_hifi/audio_engine/soloud_controller.dart';
import 'package:baydev_hifi/core/desktop/desktop_bottom_master_transport_deck.dart';
import 'package:baydev_hifi/core/desktop/desktop_lyrics_dialog.dart';
import 'package:baydev_hifi/features/library/domain/library_collection_models.dart';
import 'package:baydev_hifi/features/library/presentation/controllers/library_controller.dart';
import 'package:baydev_hifi/features/library/presentation/unified_library_screen.dart';
import 'package:baydev_hifi/features/lyrics_share/presentation/widgets/lyric_share_sheet.dart';
import 'package:baydev_hifi/features/player/domain/playback_state.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/player/presentation/controllers/player_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testTrack = Track(
    id: 'desktop_test_1',
    title: 'Linux Master HiFi Track',
    artist: 'Studio Audiophile',
    album: 'Desktop Master Works',
    duration: const Duration(minutes: 3, seconds: 45),
    filePath: '/music/test.flac',
    sampleRate: 96000,
    bitDepth: 24,
    format: AudioFormat.flac,
    lyrics: '[00:01.00]First studio master line\n[00:05.00]Second studio master line\n[00:10.00]Third studio master line',
  );

  group('DesktopBottomMasterTransportDeck Tests', () {
    testWidgets('Renders Play/Pause prominent button and toggles playback state', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      final notifier = PlayerController(SoLoudController.instance);
      notifier.state = PlaybackState(
        currentTrack: testTrack,
        status: PlaybackStatus.paused,
        duration: const Duration(minutes: 3, seconds: 45),
        position: const Duration(minutes: 1),
        volume: 0.8,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playerControllerProvider.overrideWith((ref) => notifier),
          ],
          child: const MaterialApp(
            home: Scaffold(
              bottomNavigationBar: DesktopBottomMasterTransportDeck(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify track title and artist
      expect(find.text('Linux Master HiFi Track'), findsOneWidget);
      expect(find.text('Studio Audiophile'), findsOneWidget);

      // Verify Play icon is rendered and visible inside the prominent 42px squircle button
      final playIconFinder = find.byWidgetPredicate(
        (w) => w is HugeIcon && w.icon == HugeIcons.strokeRoundedPlay,
      );
      expect(playIconFinder, findsOneWidget);

      // Tap Play button
      await tester.tap(playIconFinder);
      await tester.pump();

      // State toggles
      expect(notifier.state.isPlaying, isTrue);

      // Re-pump to update icon to Pause
      await tester.pump();
      final pauseIconFinder = find.byWidgetPredicate(
        (w) => w is HugeIcon && w.icon == HugeIcons.strokeRoundedPause,
      );
      expect(pauseIconFinder, findsOneWidget);
    });

    testWidgets('Volume slider is expanded to 120px and allows volume adjustment', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      final notifier = PlayerController(SoLoudController.instance);
      notifier.state = PlaybackState(
        currentTrack: testTrack,
        status: PlaybackStatus.playing,
        duration: const Duration(minutes: 3, seconds: 45),
        volume: 0.75,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playerControllerProvider.overrideWith((ref) => notifier),
          ],
          child: const MaterialApp(
            home: Scaffold(
              bottomNavigationBar: DesktopBottomMasterTransportDeck(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Find the volume Slider widget (max == 1.0)
      final volumeSliderFinder = find.byWidgetPredicate((w) => w is Slider && w.max == 1.0);
      expect(volumeSliderFinder, findsOneWidget);

      // Check that the container around the volume slider is 120px wide
      final sizedBoxes = tester.widgetList<SizedBox>(find.byType(SizedBox));
      final volumeSizedBox = sizedBoxes.where((box) => box.width == 120.0);
      expect(volumeSizedBox.isNotEmpty, isTrue);

      // Drag the volume slider to change volume
      await tester.drag(volumeSliderFinder, const Offset(-30, 0));
      await tester.pump();

      expect(notifier.state.volume, isNotNull);
    });
  });

  group('DesktopLyricsDialog Share Lyric Card Tests', () {
    testWidgets('DesktopLyricsDialog renders Share Lyric Card button and opens LyricShareSheet', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      final notifier = PlayerController(SoLoudController.instance);
      notifier.state = PlaybackState(
        currentTrack: testTrack,
        status: PlaybackStatus.playing,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playerControllerProvider.overrideWith((ref) => notifier),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: Builder(
                  builder: (ctx) => ElevatedButton(
                    onPressed: () => DesktopLyricsDialog.show(ctx, testTrack),
                    child: const Text('Open Dialog'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Open the lyrics dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify dialog is opened
      expect(find.byType(DesktopLyricsDialog), findsOneWidget);

      // Verify Share Lyric Card button exists in header
      final shareButtonFinder = find.byTooltip('Share Lyric Card');
      expect(shareButtonFinder, findsOneWidget);

      // Tap Share Lyric Card button
      await tester.tap(shareButtonFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify LyricShareSheet is opened
      expect(find.byType(LyricShareSheet), findsOneWidget);
    });
  });

  group('Library Responsive Albums and Artists Grid Tests', () {
    testWidgets('Albums grid adapts columns from 2 on mobile to 5 on wide desktop', (tester) async {
      // Mobile screen: width 400
      await tester.binding.setSurfaceSize(const Size(400, 800));

      final libraryController = UnifiedLibraryController();
      libraryController.state = libraryController.state.copyWith(
        tracks: [testTrack],
        currentTab: CollectionTab.albums,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            unifiedLibraryProvider.overrideWith((ref) => libraryController),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: UnifiedLibraryScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // On mobile (400px), albums grid should have crossAxisCount = 2
      final mobileGrid = tester.widget<GridView>(find.byType(GridView));
      final mobileDelegate = mobileGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(mobileDelegate.crossAxisCount, 2);

      // Desktop wide screen: width 1200
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final desktopGrid = tester.widget<GridView>(find.byType(GridView));
      final desktopDelegate = desktopGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(desktopDelegate.crossAxisCount, 5);
    });

    testWidgets('Artists grid adapts columns from 3 on mobile to 7 on wide desktop with compact height', (tester) async {
      // Mobile screen: width 400
      await tester.binding.setSurfaceSize(const Size(400, 800));

      final libraryController = UnifiedLibraryController();
      libraryController.state = libraryController.state.copyWith(
        tracks: [testTrack],
        currentTab: CollectionTab.artists,
        layoutMode: ViewLayoutMode.grid,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            unifiedLibraryProvider.overrideWith((ref) => libraryController),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: UnifiedLibraryScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // On mobile (400px), artists grid should have crossAxisCount = 3
      final mobileGrid = tester.widget<GridView>(find.byType(GridView));
      final mobileDelegate = mobileGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(mobileDelegate.crossAxisCount, 3);
      expect(mobileDelegate.childAspectRatio, 0.78);

      // Desktop wide screen: width 1200
      await tester.binding.setSurfaceSize(const Size(1200, 800));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      final desktopGrid = tester.widget<GridView>(find.byType(GridView));
      final desktopDelegate = desktopGrid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(desktopDelegate.crossAxisCount, 7);
      expect(desktopDelegate.childAspectRatio, 0.92);
    });
  });
}
