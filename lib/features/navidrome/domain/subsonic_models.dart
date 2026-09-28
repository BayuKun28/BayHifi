import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../../player/domain/track.dart';

/// Konfigurasi koneksi server Navidrome / Subsonic API
@immutable
class SubsonicServerConfig {
  const SubsonicServerConfig({
    required this.serverUrl,
    required this.username,
    required this.password,
    this.clientName = 'BaydevHiFi',
    this.apiVersion = '1.16.1',
  });

  final String serverUrl;
  final String username;
  final String password;
  final String clientName;
  final String apiVersion;

  /// Sanitasi URL agar tidak diakhiri dengan trailing slash
  String get sanitizedUrl {
    var url = serverUrl.trim();
    while (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }

  /// Membuat query parameters autentikasi Subsonic API (Token MD5 + Salt)
  Map<String, String> getAuthQueryParams() {
    final salt = _generateRandomSalt();
    final token = md5.convert(utf8.encode('$password$salt')).toString();

    return {
      'u': username.trim(),
      't': token,
      's': salt,
      'v': apiVersion,
      'c': clientName,
      'f': 'json',
    };
  }

  /// URL streaming direct lossless tanpa transcode server
  String buildStreamUrl(String songId) {
    final params = getAuthQueryParams();
    params['id'] = songId;
    params['format'] = 'raw'; // Request bit-perfect original FLAC/Lossless stream
    final queryString = Uri(queryParameters: params).query;
    return '$sanitizedUrl/rest/stream.view?$queryString';
  }

  /// URL untuk mengambil album cover art
  String buildCoverArtUrl(String coverArtId, {int size = 500}) {
    final params = getAuthQueryParams();
    params['id'] = coverArtId;
    params['size'] = size.toString();
    final queryString = Uri(queryParameters: params).query;
    return '$sanitizedUrl/rest/getCoverArt.view?$queryString';
  }

  static String _generateRandomSalt([int length = 12]) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rand = Random.secure();
    return List.generate(length, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  SubsonicServerConfig copyWith({
    String? serverUrl,
    String? username,
    String? password,
    String? clientName,
    String? apiVersion,
  }) {
    return SubsonicServerConfig(
      serverUrl: serverUrl ?? this.serverUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      clientName: clientName ?? this.clientName,
      apiVersion: apiVersion ?? this.apiVersion,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'serverUrl': serverUrl,
      'username': username,
      'password': password,
      'clientName': clientName,
      'apiVersion': apiVersion,
    };
  }

  factory SubsonicServerConfig.fromMap(Map<String, dynamic> map) {
    return SubsonicServerConfig(
      serverUrl: map['serverUrl'] as String? ?? '',
      username: map['username'] as String? ?? '',
      password: map['password'] as String? ?? '',
      clientName: map['clientName'] as String? ?? 'BaydevHiFi',
      apiVersion: map['apiVersion'] as String? ?? '1.16.1',
    );
  }
}

/// Status koneksi Navidrome
enum NavidromeConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}

/// Representasi Lagu dari Subsonic Server
@immutable
class SubsonicSong {
  const SubsonicSong({
    required this.id,
    required this.title,
    required this.artist,
    required this.album,
    required this.duration,
    this.bitRate,
    this.suffix,
    this.contentType,
    this.coverArt,
    this.size,
  });

  final String id;
  final String title;
  final String artist;
  final String album;
  final Duration duration;
  final int? bitRate;
  final String? suffix;
  final String? contentType;
  final String? coverArt;
  final int? size;

  factory SubsonicSong.fromJson(Map<String, dynamic> json) {
    return SubsonicSong(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? 'Unknown Title',
      artist: json['artist'] as String? ?? 'Unknown Artist',
      album: json['album'] as String? ?? 'Unknown Album',
      duration: Duration(seconds: json['duration'] as int? ?? 0),
      bitRate: json['bitRate'] as int?,
      suffix: (json['suffix'] as String?)?.toLowerCase(),
      contentType: json['contentType'] as String?,
      coverArt: json['coverArt'] as String?,
      size: json['size'] as int?,
    );
  }

  /// Konversi SubsonicSong menjadi Track generik Baydev HiFi
  Track toTrack(SubsonicServerConfig config) {
    final fmt = _resolveFormat(suffix);
    final isLossless = fmt == AudioFormat.flac || fmt == AudioFormat.alac || fmt == AudioFormat.wav;

    return Track(
      id: 'navidrome_$id',
      title: title,
      artist: artist,
      album: album,
      duration: duration,
      remoteUrl: config.buildStreamUrl(id),
      albumArtUrl: coverArt != null ? config.buildCoverArtUrl(coverArt!) : null,
      format: fmt,
      sampleRate: isLossless ? 96000 : 44100, // Detected or parsed streaminfo
      bitDepth: isLossless ? 24 : 16,
    );
  }

  static AudioFormat _resolveFormat(String? ext) {
    switch (ext) {
      case 'flac':
        return AudioFormat.flac;
      case 'wav':
        return AudioFormat.wav;
      case 'mp3':
        return AudioFormat.mp3;
      case 'ogg':
        return AudioFormat.ogg;
      case 'opus':
        return AudioFormat.opus;
      case 'm4a':
      case 'alac':
        return AudioFormat.alac;
      case 'dsf':
      case 'dff':
        return AudioFormat.dsd;
      default:
        return AudioFormat.unknown;
    }
  }
}
