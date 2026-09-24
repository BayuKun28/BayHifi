import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/features/library/data/local_audio_scanner.dart';
import 'package:baydev_hifi/features/library/presentation/controllers/library_controller.dart';
import 'package:baydev_hifi/features/navidrome/domain/subsonic_models.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';

void main() {
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
    });

    test('defaultLocalTracks provides valid Hi-Res tracks', () {
      final tracks = LocalAudioScanner.defaultLocalTracks;
      expect(tracks, isNotEmpty);
      expect(tracks.length, greaterThanOrEqualTo(4));

      final flacTrack = tracks.firstWhere((t) => t.format == AudioFormat.flac);
      expect(flacTrack.isHiRes, isTrue);
      expect(flacTrack.sampleRate, greaterThanOrEqualTo(96000));
      expect(flacTrack.bitDepth, 24);

      final dsdTrack = tracks.firstWhere((t) => t.format == AudioFormat.dsd);
      expect(dsdTrack.isHiRes, isTrue);
      expect(dsdTrack.sampleRate, 2822400);
    });
  });

  group('UnifiedLibraryController Filtering & Search Tests', () {
    late UnifiedLibraryController controller;

    setUp(() {
      controller = UnifiedLibraryController();
    });

    test('initial state has all default local tracks', () {
      expect(controller.state.tracks.length, LocalAudioScanner.defaultLocalTracks.length);
      expect(controller.state.selectedFilter, LibrarySourceFilter.all);
      expect(controller.state.filteredTracks.length, LocalAudioScanner.defaultLocalTracks.length);
      expect(controller.state.offlineTracksCount, LocalAudioScanner.defaultLocalTracks.length);
      expect(controller.state.navidromeTracksCount, 0);
    });

    test('filters by Hi-Res Lossless correctly', () {
      controller.setFilter(LibrarySourceFilter.hiRes);
      expect(controller.state.selectedFilter, LibrarySourceFilter.hiRes);

      final hiResTracks = controller.state.filteredTracks;
      for (final track in hiResTracks) {
        expect(track.isHiRes, isTrue);
      }
      expect(hiResTracks.length, controller.state.hiResTracksCount);
    });

    test('filters by search query matching title or artist', () {
      controller.setSearchQuery('Mahler');
      expect(controller.state.filteredTracks.length, 1);
      expect(controller.state.filteredTracks.first.title, contains('Mahler'));

      controller.setSearchQuery('Eagles');
      expect(controller.state.filteredTracks.length, 1);
      expect(controller.state.filteredTracks.first.artist, 'Eagles');

      controller.setSearchQuery('non-existent-track-xyz');
      expect(controller.state.filteredTracks, isEmpty);

      controller.setSearchQuery('');
      expect(controller.state.filteredTracks.length, LocalAudioScanner.defaultLocalTracks.length);
    });

    test('manages Navidrome connection status and disconnection', () {
      expect(controller.state.navidromeConnectionStatus, NavidromeConnectionStatus.disconnected);
      expect(controller.state.navidromeConfig, isNull);

      controller.disconnectNavidrome();
      expect(controller.state.navidromeConnectionStatus, NavidromeConnectionStatus.disconnected);
      expect(controller.state.navidromeTracksCount, 0);
    });
  });
}
