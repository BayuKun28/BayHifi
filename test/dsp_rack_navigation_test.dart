import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:baydev_hifi/features/dsp_rack/presentation/dsp_rack_screen.dart';

void main() {
  testWidgets('DspRackScreen contains Pro-Q Studio launcher banner and Pre-Amp unit', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DspRackScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify Header
    expect(find.text('MASTERING DSP RACK'), findsOneWidget);

    // 2. Verify Pro-Q Studio Launcher Banner at top of DSP Rack
    expect(find.text('PRO-Q STUDIO EQ'), findsOneWidget);
    expect(find.text('10-Band Biquad Parametric Equalizer'), findsOneWidget);
    expect(find.text('OPEN'), findsOneWidget);

    // 3. Verify Pre-Amp Gain Stage exists inside DSP Rack
    expect(find.text('PRE-AMP GAIN STAGE'), findsOneWidget);
  });
}
