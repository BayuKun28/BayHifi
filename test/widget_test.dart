import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:baydev_hifi/app/app.dart';

void main() {
  testWidgets('Baydev HiFi App Namida Architecture smoke test', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(
        child: BaydevHiFiApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify 5 Namida navigation tabs exist
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('DSP Rack'), findsWidgets);
    expect(find.text('Library'), findsWidgets);
    expect(find.text('Playlists'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);

    // Verify Dashboard header & Dynamic Studio Mixes Carousel render
    expect(find.text('BAYDEV HIFI STUDIO'), findsOneWidget);
    expect(find.text('DYNAMIC STUDIO MIXES'), findsOneWidget);
    expect(find.text('Add Music to Generate Mixes'), findsOneWidget);
  });

  testWidgets('Baydev HiFi App NavigationRail renders app logo in leading on tablet/desktop', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      const ProviderScope(
        child: BaydevHiFiApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify NavigationRail exists
    expect(find.byType(NavigationRail), findsOneWidget);

    // Verify app logo Image asset is rendered in NavigationRail leading
    final imageFinders = find.byType(Image);
    expect(imageFinders, findsWidgets);
  });
}

