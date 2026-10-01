import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/library/data/online_metadata_service.dart';

void main() {
  group('QuerySanitizer Tests', () {
    test('Cleans extensions, bracket metadata, and track numbers from dirty queries', () {
      expect(
        QuerySanitizer.cleanQuery('01 - Queen - Bohemian Rhapsody (Official Audio) [320kbps].mp3'),
        'Queen - Bohemian Rhapsody',
      );

      expect(
        QuerySanitizer.cleanQuery('02. Alan_Walker_Faded_[FLAC].flac'),
        'Alan Walker Faded',
      );

      expect(
        QuerySanitizer.cleanQuery('Track 05 - Hotel California (Remastered 2021).wav'),
        'Hotel California',
      );

      expect(
        QuerySanitizer.cleanQuery('song_title_with_underscores.m4a'),
        'song title with underscores',
      );
    });

    test('Extracts artist and title from hyphenated filename', () {
      final res1 = QuerySanitizer.extractArtistAndTitle('01 - Daft Punk - Get Lucky.mp3');
      expect(res1.artist, 'Daft Punk');
      expect(res1.title, 'Get Lucky');

      final res2 = QuerySanitizer.extractArtistAndTitle('UnknownSingleSong.flac');
      expect(res2.artist, isNull);
      expect(res2.title, 'UnknownSingleSong');
    });
  });

  group('OnlineMetadataCandidate Tests', () {
    test('Converts candidate to AudioTagData with downloaded artwork and lyrics', () {
      const candidate = OnlineMetadataCandidate(
        title: 'Bohemian Rhapsody',
        artist: 'Queen',
        album: 'A Night at the Opera',
        albumArtist: 'Queen',
        genre: 'Rock',
        year: 1975,
        trackNumber: 11,
        trackTotal: 12,
        discNumber: 1,
        discTotal: 1,
        source: MetadataSource.iTunes,
        confidenceScore: 0.95,
        lyrics: '[00:01.00]Is this the real life?',
      );

      final dummyArt = Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xE0]);
      final tagData = candidate.toAudioTagData(
        downloadedArtwork: dummyArt,
        artworkMime: 'image/jpeg',
      );

      expect(tagData.title, 'Bohemian Rhapsody');
      expect(tagData.artist, 'Queen');
      expect(tagData.album, 'A Night at the Opera');
      expect(tagData.genre, 'Rock');
      expect(tagData.year, 1975);
      expect(tagData.trackNumber, 11);
      expect(tagData.trackTotal, 12);
      expect(tagData.artworkBytes, dummyArt);
      expect(tagData.artworkMimeType, 'image/jpeg');
      expect(tagData.lyrics, '[00:01.00]Is this the real life?');
    });

    test('Applies candidate tags to Track object correctly', () {
      final original = Track(
        id: 'track_1',
        title: '01 - track01.mp3',
        artist: 'Unknown Artist',
        album: 'Unknown Album',
        duration: const Duration(minutes: 5, seconds: 55),
        filePath: '/music/track01.mp3',
      );

      const candidate = OnlineMetadataCandidate(
        title: 'Bohemian Rhapsody',
        artist: 'Queen',
        album: 'A Night at the Opera',
        year: 1975,
        genre: 'Rock',
        source: MetadataSource.iTunes,
      );

      final tagData = candidate.toAudioTagData();
      final updated = tagData.applyToTrack(original, newAlbumArtUrl: '/cached/art.jpg');

      expect(updated.title, 'Bohemian Rhapsody');
      expect(updated.artist, 'Queen');
      expect(updated.album, 'A Night at the Opera');
      expect(updated.year, 1975);
      expect(updated.genre, 'Rock');
      expect(updated.albumArtUrl, '/cached/art.jpg');
      expect(updated.filePath, '/music/track01.mp3');
    });
  });
}
