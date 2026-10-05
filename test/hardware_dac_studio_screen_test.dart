import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:baydev_hifi/app/theme/theme_mode_controller.dart';
import 'package:baydev_hifi/features/hardware_dac/data/transports/mock_dac_transport.dart';
import 'package:baydev_hifi/features/hardware_dac/presentation/controllers/dac_bridge_controller.dart';
import 'package:baydev_hifi/features/hardware_dac/presentation/screens/hardware_dac_studio_screen.dart';
import 'package:baydev_hifi/features/hardware_dac/presentation/widgets/dac_action_toolbar.dart';
import 'package:baydev_hifi/features/hardware_dac/presentation/widgets/dac_band_slider_tile.dart';
import 'package:baydev_hifi/features/hardware_dac/presentation/widgets/dac_hero_status_card.dart';
import 'package:baydev_hifi/features/hardware_dac/presentation/widgets/hardware_curve_visualizer.dart';

void main() {
  group('HardwareDacStudioScreen Widget Tests', () {
    testWidgets('Renders Hero Card, Curve Visualizer, Sliders and Action Toolbar', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dacTransportProvider.overrideWithValue(MockDacTransport()),
          ],
          child: MaterialApp(
            theme: AppThemeBuilder.buildTheme(AppPalette.namidaCyan, isDark: true),
            home: const HardwareDacStudioScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // 1. Verify App Bar
      expect(find.text('Hardware DAC Studio'), findsOneWidget);

      // 2. Verify Hero Status Card
      expect(find.byType(DacHeroStatusCard), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(DacHeroStatusCard),
          matching: find.textContaining('Kiwi Ears AD1'),
        ),
        findsOneWidget,
      );

      // 3. Verify Curve Visualizer
      expect(find.byType(HardwareCurveVisualizer), findsOneWidget);

      // 4. Verify Action Toolbar
      expect(find.byType(DacActionToolbar), findsOneWidget);
      expect(find.text('Burn to Flash'), findsOneWidget);
      expect(find.text('AutoEQ Import'), findsOneWidget);

      // 5. Verify Master Preamp Global Gain Card
      expect(find.text('Master Pre-Amp Gain'), findsOneWidget);

      // 6. Verify 5 Band Slider Tiles
      expect(find.byType(DacBandSliderTile), findsNWidgets(5));
    });

    testWidgets('Toggles Hardware EQ switch on Hero Card', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dacTransportProvider.overrideWithValue(MockDacTransport()),
          ],
          child: MaterialApp(
            theme: AppThemeBuilder.buildTheme(AppPalette.namidaCyan, isDark: true),
            home: const HardwareDacStudioScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find M3ESwitch
      final switchFinder = find.byType(M3ESwitch);
      expect(switchFinder, findsOneWidget);

      // Tap switch
      await tester.tap(switchFinder);
      await tester.pumpAndSettle();

      expect(find.text('Hardware EQ Bypassed'), findsOneWidget);
    });

    testWidgets('Taps Burn to Flash button and shows status message', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            dacTransportProvider.overrideWithValue(MockDacTransport()),
          ],
          child: MaterialApp(
            theme: AppThemeBuilder.buildTheme(AppPalette.namidaCyan, isDark: true),
            home: const HardwareDacStudioScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final burnButtonFinder = find.text('Burn to Flash');
      expect(burnButtonFinder, findsOneWidget);

      await tester.tap(burnButtonFinder, warnIfMissed: false);
      await tester.pumpAndSettle();

      expect(find.textContaining('Flashing successful'), findsOneWidget);
    });
  });
}
