import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/features/library/domain/instant_mix_engine.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';

void main() {
  group('InstantMixEngine Unit Tests', () {
    final mockTracks = [
      const Track(
        id: 'track_1',
        title: 'Master of Puppets',
        artist: 'Metallica',
        album: 'Master of Puppets',
        duration: Duration(minutes: 8, seconds: 35),
        genre: 'Heavy Metal',
        year: 1986,
        format: AudioFormat.flac,
        sampleRate: 96000,
        bitDepth: 24,
      ),
      const Track(
        id: 'track_2',
        title: 'Enter Sandman',
        artist: 'Metallica',
        album: 'Metallica (Black Album)',
        duration: Duration(minutes: 5, seconds: 31),
        genre: 'Heavy Metal / Hard Rock',
        year: 1991,
        format: AudioFormat.flac,
        sampleRate: 96000,
        bitDepth: 24,
      ),
      const Track(
        id: 'track_3',
        title: 'Peace Sells',
        artist: 'Megadeth',
        album: 'Peace Sells',
        duration: Duration(minutes: 4, seconds: 4),
        genre: 'Thrash Metal',
        year: 1986,
        format: AudioFormat.flac,
      ),
      const Track(
        id: 'track_4',
        title: 'Clair de Lune',
        artist: 'Claude Debussy',
        album: 'Suite Bergamasque',
        duration: Duration(minutes: 5, seconds: 0),
        genre: 'Classical / Piano',
        year: 1905,
        format: AudioFormat.flac,
      ),
      const Track(
        id: 'track_5',
        title: 'Nocturne in E-flat Major',
        artist: 'Frédéric Chopin',
        album: 'Nocturnes',
        duration: Duration(minutes: 4, seconds: 30),
        genre: 'Classical / Romantic',
        year: 1832,
        format: AudioFormat.flac,
      ),
      const Track(
        id: 'track_6',
        title: 'Get Lucky',
        artist: 'Daft Punk',
        album: 'Random Access Memories',
        duration: Duration(minutes: 4, seconds: 8),
        genre: 'Electronic / Funk',
        year: 2013,
        format: AudioFormat.flac,
        sampleRate: 88200,
        bitDepth: 24,
      ),
      const Track(
        id: 'track_7',
        title: 'Starboy',
        artist: 'The Weeknd',
        album: 'Starboy',
        duration: Duration(minutes: 3, seconds: 50),
        genre: 'R&B / Pop',
        year: 2016,
        format: AudioFormat.mp3,
      ),
      const Track(
        id: 'track_8',
        title: 'Blinding Lights',
        artist: 'The Weeknd',
        album: 'After Hours',
        duration: Duration(minutes: 3, seconds: 20),
        genre: 'Synthpop / R&B',
        year: 2020,
        format: AudioFormat.mp3,
      ),
      const Track(
        id: 'track_9',
        title: 'Comfortably Numb',
        artist: 'Pink Floyd',
        album: 'The Wall',
        duration: Duration(minutes: 6, seconds: 22),
        genre: 'Progressive Rock',
        year: 1979,
        format: AudioFormat.flac,
      ),
      const Track(
        id: 'track_10',
        title: 'One',
        artist: 'Metallica',
        album: '...And Justice for All',
        duration: Duration(minutes: 7, seconds: 27),
        genre: 'Heavy Metal',
        year: 1988,
        format: AudioFormat.flac,
      ),
      const Track(
        id: 'track_11',
        title: 'Holy Wars... The Punishment Due',
        artist: 'Megadeth',
        album: 'Rust in Peace',
        duration: Duration(minutes: 6, seconds: 32),
        genre: 'Thrash Metal',
        year: 1990,
        format: AudioFormat.flac,
      ),
      const Track(
        id: 'track_12',
        title: 'Gymnopédie No. 1',
        artist: 'Erik Satie',
        album: 'Gymnopédies',
        duration: Duration(minutes: 3, seconds: 15),
        genre: 'Classical / Ambient',
        year: 1888,
        format: AudioFormat.flac,
      ),
    ];

    test('Excludes seed track from the generated mix list', () {
      final engine = InstantMixEngine(random: Random(42));
      final seed = mockTracks[0]; // Master of Puppets

      final mix = engine.generateInstantMix(
        seedTrack: seed,
        pool: mockTracks,
        criteria: InstantMixCriteria.genre,
        count: 10,
      );

      expect(mix.any((t) => t.id == seed.id), isFalse);
    });

    test('Limits result count according to count parameter', () {
      final engine = InstantMixEngine(random: Random(42));
      final seed = mockTracks[0];

      final mix5 = engine.generateInstantMix(
        seedTrack: seed,
        pool: mockTracks,
        criteria: InstantMixCriteria.genre,
        count: 5,
      );
      expect(mix5.length, equals(5));

      final mix10 = engine.generateInstantMix(
        seedTrack: seed,
        pool: mockTracks,
        criteria: InstantMixCriteria.genre,
        count: 10,
      );
      expect(mix10.length, lessThanOrEqualTo(10));
    });

    test('Genre criteria prioritizes similar metal and rock tracks for metal seed', () {
      final engine = InstantMixEngine(random: Random(42));
      final seed = mockTracks[0]; // Metallica - Heavy Metal

      final mix = engine.generateInstantMix(
        seedTrack: seed,
        pool: mockTracks,
        criteria: InstantMixCriteria.genre,
        count: 5,
      );

      final topArtists = mix.take(3).map((t) => t.artist).toList();
      expect(topArtists.contains('Megadeth') || topArtists.contains('Metallica'), isTrue);
    });

    test('Mood criteria correctly matches Classical / Acoustic mood', () {
      final engine = InstantMixEngine(random: Random(42));
      final seed = mockTracks[3]; // Debussy - Classical

      final mix = engine.generateInstantMix(
        seedTrack: seed,
        pool: mockTracks,
        criteria: InstantMixCriteria.mood,
        targetMood: StudioMusicMood.chillAcoustic,
        count: 3,
      );

      final classicalArtists = mix.map((t) => t.artist).toList();
      expect(classicalArtists.contains('Frédéric Chopin') || classicalArtists.contains('Erik Satie'), isTrue);
    });

    test('Artist and Era criteria prioritizes matching artist and 1980s era', () {
      final engine = InstantMixEngine(random: Random(42));
      final seed = mockTracks[0]; // Metallica 1986

      final mix = engine.generateInstantMix(
        seedTrack: seed,
        pool: mockTracks,
        criteria: InstantMixCriteria.artistAndEra,
        count: 4,
      );

      final firstTrack = mix.first;
      expect(firstTrack.artist == 'Metallica' || (firstTrack.year != null && firstTrack.year! >= 1980 && firstTrack.year! <= 1995), isTrue);
    });

    test('generateQueueAdditions creates additions from pool', () {
      final engine = InstantMixEngine(random: Random(42));

      final additions = engine.generateQueueAdditions(
        currentTrack: mockTracks[5], // Daft Punk
        pool: mockTracks,
        criteria: InstantMixCriteria.smartRandom,
        count: 10,
      );

      expect(additions.isNotEmpty, isTrue);
      expect(additions.length, lessThanOrEqualTo(10));
      expect(additions.any((t) => t.id == mockTracks[5].id), isFalse);
    });

    test('Anti-repetition prevents 3 identical consecutive artists', () {
      final engine = InstantMixEngine(random: Random(42));
      final seed = mockTracks[0]; // Metallica

      final mix = engine.generateInstantMix(
        seedTrack: seed,
        pool: mockTracks,
        criteria: InstantMixCriteria.genre,
        count: 10,
      );

      int consecutive = 0;
      String? lastArtist;
      for (final t in mix) {
        if (t.artist == lastArtist) {
          consecutive++;
          expect(consecutive, lessThan(3));
        } else {
          lastArtist = t.artist;
          consecutive = 1;
        }
      }
    });
  });
}
