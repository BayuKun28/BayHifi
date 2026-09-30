import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:baydev_hifi/features/player/data/lyrics_service.dart';
import 'package:baydev_hifi/features/player/domain/playback_state.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/player/presentation/controllers/player_controller.dart';
import 'package:baydev_hifi/features/player/presentation/widgets/dual_pane_workstation_pane.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final dummyTrack1 = const Track(
    id: 'track_1',
    title: 'A Little Piece of Heaven',
    artist: 'Avenged Sevenfold',
    album: 'Avenged Sevenfold',
    duration: Duration(minutes: 8, seconds: 0),
    format: AudioFormat.flac,
  );

  final dummyTrack2 = const Track(
    id: 'track_2',
    title: 'Afterlife',
    artist: 'Avenged Sevenfold',
    album: 'Avenged Sevenfold',
    duration: Duration(minutes: 5, seconds: 52),
    format: AudioFormat.flac,
  );

  testWidgets('DualPaneWorkstationPane renders UP NEXT tab, LYRICS tab, and DSP RACK tab without error', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final container = ProviderContainer(
      overrides: [
        playerControllerProvider.overrideWith((ref) => FakePlayerController(
          PlaybackState(
            currentTrack: dummyTrack1,
            queue: [dummyTrack1, dummyTrack2],
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

    // 1. Verify Workstation Tabs
    expect(find.text('UP NEXT'), findsOneWidget);
    expect(find.text('LYRICS'), findsOneWidget);
    expect(find.text('DSP RACK'), findsOneWidget);
    expect(find.text('PRO-Q EQ'), findsNothing); // Pro-Q removed from cramped tabs

    // 2. Verify Up Next Tab displays queued tracks without NoSuchMethodError
    expect(find.text('2 Tracks'), findsOneWidget);
    expect(find.text('A Little Piece of Heaven'), findsOneWidget);
    expect(find.text('Afterlife'), findsOneWidget);

    // 3. Switch to LYRICS Tab
    await tester.tap(find.text('LYRICS'));
    await tester.pumpAndSettle();

    // 4. Switch to DSP RACK Tab
    await tester.tap(find.text('DSP RACK'));
    await tester.pumpAndSettle();
    expect(find.textContaining('DSP'), findsWidgets);
  });
}

class FakePlayerController extends StateNotifier<PlaybackState> implements PlayerController {
  FakePlayerController(super.state);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
