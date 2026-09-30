import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:baydev_hifi/audio_engine/soloud_controller.dart';
import 'package:baydev_hifi/features/player/domain/playback_state.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/player/presentation/controllers/player_controller.dart';
import 'package:baydev_hifi/features/player/presentation/now_playing_screen.dart';
import 'package:baydev_hifi/features/player/presentation/studio_desk_docking_screen.dart';
import 'package:baydev_hifi/features/player/presentation/widgets/namida_expandable_miniplayer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testTrack = Track(
    id: 'yt_stream_test_1',
    title: 'Streaming HiFi Master',
    artist: 'Antigravity Studio',
    album: 'Audiophile Sessions',
    duration: const Duration(minutes: 4, seconds: 15),
    remoteUrl: 'https://stream.example.com/audio.opus',
    format: AudioFormat.opus,
  );

  test('PlaybackState isLoading and isBuffering getters work correctly', () {
    const idleState = PlaybackState(status: PlaybackStatus.idle);
    expect(idleState.isLoading, isFalse);
    expect(idleState.isBuffering, isFalse);
    expect(idleState.isPlaying, isFalse);

    const loadingState = PlaybackState(status: PlaybackStatus.loading);
    expect(loadingState.isLoading, isTrue);
    expect(loadingState.isBuffering, isTrue);
    expect(loadingState.isPlaying, isFalse);

    const playingState = PlaybackState(status: PlaybackStatus.playing);
    expect(playingState.isLoading, isFalse);
    expect(playingState.isBuffering, isFalse);
    expect(playingState.isPlaying, isTrue);
  });

  testWidgets('NowPlayingScreen displays M3EProgressIndicator when loading/buffering', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 850));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerControllerProvider.overrideWith((ref) {
            final notifier = PlayerController(SoLoudController.instance);
            notifier.state = PlaybackState(
              currentTrack: testTrack,
              status: PlaybackStatus.loading,
              duration: const Duration(minutes: 4, seconds: 15),
            );
            return notifier;
          }),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: NowPlayingScreen(onOpenProQStudio: () {}),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Progress indicator should be rendered inside the Play/Pause button
    expect(find.byWidgetPredicate((w) => w is M3EProgressIndicator || w is CircularProgressIndicator || w.runtimeType.toString().contains('ProgressIndicator')), findsWidgets);
    expect(find.byTooltip('Buffering...'), findsOneWidget);
  });

  testWidgets('NamidaExpandableMiniPlayer displays M3EProgressIndicator when loading/buffering', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 850));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerControllerProvider.overrideWith((ref) {
            final notifier = PlayerController(SoLoudController.instance);
            notifier.state = PlaybackState(
              currentTrack: testTrack,
              status: PlaybackStatus.loading,
              duration: const Duration(minutes: 4, seconds: 15),
            );
            return notifier;
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: Stack(
              children: [
                SizedBox.expand(),
                NamidaExpandableMiniPlayer(),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Progress indicator should be rendered inside the miniplayer circle button
    expect(find.byWidgetPredicate((w) => w is M3EProgressIndicator || w is CircularProgressIndicator || w.runtimeType.toString().contains('ProgressIndicator')), findsWidgets);
  });

  testWidgets('StudioDeskDockingScreen displays progress indicator when loading/buffering', (tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 600));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerControllerProvider.overrideWith((ref) {
            final notifier = PlayerController(SoLoudController.instance);
            notifier.state = PlaybackState(
              currentTrack: testTrack,
              status: PlaybackStatus.loading,
              duration: const Duration(minutes: 4, seconds: 15),
            );
            return notifier;
          }),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: StudioDeskDockingScreen(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Progress indicator should be rendered inside the desk docking centerpiece
    expect(find.byWidgetPredicate((w) => w is M3EProgressIndicator || w is CircularProgressIndicator || w.runtimeType.toString().contains('ProgressIndicator')), findsWidgets);
    expect(find.byTooltip('Buffering...'), findsOneWidget);
  });
}
