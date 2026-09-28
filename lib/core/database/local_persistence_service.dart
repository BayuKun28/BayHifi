import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Layanan Penyimpanan Lokal Persisten Cepat (JSON File-based DB Engine)
class LocalPersistenceService {
  static LocalPersistenceService? _instance;
  static LocalPersistenceService get instance =>
      _instance ??= LocalPersistenceService._();

  LocalPersistenceService._();

  File? _dbFile;
  Map<String, dynamic> _cache = {};
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  /// Inisialisasi file penyimpanan persisten di direktori dokumen aplikasi
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      final dir = await getApplicationDocumentsDirectory();
      _dbFile = File('${dir.path}/baydev_hifi_storage.json');

      if (await _dbFile!.exists()) {
        final content = await _dbFile!.readAsString();
        if (content.trim().isNotEmpty) {
          _cache = jsonDecode(content) as Map<String, dynamic>;
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

  Future<void> _save() async {
    if (_dbFile == null) return;
    try {
      await _dbFile!.writeAsString(jsonEncode(_cache), flush: true);
    } catch (e) {
      debugPrint('[LocalPersistence] Save error: $e');
    }
  }

  // ─── 1. FAVORITES ──────────────────────────────────────────────────────────
  List<String> getFavoriteTrackIds() {
    final list = _cache['favorite_track_ids'];
    if (list is List) {
      return list.map((e) => e.toString()).toList();
    }
    return [];
  }

  Future<void> saveFavoriteTrackIds(Set<String> ids) async {
    _cache['favorite_track_ids'] = ids.toList();
    await _save();
  }

  // ─── 2. CUSTOM PLAYLISTS ───────────────────────────────────────────────────
  List<Map<String, dynamic>> getCustomPlaylists() {
    final list = _cache['custom_playlists'];
    if (list is List) {
      return list.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  Future<void> saveCustomPlaylists(List<Map<String, dynamic>> playlists) async {
    _cache['custom_playlists'] = playlists;
    await _save();
  }

  // ─── 2.1 SMART PLAYLISTS ───────────────────────────────────────────────────
  List<Map<String, dynamic>> getSmartPlaylists() {
    final list = _cache['smart_playlists'];
    if (list is List) {
      return list.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  Future<void> saveSmartPlaylists(List<Map<String, dynamic>> playlists) async {
    _cache['smart_playlists'] = playlists;
    await _save();
  }

  // ─── 3. PERSONALIZATION & SETTINGS ─────────────────────────────────────────
  T? getSetting<T>(String key, [T? defaultValue]) {
    final val = _cache[key];
    if (val is T) return val;
    return defaultValue;
  }

  Future<void> saveSetting(String key, dynamic value) async {
    _cache[key] = value;
    await _save();
  }

  // ─── 3.1 THEME & PALETTE PERSISTENCE ───────────────────────────────────────
  Map<String, dynamic> getThemeSettings() {
    final data = _cache['theme_settings'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return {
      'palette_id': 'obsidian_cyan',
      'theme_mode': 2, // dark
      'custom_accent': 0xFF38BDF8,
      'dynamic_album_art': false,
    };
  }

  Future<void> saveThemeSettings({
    required String paletteId,
    required int themeModeIndex,
    required int customAccentColorValue,
    required bool dynamicAlbumArtEnabled,
  }) async {
    _cache['theme_settings'] = {
      'palette_id': paletteId,
      'theme_mode': themeModeIndex,
      'custom_accent': customAccentColorValue,
      'dynamic_album_art': dynamicAlbumArtEnabled,
    };
    await _save();
  }

  // ─── 4. PLAYBACK HISTORY & AUDIOPHILE LISTENING STATS ─────────────────────


  List<Map<String, dynamic>> getPlaybackHistory() {
    final list = _cache['playback_history'];
    if (list is List) {
      return list.whereType<Map<String, dynamic>>().toList();
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

    _cache['playback_history'] = history;
    await _save();
  }

  Future<void> clearPlaybackHistory() async {
    _cache['playback_history'] = [];
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
    final state = _cache['last_session_state'];
    if (state is Map<String, dynamic>) {
      return state;
    }
    return null;
  }

  Future<void> saveLastSessionState(Map<String, dynamic> state) async {
    _cache['last_session_state'] = state;
    await _save();
  }

  // ─── 6. SAVED LOCAL LIBRARY TRACKS & MUSIC FOLDERS ─────────────────────────
  List<Map<String, dynamic>> getSavedLibraryTracks() {
    final list = _cache['saved_library_tracks'];
    if (list is List) {
      return list.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  Future<void> saveLibraryTracks(List<Map<String, dynamic>> tracks) async {
    _cache['saved_library_tracks'] = tracks;
    await _save();
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
  List<Map<String, dynamic>> getSavedFrCurves() {
    final list = _cache['saved_fr_curves'];
    if (list is List) {
      return list.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  Future<void> saveFrCurve(Map<String, dynamic> curveMap) async {
    final list = getSavedFrCurves();
    final name = curveMap['name'] as String?;
    if (name == null || name.trim().isEmpty) return;

    // Replace if exists, or append
    final updated = list.where((c) => c['name'] != name).toList();
    updated.add(curveMap);
    _cache['saved_fr_curves'] = updated;
    await _save();
  }

  Future<void> deleteFrCurve(String name) async {
    final list = getSavedFrCurves();
    _cache['saved_fr_curves'] = list.where((c) => c['name'] != name).toList();
    await _save();
  }

  List<String> getDownloadedAutoEqIds() {
    final list = _cache['autoeq_downloaded_ids'];
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
    _cache['autoeq_downloaded_ids'] = ids.toList();
    await _save();
  }

  // ─── 8. DSP RACK STATE & CUSTOM MASTERING PROFILES ─────────────────────────
  Map<String, dynamic>? getDspRackState() {
    final data = _cache['dsp_rack_state'];
    if (data is Map<String, dynamic>) {
      return data;
    }
    if (data is Map) {
      return Map<String, dynamic>.from(data);
    }
    return null;
  }

  Future<void> saveDspRackState(Map<String, dynamic> stateMap) async {
    _cache['dsp_rack_state'] = stateMap;
    await _save();
  }

  List<Map<String, dynamic>> getCustomDspProfiles() {
    final list = _cache['custom_dsp_profiles'];
    if (list is List) {
      return list.whereType<Map<String, dynamic>>().toList();
    }
    return [];
  }

  Future<void> saveCustomDspProfiles(List<Map<String, dynamic>> profiles) async {
    _cache['custom_dsp_profiles'] = profiles;
    await _save();
  }
}




