import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/library/data/metadata_tagger_service.dart';
import 'package:baydev_hifi/features/library/presentation/controllers/library_controller.dart';
import 'package:baydev_hifi/features/library/presentation/widgets/metadata_tag_editor_sheet.dart';
import 'package:baydev_hifi/features/library/presentation/widgets/batch_track_tag_editor_modal.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MetadataTaggerService Domain & Parser Tests', () {
    test('AudioTagData correctly initializes from Track and applies to Track', () {
      final sampleTrack = Track(
        id: 't1',
        title: 'Original Title',
        artist: 'Original Artist',
        album: 'Original Album',
        duration: const Duration(minutes: 3),
        filePath: '/music/t1.flac',
        format: AudioFormat.flac,
        genre: 'Rock',
        year: 2021,
        trackNumber: 1,
        trackTotal: 10,
        discNumber: 1,
        discTotal: 1,
        albumArtist: 'Original Artist',
        lyrics: 'Line 1\nLine 2',
      );

      final tagData = AudioTagData.fromTrack(sampleTrack);
      expect(tagData.title, 'Original Title');
      expect(tagData.artist, 'Original Artist');
      expect(tagData.album, 'Original Album');
      expect(tagData.genre, 'Rock');
      expect(tagData.year, 2021);
      expect(tagData.trackNumber, 1);
      expect(tagData.trackTotal, 10);
      expect(tagData.lyrics, 'Line 1\nLine 2');

      final updatedTagData = tagData.copyWith(
        title: 'New Master Title',
        artist: 'Remastered Artist',
        album: 'Deluxe Edition',
        year: 2024,
        trackNumber: 2,
        genre: 'Audiophile',
      );

      final updatedTrack = updatedTagData.applyToTrack(sampleTrack);
      expect(updatedTrack.title, 'New Master Title');
      expect(updatedTrack.artist, 'Remastered Artist');
      expect(updatedTrack.album, 'Deluxe Edition');
      expect(updatedTrack.year, 2024);
      expect(updatedTrack.trackNumber, 2);
      expect(updatedTrack.genre, 'Audiophile');
      expect(updatedTrack.duration, sampleTrack.duration);
      expect(updatedTrack.format, AudioFormat.flac);
    });

    test('TagPatternParser parses various filename patterns accurately', () {
      // 1. %artist% - %title%
      final res1 = TagPatternParser.parse('Daft Punk - Get Lucky', '%artist% - %title%');
      expect(res1['artist'], 'Daft Punk');
      expect(res1['title'], 'Get Lucky');

      // 2. %track% - %title%
      final res2 = TagPatternParser.parse('04 - Bohemian Rhapsody', '%track% - %title%');
      expect(res2['track'], '04');
      expect(res2['title'], 'Bohemian Rhapsody');

      // 3. %track%. %title%
      final res3 = TagPatternParser.parse('12. Hotel California', '%track%. %title%');
      expect(res3['track'], '12');
      expect(res3['title'], 'Hotel California');

      // 4. %track% - %artist% - %title%
      final res4 = TagPatternParser.parse('01 - Pink Floyd - Time', '%track% - %artist% - %title%');
      expect(res4['track'], '01');
      expect(res4['artist'], 'Pink Floyd');
      expect(res4['title'], 'Time');

      // 5. %title%
      final res5 = TagPatternParser.parse('Stairway to Heaven', '%title%');
      expect(res5['title'], 'Stairway to Heaven');
    });

    test('generateAutoNumberedTags generates sequential track numbering', () {
      final tracks = List.generate(
        5,
        (i) => Track(
          id: 'trk_$i',
          title: 'Track ${i + 1}',
          artist: 'Band Name',
          album: 'Album Title',
          duration: const Duration(minutes: 3),
        ),
      );

      final autoTags = MetadataTaggerService.generateAutoNumberedTags(
        tracks,
        const AutoNumberingOptions(startNumber: 1, setTotal: true),
        sharedOverrides: const AudioTagData(
          genre: 'Jazz',
          year: 2023,
        ),
      );

      expect(autoTags.length, 5);
      for (int i = 0; i < 5; i++) {
        expect(autoTags[i].trackNumber, i + 1);
        expect(autoTags[i].trackTotal, 5);
        expect(autoTags[i].genre, 'Jazz');
        expect(autoTags[i].year, 2023);
      }
    });

    test('writeBatchTags processes items and returns BatchTaggingResult', () async {
      const tagger = MetadataTaggerService();
      final tracks = [
        const Track(
          id: 'b1',
          title: 'Song A',
          artist: 'Artist A',
          album: 'Album A',
          duration: Duration(minutes: 2),
        ),
        const Track(
          id: 'b2',
          title: 'Song B',
          artist: 'Artist A',
          album: 'Album A',
          duration: Duration(minutes: 3),
        ),
      ];

      final items = [
        BatchTaggingItem(
          track: tracks[0],
          tagData: const AudioTagData(title: 'Song A Remastered', trackNumber: 1),
        ),
        BatchTaggingItem(
          track: tracks[1],
          tagData: const AudioTagData(title: 'Song B Remastered', trackNumber: 2),
        ),
      ];

      final result = await tagger.writeBatchTags(items);
      expect(result.totalCount, 2);
      expect(result.successCount, 2);
      expect(result.failedCount, 0);
      expect(result.updatedTracks.length, 2);
      expect(result.updatedTracks[0].title, 'Song A Remastered');
      expect(result.updatedTracks[1].title, 'Song B Remastered');
    });
  });

  group('UnifiedLibraryController Tagging Integration Tests', () {
    test('updateTrackTags updates track and syncs state', () async {
      final initialTracks = [
        const Track(
          id: 'sync_1',
          title: 'Old Title',
          artist: 'Old Artist',
          album: 'Old Album',
          duration: Duration(minutes: 4),
          genre: 'Pop',
          year: 2018,
          trackNumber: 1,
        ),
      ];

      final controller = UnifiedLibraryController(initialTracks: initialTracks);
      expect(controller.state.tracks.first.title, 'Old Title');

      final updated = await controller.updateTrackTags(
        'sync_1',
        const AudioTagData(
          title: 'HiFi Studio Master',
          artist: 'Master Artist',
          album: 'Master Album',
          genre: 'Audiophile Master',
          year: 2026,
          trackNumber: 5,
        ),
        writeToFile: false,
      );

      expect(updated, isNotNull);
      expect(updated!.title, 'HiFi Studio Master');
      expect(updated.artist, 'Master Artist');
      expect(updated.album, 'Master Album');
      expect(updated.genre, 'Audiophile Master');
      expect(updated.year, 2026);
      expect(updated.trackNumber, 5);

      expect(controller.state.tracks.first.title, 'HiFi Studio Master');
      expect(controller.state.tracks.first.year, 2026);
    });

    test('updateBatchTracksTags updates multiple tracks in library controller', () async {
      final initialTracks = [
        const Track(
          id: 'multi_1',
          title: 'Track One',
          artist: 'Original Artist',
          album: 'Original Album',
          duration: Duration(minutes: 3),
        ),
        const Track(
          id: 'multi_2',
          title: 'Track Two',
          artist: 'Original Artist',
          album: 'Original Album',
          duration: Duration(minutes: 4),
        ),
      ];

      final controller = UnifiedLibraryController(initialTracks: initialTracks);

      final items = [
        BatchTaggingItem(
          track: initialTracks[0],
          tagData: const AudioTagData(
            album: 'Studio Remaster',
            genre: 'Hi-Res Lossless',
            trackNumber: 1,
          ),
        ),
        BatchTaggingItem(
          track: initialTracks[1],
          tagData: const AudioTagData(
            album: 'Studio Remaster',
            genre: 'Hi-Res Lossless',
            trackNumber: 2,
          ),
        ),
      ];

      final result = await controller.updateBatchTracksTags(items);
      expect(result.successCount, 2);
      expect(controller.state.tracks[0].album, 'Studio Remaster');
      expect(controller.state.tracks[1].album, 'Studio Remaster');
      expect(controller.state.tracks[0].genre, 'Hi-Res Lossless');
      expect(controller.state.tracks[1].genre, 'Hi-Res Lossless');
    });
  });

  group('Metadata Tag Editor Widgets Tests', () {
    testWidgets('MetadataTagEditorSheet renders fields and allows editing', (tester) async {
      final testTrack = Track(
        id: 'widget_t1',
        title: 'Studio Test Track',
        artist: 'Studio Artist',
        albumArtist: 'Studio Album Artist',
        album: 'Reference Album',
        duration: const Duration(minutes: 3, seconds: 45),
        format: AudioFormat.flac,
        sampleRate: 96000,
        bitDepth: 24,
        genre: 'Audiophile',
        year: 2024,
        trackNumber: 1,
        trackTotal: 8,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            unifiedLibraryProvider.overrideWith(
              (ref) => UnifiedLibraryController(initialTracks: [testTrack]),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: MetadataTagEditorSheet(track: testTrack),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header and format badge
      expect(find.text('STUDIO TAG EDITOR'), findsOneWidget);
      expect(find.text('FLAC 24-bit / 96.0 kHz'), findsOneWidget);

      // Check form fields
      expect(find.text('TRACK TITLE'), findsOneWidget);
      expect(find.text('Studio Test Track'), findsOneWidget);
      expect(find.text('TRACK ARTIST'), findsOneWidget);
      expect(find.text('Studio Artist'), findsOneWidget);
      expect(find.text('ALBUM ARTIST'), findsOneWidget);
      expect(find.text('Studio Album Artist'), findsOneWidget);
      expect(find.text('ALBUM NAME'), findsOneWidget);
      expect(find.text('Reference Album'), findsOneWidget);

      // Check actions
      expect(find.text('Pick Image'), findsOneWidget);
      expect(find.text('Save Tags to File'), findsOneWidget);
    });

    testWidgets('BatchTrackTagEditorModal renders shared fields and auto-numbering', (tester) async {
      final tracks = [
        const Track(
          id: 'b_t1',
          title: 'Batch Song 1',
          artist: 'Common Artist',
          album: 'Common Album',
          duration: Duration(minutes: 3),
        ),
        const Track(
          id: 'b_t2',
          title: 'Batch Song 2',
          artist: 'Common Artist',
          album: 'Common Album',
          duration: Duration(minutes: 4),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            unifiedLibraryProvider.overrideWith(
              (ref) => UnifiedLibraryController(initialTracks: tracks),
            ),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: BatchTrackTagEditorModal(tracks: tracks),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check header
      expect(find.text('BATCH TAG EDITOR'), findsOneWidget);
      expect(find.text('2 TRACKS SELECTED'), findsOneWidget);

      // Check sections
      expect(find.text('BATCH COVER ARTWORK'), findsOneWidget);
      expect(find.text('COMMON TAGS (APPLY TO ALL)'), findsOneWidget);
      expect(find.text('AUTO-NUMBERING SEQUENCER'), findsOneWidget);
      expect(find.text('EXTRACT TITLE FROM FILENAME'), findsOneWidget);

      // Check apply button
      expect(find.text('Apply to 2 Tracks'), findsOneWidget);
    });
  });
}
