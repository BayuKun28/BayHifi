import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:baydev_hifi/app/app.dart';
import 'package:baydev_hifi/app/theme/theme_mode_controller.dart';
import 'package:baydev_hifi/core/database/local_persistence_service.dart';
import 'package:baydev_hifi/features/dashboard/presentation/dashboard_screen.dart';
import 'dart:io';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bayhifi_theme_test');
    await LocalPersistenceService.instance.init(customPath: '${tempDir.path}/test_storage.json');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Dark Mode & Theme Palette Propagation Tests', () {
    testWidgets('BaydevHiFiApp boots in true Dark Mode with Simple-As-F Obsidian Emerald palette by default', (tester) async {
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
      await tester.pumpAndSettle();

      final BuildContext dashboardContext = tester.element(find.byType(DashboardScreen));
      final theme = Theme.of(dashboardContext);

      // Verify brightness is Dark
      expect(theme.brightness, Brightness.dark);
      // Verify dark scaffold background (deep studio obsidian forest, NOT white)
      expect(theme.scaffoldBackgroundColor, const Color(0xFF0B110E));
      expect(theme.colorScheme.surface, const Color(0xFF101914));
      expect(theme.colorScheme.surfaceContainer, const Color(0xFF16241C));
      expect(theme.colorScheme.primary, const Color(0xFF2EE672));
    });

    testWidgets('Switching ThemePalette updates card background and primary accent dynamically', (tester) async {
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
      await tester.pumpAndSettle();

      // Change palette to Amber Tube Glow
      container.read(themeControllerProvider.notifier).setPalette(AppPalette.amberTube);
      await tester.pumpAndSettle();

      final BuildContext amberContext = tester.element(find.byType(DashboardScreen));
      final amberTheme = Theme.of(amberContext);

      expect(amberTheme.colorScheme.primary, const Color(0xFFF59E0B));
      expect(amberTheme.colorScheme.surfaceContainer, const Color(0xFF282115));
      expect(amberTheme.scaffoldBackgroundColor, const Color(0xFF141009));

      // Change palette to Emerald HiFi
      container.read(themeControllerProvider.notifier).setPalette(AppPalette.emeraldHiFi);
      await tester.pumpAndSettle();

      final BuildContext emeraldContext = tester.element(find.byType(DashboardScreen));
      final emeraldTheme = Theme.of(emeraldContext);

      expect(emeraldTheme.colorScheme.primary, const Color(0xFF10B981));
      expect(emeraldTheme.colorScheme.surfaceContainer, const Color(0xFF1A2A22));
      expect(emeraldTheme.scaffoldBackgroundColor, const Color(0xFF0C1410));
    });

    testWidgets('Switching between Light and Dark mode toggles container and background colors', (tester) async {
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
      await tester.pumpAndSettle();

      // Switch to Light Mode
      container.read(themeControllerProvider.notifier).setThemeMode(AppThemeMode.light);
      await tester.pumpAndSettle();

      BuildContext lightContext = tester.element(find.byType(DashboardScreen));
      ThemeData lightTheme = Theme.of(lightContext);

      expect(lightTheme.brightness, Brightness.light);
      expect(lightTheme.scaffoldBackgroundColor, const Color(0xFFF1F8F4));
      expect(lightTheme.colorScheme.surfaceContainer, const Color(0xFFE2F5EA));

      // Switch back to Dark Mode
      container.read(themeControllerProvider.notifier).setThemeMode(AppThemeMode.dark);
      await tester.pumpAndSettle();

      BuildContext darkContext = tester.element(find.byType(DashboardScreen));
      ThemeData darkTheme = Theme.of(darkContext);

      expect(darkTheme.brightness, Brightness.dark);
      expect(darkTheme.scaffoldBackgroundColor, const Color(0xFF0B110E));
      expect(darkTheme.colorScheme.surfaceContainer, const Color(0xFF16241C));
    });
  });
}
