import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:baydev_hifi/features/lyrics_share/presentation/widgets/lyric_share_sheet.dart';
import 'package:baydev_hifi/features/player/domain/lyrics_line.dart';
import 'package:baydev_hifi/features/player/domain/playback_state.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/player/presentation/controllers/player_controller.dart';
import 'package:baydev_hifi/features/player/presentation/widgets/now_playing_queue_sheet.dart';
import 'package:baydev_hifi/features/player/presentation/widgets/dual_pane_workstation_pane.dart';
import 'package:baydev_hifi/features/player/data/lyrics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testTrack1 = Track(
    id: 'track_1',
    title: 'Bohemian Rhapsody',
    artist: 'Queen',
    album: 'A Night at the Opera',
    duration: Duration(minutes: 5, seconds: 55),
    format: AudioFormat.flac,
  );

  const testTrack2 = Track(
    id: 'track_2',
    title: 'Don\'t Stop Me Now',
    artist: 'Queen',
    album: 'Jazz',
    duration: Duration(minutes: 3, seconds: 29),
    format: AudioFormat.flac,
  );

  final testLines = [
    const LyricsLine(timestamp: Duration(seconds: 1), text: 'Is this the real life?'),
    const LyricsLine(timestamp: Duration(seconds: 4), text: 'Is this just fantasy?'),
  ];

  group('LyricShareSheet Fullscreen Studio Tests', () {
    testWidgets('LyricShareSheet renders with solid surface background, header, and safe bottom actions', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: LyricShareSheet(
                track: testTrack1,
                allLines: testLines,
                initialSelectedLine: testLines.first,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify header and track title
      expect(find.text('Lyric Studio Share'), findsOneWidget);
      expect(find.text('Bohemian Rhapsody'), findsWidgets);

      // Verify close button with M3EIconButton
      expect(find.byType(M3EIconButton), findsWidgets);

      // Verify 4 tabs
      expect(find.text('Studio'), findsOneWidget);
      expect(find.textContaining('Lines'), findsOneWidget);
      expect(find.text('Telemetry'), findsWidgets);
      expect(find.text('Style'), findsOneWidget);

      // Verify bottom action buttons
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Share to Socials'), findsOneWidget);

      // Verify Scaffold has solid surface background (not transparent)
      final scaffold = tester.widget<Scaffold>(find.descendant(
        of: find.byType(LyricShareSheet),
        matching: find.byType(Scaffold),
      ));
      expect(scaffold.backgroundColor, isNot(Colors.transparent));
    });
  });

  group('Queue Reordering & Drag Target Tests', () {
    testWidgets('NowPlayingQueueSheet wraps items in ReorderableDelayedDragStartListener and renders strokeRoundedDragDropVertical handle', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer(
        overrides: [
          playerControllerProvider.overrideWith((ref) => FakePlayerController(
            const PlaybackState(
              currentTrack: testTrack1,
              queue: [testTrack1, testTrack2],
              queueIndex: 0,
              status: PlaybackStatus.playing,
            ),
          )),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: NowPlayingQueueSheet(),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify queue tracks rendered
      expect(find.text('UP NEXT QUEUE'), findsOneWidget);
      expect(find.text('Bohemian Rhapsody'), findsOneWidget);
      expect(find.text('Don\'t Stop Me Now'), findsOneWidget);

      // Verify ReorderableDelayedDragStartListener wraps both items
      expect(find.byType(ReorderableDelayedDragStartListener), findsNWidgets(2));

      // Verify ReorderableDragStartListener dedicated handles exist on both items
      expect(find.byType(ReorderableDragStartListener), findsNWidgets(2));

      // Verify LucideIcons.gripVertical is present
      expect(find.byWidgetPredicate((w) => w is Icon && w.icon == LucideIcons.gripVertical), findsNWidgets(2));
    });

    testWidgets('DualPaneWorkstationPane queue wraps items in ReorderableDelayedDragStartListener and renders strokeRoundedDragDropVertical handle', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer(
        overrides: [
          playerControllerProvider.overrideWith((ref) => FakePlayerController(
            const PlaybackState(
              currentTrack: testTrack1,
              queue: [testTrack1, testTrack2],
              queueIndex: 0,
              status: PlaybackStatus.playing,
            ),
          )),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: DualPaneWorkstationPane(
                lyricsResult: LyricsResult.empty(),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify tabs
      expect(find.text('UP NEXT'), findsOneWidget);

      // Verify ReorderableDelayedDragStartListener wraps both items
      expect(find.byType(ReorderableDelayedDragStartListener), findsNWidgets(2));

      // Verify ReorderableDragStartListener dedicated handles exist on both items
      expect(find.byType(ReorderableDragStartListener), findsNWidgets(2));

      // Verify LucideIcons.gripVertical is present
      expect(find.byWidgetPredicate((w) => w is Icon && w.icon == LucideIcons.gripVertical), findsNWidgets(2));
    });
  });
}

class FakePlayerController extends StateNotifier<PlaybackState> implements PlayerController {
  FakePlayerController(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
