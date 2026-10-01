import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/library/presentation/controllers/library_controller.dart';
import 'package:baydev_hifi/features/library/data/online_metadata_service.dart';
import 'package:baydev_hifi/features/library/presentation/unified_library_screen.dart';
import 'package:baydev_hifi/features/library/presentation/widgets/online_batch_auto_tagger_modal.dart';
import 'package:baydev_hifi/features/library/presentation/widgets/online_candidate_picker_modal.dart';

class FakeOnlineMetadataService extends OnlineMetadataService {
  @override
  Future<List<OnlineMetadataCandidate>> searchCandidates({
    required String query,
    String? artistHint,
    String? albumHint,
    int? targetDurationSeconds,
    int limit = 15,
  }) async {
    return [
      const OnlineMetadataCandidate(
        title: 'Faded',
        artist: 'Alan Walker',
        album: 'Different World',
        source: MetadataSource.iTunes,
        confidenceScore: 0.95,
        year: 2018,
      ),
    ];
  }

  @override
  Future<List<OnlineMetadataCandidate>> searchCandidatesForTrack(
    Track track, {
    int limit = 15,
  }) async {
    return [
      OnlineMetadataCandidate(
        title: track.title.contains('Track') ? 'Clair de Lune' : track.title,
        artist: 'Claude Debussy',
        album: 'Suite Bergamasque',
        source: MetadataSource.iTunes,
        confidenceScore: 0.90,
        year: 1905,
      ),
    ];
  }

  @override
  Future<DownloadedArtwork?> downloadArtwork(String url) async {
    return null;
  }

  @override
  Future<({String? lyrics, bool isSynced})> fetchLyrics({
    required String title,
    required String artist,
    String? album,
    int? durationSeconds,
  }) async {
    return (lyrics: null, isSynced: false);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final taggedTrack = Track(
    id: 'track_tagged',
    title: 'Clair de Lune',
    artist: 'Claude Debussy',
    album: 'Suite Bergamasque',
    duration: const Duration(minutes: 5, seconds: 0),
    filePath: '/music/clair_de_lune.flac',
    albumArtUrl: '/art/debussy.jpg',
    bitDepth: 24,
    sampleRate: 96000,
  );

  final untaggedArtistTrack = Track(
    id: 'track_untagged_1',
    title: 'Track 01',
    artist: 'Unknown Artist',
    album: 'Unknown Album',
    duration: const Duration(minutes: 3, seconds: 30),
    filePath: '/music/Track01.mp3',
  );

  final untaggedArtTrack = Track(
    id: 'track_untagged_2',
    title: 'Faded',
    artist: 'Alan Walker',
    album: 'Different World',
    duration: const Duration(minutes: 3, seconds: 32),
    filePath: '/music/faded.flac',
    albumArtUrl: null,
    albumArtBytes: null,
  );

  group('Track.isUntagged Unit Tests', () {
    test('Correctly identifies tagged and untagged tracks', () {
      expect(taggedTrack.isUntagged, isFalse);
      expect(untaggedArtistTrack.isUntagged, isTrue);
      expect(untaggedArtTrack.isUntagged, isTrue);

      final emptyArtist = Track(
        id: 'track_empty',
        title: 'Song',
        artist: '',
        album: 'Album',
        duration: const Duration(minutes: 3),
        albumArtUrl: '/art.jpg',
      );
      expect(emptyArtist.isUntagged, isTrue);

      final rawFilenameTitle = Track(
        id: 'track_raw',
        title: 'my_song_download.mp3',
        artist: 'Artist',
        album: 'Album',
        duration: const Duration(minutes: 3),
        albumArtUrl: '/art.jpg',
      );
      expect(rawFilenameTitle.isUntagged, isTrue);
    });
  });

  group('Library Untagged Filter & Chip Tests', () {
    testWidgets('Calculates untaggedTracksCount and filters correctly in UnifiedLibraryState', (tester) async {
      final libraryController = UnifiedLibraryController();
      libraryController.state = libraryController.state.copyWith(
        tracks: [taggedTrack, untaggedArtistTrack, untaggedArtTrack],
      );

      expect(libraryController.state.totalTracksCount, 3);
      expect(libraryController.state.untaggedTracksCount, 2);

      // Default filter (all)
      expect(libraryController.state.filteredTracks.length, 3);

      // Set filter to untagged
      libraryController.setFilter(LibrarySourceFilter.untagged);
      expect(libraryController.state.selectedFilter, LibrarySourceFilter.untagged);
      expect(libraryController.state.filteredTracks.length, 2);
      expect(libraryController.state.filteredTracks.map((t) => t.id).toList(), [
        'track_untagged_2',
        'track_untagged_1',
      ]);
    });

    testWidgets('Renders Untagged chip and Untagged Quick Action Banner in UnifiedLibraryScreen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      final libraryController = UnifiedLibraryController();
      libraryController.state = libraryController.state.copyWith(
        tracks: [taggedTrack, untaggedArtistTrack, untaggedArtTrack],
        selectedFilter: LibrarySourceFilter.untagged,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            unifiedLibraryProvider.overrideWith((ref) => libraryController),
            onlineMetadataServiceProvider.overrideWithValue(FakeOnlineMetadataService()),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: UnifiedLibraryScreen(),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Verify Untagged filter chip is rendered with dynamic counter (2)
      expect(find.text('Untagged (2)'), findsOneWidget);

      // Verify Untagged quick action banner is rendered
      expect(find.text('2 Untagged Tracks Found'), findsOneWidget);
      expect(find.text('Auto-Tag All from Internet'), findsOneWidget);
      expect(find.text('Batch Edit'), findsOneWidget);
    });

    testWidgets('Renders OnlineBatchAutoTaggerModal with tracks list and action buttons', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      final tracks = [untaggedArtistTrack, untaggedArtTrack];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            onlineMetadataServiceProvider.overrideWithValue(FakeOnlineMetadataService()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: OnlineBatchAutoTaggerModal(tracks: tracks),
            ),
          ),
        ),
      );

      await tester.pump();
      // Pump through the two loop iterations (150ms debounce each)
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pumpAndSettle();

      // Verify Header and modal structure
      expect(find.text('Batch Online Auto-Tagger'), findsOneWidget);
      expect(find.byType(Checkbox), findsNWidgets(2));
      expect(find.textContaining('Apply & Save 2 Tracks to Files'), findsOneWidget);
    });

    testWidgets('Renders OnlineCandidatePickerModal and displays candidates', (tester) async {
      await tester.binding.setSurfaceSize(const Size(1200, 800));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            onlineMetadataServiceProvider.overrideWithValue(FakeOnlineMetadataService()),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: OnlineCandidatePickerModal(track: untaggedArtTrack),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Online Metadata Search'), findsOneWidget);
      expect(find.text('ITUNES • MUSICBRAINZ • DEEZER • LRCLIB'), findsNothing); // upper/lowercase check
      expect(find.text('iTunes • MusicBrainz • Deezer • LRCLIB'), findsOneWidget);
      expect(find.text('95% MATCH'), findsOneWidget);
      expect(find.text('Apply'), findsOneWidget);
    });
  });
}
