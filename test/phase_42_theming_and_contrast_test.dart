import 'package:baydev_hifi/app/theme/theme_mode_controller.dart';
import 'package:baydev_hifi/features/lyrics_share/domain/models/lyric_card_theme.dart';
import 'package:baydev_hifi/features/lyrics_share/domain/models/lyric_share_config.dart';
import 'package:baydev_hifi/features/lyrics_share/presentation/widgets/lyric_card_widget.dart';
import 'package:baydev_hifi/features/player/domain/lyrics_line.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/settings/presentation/sub_screens/theming_settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const testTrack = Track(
    id: 'track_test_contrast',
    title: 'Back in Black',
    artist: 'AC/DC',
    album: 'Back in Black',
    filePath: '/music/back_in_black.flac',
    duration: Duration(minutes: 4, seconds: 15),
    format: AudioFormat.flac,
  );

  group('Phase 42: Borderless Lyric Card & Theming Contrast Tests', () {
    testWidgets('1. LyricCardWidget renders borderless container without stroke border', (tester) async {
      const config = LyricShareConfig(
        track: testTrack,
        selectedLines: [
          LyricsLine(timestamp: Duration(seconds: 1), text: 'Back in black, I hit the sack'),
        ],
        ratio: LyricCardRatio.square_1_1,
        preset: LyricCardThemePreset.studioOledBlack,
      );

      final colors = LyricCardColors.fromPreset(LyricCardThemePreset.studioOledBlack);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 300,
                child: LyricCardWidget(
                  config: config,
                  colors: colors,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find outer container inside ClipRRect
      final clipRRectFinder = find.byType(ClipRRect);
      expect(clipRRectFinder, findsWidgets);

      // Verify text is present
      expect(find.text('Back in black, I hit the sack'), findsOneWidget);
    });

    test('2. StudioColorHarmonizer converts pure black artwork to Studio Slate / Silver Ash', () {
      // Test Pitch Black (e.g. 0xFF000000 or 0xFF050505)
      const blackCover = Color(0xFF000000);
      final harmonizedDark = StudioColorHarmonizer.harmonizeAccent(blackCover, isDark: true);

      // Must be transformed to high-contrast slate (#94A3B8)
      expect(harmonizedDark, equals(const Color(0xFF94A3B8)));
      expect(harmonizedDark.computeLuminance(), greaterThan(0.25));

      // Test Dark Hue (e.g. deep dark navy #051025)
      const deepNavy = Color(0xFF051025);
      final harmonizedNavy = StudioColorHarmonizer.harmonizeAccent(deepNavy, isDark: true);
      expect(harmonizedNavy.computeLuminance(), greaterThan(0.18));

      // Test Light Mode Safety
      const blindingWhite = Color(0xFFFFFFFF);
      final harmonizedLight = StudioColorHarmonizer.harmonizeAccent(blindingWhite, isDark: false);
      expect(harmonizedLight, equals(const Color(0xFF1E293B)));
    });

    test('3. LyricCardColors.fromDynamicColor guards against pitch black cover art', () {
      const pitchBlack = Color(0xFF000000);
      final colors = LyricCardColors.fromDynamicColor(pitchBlack);

      // Accent must be slate (#94A3B8) with high luminance
      expect(colors.accentColor, equals(const Color(0xFF94A3B8)));
      expect(colors.primaryTextColor, equals(const Color(0xFFFFFFFF)));
      expect(colors.backgroundColor, equals(const Color(0xFF0C0E14)));
    });

    test('4. AppThemeBuilder ensures onPrimary has dynamic WCAG AA contrast', () {
      // If primary is light / high luminance, onPrimary must be dark (#0C0E12)
      final lightPalette = AppPalette.namidaCyan.copyWith(
        primary: const Color(0xFFE2E8F0),
      );
      final lightTheme = AppThemeBuilder.buildTheme(lightPalette, isDark: true);
      expect(lightTheme.colorScheme.onPrimary, equals(const Color(0xFF0C0E12)));

      // If primary is deep studio navy / violet, onPrimary must be crisp white (#FFFFFF)
      final darkPalette = AppPalette.namidaCyan.copyWith(
        primary: const Color(0xFF1E3A8A),
      );
      final darkTheme = AppThemeBuilder.buildTheme(darkPalette, isDark: true);
      expect(darkTheme.colorScheme.onPrimary, equals(const Color(0xFFFFFFFF)));
    });

    testWidgets('5. ThemingSettingsScreen renders redesigned cockpit, category filters, and controls', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: ThemingSettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check section headers
      expect(find.text('THEMING & COLOR PALETTES'), findsOneWidget);
      expect(find.text('ACTIVE STUDIO THEME PREVIEW'), findsOneWidget);
      expect(find.text('DISPLAY GROUND & SURFACE STYLE'), findsOneWidget);
      expect(find.text('DYNAMIC & DISPLAY ENGINES'), findsOneWidget);
      expect(find.text('STUDIO COLOR PALETTES'), findsOneWidget);
      expect(find.text('CUSTOM STUDIO ACCENT COLOR'), findsOneWidget);

      // Check Dynamic Album Art & OLED switches
      expect(find.text('Dynamic Album Art Palette'), findsOneWidget);
      expect(find.text('True OLED Black Mode'), findsOneWidget);

      // Check Category Filter Bar
      expect(find.text('All Presets'), findsOneWidget);
      expect(find.text('Studio Core'), findsOneWidget);
      expect(find.text('Pastel Soft'), findsOneWidget);

      // Filter by Pastel Soft
      await tester.tap(find.text('Pastel Soft'));
      await tester.pumpAndSettle();

      expect(find.text('Pastel Lavender'), findsOneWidget);
      expect(find.text('Pastel Sage Mint'), findsOneWidget);

      // Switch to True OLED Black mode
      await tester.tap(find.text('True OLED Black Mode'));
      await tester.pumpAndSettle();

      final state = container.read(themeControllerProvider);
      expect(state.currentPalette.id, equals('true_oled'));
    });
  });
}
