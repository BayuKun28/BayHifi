import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/audio_engine/soloud_controller.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/player/presentation/widgets/parallax_artwork_card.dart';
import 'package:baydev_hifi/features/player/presentation/widgets/spectrum_visualizer.dart';
import 'package:baydev_hifi/features/pro_q_studio/presentation/widgets/interactive_eq_canvas.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Demand-Driven FFT Visualization Lifecycle Tests', () {
    final controller = SoLoudController.instance;

    setUp(() {
      controller.releaseVisualizationDemand('test_consumer_1');
      controller.releaseVisualizationDemand('test_consumer_2');
      controller.setAppForegroundState(true);
    });

    test('Acquiring demand increments demand count and sets state', () {
      expect(controller.visualizationDemandCount, 0);

      controller.acquireVisualizationDemand('test_consumer_1');
      expect(controller.visualizationDemandCount, 1);

      controller.acquireVisualizationDemand('test_consumer_2');
      expect(controller.visualizationDemandCount, 2);

      // Releasing demand decrements count
      controller.releaseVisualizationDemand('test_consumer_1');
      expect(controller.visualizationDemandCount, 1);

      controller.releaseVisualizationDemand('test_consumer_2');
      expect(controller.visualizationDemandCount, 0);
    });

    test('Moving app to background suspends FFT even with active consumers', () {
      controller.acquireVisualizationDemand('test_consumer_1');
      expect(controller.visualizationDemandCount, 1);

      // Simulate app minimized / sent to background
      controller.setAppForegroundState(false);
      expect(controller.isVisualizationActive, isFalse);

      // Simulate app resumed to foreground
      controller.setAppForegroundState(true);
      // Demand is still 1, so it re-activates
      expect(controller.visualizationDemandCount, 1);

      // Cleanup
      controller.releaseVisualizationDemand('test_consumer_1');
    });

    test('Manual override enables and disables demand cleanly', () {
      controller.setVisualizationEnabledManually(true);
      expect(controller.visualizationDemandCount, greaterThanOrEqualTo(1));

      controller.setVisualizationEnabledManually(false);
      expect(controller.visualizationDemandCount, 0);
    });
  });

  group('ParallaxArtworkCard GPU-Isolated Transforms Tests', () {
    testWidgets('ParallaxArtworkCard renders without rebuild exceptions and handles tap', (tester) async {
      final track = Track(
        id: 'test_track_1',
        title: 'Thermal Test Song',
        artist: 'HiFi Lab',
        album: 'Cooling Album',
        duration: const Duration(minutes: 3),
      );

      bool singleTapped = false;
      bool doubleTapped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: ParallaxArtworkCard(
                  track: track,
                  isPlaying: true,
                  size: 280,
                  primaryColor: Colors.cyan,
                  onSingleTap: () => singleTapped = true,
                  onDoubleTap: () => doubleTapped = true,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify widget rendered
      expect(find.byType(ParallaxArtworkCard), findsOneWidget);
      expect(find.byType(RepaintBoundary), findsWidgets);

      // Verify tap interaction
      await tester.tap(find.byType(ParallaxArtworkCard));
      await tester.pump(const Duration(milliseconds: 300));
      expect(singleTapped, isTrue);

      // Verify double-tap interaction
      await tester.tap(find.byType(ParallaxArtworkCard));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.tap(find.byType(ParallaxArtworkCard));
      await tester.pump(const Duration(milliseconds: 300));
      expect(doubleTapped, isTrue);
    });

    testWidgets('ParallaxArtworkCard updates demand when isPlaying toggles', (tester) async {
      final controller = SoLoudController.instance;
      final track = Track(
        id: 'test_track_2',
        title: 'Pulse Track',
        artist: 'Studio',
        album: 'Dynamics',
        duration: const Duration(minutes: 4),
      );

      final isPlayingNotifier = ValueNotifier<bool>(false);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ValueListenableBuilder<bool>(
                valueListenable: isPlayingNotifier,
                builder: (context, isPlaying, _) {
                  return ParallaxArtworkCard(
                    track: track,
                    isPlaying: isPlaying,
                    size: 200,
                    primaryColor: Colors.teal,
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      // Initially not playing
      final initialCount = controller.visualizationDemandCount;

      // Start playing
      isPlayingNotifier.value = true;
      await tester.pump();
      expect(controller.visualizationDemandCount, initialCount + 1);

      // Stop playing
      isPlayingNotifier.value = false;
      await tester.pump();
      expect(controller.visualizationDemandCount, initialCount);
    });
  });

  group('SpectrumVisualizer and InteractiveEqCanvas Lifecycle Tests', () {
    testWidgets('SpectrumVisualizer acquires demand on mount and releases on dispose', (tester) async {
      final controller = SoLoudController.instance;
      final initialCount = controller.visualizationDemandCount;

      final showVisualizer = ValueNotifier<bool>(true);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ValueListenableBuilder<bool>(
                valueListenable: showVisualizer,
                builder: (context, show, _) {
                  return show ? const SpectrumVisualizer(height: 50) : const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(controller.visualizationDemandCount, initialCount + 1);

      // Unmount visualizer
      showVisualizer.value = false;
      await tester.pump();
      expect(controller.visualizationDemandCount, initialCount);
    });

    testWidgets('InteractiveEqCanvas acquires demand on mount and releases on dispose', (tester) async {
      final controller = SoLoudController.instance;
      final initialCount = controller.visualizationDemandCount;

      final showCanvas = ValueNotifier<bool>(true);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: ValueListenableBuilder<bool>(
                valueListenable: showCanvas,
                builder: (context, show, _) {
                  return show ? const SizedBox(height: 300, child: InteractiveEqCanvas()) : const SizedBox.shrink();
                },
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(controller.visualizationDemandCount, initialCount + 1);

      // Unmount canvas
      showCanvas.value = false;
      await tester.pump();
      expect(controller.visualizationDemandCount, initialCount);
    });
  });
}
