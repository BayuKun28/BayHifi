import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import 'package:baydev_hifi/core/database/local_persistence_service.dart';
import '../../player/domain/track.dart';
import '../../spotify_importer/data/audio_matcher_service.dart';
import '../../youtube_music/data/webm_to_ogg_remuxer.dart';
import '../domain/download_task.dart';
import 'audio_tagger_service.dart';

typedef DownloadProgressCallback = void Function(DownloadProgress progress);

/// High-performance Native Chunked Stream Downloader with Realtime Progress & Tag Injection
class NativeDownloadService {
  NativeDownloadService._();
  static final NativeDownloadService instance = NativeDownloadService._();

  final YoutubeExplode _yt = YoutubeExplode();
  final AudioMatcherService _matcher = AudioMatcherService.instance;
  final AudioTaggerService _tagger = AudioTaggerService.instance;

  /// Resolves the default music download directory across Android and Desktop platforms
  Future<Directory> getDownloadDirectory() async {
    Directory targetDir;
    if (Platform.isAndroid) {
      try {
        final extDirs = await getExternalStorageDirectories(type: StorageDirectory.music);
        if (extDirs != null && extDirs.isNotEmpty) {
          targetDir = Directory('${extDirs.first.path}/BaydevHiFi');
        } else {
          final docDir = await getApplicationDocumentsDirectory();
          targetDir = Directory('${docDir.path}/Music');
        }
      } catch (_) {
        final docDir = await getApplicationDocumentsDirectory();
        targetDir = Directory('${docDir.path}/Music');
      }
    } else if (Platform.isLinux || Platform.isMacOS) {
      final home = Platform.environment['HOME'];
      if (home != null && Directory('$home/Music').existsSync()) {
        targetDir = Directory('$home/Music/BaydevHiFi');
      } else {
        final docDir = await getApplicationDocumentsDirectory();
        targetDir = Directory('${docDir.path}/BaydevHiFi');
      }
    } else {
      final docDir = await getApplicationDocumentsDirectory();
      targetDir = Directory('${docDir.path}/BaydevHiFi');
    }

    if (!targetDir.existsSync()) {
      targetDir.createSync(recursive: true);
    }
    return targetDir;
  }

  /// Sanitizes track title and artist into a safe cross-platform file name
  String _sanitizeFileName(String raw) {
    final sanitized = raw
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return sanitized.isEmpty ? 'track' : sanitized;
  }

  /// Extracts YouTube video ID from a remoteUrl or videoId
  String? _extractVideoId(Track track) {
    if (track.remoteUrl != null && track.remoteUrl!.isNotEmpty) {
      final uri = Uri.tryParse(track.remoteUrl!);
      if (uri != null) {
        if (uri.queryParameters.containsKey('v')) {
          return uri.queryParameters['v'];
        }
        if (uri.host.contains('youtu.be') && uri.pathSegments.isNotEmpty) {
          return uri.pathSegments.first;
        }
      }
    }
    if (track.id.startsWith('yt_')) {
      return track.id.replaceFirst('yt_', '');
    }
    return null;
  }

  /// Executes full download pipeline for a track
  Future<Track> downloadTrack({
    required Track track,
    required DownloadProgressCallback onProgress,
    CancellationToken? cancellationToken,
  }) async {
    // 1. Resolve YouTube video ID (Match if Spotify/remote source)
    String? videoId = _extractVideoId(track);
    if (videoId == null) {
      onProgress(const DownloadProgress(
        statusText: 'Matching audio with YouTube Music...',
        fraction: 0.05,
      ));
      final match = await _matcher.matchTrack(track);
      if (match == null) {
        throw Exception('Could not find matching audio source for "${track.title}"');
      }
      videoId = match.videoId;
    }

    // 2. Fetch Stream Manifest
    onProgress(const DownloadProgress(
      statusText: 'Fetching high-bitrate stream manifest...',
      fraction: 0.10,
    ));

    final manifest = await _yt.videos.streamsClient.getManifest(videoId);
    final audioStreamInfo = manifest.audioOnly.withHighestBitrate();

    final isMp4 = audioStreamInfo.container.name.toLowerCase() == 'mp4';
    final ext = isMp4 ? 'm4a' : 'opus';
    final downloadDir = await getDownloadDirectory();
    final fileName = '${_sanitizeFileName(track.artist)} - ${_sanitizeFileName(track.title)}.$ext';
    final destinationFile = File('${downloadDir.path}/$fileName');

    // 3. Download Stream chunks & remux WebM Opus into compliant Ogg Opus
    final rawStream = _yt.videos.streamsClient.get(audioStreamInfo);
    final Stream<List<int>> stream = !isMp4
        ? WebmToOggRemuxer.remuxStream(rawStream)
        : rawStream;
    final totalBytes = audioStreamInfo.size.totalBytes;
    int downloadedBytes = 0;

    final sink = destinationFile.openWrite();
    final stopwatch = Stopwatch()..start();
    int lastSampleTime = 0;
    int lastSampleBytes = 0;
    double currentSpeed = 0.0;

    try {
      await for (final chunk in stream) {
        if (cancellationToken?.isCancelled == true) {
          await sink.close();
          if (destinationFile.existsSync()) destinationFile.deleteSync();
          throw Exception('Download cancelled by user');
        }

        sink.add(chunk);
        downloadedBytes += chunk.length;

        final elapsedMs = stopwatch.elapsedMilliseconds;
        if (elapsedMs - lastSampleTime >= 500) {
          final deltaBytes = downloadedBytes - lastSampleBytes;
          final deltaTimeSec = (elapsedMs - lastSampleTime) / 1000.0;
          currentSpeed = deltaBytes / deltaTimeSec;
          lastSampleTime = elapsedMs;
          lastSampleBytes = downloadedBytes;

          final fraction = totalBytes > 0
              ? (downloadedBytes / totalBytes).clamp(0.0, 0.92)
              : 0.5;

          onProgress(DownloadProgress(
            downloadedBytes: downloadedBytes,
            totalBytes: totalBytes,
            speedBytesPerSec: currentSpeed,
            fraction: fraction,
            statusText: 'Downloading stream: ${(fraction * 100).toStringAsFixed(0)}%',
          ));
        }
      }

      await sink.flush();
      await sink.close();
    } catch (e) {
      await sink.close();
      if (destinationFile.existsSync()) {
        try {
          destinationFile.deleteSync();
        } catch (_) {}
      }
      rethrow;
    } finally {
      stopwatch.stop();
    }

    // 4. Inject Studio Tags & Artwork
    onProgress(DownloadProgress(
      downloadedBytes: totalBytes,
      totalBytes: totalBytes,
      speedBytesPerSec: 0.0,
      fraction: 0.95,
      statusText: 'Embedding studio metadata & cover art...',
    ));

    await _tagger.tagAudioFile(
      filePath: destinationFile.path,
      track: track,
    );

    // 5. Create final local Track model
    final finalTrack = track.copyWith(
      filePath: destinationFile.path,
      fileSize: destinationFile.lengthSync(),
      format: ext == 'm4a' ? AudioFormat.unknown : AudioFormat.opus,
      lastModifiedMs: DateTime.now().millisecondsSinceEpoch,
    );

    // 6. Auto-index into LocalPersistenceService
    try {
      await LocalPersistenceService.instance.saveTrack(finalTrack);
    } catch (e) {
      debugPrint('[NativeDownloadService] Auto-index notice: $e');
    }

    onProgress(DownloadProgress(
      downloadedBytes: totalBytes,
      totalBytes: totalBytes,
      speedBytesPerSec: 0.0,
      fraction: 1.0,
      statusText: 'Download completed & indexed',
    ));

    return finalTrack;
  }
}

/// Simple cancellation token for stream downloads
class CancellationToken {
  bool _isCancelled = false;
  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }
}
