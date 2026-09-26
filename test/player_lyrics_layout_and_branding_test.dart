import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/audio_engine/soloud_controller.dart';
import 'package:baydev_hifi/core/widgets/floating_rounded_dock.dart';
import 'package:baydev_hifi/features/dashboard/presentation/dashboard_screen.dart';
import 'package:baydev_hifi/features/player/domain/playback_state.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/player/presentation/controllers/player_controller.dart';
import 'package:baydev_hifi/features/player/presentation/now_playing_screen.dart';
import 'package:baydev_hifi/features/settings/presentation/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testTrack = Track(
    id: 'test_track_1',
    title: 'Symphony in D Minor',
    artist: 'Baydev Orchestra',
    album: 'Audiophile Collection Vol 1',
    duration: const Duration(minutes: 5, seconds: 20),
    filePath: '/music/test.flac',
    format: AudioFormat.flac,
    bitDepth: 24,
    sampleRate: 96000,
  );

  testWidgets('NowPlayingScreen lyrics toggle maintains deterministic bottom controls position', (tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 850));

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          playerControllerProvider.overrideWith((ref) {
            final notifier = PlayerController(SoLoudController.instance);
            notifier.state = PlaybackState(
              currentTrack: testTrack,
              status: PlaybackStatus.playing,
              position: const Duration(seconds: 45),
              duration: const Duration(minutes: 5, seconds: 20),
            );
            return notifier;
          }),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: NowPlayingScreen(
              onOpenProQStudio: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify Baydev branding and header in Now Playing
    expect(find.text('NOW PLAYING'), findsOneWidget);
    expect(find.text('BAYDEV AUDIO ENGINE'), findsOneWidget);

    // Capture initial Y position of Play/Pause button
    final playPauseFinder = find.byTooltip('Pause');
    expect(playPauseFinder, findsOneWidget);
    final initialPlayPauseOffset = tester.getTopLeft(playPauseFinder);

    // Toggle Lyrics mode
    final lyricsButtonFinder = find.text('Lyric');
    expect(lyricsButtonFinder, findsOneWidget);
    await tester.tap(lyricsButtonFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify lyrics view is rendered
    expect(find.byKey(const ValueKey('lyrics_view')), findsOneWidget);

    // Verify Play/Pause button Y position did NOT shift
    final postLyricsPlayPauseOffset = tester.getTopLeft(playPauseFinder);
    expect(postLyricsPlayPauseOffset.dy, equals(initialPlayPauseOffset.dy));

    // Toggle back to Album Art view
    await tester.tap(lyricsButtonFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    // Verify position remains identical
    final finalPlayPauseOffset = tester.getTopLeft(playPauseFinder);
    expect(finalPlayPauseOffset.dy, equals(initialPlayPauseOffset.dy));
  });

  testWidgets('DashboardScreen renders Baydev studio logo in header', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: DashboardScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('BAYDEV HIFI STUDIO'), findsOneWidget);
    expect(find.byType(Image), findsWidgets);
  });

  testWidgets('SettingsScreen renders Baydev watermark at bottom', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1080, 2400));

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: SettingsScreen(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('BAYDEV HIFI STUDIO'), findsOneWidget);
    expect(find.text('Crafted by Baydev Studio'), findsOneWidget);
  });

  testWidgets('FloatingRoundedDock renders all 5 studio tabs with proportional layout', (tester) async {
    int selectedIndex = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FloatingRoundedDock(
            selectedIndex: selectedIndex,
            onItemSelected: (idx) => selectedIndex = idx,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('DSP Rack'), findsOneWidget);
    expect(find.text('Library'), findsOneWidget);
    expect(find.text('Playlists'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });
}
