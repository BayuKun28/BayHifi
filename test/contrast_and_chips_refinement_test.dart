import 'package:baydev_hifi/app/theme/theme_mode_controller.dart';
import 'package:baydev_hifi/features/library/presentation/widgets/create_smart_playlist_dialog.dart';
import 'package:baydev_hifi/features/youtube_music/presentation/controllers/youtube_music_controller.dart';
import 'package:baydev_hifi/features/youtube_music/presentation/youtube_discovery_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Studio Contrast & Harmonizer Tests', () {
    test('1. StudioColorHarmonizer guarantees WCAG AA contrast in Dark Mode for dark/pitch black colors', () {
      const black = Color(0xFF000000);
      final harmonizedBlack = StudioColorHarmonizer.harmonizeAccent(black, isDark: true);
      expect(harmonizedBlack, equals(const Color(0xFF94A3B8)));
      expect(harmonizedBlack.computeLuminance(), greaterThan(0.25));

      const deepNavy = Color(0xFF0A192F);
      final harmonizedNavy = StudioColorHarmonizer.harmonizeAccent(deepNavy, isDark: true);
      expect(harmonizedNavy.computeLuminance(), greaterThan(0.18));
      final hslNavy = HSLColor.fromColor(harmonizedNavy);
      expect(hslNavy.lightness, greaterThanOrEqualTo(0.58));
    });

    test('2. StudioColorHarmonizer prevents washed-out accents in Light Mode', () {
      const blindingWhite = Color(0xFFFFFFFF);
      final harmonizedWhite = StudioColorHarmonizer.harmonizeAccent(blindingWhite, isDark: false);
      expect(harmonizedWhite, equals(const Color(0xFF1E293B)));

      const paleYellow = Color(0xFFFFFF88);
      final harmonizedYellow = StudioColorHarmonizer.harmonizeAccent(paleYellow, isDark: false);
      final hslYellow = HSLColor.fromColor(harmonizedYellow);
      expect(hslYellow.lightness, lessThanOrEqualTo(0.40));
      expect(harmonizedYellow.computeLuminance(), lessThan(0.45));
    });

    test('3. StudioColorHarmonizer lifts low-contrast accents in Dark Mode for readability', () {
      const balancedCyan = Color(0xFF06B6D4);
      final harmonizedDark = StudioColorHarmonizer.harmonizeAccent(balancedCyan, isDark: true);
      final hslDark = HSLColor.fromColor(harmonizedDark);
      expect(hslDark.lightness, greaterThanOrEqualTo(0.60));
      expect(harmonizedDark.computeLuminance(), greaterThan(0.40));

      final harmonizedLight = StudioColorHarmonizer.harmonizeAccent(balancedCyan, isDark: false);
      expect(harmonizedLight.computeLuminance(), lessThan(0.40));
    });

    test('4. ThemeModeController re-harmonizes dynamic palette when switching theme modes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(themeControllerProvider.notifier);

      // Enable dynamic album art
      controller.toggleDynamicAlbumArt(true);

      // Set dynamic album art with high lightness color
      const rawBrightColor = Color(0xFFE0E7FF); // very pale lavender
      controller.setDynamicAlbumArt(const Color(0xFF1E1B4B), rawBrightColor);

      var state = container.read(themeControllerProvider);
      expect(state.currentPalette.isDynamic, isTrue);

      // Switch to Light Mode
      controller.setThemeMode(AppThemeMode.light);
      state = container.read(themeControllerProvider);
      expect(state.themeMode, equals(AppThemeMode.light));
      // In light mode, primary should be darkened for contrast
      expect(state.currentPalette.primary.computeLuminance(), lessThan(0.40));

      // Switch back to Dark Mode
      controller.setThemeMode(AppThemeMode.dark);
      state = container.read(themeControllerProvider);
      expect(state.themeMode, equals(AppThemeMode.dark));
      // In dark mode, primary should be lifted for contrast
      final hsl = HSLColor.fromColor(state.currentPalette.primary);
      expect(hsl.lightness, greaterThanOrEqualTo(0.55));
    });
  });

  group('Chip Checkmark Removal Widget Tests', () {
    testWidgets('5. YouTubeDiscoveryScreen chips render without checkmarks', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            youtubeMusicControllerProvider.overrideWith(
              (ref) => _MockYouTubeMusicController(
                ref,
                const YouTubeMusicState(trendingTracks: []),
              ),
            ),
          ],
          child: const MaterialApp(
            home: YouTubeDiscoveryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip)).toList();
      expect(chips, isNotEmpty);
      for (final chip in chips) {
        expect(chip.showCheckmark, isFalse);
      }
    });

    testWidgets('6. CreateSmartPlaylistDialog match mode chips have showCheckmark set to false', (tester) async {
      tester.view.physicalSize = const Size(600, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: CreateSmartPlaylistDialog(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final chips = tester.widgetList<ChoiceChip>(find.byType(ChoiceChip)).toList();
      expect(chips.length, greaterThanOrEqualTo(2));
      for (final chip in chips) {
        expect(chip.showCheckmark, isFalse);
      }
    });
  });
}

class _MockYouTubeMusicController extends YouTubeMusicController {
  _MockYouTubeMusicController(super.ref, [super.initialState]);

  @override
  void onQueryChanged(String newQuery) {}

  @override
  Future<void> fetchTrending({bool force = false}) async {}
}
