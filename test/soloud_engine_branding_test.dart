import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/audio_engine/soloud_controller.dart';
import 'package:baydev_hifi/features/player/domain/playback_state.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/player/presentation/controllers/player_controller.dart';
import 'package:baydev_hifi/features/player/presentation/now_playing_screen.dart';
import 'package:baydev_hifi/features/player/presentation/widgets/audio_file_inspector_sheet.dart';
import 'package:baydev_hifi/features/settings/presentation/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testTrack = Track(
    id: 'test_branding_track',
    title: 'Clair de Lune',
    artist: 'Claude Debussy',
    album: 'Suite bergamasque',
    duration: const Duration(minutes: 5, seconds: 3),
    filePath: '/music/debussy.flac',
    format: AudioFormat.flac,
    bitDepth: 24,
    sampleRate: 96000,
  );

  group('Option 1: Settings Screen SoLoud Branding Tests', () {
    testWidgets('Settings watermark renders POWERED BY SOLOUD C++ AUDIO ENGINE chip', (tester) async {
      tester.view.physicalSize = const Size(500, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Drag to bottom
      await tester.drag(find.byType(ListView), const Offset(0, -1500));
      await tester.pump();

      expect(find.text('POWERED BY SOLOUD C++ AUDIO ENGINE'), findsOneWidget);
    });
  });

  group('Option 4: Now Playing & Inspector SoLoud Branding Tests', () {
    testWidgets('NowPlayingScreen displays SOLOUD in portrait auxiliary bar', (tester) async {
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playerControllerProvider.overrideWith((ref) {
              final notifier = PlayerController(SoLoudController.instance);
              notifier.state = PlaybackState(
                currentTrack: testTrack,
                status: PlaybackStatus.playing,
                position: const Duration(seconds: 30),
                duration: const Duration(minutes: 5, seconds: 3),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: NowPlayingScreen(onOpenProQStudio: () {}),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Auxiliary format badge contains • SOLOUD
      expect(find.text('• SOLOUD'), findsOneWidget);
    });

    testWidgets('NowPlayingScreen displays POWERED BY SOLOUD ENGINE in landscape deck', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playerControllerProvider.overrideWith((ref) {
              final notifier = PlayerController(SoLoudController.instance);
              notifier.state = PlaybackState(
                currentTrack: testTrack,
                status: PlaybackStatus.playing,
                position: const Duration(seconds: 30),
                duration: const Duration(minutes: 5, seconds: 3),
              );
              return notifier;
            }),
          ],
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: NowPlayingScreen(onOpenProQStudio: () {}),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Desktop specs deck contains POWERED BY SOLOUD ENGINE
      expect(find.text('POWERED BY SOLOUD ENGINE'), findsOneWidget);
    });

    testWidgets('AudioFileInspectorSheet displays SoLoud C++ Native Engine pipeline', (tester) async {
      tester.view.physicalSize = const Size(500, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.dark(),
            home: Scaffold(
              body: AudioFileInspectorSheet(
                track: testTrack.copyWith(filePath: ''),
              ),
            ),
          ),
        ),
      );
      // Pump multiple frames for FutureBuilder to complete
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('AUDIO ENGINE PIPELINE'), findsOneWidget);
      expect(find.text('SoLoud C++ Native Engine'), findsOneWidget);
      expect(find.text('32-bit Floating-Point Low Latency Pipeline'), findsOneWidget);
    });
  });
}
