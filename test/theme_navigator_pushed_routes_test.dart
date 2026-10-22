import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:baydev_hifi/app/theme/theme_mode_controller.dart';
import 'package:baydev_hifi/features/settings/presentation/sub_screens/theming_settings_screen.dart';

void main() {
  group('Theme Navigator & Pushed Routes Color Unification Tests', () {
    testWidgets('Pushed route inherits active palette in M3ESlider, M3ESwitch and M3EButton', (tester) async {
      final palette = AppPalette.emeraldHiFi;
      final themeData = AppThemeBuilder.buildTheme(palette, isDark: true);
      final m3eThemeData = AppThemeBuilder.buildM3ETheme(palette, isDark: true);

      late Color capturedM3EPrimary;
      late Color capturedActiveTrack;
      late Color capturedInactiveTrack;
      late Color capturedThumb;

      await tester.pumpWidget(
        MaterialApp(
          theme: themeData,
          darkTheme: themeData,
          themeMode: ThemeMode.dark,
          builder: (context, child) {
            return M3ETheme(
              data: m3eThemeData,
              child: child ?? const SizedBox.shrink(),
            );
          },
          home: Builder(
            builder: (homeContext) {
              return Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    Navigator.of(homeContext).push(
                      MaterialPageRoute(
                        builder: (pushedContext) {
                          final m3e = M3ETheme.of(pushedContext);
                          final colors = m3e.sliderTheme.colors(m3e.colorScheme, enabled: true);
                          capturedM3EPrimary = m3e.colorScheme.primary;
                          capturedActiveTrack = colors.activeTrack;
                          capturedInactiveTrack = colors.inactiveTrack;
                          capturedThumb = colors.thumb;

                          return Scaffold(
                            body: Column(
                              children: [
                                M3ESlider(value: 0.5, onChanged: (_) {}),
                                M3ESwitch(value: true, onChanged: (_) {}),
                                M3EButton.filled(
                                  onPressed: () {},
                                  child: const Text('Action'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    );
                  },
                  child: const Text('Open Settings'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open Settings'));
      await tester.pumpAndSettle();

      // Verify M3E colors match Emerald HiFi, NOT Material purple/lavender
      expect(capturedM3EPrimary, equals(palette.primary));
      expect(capturedActiveTrack, equals(palette.primary));
      expect(capturedThumb, equals(palette.primary));
      // Inactive track should be dark studio container, NOT lavender (0xFFE8DEF8)
      expect(capturedInactiveTrack, isNot(equals(const Color(0xFFE8DEF8))));
      expect(capturedInactiveTrack, equals(m3eThemeData.colorScheme.secondaryContainer));

      // Verify widgets rendered in pushed route
      expect(find.byType(M3ESlider), findsOneWidget);
      expect(find.byType(M3ESwitch), findsOneWidget);
      expect(find.byType(M3EButton), findsOneWidget);
    });

    testWidgets('AppThemeBuilder configures switchTheme and button themes correctly', (tester) async {
      final palette = AppPalette.emeraldHiFi;
      final theme = AppThemeBuilder.buildTheme(palette, isDark: true);

      // Verify switchTheme
      expect(theme.switchTheme.trackColor, isNotNull);
      final activeSwitchTrack = theme.switchTheme.trackColor!.resolve({WidgetState.selected});
      expect(activeSwitchTrack, equals(palette.primary));

      // Verify sliderTheme
      expect(theme.sliderTheme.activeTrackColor, equals(palette.primary));
      expect(theme.sliderTheme.thumbColor, equals(palette.primary));

      // Verify button themes
      expect(theme.filledButtonTheme.style?.backgroundColor?.resolve({}), equals(palette.primary));
      expect(theme.textButtonTheme.style?.foregroundColor?.resolve({}), equals(palette.primary));
    });

    testWidgets('ThemingSettingsScreen renders live preview slider without throwing and reflects theme state', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: Consumer(
            builder: (context, ref, _) {
              final state = ref.watch(themeControllerProvider);
              final theme = AppThemeBuilder.buildTheme(state.currentPalette, isDark: true);
              final m3eTheme = AppThemeBuilder.buildM3ETheme(state.currentPalette, isDark: true);

              return MaterialApp(
                theme: theme,
                darkTheme: theme,
                themeMode: ThemeMode.dark,
                builder: (context, child) => M3ETheme(
                  data: m3eTheme,
                  child: child ?? const SizedBox.shrink(),
                ),
                home: const ThemingSettingsScreen(),
              );
            },
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify section header & live preview card
      expect(find.text('THEMING & COLOR PALETTES'), findsOneWidget);
      expect(find.text('ACTIVE STUDIO THEME PREVIEW'), findsOneWidget);
      expect(find.text('Studio Reference Playback'), findsOneWidget);

      // Verify M3ESlider rendered inside preview
      expect(find.byType(M3ESlider), findsWidgets);
    });
  });
}
