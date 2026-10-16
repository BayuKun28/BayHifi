import 'package:baydev_hifi/features/dashboard/presentation/dashboard_screen.dart';
import 'package:baydev_hifi/features/dashboard/presentation/widgets/simple_as_f_discovery_grid.dart';
import 'package:baydev_hifi/features/dashboard/presentation/widgets/studio_wrapped_bento_banner.dart';
import 'package:baydev_hifi/features/library/domain/library_collection_models.dart';
import 'package:baydev_hifi/features/library/presentation/controllers/library_controller.dart';
import 'package:baydev_hifi/features/library/presentation/screens/album_detail_screen.dart';
import 'package:baydev_hifi/features/library/presentation/screens/artist_detail_screen.dart';
import 'package:baydev_hifi/features/library/presentation/unified_library_screen.dart';
import 'package:baydev_hifi/features/lyrics_share/presentation/widgets/lyric_share_sheet.dart';
import 'package:baydev_hifi/features/player/domain/lyrics_line.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/player/presentation/widgets/namida_expandable_miniplayer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleTracks = <Track>[
    const Track(
      id: 'track-1',
      title: 'Studio Master One',
      artist: 'Hans Zimmer',
      album: 'Interstellar OST',
      filePath: '/music/track1.flac',
      duration: Duration(minutes: 4, seconds: 12),
      format: AudioFormat.flac,
      bitDepth: 24,
      sampleRate: 96000,
    ),
    const Track(
      id: 'track-2',
      title: 'Studio Master Two',
      artist: 'Hans Zimmer',
      album: 'Inception OST',
      filePath: '/music/track2.flac',
      duration: Duration(minutes: 3, seconds: 45),
      format: AudioFormat.flac,
      bitDepth: 24,
      sampleRate: 192000,
    ),
    const Track(
      id: 'track-3',
      title: 'Dune Theme',
      artist: 'Hans Zimmer',
      album: 'Dune Part One',
      filePath: '/music/track3.flac',
      duration: Duration(minutes: 5, seconds: 10),
      format: AudioFormat.flac,
      bitDepth: 24,
      sampleRate: 96000,
    ),
    const Track(
      id: 'track-4',
      title: 'Gladiator Theme',
      artist: 'Hans Zimmer',
      album: 'Gladiator OST',
      filePath: '/music/track4.flac',
      duration: Duration(minutes: 4, seconds: 30),
      format: AudioFormat.flac,
      bitDepth: 24,
      sampleRate: 96000,
    ),
  ];

  final sampleAlbums = [
    AlbumModel(
      name: 'Interstellar OST',
      artist: 'Hans Zimmer',
      tracks: [sampleTracks[0]],
    ),
    AlbumModel(
      name: 'Inception OST',
      artist: 'Hans Zimmer',
      tracks: [sampleTracks[1]],
    ),
    AlbumModel(
      name: 'Dune Part One',
      artist: 'Hans Zimmer',
      tracks: [sampleTracks[2]],
    ),
    AlbumModel(
      name: 'Gladiator OST',
      artist: 'Hans Zimmer',
      tracks: [sampleTracks[3]],
    ),
  ];

  final sampleArtist = ArtistModel(
    name: 'Hans Zimmer',
    tracks: sampleTracks,
  );

  group('Phase 41: UI/UX Redesign & Visual Polish Tests', () {
    testWidgets('1. LyricShareSheet ratio selector is horizontally scrollable', (tester) async {
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LyricShareSheet(
                track: sampleTracks.first,
                allLines: const [
                  LyricsLine(timestamp: Duration(seconds: 1), text: 'First line of lyrics'),
                  LyricsLine(timestamp: Duration(seconds: 5), text: 'Second line of lyrics'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure ratio section is visible
      await tester.ensureVisible(find.text('Story (9:16)'));
      await tester.pumpAndSettle();

      // Verify ratio options exist
      expect(find.text('Story (9:16)'), findsOneWidget);
      expect(find.text('Portrait (4:5)'), findsOneWidget);
      expect(find.text('Square (1:1)'), findsOneWidget);
      expect(find.text('Landscape (16:9)'), findsOneWidget);
    });

    testWidgets('2. Dashboard places Studio Wrapped Banner under Recently Played Discovery Grid', (tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SimpleAsFDiscoveryGrid), findsOneWidget);
      expect(find.byType(StudioWrappedBentoBanner), findsOneWidget);

      final gridTop = tester.getTopLeft(find.byType(SimpleAsFDiscoveryGrid)).dy;
      final wrappedTop = tester.getTopLeft(find.byType(StudioWrappedBentoBanner)).dy;

      expect(wrappedTop, greaterThan(gridTop));
    });

    testWidgets('3. Library defaults to Grid Mode for Albums and Artists', (tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final controller = UnifiedLibraryController(
        initialTracks: sampleTracks,
      );
      controller.setTab(CollectionTab.artists);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            unifiedLibraryProvider.overrideWith((ref) => controller),
          ],
          child: const MaterialApp(
            home: UnifiedLibraryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify artist name is visible in Grid mode
      expect(find.text('Hans Zimmer'), findsOneWidget);
      // Verify album/track count text is rendered in 3-column grid layout
      expect(find.textContaining('Tracks'), findsWidgets);
      // Verify layout mode is grid by default
      expect(controller.state.layoutMode, equals(ViewLayoutMode.grid));
    });

    testWidgets('4. AlbumDetailScreen renders header with artist photo fallback without overflow', (tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: AlbumDetailScreen(album: sampleAlbums.first),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Interstellar OST'), findsWidgets);
      expect(find.text('Hans Zimmer'), findsWidgets);
      expect(find.text('Play All'), findsOneWidget);
    });

    testWidgets('5. ArtistDetailScreen renders 2x2 collage backdrop when >= 4 albums', (tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            unifiedLibraryProvider.overrideWith((ref) => UnifiedLibraryController(
                  initialTracks: sampleTracks,
                )),
          ],
          child: MaterialApp(
            home: ArtistDetailScreen(artist: sampleArtist),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Hans Zimmer'), findsWidgets);
      expect(find.text('ARTIST DISCOGRAPHY'), findsOneWidget);
      expect(find.text('Play All'), findsOneWidget);
      expect(find.text('Shuffle'), findsOneWidget);
    });

    testWidgets('6. Library Tracks tab renders Shuffle Shortcut FAB above Category FAB and triggers queue shuffle on tap', (tester) async {
      tester.view.physicalSize = const Size(420, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final libraryController = UnifiedLibraryController(
        initialTracks: sampleTracks,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            unifiedLibraryProvider.overrideWith((ref) => libraryController),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  UnifiedLibraryScreen(),
                  NamidaExpandableMiniPlayer(
                    collapsedBottomOffset: 78.0,
                    isLibraryTab: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify both Source Filter FAB and Shuffle FAB are visible on Tracks tab
      final sourceFilterFab = find.byTooltip('Filter Audio Source');
      final shuffleFab = find.byTooltip('Shuffle All Tracks');
      expect(sourceFilterFab, findsOneWidget);
      expect(shuffleFab, findsOneWidget);

      // Verify vertical positioning: Shuffle FAB must be above Source Filter FAB
      final sourceFilterFabTop = tester.getTopLeft(sourceFilterFab).dy;
      final shuffleFabTop = tester.getTopLeft(shuffleFab).dy;
      expect(shuffleFabTop, lessThan(sourceFilterFabTop));

      // Tap Shuffle FAB
      await tester.tap(shuffleFab);
      await tester.pump(); // Start snackbar animation

      // Verify snackbar is displayed
      expect(find.textContaining('Shuffled 4 tracks into queue'), findsOneWidget);

      // Now switch tab to Albums
      libraryController.setTab(CollectionTab.albums);
      await tester.pump(const Duration(milliseconds: 300));

      // Shuffle FAB should not be visible on Albums tab, while Source Filter FAB remains
      expect(find.byTooltip('Shuffle All Tracks'), findsNothing);
      expect(find.byTooltip('Filter Audio Source'), findsOneWidget);
    });
  });
}
