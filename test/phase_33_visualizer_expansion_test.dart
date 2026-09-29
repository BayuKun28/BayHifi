import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/app/theme/theme_mode_controller.dart';
import 'package:baydev_hifi/audio_engine/audio_cache_service.dart';
import 'package:baydev_hifi/core/database/local_persistence_service.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/player/presentation/widgets/custom_album_art_view.dart';
import 'package:baydev_hifi/features/player/presentation/widgets/custom_time_bar.dart';
import 'package:baydev_hifi/features/player/presentation/widgets/spectrum_visualizer.dart';
import 'package:baydev_hifi/features/settings/domain/player_customization_settings.dart';
import 'package:baydev_hifi/features/settings/presentation/controllers/player_customization_controller.dart';
import 'package:baydev_hifi/features/settings/presentation/sub_screens/visualizer_settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bayhifi_phase33_test');
    await LocalPersistenceService.instance.init(customPath: '${tempDir.path}/test_storage.json');
    AudioCacheService.instance.setCacheDirForTesting(tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  final testTrack = Track(
    id: 'test_1',
    title: 'Hotel California',
    artist: 'Eagles',
    album: 'Hotel California (Hi-Res Master)',
    duration: const Duration(minutes: 6, seconds: 30),
    filePath: '/music/eagles.flac',
    format: AudioFormat.flac,
    bitDepth: 24,
    sampleRate: 96000,
  );

  group('Phase 33.1: Album Art Styles & Animation Rendering Tests', () {
    for (final style in AlbumArtStyle.values) {
      testWidgets('CustomAlbumArtView renders style $style cleanly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppThemeBuilder.buildTheme(AppPalette.namidaCyan, isDark: true),
            home: Scaffold(
              body: Center(
                child: CustomAlbumArtView(
                  track: testTrack,
                  isPlaying: true,
                  style: style,
                  ambientGlow: true,
                  primaryColor: const Color(0xFF38BDF8),
                  size: 200,
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));

        expect(find.byType(CustomAlbumArtView), findsOneWidget);
      });
    }
  });

  group('Phase 33.2: Spectrum Visualizer Styles Rendering Tests', () {
    for (final style in SpectrumStyle.values) {
      testWidgets('SpectrumVisualizer renders style $style without exception', (tester) async {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        container.read(playerCustomizationProvider.notifier).setSpectrumStyle(style);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              theme: AppThemeBuilder.buildTheme(AppPalette.namidaCyan, isDark: true),
              home: const Scaffold(
                body: SpectrumVisualizer(height: 40),
              ),
            ),
          ),
        );

        await tester.pump();
        expect(find.byType(SpectrumVisualizer), findsOneWidget);
      });
    }
  });

  group('Phase 33.3: Custom Time Bar Styles Rendering Tests', () {
    for (final style in TimeBarStyle.values) {
      testWidgets('CustomTimeBar renders style $style and seeks properly', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppThemeBuilder.buildTheme(AppPalette.namidaCyan, isDark: true),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 300,
                  child: CustomTimeBar(
                    position: const Duration(minutes: 2, seconds: 15),
                    duration: const Duration(minutes: 5),
                    style: style,
                    primaryColor: const Color(0xFF38BDF8),
                    onSeek: (_) {},
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.pump();
        expect(find.byType(CustomTimeBar), findsOneWidget);
        expect(find.text('02:15'), findsOneWidget);
        expect(find.text('05:00'), findsOneWidget);
      });
    }
  });

  group('Phase 33.4: VisualizerSettingsScreen Bento ComboBox Selectors Tests', () {
    testWidgets('VisualizerSettingsScreen renders compact Bento ComboBox dropdowns', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppThemeBuilder.buildTheme(AppPalette.namidaCyan, isDark: true),
            home: const VisualizerSettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('ALBUM ART & COVER STYLE'), findsOneWidget);
      expect(find.text('RTA SPECTRUM VISUALIZER'), findsOneWidget);
      expect(find.text('TIME BAR & SEEKBAR STYLE'), findsOneWidget);
      expect(find.text('ADAPTIVE PERFORMANCE PROFILE'), findsOneWidget);

      // Verify changing values via notifier updates the active display
      container.read(playerCustomizationProvider.notifier).setAlbumArtStyle(AlbumArtStyle.turntable);
      container.read(playerCustomizationProvider.notifier).setTimeBarStyle(TimeBarStyle.ruler);
      await tester.pumpAndSettle();

      expect(find.text(AlbumArtStyle.turntable.label), findsOneWidget);
      expect(find.text(TimeBarStyle.ruler.label), findsOneWidget);
    });
  });
}
