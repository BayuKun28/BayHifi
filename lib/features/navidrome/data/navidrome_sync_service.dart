import 'package:flutter/foundation.dart';
import '../../../../core/database/local_persistence_service.dart';
import '../../player/domain/track.dart';
import '../domain/subsonic_models.dart';
import 'subsonic_client.dart';

/// Service responsible for Subsonic/Navidrome server authentication, session management,
/// and cloud music catalog synchronization.
class NavidromeSyncService {
  final SubsonicClient _client;

  NavidromeSyncService({SubsonicClient? client})
      : _client = client ?? SubsonicClient();

  /// Pings Navidrome server and persists configuration upon successful connection.
  Future<bool> connect(SubsonicServerConfig config) async {
    try {
      final isOnline = await _client.ping(config);
      if (isOnline) {
        await LocalPersistenceService.instance.saveSetting('navidrome_config', config.toMap());
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[NavidromeSyncService] Connection error: $e');
      return false;
    }
  }

  /// Restores saved Navidrome session from persistent storage.
  SubsonicServerConfig? getSavedConfig() {
    try {
      final configMap = LocalPersistenceService.instance.getSetting<Map<String, dynamic>>('navidrome_config');
      if (configMap != null) {
        final config = SubsonicServerConfig.fromMap(configMap);
        if (config.serverUrl.isNotEmpty && config.username.isNotEmpty) {
          return config;
        }
      }
    } catch (e) {
      debugPrint('[NavidromeSyncService] Error reading saved config: $e');
    }
    return null;
  }

  /// Disconnects Navidrome and clears persisted session.
  Future<void> disconnect() async {
    await LocalPersistenceService.instance.removeSetting('navidrome_config');
  }

  /// Synchronizes tracks from the Navidrome server.
  Future<List<Track>> fetchRemoteTracks(SubsonicServerConfig config) async {
    final songs = await _client.fetchAllSongs(config);
    return songs.map((s) => s.toTrack(config)).toList();
  }
}
