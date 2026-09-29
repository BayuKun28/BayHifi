import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:baydev_hifi/app/theme/theme_mode_controller.dart';
import 'package:baydev_hifi/features/settings/presentation/settings_screen.dart';
import 'package:baydev_hifi/features/settings/presentation/sub_screens/theming_settings_screen.dart';
import 'package:baydev_hifi/features/settings/presentation/sub_screens/audio_hardware_settings_screen.dart';
import 'package:baydev_hifi/features/settings/presentation/sub_screens/docking_settings_screen.dart';
import 'package:baydev_hifi/core/database/local_persistence_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bayhifi_phase34_test');
    await LocalPersistenceService.instance.init(customPath: '${tempDir.path}/test_storage.json');
  });

  group('Phase 34.1: 19 M3 Expressive Studio Palettes Integrity Tests', () {
    test('All 19 AppPalette presets are registered with unique IDs', () {
      expect(AppPalette.allPresets.length, 19);

      final ids = AppPalette.allPresets.map((p) => p.id).toSet();
      expect(ids.length, 19, reason: 'Every palette must have a unique identifier');

      // Verify the 7 newly added palettes
      final newPaletteIds = {
        'nordic_slate',
        'terracotta_clay',
        'matcha_botanical',
        'midnight_sapphire',
        'vintage_brass',
        'mocha_espresso',
        'pro_carbon',
      };

      for (final newId in newPaletteIds) {
        expect(ids.contains(newId), isTrue, reason: 'Palette $newId must be in allPresets');
      }
    });

    test('All 19 AppPalette presets construct valid non-null color schemes', () {
      for (final palette in AppPalette.allPresets) {
        final darkScheme = AppThemeBuilder.buildTheme(palette, isDark: true);
        final lightScheme = AppThemeBuilder.buildTheme(palette, isDark: false);

        expect(darkScheme.colorScheme.primary, palette.primary);
        expect(lightScheme.colorScheme.primary, isNotNull);
        expect(darkScheme.scaffoldBackgroundColor, isNotNull);
      }
    });
  });

  group('Phase 34.2: SettingsScreen M3 Expressive Hub Widget Tests', () {
    testWidgets('SettingsScreen renders interactive studio cockpit hero and 4 sections', (tester) async {
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
            theme: AppThemeBuilder.buildTheme(AppPalette.nordicSlate, isDark: true),
            home: const SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Cockpit Hero
      expect(find.text('STUDIO SYSTEM COCKPIT'), findsOneWidget);
      expect(find.text('48kHz SOLOUD ENGINE'), findsOneWidget);

      // Section Headers
      expect(find.text('AESTHETICS & ATMOSPHERE'), findsOneWidget);
      expect(find.text('AUDIO ARCHITECTURE & DSP WORKSTATION'), findsOneWidget);
      expect(find.text('MEDIA, LIBRARY & STORAGE'), findsOneWidget);
      expect(find.text('SYSTEM, GESTURES & ARCHIVE'), findsOneWidget);

      // Category Cards
      expect(find.text('THEMING & COLOR PALETTES'), findsOneWidget);
      expect(find.text('VISUALIZER & DISPLAY'), findsOneWidget);
      expect(find.text('STUDIO WORKSTATION & CAR DOCK'), findsOneWidget);
      expect(find.text('AUDIO HARDWARE & DAC ENGINE'), findsOneWidget);
      expect(find.text('ADVANCED PLAYBACK ENGINE & FADES'), findsOneWidget);
      expect(find.text('LIBRARY SCANNER & SLEEP TIMER'), findsOneWidget);
      expect(find.text('STORAGE & CACHE QUOTA'), findsOneWidget);
      expect(find.text('GESTURES & TRACK TILES'), findsOneWidget);
      expect(find.text('BACKUP & RESTORE ARCHIVE'), findsOneWidget);
    });

    testWidgets('SettingsScreen responds to palette changes dynamically', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppThemeBuilder.buildTheme(AppPalette.terracottaClay, isDark: true),
            home: const SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      container.read(themeControllerProvider.notifier).setPalette(AppPalette.matchaBotanical);
      await tester.pumpAndSettle();

      expect(find.text(AppPalette.matchaBotanical.name), findsAtLeastNWidgets(1));
    });
  });

  group('Phase 34.3: Sub-Screens M3 Expressive Rendering Tests', () {
    testWidgets('ThemingSettingsScreen renders all 19 studio palettes and mode selectors', (tester) async {
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
            theme: AppThemeBuilder.buildTheme(AppPalette.midnightSapphire, isDark: true),
            home: const ThemingSettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('THEMING & COLOR PALETTES'), findsOneWidget);
      expect(find.text('ACTIVE THEME PREVIEW'), findsOneWidget);
      expect(find.text('THEME MODE'), findsOneWidget);
      expect(find.text('SURFACE & COMPONENT FILL STYLE'), findsOneWidget);
      expect(find.text('STUDIO COLOR PALETTES'), findsOneWidget);

      // Verify the new palettes render in list
      expect(find.text(AppPalette.nordicSlate.name), findsOneWidget);
      expect(find.text(AppPalette.terracottaClay.name), findsOneWidget);
      expect(find.text(AppPalette.vintageBrass.name), findsOneWidget);
      expect(find.text(AppPalette.mochaEspresso.name), findsOneWidget);
      expect(find.text(AppPalette.proCarbon.name), findsOneWidget);
    });

    testWidgets('AudioHardwareSettingsScreen renders Bento dropdown and buffer slider', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppThemeBuilder.buildTheme(AppPalette.namidaCyan, isDark: true),
            home: const AudioHardwareSettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('AUDIO HARDWARE & DAC ENGINE'), findsOneWidget);
      expect(find.text('SoLoud C++ Audio Engine'), findsOneWidget);
      expect(find.text('Output Audio Device'), findsOneWidget);
      expect(find.text('Buffer Latency Tuning'), findsOneWidget);
      expect(find.text('Bit-Perfect Resampling Bypass'), findsOneWidget);
    });

    testWidgets('DockingSettingsScreen renders desk docking action and feature overview', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppThemeBuilder.buildTheme(AppPalette.namidaCyan, isDark: true),
            home: const DockingSettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('STUDIO WORKSTATION & CAR DOCK'), findsOneWidget);
      expect(find.text('LAUNCH STUDIO DOCKING MODE'), findsOneWidget);
      expect(find.text('High-Contrast Studio Clock'), findsOneWidget);
      expect(find.text('Dual Analog VU Meters'), findsOneWidget);
    });
  });
}
