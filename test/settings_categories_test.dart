import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:baydev_hifi/features/settings/presentation/settings_screen.dart';
import 'package:baydev_hifi/features/settings/presentation/sub_screens/theming_settings_screen.dart';
import 'package:baydev_hifi/features/settings/presentation/sub_screens/visualizer_settings_screen.dart';
import 'package:baydev_hifi/features/settings/presentation/sub_screens/gestures_settings_screen.dart';
import 'package:baydev_hifi/features/settings/presentation/sub_screens/docking_settings_screen.dart';
import 'package:baydev_hifi/features/settings/presentation/sub_screens/audio_hardware_settings_screen.dart';
import 'package:baydev_hifi/features/settings/presentation/sub_screens/library_scanner_settings_screen.dart';

void main() {
  testWidgets('SettingsScreen displays category cards and navigates to sub-screens', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SettingsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify Main Category Hub renders
    expect(find.text('SETTINGS & PREFERENCES'), findsOneWidget);
    expect(find.text('STUDIO SYSTEM PROFILE'), findsOneWidget);
    expect(find.text('THEMING & COLOR PALETTES'), findsOneWidget);

    // 2. Test Navigating to Theming Sub-screen
    await tester.tap(find.text('THEMING & COLOR PALETTES'));
    await tester.pumpAndSettle();

    expect(find.byType(ThemingSettingsScreen), findsOneWidget);
    expect(find.text('STUDIO COLOR PALETTES'), findsOneWidget);

    // Navigate back to Hub
    await tester.tap(find.byType(IconButton).first);
    await tester.pumpAndSettle();

    // 3. Test Navigating to Visualizer Sub-screen
    await tester.tap(find.text('VISUALIZER & DISPLAY').first);
    await tester.pumpAndSettle();

    expect(find.byType(VisualizerSettingsScreen), findsOneWidget);
    expect(find.text('ALBUM ART & COVER STYLE'), findsOneWidget);
    expect(find.text('RTA SPECTRUM VISUALIZER'), findsOneWidget);

    // Navigate back
    await tester.tap(find.byType(IconButton).first);
    await tester.pumpAndSettle();

    // 4. Test Navigating to Gestures Sub-screen
    await tester.tap(find.text('GESTURES & TRACK TILES'));
    await tester.pumpAndSettle();

    expect(find.byType(GesturesSettingsScreen), findsOneWidget);
    expect(find.text('NOW PLAYING ARTWORK GESTURES'), findsOneWidget);

    // Navigate back
    await tester.tap(find.byType(IconButton).first);
    await tester.pumpAndSettle();

    // 5. Test Navigating to Docking Sub-screen
    await tester.tap(find.text('STUDIO WORKSTATION & CAR DOCK'));
    await tester.pumpAndSettle();

    expect(find.byType(DockingSettingsScreen), findsOneWidget);
    expect(find.text('LAUNCH STUDIO DOCKING MODE'), findsOneWidget);

    // Navigate back
    await tester.tap(find.byType(IconButton).first);
    await tester.pumpAndSettle();

    // 6. Test Navigating to Audio Hardware Sub-screen
    await tester.tap(find.text('AUDIO HARDWARE & DAC ENGINE'));
    await tester.pumpAndSettle();

    expect(find.byType(AudioHardwareSettingsScreen), findsOneWidget);
    expect(find.text('Output Audio Device'), findsOneWidget);

    // Navigate back
    await tester.tap(find.byType(IconButton).first);
    await tester.pumpAndSettle();

    // 7. Test Navigating to Library Scanner Sub-screen
    await tester.tap(find.text('LIBRARY SCANNER & SLEEP TIMER'));
    await tester.pumpAndSettle();

    expect(find.byType(LibraryScannerSettingsScreen), findsOneWidget);
    expect(find.text('LIBRARY SCANNER RULES'), findsOneWidget);
  });
}
