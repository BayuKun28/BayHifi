import 'package:flutter/foundation.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../player/domain/track.dart';
import '../domain/spotify_models.dart';

/// Result of matching a Spotify track to a YouTube audio stream
@immutable
class MatchedAudioResult {
  final String videoId;
  final String videoTitle;
  final String channelTitle;
  final Duration duration;
  final double matchScore;
  final String? audioStreamUrl;

  const MatchedAudioResult({
    required this.videoId,
    required this.videoTitle,
    required this.channelTitle,
    required this.duration,
    required this.matchScore,
    this.audioStreamUrl,
  });
}

/// Intelligent matcher that finds the most accurate YouTube / YouTube Music audio stream for any given track metadata.
class AudioMatcherService {
  AudioMatcherService._();
  static final AudioMatcherService instance = AudioMatcherService._();

  final YoutubeExplode _yt = YoutubeExplode();

  /// Matches a SpotifyTrack to the best available YouTube audio stream.
  Future<MatchedAudioResult?> matchSpotifyTrack(SpotifyTrack track) async {
    return matchMetadata(
      title: track.title,
      artist: track.artist,
      duration: track.duration,
      album: track.album,
      isrc: track.isrc,
    );
  }

  /// Matches a Baydev Track model to the best available YouTube audio stream.
  Future<MatchedAudioResult?> matchTrack(Track track) async {
    return matchMetadata(
      title: track.title,
      artist: track.artist,
      duration: track.duration,
      album: track.album,
    );
  }

  /// Finds and ranks matching YouTube videos based on metadata heuristics.
  Future<MatchedAudioResult?> matchMetadata({
    required String title,
    required String artist,
    required Duration duration,
    String? album,
    String? isrc,
  }) async {
    try {
      final cleanTitle = _cleanQuery(title);
      final cleanArtist = _cleanQuery(artist);

      // 1. Build queries in order of precision
      final queries = [
        '$cleanArtist - $cleanTitle official audio',
        '$cleanArtist - $cleanTitle',
        '$cleanTitle $cleanArtist',
      ];

      final candidates = <Video>[];
      final seenIds = <String>{};

      for (final q in queries) {
        try {
          final results = await _yt.search.search(q);
          for (final v in results) {
            if (seenIds.add(v.id.value)) {
              candidates.add(v);
            }
            if (candidates.length >= 8) break;
          }
        } catch (e) {
          debugPrint('[AudioMatcherService] Search query "$q" error: $e');
        }
        if (candidates.length >= 6) break;
      }

      if (candidates.isEmpty) return null;

      // 2. Score each candidate
      MatchedAudioResult? bestMatch;
      double highestScore = -100.0;

      for (final video in candidates) {
        final score = _calculateScore(
          targetTitle: title,
          targetArtist: artist,
          targetDuration: duration,
          candidateVideo: video,
        );

        if (score > highestScore) {
          highestScore = score;
          bestMatch = MatchedAudioResult(
            videoId: video.id.value,
            videoTitle: video.title,
            channelTitle: video.author,
            duration: video.duration ?? Duration.zero,
            matchScore: score,
          );
        }
      }

      return bestMatch;
    } catch (e, st) {
      debugPrint('[AudioMatcherService] Matching error: $e\n$st');
      return null;
    }
  }

  /// Calculates a heuristic match score between 0.0 and 100.0
  double _calculateScore({
    required String targetTitle,
    required String targetArtist,
    required Duration targetDuration,
    required Video candidateVideo,
  }) {
    double score = 50.0;

    final videoTitleLower = candidateVideo.title.toLowerCase();
    final videoAuthorLower = candidateVideo.author.toLowerCase();
    final targetTitleLower = targetTitle.toLowerCase();
    final targetArtistLower = targetArtist.toLowerCase();

    // ─── 1. Duration Delta Scoring ──────────────────────────────────────────
    if (targetDuration > Duration.zero && candidateVideo.duration != null) {
      final deltaSeconds =
          (candidateVideo.duration!.inSeconds - targetDuration.inSeconds).abs();
      if (deltaSeconds <= 2) {
        score += 35.0; // Excellent duration match
      } else if (deltaSeconds <= 5) {
        score += 25.0;
      } else if (deltaSeconds <= 12) {
        score += 10.0;
      } else if (deltaSeconds > 45) {
        score -= 40.0; // Likely a music video with long intro/outro or full album
      }
    }

    // ─── 2. Title & Artist Keyword Overlap ───────────────────────────────────
    final titleTokens = _extractTokens(targetTitleLower);
    final artistTokens = _extractTokens(targetArtistLower);

    int titleTokensFound = 0;
    for (final t in titleTokens) {
      if (videoTitleLower.contains(t)) {
        titleTokensFound++;
      }
    }
    if (titleTokens.isNotEmpty) {
      score += (titleTokensFound / titleTokens.length) * 25.0;
    }

    bool artistMatched = false;
    for (final a in artistTokens) {
      if (videoAuthorLower.contains(a) || videoTitleLower.contains(a)) {
        artistMatched = true;
        break;
      }
    }
    if (artistMatched) {
      score += 20.0;
    }

    // ─── 3. Official Audio & Topic Channel Boost ────────────────────────────
    if (videoAuthorLower.endsWith(' - topic') ||
        videoAuthorLower.contains('official') ||
        videoTitleLower.contains('official audio') ||
        videoTitleLower.contains('provided to youtube')) {
      score += 15.0;
    }

    // ─── 4. Noise Keyword Penalties (Unless in original title) ────────────────
    final unwantedKeywords = [
      'cover',
      'karaoke',
      'instrumental',
      'parody',
      'reaction',
      'remix',
      '8d audio',
      'bass boosted',
      'live at',
      'live in',
      'concert',
      'tribute',
    ];

    for (final kw in unwantedKeywords) {
      if (videoTitleLower.contains(kw) && !targetTitleLower.contains(kw)) {
        score -= 30.0;
      }
    }

    return score.clamp(0.0, 100.0);
  }

  Set<String> _extractTokens(String text) {
    return text
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .split(RegExp(r'\s+'))
        .where((t) => t.length > 1 && !const {'the', 'a', 'an', 'and', 'feat', 'ft', 'prod'}.contains(t))
        .toSet();
  }

  String _cleanQuery(String input) {
    return input
        .replaceAll(RegExp(r'[\(\[\{].*?[\)\]\}]'), '') // remove parenthesized info
        .replaceAll(RegExp(r'[^\w\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
