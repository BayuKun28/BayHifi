import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../domain/subsonic_models.dart';

/// Client REST untuk Subsonic API (Navidrome)
class SubsonicClient {
  SubsonicClient({Dio? dio})
      : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 10),
                receiveTimeout: const Duration(seconds: 15),
                sendTimeout: const Duration(seconds: 10),
              ),
            );

  final Dio _dio;

  /// Melakukan uji koneksi ping ke server Subsonic
  Future<bool> ping(SubsonicServerConfig config) async {
    try {
      final uri = '${config.sanitizedUrl}/rest/ping.view';
      final response = await _dio.get(
        uri,
        queryParameters: config.getAuthQueryParams(),
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final subResp = response.data['subsonic-response'];
        return subResp != null && subResp['status'] == 'ok';
      }
      return false;
    } catch (e) {
      debugPrint('[SubsonicClient] Ping failed: $e');
      return false;
    }
  }

  /// Mengambil daftar lagu acak dari perpustakaan server
  Future<List<SubsonicSong>> getRandomSongs(
    SubsonicServerConfig config, {
    int size = 50,
  }) async {
    try {
      final uri = '${config.sanitizedUrl}/rest/getRandomSongs.view';
      final params = config.getAuthQueryParams();
      params['size'] = size.toString();

      final response = await _dio.get(uri, queryParameters: params);

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final subResp = response.data['subsonic-response'];
        if (subResp != null && subResp['status'] == 'ok') {
          final randomSongs = subResp['randomSongs'];
          if (randomSongs != null && randomSongs['song'] is List) {
            final list = randomSongs['song'] as List;
            return list.map((item) => SubsonicSong.fromJson(item as Map<String, dynamic>)).toList();
          }
        }
      }
      return [];
    } catch (e) {
      debugPrint('[SubsonicClient] getRandomSongs error: $e');
      return [];
    }
  }

  /// Melakukan pencarian lagu berdasarkan query teks
  Future<List<SubsonicSong>> searchSongs(
    SubsonicServerConfig config,
    String query, {
    int songCount = 30,
  }) async {
    try {
      final uri = '${config.sanitizedUrl}/rest/search3.view';
      final params = config.getAuthQueryParams();
      params['query'] = query;
      params['songCount'] = songCount.toString();

      final response = await _dio.get(uri, queryParameters: params);

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final subResp = response.data['subsonic-response'];
        if (subResp != null && subResp['status'] == 'ok') {
          final searchResult = subResp['searchResult3'];
          if (searchResult != null && searchResult['song'] is List) {
            final list = searchResult['song'] as List;
            return list.map((item) => SubsonicSong.fromJson(item as Map<String, dynamic>)).toList();
          }
        }
      }
      return [];
    } catch (e) {
      debugPrint('[SubsonicClient] searchSongs error: $e');
      return [];
    }
  }
}
