import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:baydev_hifi/audio_engine/soloud_controller.dart';
import 'package:baydev_hifi/features/player/domain/playback_state.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/player/presentation/controllers/player_controller.dart';
import 'package:baydev_hifi/features/player/presentation/now_playing_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testTrack = Track(
    id: 'responsive_track_1',
    title: 'Echoes',
    artist: 'Pink Floyd',
    album: 'Meddle',
    duration: const Duration(minutes: 23, seconds: 31),
    filePath: '/music/meddle_echoes.flac',
    format: AudioFormat.flac,
    bitDepth: 24,
    sampleRate: 96000,
  );

  testWidgets('NowPlayingScreen does not crash on narrow mobile window (<300px)', (tester) async {
    // Ultra narrow window test (e.g., floating split-screen on desktop or compact mobile)
    tester.view.physicalSize = const Size(260, 520);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerControllerProvider.overrideWith((ref) {
            final notifier = PlayerController(SoLoudController.instance);
            notifier.state = PlaybackState(
              currentTrack: testTrack,
              queue: [testTrack],
              queueIndex: 0,
              status: PlaybackStatus.playing,
              position: const Duration(minutes: 2, seconds: 15),
              duration: const Duration(minutes: 23, seconds: 31),
            );
            return notifier;
          }),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: NowPlayingScreen(
              onCollapse: () {},
              onOpenProQStudio: () {},
              onOpenDspRack: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify track title and artist render without clamp crash
    expect(find.text('Echoes'), findsOneWidget);
    expect(find.text('FLAC'), findsOneWidget);
  });

  testWidgets('NowPlayingScreen auxiliary bar buttons are interactive on tablet portrait', (tester) async {
    tester.view.physicalSize = const Size(600, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    bool proQOpened = false;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerControllerProvider.overrideWith((ref) {
            final notifier = PlayerController(SoLoudController.instance);
            notifier.state = PlaybackState(
              currentTrack: testTrack,
              queue: [testTrack],
              queueIndex: 0,
              status: PlaybackStatus.playing,
              position: const Duration(minutes: 5, seconds: 0),
              duration: const Duration(minutes: 23, seconds: 31),
            );
            return notifier;
          }),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: NowPlayingScreen(
              onCollapse: () {},
              onOpenProQStudio: () => proQOpened = true,
              onOpenDspRack: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify auxiliary bar elements
    expect(find.text('FLAC'), findsOneWidget);
    expect(find.text('LYRICS'), findsOneWidget);

    // Tap Pro-Q spectrum button
    final proQBtn = find.byIcon(LucideIcons.audioLines);
    expect(proQBtn, findsOneWidget);
    await tester.tap(proQBtn);
    await tester.pump();

    expect(proQOpened, isTrue);
  });
}
