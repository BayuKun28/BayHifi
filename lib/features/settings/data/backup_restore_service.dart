import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../../../../core/database/local_persistence_service.dart';

/// Validation report for a candidate backup file
class BackupValidationResult {
  final bool isValid;
  final String? errorMessage;
  final int version;
  final DateTime? createdAt;
  final int customPlaylistsCount;
  final int smartPlaylistsCount;
  final int favoritesCount;
  final int musicFoldersCount;
  final int historyCount;

  const BackupValidationResult({
    required this.isValid,
    this.errorMessage,
    this.version = 1,
    this.createdAt,
    this.customPlaylistsCount = 0,
    this.smartPlaylistsCount = 0,
    this.favoritesCount = 0,
    this.musicFoldersCount = 0,
    this.historyCount = 0,
  });
}

/// Result report after executing backup restore
class RestoreResult {
  final bool success;
  final String message;
  final int restoredPlaylistsCount;
  final int restoredSmartPlaylistsCount;
  final int restoredFavoritesCount;

  const RestoreResult({
    required this.success,
    required this.message,
    this.restoredPlaylistsCount = 0,
    this.restoredSmartPlaylistsCount = 0,
    this.restoredFavoritesCount = 0,
  });
}

/// Comprehensive Backup & Restore Service for Baydev HiFi (.bayhifi JSON Archive)
class BackupRestoreService {
  static BackupRestoreService? _instance;
  static BackupRestoreService get instance => _instance ??= BackupRestoreService._();

  BackupRestoreService._();

  /// Create a complete JSON archive of all user settings, playlists, smart rules & favorites
  String createBackupJson({
    bool includeHistory = true,
    bool includeLibrary = true,
  }) {
    final storage = LocalPersistenceService.instance;

    final backupMap = <String, dynamic>{
      'app': 'Baydev HiFi',
      'version': 1,
      'createdAt': DateTime.now().toIso8601String(),
      'theme_settings': storage.getThemeSettings(),
      'custom_playlists': storage.getCustomPlaylists(),
      'smart_playlists': storage.getSmartPlaylists(),
      'favorite_track_ids': storage.getFavoriteTrackIds(),
      'saved_music_folders': storage.getMusicFolders(),
    };

    if (includeHistory) {
      backupMap['playback_history'] = storage.getPlaybackHistory();
    }

    if (includeLibrary) {
      backupMap['saved_library_tracks'] = storage.getSavedLibraryTracks();
    }

    // Include personalization settings
    final allKeys = ['player_customization_settings', 'playback_settings', 'lyrics_display_mode'];
    for (final key in allKeys) {
      final val = storage.getSetting<dynamic>(key);
      if (val != null) {
        backupMap[key] = val;
      }
    }

    return const JsonEncoder.withIndent('  ').convert(backupMap);
  }

  /// Validate backup JSON payload before restoring
  BackupValidationResult validateBackup(String jsonString) {
    if (jsonString.trim().isEmpty) {
      return const BackupValidationResult(isValid: false, errorMessage: 'Backup file is empty.');
    }

    try {
      final data = jsonDecode(jsonString);
      if (data is! Map<String, dynamic>) {
        return const BackupValidationResult(isValid: false, errorMessage: 'Invalid JSON schema.');
      }

      final app = data['app'] as String?;
      if (app != 'Baydev HiFi') {
        return const BackupValidationResult(
          isValid: false,
          errorMessage: 'Unrecognized backup format. Expected "Baydev HiFi" signature.',
        );
      }

      final version = (data['version'] as num?)?.toInt() ?? 1;
      DateTime? createdAt;
      if (data['createdAt'] is String) {
        createdAt = DateTime.tryParse(data['createdAt'] as String);
      }

      final customPlaylists = (data['custom_playlists'] as List?)?.length ?? 0;
      final smartPlaylists = (data['smart_playlists'] as List?)?.length ?? 0;
      final favorites = (data['favorite_track_ids'] as List?)?.length ?? 0;
      final folders = (data['saved_music_folders'] as List?)?.length ?? 0;
      final history = (data['playback_history'] as List?)?.length ?? 0;

      return BackupValidationResult(
        isValid: true,
        version: version,
        createdAt: createdAt,
        customPlaylistsCount: customPlaylists,
        smartPlaylistsCount: smartPlaylists,
        favoritesCount: favorites,
        musicFoldersCount: folders,
        historyCount: history,
      );
    } catch (e) {
      return BackupValidationResult(isValid: false, errorMessage: 'Failed to parse JSON: $e');
    }
  }

  /// Restore state from a validated JSON backup string
  Future<RestoreResult> restoreFromBackupJson(
    String jsonString, {
    bool restorePlaylists = true,
    bool restoreSmartRules = true,
    bool restoreFavorites = true,
    bool restoreTheme = true,
    bool restoreFolders = true,
    bool restoreHistory = false,
  }) async {
    final validation = validateBackup(jsonString);
    if (!validation.isValid) {
      return RestoreResult(success: false, message: validation.errorMessage ?? 'Validation failed.');
    }

    try {
      final data = jsonDecode(jsonString) as Map<String, dynamic>;
      final storage = LocalPersistenceService.instance;

      int playlistsCount = 0;
      int smartCount = 0;
      int favCount = 0;

      // 1. Theme Settings
      if (restoreTheme && data['theme_settings'] is Map) {
        final theme = Map<String, dynamic>.from(data['theme_settings'] as Map);
        await storage.saveThemeSettings(
          paletteId: theme['palette_id'] as String? ?? 'obsidian_cyan',
          themeModeIndex: (theme['theme_mode'] as num?)?.toInt() ?? 2,
          customAccentColorValue: (theme['custom_accent'] as num?)?.toInt() ?? 0xFF38BDF8,
          dynamicAlbumArtEnabled: theme['dynamic_album_art'] as bool? ?? false,
        );
      }

      // 2. Custom Playlists
      if (restorePlaylists && data['custom_playlists'] is List) {
        final rawList = data['custom_playlists'] as List;
        final list = rawList.whereType<Map<String, dynamic>>().toList();
        await storage.saveCustomPlaylists(list);
        playlistsCount = list.length;
      }

      // 3. Smart Playlists
      if (restoreSmartRules && data['smart_playlists'] is List) {
        final rawList = data['smart_playlists'] as List;
        final list = rawList.whereType<Map<String, dynamic>>().toList();
        await storage.saveSmartPlaylists(list);
        smartCount = list.length;
      }

      // 4. Favorites
      if (restoreFavorites && data['favorite_track_ids'] is List) {
        final rawList = data['favorite_track_ids'] as List;
        final set = rawList.map((e) => e.toString()).toSet();
        await storage.saveFavoriteTrackIds(set);
        favCount = set.length;
      }

      // 5. Music Folders
      if (restoreFolders && data['saved_music_folders'] is List) {
        final rawList = data['saved_music_folders'] as List;
        final folders = rawList.map((e) => e.toString()).toList();
        await storage.saveMusicFolders(folders);
      }

      // 6. Settings & History
      if (restoreHistory && data['playback_history'] is List) {
        final rawList = data['playback_history'] as List;
        for (final item in rawList.whereType<Map<String, dynamic>>()) {
          await storage.logTrackPlayback(item);
        }
      }

      if (data['player_customization_settings'] != null) {
        await storage.saveSetting('player_customization_settings', data['player_customization_settings']);
      }
      if (data['playback_settings'] != null) {
        await storage.saveSetting('playback_settings', data['playback_settings']);
      }
      if (data['lyrics_display_mode'] != null) {
        await storage.saveSetting('lyrics_display_mode', data['lyrics_display_mode']);
      }

      return RestoreResult(
        success: true,
        message: 'Successfully restored $playlistsCount playlists, $smartCount smart rules, and $favCount favorites.',
        restoredPlaylistsCount: playlistsCount,
        restoredSmartPlaylistsCount: smartCount,
        restoredFavoritesCount: favCount,
      );
    } catch (e) {
      return RestoreResult(success: false, message: 'Restore error: $e');
    }
  }

  /// Export backup JSON directly to a file on local storage
  Future<File> saveBackupToFile(String jsonString) async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${appDocDir.path}/baydev_hifi_backup_$timestamp.bayhifi');
    return await file.writeAsString(jsonString, flush: true);
  }
}
