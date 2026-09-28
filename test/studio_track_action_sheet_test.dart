import 'package:baydev_hifi/features/library/domain/library_collection_models.dart';
import 'package:baydev_hifi/features/library/presentation/controllers/library_controller.dart';
import 'package:baydev_hifi/features/library/presentation/widgets/studio_track_action_sheet.dart';
import 'package:baydev_hifi/features/library/presentation/widgets/track_tile.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final sampleTrack = Track(
    id: 'track_test_01',
    title: 'Precision Master Audio',
    artist: 'Audiophile Lab',
    album: 'Reference Studio Vol 1',
    duration: const Duration(seconds: 320),
    format: AudioFormat.flac,
    sampleRate: 96000,
    bitDepth: 24,
    filePath: '/storage/emulated/0/Music/track.flac',
  );

  Widget createTestWidget({required Widget child}) {
    return ProviderScope(
      overrides: [
        unifiedLibraryProvider.overrideWith((ref) {
          final notifier = UnifiedLibraryController();
          notifier.state = notifier.state.copyWith(
            tracks: [sampleTrack],
            customPlaylists: [
              PlaylistModel(
                id: 'pl_01',
                name: 'HiFi Chill',
                description: 'Test playlist',
                tracks: [sampleTrack],
                createdAt: DateTime(2026, 1, 1),
              ),
            ],
          );
          return notifier;
        }),
      ],
      child: MaterialApp(
        theme: ThemeData.dark(useMaterial3: true),
        home: Scaffold(body: child),
      ),
    );
  }

  group('StudioTrackActionSheet Tests', () {
    testWidgets('renders track header, Hi-Res badge, and complete action list', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => StudioTrackActionSheet.show(context, sampleTrack),
            child: const Text('Open Sheet'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      // Tap button to open sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Verify Header
      expect(find.text('Precision Master Audio'), findsOneWidget);
      expect(find.text('Audiophile Lab • Reference Studio Vol 1'), findsOneWidget);
      expect(find.text('HI-RES'), findsOneWidget);
      expect(find.text('FLAC'), findsOneWidget);

      // Verify All Action Items
      expect(find.text('Play Next'), findsOneWidget);
      expect(find.text('Add to Queue'), findsOneWidget);
      expect(find.text('Add to Playlist'), findsOneWidget);
      expect(find.text('Go to Album'), findsOneWidget);
      expect(find.text('Go to Artist'), findsOneWidget);
      expect(find.text('Add to Favorites'), findsOneWidget);
      expect(find.text('Edit Metadata Tags'), findsOneWidget);
      expect(find.text('Inspect Audio Specs'), findsOneWidget);
    });

    testWidgets('TrackTile 3-dots button triggers StudioTrackActionSheet consistently', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget(
        child: TrackTile(
          track: sampleTrack,
          isPlaying: false,
          onTap: () {},
        ),
      ));
      await tester.pumpAndSettle();

      // Find 3 dots icon button
      final moreButton = find.byTooltip('Track Options');
      expect(moreButton, findsOneWidget);

      await tester.tap(moreButton);
      await tester.pumpAndSettle();

      // Verify Unified Sheet opens
      expect(find.text('Play Next'), findsOneWidget);
      expect(find.text('Add to Queue'), findsOneWidget);
      expect(find.text('Go to Album'), findsOneWidget);
    });

    testWidgets('Add to Playlist item opens playlist selection sheet', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget(
        child: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => StudioTrackActionSheet.show(context, sampleTrack),
            child: const Text('Open Sheet'),
          ),
        ),
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Tap Add to Playlist
      await tester.tap(find.text('Add to Playlist'));
      await tester.pumpAndSettle();

      // Verify Playlist Sheet
      expect(find.text('ADD TRACK TO PLAYLIST'), findsOneWidget);
      expect(find.text('HiFi Chill'), findsOneWidget);
    });
  });
}
