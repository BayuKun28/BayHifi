import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/app/theme/studio_surface_theme.dart';
import 'package:baydev_hifi/app/theme/theme_mode_controller.dart';
import 'package:baydev_hifi/audio_engine/audio_cache_service.dart';
import 'package:baydev_hifi/core/database/local_persistence_service.dart';
import 'package:baydev_hifi/core/widgets/floating_rounded_dock.dart';
import 'package:baydev_hifi/features/dashboard/presentation/dashboard_screen.dart';
import 'package:baydev_hifi/features/dsp_rack/presentation/widgets/rack_unit_card.dart';
import 'package:baydev_hifi/features/library/presentation/unified_library_screen.dart';
import 'package:baydev_hifi/features/player/presentation/widgets/namida_expandable_miniplayer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('bayhifi_phase32_test');
    await LocalPersistenceService.instance.init(customPath: '${tempDir.path}/test_storage.json');
    AudioCacheService.instance.setCacheDirForTesting(tempDir);
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Phase 32.1: StudioSurfaceTheme Static Resolution Unit Tests', () {
    testWidgets('surfaceContainer resolves correctly for translucent and solid', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemeBuilder.buildTheme(AppPalette.namidaCyan, isDark: true),
          home: Builder(
            builder: (context) {
              final colorTranslucent = StudioSurfaceTheme.surfaceContainer(context, isSolid: false);
              final colorSolid = StudioSurfaceTheme.surfaceContainer(context, isSolid: true);
              final scheme = Theme.of(context).colorScheme;

              expect(colorTranslucent.a, closeTo(0.85, 0.01));
              expect(colorSolid.a, 1.0);
              expect(colorSolid, scheme.surfaceContainer);

              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    testWidgets('surfaceContainerHigh resolves correctly for translucent and solid', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemeBuilder.buildTheme(AppPalette.namidaCyan, isDark: true),
          home: Builder(
            builder: (context) {
              final colorTranslucent = StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: false);
              final colorSolid = StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: true);
              final scheme = Theme.of(context).colorScheme;

              expect(colorTranslucent.a, closeTo(0.90, 0.01));
              expect(colorSolid.a, 1.0);
              expect(colorSolid, scheme.surfaceContainerHighest);

              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    testWidgets('surfaceContainerLow resolves correctly for translucent and solid', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemeBuilder.buildTheme(AppPalette.namidaCyan, isDark: true),
          home: Builder(
            builder: (context) {
              final colorTranslucent = StudioSurfaceTheme.surfaceContainerLow(context, isSolid: false);
              final colorSolid = StudioSurfaceTheme.surfaceContainerLow(context, isSolid: true);
              final scheme = Theme.of(context).colorScheme;

              expect(colorTranslucent.a, closeTo(0.70, 0.01));
              expect(colorSolid.a, 1.0);
              expect(colorSolid, scheme.surfaceContainerLow);

              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    testWidgets('surface resolves correctly for translucent and solid', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemeBuilder.buildTheme(AppPalette.namidaCyan, isDark: true),
          home: Builder(
            builder: (context) {
              final colorTranslucent = StudioSurfaceTheme.surface(context, isSolid: false);
              final colorSolid = StudioSurfaceTheme.surface(context, isSolid: true);
              final scheme = Theme.of(context).colorScheme;

              expect(colorTranslucent.a, closeTo(0.90, 0.01));
              expect(colorSolid.a, 1.0);
              expect(colorSolid, scheme.surface);

              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    testWidgets('tintedContainer creates subtle alpha vs 100% opaque alphaBlend', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemeBuilder.buildTheme(AppPalette.namidaCyan, isDark: true),
          home: Builder(
            builder: (context) {
              const tint = Colors.amber;
              final colorTranslucent = StudioSurfaceTheme.tintedContainer(context, tint, isSolid: false);
              final colorSolid = StudioSurfaceTheme.tintedContainer(context, tint, isSolid: true);

              expect(colorTranslucent.a, closeTo(0.14, 0.01));
              expect(colorSolid.a, 1.0); // Solid must be 100% opaque

              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    testWidgets('outline and subtleOutline resolve correctly', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemeBuilder.buildTheme(AppPalette.namidaCyan, isDark: true),
          home: Builder(
            builder: (context) {
              final outTranslucent = StudioSurfaceTheme.outline(context, isSolid: false);
              final outSolid = StudioSurfaceTheme.outline(context, isSolid: true);
              final subOutTranslucent = StudioSurfaceTheme.subtleOutline(context, isSolid: false);
              final subOutSolid = StudioSurfaceTheme.subtleOutline(context, isSolid: true);

              final scheme = Theme.of(context).colorScheme;

              expect(outSolid, scheme.outlineVariant);
              expect(outTranslucent, scheme.outlineVariant.withValues(alpha: 0.5));
              expect(subOutSolid, scheme.outlineVariant.withValues(alpha: 0.6));
              expect(subOutTranslucent, scheme.outlineVariant.withValues(alpha: 0.35));

              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });

    testWidgets('cardDecoration creates conforming M3 Expressive Studio Bento decoration', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: AppThemeBuilder.buildTheme(AppPalette.namidaCyan, isDark: true),
          home: Builder(
            builder: (context) {
              final decorTranslucent = StudioSurfaceTheme.cardDecoration(context: context, isSolid: false, radius: 16);
              final decorSolid = StudioSurfaceTheme.cardDecoration(context: context, isSolid: true, radius: 16);

              expect(decorTranslucent.borderRadius, BorderRadius.circular(16));
              expect(decorTranslucent.boxShadow, isNull);
              expect(decorSolid.boxShadow, isNotNull);
              expect(decorSolid.boxShadow!.isNotEmpty, isTrue);

              return const SizedBox.shrink();
            },
          ),
        ),
      );
    });
  });

  group('Phase 32.2: Extension and Controller Reactive Selection Tests', () {
    testWidgets('SurfaceStyleRefExtension reflects ThemeController state', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, child) {
                final isSolid = ref.isSolidStyle;
                final fillStyle = ref.surfaceFillStyle;
                return Column(
                  children: [
                    Text('SOLID: $isSolid'),
                    Text('STYLE: ${fillStyle.name}'),
                  ],
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('SOLID: false'), findsOneWidget);
      expect(find.text('STYLE: translucent'), findsOneWidget);

      container.read(themeControllerProvider.notifier).setSurfaceFillStyle(SurfaceFillStyle.solid);
      await tester.pump();

      expect(find.text('SOLID: true'), findsOneWidget);
      expect(find.text('STYLE: solid'), findsOneWidget);
    });
  });

  group('Phase 32.3: DashboardScreen SurfaceFillStyle Rendering Tests', () {
    testWidgets('DashboardScreen renders all Bento Cards seamlessly in Solid and Translucent modes', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppThemeBuilder.buildTheme(AppPalette.namidaCyan, isDark: true),
            home: const DashboardScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Translucent mode check
      expect(find.text('C++ SOLOUD AUDIO ENGINE'), findsOneWidget);
      expect(find.text('AUDIOPHILE LISTENING STATS'), findsOneWidget);

      // Switch to Pure Solid M3 mode
      container.read(themeControllerProvider.notifier).setSurfaceFillStyle(SurfaceFillStyle.solid);
      await tester.pumpAndSettle();

      expect(find.text('C++ SOLOUD AUDIO ENGINE'), findsOneWidget);
      expect(find.text('AUDIOPHILE LISTENING STATS'), findsOneWidget);
    });
  });

  group('Phase 32.4: UnifiedLibraryScreen & FloatingDock SurfaceFillStyle Tests', () {
    testWidgets('UnifiedLibraryScreen renders clean empty state and search bar in Solid mode', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(themeControllerProvider.notifier).setSurfaceFillStyle(SurfaceFillStyle.solid);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppThemeBuilder.buildTheme(AppPalette.namidaCyan, isDark: true),
            home: const UnifiedLibraryScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('NO AUDIO TRACKS LOADED'), findsOneWidget);
      expect(find.text('SELECT MUSIC FOLDER'), findsOneWidget);
    });

    testWidgets('FloatingRoundedDock renders floating navigation capsule with active pill', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      int selectedIndex = 0;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppThemeBuilder.buildTheme(AppPalette.namidaCyan, isDark: true),
            home: Scaffold(
              body: Stack(
                children: [
                  FloatingRoundedDock(
                    selectedIndex: selectedIndex,
                    onItemSelected: (index) => selectedIndex = index,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
      expect(find.text('Library'), findsOneWidget);
      expect(find.text('DSP Rack'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Switch to solid style
      container.read(themeControllerProvider.notifier).setSurfaceFillStyle(SurfaceFillStyle.solid);
      await tester.pumpAndSettle();

      expect(find.text('Dashboard'), findsOneWidget);
    });
  });

  group('Phase 32.5: RackUnitCard & MiniPlayer SurfaceFillStyle Rendering Tests', () {
    testWidgets('RackUnitCard renders with solid surface and outline', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(themeControllerProvider.notifier).setSurfaceFillStyle(SurfaceFillStyle.solid);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppThemeBuilder.buildTheme(AppPalette.namidaCyan, isDark: true),
            home: Scaffold(
              body: RackUnitCard(
                unitNumber: '01',
                title: 'PRE-AMP GAIN STAGE',
                subtitle: 'INPUT HEADROOM ATTENUATION',
                accentColor: Colors.amber,
                isActive: true,
                onToggle: () {},
                content: const Text('CONTROL_1'),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('PRE-AMP GAIN STAGE'), findsOneWidget);
      expect(find.text('CONTROL_1'), findsOneWidget);
    });

    testWidgets('NamidaExpandableMiniPlayer renders collapsed player bar in Solid mode', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(themeControllerProvider.notifier).setSurfaceFillStyle(SurfaceFillStyle.solid);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppThemeBuilder.buildTheme(AppPalette.namidaCyan, isDark: true),
            home: const Scaffold(
              body: Stack(
                children: [
                  Positioned.fill(
                    child: Text('MAIN_CONTENT'),
                  ),
                  NamidaExpandableMiniPlayer(),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('MAIN_CONTENT'), findsOneWidget);
    });
  });
}
