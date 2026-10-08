import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/app/theme/theme_mode_controller.dart';
import 'package:baydev_hifi/core/database/local_persistence_service.dart';
import 'package:baydev_hifi/core/widgets/studio_wallpaper_backdrop.dart';
import 'package:baydev_hifi/features/settings/presentation/sub_screens/theming_settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('baydev_wallpaper_test_');
    await LocalPersistenceService.instance.init(
      customPath: '${tempDir.path}/test_storage.json',
    );
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('WallpaperSettings Model & Serialization Tests', () {
    test('Default values are correct and safe for studio aesthetics', () {
      const settings = WallpaperSettings();
      expect(settings.enabled, false);
      expect(settings.imagePath, isNull);
      expect(settings.blurRadius, 16.0);
      expect(settings.dimOpacity, 0.45);
      expect(settings.syncPalette, true);
      expect(settings.scope, WallpaperScope.appWide);
      expect(settings.extractedPrimary, isNull);
      expect(settings.extractedSecondary, isNull);
      expect(settings.extractedTertiary, isNull);
    });

    test('copyWith updates fields correctly', () {
      const settings = WallpaperSettings();
      final updated = settings.copyWith(
        enabled: true,
        imagePath: '/path/to/wallpaper.jpg',
        blurRadius: 24.0,
        dimOpacity: 0.60,
        syncPalette: false,
        scope: WallpaperScope.dashboardAndPlayer,
        extractedPrimary: const Color(0xFF38BDF8),
        extractedSecondary: const Color(0xFF0284C7),
        extractedTertiary: const Color(0xFFA855F7),
      );

      expect(updated.enabled, true);
      expect(updated.imagePath, '/path/to/wallpaper.jpg');
      expect(updated.blurRadius, 24.0);
      expect(updated.dimOpacity, 0.60);
      expect(updated.syncPalette, false);
      expect(updated.scope, WallpaperScope.dashboardAndPlayer);
      expect(updated.extractedPrimary, const Color(0xFF38BDF8));
      expect(updated.extractedSecondary, const Color(0xFF0284C7));
      expect(updated.extractedTertiary, const Color(0xFFA855F7));
    });

    test('toJson and fromJson serialize & deserialize deterministically', () {
      final original = const WallpaperSettings(
        enabled: true,
        imagePath: '/data/wallpaper_4k.png',
        blurRadius: 20.0,
        dimOpacity: 0.50,
        syncPalette: true,
        scope: WallpaperScope.appWide,
        extractedPrimary: Color(0xFF10B981),
        extractedSecondary: Color(0xFF059669),
        extractedTertiary: Color(0xFF34D399),
      );

      final json = original.toJson();
      final restored = WallpaperSettings.fromJson(json);

      expect(restored.enabled, original.enabled);
      expect(restored.imagePath, original.imagePath);
      expect(restored.blurRadius, original.blurRadius);
      expect(restored.dimOpacity, original.dimOpacity);
      expect(restored.syncPalette, original.syncPalette);
      expect(restored.scope, original.scope);
      expect(restored.extractedPrimary?.toARGB32(), original.extractedPrimary?.toARGB32());
      expect(restored.extractedSecondary?.toARGB32(), original.extractedSecondary?.toARGB32());
      expect(restored.extractedTertiary?.toARGB32(), original.extractedTertiary?.toARGB32());
    });
    test('isAsset returns true for asset paths and false for storage paths', () {
      const assetSettings = WallpaperSettings(imagePath: 'assets/images/wallpapers/obsidian_soundwaves.jpg');
      expect(assetSettings.isAsset, isTrue);
      expect(assetSettings.hasWallpaper, isTrue);

      const fileSettings = WallpaperSettings(imagePath: '/data/user/0/wallpaper.jpg');
      expect(fileSettings.isAsset, isFalse);
      expect(fileSettings.hasWallpaper, isTrue);

      const emptySettings = WallpaperSettings();
      expect(emptySettings.isAsset, isFalse);
      expect(emptySettings.hasWallpaper, isFalse);
    });

    test('StudioWallpaperPreset.presets contains 6 preloaded audiophile presets', () {
      expect(StudioWallpaperPreset.presets.length, 6);
      final ids = StudioWallpaperPreset.presets.map((p) => p.id).toList();
      expect(ids, contains('obsidian_soundwaves'));
      expect(ids, contains('warm_tube_analog'));
      expect(ids, contains('mastering_console'));
      expect(ids, contains('cyber_spectrum'));
      expect(ids, contains('dark_tech'));
      expect(ids, contains('vinyl_resonance'));

      for (final preset in StudioWallpaperPreset.presets) {
        expect(preset.title.isNotEmpty, isTrue);
        expect(preset.assetPath.startsWith('assets/images/wallpapers/'), isTrue);
        expect(preset.primaryColor, isNotNull);
        expect(preset.secondaryColor, isNotNull);
        expect(preset.tertiaryColor, isNotNull);
      }
    });
  });

  group('ThemeController Wallpaper State & Persistence Tests', () {
    test('ThemeController setWallpaperPreset updates wallpaper and synchronizes studio palette', () async {
      final container = ProviderContainer();
      final controller = container.read(themeControllerProvider.notifier);

      final warmTubePreset = StudioWallpaperPreset.presets.firstWhere(
        (p) => p.id == 'warm_tube_analog',
      );

      await controller.setWallpaperPreset(warmTubePreset);

      final state = container.read(themeControllerProvider);
      expect(state.wallpaperSettings.enabled, true);
      expect(state.wallpaperSettings.imagePath, warmTubePreset.assetPath);
      expect(state.wallpaperSettings.isAsset, true);
      expect(state.wallpaperSettings.extractedPrimary, isNotNull);
      expect(state.wallpaperSettings.extractedSecondary, isNotNull);
      expect(state.wallpaperSettings.extractedTertiary, isNotNull);
      expect(state.currentPalette.id, 'custom_wallpaper');
      expect(state.currentPalette.name, contains('Warm Tube Analog'));
    });

    test('ThemeController modifies wallpaper dim and clamps correctly', () {
      final container = ProviderContainer();
      final controller = container.read(themeControllerProvider.notifier);

      controller.setWallpaperDim(0.75);
      expect(container.read(themeControllerProvider).wallpaperSettings.dimOpacity, 0.75);

      controller.setWallpaperDim(1.5); // Should clamp to max 0.85
      expect(container.read(themeControllerProvider).wallpaperSettings.dimOpacity, 0.85);

      controller.setWallpaperDim(-0.5); // Should clamp to min 0.0
      expect(container.read(themeControllerProvider).wallpaperSettings.dimOpacity, 0.0);
    });

    test('ThemeController modifies wallpaper blur and clamps correctly', () {
      final container = ProviderContainer();
      final controller = container.read(themeControllerProvider.notifier);

      controller.setWallpaperBlur(28.0);
      expect(container.read(themeControllerProvider).wallpaperSettings.blurRadius, 28.0);

      controller.setWallpaperBlur(100.0); // Should clamp to max 40.0
      expect(container.read(themeControllerProvider).wallpaperSettings.blurRadius, 40.0);

      controller.setWallpaperBlur(-10.0); // Should clamp to min 0.0
      expect(container.read(themeControllerProvider).wallpaperSettings.blurRadius, 0.0);
    });

    test('ThemeController toggleWallpaperEnabled and setWallpaperScope', () {
      final container = ProviderContainer();
      final controller = container.read(themeControllerProvider.notifier);

      controller.toggleWallpaperEnabled(true);
      expect(container.read(themeControllerProvider).wallpaperSettings.enabled, true);

      controller.setWallpaperScope(WallpaperScope.dashboardAndPlayer);
      expect(
        container.read(themeControllerProvider).wallpaperSettings.scope,
        WallpaperScope.dashboardAndPlayer,
      );
    });

    test('ThemeController removeWallpaper resets settings and falls back safely', () {
      final container = ProviderContainer();
      final controller = container.read(themeControllerProvider.notifier);

      controller.toggleWallpaperEnabled(true);
      controller.removeWallpaper();

      final state = container.read(themeControllerProvider);
      expect(state.wallpaperSettings.enabled, false);
      expect(state.wallpaperSettings.imagePath, isNull);
      expect(state.wallpaperSettings.extractedPrimary, isNull);
    });
  });

  group('StudioWallpaperBackdrop Widget Tests', () {
    testWidgets('Renders child directly when wallpaper is disabled', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: StudioWallpaperBackdrop(
              child: const Scaffold(
                body: Center(child: Text('Studio Content')),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Studio Content'), findsOneWidget);
    });

    testWidgets('AppThemeBuilder respects isWallpaperActive parameter', (tester) async {
      final opaqueTheme = AppThemeBuilder.buildTheme(
        AppPalette.namidaCyan,
        isDark: true,
        isWallpaperActive: false,
      );
      expect(opaqueTheme.scaffoldBackgroundColor, isNot(Colors.transparent));

      final transparentTheme = AppThemeBuilder.buildTheme(
        AppPalette.namidaCyan,
        isDark: true,
        isWallpaperActive: true,
      );
      expect(transparentTheme.scaffoldBackgroundColor, Colors.transparent);
    });
  });

  group('ThemingSettingsScreen Wallpaper Section Widget Tests', () {
    testWidgets('Displays Custom Studio Wallpaper, 6 presets, and action controls', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const ThemingSettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('CUSTOM STUDIO WALLPAPER & BACKDROP'), findsOneWidget);
      expect(find.text('STUDIO PRESETS (6 PRELOADED)'), findsOneWidget);
      expect(find.text('Obsidian Soundwaves'), findsOneWidget);
      expect(find.text('Warm Tube Analog'), findsOneWidget);
      expect(find.text('Dark Tech Studio'), findsOneWidget);
      expect(find.text('CUSTOM IMAGE FROM DEVICE'), findsOneWidget);
    });

    testWidgets('Tapping preset applies wallpaper and activates preset theme', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: const ThemingSettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final obsidianPresetFinder = find.text('Obsidian Soundwaves');
      expect(obsidianPresetFinder, findsOneWidget);

      await tester.tap(obsidianPresetFinder);
      await tester.pumpAndSettle();

      final state = container.read(themeControllerProvider);
      expect(state.wallpaperSettings.enabled, true);
      expect(state.wallpaperSettings.imagePath, 'assets/images/wallpapers/obsidian_soundwaves.jpg');
      expect(state.currentPalette.id, 'custom_wallpaper');
    });
  });
}
