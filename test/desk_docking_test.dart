import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:baydev_hifi/features/player/domain/playback_state.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/player/presentation/controllers/player_controller.dart';
import 'package:baydev_hifi/features/player/presentation/studio_desk_docking_screen.dart';
import 'package:baydev_hifi/features/player/presentation/widgets/custom_time_bar.dart';

void main() {
  final testTrack = const Track(
    id: 'desk_test_1',
    title: 'A Little Piece of Heaven',
    artist: 'Avenged Sevenfold',
    album: 'Avenged Sevenfold',
    duration: Duration(minutes: 8, seconds: 0),
    format: AudioFormat.flac,
    sampleRate: 96000,
    bitDepth: 24,
  );

  testWidgets('StudioDeskDockingScreen renders without errors in portrait and landscape with M3E wavy seekbar', (WidgetTester tester) async {
    // 1. Test phone portrait stand
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    final container = ProviderContainer(
      overrides: [
        playerControllerProvider.overrideWith((ref) => FakePlayerController(
          PlaybackState(
            currentTrack: testTrack,
            status: PlaybackStatus.playing,
            duration: const Duration(minutes: 8, seconds: 0),
            position: const Duration(minutes: 3, seconds: 21),
            volume: 0.8,
          ),
        )),
      ],
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: StudioDeskDockingScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Exit Dock button
    expect(find.text('EXIT DOCK'), findsOneWidget);

    // Verify Technical specs badge
    expect(find.textContaining('FLAC'), findsWidgets);
    expect(find.textContaining('96.0 kHz'), findsWidgets);
    expect(find.textContaining('24-bit'), findsWidgets);

    // Verify Track title & artist
    expect(find.text('A Little Piece of Heaven'), findsOneWidget);
    expect(find.textContaining('Avenged Sevenfold'), findsWidgets);

    // Verify CustomTimeBar is rendered
    expect(find.byType(CustomTimeBar), findsOneWidget);

    // Verify Visualizer mode switcher button (initial: ARTWORK)
    expect(find.text('ARTWORK'), findsOneWidget);

    // Cycle visualizer mode to VU METERS
    await tester.tap(find.text('ARTWORK'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('VU METERS'), findsOneWidget);
    expect(find.text('ANALOG STEREO MONITOR'), findsOneWidget);

    // Cycle visualizer mode to SPECTRUM
    await tester.tap(find.text('VU METERS'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('SPECTRUM'), findsOneWidget);

    // 2. Test Landscape Car / Desk Docking
    tester.view.physicalSize = const Size(844, 390);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('EXIT DOCK'), findsOneWidget);
    expect(find.text('A Little Piece of Heaven'), findsOneWidget);
    expect(find.byType(CustomTimeBar), findsOneWidget);

    // 3. Test DSP preset pills
    final presetBtn = find.text('Audiophile Pure');
    if (presetBtn.evaluate().isNotEmpty) {
      await tester.tap(presetBtn.first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
    }
  });
}

class FakePlayerController extends StateNotifier<PlaybackState> implements PlayerController {
  FakePlayerController(super.state);

  @override
  void togglePlayPause() {
    state = state.copyWith(
      status: state.isPlaying ? PlaybackStatus.paused : PlaybackStatus.playing,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
