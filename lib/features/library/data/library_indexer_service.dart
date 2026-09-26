import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../player/domain/track.dart';
import '../data/local_audio_scanner.dart';

/// Representation of a candidate relocation match for a missing track
class MovedTrackMatch {
  final Track track;
  final String newFilePath;
  final double confidence; // 0.0 to 1.0
  final String matchReason;

  const MovedTrackMatch({
    required this.track,
    required this.newFilePath,
    required this.confidence,
    required this.matchReason,
  });
}

/// A cluster of duplicate tracks sharing the same title & artist identity
class DuplicateTrackGroup {
  final String key;
  final String normalizedTitle;
  final String normalizedArtist;
  final List<Track> tracks;
  final Track bestTrack;

  const DuplicateTrackGroup({
    required this.key,
    required this.normalizedTitle,
    required this.normalizedArtist,
    required this.tracks,
    required this.bestTrack,
  });

  /// Tracks recommended for removal (all tracks except the best quality one)
  List<Track> get redundantTracks => tracks.where((t) => t.id != bestTrack.id).toList();
}

/// Comprehensive Library Maintenance & Indexer Service
class LibraryIndexerService {
  static LibraryIndexerService? _instance;
  static LibraryIndexerService get instance => _instance ??= LibraryIndexerService._();

  LibraryIndexerService._();

  /// Asynchronously identify tracks whose physical audio file no longer exists on disk
  Future<List<Track>> findMissingTracks(List<Track> tracks) async {
    final missing = <Track>[];
    for (final track in tracks) {
      if (track.filePath == null || track.filePath!.isEmpty) {
        continue; // Skip remote streaming tracks
      }
      try {
        final file = File(track.filePath!);
        if (!await file.exists()) {
          missing.add(track);
        }
      } catch (e) {
        missing.add(track);
      }
    }
    return missing;
  }

  /// Search configured music folders to locate moved or renamed files for missing tracks
  Future<List<MovedTrackMatch>> findMovedTrackCandidates(
    List<Track> missingTracks,
    List<String> musicFolders,
  ) async {
    if (missingTracks.isEmpty || musicFolders.isEmpty) return [];

    final candidateFiles = <File>[];
    final supportedExtensions = LocalAudioScanner.supportedExtensions;

    // 1. Gather all existing audio files from configured music folders
    for (final folderPath in musicFolders) {
      try {
        final dir = Directory(folderPath);
        if (await dir.exists()) {
          await for (final entity in dir.list(recursive: true, followLinks: false)) {
            if (entity is File) {
              final ext = entity.path.toLowerCase().split('.').last;
              if (supportedExtensions.contains(ext)) {
                candidateFiles.add(entity);
              }
            }
          }
        }
      } catch (e) {
        debugPrint('[LibraryIndexer] Folder list notice for $folderPath: $e');
      }
    }

    if (candidateFiles.isEmpty) return [];

    final results = <MovedTrackMatch>[];

    // 2. Match each missing track against candidates
    for (final missing in missingTracks) {
      final missingTitle = _normalizeString(missing.title);
      final missingArtist = _normalizeString(missing.artist);
      final missingBaseName = _extractBaseName(missing.filePath ?? '');

      MovedTrackMatch? bestMatch;

      for (final candidate in candidateFiles) {
        final candidatePath = candidate.path;
        final candidateBaseName = _extractBaseName(candidatePath);

        // A. Exact Base Filename Match (e.g. file was moved to another folder)
        if (missingBaseName.isNotEmpty &&
            _normalizeString(candidateBaseName) == _normalizeString(missingBaseName)) {
          bestMatch = MovedTrackMatch(
            track: missing,
            newFilePath: candidatePath,
            confidence: 0.95,
            matchReason: 'Identical file name in new folder',
          );
          break;
        }

        // B. Match by normalized title & artist in file name
        final normCandBase = _normalizeString(candidateBaseName);
        if (missingTitle.isNotEmpty && normCandBase.contains(missingTitle)) {
          if (missingArtist.isNotEmpty && normCandBase.contains(missingArtist)) {
            bestMatch = MovedTrackMatch(
              track: missing,
              newFilePath: candidatePath,
              confidence: 0.88,
              matchReason: 'Title & Artist match in file name',
            );
            break;
          } else {
            bestMatch = MovedTrackMatch(
              track: missing,
              newFilePath: candidatePath,
              confidence: 0.70,
              matchReason: 'Title match in file name',
            );
          }
        }
      }

      if (bestMatch != null) {
        results.add(bestMatch);
      }
    }

    return results;
  }

  /// Scan library for duplicate audio tracks and rank them by audiophile fidelity
  List<DuplicateTrackGroup> findDuplicates(List<Track> tracks) {
    final Map<String, List<Track>> groups = {};

    for (final track in tracks) {
      final normTitle = _normalizeString(track.title);
      final normArtist = _normalizeString(track.artist);
      if (normTitle.isEmpty) continue;

      final key = '$normTitle###$normArtist';
      groups.putIfAbsent(key, () => []).add(track);
    }

    final duplicateGroups = <DuplicateTrackGroup>[];

    for (final entry in groups.entries) {
      if (entry.value.length > 1) {
        final groupTracks = entry.value;
        // Sort descending by audio quality score
        groupTracks.sort((a, b) => computeQualityScore(b).compareTo(computeQualityScore(a)));

        final first = groupTracks.first;
        final normTitle = _normalizeString(first.title);
        final normArtist = _normalizeString(first.artist);

        duplicateGroups.add(
          DuplicateTrackGroup(
            key: entry.key,
            normalizedTitle: normTitle,
            normalizedArtist: normArtist,
            tracks: groupTracks,
            bestTrack: groupTracks.first,
          ),
        );
      }
    }

    // Sort groups by title
    duplicateGroups.sort((a, b) => a.normalizedTitle.compareTo(b.normalizedTitle));
    return duplicateGroups;
  }

  /// Compute audio fidelity rating score for duplicate ranking
  int computeQualityScore(Track track) {
    int score = 0;
    final format = track.format.name.toLowerCase();
    final isLossless = track.isHiRes || format == 'flac' || format == 'wav' || format == 'dsd' || format == 'alac';

    if (isLossless) {
      score += 10000;
      score += (track.bitDepth ?? 16) * 100;
      score += (track.sampleRate ?? 44100) ~/ 1000;
    } else {
      score += 1000;
      score += (track.bitrate ?? 128) * 2;
    }

    // Prefer files with embedded cover art
    if ((track.albumArtBytes != null && track.albumArtBytes!.isNotEmpty) ||
        (track.albumArtUrl != null && track.albumArtUrl!.isNotEmpty)) {
      score += 50;
    }

    // Prefer files with lyrics
    if (track.lyrics != null && track.lyrics!.isNotEmpty) {
      score += 30;
    }

    return score;
  }

  String _normalizeString(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _extractBaseName(String filePath) {
    if (filePath.isEmpty) return '';
    final lastSegment = filePath.split(Platform.pathSeparator).last;
    final dotIndex = lastSegment.lastIndexOf('.');
    if (dotIndex > 0) {
      return lastSegment.substring(0, dotIndex);
    }
    return lastSegment;
  }
}
