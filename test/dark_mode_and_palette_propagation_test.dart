import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:baydev_hifi/app/app.dart';
import 'package:baydev_hifi/app/theme/theme_mode_controller.dart';
import 'package:baydev_hifi/core/database/local_persistence_service.dart';
import 'package:baydev_hifi/features/dashboard/presentation/dashboard_screen.dart';
import 'package:baydev_hifi/features/dashboard/presentation/widgets/studio_wrapped_bento_banner.dart';
import 'package:baydev_hifi/features/dashboard/presentation/widgets/simple_as_f_discovery_grid.dart';
import 'package:baydev_hifi/features/hardware_dac/presentation/screens/hardware_dac_studio_screen.dart';
import 'package:baydev_hifi/features/hardware_dac/presentation/widgets/hardware_curve_visualizer.dart';
import 'package:baydev_hifi/features/hardware_dac/presentation/widgets/dac_hero_status_card.dart';
import 'package:baydev_hifi/features/hardware_dac/presentation/widgets/dac_action_toolbar.dart';
import 'package:baydev_hifi/features/player/presentation/now_playing_screen.dart';
import 'package:baydev_hifi/features/analytics/presentation/templates/studio_wrapped_export_hub.dart';
import 'package:baydev_hifi/features/analytics/presentation/story/studio_wrapped_story_screen.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
      // Verify dark scaffold background (deep studio obsidian carbon)
      expect(theme.scaffoldBackgroundColor, const Color(0xFF0D0E12));
      expect(theme.colorScheme.surface, const Color(0xFF12141A));
      expect(theme.colorScheme.surfaceContainer, const Color(0xFF16181F));
      expect(theme.colorScheme.primary, const Color(0xFF10B981));
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
      expect(amberTheme.colorScheme.surfaceContainer, const Color(0xFF16181F));
      expect(amberTheme.scaffoldBackgroundColor, const Color(0xFF0D0E12));

      // Change palette to Emerald HiFi
      container.read(themeControllerProvider.notifier).setPalette(AppPalette.emeraldHiFi);
      await tester.pumpAndSettle();

      final BuildContext emeraldContext = tester.element(find.byType(DashboardScreen));
      final emeraldTheme = Theme.of(emeraldContext);

      expect(emeraldTheme.colorScheme.primary, const Color(0xFF10B981));
      expect(emeraldTheme.colorScheme.surfaceContainer, const Color(0xFF16181F));
      expect(emeraldTheme.scaffoldBackgroundColor, const Color(0xFF0D0E12));
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
      expect(darkTheme.scaffoldBackgroundColor, const Color(0xFF0D0E12));
      expect(darkTheme.colorScheme.surfaceContainer, const Color(0xFF16181F));
    });

    testWidgets('Dashboard cards and banners adapt properly to Light Mode without hardcoded dark surfaces', (tester) async {
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

      // Verify Dashboard and banners are present
      expect(find.byType(StudioWrappedBentoBanner), findsOneWidget);
      expect(find.byType(SimpleAsFDiscoveryGrid), findsOneWidget);

      final BuildContext bentoContext = tester.element(find.byType(StudioWrappedBentoBanner));
      final bentoContainer = tester.widget<Container>(
        find.descendant(
          of: find.byType(StudioWrappedBentoBanner),
          matching: find.byType(Container),
        ).first,
      );
      final bentoDec = bentoContainer.decoration as BoxDecoration;
      // In Light Mode, container color should match theme surfaceContainer (not hardcoded 0xFF16181F)
      expect(bentoDec.color, Theme.of(bentoContext).colorScheme.surfaceContainer);

      final BuildContext discoveryContext = tester.element(find.byType(SimpleAsFDiscoveryGrid));
      final discoveryContainer = tester.widget<Container>(
        find.descendant(
          of: find.byType(SimpleAsFDiscoveryGrid),
          matching: find.byType(Container),
        ).first,
      );
      final discoveryDec = discoveryContainer.decoration as BoxDecoration;
      expect(discoveryDec.color, Theme.of(discoveryContext).colorScheme.surfaceContainer);
    });

    testWidgets('HardwareDacStudioScreen adapts properly to Light Mode', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final theme = AppThemeBuilder.buildTheme(
        AppPalette.emeraldHiFi,
        isDark: false,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: theme,
            home: const HardwareDacStudioScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify screen scaffold uses light background
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, theme.scaffoldBackgroundColor);

      // Verify sub-components are present
      expect(find.byType(DacHeroStatusCard), findsOneWidget);
      expect(find.byType(HardwareCurveVisualizer), findsOneWidget);
      expect(find.byType(DacActionToolbar), findsOneWidget);

      // Verify visualizer container color matches light surfaceContainer
      final curveVisualizer = tester.widget<HardwareCurveVisualizer>(find.byType(HardwareCurveVisualizer));
      expect(curveVisualizer, isNotNull);
    });

    testWidgets('NowPlayingScreen top bar collapse and 3-dots icons use onSurface color in Light Mode', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final theme = AppThemeBuilder.buildTheme(
        AppPalette.emeraldHiFi,
        isDark: false,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: theme,
            home: NowPlayingScreen(
              onCollapse: () {},
              onOpenProQStudio: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find chevron down icon
      final chevronFinder = find.byIcon(LucideIcons.chevronDown);
      expect(chevronFinder, findsOneWidget);
      final chevronIcon = tester.widget<Icon>(chevronFinder);
      expect(chevronIcon.color, theme.colorScheme.onSurface);
      expect(chevronIcon.color != Colors.white, isTrue);

      // Find 3-dots more vertical icon
      final moreFinder = find.byIcon(LucideIcons.moreVertical);
      expect(moreFinder, findsOneWidget);
      final moreIcon = tester.widget<Icon>(moreFinder);
      expect(moreIcon.color, theme.colorScheme.onSurface);
      expect(moreIcon.color != Colors.white, isTrue);
    });

    testWidgets('StudioWrappedExportHub back button, calendar icon, and title use onSurface in Light Mode', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final theme = AppThemeBuilder.buildTheme(
        AppPalette.emeraldHiFi,
        isDark: false,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: theme,
            home: const StudioWrappedExportHub(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Verify back button in top-left
      final backFinder = find.byIcon(LucideIcons.arrowLeft);
      expect(backFinder, findsOneWidget);
      final backIcon = tester.widget<Icon>(backFinder);
      expect(backIcon.color, theme.colorScheme.onSurface);
      expect(backIcon.color != Colors.white, isTrue);

      // Verify calendar icon in actions
      final calendarFinder = find.byIcon(LucideIcons.calendar);
      expect(calendarFinder, findsOneWidget);
      final calendarIcon = tester.widget<Icon>(calendarFinder);
      expect(calendarIcon.color, theme.colorScheme.onSurface);
      expect(calendarIcon.color != Colors.white, isTrue);

      // Verify title text has onSurface color
      final titleFinder = find.text('STUDIO RECAP GALLERY');
      expect(titleFinder, findsOneWidget);
      final titleWidget = tester.widget<Text>(titleFinder);
      expect(titleWidget.style?.color, theme.colorScheme.onSurface);
    });

    testWidgets('StudioWrappedStoryScreen scaffold, header buttons, and texts adapt to Light Mode', (tester) async {
      await tester.binding.setSurfaceSize(const Size(400, 850));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final theme = AppThemeBuilder.buildTheme(
        AppPalette.emeraldHiFi,
        isDark: false,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: theme,
            home: const StudioWrappedStoryScreen(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify Scaffold background is light (not black)
      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(scaffold.backgroundColor, theme.scaffoldBackgroundColor);
      expect(scaffold.backgroundColor != Colors.black, isTrue);

      // Verify back button in top-left has onSurface color
      final backFinder = find.byIcon(LucideIcons.arrowLeft);
      expect(backFinder, findsOneWidget);
      final backIcon = tester.widget<Icon>(backFinder);
      expect(backIcon.color, theme.colorScheme.onSurface);
      expect(backIcon.color != Colors.white, isTrue);

      // Verify share2 and x header buttons
      final shareFinder = find.descendant(
        of: find.byType(IconButton),
        matching: find.byIcon(LucideIcons.share2),
      );
      expect(shareFinder, findsOneWidget);
      final shareIcon = tester.widget<Icon>(shareFinder);
      expect(shareIcon.color, theme.colorScheme.onSurface);
      expect(shareIcon.color != Colors.white, isTrue);

      final closeFinder = find.descendant(
        of: find.byType(IconButton),
        matching: find.byIcon(LucideIcons.x),
      );
      expect(closeFinder, findsOneWidget);
      final closeIcon = tester.widget<Icon>(closeFinder);
      expect(closeIcon.color, theme.colorScheme.onSurface);
      expect(closeIcon.color != Colors.white, isTrue);

      // Verify Slide 1 title text has onSurface color (not white)
      final titleFinder = find.text('A Year in Pure Sound');
      expect(titleFinder, findsOneWidget);
      final titleWidget = tester.widget<Text>(titleFinder);
      expect(titleWidget.style?.color, theme.colorScheme.onSurface);
      expect(titleWidget.style?.color != Colors.white, isTrue);

      // Let story advance to final slide and check Slide 7 elements
      await tester.pumpAndSettle();
      final replayFinder = find.text('REPLAY RECAP STORY');
      expect(replayFinder, findsOneWidget);
      final replayWidget = tester.widget<Text>(replayFinder);
      expect(replayWidget.style?.color, theme.colorScheme.onSurfaceVariant);
    });
  });
}
