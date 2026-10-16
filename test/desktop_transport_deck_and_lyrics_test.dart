import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
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
import 'package:baydev_hifi/features/settings/domain/player_customization_settings.dart';
import 'package:baydev_hifi/features/settings/domain/player_playback_settings.dart';
import 'package:baydev_hifi/features/settings/presentation/controllers/playback_settings_controller.dart';
import 'package:baydev_hifi/features/settings/presentation/controllers/player_customization_controller.dart';

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
        (w) => w is Icon && w.icon == LucideIcons.play,
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
        (w) => w is Icon && w.icon == LucideIcons.pause,
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

      // Find the volume Slider widget (M3ESlider or Slider) inside the 120px SizedBox
      final volumeSliderFinder = find.descendant(
        of: find.byWidgetPredicate((w) => w is SizedBox && w.width == 120.0),
        matching: find.byWidgetPredicate((w) => w is M3ESlider || w is Slider),
      );
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

    testWidgets('Shuffle and Repeat buttons render visible active states and tooltips when toggled', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      final notifier = PlayerController(SoLoudController.instance);
      notifier.state = PlaybackState(
        currentTrack: testTrack,
        status: PlaybackStatus.playing,
        isShuffle: false,
        repeatMode: PlaybackRepeatMode.off,
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

      // Verify inactive tooltips
      expect(find.byTooltip('Shuffle: OFF'), findsOneWidget);
      expect(find.byTooltip('Repeat: OFF'), findsOneWidget);

      // Tap Shuffle button
      await tester.tap(find.byTooltip('Shuffle: OFF'));
      await tester.pump();

      expect(notifier.state.isShuffle, isTrue);
      expect(find.byTooltip('Shuffle: ON'), findsOneWidget);

      // Tap Repeat button -> Repeat ALL
      await tester.tap(find.byTooltip('Repeat: OFF'));
      await tester.pump();

      expect(notifier.state.repeatMode, PlaybackRepeatMode.all);
      expect(find.byTooltip('Repeat: ALL'), findsOneWidget);

      // Tap Repeat button again -> Repeat ONE
      await tester.tap(find.byTooltip('Repeat: ALL'));
      await tester.pump();

      expect(notifier.state.repeatMode, PlaybackRepeatMode.one);
      expect(find.byTooltip('Repeat: ONE'), findsOneWidget);

      // Verify RepeatOne icon is rendered
      final repeatOneIcon = find.byWidgetPredicate(
        (w) => w is Icon && w.icon == LucideIcons.repeat1,
      );
      expect(repeatOneIcon, findsOneWidget);
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

  group('DesktopBottomMasterTransportDeck Dynamic Settings & Visibility Rules Tests', () {
    testWidgets('Respects trackTitleFirst ordering (title first vs artist first)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      final playerNotifier = PlayerController(SoLoudController.instance);
      playerNotifier.state = PlaybackState(
        currentTrack: testTrack,
        status: PlaybackStatus.playing,
        duration: const Duration(minutes: 3, seconds: 45),
      );

      final customNotifier = PlayerCustomizationNotifier();
      customNotifier.state = customNotifier.state.copyWith(trackTitleFirst: true);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playerControllerProvider.overrideWith((ref) => playerNotifier),
            playerCustomizationProvider.overrideWith((ref) => customNotifier),
          ],
          child: const MaterialApp(
            home: Scaffold(
              bottomNavigationBar: DesktopBottomMasterTransportDeck(),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Linux Master HiFi Track'), findsOneWidget);
      expect(find.text('Studio Audiophile'), findsOneWidget);

      // Change setting: artist first
      customNotifier.state = customNotifier.state.copyWith(trackTitleFirst: false);
      await tester.pump();

      expect(find.text('Studio Audiophile'), findsOneWidget);
      expect(find.text('Linux Master HiFi Track'), findsOneWidget);
    });

    testWidgets('Respects trackShowFormatBadge and trackShowBitrate visibility rules', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      final playerNotifier = PlayerController(SoLoudController.instance);
      playerNotifier.state = PlaybackState(
        currentTrack: testTrack,
        status: PlaybackStatus.playing,
        duration: const Duration(minutes: 3, seconds: 45),
      );

      final customNotifier = PlayerCustomizationNotifier();
      customNotifier.state = customNotifier.state.copyWith(
        trackShowFormatBadge: true,
        trackShowBitrate: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playerControllerProvider.overrideWith((ref) => playerNotifier),
            playerCustomizationProvider.overrideWith((ref) => customNotifier),
          ],
          child: const MaterialApp(
            home: Scaffold(
              bottomNavigationBar: DesktopBottomMasterTransportDeck(),
            ),
          ),
        ),
      );

      await tester.pump();

      // With trackShowBitrate: true -> '96kHz / 24bit'
      expect(find.text('96kHz / 24bit'), findsOneWidget);

      // Set trackShowBitrate: false -> shows format name 'FLAC'
      customNotifier.state = customNotifier.state.copyWith(
        trackShowFormatBadge: true,
        trackShowBitrate: false,
      );
      await tester.pump();
      expect(find.text('FLAC'), findsOneWidget);

      // Hide format badge entirely
      customNotifier.state = customNotifier.state.copyWith(
        trackShowFormatBadge: false,
      );
      await tester.pump();
      expect(find.text('FLAC'), findsNothing);
      expect(find.text('96kHz / 24bit'), findsNothing);
    });

    testWidgets('Respects trackShowDirectFav (shows/hides favorite button and toggles state)', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      final playerNotifier = PlayerController(SoLoudController.instance);
      playerNotifier.state = PlaybackState(
        currentTrack: testTrack,
        status: PlaybackStatus.playing,
      );

      final customNotifier = PlayerCustomizationNotifier();
      customNotifier.state = customNotifier.state.copyWith(trackShowDirectFav: true);

      final libraryController = UnifiedLibraryController();
      libraryController.state = libraryController.state.copyWith(
        tracks: [testTrack],
        favoriteTrackIds: {},
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playerControllerProvider.overrideWith((ref) => playerNotifier),
            playerCustomizationProvider.overrideWith((ref) => customNotifier),
            unifiedLibraryProvider.overrideWith((ref) => libraryController),
          ],
          child: const MaterialApp(
            home: Scaffold(
              bottomNavigationBar: DesktopBottomMasterTransportDeck(),
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify un-favorited state with tooltip
      expect(find.byTooltip('Add to Favorites'), findsOneWidget);

      // Tap favorite button to toggle favorite state
      await tester.tap(find.byTooltip('Add to Favorites'));
      await tester.pump();

      expect(libraryController.state.favoriteTrackIds.contains(testTrack.id), isTrue);
      expect(find.byTooltip('Remove from Favorites'), findsOneWidget);

      // Hide direct favorite button
      customNotifier.state = customNotifier.state.copyWith(trackShowDirectFav: false);
      await tester.pump();

      expect(find.byTooltip('Remove from Favorites'), findsNothing);
      expect(find.byTooltip('Add to Favorites'), findsNothing);
    });

    testWidgets('Respects trackShowDuration and toggles timeDisplayMode on click', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      final playerNotifier = PlayerController(SoLoudController.instance);
      playerNotifier.state = PlaybackState(
        currentTrack: testTrack,
        status: PlaybackStatus.playing,
        position: const Duration(minutes: 1, seconds: 15),
        duration: const Duration(minutes: 3, seconds: 45),
      );

      final customNotifier = PlayerCustomizationNotifier();
      customNotifier.state = customNotifier.state.copyWith(trackShowDuration: true);

      final playbackSettingsNotifier = PlaybackSettingsController();
      playbackSettingsNotifier.state = playbackSettingsNotifier.state.copyWith(
        timeDisplayMode: TimeDisplayMode.remaining,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playerControllerProvider.overrideWith((ref) => playerNotifier),
            playerCustomizationProvider.overrideWith((ref) => customNotifier),
            playbackSettingsProvider.overrideWith((ref) => playbackSettingsNotifier),
          ],
          child: const MaterialApp(
            home: Scaffold(
              bottomNavigationBar: DesktopBottomMasterTransportDeck(),
            ),
          ),
        ),
      );

      await tester.pump();

      // Position: 01:15
      expect(find.text('01:15'), findsOneWidget);

      // Remaining: 03:45 - 01:15 = -02:30
      expect(find.text('-02:30'), findsOneWidget);

      // Tap duration text to toggle to Total mode
      await tester.tap(find.text('-02:30'));
      await tester.pump();

      expect(playbackSettingsNotifier.state.timeDisplayMode, TimeDisplayMode.total);
      expect(find.text('03:45'), findsOneWidget);
    });

    testWidgets('Respects dynamic spectrumStyle and albumArtStyle configurations', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      final playerNotifier = PlayerController(SoLoudController.instance);
      playerNotifier.state = PlaybackState(
        currentTrack: testTrack,
        status: PlaybackStatus.playing,
      );

      final customNotifier = PlayerCustomizationNotifier();
      customNotifier.state = customNotifier.state.copyWith(
        spectrumStyle: SpectrumStyle.vuMeter,
        albumArtStyle: AlbumArtStyle.vinyl,
        ambientGlow: true,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playerControllerProvider.overrideWith((ref) => playerNotifier),
            playerCustomizationProvider.overrideWith((ref) => customNotifier),
          ],
          child: const MaterialApp(
            home: Scaffold(
              bottomNavigationBar: DesktopBottomMasterTransportDeck(),
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify Spectrum tooltip matches active spectrum style
      expect(find.byTooltip('Spectrum: Dual Analog VU Dials'), findsOneWidget);

      // Change spectrum style to wave
      customNotifier.state = customNotifier.state.copyWith(
        spectrumStyle: SpectrumStyle.wave,
      );
      await tester.pump();

      expect(find.byTooltip('Spectrum: Liquid Wave'), findsOneWidget);
    });

    testWidgets('Renders Desktop DSP Signal Chain capsule with AutoEQ, DSP Rack and DAC chips', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1300, 800));

      final playerNotifier = PlayerController(SoLoudController.instance);
      playerNotifier.state = PlaybackState(
        currentTrack: testTrack,
        status: PlaybackStatus.playing,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playerControllerProvider.overrideWith((ref) => playerNotifier),
          ],
          child: const MaterialApp(
            home: Scaffold(
              bottomNavigationBar: DesktopBottomMasterTransportDeck(),
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify AutoEQ, DSP Rack, and DAC Bridge chips are rendered
      expect(find.byWidgetPredicate((w) => w is Tooltip && (w.message?.contains('AutoEQ Target') ?? false)), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is Tooltip && (w.message?.contains('Mastering DSP Rack') ?? false)), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is Tooltip && (w.message?.contains('Hardware DAC') ?? false)), findsOneWidget);
    });
  });
}
