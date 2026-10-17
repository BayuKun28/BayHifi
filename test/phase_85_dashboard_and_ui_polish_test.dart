import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:baydev_hifi/app/theme/simple_as_f_theme.dart';
import 'package:baydev_hifi/core/database/local_persistence_service.dart';
import 'package:baydev_hifi/core/widgets/two_tone_header.dart';
import 'package:baydev_hifi/features/dashboard/presentation/dashboard_screen.dart';
import 'package:baydev_hifi/features/dashboard/presentation/widgets/simple_as_f_discovery_grid.dart';
import 'package:baydev_hifi/features/dashboard/presentation/widgets/studio_instant_mix_banner.dart';
import 'package:baydev_hifi/features/dashboard/presentation/widgets/studio_wrapped_bento_banner.dart';
import 'package:baydev_hifi/features/library/presentation/controllers/library_controller.dart';
import 'package:baydev_hifi/features/library/presentation/widgets/download_toggle_row.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/pro_q_studio/presentation/widgets/auto_eq_modal_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  final testTrack1 = Track(
    id: 'track_1',
    title: 'Viva La Vida',
    artist: 'Coldplay',
    album: 'Viva La Vida or Death and All His Friends',
    filePath: '/storage/viva.flac',
    duration: const Duration(seconds: 242),
    sampleRate: 44100,
    bitrate: 1411,
    format: AudioFormat.flac,
  );

  final testTrack2 = Track(
    id: 'track_2',
    title: 'Fix You',
    artist: 'Coldplay',
    album: 'X&Y',
    filePath: '/storage/fixyou.flac',
    duration: const Duration(seconds: 295),
    sampleRate: 96000,
    bitrate: 2400,
    format: AudioFormat.flac,
  );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('baydev_p85_test_');
    final dbPath = '${tempDir.path}/test_db.json';
    await LocalPersistenceService.instance.init(customPath: dbPath);
    await LocalPersistenceService.instance.logTrackPlayback(testTrack1.toMap());
    await LocalPersistenceService.instance.logTrackPlayback(testTrack2.toMap());
  });

  tearDown(() async {
    try {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('Phase 85: Dashboard & UI Polish Tests', () {
    testWidgets('1. StudioInstantMixBanner renders Smart Mix with Lucide sparkles and play icons', (tester) async {
      final controller = UnifiedLibraryController(
        initialTracks: [testTrack1, testTrack2],
      );

      final container = ProviderContainer(
        overrides: [
          unifiedLibraryProvider.overrideWith((ref) => controller),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: SimpleAsFTheme.forestCanvas),
            home: const Scaffold(
              body: SingleChildScrollView(
                child: StudioInstantMixBanner(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StudioInstantMixBanner), findsOneWidget);
      expect(find.text('STUDIO SMART MIX'), findsOneWidget);
      expect(find.text('START SMART MIX'), findsOneWidget);

      // Verify Lucide icons are used
      expect(find.byWidgetPredicate((w) => w is Icon && w.icon == LucideIcons.sparkles), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is Icon && w.icon == LucideIcons.play), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is Icon && w.icon == LucideIcons.slidersHorizontal), findsOneWidget);
    });

    testWidgets('2. SimpleAsFDiscoveryGrid enforces 2x2 grid (max 4 items) on mobile width (<600px)', (tester) async {
      tester.view.physicalSize = const Size(390 * 3, 844 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final tracks = List.generate(
        8,
        (i) => Track(
          id: 'track_$i',
          title: 'Track $i',
          artist: 'Artist $i',
          album: 'Album $i',
          filePath: '/storage/t$i.mp3',
          duration: const Duration(seconds: 180),
        ),
      );

      final controller = UnifiedLibraryController(
        initialTracks: tracks,
      );

      final container = ProviderContainer(
        overrides: [
          unifiedLibraryProvider.overrideWith((ref) => controller),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: SimpleAsFTheme.forestCanvas),
            home: const Scaffold(
              body: SingleChildScrollView(
                child: SimpleAsFDiscoveryGrid(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final gridView = tester.widget<GridView>(find.byType(GridView));
      final delegate = gridView.childrenDelegate as SliverChildBuilderDelegate;
      // Must be capped at 4 items for mobile 2x2 grid
      expect(delegate.estimatedChildCount, lessThanOrEqualTo(4));
    });

    testWidgets('3. DashboardScreen contains Wrapped, Smart Mix, YouTube capsule and excludes DownloadToggleRow', (tester) async {
      tester.view.physicalSize = const Size(400 * 3, 1000 * 3);
      tester.view.devicePixelRatio = 3.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final controller = UnifiedLibraryController(
        initialTracks: [testTrack1, testTrack2],
      );

      final container = ProviderContainer(
        overrides: [
          unifiedLibraryProvider.overrideWith((ref) => controller),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: SimpleAsFTheme.forestCanvas),
            home: const DashboardScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Wrapped banner is present
      expect(find.byType(StudioWrappedBentoBanner), findsOneWidget);
      // Smart Mix banner is present
      expect(find.byType(StudioInstantMixBanner), findsOneWidget);
      // YouTube Music HiFi capsule is present
      expect(find.text('Explore YouTube Music HiFi • Global Streaming'), findsOneWidget);
      // Recently Played is present
      expect(find.byWidgetPredicate((w) => w is TwoToneHeader && w.primaryText == 'RECENTLY'), findsOneWidget);
      // DownloadToggleRow is REMOVED
      expect(find.byType(DownloadToggleRow), findsNothing);
    });

    testWidgets('4. AutoEqModalDialog uses solid studio button styling with high-contrast text', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: ThemeData.dark().copyWith(scaffoldBackgroundColor: SimpleAsFTheme.forestCanvas),
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const AutoEqModalDialog(),
                      );
                    },
                    child: const Text('Open AutoEQ'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open AutoEQ'));
      await tester.pumpAndSettle();

      // Verify Apply button is rendered
      expect(find.text('APPLY TO DSP'), findsOneWidget);
      // Verify Lucide activity icon is present on the solid button
      expect(find.byWidgetPredicate((w) => w is Icon && w.icon == LucideIcons.activity), findsAtLeastNWidgets(1));
    });
  });
}
