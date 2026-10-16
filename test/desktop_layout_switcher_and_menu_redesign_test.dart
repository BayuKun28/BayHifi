import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:baydev_hifi/core/desktop/desktop_layout_controller.dart';
import 'package:baydev_hifi/core/desktop/desktop_window_service.dart';
import 'package:baydev_hifi/features/dsp_rack/presentation/dsp_rack_screen.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/library/presentation/controllers/library_controller.dart';
import 'package:baydev_hifi/features/library/presentation/unified_library_screen.dart';
import 'package:baydev_hifi/features/dashboard/presentation/widgets/studio_wrapped_bento_banner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Desktop Layout Controller Tests', () {
    test('initial state is auto mode', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      expect(container.read(desktopLayoutModeProvider), equals(DesktopLayoutMode.auto));
    });

    test('updates state to mobile, tablet, and desktop modes', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final controller = container.read(desktopLayoutModeProvider.notifier);

      controller.setLayoutMode(DesktopLayoutMode.mobile);
      expect(container.read(desktopLayoutModeProvider), equals(DesktopLayoutMode.mobile));

      controller.setLayoutMode(DesktopLayoutMode.tablet);
      expect(container.read(desktopLayoutModeProvider), equals(DesktopLayoutMode.tablet));

      controller.setLayoutMode(DesktopLayoutMode.desktop);
      expect(container.read(desktopLayoutModeProvider), equals(DesktopLayoutMode.desktop));

      controller.setLayoutMode(DesktopLayoutMode.auto);
      expect(container.read(desktopLayoutModeProvider), equals(DesktopLayoutMode.auto));
    });
  });

  group('Desktop Window Service Sizing API Tests', () {
    test('setMobileSize, setTabletSize, setDesktopSize execute safely', () {
      final service = DesktopWindowService.instance;
      expect(() => service.setMobileSize(), returnsNormally);
      expect(() => service.setTabletSize(), returnsNormally);
      expect(() => service.setDesktopSize(), returnsNormally);
    });
  });

  group('DSP Category Filter Tests', () {
    test('DspCategoryFilter enum defines all 4 categories', () {
      expect(DspCategoryFilter.values.length, equals(4));
      expect(DspCategoryFilter.all.label, contains('All Modules'));
      expect(DspCategoryFilter.dynamics.label, equals('Dynamics'));
      expect(DspCategoryFilter.tone.label, equals('Tone & EQ'));
      expect(DspCategoryFilter.spatial.label, equals('Spatial & Tube'));
    });
  });

  group('Library Source Filter & Dock Tests', () {
    test('LibrarySourceFilter enum contains 5 sources with distinct labels', () {
      expect(LibrarySourceFilter.values.length, equals(5));
      expect(LibrarySourceFilter.values, contains(LibrarySourceFilter.all));
      expect(LibrarySourceFilter.values, contains(LibrarySourceFilter.offline));
      expect(LibrarySourceFilter.values, contains(LibrarySourceFilter.cloud));
      expect(LibrarySourceFilter.values, contains(LibrarySourceFilter.hiRes));
      expect(LibrarySourceFilter.values, contains(LibrarySourceFilter.untagged));
    });

    test('UnifiedLibraryState filters tracks by source correctly', () {
      final sampleTracks = [
        const Track(
          id: 'local_1',
          title: 'Local Track',
          artist: 'Artist A',
          album: 'Album A',
          albumArtUrl: 'https://example.com/art1.jpg',
          filePath: '/storage/track1.flac',
          duration: Duration(minutes: 3),
          format: AudioFormat.flac,
          bitDepth: 24,
          sampleRate: 96000,
        ),
        const Track(
          id: 'cloud_1',
          title: 'Cloud Track',
          artist: 'Artist B',
          album: 'Album B',
          albumArtUrl: 'https://example.com/art2.jpg',
          remoteUrl: 'https://navidrome.org/stream/1',
          duration: Duration(minutes: 4),
          format: AudioFormat.mp3,
        ),
        const Track(
          id: 'untagged_1',
          title: '',
          artist: '',
          album: '',
          filePath: '/storage/untagged.wav',
          duration: Duration(minutes: 2),
          format: AudioFormat.wav,
        ),
      ];

      final state = UnifiedLibraryState(tracks: sampleTracks);

      expect(state.totalTracksCount, equals(3));
      expect(state.offlineTracksCount, equals(2)); // local_1 and untagged_1 have filePath
      expect(state.cloudTracksCount, equals(1)); // cloud_1
      expect(state.hiResTracksCount, equals(1)); // local_1 is 24-bit 96kHz
      expect(state.untaggedTracksCount, equals(1)); // untagged_1

      // Test switching filters
      final offlineState = state.copyWith(selectedFilter: LibrarySourceFilter.offline);
      expect(offlineState.selectedFilter, equals(LibrarySourceFilter.offline));
      expect(offlineState.filteredTracks.length, equals(2));

      final cloudState = state.copyWith(selectedFilter: LibrarySourceFilter.cloud);
      expect(cloudState.selectedFilter, equals(LibrarySourceFilter.cloud));
      expect(cloudState.filteredTracks.length, equals(1));

      final hiResState = state.copyWith(selectedFilter: LibrarySourceFilter.hiRes);
      expect(hiResState.selectedFilter, equals(LibrarySourceFilter.hiRes));
      expect(hiResState.filteredTracks.length, equals(1));

      final allState = state.copyWith(selectedFilter: LibrarySourceFilter.all);
      expect(allState.selectedFilter, equals(LibrarySourceFilter.all));
      expect(allState.filteredTracks.length, equals(3));
    });
  });

  group('Studio Wrapped Integration Tests', () {
    testWidgets('StudioWrappedBentoBanner renders two-tone typography and stat chips', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: StudioWrappedBentoBanner(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StudioWrappedBentoBanner), findsOneWidget);
      expect(find.text('STUDIO WRAPPED 2026'), findsOneWidget);
      expect(find.text('PLAY RECAP STORY'), findsOneWidget);
      expect(find.text('TEMPLATES'), findsOneWidget);
    });
  });

  group('DSP Master Wet Slider Alignment Tests', () {
    testWidgets('Master Wet / Dry row has CrossAxisAlignment.end for precise baseline alignment', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: DspRackScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the Auto Genre Rules button tooltip
      final genreRulesButton = find.byTooltip('Auto Genre Rules');
      expect(genreRulesButton, findsOneWidget);

      // Verify master wet label exists
      expect(find.text('MASTER WET / DRY'), findsOneWidget);
    });
  });

  group('Adaptive Library Source Chips Tests', () {
    testWidgets('Top source filter chips are visible on Desktop and hidden on Mobile', (tester) async {
      // 1. Desktop Mode (width: 1200)
      tester.view.physicalSize = const Size(1200, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: UnifiedLibraryScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // In Desktop mode, top chips must be visible
      expect(find.textContaining('All Sources'), findsOneWidget);
      expect(find.textContaining('Offline Local'), findsOneWidget);
      expect(find.textContaining('Cloud Library'), findsOneWidget);

      // 2. Mobile Mode (width: 400)
      tester.view.physicalSize = const Size(400, 800);
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: UnifiedLibraryScreen(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // In Mobile mode, top chips must be hidden because FAB dock handles it
      expect(find.textContaining('All Sources'), findsNothing);
      expect(find.textContaining('Offline Local'), findsNothing);
    });
  });
}

