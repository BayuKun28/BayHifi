import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/user_profile.dart';

/// Service jaringan untuk komunikasi dengan BayHifi Go Backend
class CloudSyncService {
  final Dio _dio;

  CloudSyncService({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 15),
                sendTimeout: const Duration(seconds: 10),
              ),
            );

  static const String _prefKeyServerUrl = 'bayhifi_cloud_server_url';
  static const String _prefKeyToken = 'bayhifi_cloud_token';
  static const String _prefKeyUser = 'bayhifi_cloud_user_json';
  static const String _prefKeyLastSynced = 'bayhifi_cloud_last_synced';

  /// Membersihkan URL server dari trailing slash
  String sanitizeUrl(String url) {
    var s = url.trim();
    while (s.endsWith('/')) {
      s = s.substring(0, s.length - 1);
    }
    return s;
  }

  /// Membaca konfigurasi session tersimpan
  Future<Map<String, dynamic>> getSavedSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final defaultUrl = kIsWeb ? Uri.base.origin : 'http://localhost:8111';
      final serverUrl = prefs.getString(_prefKeyServerUrl) ?? defaultUrl;
      final token = prefs.getString(_prefKeyToken);
      final userJson = prefs.getString(_prefKeyUser);
      final lastSyncedStr = prefs.getString(_prefKeyLastSynced);

      UserProfile? user;
      if (userJson != null) {
        user = UserProfile.fromMap(jsonDecode(userJson) as Map<String, dynamic>);
      }

      DateTime? lastSynced;
      if (lastSyncedStr != null) {
        lastSynced = DateTime.tryParse(lastSyncedStr);
      }

      return {
        'serverUrl': serverUrl,
        'token': token,
        'user': user,
        'lastSyncedAt': lastSynced,
      };
    } catch (e) {
      final defaultUrl = kIsWeb ? Uri.base.origin : 'http://localhost:8111';
      return {'serverUrl': defaultUrl};
    }
  }

  /// Menyimpan session aktif
  Future<void> saveSession({
    required String serverUrl,
    required String token,
    required UserProfile user,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyServerUrl, sanitizeUrl(serverUrl));
      await prefs.setString(_prefKeyToken, token);
      await prefs.setString(_prefKeyUser, jsonEncode(user.toMap()));
    } catch (e) {
      debugPrint('[CloudSyncService] Error saving session: $e');
    }
  }

  /// Memperbarui timestamp sinkronisasi terakhir
  Future<void> updateLastSynced(DateTime time) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyLastSynced, time.toIso8601String());
    } catch (_) {}
  }

  /// Menghapus session cloud (Logout)
  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKeyToken);
      await prefs.remove(_prefKeyUser);
      await prefs.remove(_prefKeyLastSynced);
    } catch (e) {
      debugPrint('[CloudSyncService] Error clearing session: $e');
    }
  }

  /// Login ke server BayHifi
  Future<Map<String, dynamic>> login({
    required String serverUrl,
    required String username,
    required String password,
  }) async {
    final cleanUrl = sanitizeUrl(serverUrl);
    try {
      final res = await _dio.post(
        '$cleanUrl/api/auth/login',
        data: {'username': username, 'password': password},
      );

      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        final data = res.data as Map<String, dynamic>;
        if (data['success'] == true && data['token'] != null) {
          final token = data['token'] as String;
          final user = UserProfile.fromMap(data['user'] as Map<String, dynamic>);
          await saveSession(serverUrl: cleanUrl, token: token, user: user);
          return {'success': true, 'token': token, 'user': user};
        }
      }
      return {'success': false, 'message': res.data?['message'] ?? 'Login failed'};
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Network error';
      return {'success': false, 'message': msg};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Registrasi akun baru di server BayHifi
  Future<Map<String, dynamic>> register({
    required String serverUrl,
    required String username,
    required String password,
    String? email,
  }) async {
    final cleanUrl = sanitizeUrl(serverUrl);
    try {
      final res = await _dio.post(
        '$cleanUrl/api/auth/register',
        data: {
          'username': username,
          'password': password,
          if (email != null && email.isNotEmpty) 'email': email,
        },
      );

      if (res.statusCode == 201 && res.data is Map<String, dynamic>) {
        final data = res.data as Map<String, dynamic>;
        if (data['success'] == true && data['token'] != null) {
          final token = data['token'] as String;
          final user = UserProfile.fromMap(data['user'] as Map<String, dynamic>);
          await saveSession(serverUrl: cleanUrl, token: token, user: user);
          return {'success': true, 'token': token, 'user': user};
        }
      }
      return {'success': false, 'message': res.data?['message'] ?? 'Registration failed'};
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Network error';
      return {'success': false, 'message': msg};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Mengubah password user yang sedang terotentikasi
  Future<Map<String, dynamic>> changePassword({
    required String serverUrl,
    required String token,
    required String oldPassword,
    required String newPassword,
  }) async {
    final cleanUrl = sanitizeUrl(serverUrl);
    try {
      final res = await _dio.post(
        '$cleanUrl/api/auth/change-password',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
        data: {
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        },
      );

      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        final data = res.data as Map<String, dynamic>;
        if (data['success'] == true) {
          return {'success': true, 'message': data['message'] ?? 'Password changed successfully'};
        }
      }
      return {'success': false, 'message': res.data?['message'] ?? 'Failed to change password'};
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message ?? 'Network error';
      return {'success': false, 'message': msg};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Sinkronisasi batch log pemutaran (Studio Wrapped)
  Future<int> syncPlaybackLogs({
    required String serverUrl,
    required String token,
    required List<Map<String, dynamic>> logs,
  }) async {
    if (logs.isEmpty) return 0;
    final cleanUrl = sanitizeUrl(serverUrl);
    try {
      final res = await _dio.post(
        '$cleanUrl/api/sync/logs',
        data: {'logs': logs},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        final data = res.data as Map<String, dynamic>;
        final synced = data['syncedCount'] as int? ?? 0;
        await updateLastSynced(DateTime.now());
        return synced;
      }
      return 0;
    } catch (e) {
      debugPrint('[CloudSyncService] Log sync error: $e');
      return 0;
    }
  }

  /// Mengirim profil AutoEQ dan DSP aktif ke cloud
  Future<bool> syncDspProfile({
    required String serverUrl,
    required String token,
    required Map<String, dynamic> dspData,
  }) async {
    final cleanUrl = sanitizeUrl(serverUrl);
    try {
      final res = await _dio.put(
        '$cleanUrl/api/sync/dsp',
        data: dspData,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return res.statusCode == 200 && res.data?['success'] == true;
    } catch (e) {
      debugPrint('[CloudSyncService] DSP sync error: $e');
      return false;
    }
  }

  /// Mengambil profil AutoEQ dan DSP dari cloud
  Future<Map<String, dynamic>?> fetchDspProfile({
    required String serverUrl,
    required String token,
  }) async {
    final cleanUrl = sanitizeUrl(serverUrl);
    try {
      final res = await _dio.get(
        '$cleanUrl/api/sync/dsp',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (res.statusCode == 200 && res.data?['profile'] != null) {
        return res.data['profile'] as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      debugPrint('[CloudSyncService] Fetch DSP error: $e');
      return null;
    }
  }

  /// Mengambil semua pengaturan dan preferensi pengguna dari cloud
  Future<Map<String, dynamic>?> fetchUserSettings({
    required String serverUrl,
    required String token,
  }) async {
    final cleanUrl = sanitizeUrl(serverUrl);
    try {
      final res = await _dio.get(
        '$cleanUrl/api/sync/settings',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        final data = res.data as Map<String, dynamic>;
        if (data['success'] == true && data['settings'] != null) {
          if (data['settings'] is Map<String, dynamic>) {
            return data['settings'] as Map<String, dynamic>;
          }
        }
      }
      return null;
    } catch (e) {
      debugPrint('[CloudSyncService] Fetch settings error: $e');
      return null;
    }
  }

  /// Menyimpan semua preferensi pengguna ke cloud
  Future<bool> saveUserSettings({
    required String serverUrl,
    required String token,
    required Map<String, dynamic> settings,
  }) async {
    final cleanUrl = sanitizeUrl(serverUrl);
    try {
      final res = await _dio.put(
        '$cleanUrl/api/sync/settings',
        data: settings,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return res.statusCode == 200 && res.data?['success'] == true;
    } catch (e) {
      debugPrint('[CloudSyncService] Save settings error: $e');
      return false;
    }
  }

  /// Mengambil riwayat log pemutaran (statistik) dari cloud untuk sinkronisasi perangkat baru
  Future<List<Map<String, dynamic>>> fetchPlaybackLogs({
    required String serverUrl,
    required String token,
    int limit = 500,
  }) async {
    final cleanUrl = sanitizeUrl(serverUrl);
    try {
      final res = await _dio.get(
        '$cleanUrl/api/sync/logs',
        queryParameters: {'limit': limit},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (res.statusCode == 200 && res.data is Map<String, dynamic>) {
        final data = res.data as Map<String, dynamic>;
        if (data['success'] == true && data['logs'] is List) {
          final list = data['logs'] as List;
          return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('[CloudSyncService] Fetch logs error: $e');
      return [];
    }
  }

  /// Mengambil daftar lagu dari library server
  Future<List<Map<String, dynamic>>> fetchLibraryTracks({
    String? serverUrl,
    String? search,
    int limit = 200,
    int offset = 0,
  }) async {
    final defaultUrl = kIsWeb ? Uri.base.origin : 'http://localhost:8111';
    final cleanUrl = sanitizeUrl(serverUrl ?? defaultUrl);
    try {
      final res = await _dio.get(
        '$cleanUrl/api/library/tracks',
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          'limit': limit,
          'offset': offset,
        },
      );
      if (res.statusCode == 200 && res.data?['tracks'] is List) {
        final list = res.data['tracks'] as List;
        return list.map((e) => e as Map<String, dynamic>).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[CloudSyncService] Fetch library error: $e');
      return [];
    }
  }
}
