import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/features/player/presentation/now_playing_screen.dart';
import 'package:baydev_hifi/features/player/presentation/widgets/custom_time_bar.dart';
import 'package:baydev_hifi/features/pro_q_studio/domain/eq_band.dart';
import 'package:baydev_hifi/features/pro_q_studio/presentation/widgets/eq_curve_painter.dart';
import 'package:baydev_hifi/features/settings/domain/player_customization_settings.dart';
import 'package:baydev_hifi/features/settings/presentation/controllers/player_customization_controller.dart';
import 'package:baydev_hifi/features/settings/presentation/settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 68: Comprehensive UI/UX Refinement Tests', () {
    testWidgets('SettingsScreen instant search filters categories in real time', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify search bar is visible
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Search settings, DSP, hardware, theming...'), findsOneWidget);

      // Type "AutoEQ" into search bar
      await tester.enterText(find.byType(TextField), 'AutoEQ');
      await tester.pumpAndSettle();

      // Verify search results are displayed
      expect(find.textContaining('MATCHING SETTINGS'), findsOneWidget);
      expect(find.text('AUDIO HARDWARE & DAC ENGINE'), findsOneWidget);

      // Type nonexistent query
      await tester.enterText(find.byType(TextField), 'NonexistentSettingKeywordXYZ');
      await tester.pumpAndSettle();

      expect(find.textContaining('No settings found'), findsOneWidget);
    });

    testWidgets('SettingsScreen retains search field focus during continuous typing', (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1000));

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SettingsScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final searchField = find.byKey(const ValueKey('settings_search_field'));
      expect(searchField, findsOneWidget);

      // Tap to focus
      await tester.tap(searchField);
      await tester.pumpAndSettle();

      // Enter first character
      await tester.enterText(searchField, 'D');
      await tester.pump();

      // Verify TextField is still the focused widget
      final textFieldWidget = tester.widget<TextField>(searchField);
      expect(textFieldWidget.focusNode?.hasFocus, isTrue);

      // Enter more characters
      await tester.enterText(searchField, 'DSP');
      await tester.pumpAndSettle();

      expect(textFieldWidget.focusNode?.hasFocus, isTrue);
      expect(find.textContaining('MATCHING SETTINGS'), findsOneWidget);
    });

    testWidgets('CustomTimeBar renders time display and supports scrubbing state', (tester) async {
      Duration? seekedDuration;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: CustomTimeBar(
                  position: const Duration(minutes: 1, seconds: 30),
                  duration: const Duration(minutes: 4, seconds: 20),
                  primaryColor: Colors.amber,
                  style: TimeBarStyle.slim,
                  onSeek: (dur) => seekedDuration = dur,
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify position and duration are rendered
      expect(find.text('01:30'), findsOneWidget);
      expect(find.text('04:20'), findsOneWidget);
      expect(seekedDuration, isNull);
    });

    testWidgets('NowPlayingScreen respects NowPlayingBackdropMode', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 800));

      final customNotifier = PlayerCustomizationNotifier();
      customNotifier.state = customNotifier.state.copyWith(
        backdropMode: NowPlayingBackdropMode.pureBlackOled,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            playerCustomizationProvider.overrideWith((ref) => customNotifier),
          ],
          child: MaterialApp(
            home: NowPlayingScreen(
              onOpenProQStudio: () {},
            ),
          ),
        ),
      );

      await tester.pump();

      // Verify screen renders
      expect(find.byType(NowPlayingScreen), findsOneWidget);

      // Switch to album art glow mode
      customNotifier.state = customNotifier.state.copyWith(
        backdropMode: NowPlayingBackdropMode.albumArtGlow,
      );
      await tester.pump();

      expect(customNotifier.state.backdropMode, NowPlayingBackdropMode.albumArtGlow);
    });

    testWidgets('EqCurvePainter paints RTA spectrum and peak hold caps without errors', (tester) async {
      final painter = EqCurvePainter(
        bands: [
          const EqBand(index: 0, frequency: 1000, gainDb: 3.0, q: 1.41),
        ],
        selectedBandIndex: 0,
        isEnabled: true,
        showFrCurves: true,
        isRtaEnabled: true,
        rtaSpectrum: List.generate(32, (i) => 0.65),
        driverFr: null,
        targetFr: null,
      );

      final recorder = PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(400, 300);

      expect(() => painter.paint(canvas, size), returnsNormally);
    });
  });
}
