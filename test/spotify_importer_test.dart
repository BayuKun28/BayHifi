import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/features/spotify_importer/domain/spotify_models.dart';
import 'package:baydev_hifi/features/spotify_importer/data/spotify_metadata_service.dart';

void main() {
  group('Spotify URL Parsing Tests', () {
    test('Correctly parses Spotify Track HTTP URL', () {
      const url = 'https://open.spotify.com/track/4cOdK2wGLETKBW3PvgPWqT?si=abc12345';
      final parsed = SpotifyParsedUrl.parse(url);

      expect(parsed, isNotNull);
      expect(parsed!.type, equals(SpotifyItemType.track));
      expect(parsed.id, equals('4cOdK2wGLETKBW3PvgPWqT'));
      expect(parsed.isValid, isTrue);
    });

    test('Correctly parses Spotify Track International URL (intl-id)', () {
      const url = 'https://open.spotify.com/intl-id/track/4cOdK2wGLETKBW3PvgPWqT';
      final parsed = SpotifyParsedUrl.parse(url);

      expect(parsed, isNotNull);
      expect(parsed!.type, equals(SpotifyItemType.track));
      expect(parsed.id, equals('4cOdK2wGLETKBW3PvgPWqT'));
      expect(parsed.isValid, isTrue);
    });

    test('Correctly parses Spotify Album URL', () {
      const url = 'https://open.spotify.com/album/4m2880jivSbbyEGAKfITCa';
      final parsed = SpotifyParsedUrl.parse(url);

      expect(parsed, isNotNull);
      expect(parsed!.type, equals(SpotifyItemType.album));
      expect(parsed.id, equals('4m2880jivSbbyEGAKfITCa'));
    });

    test('Correctly parses Spotify Playlist URL', () {
      const url = 'https://open.spotify.com/playlist/37i9dQZF1DXcBWIGoYBM5M?si=xyz';
      final parsed = SpotifyParsedUrl.parse(url);

      expect(parsed, isNotNull);
      expect(parsed!.type, equals(SpotifyItemType.playlist));
      expect(parsed.id, equals('37i9dQZF1DXcBWIGoYBM5M'));
    });

    test('Correctly parses Spotify URI scheme', () {
      const uri = 'spotify:track:4cOdK2wGLETKBW3PvgPWqT';
      final parsed = SpotifyParsedUrl.parse(uri);

      expect(parsed, isNotNull);
      expect(parsed!.type, equals(SpotifyItemType.track));
      expect(parsed.id, equals('4cOdK2wGLETKBW3PvgPWqT'));
    });

    test('Returns null for invalid or empty URL', () {
      expect(SpotifyParsedUrl.parse(''), isNull);
      expect(SpotifyParsedUrl.parse('https://google.com'), isNull);
      expect(SpotifyParsedUrl.parse('not_a_url'), isNull);
    });
  });

  group('Spotify Metadata Domain Tests', () {
    test('SpotifyTrack from JSON maps fields properly', () {
      final json = {
        'id': 'test_track_123',
        'name': 'Starboy',
        'artists': [
          {'name': 'The Weeknd'},
          {'name': 'Daft Punk'},
        ],
        'album': {
          'name': 'Starboy',
          'images': [
            {'url': 'https://i.scdn.co/image/ab67616d0000b2734718e2b124f79258be7bc452'},
          ],
          'release_date': '2016-11-25',
        },
        'duration_ms': 230453,
        'track_number': 1,
        'disc_number': 1,
        'external_ids': {'isrc': 'USUM71607833'},
      };

      final track = SpotifyTrack.fromJson(json);

      expect(track.id, equals('test_track_123'));
      expect(track.title, equals('Starboy'));
      expect(track.artist, equals('The Weeknd, Daft Punk'));
      expect(track.album, equals('Starboy'));
      expect(track.duration, equals(const Duration(milliseconds: 230453)));
      expect(track.releaseYear, equals(2016));
      expect(track.trackNumber, equals(1));
      expect(track.isrc, equals('USUM71607833'));

      final bayTrack = track.toTrack();
      expect(bayTrack.id, equals('spotify_test_track_123'));
      expect(bayTrack.title, equals('Starboy'));
      expect(bayTrack.remoteUrl, equals('spotify://track/test_track_123'));
    });

    test('SpotifyAlbum from JSON parses album and tracklist', () {
      final json = {
        'id': 'test_album_456',
        'name': 'Random Access Memories',
        'artists': [
          {'name': 'Daft Punk'},
        ],
        'images': [
          {'url': 'https://i.scdn.co/image/ram_cover'},
        ],
        'release_date': '2013-05-17',
        'total_tracks': 2,
        'tracks': {
          'items': [
            {
              'id': 't1',
              'name': 'Give Life Back to Music',
              'duration_ms': 275000,
              'artists': [
                {'name': 'Daft Punk'}
              ],
            },
            {
              'id': 't2',
              'name': 'Get Lucky',
              'duration_ms': 248000,
              'artists': [
                {'name': 'Daft Punk'},
                {'name': 'Pharrell Williams'}
              ],
            },
          ],
        },
      };

      final album = SpotifyAlbum.fromJson(json);

      expect(album.id, equals('test_album_456'));
      expect(album.title, equals('Random Access Memories'));
      expect(album.artist, equals('Daft Punk'));
      expect(album.releaseYear, equals(2013));
      expect(album.totalTracks, equals(2));
      expect(album.tracks.length, equals(2));
      expect(album.tracks[1].title, equals('Get Lucky'));
      expect(album.tracks[1].album, equals('Random Access Memories'));
    });
  });

  group('Spotify Embed Resolver Live Integration Tests', () {
    test('Resolves user playlist from Spotify embed HTML', () async {
      final service = SpotifyMetadataService.instance;
      final preview = await service.resolveUrl('https://open.spotify.com/playlist/2TN5J0vHF7Agw7Lg5DVEFZ');

      expect(preview, isNotNull);
      expect(preview!.title, equals('Pang'));
      expect(preview.type, equals(SpotifyItemType.playlist));
      expect(preview.trackCount, greaterThanOrEqualTo(18));
      expect(preview.tracks.first.title, equals('Anthem Part Two'));
      expect(preview.tracks.first.artist, equals('blink-182'));
      expect(preview.tracks.first.duration.inSeconds, equals(227));
    });

    test('Resolves single track from Spotify embed HTML', () async {
      final service = SpotifyMetadataService.instance;
      final preview = await service.resolveUrl('https://open.spotify.com/track/24CRDgNOgA72JLL7PHFjgB');

      expect(preview, isNotNull);
      expect(preview!.title, equals('Anthem Part Two'));
      expect(preview.type, equals(SpotifyItemType.track));
      expect(preview.trackCount, equals(1));
      expect(preview.tracks.first.artist, equals('blink-182'));
      expect(preview.tracks.first.duration.inSeconds, equals(227));
    });
  });
}

