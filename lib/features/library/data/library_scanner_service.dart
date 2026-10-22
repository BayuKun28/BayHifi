import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/database/local_persistence_service.dart';
import '../../../../core/storage/storage_permission_service.dart';
import '../../player/domain/track.dart';
import 'local_audio_scanner.dart';

/// Result object for scanning operations
class DirectoryScanResult {
  final List<Track> allTracks;
  final List<Track> newTracks;
  final String statusMessage;

  const DirectoryScanResult({
    required this.allTracks,
    required this.newTracks,
    required this.statusMessage,
  });
}

/// Service dedicated to local storage audio discovery, directory scanning,
/// differential startup sync, and artwork recovery.
class LibraryScannerService {
  final LocalAudioScanner _scanner;

  const LibraryScannerService({LocalAudioScanner? scanner})
      : _scanner = scanner ?? const LocalAudioScanner();

  LocalAudioScanner get scanner => _scanner;

  /// Ensures necessary Android storage permissions using StoragePermissionService.
  Future<bool> ensureStoragePermissions() async {
    return StoragePermissionService.instance.ensureBasicStoragePermissions();
  }

  /// Checks if manage external storage permission is granted.
  Future<bool> checkManageStorageGranted() async {
    return StoragePermissionService.instance.hasManageExternalStoragePermission();
  }

  /// Open directory picker to select and scan user's custom music folder.
  Future<DirectoryScanResult?> pickAndScanDirectory({
    required List<Track> currentTracks,
    void Function(int count, String folder)? onProgress,
  }) async {
    await ensureStoragePermissions();

    final selectedDirectory = await FilePicker.getDirectoryPath(
      dialogTitle: 'Select Music Folder to Scan',
    );

    if (selectedDirectory == null || selectedDirectory.isEmpty) {
      return null;
    }

    // Persist folder
    final currentFolders = LocalPersistenceService.instance.getMusicFolders();
    if (!currentFolders.contains(selectedDirectory)) {
      final updatedFolders = [...currentFolders, selectedDirectory];
      await LocalPersistenceService.instance.saveMusicFolders(updatedFolders);
    }

    final existingMap = <String, Track>{
      for (final t in currentTracks)
        if (t.filePath != null && t.filePath!.isNotEmpty) t.filePath!: t,
    };

    final scanned = await _scanner.scanDirectory(
      Directory(selectedDirectory),
      existingTracksByPath: existingMap,
      onProgress: onProgress,
    );

    final existingTrackPaths = currentTracks.map((t) => t.filePath).whereType<String>().toSet();
    final newTracks = scanned
        .where((t) => t.filePath == null || !existingTrackPaths.contains(t.filePath))
        .toList();

    final updatedList = [...currentTracks, ...newTracks];
    await _persistTracks(updatedList);

    final folderName = selectedDirectory.split(Platform.pathSeparator).last;
    final isExternalSd = selectedDirectory.startsWith('/storage/') &&
        !selectedDirectory.startsWith('/storage/emulated/0');

    String statusMsg;
    if (newTracks.isNotEmpty) {
      statusMsg = 'Added ${newTracks.length} tracks from $folderName.';
    } else if (scanned.isEmpty) {
      final hasManagePermission = await checkManageStorageGranted();
      if (isExternalSd && !hasManagePermission) {
        statusMsg = 'No files found in $folderName. Please grant "All files access" in Android Settings for SD card access.';
      } else {
        statusMsg = 'No audio files found in $folderName (FLAC, WAV, MP3, OPUS, OGG, M4A, DSD).';
      }
    } else {
      statusMsg = 'All ${scanned.length} tracks in $folderName are already in your library.';
    }

    return DirectoryScanResult(
      allTracks: updatedList,
      newTracks: newTracks,
      statusMessage: statusMsg,
    );
  }

  /// Open file picker to choose specific audio files.
  Future<DirectoryScanResult?> pickAudioFiles({
    required List<Track> currentTracks,
  }) async {
    await ensureStoragePermissions();

    final pickedFiles = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
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
        'webm',
      ],
    );

    if (pickedFiles.isEmpty) {
      return null;
    }

    final files = pickedFiles
        .map((f) => f.path)
        .whereType<String>()
        .where((p) => p.isNotEmpty)
        .map((p) => File(p))
        .toList();

    final parsed = await _scanner.parseFiles(files);

    final existingTrackPaths = currentTracks.map((t) => t.filePath).whereType<String>().toSet();
    final newTracks = parsed
        .where((t) => t.filePath == null || !existingTrackPaths.contains(t.filePath))
        .toList();

    final updatedList = [...currentTracks, ...newTracks];
    await _persistTracks(updatedList);

    final statusMsg = newTracks.isNotEmpty
        ? 'Added ${newTracks.length} audio files to library.'
        : (parsed.isEmpty
            ? 'Could not parse selected audio files.'
            : 'Selected files are already in your library.');

    return DirectoryScanResult(
      allTracks: updatedList,
      newTracks: newTracks,
      statusMessage: statusMsg,
    );
  }

  /// Silent background sync on startup: only parses new or modified files.
  Future<List<Track>?> syncNewTracksOnStartup({
    required List<Track> currentTracks,
  }) async {
    final autoScan = LocalPersistenceService.instance.getSetting<bool>('auto_scan_on_startup', true) ?? true;
    if (!autoScan) return null;

    final savedFolders = LocalPersistenceService.instance.getMusicFolders();
    if (savedFolders.isEmpty) return null;

    try {
      final existingMap = <String, Track>{
        for (final t in currentTracks)
          if (t.filePath != null && t.filePath!.isNotEmpty) t.filePath!: t,
      };

      final scanned = await _scanner.scanPaths(
        savedFolders,
        existingTracksByPath: existingMap,
      );

      if (scanned.isEmpty && currentTracks.isNotEmpty) return null;

      final existingPaths = currentTracks.map((t) => t.filePath).whereType<String>().toSet();
      final scannedPaths = scanned.map((t) => t.filePath).whereType<String>().toSet();

      final hasChanges = scanned.length != currentTracks.where((t) => t.filePath != null).length ||
          !setEquals(existingPaths, scannedPaths);

      if (hasChanges) {
        final existingCloud = currentTracks.where((t) => t.remoteUrl != null).toList();
        final combined = [...scanned, ...existingCloud];
        await _persistTracks(combined);
        return combined;
      }
    } catch (e) {
      debugPrint('[LibraryScannerService] Background startup sync notice: $e');
    }
    return null;
  }

  /// Recovers missing album artwork in background.
  Future<List<Track>?> recoverMissingArtwork({
    required List<Track> currentTracks,
  }) async {
    final needsRecovery = currentTracks.where(
      (t) => (t.albumArtBytes == null || t.albumArtBytes!.isEmpty) &&
             (t.albumArtUrl == null || t.albumArtUrl!.isEmpty) &&
             t.filePath != null && t.filePath!.isNotEmpty,
    ).toList();

    if (needsRecovery.isEmpty) return null;

    bool hasAnyUpdated = false;
    final updatedList = List<Track>.from(currentTracks);

    for (int i = 0; i < updatedList.length; i++) {
      final t = updatedList[i];
      if ((t.albumArtBytes == null || t.albumArtBytes!.isEmpty) &&
          (t.albumArtUrl == null || t.albumArtUrl!.isEmpty) &&
          t.filePath != null && t.filePath!.isNotEmpty) {
        final updated = await LocalAudioScanner.extractAndCacheCoverArt(t);
        if (updated.albumArtUrl != null || updated.albumArtBytes != null) {
          updatedList[i] = updated;
          hasAnyUpdated = true;
        }
      }
    }

    if (hasAnyUpdated) {
      await _persistTracks(updatedList);
      return updatedList;
    }
    return null;
  }

  /// Rescan all saved folders.
  Future<List<Track>> rescanSavedFolders({
    required List<Track> currentTracks,
    required List<String> savedFolders,
    void Function(int count, String path)? onProgress,
  }) async {
    await ensureStoragePermissions();

    final existingMap = <String, Track>{
      for (final t in currentTracks)
        if (t.filePath != null && t.filePath!.isNotEmpty) t.filePath!: t,
    };

    final scanned = await _scanner.scanPaths(
      savedFolders,
      existingTracksByPath: existingMap,
      onProgress: onProgress,
    );

    final existingCloud = currentTracks.where((t) => t.remoteUrl != null).toList();
    final combined = [...scanned, ...existingCloud];

    await _persistTracks(combined);
    return combined;
  }

  Future<void> _persistTracks(List<Track> tracks) async {
    try {
      final maps = tracks.map((t) => t.toMap()).toList();
      await LocalPersistenceService.instance.saveLibraryTracks(maps);
    } catch (e) {
      debugPrint('[LibraryScannerService] Error persisting tracks: $e');
    }
  }
}
