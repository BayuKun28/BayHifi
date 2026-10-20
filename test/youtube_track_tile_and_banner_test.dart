import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/youtube_music/presentation/widgets/youtube_offline_banner.dart';
import 'package:baydev_hifi/features/youtube_music/presentation/widgets/youtube_track_tile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testTrack = Track(
    id: 'yt_test_1',
    title: 'Starboy',
    artist: 'The Weeknd',
    album: 'Starboy',
    duration: const Duration(minutes: 3, seconds: 50),
    filePath: 'https://stream.youtube.com/audio/starboy',
    format: AudioFormat.opus,
  );

  testWidgets('YouTubeTrackTile renders title, artist, opus tag and responds to tap', (tester) async {
    bool tapped = false;
    bool radioStarted = false;

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: YouTubeTrackTile(
              track: testTrack,
              isPlaying: false,
              onTap: () => tapped = true,
              onStartRadio: () => radioStarted = true,
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Starboy'), findsOneWidget);
    expect(find.text('The Weeknd'), findsOneWidget);
    expect(find.text('OPUS'), findsOneWidget);

    await tester.tap(find.text('Starboy'));
    await tester.pump();
    expect(tapped, isTrue);

    await tester.tap(find.byIcon(LucideIcons.radio));
    await tester.pump();
    expect(radioStarted, isTrue);
  });

  testWidgets('YouTubeOfflineBanner renders retry message and triggers callback', (tester) async {
    bool retried = false;

    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: Scaffold(
          body: YouTubeOfflineBanner(
            message: 'No internet connection',
            onRetry: () => retried = true,
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('No internet connection'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pump();
    expect(retried, isTrue);
  });
}
