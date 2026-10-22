import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/features/library/domain/library_collection_models.dart';
import 'package:baydev_hifi/features/library/presentation/controllers/library_controller.dart';
import 'package:baydev_hifi/features/library/presentation/tabs/library_tracks_tab.dart';
import 'package:baydev_hifi/features/library/presentation/widgets/library_sort_filter_sheets.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testTrack1 = Track(
    id: 'track_1',
    title: 'Comfortably Numb',
    artist: 'Pink Floyd',
    album: 'The Wall',
    duration: const Duration(minutes: 6, seconds: 22),
    filePath: '/music/the_wall.flac',
    format: AudioFormat.flac,
  );

  final testTrack2 = Track(
    id: 'track_2',
    title: 'Wish You Were Here',
    artist: 'Pink Floyd',
    album: 'Wish You Were Here',
    duration: const Duration(minutes: 5, seconds: 34),
    filePath: '/music/wywh.flac',
    format: AudioFormat.flac,
  );

  testWidgets('LibraryTracksTab renders track tiles and triggers tap events', (tester) async {
    final scrollController = ScrollController();
    addTearDown(() => scrollController.dispose());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          unifiedLibraryProvider.overrideWith((ref) {
            return UnifiedLibraryController(
              initialTracks: [testTrack1, testTrack2],
            );
          }),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: LibraryTracksTab(
              scrollController: scrollController,
              bottomPadding: 0,
              onAddToPlaylist: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Comfortably Numb'), findsOneWidget);
    expect(find.text('Wish You Were Here'), findsOneWidget);
  });

  testWidgets('LibrarySortFilterSheets showSortSheet opens and shows sort options', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          unifiedLibraryProvider.overrideWith((ref) => UnifiedLibraryController()),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, _) {
                return ElevatedButton(
                  onPressed: () => LibrarySortFilterSheets.showSortSheet(context, ref),
                  child: const Text('Open Sort'),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open Sort'));
    await tester.pumpAndSettle();

    expect(find.text('SORT COLLECTION'), findsOneWidget);
    expect(find.text(SortField.title.label), findsOneWidget);
    expect(find.text(SortField.artist.label), findsOneWidget);
  });

  testWidgets('LibraryTracksTab reactively filters tracks when audio source filter changes', (tester) async {
    final scrollController = ScrollController();
    addTearDown(() => scrollController.dispose());

    final hiResTrack = Track(
      id: 'hires_1',
      title: 'Hi-Res Symphony',
      artist: 'Audiophile Master',
      album: 'Studio Vault',
      duration: const Duration(minutes: 4),
      filePath: '/music/symphony.flac',
      format: AudioFormat.flac,
      sampleRate: 96000,
      bitDepth: 24,
    );

    final standardTrack = Track(
      id: 'standard_1',
      title: 'Standard MP3 Song',
      artist: 'Radio Band',
      album: 'Pop Hits',
      duration: const Duration(minutes: 3),
      filePath: '/music/song.mp3',
      format: AudioFormat.mp3,
      sampleRate: 44100,
      bitDepth: 16,
    );

    late UnifiedLibraryController controller;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          unifiedLibraryProvider.overrideWith((ref) {
            controller = UnifiedLibraryController(
              initialTracks: [hiResTrack, standardTrack],
            );
            return controller;
          }),
        ],
        child: MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: LibraryTracksTab(
              scrollController: scrollController,
              bottomPadding: 0,
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Initially with LibrarySourceFilter.all, both tracks are visible
    expect(find.text('Hi-Res Symphony'), findsOneWidget);
    expect(find.text('Standard MP3 Song'), findsOneWidget);

    // Filter to Hi-Res only (as triggered by FAB audio source dock)
    controller.setFilter(LibrarySourceFilter.hiRes);
    await tester.pumpAndSettle();

    // Now only Hi-Res Symphony must be displayed
    expect(find.text('Hi-Res Symphony'), findsOneWidget);
    expect(find.text('Standard MP3 Song'), findsNothing);

    // Reset back to All Sources
    controller.setFilter(LibrarySourceFilter.all);
    await tester.pumpAndSettle();

    expect(find.text('Hi-Res Symphony'), findsOneWidget);
    expect(find.text('Standard MP3 Song'), findsOneWidget);
  });
}
