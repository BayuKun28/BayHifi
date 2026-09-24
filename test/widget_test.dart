import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:baydev_hifi/app/app.dart';

void main() {
  testWidgets('Baydev HiFi App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: BaydevHiFiApp(),
      ),
    );

    // Verify app title or core elements render
    expect(find.text('BAYDEV HIFI'), findsOneWidget);
    expect(find.text('Player'), findsOneWidget);
    expect(find.text('Pro-Q'), findsOneWidget);
  });
}
