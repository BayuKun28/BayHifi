import 'dart:io';
import '../../player/domain/track.dart';

/// Standard M3U / M3U8 playlist generator and exporter
class M3u8PlaylistService {
  const M3u8PlaylistService();

  /// Generates standard Extended M3U8 playlist content
  static String generateM3u8({
    required String playlistName,
    required List<Track> tracks,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('#EXTM3U');
    buffer.writeln('#PLAYLIST:$playlistName');

    for (final track in tracks) {
      final seconds = track.duration.inSeconds;
      final artist = track.artist.trim().isNotEmpty ? track.artist.trim() : 'Unknown Artist';
      final title = track.title.trim().isNotEmpty ? track.title.trim() : 'Unknown Title';
      final path = track.filePath ?? track.remoteUrl ?? '';

      buffer.writeln('#EXTINF:$seconds,$artist - $title');
      buffer.writeln(path);
    }

    return buffer.toString();
  }

  /// Saves the M3U8 string to target path
  static Future<File> saveToFile({
    required String filePath,
    required String m3u8Content,
  }) async {
    final file = File(filePath);
    await file.parent.create(recursive: true);
    return file.writeAsString(m3u8Content);
  }
}
