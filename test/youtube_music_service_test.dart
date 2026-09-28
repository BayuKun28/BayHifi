import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/features/youtube_music/data/youtube_music_service.dart';

void main() {
  group('YouTubeMusicService Unit Tests', () {
    test('cleanMetadata sanitizes bracketed video suffixes and extracts artist - title', () {
      final res1 = YouTubeMusicService.cleanMetadata(
        'Eminem - Lose Yourself [Official Music Video]',
        'EminemVEVO',
      );
      expect(res1.artist, equals('Eminem'));
      expect(res1.title, equals('Lose Yourself'));

      final res2 = YouTubeMusicService.cleanMetadata(
        'Daft Punk - Get Lucky (Official Audio) ft. Pharrell Williams',
        'Daft Punk - Topic',
      );
      expect(res2.artist, equals('Daft Punk'));
      expect(res2.title, contains('Get Lucky'));

      final res3 = YouTubeMusicService.cleanMetadata(
        'Hotel California (2013 Remastered HD)',
        'Eagles - Topic',
      );
      expect(res3.artist, equals('Eagles'));
      expect(res3.title, equals('Hotel California'));
    });

    test('cleanMetadata handles colon separator "Artist : Title"', () {
      final res = YouTubeMusicService.cleanMetadata(
        'Aimer : Brave Shine [4K MV]',
        'Aimer Official Channel',
      );
      expect(res.artist, equals('Aimer'));
      expect(res.title, equals('Brave Shine'));
    });

    test('cleanMetadata strips leading numbers from track title', () {
      final res = YouTubeMusicService.cleanMetadata(
        '01. Bohemian Rhapsody',
        'Queen',
      );
      expect(res.artist, equals('Queen'));
      expect(res.title, equals('Bohemian Rhapsody'));
    });

    test('cleanMetadata fallbacks cleanly when no separator is present', () {
      final res = YouTubeMusicService.cleanMetadata(
        'Starboy (Lyric Video)',
        'The Weeknd VEVO',
      );
      expect(res.artist, equals('The Weeknd'));
      expect(res.title, equals('Starboy'));
    });

    test('cleanMetadata strips channel suffixes like VEVO and Topic', () {
      final res = YouTubeMusicService.cleanMetadata(
        'Song Title',
        'Artist Name - Topic',
      );
      expect(res.artist, equals('Artist Name'));
    });
  });
}
