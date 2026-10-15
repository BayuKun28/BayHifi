import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../database/local_persistence_service.dart';
import '../../features/player/domain/track.dart';

/// Unified Studio Artwork Widget for Baydev HiFi
/// Reliably renders album artwork from memory bytes, local cached image files,
/// sidecar images, or remote network URLs with graceful studio fallbacks.
class StudioArtworkWidget extends StatelessWidget {
  final Track? track;
  final Uint8List? bytes;
  final String? url;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final double? width;
  final double? height;
  final dynamic fallbackIcon;
  final double fallbackIconSize;
  final Color? fallbackColor;
  final Color? backgroundColor;

  const StudioArtworkWidget({
    super.key,
    this.track,
    this.bytes,
    this.url,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.width,
    this.height,
    this.fallbackIcon = HugeIcons.strokeRoundedAlbum01,
    this.fallbackIconSize = 24.0,
    this.fallbackColor,
    this.backgroundColor,
  });

  /// Normalizes image URLs (e.g. converts YouTube AVIF image URLs with complex query parameters to clean, high-compatibility JPEGs)
  static String normalizeArtworkUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.trim().isEmpty) return '';
    final clean = rawUrl.trim();
    if (clean.contains('i.ytimg.com') && (clean.contains('sqp=') || clean.contains('hq720.jpg'))) {
      final match = RegExp(r'/vi/([^/]+)/').firstMatch(clean);
      if (match != null && match.group(1) != null) {
        return 'https://i.ytimg.com/vi/${match.group(1)}/hqdefault.jpg';
      }
    }
    return clean;
  }

  static bool _isLocalPath(String path) {
    if (kIsWeb) return false;
    if (path.startsWith('file://')) return true;
    if (path.startsWith('/home/') ||
        path.startsWith('/mnt/') ||
        path.startsWith('/data/') ||
        path.startsWith('/storage/') ||
        path.startsWith('/private/') ||
        path.startsWith('/Users/') ||
        path.startsWith('/var/') ||
        path.startsWith('/tmp/') ||
        RegExp(r'^[a-zA-Z]:[/\\]').hasMatch(path)) {
      return true;
    }
    try {
      final clean = path.startsWith('file://') ? Uri.parse(path).toFilePath() : path;
      return File(clean).existsSync();
    } catch (_) {
      return false;
    }
  }

  static String _resolveServerUrl(String relativePath) {
    if (kIsWeb) {
      return Uri.base.resolve(relativePath).toString();
    }
    final serverUrl = LocalPersistenceService.instance.getSetting<String>('bayhifi_cloud_server_url') ??
        'http://localhost:8111';
    final cleanBase = serverUrl.endsWith('/') ? serverUrl.substring(0, serverUrl.length - 1) : serverUrl;
    final cleanPath = relativePath.startsWith('/') ? relativePath : '/$relativePath';
    return '$cleanBase$cleanPath';
  }

  /// Helper to obtain an ImageProvider from a Track (for ThemeController, PaletteGenerator, etc.)
  static ImageProvider? getImageProvider(Track? track) {
    if (track == null) return null;

    if (track.albumArtBytes != null && track.albumArtBytes!.isNotEmpty) {
      return MemoryImage(track.albumArtBytes!);
    }

    final rawUrl = track.albumArtUrl;
    if (rawUrl != null && rawUrl.trim().isNotEmpty) {
      final cleanUrl = normalizeArtworkUrl(rawUrl);
      if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
        return NetworkImage(cleanUrl);
      } else if (_isLocalPath(cleanUrl)) {
        final filePath = cleanUrl.startsWith('file://')
            ? Uri.parse(cleanUrl).toFilePath()
            : cleanUrl;
        return FileImage(File(filePath));
      } else if (cleanUrl.startsWith('/')) {
        final resolved = _resolveServerUrl(cleanUrl);
        return NetworkImage(resolved);
      }
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final targetBytes = bytes ?? track?.albumArtBytes;
    final targetUrl = url ?? track?.albumArtUrl;

    Widget imageContent;

    if (targetBytes != null && targetBytes.isNotEmpty) {
      imageContent = Image.memory(
        targetBytes,
        fit: fit,
        width: width ?? double.infinity,
        height: height ?? double.infinity,
        errorBuilder: (context, error, stackTrace) => _buildFallback(theme, primary),
      );
    } else if (targetUrl != null && targetUrl.trim().isNotEmpty) {
      final cleanUrl = normalizeArtworkUrl(targetUrl);
      if (cleanUrl.startsWith('http://') || cleanUrl.startsWith('https://')) {
        imageContent = Image.network(
          cleanUrl,
          fit: fit,
          width: width ?? double.infinity,
          height: height ?? double.infinity,
          errorBuilder: (context, error, stackTrace) => _buildFallback(theme, primary),
        );
      } else if (_isLocalPath(cleanUrl)) {
        final filePath = cleanUrl.startsWith('file://')
            ? Uri.parse(cleanUrl).toFilePath()
            : cleanUrl;
        imageContent = Image.file(
          File(filePath),
          fit: fit,
          width: width ?? double.infinity,
          height: height ?? double.infinity,
          errorBuilder: (context, error, stackTrace) => _buildFallback(theme, primary),
        );
      } else if (cleanUrl.startsWith('/')) {
        final resolved = _resolveServerUrl(cleanUrl);
        imageContent = Image.network(
          resolved,
          fit: fit,
          width: width ?? double.infinity,
          height: height ?? double.infinity,
          errorBuilder: (context, error, stackTrace) => _buildFallback(theme, primary),
        );
      } else {
        imageContent = _buildFallback(theme, primary);
      }
    } else {
      imageContent = _buildFallback(theme, primary);
    }

    final container = Container(
      width: width,
      height: height,
      color: backgroundColor ?? theme.colorScheme.surfaceContainerHighest,
      child: imageContent,
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: container,
      );
    }

    return container;
  }

  Widget _buildFallback(ThemeData theme, Color primary) {
    return Center(
      child: HugeIcon(
        icon: fallbackIcon,
        size: fallbackIconSize,
        color: fallbackColor ?? primary.withValues(alpha: 0.7),
      ),
    );
  }
}
