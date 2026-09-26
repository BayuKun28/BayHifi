import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:baydev_hifi/features/player/presentation/studio_desk_docking_screen.dart';

void main() {
  testWidgets('StudioDeskDockingScreen renders without errors in portrait and landscape', (WidgetTester tester) async {
    // Test typical phone portrait
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: StudioDeskDockingScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('EXIT DOCK'), findsOneWidget);

    // Toggle Visualizer mode (VU Meters to Spectrum)
    final visualizerToggle = find.byWidgetPredicate(
      (w) => w is HugeIcon && (w.icon == HugeIcons.strokeRoundedSlidersVertical || w.icon == HugeIcons.strokeRoundedAudioWaveform),
    );
    if (visualizerToggle.evaluate().isNotEmpty) {
      await tester.tap(visualizerToggle.first);
      await tester.pumpAndSettle();
    }

    // Tap DSP Preset (e.g. Warm Tube or Pure)
    final presetBtn = find.text('Audiophile Pure');
    if (presetBtn.evaluate().isNotEmpty) {
      await tester.tap(presetBtn);
      await tester.pumpAndSettle();
    }

    // Test landscape
    tester.view.physicalSize = const Size(844, 390);
    await tester.pumpAndSettle();
    expect(find.text('EXIT DOCK'), findsOneWidget);

    // Test narrow phone portrait
    tester.view.physicalSize = const Size(360, 740);
    await tester.pumpAndSettle();
    expect(find.text('EXIT DOCK'), findsOneWidget);
  });
}
