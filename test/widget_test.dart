import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:baydev_hifi/app/app.dart';
import 'package:baydev_hifi/core/database/local_persistence_service.dart';
import 'package:baydev_hifi/core/desktop/desktop_studio_sidebar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bayhifi_widget_test');
    await LocalPersistenceService.instance.init(customPath: '${tempDir.path}/test_storage.json');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  testWidgets('Baydev HiFi App Namida Architecture smoke test', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(400, 850));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BaydevHiFiApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify Namida navigation tabs exist
    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('DSP Rack'), findsWidgets);
    expect(find.text('Library'), findsWidgets);
    expect(find.text('Playlists'), findsWidgets);
    expect(find.text('Settings'), findsWidgets);

    // Verify Dashboard header & Dynamic Studio Mixes Carousel render
    expect(find.text('BAYDEV HIFI STUDIO'), findsOneWidget);
    expect(find.text('DYNAMIC STUDIO MIXES'), findsOneWidget);
    expect(find.text('Add Music to Generate Mixes'), findsOneWidget);

    // Drain timers
    await tester.pump(const Duration(seconds: 5));
  });

  testWidgets('Baydev HiFi App DesktopStudioSidebar renders app logo in leading on tablet/desktop', (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 768));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final container = ProviderContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const BaydevHiFiApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    // Verify DesktopStudioSidebar exists
    expect(find.byType(DesktopStudioSidebar), findsOneWidget);

    // Verify app logo Image asset is rendered in sidebar
    final imageFinders = find.byType(Image);
    expect(imageFinders, findsWidgets);

    // Drain timers
    await tester.pump(const Duration(seconds: 5));
  });
}
