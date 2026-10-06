import 'dart:math';
import '../../player/domain/track.dart';

/// Supported mix modes for Instant Mix generation.
enum InstantMixCriteria {
  genre,
  mood,
  artistAndEra,
  smartRandom,
}

/// Curated audiophile and studio mood categories.
enum StudioMusicMood {
  energetic,
  chillAcoustic,
  melancholic,
  audiophileMaster,
}

extension StudioMusicMoodExtension on StudioMusicMood {
  String get displayName {
    switch (this) {
      case StudioMusicMood.energetic:
        return 'Energetic & Upbeat';
      case StudioMusicMood.chillAcoustic:
        return 'Chill & Acoustic';
      case StudioMusicMood.melancholic:
        return 'Melancholic & Late Night';
      case StudioMusicMood.audiophileMaster:
        return 'Hi-Res Studio Masters';
    }
  }

  String get description {
    switch (this) {
      case StudioMusicMood.energetic:
        return 'Rock, EDM, Dance, and high-energy tracks';
      case StudioMusicMood.chillAcoustic:
        return 'Acoustic, Classical, Ambient, and soothing calm';
      case StudioMusicMood.melancholic:
        return 'R&B, Soul, Indie, Lo-Fi, and moody ballads';
      case StudioMusicMood.audiophileMaster:
        return '24-bit / 96kHz+, DSD, and lossless studio masters';
    }
  }
}

/// Queue placement options for adding tracks to active playback.
enum QueueAddPlacement {
  appendToEnd,
  playNext,
}

/// Deterministic domain engine for generating smart Instant Mixes and dynamic queue additions.
class InstantMixEngine {
  const InstantMixEngine({this.random});

  final Random? random;

  Random get _rng => random ?? Random();

  /// Generates an Instant Mix of tracks seeded by [seedTrack] from [pool].
  ///
  /// The resulting list does NOT include [seedTrack], which should be played first at index 0.
  List<Track> generateInstantMix({
    required Track seedTrack,
    required List<Track> pool,
    InstantMixCriteria criteria = InstantMixCriteria.genre,
    StudioMusicMood? targetMood,
    int count = 10,
    Set<String>? favoriteIds,
  }) {
    if (pool.isEmpty) return [];

    // Exclude the seed track from candidates
    final candidates = pool.where((t) => t.id != seedTrack.id).toList();
    if (candidates.isEmpty) return [];

    final scoredTracks = <_ScoredTrack>[];

    for (final candidate in candidates) {
      final score = _calculateScore(
        candidate: candidate,
        seed: seedTrack,
        criteria: criteria,
        targetMood: targetMood,
        isFavorite: favoriteIds?.contains(candidate.id) ?? false,
      );
      scoredTracks.add(_ScoredTrack(track: candidate, score: score));
    }

    // Sort descending by score
    scoredTracks.sort((a, b) => b.score.compareTo(a.score));

    // Anti-repetition dispersion selection
    final selected = _disperseSelection(
      scoredTracks: scoredTracks,
      seedTrack: seedTrack,
      targetCount: count,
    );

    return selected;
  }

  /// Generates dynamic track additions for Now Playing queue expansion.
  List<Track> generateQueueAdditions({
    Track? currentTrack,
    required List<Track> pool,
    InstantMixCriteria criteria = InstantMixCriteria.smartRandom,
    StudioMusicMood? targetMood,
    int count = 10,
    Set<String>? favoriteIds,
  }) {
    if (pool.isEmpty) return [];

    final seed = currentTrack ?? pool.first;
    return generateInstantMix(
      seedTrack: seed,
      pool: pool,
      criteria: criteria,
      targetMood: targetMood,
      count: count,
      favoriteIds: favoriteIds,
    );
  }

  double _calculateScore({
    required Track candidate,
    required Track seed,
    required InstantMixCriteria criteria,
    StudioMusicMood? targetMood,
    required bool isFavorite,
  }) {
    double score = 0.0;
    final randomJitter = (_rng.nextDouble() * 0.1) - 0.05;

    switch (criteria) {
      case InstantMixCriteria.genre:
        score += _scoreGenreSimilarity(candidate.genre, seed.genre) * 0.70;
        score += _scoreArtistAffinity(candidate, seed) * 0.15;
        score += _scoreEraAffinity(candidate, seed) * 0.15;
        break;

      case InstantMixCriteria.mood:
        final mood = targetMood ?? _inferMood(seed);
        score += _scoreMoodMatch(candidate, mood) * 0.75;
        score += _scoreGenreSimilarity(candidate.genre, seed.genre) * 0.25;
        break;

      case InstantMixCriteria.artistAndEra:
        score += _scoreArtistAffinity(candidate, seed) * 0.50;
        score += _scoreEraAffinity(candidate, seed) * 0.35;
        score += _scoreGenreSimilarity(candidate.genre, seed.genre) * 0.15;
        break;

      case InstantMixCriteria.smartRandom:
        score += _rng.nextDouble() * 0.60;
        score += _scoreGenreSimilarity(candidate.genre, seed.genre) * 0.25;
        if (isFavorite) score += 0.15;
        break;
    }

    // Small bonus for favorites in all modes
    if (isFavorite && criteria != InstantMixCriteria.smartRandom) {
      score += 0.05;
    }

    return score + randomJitter;
  }

  double _scoreGenreSimilarity(String? genreA, String? genreB) {
    if (genreA == null || genreB == null) return 0.2;
    final a = genreA.trim().toLowerCase();
    final b = genreB.trim().toLowerCase();
    if (a.isEmpty || b.isEmpty) return 0.2;

    if (a == b) return 1.0;

    final tokensA = a.split(RegExp(r'[/,;\s]+')).where((s) => s.isNotEmpty).toSet();
    final tokensB = b.split(RegExp(r'[/,;\s]+')).where((s) => s.isNotEmpty).toSet();

    final intersection = tokensA.intersection(tokensB);
    if (intersection.isNotEmpty) {
      return 0.75;
    }

    final clusterA = _genreCluster(a);
    final clusterB = _genreCluster(b);
    if (clusterA != null && clusterA == clusterB) {
      return 0.60;
    }

    return 0.10;
  }

  String? _genreCluster(String genre) {
    if (genre.contains('rock') || genre.contains('metal') || genre.contains('punk') || genre.contains('grunge')) {
      return 'rock_metal';
    }
    if (genre.contains('jazz') || genre.contains('blues') || genre.contains('soul') || genre.contains('funk')) {
      return 'jazz_soul';
    }
    if (genre.contains('electro') || genre.contains('edm') || genre.contains('dance') || genre.contains('house') || genre.contains('synth') || genre.contains('techno')) {
      return 'electronic';
    }
    if (genre.contains('classic') || genre.contains('symphon') || genre.contains('piano') || genre.contains('acoustic') || genre.contains('orchestr')) {
      return 'acoustic_classical';
    }
    if (genre.contains('hip hop') || genre.contains('rap') || genre.contains('trap') || genre.contains('r&b')) {
      return 'urban_hiphop';
    }
    if (genre.contains('pop') || genre.contains('indie') || genre.contains('folk') || genre.contains('vocal')) {
      return 'pop_indie';
    }
    if (genre.contains('ambient') || genre.contains('chill') || genre.contains('soundtrack') || genre.contains('ost')) {
      return 'ambient_soundtrack';
    }
    return null;
  }

  double _scoreArtistAffinity(Track candidate, Track seed) {
    final a1 = candidate.artist.trim().toLowerCase();
    final a2 = seed.artist.trim().toLowerCase();
    if (a1.isNotEmpty && a1 == a2) {
      return 1.0;
    }
    final alb1 = candidate.album.trim().toLowerCase();
    final alb2 = seed.album.trim().toLowerCase();
    if (alb1.isNotEmpty && alb1 == alb2) {
      return 0.85;
    }
    return 0.10;
  }

  double _scoreEraAffinity(Track candidate, Track seed) {
    if (candidate.year == null || seed.year == null) return 0.3;
    final diff = (candidate.year! - seed.year!).abs();
    if (diff == 0) return 1.0;
    if (diff <= 3) return 0.85;
    if (diff <= 7) return 0.65;
    if (diff <= 12) return 0.40;
    return 0.15;
  }

  double _scoreMoodMatch(Track candidate, StudioMusicMood mood) {
    final inferred = _inferMood(candidate);
    if (inferred == mood) return 1.0;

    switch (mood) {
      case StudioMusicMood.audiophileMaster:
        return candidate.isHiRes || candidate.format == AudioFormat.flac || candidate.format == AudioFormat.dsd
            ? 0.90
            : 0.20;
      case StudioMusicMood.chillAcoustic:
        return (inferred == StudioMusicMood.melancholic || inferred == StudioMusicMood.audiophileMaster) ? 0.60 : 0.15;
      case StudioMusicMood.melancholic:
        return (inferred == StudioMusicMood.chillAcoustic) ? 0.60 : 0.15;
      case StudioMusicMood.energetic:
        return 0.10;
    }
  }

  StudioMusicMood _inferMood(Track track) {
    if (track.isHiRes || track.format == AudioFormat.dsd) {
      return StudioMusicMood.audiophileMaster;
    }

    final genre = (track.genre ?? '').toLowerCase();
    if (genre.contains('rock') ||
        genre.contains('metal') ||
        genre.contains('edm') ||
        genre.contains('dance') ||
        genre.contains('electro') ||
        genre.contains('techno') ||
        genre.contains('house') ||
        genre.contains('trap')) {
      return StudioMusicMood.energetic;
    }

    if (genre.contains('acoustic') ||
        genre.contains('classic') ||
        genre.contains('piano') ||
        genre.contains('ambient') ||
        genre.contains('folk') ||
        genre.contains('instrumental') ||
        track.duration >= const Duration(minutes: 5)) {
      return StudioMusicMood.chillAcoustic;
    }

    if (genre.contains('r&b') ||
        genre.contains('soul') ||
        genre.contains('lo-fi') ||
        genre.contains('lofi') ||
        genre.contains('blues') ||
        genre.contains('ballad') ||
        genre.contains('indie')) {
      return StudioMusicMood.melancholic;
    }

    return StudioMusicMood.energetic;
  }

  /// Disperses tracks to avoid putting more than 2 consecutive tracks by the exact same artist.
  List<Track> _disperseSelection({
    required List<_ScoredTrack> scoredTracks,
    required Track seedTrack,
    required int targetCount,
  }) {
    final result = <Track>[];
    final remaining = List<_ScoredTrack>.from(scoredTracks);
    String? lastArtist = seedTrack.artist.trim().toLowerCase();
    int consecutiveArtistCount = 1;

    while (result.length < targetCount && remaining.isNotEmpty) {
      int pickIndex = -1;

      // Try finding the best candidate not exceeding consecutive artist limit
      for (int i = 0; i < remaining.length; i++) {
        final candArtist = remaining[i].track.artist.trim().toLowerCase();
        if (candArtist != lastArtist || consecutiveArtistCount < 2) {
          pickIndex = i;
          break;
        }
      }

      // If all remaining candidates are from the same artist, pick the top one
      if (pickIndex == -1) {
        pickIndex = 0;
      }

      final picked = remaining.removeAt(pickIndex);
      result.add(picked.track);

      final currentArtist = picked.track.artist.trim().toLowerCase();
      if (currentArtist == lastArtist) {
        consecutiveArtistCount++;
      } else {
        lastArtist = currentArtist;
        consecutiveArtistCount = 1;
      }
    }

    return result;
  }
}

class _ScoredTrack {
  final Track track;
  final double score;

  const _ScoredTrack({required this.track, required this.score});
}
