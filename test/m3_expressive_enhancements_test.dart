import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:baydev_hifi/app/theme/theme_mode_controller.dart';
import 'package:baydev_hifi/features/dsp_rack/presentation/dsp_rack_screen.dart';
import 'package:baydev_hifi/features/dsp_rack/presentation/widgets/rack_unit_card.dart';
import 'package:baydev_hifi/features/library/presentation/unified_library_screen.dart';
import 'package:baydev_hifi/features/player/presentation/now_playing_screen.dart';
import 'package:baydev_hifi/features/player/presentation/widgets/namida_expandable_miniplayer.dart';

void main() {
  group('Material 3 Expressive Studio Enhancements Tests', () {
    testWidgets('DSP Rack collapsible units and reset confirmation dialog', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: DspRackScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify RackUnitCard is rendered
      expect(find.byType(RackUnitCard), findsWidgets);

      // Verify Reset to Flat Reference button exists in AppBar actions
      final resetBtn = find.byTooltip('Reset to Flat Reference');
      expect(resetBtn, findsOneWidget);

      // Tap Reset button to open confirmation modal
      await tester.tap(resetBtn);
      await tester.pumpAndSettle();

      // Verify confirmation dialog appeared
      expect(find.text('RESET DSP RACK'), findsOneWidget);
      expect(find.text('CANCEL'), findsOneWidget);
      expect(find.text('RESET ALL'), findsOneWidget);

      // Tap CANCEL
      await tester.tap(find.text('CANCEL'));
      await tester.pumpAndSettle();
      expect(find.text('RESET DSP RACK'), findsNothing);
    });

    testWidgets('Category FAB is aligned with miniplayer on Library tab and hidden on other tabs', (tester) async {
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // 1. Render on Library tab (isLibraryTab: true)
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  UnifiedLibraryScreen(),
                  NamidaExpandableMiniPlayer(
                    collapsedBottomOffset: 78.0,
                    isLibraryTab: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Category FAB should be visible on Library tab
      final triggerPill = find.byTooltip('Switch Library Category');
      expect(triggerPill, findsOneWidget);

      // Tap the FAB to expand dock
      await tester.tap(triggerPill);
      await tester.pumpAndSettle();

      // Options should be visible in popup
      expect(find.text('Albums'), findsOneWidget);
      expect(find.text('Artists'), findsOneWidget);
      expect(find.text('Genres'), findsOneWidget);
      expect(find.text('Folders'), findsOneWidget);
      expect(find.text('Playlists'), findsOneWidget);

      // Tap 'Albums' option
      await tester.tap(find.text('Albums'));
      await tester.pumpAndSettle();

      // Popup should be dismissed
      expect(find.text('Folders'), findsNothing);

      // 2. Render on other tab (isLibraryTab: false)
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Stack(
                children: [
                  NamidaExpandableMiniPlayer(
                    collapsedBottomOffset: 78.0,
                    isLibraryTab: false,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Category FAB should NOT be visible when not on Library tab
      expect(find.byTooltip('Switch Library Category'), findsNothing);
    });

    test('ThemeController supports curated Pastel Studio Palettes', () {
      final container = ProviderContainer();
      final controller = container.read(themeControllerProvider.notifier);

      // Verify pastel palettes exist in allPresets
      final pastelLavender = AppPalette.allPresets.firstWhere((p) => p.id == 'pastel_lavender');
      final pastelSage = AppPalette.allPresets.firstWhere((p) => p.id == 'pastel_sage');
      final pastelSky = AppPalette.allPresets.firstWhere((p) => p.id == 'pastel_sky');

      expect(pastelLavender.name, 'Pastel Lavender');
      expect(pastelSage.name, 'Pastel Sage Mint');
      expect(pastelSky.name, 'Pastel Powder Sky');

      // Set palette
      controller.setPalette(pastelLavender);
      expect(container.read(themeControllerProvider).currentPalette.id, 'pastel_lavender');
      expect(container.read(themeControllerProvider).currentPalette.primary, const Color(0xFFB8A9E8));
    });

    testWidgets('NowPlayingScreen renders Material 3 Expressive squircle playback controls', (tester) async {
      tester.view.physicalSize = const Size(400, 850);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: NowPlayingScreen(
              onOpenProQStudio: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Check tooltips for playback controls
      expect(find.byTooltip('Previous Track'), findsOneWidget);
      expect(find.byTooltip('Next Track'), findsOneWidget);
      expect(find.byTooltip('Shuffle Playback'), findsOneWidget);
    });
  });
}
