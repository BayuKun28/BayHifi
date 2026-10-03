import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

/// Cross-platform storage permission and public shared directory manager service
class StoragePermissionService {
  static StoragePermissionService? _instance;
  static StoragePermissionService get instance =>
      _instance ??= StoragePermissionService._();

  StoragePermissionService._();

  /// Checks if All Files Access (MANAGE_EXTERNAL_STORAGE) is granted on Android 11+ (API 30+)
  Future<bool> hasManageExternalStoragePermission() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final status = await Permission.manageExternalStorage.status;
      return status.isGranted;
    } catch (e) {
      debugPrint('[StoragePermissionService] Error checking manageExternalStorage: $e');
      return false;
    }
  }

  /// Requests All Files Access (MANAGE_EXTERNAL_STORAGE) on Android
  Future<bool> requestManageExternalStoragePermission() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final status = await Permission.manageExternalStorage.request();
      if (status.isGranted) return true;

      // If denied or permanently denied, open system settings page
      if (status.isPermanentlyDenied || status.isDenied || status.isRestricted) {
        await openAppSettings();
        final recheck = await Permission.manageExternalStorage.status;
        return recheck.isGranted;
      }
      return false;
    } catch (e) {
      debugPrint('[StoragePermissionService] Error requesting manageExternalStorage: $e');
      return false;
    }
  }

  /// Ensures baseline read permissions for audio & storage
  Future<bool> ensureBasicStoragePermissions() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      final storageStatus = await Permission.storage.request();
      PermissionStatus audioStatus = PermissionStatus.granted;
      try {
        audioStatus = await Permission.audio.request();
      } catch (_) {}

      try {
        await Permission.notification.request();
      } catch (_) {}

      return storageStatus.isGranted || audioStatus.isGranted;
    } catch (e) {
      debugPrint('[StoragePermissionService] Error ensuring basic storage permissions: $e');
      return true;
    }
  }

  /// Tests if a file or directory path is directly writable by the current process
  Future<bool> canWriteToPath(String path) async {
    if (kIsWeb) return false;
    try {
      final file = File(path);
      if (await file.exists()) {
        final sink = file.openWrite(mode: FileMode.append);
        await sink.flush();
        await sink.close();
        return true;
      } else {
        final dir = Directory(path);
        if (await dir.exists()) {
          final testFile = File('${dir.path}/.baydev_write_test_${DateTime.now().millisecondsSinceEpoch}');
          await testFile.writeAsString('test', flush: true);
          if (await testFile.exists()) {
            await testFile.delete();
            return true;
          }
        }
      }
      return false;
    } catch (e) {
      debugPrint('[StoragePermissionService] Write check failed for $path: $e');
      return false;
    }
  }

  /// Resolves the public shared music directory that is immune to Android Clear App Data
  Future<Directory> getPublicMusicDirectory() async {
    if (kIsWeb) {
      final dir = await getApplicationDocumentsDirectory();
      return Directory('${dir.path}/Music');
    }

    if (Platform.isAndroid) {
      // 1. Primary Public Music folder (/storage/emulated/0/Music/BaydevHiFi)
      final primaryMusic = Directory('/storage/emulated/0/Music/BaydevHiFi');
      try {
        if (!primaryMusic.existsSync()) {
          primaryMusic.createSync(recursive: true);
        }
        return primaryMusic;
      } catch (e) {
        debugPrint('[StoragePermissionService] Primary Music dir creation notice: $e');
      }

      // 2. Secondary Public Download folder (/storage/emulated/0/Download/BaydevHiFi)
      final fallbackDownload = Directory('/storage/emulated/0/Download/BaydevHiFi');
      try {
        if (!fallbackDownload.existsSync()) {
          fallbackDownload.createSync(recursive: true);
        }
        return fallbackDownload;
      } catch (e) {
        debugPrint('[StoragePermissionService] Fallback Download dir creation notice: $e');
      }

      // 3. Fallback to app documents directory
      final docDir = await getApplicationDocumentsDirectory();
      final localMusic = Directory('${docDir.path}/Music');
      if (!localMusic.existsSync()) {
        localMusic.createSync(recursive: true);
      }
      return localMusic;
    }

    if (Platform.isLinux || Platform.isMacOS) {
      final home = Platform.environment['HOME'];
      if (home != null && Directory('$home/Music').existsSync()) {
        final dir = Directory('$home/Music/BaydevHiFi');
        if (!dir.existsSync()) dir.createSync(recursive: true);
        return dir;
      }
    }

    if (Platform.isWindows) {
      final userProfile = Platform.environment['USERPROFILE'];
      if (userProfile != null && Directory('$userProfile\\Music').existsSync()) {
        final dir = Directory('$userProfile\\Music\\BaydevHiFi');
        if (!dir.existsSync()) dir.createSync(recursive: true);
        return dir;
      }
    }

    final docDir = await getApplicationDocumentsDirectory();
    final targetDir = Directory('${docDir.path}/BaydevHiFi');
    if (!targetDir.existsSync()) targetDir.createSync(recursive: true);
    return targetDir;
  }

  /// Resolves the public backup file path for library state synchronization
  Future<File> getPublicBackupFile() async {
    final publicDir = await getPublicMusicDirectory();
    return File('${publicDir.path}/baydev_hifi_backup.json');
  }
}
