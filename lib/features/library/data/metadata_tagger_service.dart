import 'dart:io';
import 'package:audiotags/audiotags.dart' as at;
import 'package:audio_metadata_reader/audio_metadata_reader.dart' as amr;
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../player/domain/track.dart';

/// Representation of metadata tags for an audio track
class AudioTagData {
  final String? title;
  final String? artist;
  final String? album;
  final String? albumArtist;
  final String? genre;
  final int? year;
  final int? trackNumber;
  final int? trackTotal;
  final int? discNumber;
  final int? discTotal;
  final String? lyrics;
  final Uint8List? artworkBytes;
  final String? artworkMimeType;
  final String? filePath;

  const AudioTagData({
    this.title,
    this.artist,
    this.album,
    this.albumArtist,
    this.genre,
    this.year,
    this.trackNumber,
    this.trackTotal,
    this.discNumber,
    this.discTotal,
    this.lyrics,
    this.artworkBytes,
    this.artworkMimeType,
    this.filePath,
  });

  /// Create AudioTagData from an existing Track domain object
  factory AudioTagData.fromTrack(Track track) {
    return AudioTagData(
      title: track.title,
      artist: track.artist,
      album: track.album,
      albumArtist: track.albumArtist ?? track.artist,
      genre: track.genre,
      year: track.year,
      trackNumber: track.trackNumber,
      trackTotal: track.trackTotal,
      discNumber: track.discNumber,
      discTotal: track.discTotal,
      lyrics: track.lyrics,
      artworkBytes: track.albumArtBytes,
      filePath: track.filePath,
    );
  }

  /// Create updated Track object applying this tag data
  Track applyToTrack(Track original, {String? newAlbumArtUrl}) {
    return original.copyWith(
      title: (title != null && title!.trim().isNotEmpty) ? title!.trim() : original.title,
      artist: (artist != null && artist!.trim().isNotEmpty) ? artist!.trim() : original.artist,
      album: (album != null && album!.trim().isNotEmpty) ? album!.trim() : original.album,
      albumArtist: albumArtist?.trim(),
      genre: genre?.trim(),
      year: year,
      trackNumber: trackNumber,
      trackTotal: trackTotal,
      discNumber: discNumber,
      discTotal: discTotal,
      lyrics: lyrics?.trim(),
      albumArtBytes: artworkBytes ?? original.albumArtBytes,
      albumArtUrl: newAlbumArtUrl ?? original.albumArtUrl,
    );
  }

  AudioTagData copyWith({
    String? title,
    String? artist,
    String? album,
    String? albumArtist,
    String? genre,
    int? year,
    int? trackNumber,
    int? trackTotal,
    int? discNumber,
    int? discTotal,
    String? lyrics,
    Uint8List? artworkBytes,
    String? artworkMimeType,
    String? filePath,
    bool clearArtwork = false,
  }) {
    return AudioTagData(
      title: title ?? this.title,
      artist: artist ?? this.artist,
      album: album ?? this.album,
      albumArtist: albumArtist ?? this.albumArtist,
      genre: genre ?? this.genre,
      year: year ?? this.year,
      trackNumber: trackNumber ?? this.trackNumber,
      trackTotal: trackTotal ?? this.trackTotal,
      discNumber: discNumber ?? this.discNumber,
      discTotal: discTotal ?? this.discTotal,
      lyrics: lyrics ?? this.lyrics,
      artworkBytes: clearArtwork ? null : (artworkBytes ?? this.artworkBytes),
      artworkMimeType: clearArtwork ? null : (artworkMimeType ?? this.artworkMimeType),
      filePath: filePath ?? this.filePath,
    );
  }
}

/// Item to be processed in batch tagging
class BatchTaggingItem {
  final Track track;
  final AudioTagData tagData;

  const BatchTaggingItem({
    required this.track,
    required this.tagData,
  });
}

/// Result summary of batch tagging operation
class BatchTaggingResult {
  final int totalCount;
  final int successCount;
  final int failedCount;
  final List<String> failedFiles;
  final List<Track> updatedTracks;

  const BatchTaggingResult({
    required this.totalCount,
    required this.successCount,
    required this.failedCount,
    required this.failedFiles,
    required this.updatedTracks,
  });
}

/// Options for auto-numbering tracks in batch
class AutoNumberingOptions {
  final int startNumber;
  final bool setTotal;
  final int? totalCount;

  const AutoNumberingOptions({
    this.startNumber = 1,
    this.setTotal = true,
    this.totalCount,
  });
}

/// Helper to parse filename patterns such as "%artist% - %title%" or "%track% - %title%"
class TagPatternParser {
  const TagPatternParser._();

  /// Parse a filename into tag components according to a pattern
  static Map<String, String> parse(String filenameWithoutExtension, String pattern) {
    final result = <String, String>{};
    if (pattern.isEmpty || filenameWithoutExtension.isEmpty) return result;

    // Standard pattern delimiters: " - ", " . ", ".", "_", "-"
    if (pattern == '%artist% - %title%') {
      final parts = filenameWithoutExtension.split(' - ');
      if (parts.length >= 2) {
        result['artist'] = parts[0].trim();
        result['title'] = parts.sublist(1).join(' - ').trim();
      } else {
        result['title'] = filenameWithoutExtension.trim();
      }
    } else if (pattern == '%track% - %title%') {
      final parts = filenameWithoutExtension.split(' - ');
      if (parts.length >= 2) {
        result['track'] = parts[0].replaceAll(RegExp(r'\D'), '').trim();
        result['title'] = parts.sublist(1).join(' - ').trim();
      } else {
        result['title'] = filenameWithoutExtension.trim();
      }
    } else if (pattern == '%track%. %title%') {
      final match = RegExp(r'^(\d+)\.\s*(.*)$').firstMatch(filenameWithoutExtension);
      if (match != null) {
        result['track'] = match.group(1) ?? '';
        result['title'] = match.group(2) ?? '';
      } else {
        result['title'] = filenameWithoutExtension.trim();
      }
    } else if (pattern == '%track% - %artist% - %title%') {
      final parts = filenameWithoutExtension.split(' - ');
      if (parts.length >= 3) {
        result['track'] = parts[0].replaceAll(RegExp(r'\D'), '').trim();
        result['artist'] = parts[1].trim();
        result['title'] = parts.sublist(2).join(' - ').trim();
      } else if (parts.length == 2) {
        result['artist'] = parts[0].trim();
        result['title'] = parts[1].trim();
      } else {
        result['title'] = filenameWithoutExtension.trim();
      }
    } else if (pattern == '%title%') {
      result['title'] = filenameWithoutExtension.trim();
    }

    return result;
  }
}

/// Service for reading and writing audio metadata tags directly to physical files
class MetadataTaggerService {
  const MetadataTaggerService();

  /// Read metadata tags directly from the physical audio file
  Future<AudioTagData?> readPhysicalTags(String filePath) async {
    final file = File(filePath);
    if (!file.existsSync()) return null;

    try {
      // First attempt with audiotags plugin
      try {
        final tag = await at.AudioTags.read(filePath);
        if (tag != null) {
          Uint8List? artBytes;
          String? mimeType;
          if (tag.pictures.isNotEmpty) {
            artBytes = tag.pictures.first.bytes;
            mimeType = tag.pictures.first.mimeType?.name;
          }

          return AudioTagData(
            title: tag.title,
            artist: tag.trackArtist,
            album: tag.album,
            albumArtist: tag.albumArtist,
            genre: tag.genre,
            year: tag.year,
            trackNumber: tag.trackNumber,
            trackTotal: tag.trackTotal,
            discNumber: tag.discNumber,
            discTotal: tag.discTotal,
            lyrics: tag.lyrics,
            artworkBytes: artBytes,
            artworkMimeType: mimeType,
            filePath: filePath,
          );
        }
      } catch (pluginErr) {
        debugPrint('[MetadataTaggerService] audiotags read fallback: $pluginErr');
      }

      // Fallback with audio_metadata_reader
      final metadata = amr.readMetadata(file, getImage: true);
      Uint8List? coverBytes;
      if (metadata.pictures.isNotEmpty) {
        coverBytes = metadata.pictures.first.bytes;
      }

      return AudioTagData(
        title: metadata.title,
        artist: metadata.artist,
        album: metadata.album,
        albumArtist: metadata.albumArtist,
        genre: metadata.genres.isNotEmpty ? metadata.genres.first : null,
        year: metadata.year?.year,
        trackNumber: metadata.trackNumber,
        trackTotal: metadata.trackTotal,
        discNumber: metadata.discNumber,
        discTotal: null,
        lyrics: metadata.lyrics,
        artworkBytes: coverBytes,
        filePath: filePath,
      );
    } catch (e) {
      debugPrint('[MetadataTaggerService] Error reading tags for $filePath: $e');
      return null;
    }
  }

  /// Write metadata tags directly to the physical audio file
  Future<bool> writePhysicalTags(String filePath, AudioTagData tagData) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      debugPrint('[MetadataTaggerService] Cannot write tags, file does not exist: $filePath');
      return false;
    }

    try {
      final pictures = <at.Picture>[];
      if (tagData.artworkBytes != null && tagData.artworkBytes!.isNotEmpty) {
        final isPng = tagData.artworkMimeType == 'image/png' ||
            (tagData.artworkBytes!.length > 8 &&
                tagData.artworkBytes![0] == 0x89 &&
                tagData.artworkBytes![1] == 0x50);
        pictures.add(
          at.Picture(
            bytes: tagData.artworkBytes!,
            mimeType: isPng ? at.MimeType.png : at.MimeType.jpeg,
            pictureType: at.PictureType.coverFront,
          ),
        );
      }

      final tag = at.Tag(
        title: tagData.title,
        trackArtist: tagData.artist,
        album: tagData.album,
        albumArtist: tagData.albumArtist,
        genre: tagData.genre,
        year: tagData.year,
        trackNumber: tagData.trackNumber,
        trackTotal: tagData.trackTotal,
        discNumber: tagData.discNumber,
        discTotal: tagData.discTotal,
        lyrics: tagData.lyrics,
        pictures: pictures,
      );

      await at.AudioTags.write(filePath, tag);
      return true;
    } catch (e) {
      debugPrint('[MetadataTaggerService] Error writing physical tags to $filePath: $e');
      return false;
    }
  }

  /// Cache cover artwork to disk and return the cached image path
  Future<String?> cacheCoverArt(Uint8List artworkBytes, String trackKey) async {
    try {
      final appDir = await getApplicationDocumentsDirectory();
      final coversDir = Directory('${appDir.path}/covers');
      if (!coversDir.existsSync()) {
        coversDir.createSync(recursive: true);
      }
      final cacheFile = File('${coversDir.path}/art_tagger_${trackKey.hashCode.abs()}.jpg');
      await cacheFile.writeAsBytes(artworkBytes, flush: true);
      return cacheFile.path;
    } catch (e) {
      debugPrint('[MetadataTaggerService] Error caching cover art: $e');
      return null;
    }
  }

  /// Sequentially process batch tagging with progress callback
  Future<BatchTaggingResult> writeBatchTags(
    List<BatchTaggingItem> items, {
    void Function(int current, int total, String currentFile)? onProgress,
  }) async {
    int success = 0;
    int failed = 0;
    final failedFiles = <String>[];
    final updatedTracks = <Track>[];

    for (int i = 0; i < items.length; i++) {
      final item = items[i];
      final original = item.track;
      final tagData = item.tagData;

      onProgress?.call(i + 1, items.length, original.title);

      String? cachedArtPath;
      if (tagData.artworkBytes != null && tagData.artworkBytes!.isNotEmpty) {
        cachedArtPath = await cacheCoverArt(tagData.artworkBytes!, original.id);
      }

      bool writeOk = false;
      if (original.filePath != null && original.filePath!.isNotEmpty) {
        writeOk = await writePhysicalTags(original.filePath!, tagData);
      } else {
        // Virtual/cloud track update without physical write
        writeOk = true;
      }

      if (writeOk) {
        success++;
      } else {
        failed++;
        if (original.filePath != null) {
          failedFiles.add(original.filePath!);
        }
      }

      // Always produce the updated Track domain model for in-memory & persistence sync
      final updatedTrack = tagData.applyToTrack(original, newAlbumArtUrl: cachedArtPath);
      updatedTracks.add(updatedTrack);

      // Yield frame periodically to maintain UI responsiveness
      if (i % 3 == 0) {
        await Future<void>.delayed(Duration.zero);
      }
    }

    return BatchTaggingResult(
      totalCount: items.length,
      successCount: success,
      failedCount: failed,
      failedFiles: failedFiles,
      updatedTracks: updatedTracks,
    );
  }

  /// Apply auto-numbering sequence to a list of tracks
  static List<AudioTagData> generateAutoNumberedTags(
    List<Track> tracks,
    AutoNumberingOptions options, {
    AudioTagData? sharedOverrides,
  }) {
    final total = options.setTotal ? (options.totalCount ?? tracks.length) : null;
    final result = <AudioTagData>[];

    for (int i = 0; i < tracks.length; i++) {
      final t = tracks[i];
      final currentNum = options.startNumber + i;
      var base = AudioTagData.fromTrack(t);

      if (sharedOverrides != null) {
        base = base.copyWith(
          artist: sharedOverrides.artist?.isNotEmpty == true ? sharedOverrides.artist : null,
          album: sharedOverrides.album?.isNotEmpty == true ? sharedOverrides.album : null,
          albumArtist: sharedOverrides.albumArtist?.isNotEmpty == true ? sharedOverrides.albumArtist : null,
          genre: sharedOverrides.genre?.isNotEmpty == true ? sharedOverrides.genre : null,
          year: sharedOverrides.year,
          artworkBytes: sharedOverrides.artworkBytes,
          artworkMimeType: sharedOverrides.artworkMimeType,
        );
      }

      result.add(
        base.copyWith(
          trackNumber: currentNum,
          trackTotal: total,
        ),
      );
    }

    return result;
  }
}
