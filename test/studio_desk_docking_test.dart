import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:baydev_hifi/features/settings/presentation/settings_screen.dart';
import 'package:baydev_hifi/features/settings/presentation/sub_screens/docking_settings_screen.dart';

void main() {
  testWidgets('SettingsScreen has Studio Workstation category and navigates to launch button', (WidgetTester tester) async {
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

    // Verify Settings renders the Studio Workstation & Car Dock category
    expect(find.text('STUDIO WORKSTATION & CAR DOCK'), findsOneWidget);

    // Tap to open DockingSettingsScreen
    await tester.tap(find.text('STUDIO WORKSTATION & CAR DOCK'));
    await tester.pumpAndSettle();

    expect(find.byType(DockingSettingsScreen), findsOneWidget);
    expect(find.text('LAUNCH STUDIO DOCKING MODE'), findsOneWidget);
  });
}
