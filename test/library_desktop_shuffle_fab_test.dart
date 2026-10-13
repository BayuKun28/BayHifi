import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:baydev_hifi/features/library/domain/library_collection_models.dart';
import 'package:baydev_hifi/features/library/presentation/controllers/library_controller.dart';
import 'package:baydev_hifi/features/library/presentation/controllers/library_selection_controller.dart';
import 'package:baydev_hifi/features/library/presentation/unified_library_screen.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/player/presentation/controllers/player_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleTracks = [
    const Track(
      id: 'track-1',
      title: 'Time',
      artist: 'Hans Zimmer',
      album: 'Inception',
      duration: Duration(minutes: 4, seconds: 35),
      filePath: '/music/time.flac',
      format: AudioFormat.flac,
      sampleRate: 96000,
      bitDepth: 24,
    ),
    const Track(
      id: 'track-2',
      title: 'Cornfield Chase',
      artist: 'Hans Zimmer',
      album: 'Interstellar',
      duration: Duration(minutes: 2, seconds: 7),
      filePath: '/music/cornfield.flac',
      format: AudioFormat.flac,
      sampleRate: 96000,
      bitDepth: 24,
    ),
    const Track(
      id: 'track-3',
      title: 'Stay',
      artist: 'Hans Zimmer',
      album: 'Interstellar',
      duration: Duration(minutes: 6, seconds: 52),
      filePath: '/music/stay.flac',
      format: AudioFormat.flac,
      sampleRate: 192000,
      bitDepth: 24,
    ),
  ];

  group('Desktop Library Tracks Shuffle FAB Tests', () {
    testWidgets('Renders M3EExtendedFab on desktop (width >= 960px) in Tracks tab and triggers shuffle', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final libraryController = UnifiedLibraryController(
        initialTracks: sampleTracks,
      );

      final container = ProviderContainer(
        overrides: [
          unifiedLibraryProvider.overrideWith((ref) => libraryController),
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

      // Verify the desktop shuffle FAB is visible on Tracks tab
      final desktopFabByKey = find.byKey(const ValueKey('desktop_shuffle_fab'));
      final desktopFabByTooltip = find.byTooltip('Shuffle All Tracks');

      expect(desktopFabByKey, findsOneWidget);
      expect(desktopFabByTooltip, findsOneWidget);
      expect(find.text('Shuffle All'), findsOneWidget);

      // Verify the icon inside FAB
      expect(
        find.descendant(
          of: desktopFabByKey,
          matching: find.byWidgetPredicate(
            (w) => w is HugeIcon && w.icon == HugeIcons.strokeRoundedShuffle,
          ),
        ),
        findsOneWidget,
      );

      // Tap Desktop Shuffle FAB
      await tester.tap(desktopFabByKey);
      await tester.pump(); // trigger SnackBar animation

      // Verify SnackBar confirmation and Player queue updated
      expect(find.textContaining('Shuffled 3 tracks into queue'), findsOneWidget);
      final playerState = container.read(playerControllerProvider);
      expect(playerState.queue.length, 3);
    });

    testWidgets('Shows "No tracks to shuffle." SnackBar when library tracks is empty on desktop', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final libraryController = UnifiedLibraryController(
        initialTracks: const [],
      );

      final container = ProviderContainer(
        overrides: [
          unifiedLibraryProvider.overrideWith((ref) => libraryController),
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

      final desktopFabByKey = find.byKey(const ValueKey('desktop_shuffle_fab'));
      expect(desktopFabByKey, findsOneWidget);

      await tester.tap(desktopFabByKey);
      await tester.pump();

      expect(find.text('No tracks to shuffle.'), findsOneWidget);
    });

    testWidgets('Hides desktop shuffle FAB when switching away from Tracks tab (e.g. Albums)', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final libraryController = UnifiedLibraryController(
        initialTracks: sampleTracks,
      );

      final container = ProviderContainer(
        overrides: [
          unifiedLibraryProvider.overrideWith((ref) => libraryController),
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

      expect(find.byKey(const ValueKey('desktop_shuffle_fab')), findsOneWidget);

      // Switch tab to Albums
      libraryController.setTab(CollectionTab.albums);
      await tester.pumpAndSettle();

      // Should be hidden on Albums tab
      expect(find.byKey(const ValueKey('desktop_shuffle_fab')), findsNothing);
      expect(find.byTooltip('Shuffle All Tracks'), findsNothing);
    });

    testWidgets('Hides desktop shuffle FAB when track multi-selection mode is active', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final libraryController = UnifiedLibraryController(
        initialTracks: sampleTracks,
      );

      final container = ProviderContainer(
        overrides: [
          unifiedLibraryProvider.overrideWith((ref) => libraryController),
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

      expect(find.byKey(const ValueKey('desktop_shuffle_fab')), findsOneWidget);

      // Activate multi-selection
      container.read(librarySelectionProvider.notifier).toggle('track-1');
      await tester.pumpAndSettle();

      // Verify FAB hides during selection mode
      expect(find.byKey(const ValueKey('desktop_shuffle_fab')), findsNothing);

      // Clear selection
      container.read(librarySelectionProvider.notifier).clear();
      await tester.pumpAndSettle();

      // FAB returns
      expect(find.byKey(const ValueKey('desktop_shuffle_fab')), findsOneWidget);
    });

    testWidgets('Breakpoint Guard: Does NOT render desktop FAB on mobile (< 650px) or tablet (< 960px)', (tester) async {
      // Test mobile screen width (400px)
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final libraryController = UnifiedLibraryController(
        initialTracks: sampleTracks,
      );

      final container = ProviderContainer(
        overrides: [
          unifiedLibraryProvider.overrideWith((ref) => libraryController),
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

      // On mobile dimensions, UnifiedLibraryScreen does not render the desktop FAB
      // (mobile uses NamidaExpandableMiniPlayer's FAB instead)
      expect(find.byKey(const ValueKey('desktop_shuffle_fab')), findsNothing);

      // Now test tablet dimensions (800px < 960px)
      tester.view.physicalSize = const Size(800, 600);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('desktop_shuffle_fab')), findsNothing);
    });
  });
}
