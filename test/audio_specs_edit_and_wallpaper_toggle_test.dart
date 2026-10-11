import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:baydev_hifi/app/theme/theme_mode_controller.dart';
import 'package:baydev_hifi/core/database/local_persistence_service.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/player/presentation/widgets/audio_file_inspector_sheet.dart';
import 'package:baydev_hifi/features/library/presentation/widgets/metadata_tag_editor_sheet.dart';
import 'package:baydev_hifi/features/settings/presentation/sub_screens/theming_settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bayhifi_spec_wp_test_');
    await LocalPersistenceService.instance.init(
      customPath: '${tempDir.path}/test_storage.json',
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('AudioFileInspectorSheet Quick Action Edit Metadata Tests', () {
    const testTrack = Track(
      id: 'spec_track_42',
      title: 'HiFi Mastering Suite',
      artist: 'Acoustic Labs',
      album: 'Studio Reference Vol 1',
      genre: 'Audiophile',
      year: 2026,
      trackNumber: 7,
      duration: Duration(minutes: 4, seconds: 15),
      filePath: '/music/mastering_suite.flac',
      sampleRate: 96000,
      bitDepth: 24,
      format: AudioFormat.flac,
    );

    testWidgets('Renders Edit Metadata button in header and summary card', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => AudioFileInspectorSheet.show(ctx, testTrack),
                  child: const Text('Open Inspector'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Inspector'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify Audio File Inspector is visible
      expect(find.text('AUDIO FILE INSPECTOR'), findsOneWidget);
      expect(find.text('HiFi Mastering Suite'), findsWidgets);
      expect(find.text('Acoustic Labs • Studio Reference Vol 1'), findsWidgets);

      // Verify EDIT TAGS button in the track summary card
      expect(find.text('EDIT TAGS'), findsOneWidget);

      // Verify the header edit icon button with tooltip
      expect(find.byTooltip('Edit Metadata Tags'), findsOneWidget);
    });

    testWidgets('Tapping EDIT TAGS dismisses inspector and opens MetadataTagEditorSheet', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (ctx) => ElevatedButton(
                  onPressed: () => AudioFileInspectorSheet.show(ctx, testTrack),
                  child: const Text('Open Inspector'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Inspector'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Tap EDIT TAGS button
      final editTagsFinder = find.text('EDIT TAGS');
      expect(editTagsFinder, findsOneWidget);
      await tester.tap(editTagsFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify AudioFileInspectorSheet is dismissed
      expect(find.text('AUDIO FILE INSPECTOR'), findsNothing);

      // Verify MetadataTagEditorSheet is opened with track details
      expect(find.byType(MetadataTagEditorSheet), findsOneWidget);
      expect(find.text('STUDIO TAG EDITOR'), findsOneWidget);
    });
  });

  group('Background Wallpaper Toggle Lockout Fix Tests', () {
    test('Preset wallpaper hasImage is true and toggle switch remains active', () async {
      final container = ProviderContainer();
      final controller = container.read(themeControllerProvider.notifier);

      // Select preset wallpaper
      final preset = StudioWallpaperPreset.presets.first;
      await controller.setWallpaperPreset(preset);

      final state = container.read(themeControllerProvider);
      expect(state.wallpaperSettings.enabled, true);
      expect(state.wallpaperSettings.isAsset, true);
      expect(state.wallpaperSettings.imagePath, preset.assetPath);

      // Verify hasImage logic equivalent in ThemingSettingsScreen
      final hasImage = state.wallpaperSettings.imagePath != null &&
          state.wallpaperSettings.imagePath!.isNotEmpty &&
          (state.wallpaperSettings.isAsset || File(state.wallpaperSettings.imagePath!).existsSync());
      expect(hasImage, isTrue, reason: 'Preset asset wallpaper must evaluate hasImage as true');
    });

    testWidgets('ThemingSettingsScreen wallpaper switch can be toggled OFF when preset wallpaper is active', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() => tester.view.resetPhysicalSize());

      final container = ProviderContainer();
      final controller = container.read(themeControllerProvider.notifier);

      // Activate preset wallpaper
      final preset = StudioWallpaperPreset.presets.first;
      await controller.setWallpaperPreset(preset);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ThemingSettingsScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify ACTIVE badge is present
      expect(find.text('ACTIVE'), findsOneWidget);

      // Find the specific wallpaper toggle M3ESwitch by key
      final switchFinder = find.byKey(const ValueKey('wallpaper_toggle_switch'));
      expect(switchFinder, findsOneWidget);

      final switchWidget = tester.widget<M3ESwitch>(switchFinder);
      expect(switchWidget.value, true);
      expect(switchWidget.onChanged, isNotNull, reason: 'Switch must not be disabled when wallpaper is enabled');

      // Toggle wallpaper OFF
      await tester.tap(switchFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // State should reflect disabled wallpaper
      final updatedState = container.read(themeControllerProvider);
      expect(updatedState.wallpaperSettings.enabled, false);
      expect(find.text('ACTIVE'), findsNothing);
    });

    test('ThemeController setPalette decouples syncPalette without breaking wallpaper toggling', () async {
      final container = ProviderContainer();
      final controller = container.read(themeControllerProvider.notifier);

      // Set preset wallpaper with initial syncPalette true
      final preset = StudioWallpaperPreset.presets.first;
      await controller.setWallpaperPreset(preset, syncPalette: true);

      var state = container.read(themeControllerProvider);
      expect(state.wallpaperSettings.enabled, true);
      expect(state.wallpaperSettings.syncPalette, true);

      // User explicitly selects another palette
      controller.setPalette(AppPalette.trueOledBlack);

      state = container.read(themeControllerProvider);
      expect(state.currentPalette.id, AppPalette.trueOledBlack.id);
      expect(state.wallpaperSettings.syncPalette, false, reason: 'Manual palette choice sets syncPalette to false');
      expect(state.wallpaperSettings.enabled, true, reason: 'Wallpaper background stays enabled until explicitly toggled off');

      // User toggles wallpaper off
      controller.toggleWallpaperEnabled(false);
      expect(container.read(themeControllerProvider).wallpaperSettings.enabled, false);

      // User toggles wallpaper back on
      controller.toggleWallpaperEnabled(true);
      expect(container.read(themeControllerProvider).wallpaperSettings.enabled, true);
    });
  });
}
