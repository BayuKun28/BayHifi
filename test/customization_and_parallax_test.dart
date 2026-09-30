import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/settings/domain/player_customization_settings.dart';
import 'package:baydev_hifi/features/settings/presentation/controllers/player_customization_controller.dart';
import 'package:baydev_hifi/features/player/presentation/widgets/parallax_artwork_card.dart';
import 'package:baydev_hifi/features/library/presentation/widgets/track_tile.dart';
import 'package:baydev_hifi/features/settings/presentation/sub_screens/visualizer_settings_screen.dart';
import 'package:baydev_hifi/features/settings/presentation/sub_screens/gestures_settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlayerCustomizationSettings Domain & Presets Tests', () {
    test('Default settings verify studio audiophile defaults', () {
      const settings = PlayerCustomizationSettings();

      expect(settings.albumArtStyle, AlbumArtStyle.cdJewel);
      expect(settings.spectrumStyle, SpectrumStyle.m3Expressive);
      expect(settings.timeBarStyle, TimeBarStyle.wavy);
      expect(settings.ambientGlow, isTrue);
      expect(settings.ambientGlowIntensity, 0.35);
      expect(settings.fftBins, 512);

      expect(settings.performanceMode, PerformanceMode.studioHiFi);
      expect(settings.enableParallax, isTrue);
      expect(settings.parallaxIntensity, 1.0);
      expect(settings.enableBackdropBlur, isTrue);
      expect(settings.blurSigma, 18.0);
      expect(settings.enableBreathingPulse, isTrue);

      expect(settings.singleTapAction, ArtworkGestureAction.toggleLyrics);
      expect(settings.doubleTapAction, ArtworkGestureAction.toggleFavorite);
      expect(settings.longPressAction, ArtworkGestureAction.openInspector);

      expect(settings.trackTitleFirst, isTrue);
      expect(settings.trackShowFormatBadge, isTrue);
      expect(settings.trackShowBitrate, isTrue);
      expect(settings.trackShowDuration, isTrue);
      expect(settings.trackShowDirectFav, isTrue);
      expect(settings.trackSwipeLeft, TrackTileSwipeAction.addToQueue);
      expect(settings.trackSwipeRight, TrackTileSwipeAction.toggleFavorite);
    });

    test('Performance mode application updates dependent graphics toggles', () async {
      final notifier = PlayerCustomizationNotifier();

      // Switch to Battery Saver
      await notifier.setPerformanceMode(PerformanceMode.batterySaver);
      expect(notifier.state.performanceMode, PerformanceMode.batterySaver);
      expect(notifier.state.enableParallax, isFalse);
      expect(notifier.state.ambientGlow, isFalse);
      expect(notifier.state.enableBackdropBlur, isFalse);
      expect(notifier.state.enableBreathingPulse, isFalse);

      // Switch to Balanced
      await notifier.setPerformanceMode(PerformanceMode.balanced);
      expect(notifier.state.performanceMode, PerformanceMode.balanced);
      expect(notifier.state.enableParallax, isTrue);
      expect(notifier.state.parallaxIntensity, 0.6);
      expect(notifier.state.blurSigma, 12.0);

      // Switch to Studio HiFi
      await notifier.setPerformanceMode(PerformanceMode.studioHiFi);
      expect(notifier.state.performanceMode, PerformanceMode.studioHiFi);
      expect(notifier.state.enableParallax, isTrue);
      expect(notifier.state.parallaxIntensity, 1.0);
      expect(notifier.state.ambientGlow, isTrue);
      expect(notifier.state.enableBreathingPulse, isTrue);
    });

    test('Enum parsers map string identifiers with fallback safety', () {
      expect(PerformanceMode.fromString('batterySaver'), PerformanceMode.batterySaver);
      expect(PerformanceMode.fromString('invalid'), PerformanceMode.studioHiFi);

      expect(ArtworkGestureAction.fromString('openDspRack'), ArtworkGestureAction.openDspRack);
      expect(ArtworkGestureAction.fromString('invalid', ArtworkGestureAction.none), ArtworkGestureAction.none);

      expect(TrackTileSwipeAction.fromString('playNext'), TrackTileSwipeAction.playNext);
      expect(TrackTileSwipeAction.fromString(null), TrackTileSwipeAction.none);

      expect(AlbumArtStyle.fromString('vinyl'), AlbumArtStyle.vinyl);
      expect(AlbumArtStyle.fromString('nonexistent'), AlbumArtStyle.cdJewel);
    });
  });

  group('Customization UI Widgets Tests', () {
    final mockTrack = Track(
      id: '/mock/track.flac',
      title: 'Acoustic Masterpiece',
      artist: 'Studio Virtuoso',
      album: 'Reference Mastering 2026',
      duration: const Duration(minutes: 4, seconds: 12),
      format: AudioFormat.flac,
      sampleRate: 96000,
      bitDepth: 24,
    );

    testWidgets('ParallaxArtworkCard renders correctly and triggers gestures', (tester) async {
      bool singleTapped = false;
      bool longPressed = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Center(
                child: ParallaxArtworkCard(
                  track: mockTrack,
                  isPlaying: false,
                  size: 200,
                  primaryColor: const Color(0xFF00E5FF),
                  onSingleTap: () => singleTapped = true,
                  onLongPress: () => longPressed = true,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ParallaxArtworkCard), findsOneWidget);

      // Tap gesture
      await tester.tap(find.byType(ParallaxArtworkCard));
      await tester.pump(const Duration(milliseconds: 300));
      expect(singleTapped, isTrue);

      // Long press gesture
      await tester.longPress(find.byType(ParallaxArtworkCard));
      await tester.pump();
      expect(longPressed, isTrue);
    });

    testWidgets('TrackTile displays metadata, format badge, and tabular figures', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: TrackTile(
                track: mockTrack,
                isPlaying: false,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Acoustic Masterpiece'), findsOneWidget);
      expect(find.text('Studio Virtuoso • Reference Mastering 2026'), findsOneWidget);
      expect(find.text('FLAC'), findsOneWidget);
      expect(find.text('96.0kHz'), findsOneWidget);
      expect(find.text('04:12'), findsOneWidget);

      await tester.tap(find.text('Acoustic Masterpiece'));
      expect(tapped, isTrue);
    });

    testWidgets('VisualizerSettingsScreen renders all sections without error', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: VisualizerSettingsScreen(),
          ),
        ),
      );

      expect(find.text('VISUAL DYNAMICS & DISPLAY'), findsOneWidget);
      expect(find.text('ADAPTIVE PERFORMANCE PROFILE'), findsOneWidget);
      expect(find.text('3D PARALLAX MOTION & BREATHING PULSE'), findsOneWidget);
      expect(find.text('DYNAMIC BACKDROP BLUR & AMBIENT GLOW'), findsOneWidget);
      expect(find.text('ALBUM ART & COVER STYLE'), findsOneWidget);
      expect(find.text('RTA SPECTRUM VISUALIZER'), findsOneWidget);
    });

    testWidgets('GesturesSettingsScreen renders gesture configuration switches', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: GesturesSettingsScreen(),
          ),
        ),
      );

      expect(find.text('GESTURES & TRACK TILES'), findsOneWidget);
      expect(find.text('NOW PLAYING ARTWORK GESTURES'), findsOneWidget);
      expect(find.text('TRACK TILE DISPLAY & METADATA'), findsOneWidget);
      expect(find.text('TRACK LIST SWIPE ACTIONS'), findsOneWidget);
      expect(find.text('Title First Layout'), findsOneWidget);
      expect(find.text('Show Audio Format Badge'), findsOneWidget);
    });
  });
}
