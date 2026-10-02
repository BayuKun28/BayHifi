import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/app/app.dart';
import 'package:baydev_hifi/features/library/presentation/controllers/library_controller.dart';
import 'package:baydev_hifi/features/library/presentation/controllers/library_selection_controller.dart';
import 'package:baydev_hifi/features/library/presentation/unified_library_screen.dart';
import 'package:baydev_hifi/features/library/presentation/widgets/library_batch_actions_bar.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testTracks = [
    const Track(
      id: 'track_1',
      title: 'First Studio Track',
      artist: 'Audiophile Artist 1',
      album: 'Studio Master Vol 1',
      duration: Duration(minutes: 4, seconds: 12),
      filePath: '/storage/music/track1.flac',
      format: AudioFormat.flac,
      sampleRate: 96000,
      bitDepth: 24,
    ),
    const Track(
      id: 'track_2',
      title: 'Second Studio Track',
      artist: 'Audiophile Artist 2',
      album: 'Studio Master Vol 1',
      duration: Duration(minutes: 3, seconds: 45),
      filePath: '/storage/music/track2.flac',
      format: AudioFormat.flac,
      sampleRate: 96000,
      bitDepth: 24,
    ),
    const Track(
      id: 'track_3',
      title: 'Third Studio Track',
      artist: 'Audiophile Artist 3',
      album: 'Studio Master Vol 2',
      duration: Duration(minutes: 5, seconds: 10),
      filePath: '/storage/music/track3.flac',
      format: AudioFormat.flac,
      sampleRate: 192000,
      bitDepth: 24,
    ),
  ];

  group('LibrarySelectionNotifier Unit Tests', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('Initial selection state is empty', () {
      final state = container.read(librarySelectionProvider);
      expect(state.selectedTrackIds, isEmpty);
      expect(state.isSelecting, isFalse);
      expect(state.count, 0);
      expect(state.isSelected('track_1'), isFalse);
    });

    test('toggle adds and removes tracks from selection', () {
      final notifier = container.read(librarySelectionProvider.notifier);

      notifier.toggle('track_1');
      var state = container.read(librarySelectionProvider);
      expect(state.isSelecting, isTrue);
      expect(state.count, 1);
      expect(state.isSelected('track_1'), isTrue);
      expect(state.isSelected('track_2'), isFalse);

      notifier.toggle('track_2');
      state = container.read(librarySelectionProvider);
      expect(state.count, 2);
      expect(state.isSelected('track_1'), isTrue);
      expect(state.isSelected('track_2'), isTrue);

      notifier.toggle('track_1');
      state = container.read(librarySelectionProvider);
      expect(state.count, 1);
      expect(state.isSelected('track_1'), isFalse);
      expect(state.isSelected('track_2'), isTrue);

      notifier.toggle('track_2');
      state = container.read(librarySelectionProvider);
      expect(state.isSelecting, isFalse);
      expect(state.count, 0);
    });

    test('selectAll and deselectAll manage entire track batch', () {
      final notifier = container.read(librarySelectionProvider.notifier);

      notifier.selectAll(testTracks);
      var state = container.read(librarySelectionProvider);
      expect(state.isSelecting, isTrue);
      expect(state.count, 3);
      expect(state.isSelected('track_1'), isTrue);
      expect(state.isSelected('track_2'), isTrue);
      expect(state.isSelected('track_3'), isTrue);

      notifier.deselectAll();
      state = container.read(librarySelectionProvider);
      expect(state.isSelecting, isFalse);
      expect(state.count, 0);
    });

    test('clear resets state silently', () {
      final notifier = container.read(librarySelectionProvider.notifier);

      notifier.select('track_1');
      expect(container.read(librarySelectionProvider).isSelecting, isTrue);

      notifier.clear();
      expect(container.read(librarySelectionProvider).isSelecting, isFalse);
    });
  });

  group('UnifiedLibraryScreen Track Selection Widget Tests', () {
    testWidgets('Longpress on TrackTile enters selection mode and shows LibraryBatchActionsBar', (tester) async {
      final container = ProviderContainer(
        overrides: [
          unifiedLibraryProvider.overrideWith(
            (ref) => UnifiedLibraryController(initialTracks: testTracks),
          ),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: UnifiedLibraryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify tracks are rendered
      expect(find.text('First Studio Track'), findsOneWidget);
      expect(find.byType(LibraryBatchActionsBar), findsNothing);

      // Longpress first track
      await tester.longPress(find.text('First Studio Track'));
      await tester.pumpAndSettle();

      // Verify selection mode is active and LibraryBatchActionsBar is displayed
      expect(container.read(librarySelectionProvider).isSelecting, isTrue);
      expect(container.read(librarySelectionProvider).count, 1);
      expect(find.byType(LibraryBatchActionsBar), findsOneWidget);
      expect(find.text('1'), findsWidgets);

      // Tap on second track to toggle selection while in selection mode
      await tester.tap(find.text('Second Studio Track'));
      await tester.pumpAndSettle();

      expect(container.read(librarySelectionProvider).count, 2);
      expect(find.text('2'), findsWidgets);

      // Tap cancel button in batch actions bar
      final cancelButton = find.byTooltip('Cancel Selection');
      expect(cancelButton, findsOneWidget);
      await tester.tap(cancelButton);
      await tester.pumpAndSettle();

      // Verify selection mode is closed
      expect(container.read(librarySelectionProvider).isSelecting, isFalse);
      expect(find.byType(LibraryBatchActionsBar), findsNothing);
    });
  });

  group('Mobile Layout Selection Mode Dock & Miniplayer Transition Tests', () {
    testWidgets('Mobile layout slides down dock and miniplayer when selection is active', (tester) async {
      final container = ProviderContainer(
        overrides: [
          unifiedLibraryProvider.overrideWith(
            (ref) => UnifiedLibraryController(initialTracks: testTracks),
          ),
        ],
      );

      // Set mobile screen dimensions (< 650px)
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BaydevHiFiApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Library (Nav index 2)
      final libraryNavDestination = find.text('Library');
      expect(libraryNavDestination, findsWidgets);
      await tester.tap(libraryNavDestination.first);
      await tester.pumpAndSettle();

      // Initially no selection
      expect(container.read(librarySelectionProvider).isSelecting, isFalse);

      // Find AnimatedSlide widgets
      final animatedSlidesBefore = tester.widgetList<AnimatedSlide>(find.byType(AnimatedSlide)).toList();
      for (final slide in animatedSlidesBefore) {
        expect(slide.offset, Offset.zero);
      }

      // Trigger selection via provider
      container.read(librarySelectionProvider.notifier).select('track_1');
      await tester.pumpAndSettle();

      // Verify slides moved down
      final animatedSlidesAfter = tester.widgetList<AnimatedSlide>(find.byType(AnimatedSlide)).toList();
      final slideOffsets = animatedSlidesAfter.map((s) => s.offset).toList();
      expect(slideOffsets.any((offset) => offset.dy > 0), isTrue);

      // Clear selection
      container.read(librarySelectionProvider.notifier).clear();
      await tester.pumpAndSettle();

      // Verify slides returned to normal
      final animatedSlidesReset = tester.widgetList<AnimatedSlide>(find.byType(AnimatedSlide)).toList();
      for (final slide in animatedSlidesReset) {
        expect(slide.offset, Offset.zero);
      }
    });
  });
}
