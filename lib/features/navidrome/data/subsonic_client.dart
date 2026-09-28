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

  /// Mengambil seluruh lagu dari perpustakaan server Navidrome secara komprehensif
  Future<List<SubsonicSong>> fetchAllSongs(
    SubsonicServerConfig config, {
    int maxSongs = 5000,
  }) async {
    final allSongs = <String, SubsonicSong>{};

    try {
      // 1. Initial batch with getRandomSongs (up to 500)
      final initialBatch = await getRandomSongs(config, size: 500);
      for (final s in initialBatch) {
        allSongs[s.id] = s;
      }

      // 2. Paginated search3 queries for complete catalog indexing
      int offset = 0;
      const batchSize = 500;
      bool hasMore = true;

      while (hasMore && allSongs.length < maxSongs) {
        final uri = '${config.sanitizedUrl}/rest/search3.view';
        final params = config.getAuthQueryParams();
        params['query'] = ' ';
        params['songCount'] = batchSize.toString();
        params['songOffset'] = offset.toString();

        final response = await _dio.get(uri, queryParameters: params);
        if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
          final subResp = response.data['subsonic-response'];
          if (subResp != null && subResp['status'] == 'ok') {
            final searchResult = subResp['searchResult3'];
            if (searchResult != null && searchResult['song'] is List) {
              final list = searchResult['song'] as List;
              if (list.isEmpty) {
                hasMore = false;
              } else {
                for (final item in list) {
                  final song = SubsonicSong.fromJson(item as Map<String, dynamic>);
                  allSongs[song.id] = song;
                }
                offset += list.length;
                if (list.length < batchSize) {
                  hasMore = false;
                }
              }
            } else {
              hasMore = false;
            }
          } else {
            hasMore = false;
          }
        } else {
          hasMore = false;
        }
      }
    } catch (e) {
      debugPrint('[SubsonicClient] fetchAllSongs error: $e');
    }

    return allSongs.values.toList();
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
