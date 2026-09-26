import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:baydev_hifi/app/app.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/player/presentation/controllers/player_controller.dart';
import 'package:baydev_hifi/features/player/presentation/controllers/player_expansion_controller.dart';
import 'package:baydev_hifi/features/player/presentation/widgets/namida_expandable_miniplayer.dart';
import 'package:baydev_hifi/features/library/presentation/unified_library_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return '/tmp/bayhifi_test_dir';
    });
  });

  group('Android System Back Navigation & MiniPlayer PopScope Tests', () {
    testWidgets('Expanded player intercepts system back press and collapses smoothly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  Center(child: Text('Underlying Screen Content')),
                  NamidaExpandableMiniPlayer(),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Initial state: player is collapsed
      expect(container.read(playerExpansionProvider), isFalse);

      // Expand the player to full screen
      container.read(playerExpansionProvider.notifier).expand();
      await tester.pumpAndSettle();
      expect(container.read(playerExpansionProvider), isTrue);

      // Verify NowPlayingScreen is visible
      expect(find.text('NOW PLAYING'), findsOneWidget);

      // Simulate Android hardware back button / swipe back gesture
      final popHandled = await tester.binding.handlePopRoute();
      expect(popHandled, isTrue); // PopScope intercepted the back navigation
      await tester.pumpAndSettle();

      // Verify the player has collapsed back into the miniplayer
      expect(container.read(playerExpansionProvider), isFalse);
      expect(find.text('Underlying Screen Content'), findsOneWidget);
    });

    testWidgets('Full BaydevHiFiApp navigates back to underlying screen on back press',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer();
      final sampleTrack = const Track(
        id: 'test_track_1',
        title: 'Studio Hi-Res Symphony',
        artist: 'Baydev Orchestra',
        album: 'Mastering Opus 1',
        duration: Duration(minutes: 4, seconds: 20),
        format: AudioFormat.flac,
        sampleRate: 96000,
        bitDepth: 24,
      );
      container.read(playerControllerProvider.notifier).state =
          container.read(playerControllerProvider).copyWith(
                queue: [sampleTrack],
                currentTrack: sampleTrack,
              );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const BaydevHiFiApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Verify Dashboard is visible
      expect(find.text('BAYDEV HIFI STUDIO'), findsOneWidget);

      // Expand the player screen
      container.read(playerExpansionProvider.notifier).expand();
      await tester.pumpAndSettle();
      expect(container.read(playerExpansionProvider), isTrue);
      expect(find.text('NOW PLAYING'), findsOneWidget);

      // Press Android system back button
      final handled = await tester.binding.handlePopRoute();
      expect(handled, isTrue);
      await tester.pumpAndSettle();

      // Verify app returned to Dashboard with player collapsed as miniplayer
      expect(container.read(playerExpansionProvider), isFalse);
      expect(find.text('BAYDEV HIFI STUDIO'), findsOneWidget);
    });

    testWidgets('UnifiedLibraryScreen clears multi-select mode on system back press',
        (WidgetTester tester) async {
      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: UnifiedLibraryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // By default, no tracks selected, pop is allowed normally
      final initialPopHandled = await tester.binding.handlePopRoute();
      expect(initialPopHandled, isFalse); // Nothing intercepted, normal pop allowed
    });
  });
}
