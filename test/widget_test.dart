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
    await tester.pump();

    // Verify 4 Namida navigation tabs exist (without dedicated player tab)
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('DSP Rack'), findsWidgets);
    expect(find.text('Library'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);

    // Verify Dashboard header & Pro-Q card render
    expect(find.text('BAYDEV HIFI STUDIO'), findsOneWidget);
    expect(find.text('PRO-Q STUDIO'), findsOneWidget);
  });
}
