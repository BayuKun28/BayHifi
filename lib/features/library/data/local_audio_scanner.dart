import 'dart:io';
import 'package:audio_metadata_reader/audio_metadata_reader.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import '../../player/domain/track.dart';

/// Scanner untuk menemukan file audio lokal dan mengekstrak format audiophile dengan caching diferensial
class LocalAudioScanner {
  const LocalAudioScanner();

  /// Daftar ekstensi file audio audiophile yang didukung
  static const supportedExtensions = {
    'flac',
    'wav',
    'mp3',
    'opus',
    'ogg',
    'alac',
    'dsf',
    'dff',
    'm4a',
    'aac',
    'aiff',
    'aif',
    'wma',
    'ape',
    'mp4',
    'webm'
  };

  /// Memindai beberapa path direktori lokal untuk file audio
  Future<List<Track>> scanPaths(
    List<String> paths, {
    Map<String, Track>? existingTracksByPath,
    void Function(int foundCount, String currentPath)? onProgress,
  }) async {
    final allTracks = <Track>[];
    for (final path in paths) {
      final dir = Directory(path);
      final tracks = await scanDirectory(
        dir,
        existingTracksByPath: existingTracksByPath,
        onProgress: (count, folder) {
          onProgress?.call(allTracks.length + count, folder);
        },
      );
      allTracks.addAll(tracks);
    }
    return allTracks;
  }

  /// Memindai direktori lokal untuk file audio secara rekursif dan tahan terhadap permission error
  Future<List<Track>> scanDirectory(
    Directory directory, {
    Map<String, Track>? existingTracksByPath,
    void Function(int foundCount, String currentPath)? onProgress,
  }) async {
    final tracks = <Track>[];

    try {
      final dirQueue = <Directory>[directory];
      final visitedPaths = <String>{};
      int processedCount = 0;

      while (dirQueue.isNotEmpty) {
        final currentDir = dirQueue.removeAt(0);
        final canonicalPath = currentDir.path;
        if (visitedPaths.contains(canonicalPath)) continue;
        visitedPaths.add(canonicalPath);

        final folderName = currentDir.path.split(Platform.pathSeparator).last;
        onProgress?.call(tracks.length, folderName);

        List<FileSystemEntity> entities = const [];
        try {
          entities = currentDir.listSync(followLinks: false);
        } catch (_) {
          try {
            entities = await currentDir.list(followLinks: false).toList();
          } catch (dirErr) {
            debugPrint('[LocalAudioScanner] Skipping unreadable folder ${currentDir.path}: $dirErr');
            continue;
          }
        }

        for (final entity in entities) {
          if (entity is Directory) {
            final dirName = entity.path.split(Platform.pathSeparator).last;
            // Abaikan direktori sistem tersembunyi
            if (!dirName.startsWith('.') && !dirName.startsWith('\$')) {
              dirQueue.add(entity);
            }
          } else if (entity is File) {
            final path = entity.path;
            final dotIdx = path.lastIndexOf('.');
            if (dotIdx != -1 && dotIdx < path.length - 1) {
              final ext = path.substring(dotIdx + 1).toLowerCase();
              if (supportedExtensions.contains(ext)) {
                // ─── DIFFERENTIAL / INCREMENTAL CACHE CHECK ───
                if (existingTracksByPath != null && existingTracksByPath.containsKey(path)) {
                  final cachedTrack = existingTracksByPath[path]!;
                  int currentLength = 0;
                  int currentModified = 0;
                  try {
                    final stat = entity.statSync();
                    currentLength = stat.size;
                    currentModified = stat.modified.millisecondsSinceEpoch;
                  } catch (_) {}

                  // Check if artwork is already cached or present on disk
                  bool hasValidArtwork = false;
                  if (cachedTrack.albumArtBytes != null && cachedTrack.albumArtBytes!.isNotEmpty) {
                    hasValidArtwork = true;
                  } else if (cachedTrack.albumArtUrl != null && cachedTrack.albumArtUrl!.isNotEmpty) {
                    try {
                      hasValidArtwork = File(cachedTrack.albumArtUrl!).existsSync();
                    } catch (_) {}
                  }

                  if (currentLength > 0 &&
                      cachedTrack.fileSize == currentLength &&
                      (cachedTrack.lastModifiedMs == null || cachedTrack.lastModifiedMs == currentModified) &&
                      hasValidArtwork) {
                    tracks.add(cachedTrack);
                    continue;
                  }
                }

                // File baru, dimodifikasi, atau belum memiliki cache artwork -> Ekstrak metadata
                final track = await _parseFileToTrack(entity, ext);
                if (track != null) {
                  tracks.add(track);
                  if (tracks.length % 5 == 0) {
                    onProgress?.call(tracks.length, folderName);
                  }
                }
              }
            }
            // Yield per file to maintain 60/120fps UI responsiveness
            await Future<void>.delayed(Duration.zero);
          }
        }

        processedCount++;
        if (processedCount % 5 == 0) {
          await Future<void>.delayed(Duration.zero);
        }
      }
    } catch (e) {
      debugPrint('[LocalAudioScanner] Error scanning directory: $e');
    }

    debugPrint('[LocalAudioScanner] Total audio files discovered: ${tracks.length} in ${directory.path}');
    return tracks;
  }

  /// Membaca daftar file terpilih dan mengekstrak metadata Track
  Future<List<Track>> parseFiles(List<File> files) async {
    final tracks = <Track>[];
    for (final file in files) {
      final path = file.path;
      final dotIdx = path.lastIndexOf('.');
      if (dotIdx != -1 && dotIdx < path.length - 1) {
        final ext = path.substring(dotIdx + 1).toLowerCase();
        if (supportedExtensions.contains(ext)) {
          final track = await _parseFileToTrack(file, ext);
          if (track != null) {
            tracks.add(track);
          }
        }
      }
    }
    return tracks;
  }

  /// Membaca single file audio dan mengekstrak metadata
  Future<Track?> parseFile(File file) async {
    final path = file.path;
    final dotIdx = path.lastIndexOf('.');
    if (dotIdx != -1 && dotIdx < path.length - 1) {
      final ext = path.substring(dotIdx + 1).toLowerCase();
      if (supportedExtensions.contains(ext)) {
        return _parseFileToTrack(file, ext);
      }
    }
    return null;
  }

  Future<Track?> _parseFileToTrack(File file, String extension) async {
    try {
      final fileName = file.uri.pathSegments.last;
      final nameWithoutExt = fileName.contains('.')
          ? fileName.substring(0, fileName.lastIndexOf('.'))
          : fileName;

      // Ekstraksi default artis & judul dari pola nama file "Artist - Title" jika tersedia
      String artist = 'Unknown Artist';
      String title = nameWithoutExt;

      if (nameWithoutExt.contains(' - ')) {
        final parts = nameWithoutExt.split(' - ');
        artist = parts[0].trim();
        title = parts.sublist(1).join(' - ').trim();
      }

      // Default nama album dari folder induk
      final parentFolder = file.parent.path.split(Platform.pathSeparator).last;
      String albumName = parentFolder.isNotEmpty && parentFolder != '.'
          ? parentFolder
          : 'Local Music';

      String? genre;
      int? year;
      int? trackNumber;
      Duration duration = const Duration(minutes: 3, seconds: 30);
      Uint8List? coverBytes;
      String? lyrics;

      // 1. Baca metadata ID3 / Vorbis / FLAC / MP4 menggunakan audio_metadata_reader
      try {
        final metadata = readMetadata(file, getImage: true);
        if (metadata.title != null && metadata.title!.trim().isNotEmpty) {
          title = metadata.title!.trim();
        }
        if (metadata.artist != null && metadata.artist!.trim().isNotEmpty) {
          artist = metadata.artist!.trim();
        }
        if (metadata.album != null && metadata.album!.trim().isNotEmpty) {
          albumName = metadata.album!.trim();
        }
        if (metadata.genres.isNotEmpty) {
          genre = metadata.genres.first.trim();
        }
        if (metadata.year != null) {
          year = metadata.year?.year;
        }
        if (metadata.trackNumber != null) {
          trackNumber = metadata.trackNumber;
        }
        if (metadata.duration != null && metadata.duration! > Duration.zero) {
          duration = metadata.duration!;
        }
        if (metadata.pictures.isNotEmpty) {
          coverBytes = metadata.pictures.first.bytes;
        }
        if (metadata.lyrics != null && metadata.lyrics!.trim().isNotEmpty) {
          lyrics = metadata.lyrics!.trim();
        }
      } catch (metaErr) {
        debugPrint('[LocalAudioScanner] Audio metadata reader notice for ${file.path}: $metaErr');
      }

      // 2. Fallback sidecar cover art jika tidak ada embedded image
      String? albumArtUrl;
      if (coverBytes == null) {
        final sidecarFile = _findSidecarCoverArtFile(file);
        if (sidecarFile != null) {
          try {
            coverBytes = sidecarFile.readAsBytesSync();
            albumArtUrl = sidecarFile.path;
          } catch (_) {}
        }
      }

      int fileLen = 0;
      int modifiedEpoch = 0;
      try {
        final stat = file.statSync();
        fileLen = stat.size;
        modifiedEpoch = stat.modified.millisecondsSinceEpoch;
      } catch (_) {}

      // 3. Cache extracted embedded cover image to disk for instant restoration
      if (albumArtUrl == null && coverBytes != null && coverBytes.isNotEmpty) {
        try {
          final cacheDir = await getApplicationDocumentsDirectory();
          final coversDir = Directory('${cacheDir.path}/covers');
          if (!coversDir.existsSync()) {
            coversDir.createSync(recursive: true);
          }
          final cacheFile = File('${coversDir.path}/art_${file.path.hashCode.abs()}_$fileLen.jpg');
          if (!cacheFile.existsSync()) {
            await cacheFile.writeAsBytes(coverBytes, flush: true);
          }
          albumArtUrl = cacheFile.path;
        } catch (cacheErr) {
          debugPrint('[LocalAudioScanner] Error writing cover art cache: $cacheErr');
        }
      }

      // 4. Fallback sidecar .lrc jika tidak ada embedded lyrics
      lyrics ??= _findSidecarLyrics(file);

      // Format audio & estimasi audiophile spec
      final fmt = _resolveFormat(extension);
      int? sampleRate;
      int? bitDepth;

      if (fmt == AudioFormat.flac) {
        sampleRate = 96000;
        bitDepth = 24;
      } else if (fmt == AudioFormat.wav) {
        sampleRate = 44100;
        bitDepth = 16;
      } else if (fmt == AudioFormat.dsd) {
        sampleRate = 2822400; // DSD64
        bitDepth = 1;
      } else {
        sampleRate = 44100;
        bitDepth = 16;
      }

      final trackId = 'local_${file.path.hashCode}_$fileLen';

      return Track(
        id: trackId,
        title: _beautifyTitle(title),
        artist: artist,
        album: albumName,
        duration: duration,
        filePath: file.path,
        albumArtBytes: coverBytes,
        albumArtUrl: albumArtUrl,
        format: fmt,
        sampleRate: sampleRate,
        bitDepth: bitDepth,
        genre: genre,
        year: year,
        trackNumber: trackNumber,
        lyrics: lyrics,
        lastModifiedMs: modifiedEpoch,
        fileSize: fileLen,
      );
    } catch (e) {
      debugPrint('[LocalAudioScanner] Failed parsing file ${file.path}: $e');
      return null;
    }
  }

  /// Cari file cover image yang berdampingan di direktori yang sama (sidecar cover)
  static File? _findSidecarCoverArtFile(File audioFile) {
    try {
      final parent = audioFile.parent;
      const candidates = [
        'cover.jpg', 'cover.png', 'cover.jpeg',
        'folder.jpg', 'folder.png', 'folder.jpeg',
        'front.jpg', 'front.png', 'front.jpeg',
        'albumart.jpg', 'albumart.png', 'album.jpg', 'album.png',
      ];
      for (final name in candidates) {
        final imgFile = File('${parent.path}${Platform.pathSeparator}$name');
        if (imgFile.existsSync()) {
          return imgFile;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Ekstraksi cover art secara on-demand jika lagu belum memiliki artwork
  static Future<Track> extractAndCacheCoverArt(Track track) async {
    if ((track.albumArtBytes != null && track.albumArtBytes!.isNotEmpty) ||
        (track.albumArtUrl != null && track.albumArtUrl!.isNotEmpty)) {
      return track;
    }
    if (track.filePath == null || track.filePath!.isEmpty) {
      return track;
    }

    try {
      final file = File(track.filePath!);
      if (!file.existsSync()) return track;

      Uint8List? coverBytes;
      String? albumArtUrl;

      try {
        final metadata = readMetadata(file, getImage: true);
        if (metadata.pictures.isNotEmpty) {
          coverBytes = metadata.pictures.first.bytes;
        }
      } catch (_) {}

      if (coverBytes == null) {
        final sidecar = _findSidecarCoverArtFile(file);
        if (sidecar != null) {
          coverBytes = sidecar.readAsBytesSync();
          albumArtUrl = sidecar.path;
        }
      }

      if (albumArtUrl == null && coverBytes != null && coverBytes.isNotEmpty) {
        final cacheDir = await getApplicationDocumentsDirectory();
        final coversDir = Directory('${cacheDir.path}/covers');
        if (!coversDir.existsSync()) {
          coversDir.createSync(recursive: true);
        }
        final cacheFile = File('${coversDir.path}/art_${file.path.hashCode.abs()}_${track.fileSize ?? 0}.jpg');
        if (!cacheFile.existsSync()) {
          await cacheFile.writeAsBytes(coverBytes, flush: true);
        }
        albumArtUrl = cacheFile.path;
      }

      if (coverBytes != null || albumArtUrl != null) {
        return track.copyWith(
          albumArtBytes: coverBytes,
          albumArtUrl: albumArtUrl,
        );
      }
    } catch (e) {
      debugPrint('[LocalAudioScanner] Error extracting on-demand cover: $e');
    }

    return track;
  }

  /// Cari file lirik .lrc yang berdampingan dengan file audio
  static String? _findSidecarLyrics(File audioFile) {
    try {
      final path = audioFile.path;
      final dotIdx = path.lastIndexOf('.');
      if (dotIdx != -1) {
        final lrcPath = '${path.substring(0, dotIdx)}.lrc';
        final lrcFile = File(lrcPath);
        if (lrcFile.existsSync()) {
          return lrcFile.readAsStringSync();
        }
      }
    } catch (_) {}
    return null;
  }

  static String _beautifyTitle(String rawTitle) {
    return rawTitle.replaceAll('_', ' ');
  }

  static AudioFormat _resolveFormat(String ext) {
    switch (ext.toLowerCase()) {
      case 'flac':
        return AudioFormat.flac;
      case 'wav':
      case 'aiff':
      case 'aif':
        return AudioFormat.wav;
      case 'mp3':
      case 'wma':
      case 'ape':
        return AudioFormat.mp3;
      case 'opus':
        return AudioFormat.opus;
      case 'ogg':
      case 'webm':
        return AudioFormat.ogg;
      case 'alac':
      case 'm4a':
      case 'aac':
      case 'mp4':
        return AudioFormat.alac;
      case 'dsf':
      case 'dff':
        return AudioFormat.dsd;
      default:
        return AudioFormat.unknown;
    }
  }

  /// Koleksi track demo bawaan (dikembalikan kosong sesuai request user untuk library murni direktori lokal)
  static List<Track> get defaultLocalTracks => const [];
}
