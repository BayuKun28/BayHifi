import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:baydev_hifi/features/dashboard/presentation/dashboard_screen.dart';

void main() {
  testWidgets('DashboardScreen renders clean high-density cards and scroll physics', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: DashboardScreen(
            onNavigateToPlayer: () {},
            onNavigateToLibrary: () {},
            onNavigateToDsp: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Dashboard renders header, audio engine bento, and Studio Showcase Carousel
    expect(find.text('BAYDEV HIFI STUDIO'), findsOneWidget);
    expect(find.text('C++ SOLOUD AUDIO ENGINE'), findsOneWidget);
    expect(find.text('DYNAMIC STUDIO MIXES'), findsOneWidget);
    expect(find.text('Add Music to Generate Mixes'), findsOneWidget);

    // Verify removed redundant cards are not present on Dashboard
    expect(find.text('UNIFIED MUSIC LIBRARY'), findsNothing);
    expect(find.text('STUDIO DESK & CAR DOCKING'), findsNothing);

    // Verify SingleChildScrollView exists and has AlwaysScrollableScrollPhysics
    final scrollFinder = find.byType(SingleChildScrollView).first;
    expect(scrollFinder, findsOneWidget);

    final scrollWidget = tester.widget<SingleChildScrollView>(scrollFinder);
    expect(scrollWidget.physics, isA<AlwaysScrollableScrollPhysics>());

    // Test dragging to scroll down
    await tester.drag(scrollFinder, const Offset(0, -300));
    await tester.pumpAndSettle();

    // Verify bottom statistics card is present in widget tree
    expect(find.text('AUDIOPHILE LISTENING STATS'), findsOneWidget);
  });
}
