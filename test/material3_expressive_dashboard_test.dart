import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:baydev_hifi/features/dashboard/presentation/dashboard_screen.dart';
import 'package:baydev_hifi/features/dashboard/presentation/widgets/engine_telemetry_bento_card.dart';
import 'package:baydev_hifi/features/dashboard/presentation/widgets/studio_hero_showcase_carousel.dart';
import 'package:baydev_hifi/features/dashboard/presentation/widgets/listening_statistics_card.dart';
import 'package:baydev_hifi/features/dashboard/presentation/widgets/recent_sessions_bento_carousel.dart';
import 'package:baydev_hifi/features/settings/presentation/sub_screens/audio_hardware_settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('DashboardScreen renders semi-minimalist Material 3 Expressive Bento modules and navigates seamlessly', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: DashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Verify Clean Header
    expect(find.text('BAYDEV HIFI STUDIO'), findsOneWidget);
    expect(find.text('Studio Command & Telemetry'), findsNothing);
    expect(find.text('SoLoud Active'), findsOneWidget);

    // 2. Verify Bento 1: Engine Telemetry
    expect(find.byType(EngineTelemetryBentoCard), findsOneWidget);
    expect(find.text('C++ SOLOUD AUDIO ENGINE'), findsOneWidget);
    expect(find.text('BIT-PERFECT DIRECT'), findsOneWidget);

    // 3. Verify Dynamic Studio Mixes Carousel (Directly above Listening Statistics Card)
    expect(find.byType(StudioHeroShowcaseCarousel), findsOneWidget);
    expect(find.text('DYNAMIC STUDIO MIXES'), findsOneWidget);
    expect(find.text('Add Music to Generate Mixes'), findsOneWidget);

    // 4. Verify Bento 2: Listening Statistics Card
    expect(find.byType(ListeningStatisticsCard), findsOneWidget);
    expect(find.text('AUDIOPHILE LISTENING STATS'), findsOneWidget);

    // 5. Verify Bento 3: Recent Sessions Carousel
    expect(find.byType(RecentSessionsBentoCarousel), findsOneWidget);

    // 6. Test Navigation: Tap Engine Telemetry Card to open Audio Hardware Settings
    await tester.tap(find.byType(EngineTelemetryBentoCard));
    await tester.pumpAndSettle();
    expect(find.byType(AudioHardwareSettingsScreen), findsOneWidget);
  });
}
