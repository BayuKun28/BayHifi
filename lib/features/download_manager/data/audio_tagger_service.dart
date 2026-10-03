import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../library/data/metadata_tagger_service.dart';
import '../../player/domain/track.dart';

/// Audio metadata tagging and studio artwork injection service for newly downloaded tracks
class AudioTaggerService {
  AudioTaggerService._();
  static final AudioTaggerService instance = AudioTaggerService._();

  final MetadataTaggerService _tagger = const MetadataTaggerService();

  /// Fetches artwork bytes from URL (with timeout and error handling)
  Future<Uint8List?> fetchArtworkBytes(String? url) async {
    if (url == null || url.trim().isEmpty) return null;
    try {
      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200 && response.bodyBytes.isNotEmpty) {
        return response.bodyBytes;
      }
    } catch (e) {
      debugPrint('[AudioTaggerService] Failed to fetch cover art from $url: $e');
    }
    return null;
  }

  /// Embeds comprehensive studio tags and front cover artwork into the audio file
  Future<bool> tagAudioFile({
    required String filePath,
    required Track track,
    Uint8List? explicitArtworkBytes,
  }) async {
    final file = File(filePath);
    if (!file.existsSync()) {
      debugPrint('[AudioTaggerService] File not found for tagging: $filePath');
      return false;
    }

    try {
      // 1. Resolve artwork bytes
      Uint8List? artBytes = explicitArtworkBytes ?? track.albumArtBytes;
      if (artBytes == null && track.albumArtUrl != null) {
        artBytes = await fetchArtworkBytes(track.albumArtUrl);
      }

      // 2. Prepare tag data
      final tagData = AudioTagData(
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
        artworkBytes: artBytes,
        filePath: filePath,
      );

      // 3. Write physical tags
      final result = await _tagger.writePhysicalTags(filePath, tagData);
      debugPrint('[AudioTaggerService] Tagging $filePath: ${result.status.name}');
      return result.isSuccess;
    } catch (e, st) {
      debugPrint('[AudioTaggerService] Error tagging file $filePath: $e\n$st');
      return false;
    }
  }
}
