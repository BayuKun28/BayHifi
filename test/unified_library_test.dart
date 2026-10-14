import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/features/library/data/local_audio_scanner.dart';
import 'package:baydev_hifi/features/library/domain/library_collection_models.dart';
import 'package:baydev_hifi/features/library/presentation/controllers/library_controller.dart';
import 'package:baydev_hifi/features/navidrome/domain/subsonic_models.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SubsonicServerConfig & MD5 Auth Tests', () {
    test('sanitizes URL by removing trailing slashes', () {
      final config = SubsonicServerConfig(
        serverUrl: 'https://music.example.com///',
        username: 'audiophile',
        password: 'secretpassword',
      );
      expect(config.sanitizedUrl, 'https://music.example.com');
    });

    test('generates valid MD5 salt and token query parameters', () {
      final config = SubsonicServerConfig(
        serverUrl: 'https://music.example.com',
        username: 'audiophile',
        password: 'mypassword',
      );

      final params = config.getAuthQueryParams();
      expect(params['u'], 'audiophile');
      expect(params['v'], '1.16.1');
      expect(params['c'], 'BaydevHiFi');
      expect(params['f'], 'json');
      expect(params['s'], isNotEmpty);
      expect(params['t'], isNotEmpty);
      expect(params['t']!.length, 32); // MD5 hex length is 32 chars
    });

    test('builds direct lossless FLAC stream URL', () {
      final config = SubsonicServerConfig(
        serverUrl: 'http://192.168.1.100:4533',
        username: 'admin',
        password: 'adminpassword',
      );

      final streamUrl = config.buildStreamUrl('song-uuid-1234');
      expect(streamUrl, startsWith('http://192.168.1.100:4533/rest/stream.view'));
      expect(streamUrl, contains('id=song-uuid-1234'));
      expect(streamUrl, contains('format=raw')); // Bit-perfect direct stream
    });

    test('builds cover art URL with target size', () {
      final config = SubsonicServerConfig(
        serverUrl: 'http://192.168.1.100:4533',
        username: 'admin',
        password: 'adminpassword',
      );

      final coverUrl = config.buildCoverArtUrl('cover-uuid-5678', size: 500);
      expect(coverUrl, startsWith('http://192.168.1.100:4533/rest/getCoverArt.view'));
      expect(coverUrl, contains('id=cover-uuid-5678'));
      expect(coverUrl, contains('size=500'));
    });
  });

  group('LocalAudioScanner Tests', () {
    test('contains audiophile formats in supportedExtensions', () {
      expect(LocalAudioScanner.supportedExtensions, contains('flac'));
      expect(LocalAudioScanner.supportedExtensions, contains('wav'));
      expect(LocalAudioScanner.supportedExtensions, contains('dsf'));
      expect(LocalAudioScanner.supportedExtensions, contains('mp3'));
      expect(LocalAudioScanner.supportedExtensions, contains('alac'));
      expect(LocalAudioScanner.supportedExtensions, contains('opus'));
    });

    test('defaultLocalTracks is empty (pure custom user library)', () {
      final tracks = LocalAudioScanner.defaultLocalTracks;
      expect(tracks, isEmpty);
    });

    test('parseFile parses audio file correctly with title extraction', () async {
      const scanner = LocalAudioScanner();
      final tempFile = File('/tmp/music/Artist Name - Track Title.flac');
      final track = await scanner.parseFile(tempFile);

      expect(track, isNotNull);
      expect(track!.title, 'Track Title');
      expect(track.artist, 'Artist Name');
      expect(track.format, AudioFormat.flac);
      expect(track.sampleRate, 96000);
      expect(track.bitDepth, 24);
      expect(track.isHiRes, isTrue);
    });
  });

  group('UnifiedLibraryController Filtering & Collection Tests', () {
    late UnifiedLibraryController controller;

    final sampleCustomTracks = [
      const Track(
        id: 'cust_1',
        title: 'Symphony No. 5 in C Minor',
        artist: 'Ludwig van Beethoven',
        album: 'Beethoven: Symphonies',
        duration: Duration(minutes: 7, seconds: 20),
        filePath: '/storage/music/Beethoven/symphony5.flac',
        format: AudioFormat.flac,
        sampleRate: 192000,
        bitDepth: 24,
      ),
      const Track(
        id: 'cust_2',
        title: 'Hotel California',
        artist: 'Eagles',
        album: 'Hotel California',
        duration: Duration(minutes: 6, seconds: 30),
        filePath: '/storage/music/Eagles/hotel_california.wav',
        format: AudioFormat.wav,
        sampleRate: 44100,
        bitDepth: 16,
      ),
      const Track(
        id: 'cust_3',
        title: 'Take Five',
        artist: 'Dave Brubeck',
        album: 'Time Out',
        duration: Duration(minutes: 5, seconds: 24),
        filePath: '/storage/music/Brubeck/take_five.dsf',
        format: AudioFormat.dsd,
        sampleRate: 2822400,
        bitDepth: 1,
      ),
    ];

    setUp(() {
      controller = UnifiedLibraryController(
        initialTracks: sampleCustomTracks,
      );
    });

    test('initial state contains supplied custom tracks', () {
      expect(controller.state.tracks.length, 3);
      expect(controller.state.selectedFilter, LibrarySourceFilter.all);
      expect(controller.state.filteredTracks.length, 3);
      expect(controller.state.offlineTracksCount, 3);
      expect(controller.state.navidromeTracksCount, 0);
    });

    test('filters by Hi-Res Lossless correctly', () {
      controller.setFilter(LibrarySourceFilter.hiRes);
      expect(controller.state.selectedFilter, LibrarySourceFilter.hiRes);

      final hiResTracks = controller.state.filteredTracks;
      expect(hiResTracks.length, 2); // Beethoven (24-bit/192kHz) and Take Five (DSD)
      for (final track in hiResTracks) {
        expect(track.isHiRes, isTrue);
      }
    });

    test('filters by search query matching title or artist', () {
      controller.setSearchQuery('Beethoven');
      expect(controller.state.filteredTracks.length, 1);
      expect(controller.state.filteredTracks.first.title, contains('Symphony'));

      controller.setSearchQuery('Eagles');
      expect(controller.state.filteredTracks.length, 1);
      expect(controller.state.filteredTracks.first.artist, 'Eagles');

      controller.setSearchQuery('non-existent-track-xyz');
      expect(controller.state.filteredTracks, isEmpty);

      controller.setSearchQuery('');
      expect(controller.state.filteredTracks.length, 3);
    });

    test('sorts tracks by Title, Artist, Duration, and Hi-Res in both directions', () {
      // Sort by Title Ascending
      controller.setSortField(SortField.title);
      expect(controller.state.filteredTracks[0].title, 'Hotel California');
      expect(controller.state.filteredTracks[1].title, 'Symphony No. 5 in C Minor');
      expect(controller.state.filteredTracks[2].title, 'Take Five');

      // Sort by Title Descending
      controller.toggleSortDirection();
      expect(controller.state.filteredTracks[0].title, 'Take Five');
      expect(controller.state.filteredTracks[1].title, 'Symphony No. 5 in C Minor');
      expect(controller.state.filteredTracks[2].title, 'Hotel California');

      // Sort by Artist Ascending
      controller.toggleSortDirection(); // Back to Ascending
      controller.setSortField(SortField.artist);
      expect(controller.state.filteredTracks[0].artist, 'Dave Brubeck');
      expect(controller.state.filteredTracks[1].artist, 'Eagles');
      expect(controller.state.filteredTracks[2].artist, 'Ludwig van Beethoven');

      // Sort by Duration Descending
      controller.setSortDirection(SortDirection.descending);
      controller.setSortField(SortField.duration);
      expect(controller.state.filteredTracks[0].title, 'Symphony No. 5 in C Minor'); // 7m 20s
      expect(controller.state.filteredTracks[1].title, 'Hotel California'); // 6m 30s
      expect(controller.state.filteredTracks[2].title, 'Take Five'); // 5m 24s
    });

    test('extracts dynamic genres from track metadata and groups tracks', () {
      final customGenreTracks = [
        const Track(
          id: 'g1',
          title: 'So What',
          artist: 'Miles Davis',
          album: 'Kind of Blue',
          genre: 'Jazz',
          duration: Duration(minutes: 9, seconds: 22),
          filePath: '/music/jazz1.flac',
          format: AudioFormat.flac,
        ),
        const Track(
          id: 'g2',
          title: 'Master of Puppets',
          artist: 'Metallica',
          album: 'Master of Puppets',
          genre: 'Heavy Metal',
          duration: Duration(minutes: 8, seconds: 35),
          filePath: '/music/metal1.flac',
          format: AudioFormat.flac,
        ),
        const Track(
          id: 'g3',
          title: 'Autumn Leaves',
          artist: 'Cannonball Adderley',
          album: 'Somethin Else',
          genre: 'Jazz',
          duration: Duration(minutes: 10, seconds: 58),
          filePath: '/music/jazz2.flac',
          format: AudioFormat.flac,
        ),
      ];

      final genreController = UnifiedLibraryController(initialTracks: customGenreTracks);
      final genres = genreController.state.genres;

      expect(genres.length, 2);
      expect(genres.map((g) => g.name).toList(), containsAll(['Heavy Metal', 'Jazz']));

      final jazzGenre = genres.firstWhere((g) => g.name == 'Jazz');
      expect(jazzGenre.trackCount, 2);
      expect(jazzGenre.tracks.map((t) => t.title), containsAll(['So What', 'Autumn Leaves']));

      final metalGenre = genres.firstWhere((g) => g.name == 'Heavy Metal');
      expect(metalGenre.trackCount, 1);
      expect(metalGenre.tracks.first.title, 'Master of Puppets');
    });

    test('removes configured music folder and deletes custom playlist', () {
      controller.createPlaylist('Test Playlist', 'Desc');
      final pId = controller.state.customPlaylists.first.id;
      expect(controller.state.customPlaylists.length, 1);

      controller.deletePlaylist(pId);
      expect(controller.state.customPlaylists, isEmpty);

      controller.removeMusicFolder('/storage/music/Beethoven');
      expect(controller.state.configuredFolderPaths, isNot(contains('/storage/music/Beethoven')));
    });

    test('computes albums, artists, playlists, and folders correctly', () {
      expect(controller.state.albums.length, 3);
      expect(controller.state.artists.length, 3);
      expect(controller.state.playlists.length, greaterThanOrEqualTo(2)); // Favorites & HiRes Masters
      expect(controller.state.folders.length, 3); // Beethoven, Eagles, Brubeck
    });

    test('creates custom playlists and adds tracks', () {
      controller.createPlaylist('Late Night Jazz', 'Soft audiophile jazz');
      expect(controller.state.customPlaylists.length, 1);
      expect(controller.state.customPlaylists.first.name, 'Late Night Jazz');

      final playlistId = controller.state.customPlaylists.first.id;
      controller.addTrackToPlaylist(playlistId, sampleCustomTracks.first);

      final updated = controller.state.customPlaylists.firstWhere((p) => p.id == playlistId);
      expect(updated.tracks.length, 1);
      expect(updated.tracks.first.id, sampleCustomTracks.first.id);
    });

    test('clears library correctly', () async {
      await controller.clearLibrary();
      expect(controller.state.tracks, isEmpty);
      expect(controller.state.filteredTracks, isEmpty);
      expect(controller.state.totalTracksCount, 0);
    });

    test('serializes and deserializes caching fields (lastModifiedMs and fileSize)', () {
      const track = Track(
        id: 'cached_track_1',
        title: 'Cached Title',
        artist: 'Cached Artist',
        album: 'Cached Album',
        duration: Duration(minutes: 4, seconds: 12),
        filePath: '/music/cached.flac',
        sampleRate: 96000,
        bitDepth: 24,
        format: AudioFormat.flac,
        lastModifiedMs: 1727258400000,
        fileSize: 45120000,
      );

      final map = track.toMap();
      expect(map['lastModifiedMs'], 1727258400000);
      expect(map['fileSize'], 45120000);

      final restored = Track.fromMap(map);
      expect(restored.lastModifiedMs, 1727258400000);
      expect(restored.fileSize, 45120000);
      expect(restored.id, 'cached_track_1');
    });

    test('manages Navidrome connection status and disconnection', () {
      expect(controller.state.navidromeConnectionStatus, NavidromeConnectionStatus.disconnected);
      expect(controller.state.navidromeConfig, isNull);

      controller.disconnectNavidrome();
      expect(controller.state.navidromeConnectionStatus, NavidromeConnectionStatus.disconnected);
      expect(controller.state.navidromeTracksCount, 0);
    });

    test('serializes and filters server streaming tracks correctly', () {
      const serverTrack = Track(
        id: 'track-uuid-999',
        title: 'Server Masterpiece',
        artist: 'Studio Artist',
        album: 'Audiophile Vol 1',
        duration: Duration(minutes: 5),
        remoteUrl: '/api/library/stream/track-uuid-999',
        albumArtUrl: '/api/library/cover/track-uuid-999',
        format: AudioFormat.flac,
        sampleRate: 96000,
        bitDepth: 24,
      );

      final map = serverTrack.toMap();
      expect(map['remoteUrl'], '/api/library/stream/track-uuid-999');
      expect(map['albumArtUrl'], '/api/library/cover/track-uuid-999');

      final fromMap = Track.fromMap(map);
      expect(fromMap.remoteUrl, '/api/library/stream/track-uuid-999');
      expect(fromMap.albumArtUrl, '/api/library/cover/track-uuid-999');
      expect(fromMap.isHiRes, isTrue);
    });
  });
}

