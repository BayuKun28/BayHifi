import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/player/domain/track.dart';

/// Layanan Penyimpanan Lokal Persisten Cepat (JSON File-based DB Engine)
class LocalPersistenceService {
  static LocalPersistenceService? _instance;
  static LocalPersistenceService get instance =>
      _instance ??= LocalPersistenceService._();

  LocalPersistenceService._();

  File? _dbFile;
  Map<String, dynamic> _cache = {};
  bool _isInitialized = false;
  String _activeUserId = 'guest';

  bool get isInitialized => _isInitialized;
  String get activeUserId => _activeUserId;

  /// Global keys that belong to device hardware/system configuration and must NEVER be scoped per user
  static const Set<String> _unscopedGlobalKeys = {
    'saved_music_folders',
    'saved_library_tracks',
    'desktop_window_geometry',
    'bayhifi_cloud_server_url',
    'audio_cache_version',
  };

  /// Switches the active user namespace.
  /// If [cloneGuestIfEmpty] is true and switching to an authenticated user who has no
  /// prior local settings, the current guest preferences are cloned into this user's partition.
  Future<void> switchUser(String? userId, {bool cloneGuestIfEmpty = true}) async {
    final targetId = (userId == null || userId.trim().isEmpty) ? 'guest' : userId.trim();
    if (_activeUserId == targetId) return;

    final oldUserId = _activeUserId;
    _activeUserId = targetId;

    if (targetId != 'guest' && cloneGuestIfEmpty) {
      final userPrefix = 'u_${targetId}_';
      final hasUserData = _cache.keys.any((k) => k.startsWith(userPrefix));
      if (!hasUserData) {
        _clonePartition(sourceUserId: oldUserId, targetUserId: targetId);
        await _save();
      }
    }
    debugPrint('[LocalPersistence] Switched active user partition to: $targetId');
  }

  void _clonePartition({required String sourceUserId, required String targetUserId}) {
    final srcPrefix = 'u_${sourceUserId}_';
    final targetPrefix = 'u_${targetUserId}_';

    // 1. Copy any explicitly scoped keys of source user
    final sourceKeys = _cache.keys.where((k) => k.startsWith(srcPrefix)).toList();
    for (final k in sourceKeys) {
      final baseKey = k.substring(srcPrefix.length);
      _cache['$targetPrefix$baseKey'] = jsonDecode(jsonEncode(_cache[k]));
    }

    // 2. If source user was guest and had unscoped legacy fallback keys, clone those too
    if (sourceUserId == 'guest') {
      for (final entry in _cache.entries) {
        if (!entry.key.startsWith('u_') && !_unscopedGlobalKeys.contains(entry.key)) {
          final targetKey = '$targetPrefix${entry.key}';
          if (!_cache.containsKey(targetKey)) {
            _cache[targetKey] = jsonDecode(jsonEncode(entry.value));
          }
        }
      }
    }
  }

  dynamic _readScoped(String baseKey) {
    if (_unscopedGlobalKeys.contains(baseKey)) {
      return _cache[baseKey];
    }
    final scoped = 'u_${_activeUserId}_$baseKey';
    if (_cache.containsKey(scoped)) {
      return _cache[scoped];
    }
    // Backward compatibility fallback for 'guest': if scoped doesn't exist, check unscoped legacy key
    if (_activeUserId == 'guest' && _cache.containsKey(baseKey)) {
      return _cache[baseKey];
    }
    return null;
  }

  void _writeScoped(String baseKey, dynamic value) {
    if (_unscopedGlobalKeys.contains(baseKey)) {
      _cache[baseKey] = value;
    } else {
      _cache['u_${_activeUserId}_$baseKey'] = value;
    }
  }

  void _removeScoped(String baseKey) {
    if (_unscopedGlobalKeys.contains(baseKey)) {
      _cache.remove(baseKey);
    } else {
      _cache.remove('u_${_activeUserId}_$baseKey');
    }
  }

  /// Exports active user's settings as an un-prefixed map for remote sync or export
  Map<String, dynamic> exportCurrentUserSettings() {
    final prefix = 'u_${_activeUserId}_';
    final result = <String, dynamic>{};
    for (final entry in _cache.entries) {
      if (entry.key.startsWith(prefix)) {
        final key = entry.key.substring(prefix.length);
        if (!_unscopedGlobalKeys.contains(key) && key != 'playback_history_logs') {
          result[key] = entry.value;
        }
      } else if (_activeUserId == 'guest' &&
          !entry.key.startsWith('u_') &&
          !_unscopedGlobalKeys.contains(entry.key) &&
          entry.key != 'playback_history_logs') {
        result[entry.key] = entry.value;
      }
    }
    return result;
  }

  /// Imports user settings bundle into active user's partition
  Future<void> importCurrentUserSettings(Map<String, dynamic> bundle, {bool overwrite = true}) async {
    for (final entry in bundle.entries) {
      if (_unscopedGlobalKeys.contains(entry.key)) continue;
      if (overwrite || _readScoped(entry.key) == null) {
        _writeScoped(entry.key, entry.value);
      }
    }
    await _save();
  }

  /// Imports and deduplicates playback history logs into active user's partition
  Future<void> importPlaybackLogs(List<Map<String, dynamic>> remoteLogs) async {
    final currentLogs = getPlaybackHistoryLogs();
    final existingIds = currentLogs.map((l) => l['id']?.toString() ?? '').toSet();

    final toAdd = <Map<String, dynamic>>[];
    for (final log in remoteLogs) {
      final id = log['id']?.toString() ?? '';
      if (id.isNotEmpty && !existingIds.contains(id)) {
        toAdd.add(log);
        existingIds.add(id);
      }
    }

    if (toAdd.isNotEmpty) {
      currentLogs.addAll(toAdd);
      currentLogs.sort((a, b) {
        final tA = a['playedAt'] ?? a['played_at'] ?? 0;
        final tB = b['playedAt'] ?? b['played_at'] ?? 0;
        return (tA as num).compareTo(tB as num);
      });
      if (currentLogs.length > 10000) {
        currentLogs.removeRange(0, currentLogs.length - 10000);
      }
      _writeScoped('playback_history_logs', currentLogs);
      await _save();
    }
  }

  /// Returns true if the database has no stored playlists, favorites, folders, or tracks
  bool get isEmpty {
    if (_cache.isEmpty) return true;
    final hasPlaylists = getCustomPlaylists().isNotEmpty;
    final hasFavorites = getFavoriteTrackIds().isNotEmpty;
    final hasFolders = getMusicFolders().isNotEmpty;
    final hasTracks = getSavedLibraryTracks().isNotEmpty;
    return !hasPlaylists && !hasFavorites && !hasFolders && !hasTracks;
  }

  /// Exports full raw internal cache for backup archiving
  Map<String, dynamic> exportFullSnapshot() {
    return Map<String, dynamic>.from(_cache);
  }

  /// Imports full snapshot and persists to disk
  Future<void> importFullSnapshot(Map<String, dynamic> snapshot, {bool overwrite = true}) async {
    if (overwrite) {
      _cache = Map<String, dynamic>.from(snapshot);
    } else {
      _cache.addAll(snapshot);
    }
    await _save();
  }

  /// Inisialisasi file penyimpanan persisten di direktori dokumen aplikasi
  Future<void> init({String? customPath}) async {
    if (_isInitialized && customPath == null) return;

    if (kIsWeb) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final raw = prefs.getString('baydev_hifi_web_storage');
        if (raw != null && raw.trim().isNotEmpty) {
          _cache = jsonDecode(raw) as Map<String, dynamic>;
        } else {
          _cache = {};
        }
        _isInitialized = true;
        debugPrint('[LocalPersistence] Initialized on Web via SharedPreferences');
      } catch (e) {
        debugPrint('[LocalPersistence] Web initialization error: $e');
        _cache = {};
        _isInitialized = true;
      }
      return;
    }

    try {
      if (customPath != null) {
        _dbFile = File(customPath);
      } else {
        final dir = await getApplicationDocumentsDirectory();
        _dbFile = File('${dir.path}/baydev_hifi_storage.json');
      }

      if (await _dbFile!.exists()) {
        final content = await _dbFile!.readAsString();
        if (content.trim().isNotEmpty) {
          if (content.length > 20000 && !kIsWeb) {
            _cache = await compute(_decodeJsonMap, content);
          } else {
            _cache = jsonDecode(content) as Map<String, dynamic>;
          }
        }
      } else {
        _cache = {};
        await _save();
      }
      _isInitialized = true;
      debugPrint('[LocalPersistence] Initialized at ${_dbFile!.path}');
    } catch (e) {
      debugPrint('[LocalPersistence] Failed initialization: $e');
      _cache = {};
      _isInitialized = true;
    }
  }

  Timer? _saveDebounceTimer;
  Completer<void>? _saveCompleter;

  Future<void> _save({bool immediate = false}) {
    final inTest = Platform.environment.containsKey('FLUTTER_TEST');
    if (immediate || inTest) {
      _saveDebounceTimer?.cancel();
      _saveDebounceTimer = null;
      final completer = _saveCompleter;
      _saveCompleter = null;
      return _performWrite().then((_) {
        if (completer != null && !completer.isCompleted) completer.complete();
      }).catchError((e) {
        if (completer != null && !completer.isCompleted) completer.completeError(e);
      });
    }

    _saveCompleter ??= Completer<void>();
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(const Duration(milliseconds: 150), () {
      _saveDebounceTimer = null;
      final completer = _saveCompleter;
      _saveCompleter = null;
      _performWrite().then((_) {
        if (completer != null && !completer.isCompleted) completer.complete();
      }).catchError((e) {
        if (completer != null && !completer.isCompleted) completer.completeError(e);
      });
    });

    return _saveCompleter!.future;
  }

  /// Forces an immediate flush to disk if any debounced write is pending
  Future<void> flush() async {
    if (_saveDebounceTimer != null) {
      await _save(immediate: true);
    }
  }

  Future<void> _performWrite() async {
    if (kIsWeb) {
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('baydev_hifi_web_storage', jsonEncode(_cache));
      } catch (e) {
        debugPrint('[LocalPersistence] Web save error: $e');
      }
      return;
    }
    if (_dbFile == null) return;
    try {
      final String raw;
      final trackList = _cache['saved_library_tracks'];
      final isLargePayload = (_cache.length > 50) || (trackList is List && trackList.length > 50);

      if (isLargePayload && !kIsWeb) {
        raw = await compute(_encodeJsonMap, Map<String, dynamic>.from(_cache));
      } else {
        raw = jsonEncode(_cache);
      }
      await _dbFile!.writeAsString(raw, flush: true);
    } catch (e) {
      debugPrint('[LocalPersistence] Save error: $e');
    }
  }

  // ─── 1. FAVORITES ──────────────────────────────────────────────────────────
  List<String> getFavoriteTrackIds() {
    final list = _readScoped('favorite_track_ids');
    if (list is List) {
      return list.map((e) => e.toString()).toList();
    }
    return [];
  }

  Future<void> saveFavoriteTrackIds(Set<String> ids) async {
    _writeScoped('favorite_track_ids', ids.toList());
    await _save();
  }

  // ─── 2. CUSTOM PLAYLISTS ───────────────────────────────────────────────────
  List<Map<String, dynamic>> getCustomPlaylists() {
    final list = _readScoped('custom_playlists');
    if (list is List) {
      return list.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
    }
    return [];
  }

  Future<void> saveCustomPlaylists(List<Map<String, dynamic>> playlists) async {
    _writeScoped('custom_playlists', playlists);
    await _save();
  }

  // ─── 2.1 SMART PLAYLISTS ───────────────────────────────────────────────────
  List<Map<String, dynamic>> getSmartPlaylists() {
    final list = _readScoped('smart_playlists');
    if (list is List) {
      return list.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
    }
    return [];
  }

  Future<void> saveSmartPlaylists(List<Map<String, dynamic>> playlists) async {
    _writeScoped('smart_playlists', playlists);
    await _save();
  }

  // ─── 3. PERSONALIZATION & SETTINGS ─────────────────────────────────────────
  T? getSetting<T>(String key, [T? defaultValue]) {
    final val = _readScoped(key);
    if (val is T) return val;
    return defaultValue;
  }

  Future<void> saveSetting(String key, dynamic value) async {
    _writeScoped(key, value);
    await _save();
  }

  Future<void> removeSetting(String key) async {
    _removeScoped(key);
    await _save();
  }

  // ─── 3.1 THEME & PALETTE PERSISTENCE ───────────────────────────────────────
  Map<String, dynamic> getThemeSettings() {
    final hasMigratedV2 = _readScoped('migrated_to_simple_as_f_v2') == true;
    if (!hasMigratedV2) {
      _writeScoped('migrated_to_simple_as_f_v2', true);
      final defaultSettings = <String, dynamic>{
        'palette_id': 'simple_as_f',
        'theme_mode': 2, // dark
        'custom_accent': 0xFF2EE672,
        'dynamic_album_art': false,
        'surface_fill_style': 'solid',
      };
      _writeScoped('theme_settings', defaultSettings);
      _save();
      return defaultSettings;
    }

    final data = _readScoped('theme_settings');
    if (data is Map<String, dynamic>) {
      bool changed = false;
      if (data['palette_id'] == 'obsidian_cyan' || data['palette_id'] == null) {
        data['palette_id'] = 'simple_as_f';
        changed = true;
      }
      if (data['custom_accent'] == 0xFF38BDF8 || data['custom_accent'] == null) {
        data['custom_accent'] = 0xFF2EE672;
        changed = true;
      }
      if (changed) {
        _writeScoped('theme_settings', data);
        _save();
      }
      return data;
    }
    if (data is Map) {
      final map = Map<String, dynamic>.from(data);
      bool changed = false;
      if (map['palette_id'] == 'obsidian_cyan' || map['palette_id'] == null) {
        map['palette_id'] = 'simple_as_f';
        changed = true;
      }
      if (map['custom_accent'] == 0xFF38BDF8 || map['custom_accent'] == null) {
        map['custom_accent'] = 0xFF2EE672;
        changed = true;
      }
      if (changed) {
        _writeScoped('theme_settings', map);
        _save();
      }
      return map;
    }
    return {
      'palette_id': 'simple_as_f',
      'theme_mode': 2, // dark
      'custom_accent': 0xFF2EE672,
      'dynamic_album_art': false,
      'surface_fill_style': 'solid',
    };
  }

  Future<void> saveThemeSettings({
    required String paletteId,
    required int themeModeIndex,
    required int customAccentColorValue,
    required bool dynamicAlbumArtEnabled,
    String surfaceFillStyle = 'translucent',
    int? dynamicDominantValue,
    int? dynamicVibrantValue,
    Map<String, dynamic>? wallpaperSettings,
  }) async {
    _writeScoped('migrated_to_simple_as_f_v2', true);
    _writeScoped('theme_settings', {
      'palette_id': paletteId,
      'theme_mode': themeModeIndex,
      'custom_accent': customAccentColorValue,
      'dynamic_album_art': dynamicAlbumArtEnabled,
      'surface_fill_style': surfaceFillStyle,
      'dynamic_dominant': ?dynamicDominantValue,
      'dynamic_vibrant': ?dynamicVibrantValue,
      'wallpaper_settings': ?wallpaperSettings,
    });
    await _save();
  }

  Map<String, dynamic> getWallpaperSettings() {
    final themeSettings = getThemeSettings();
    final nested = themeSettings['wallpaper_settings'];
    if (nested is Map) {
      return Map<String, dynamic>.from(nested);
    }
    final data = _readScoped('wallpaper_settings');
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {
      'enabled': false,
      'image_path': null,
      'blur_radius': 16.0,
      'dim_opacity': 0.45,
      'sync_palette': true,
      'scope': 'appWide',
    };
  }

  Future<void> saveWallpaperSettings({
    required bool enabled,
    String? imagePath,
    double blurRadius = 16.0,
    double dimOpacity = 0.45,
    bool syncPalette = true,
    String scope = 'appWide',
  }) async {
    final map = {
      'enabled': enabled,
      'image_path': imagePath,
      'blur_radius': blurRadius,
      'dim_opacity': dimOpacity,
      'sync_palette': syncPalette,
      'scope': scope,
    };
    _writeScoped('wallpaper_settings', map);
    final themeSettings = Map<String, dynamic>.from(getThemeSettings());
    themeSettings['wallpaper_settings'] = map;
    _writeScoped('theme_settings', themeSettings);
    await _save();
  }

  Future<String> saveCustomWallpaperFile(File sourceFile) async {
    final dir = await getApplicationDocumentsDirectory();
    final wallpaperDir = Directory('${dir.path}/wallpapers');
    if (!await wallpaperDir.exists()) {
      await wallpaperDir.create(recursive: true);
    }
    final ext = sourceFile.path.contains('.') ? sourceFile.path.split('.').last : 'jpg';
    final targetPath = '${wallpaperDir.path}/custom_wallpaper_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final targetFile = await sourceFile.copy(targetPath);
    return targetFile.path;
  }

  Future<void> deleteCustomWallpaperFile(String filePath) async {
    try {
      final file = File(filePath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      debugPrint('[LocalPersistence] Notice deleting wallpaper file: $e');
    }
  }

  // ─── 4. PLAYBACK HISTORY & AUDIOPHILE LISTENING STATS ─────────────────────


  List<Map<String, dynamic>> getPlaybackHistory() {
    final list = _readScoped('playback_history');
    if (list is List) {
      return list.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
    }
    return [];
  }

  Future<void> logTrackPlayback(Map<String, dynamic> trackMap) async {
    final history = getPlaybackHistory();
    final entry = {
      ...trackMap,
      'playedAt': DateTime.now().millisecondsSinceEpoch,
    };

    // Insert at front
    history.insert(0, entry);

    // Keep history capped at 500 entries for optimal performance
    if (history.length > 500) {
      history.removeRange(500, history.length);
    }

    _writeScoped('playback_history', history);
    await _save();
  }

  Future<void> clearPlaybackHistory() async {
    _writeScoped('playback_history', []);
    await _save();
  }

  Map<String, dynamic> getListeningStats() {
    final history = getPlaybackHistory();
    if (history.isEmpty) {
      return {
        'totalTracksPlayed': 0,
        'totalListeningSeconds': 0,
        'hiResTracksPlayed': 0,
        'hiResPercentage': 0.0,
        'topTracks': <Map<String, dynamic>>[],
      };
    }

    int totalTracks = history.length;
    int totalSec = 0;
    int hiResCount = 0;
    final Map<String, Map<String, dynamic>> trackCounts = {};

    for (final item in history) {
      final durMs = (item['durationMs'] as num?)?.toInt() ?? 0;
      totalSec += (durMs / 1000).round();

      final bitDepth = (item['bitDepth'] as num?)?.toInt() ?? 16;
      final sampleRate = (item['sampleRate'] as num?)?.toInt() ?? 44100;
      final format = item['format'] as String? ?? '';
      final isHiRes = bitDepth >= 24 || sampleRate >= 88200 || format == 'dsd' || format == 'flac';

      if (isHiRes) {
        hiResCount++;
      }

      final id = item['id']?.toString() ?? item['title']?.toString() ?? 'unknown';
      if (!trackCounts.containsKey(id)) {
        trackCounts[id] = {
          'id': id,
          'title': item['title'] ?? 'Unknown Track',
          'artist': item['artist'] ?? 'Unknown Artist',
          'album': item['album'] ?? 'Unknown Album',
          'filePath': item['filePath'],
          'remoteUrl': item['remoteUrl'],
          'isHiRes': isHiRes,
          'count': 1,
        };
      } else {
        trackCounts[id]!['count'] = (trackCounts[id]!['count'] as int) + 1;
      }
    }

    final topList = trackCounts.values.toList()
      ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    final top5 = topList.take(5).toList();

    return {
      'totalTracksPlayed': totalTracks,
      'totalListeningSeconds': totalSec,
      'hiResTracksPlayed': hiResCount,
      'hiResPercentage': totalTracks > 0 ? (hiResCount / totalTracks) * 100.0 : 0.0,
      'topTracks': top5,
    };
  }

  // ─── 5. LAST SESSION RESUME & STATE RESTORATION ────────────────────────────
  Map<String, dynamic>? getLastSessionState() {
    final state = _readScoped('last_session_state');
    if (state is Map<String, dynamic>) {
      return state;
    }
    return null;
  }

  Future<void> saveLastSessionState(Map<String, dynamic> state) async {
    _writeScoped('last_session_state', state);
    await _save();
  }

  // ─── 6. SAVED LOCAL LIBRARY TRACKS & MUSIC FOLDERS (GLOBAL) ────────────────
  List<Map<String, dynamic>> getSavedLibraryTracks() {
    final list = _cache['saved_library_tracks'];
    if (list is List) {
      return list.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
    }
    return [];
  }

  Future<void> saveLibraryTracks(List<Map<String, dynamic>> tracks) async {
    _cache['saved_library_tracks'] = tracks;
    await _save();
  }

  Future<void> saveTrack(Track track) async {
    final current = getSavedLibraryTracks();
    final updated = current.where((m) => m['id'] != track.id).toList();
    updated.add(track.toMap());
    await saveLibraryTracks(updated);
  }

  Track? getTrack(String id) {
    final list = getSavedLibraryTracks();
    for (final map in list) {
      if (map['id'] == id) {
        return Track.fromMap(map);
      }
    }
    return null;
  }

  List<String> getMusicFolders() {
    final list = _cache['saved_music_folders'];
    if (list is List) {
      return list.map((e) => e.toString()).toList();
    }
    return [];
  }

  Future<void> saveMusicFolders(List<String> folders) async {
    _cache['saved_music_folders'] = folders;
    await _save();
  }

  // ─── 7. AUTOEQ CLOUD PRESETS & OFFLINE FR CURVES ───────────────────────────
  List<Map<String, dynamic>> getSavedFrCurves({String? category}) {
    final list = _readScoped('saved_fr_curves');
    if (list is List) {
      final items = list.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
      if (category != null && category.isNotEmpty) {
        return items.where((c) {
          final cat = c['category'] as String?;
          final name = (c['name'] as String? ?? '').toLowerCase();
          if (category == 'target') {
            return cat == 'target' || name.contains('target');
          } else {
            return cat == 'driver' || (!name.contains('target') && cat != 'target');
          }
        }).toList();
      }
      return items;
    }
    return [];
  }

  Future<void> saveFrCurve(Map<String, dynamic> curveMap) async {
    final list = getSavedFrCurves();
    final id = curveMap['id'] as String?;
    final name = curveMap['name'] as String?;
    if ((name == null || name.trim().isEmpty) && (id == null || id.trim().isEmpty)) return;

    // Replace if exists, or append
    final updated = list.where((c) => (id == null || c['id'] != id) && (name == null || c['name'] != name)).toList();
    updated.add(curveMap);
    _writeScoped('saved_fr_curves', updated);
    await _save();
  }

  Future<void> deleteFrCurve(String idOrName) async {
    final list = getSavedFrCurves();
    _writeScoped('saved_fr_curves',
        list.where((c) => c['id'] != idOrName && c['name'] != idOrName).toList());
    await _save();
  }

  // ─── 8. HARDWARE DAC CUSTOM PROFILES (SCOPED PER USER) ─────────────────────
  List<Map<String, dynamic>> getSavedDacProfiles() {
    final list = _readScoped('saved_dac_profiles');
    if (list is List) {
      return list.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
    }
    return [];
  }

  Future<void> saveDacProfile(Map<String, dynamic> profileMap) async {
    final list = getSavedDacProfiles();
    final id = profileMap['id'] as String?;
    final name = profileMap['name'] as String?;
    if ((id == null || id.trim().isEmpty) && (name == null || name.trim().isEmpty)) return;

    final updated = list.where((p) => (id == null || p['id'] != id) && (name == null || p['name'] != name)).toList();
    updated.add(profileMap);
    _writeScoped('saved_dac_profiles', updated);
    await _save();
  }

  Future<void> deleteDacProfile(String profileIdOrName) async {
    final list = getSavedDacProfiles();
    _writeScoped('saved_dac_profiles',
        list.where((p) => p['id'] != profileIdOrName && p['name'] != profileIdOrName).toList());
    await _save();
  }

  List<String> getDownloadedAutoEqIds() {
    final list = _readScoped('autoeq_downloaded_ids');
    if (list is List) {
      return list.map((e) => e.toString()).toList();
    }
    return [
      'target_harman_ie_2019v2',
      'target_hbb_bad_guy',
      'target_ief_neutral_2023',
      'iem_kz_castor_bass_enhanced',
      'iem_moondrop_chu2',
      'hp_sennheiser_hd600',
    ];
  }

  Future<void> saveDownloadedAutoEqIds(Set<String> ids) async {
    _writeScoped('autoeq_downloaded_ids', ids.toList());
    await _save();
  }

  // ─── 8. DSP RACK STATE & CUSTOM MASTERING PROFILES ─────────────────────────
  Map<String, dynamic>? getDspRackState() {
    final data = _readScoped('dsp_rack_state');
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  Future<void> saveDspRackState(Map<String, dynamic> stateMap) async {
    _writeScoped('dsp_rack_state', stateMap);
    await _save();
  }

  List<Map<String, dynamic>> getCustomDspProfiles() {
    final list = _readScoped('custom_dsp_profiles');
    if (list is List) {
      return list.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
    }
    return [];
  }

  Future<void> saveCustomDspProfiles(List<Map<String, dynamic>> profiles) async {
    _writeScoped('custom_dsp_profiles', profiles);
    await _save();
  }

  // ─── 8.1 PER-TRACK DSP OVERRIDES & GENRE MAPPINGS ────────────────────────
  Map<String, Map<String, dynamic>> getDspTrackOverrides() {
    final data = _readScoped('dsp_track_overrides');
    if (data is Map) {
      final result = <String, Map<String, dynamic>>{};
      data.forEach((k, v) {
        if (k is String && v is Map) {
          result[k] = Map<String, dynamic>.from(v);
        }
      });
      return result;
    }
    return {};
  }

  Future<void> saveDspTrackOverride(Map<String, dynamic> overrideMap) async {
    final trackId = overrideMap['trackId'] as String?;
    if (trackId == null || trackId.isEmpty) return;
    final current = getDspTrackOverrides();
    current[trackId] = overrideMap;
    _writeScoped('dsp_track_overrides', current);
    await _save();
  }

  Future<void> removeDspTrackOverride(String trackId) async {
    final current = getDspTrackOverrides();
    if (current.containsKey(trackId)) {
      current.remove(trackId);
      _writeScoped('dsp_track_overrides', current);
      await _save();
    }
  }

  Map<String, String> getDspGenreMappings() {
    final data = _readScoped('dsp_genre_mappings');
    if (data is Map) {
      final result = <String, String>{};
      data.forEach((k, v) {
        if (k is String && v is String) {
          result[k] = v;
        }
      });
      return result;
    }
    return {};
  }

  Future<void> saveDspGenreMappings(Map<String, String> mappings) async {
    _writeScoped('dsp_genre_mappings', Map<String, String>.from(mappings));
    await _save();
  }

  bool isDspAutoApplyByGenreEnabled() {
    final val = _readScoped('dsp_auto_apply_genre_enabled');
    if (val is bool) return val;
    return true; // Enabled by default
  }

  Future<void> setDspAutoApplyByGenreEnabled(bool enabled) async {
    _writeScoped('dsp_auto_apply_genre_enabled', enabled);
    await _save();
  }


  // ─── 9. CUSTOM PRO-Q EQ PRESETS ─────────────────────────────────────────────
  /// Returns all user-saved EQ presets. Each entry has: name, preampDb, bands (List<Map>).
  List<Map<String, dynamic>> getCustomEqPresets() {
    final list = _readScoped('custom_eq_presets');
    if (list is List) {
      return list.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
    }
    return [];
  }

  /// Saves (or overwrites) a custom EQ preset by name.
  Future<void> saveCustomEqPreset({
    required String name,
    required double preampDb,
    required List<Map<String, dynamic>> bands,
  }) async {
    if (name.trim().isEmpty) return;
    final list = getCustomEqPresets();
    final entry = <String, dynamic>{
      'name': name.trim(),
      'preampDb': preampDb,
      'bands': bands,
      'savedAt': DateTime.now().toIso8601String(),
    };
    final updated = list.where((p) => p['name'] != name.trim()).toList();
    updated.add(entry);
    _writeScoped('custom_eq_presets', updated);
    await _save();
  }

  /// Deletes a custom EQ preset by name.
  Future<void> deleteCustomEqPreset(String name) async {
    final list = getCustomEqPresets();
    _writeScoped('custom_eq_presets', list.where((p) => p['name'] != name).toList());
    await _save();
  }

  /// Returns the actively applied EQ state (bands, preampDb, activePresetName).
  Map<String, dynamic>? getActiveEqState() {
    final data = _readScoped('active_eq_state');
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  /// Saves the currently applied EQ state, including last selected Driver & Target curve names, serialized curves, and active status.
  Future<void> saveActiveEqState({
    required List<Map<String, dynamic>> bands,
    required double preampDb,
    required String activePresetName,
    String? lastDriverName,
    String? lastTargetName,
    Map<String, dynamic>? lastDriverCurve,
    Map<String, dynamic>? lastTargetCurve,
    bool preserveCurvesIfNull = false,
    bool isAutoEqActive = false,
    bool isEnabled = true,
    String? bandResolution,
    String? tuningMode,
  }) async {
    final existing = getActiveEqState();
    _writeScoped('active_eq_state', {
      'bands': bands,
      'preampDb': preampDb,
      'activePresetName': activePresetName,
      'lastDriverName': preserveCurvesIfNull ? (lastDriverName ?? existing?['lastDriverName']) : lastDriverName,
      'lastTargetName': preserveCurvesIfNull ? (lastTargetName ?? existing?['lastTargetName']) : lastTargetName,
      'lastDriverCurve': preserveCurvesIfNull ? (lastDriverCurve ?? existing?['lastDriverCurve']) : lastDriverCurve,
      'lastTargetCurve': preserveCurvesIfNull ? (lastTargetCurve ?? existing?['lastTargetCurve']) : lastTargetCurve,
      'isAutoEqActive': isAutoEqActive,
      'isEnabled': isEnabled,
      'bandResolution': bandResolution ?? (existing?['bandResolution'] as String?),
      'tuningMode': tuningMode ?? (existing?['tuningMode'] as String?),
      'savedAt': DateTime.now().toIso8601String(),
    });
    await _save();
  }

  /// Returns the last selected Driver & Target curve names and serialized maps.
  Map<String, dynamic> getLastSelectedAutoEqCurves() {
    final state = getActiveEqState();
    return {
      'driverName': state?['lastDriverName'] as String?,
      'targetName': state?['lastTargetName'] as String?,
      'driverCurve': state?['lastDriverCurve'] as Map<String, dynamic>?,
      'targetCurve': state?['lastTargetCurve'] as Map<String, dynamic>?,
    };
  }

  // ─── 9. DESKTOP WINDOW GEOMETRY PERSISTENCE (GLOBAL) ───────────────────────
  Map<String, dynamic>? getWindowDimensions() {
    final data = _cache['desktop_window_geometry'];
    if (data is Map<String, dynamic>) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  Future<void> saveWindowDimensions({
    required double width,
    required double height,
    double? x,
    double? y,
    bool isMaximized = false,
  }) async {
    _cache['desktop_window_geometry'] = {
      'width': width,
      'height': height,
      'x': x,
      'y': y,
      'isMaximized': isMaximized,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await _save();
  }

  // ─── 10. STUDIO WRAPPED & PLAYBACK TELEMETRY ───────────────────────────────
  List<Map<String, dynamic>> getPlaybackHistoryLogs() {
    final list = _readScoped('playback_history_logs');
    if (list is List) {
      return list.whereType<Map>().map((m) => Map<String, dynamic>.from(m)).toList();
    }
    return [];
  }

  Future<void> logPlaybackSession(Map<String, dynamic> sessionLog) async {
    final list = getPlaybackHistoryLogs();
    // Keep a rolling buffer of up to 10,000 playback session entries
    if (list.length >= 10000) {
      list.removeAt(0);
    }
    list.add(sessionLog);
    _writeScoped('playback_history_logs', list);
    await _save();
  }

  Future<void> clearPlaybackHistoryLogs() async {
    _writeScoped('playback_history_logs', <Map<String, dynamic>>[]);
    await _save();
  }

  Future<void> updatePlaybackHistoryLogs(List<Map<String, dynamic>> updatedLogs) async {
    _writeScoped('playback_history_logs', updatedLogs);
    await _save();
  }

  Map<String, dynamic>? getCachedWrappedSummary() {
    final data = _readScoped('cached_wrapped_summary');
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  Future<void> saveCachedWrappedSummary(Map<String, dynamic> summary) async {
    _writeScoped('cached_wrapped_summary', summary);
    await _save();
  }
}

Map<String, dynamic> _decodeJsonMap(String source) {
  return jsonDecode(source) as Map<String, dynamic>;
}

String _encodeJsonMap(Map<String, dynamic> data) {
  return jsonEncode(data);
}






