import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:baydev_hifi/app/app.dart';

void main() {
  testWidgets('Baydev HiFi App Namida Architecture smoke test', (WidgetTester tester) async {
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
}
