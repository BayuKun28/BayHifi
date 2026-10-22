import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:baydev_hifi/core/database/local_persistence_service.dart';
import 'package:baydev_hifi/features/library/domain/library_collection_models.dart';
import 'package:baydev_hifi/features/library/presentation/controllers/library_controller.dart';
import 'package:baydev_hifi/features/library/presentation/widgets/studio_playlist_action_sheet.dart';
import 'package:baydev_hifi/features/library/presentation/widgets/studio_track_action_sheet.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory testDir;

  setUpAll(() async {
    testDir = Directory.systemTemp.createTempSync('bayhifi_cleanup_test_');

    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      return testDir.path;
    });

    SharedPreferences.setMockInitialValues({});
    await LocalPersistenceService.instance.init();
  });

  tearDownAll(() {
    try {
      if (testDir.existsSync()) {
        testDir.deleteSync(recursive: true);
      }
    } catch (_) {}
  });

  group('Track.isRemote Property Tests', () {
    test('correctly identifies remote tracks from streaming platforms and URLs', () {
      const ytTrack = Track(
        id: 'yt_abc123',
        title: 'Online Song',
        artist: 'Online Artist',
        album: 'Online Album',
        duration: Duration(minutes: 3),
        remoteUrl: 'https://youtube.com/audio/123',
      );
      expect(ytTrack.isRemote, isTrue);

      const spotifyTrack = Track(
        id: 'spotify_xyz789',
        title: 'Spotify Track',
        artist: 'Spotify Artist',
        album: 'Spotify Album',
        duration: Duration(minutes: 4),
      );
      expect(spotifyTrack.isRemote, isTrue);

      const subsonicTrack = Track(
        id: 'subsonic_s1',
        title: 'Subsonic Track',
        artist: 'Subsonic Artist',
        album: 'Subsonic Album',
        duration: Duration(minutes: 5),
      );
      expect(subsonicTrack.isRemote, isTrue);

      const localTrack = Track(
        id: 'local_1',
        title: 'Local FLAC',
        artist: 'Local Artist',
        album: 'Local Album',
        duration: Duration(minutes: 4, seconds: 12),
        filePath: '/storage/emulated/0/Music/song.flac',
        format: AudioFormat.flac,
      );
      expect(localTrack.isRemote, isFalse);
    });
  });

  group('UnifiedLibraryController Online Track & Playlist Cleanup Tests', () {
    const tOnline1 = Track(
      id: 'yt_song1',
      title: 'YouTube Song 1',
      artist: 'Artist 1',
      album: 'Online Hits',
      duration: Duration(minutes: 3, seconds: 30),
      remoteUrl: 'https://youtube.com/song1',
    );
    const tOnline2 = Track(
      id: 'spotify_song2',
      title: 'Spotify Song 2',
      artist: 'Artist 2',
      album: 'Online Hits',
      duration: Duration(minutes: 4),
    );
    const tOnlineShared = Track(
      id: 'yt_shared',
      title: 'Shared Online Song',
      artist: 'Popular Artist',
      album: 'Chart Toppers',
      duration: Duration(minutes: 3),
      remoteUrl: 'https://youtube.com/shared',
    );
    const tLocal = Track(
      id: 'local_flac_1',
      title: 'Local Master',
      artist: 'Audiophile Band',
      album: 'HiRes Master',
      duration: Duration(minutes: 5),
      filePath: '/music/local_flac_1.flac',
      format: AudioFormat.flac,
    );

    late UnifiedLibraryController controller;

    setUp(() async {
      await LocalPersistenceService.instance.saveFavoriteTrackIds({});

      final p1 = PlaylistModel(
        id: 'p_imported_yt',
        name: 'Imported YouTube Hits',
        description: 'Test playlist 1',
        tracks: [tOnline1, tOnline2, tOnlineShared, tLocal],
        isCustom: true,
        createdAt: DateTime(2026, 1, 1),
      );

      final p2 = PlaylistModel(
        id: 'p_other_custom',
        name: 'My Other Playlist',
        description: 'Test playlist 2',
        tracks: [tOnlineShared],
        isCustom: true,
        createdAt: DateTime(2026, 1, 1),
      );

      controller = UnifiedLibraryController(
        initialTracks: [tOnline1, tOnline2, tOnlineShared, tLocal],
        initialCustomPlaylists: [p1, p2],
      );
    });

    test('deletePlaylist with removeOnlineTracks: false preserves all tracks in library', () {
      controller.deletePlaylist('p_imported_yt', removeOnlineTracks: false);

      expect(controller.state.customPlaylists.length, 1);
      expect(controller.state.customPlaylists.first.id, 'p_other_custom');

      // All tracks still in library
      expect(controller.state.tracks.length, 4);
      expect(controller.state.tracks.map((t) => t.id), containsAll(['yt_song1', 'spotify_song2', 'yt_shared', 'local_flac_1']));
    });

    test('deletePlaylist with removeOnlineTracks: true removes only exclusive online tracks and preserves shared & local tracks', () {
      controller.deletePlaylist('p_imported_yt', removeOnlineTracks: true);

      expect(controller.state.customPlaylists.length, 1);
      expect(controller.state.customPlaylists.first.id, 'p_other_custom');

      // yt_song1 and spotify_song2 should be removed
      // yt_shared should be preserved (it is in p_other_custom)
      // local_flac_1 should be preserved (it is local audio)
      final remainingIds = controller.state.tracks.map((t) => t.id).toList();
      expect(remainingIds, isNot(contains('yt_song1')));
      expect(remainingIds, isNot(contains('spotify_song2')));
      expect(remainingIds, contains('yt_shared'));
      expect(remainingIds, contains('local_flac_1'));
      expect(controller.state.statusMessage, contains('2 online tracks removed'));
    });

    test('deletePlaylist preserves online tracks if they are favorited', () {
      controller.toggleFavorite('yt_song1');
      expect(controller.state.favoriteTrackIds, contains('yt_song1'));

      controller.deletePlaylist('p_imported_yt', removeOnlineTracks: true);

      // yt_song1 is in favorites, so it must NOT be removed
      final remainingIds = controller.state.tracks.map((t) => t.id).toList();
      expect(remainingIds, contains('yt_song1'));
      expect(remainingIds, isNot(contains('spotify_song2')));
    });

    test('removeTrackFromLibrary removes track completely and cleans up playlists and favorites', () {
      controller.toggleFavorite('yt_song1');
      expect(controller.state.favoriteTrackIds, contains('yt_song1'));

      controller.removeTrackFromLibrary('yt_song1');

      // Removed from library
      expect(controller.state.tracks.any((t) => t.id == 'yt_song1'), isFalse);
      // Removed from custom playlist
      final p1 = controller.state.customPlaylists.firstWhere((p) => p.id == 'p_imported_yt');
      expect(p1.tracks.any((t) => t.id == 'yt_song1'), isFalse);
      // Removed from favorites
      expect(controller.state.favoriteTrackIds, isNot(contains('yt_song1')));
      expect(controller.state.statusMessage, contains('Removed "YouTube Song 1" from library'));
    });

    test('removeTracksBatch removes multiple tracks and cleans up correctly', () {
      controller.toggleFavorite('yt_song1');

      controller.removeTracksBatch(['yt_song1', 'spotify_song2']);

      expect(controller.state.tracks.any((t) => t.id == 'yt_song1'), isFalse);
      expect(controller.state.tracks.any((t) => t.id == 'spotify_song2'), isFalse);
      expect(controller.state.favoriteTrackIds, isNot(contains('yt_song1')));

      final p1 = controller.state.customPlaylists.firstWhere((p) => p.id == 'p_imported_yt');
      expect(p1.tracks.any((t) => t.id == 'yt_song1'), isFalse);
      expect(p1.tracks.any((t) => t.id == 'spotify_song2'), isFalse);
      expect(controller.state.statusMessage, contains('Removed 2 tracks from library'));
    });

    test('removeTrackFromPlaylist removes track only from playlist without deleting from library', () {
      controller.removeTrackFromPlaylist('p_imported_yt', 'yt_song1');

      final p1 = controller.state.customPlaylists.firstWhere((p) => p.id == 'p_imported_yt');
      expect(p1.tracks.any((t) => t.id == 'yt_song1'), isFalse);

      // Still in library!
      expect(controller.state.tracks.any((t) => t.id == 'yt_song1'), isTrue);
      expect(controller.state.statusMessage, contains('Removed "YouTube Song 1" from playlist'));
    });
  });

  group('Studio Track & Playlist Action Sheets UI Tests', () {
    const tOnline = Track(
      id: 'yt_ui_track',
      title: 'Stream Song',
      artist: 'Online Artist',
      album: 'Stream Hits',
      duration: Duration(minutes: 3),
      remoteUrl: 'https://youtube.com/stream',
    );

    testWidgets('StudioTrackActionSheet displays Remove from Playlist and Remove from Library', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      StudioTrackActionSheet.show(
                        context,
                        tOnline,
                        playlistId: 'p_test',
                      );
                    },
                    child: const Text('Open Sheet'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Remove from Playlist'), findsOneWidget);
      expect(find.text('Remove from Library'), findsOneWidget);
    });

    testWidgets('StudioPlaylistActionSheet delete dialog shows online tracks removal checkbox', (tester) async {
      final playlist = PlaylistModel(
        id: 'p_online',
        name: 'Online Mix',
        description: 'Test online playlist',
        tracks: [tOnline],
        isCustom: true,
        createdAt: DateTime(2026, 1, 1),
      );

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  return ElevatedButton(
                    onPressed: () {
                      StudioPlaylistActionSheet.showForPlaylist(
                        context,
                        playlist: playlist,
                      );
                    },
                    child: const Text('Open Playlist Sheet'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Playlist Sheet'));
      await tester.pumpAndSettle();

      // Tap Delete Playlist action
      await tester.tap(find.text('Delete Playlist'));
      await tester.pumpAndSettle();

      // Confirmation dialog should show
      expect(find.text('DELETE PLAYLIST?'), findsOneWidget);
      expect(find.text('Also remove 1 online track'), findsOneWidget);
      expect(find.text('Tracks saved in other playlists or favorites will be safely kept.'), findsOneWidget);
    });
  });
}
