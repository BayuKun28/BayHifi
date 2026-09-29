import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Result envelope for lyric card share & save operations
class ShareActionResult {
  final bool success;
  final String? savedFilePath;
  final String? displayLocation;
  final String? errorMessage;
  final bool isMissingPlugin;

  const ShareActionResult({
    required this.success,
    this.savedFilePath,
    this.displayLocation,
    this.errorMessage,
    this.isMissingPlugin = false,
  });
}

/// High-performance offscreen and widget rasterization service for Studio Lyric Cards
class LyricImageGenerator {
  const LyricImageGenerator._();

  /// Captures a [RepaintBoundary] identified by [boundaryKey] into PNG [Uint8List] bytes.
  static Future<Uint8List?> capturePng(
    GlobalKey boundaryKey, {
    double pixelRatio = 3.0,
  }) async {
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject()
          as RenderRepaintBoundary?;

      if (boundary == null) {
        debugPrint('[LyricImageGenerator] Error: RenderRepaintBoundary is null');
        return null;
      }

      // Check if the boundary is currently painting or needs layout
      if (boundary.debugNeedsPaint) {
        await Future.delayed(const Duration(milliseconds: 20));
      }

      final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
      final ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);

      if (byteData == null) {
        debugPrint('[LyricImageGenerator] Error: ByteData is null after image conversion');
        return null;
      }

      return byteData.buffer.asUint8List();
    } catch (e, stack) {
      debugPrint('[LyricImageGenerator] Capture error: $e\n$stack');
      return null;
    }
  }

  /// Writes PNG bytes to the device's public Pictures / Gallery directory so it appears in Photos/Gallery
  static Future<File?> saveBytesToPublicGallery(
    Uint8List bytes, {
    String prefix = 'baydev_hifi_lyric',
  }) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${prefix}_$timestamp.png';
      Directory? targetDir;

      if (!kIsWeb && Platform.isAndroid) {
        // Try public Pictures/BayHifi directory for direct gallery visibility
        try {
          final publicDir = Directory('/storage/emulated/0/Pictures/BayHifi');
          if (!await publicDir.exists()) {
            await publicDir.create(recursive: true);
          }
          if (await publicDir.exists()) {
            targetDir = publicDir;
          }
        } catch (_) {}

        if (targetDir == null) {
          try {
            final extDirs = await getExternalStorageDirectories(type: StorageDirectory.pictures);
            if (extDirs != null && extDirs.isNotEmpty) {
              targetDir = extDirs.first;
            }
          } catch (_) {}
        }
      } else if (!kIsWeb && (Platform.isLinux || Platform.isWindows)) {
        try {
          final downloads = await getDownloadsDirectory();
          if (downloads != null) {
            final bayHifiDir = Directory('${downloads.path}/BayHifi');
            if (!await bayHifiDir.exists()) {
              await bayHifiDir.create(recursive: true);
            }
            targetDir = bayHifiDir;
          }
        } catch (_) {}
      } else if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
        try {
          targetDir = await getApplicationDocumentsDirectory();
        } catch (_) {}
      }

      // Fallback to application documents or temp directory
      targetDir ??= await getApplicationDocumentsDirectory();

      final file = File('${targetDir.path}/$fileName');
      await file.writeAsBytes(bytes, flush: true);
      debugPrint('[LyricImageGenerator] Successfully saved image to: ${file.path}');
      return file;
    } catch (e) {
      debugPrint('[LyricImageGenerator] Gallery save error: $e');
      // Fallback to temp cache directory if public write fails
      return saveBytesToTempCache(bytes, prefix: prefix);
    }
  }

  /// Writes PNG bytes to temporary cache directory and returns the generated [File].
  static Future<File?> saveBytesToTempCache(
    Uint8List bytes, {
    String prefix = 'baydev_hifi_lyrics',
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final file = File('${tempDir.path}/${prefix}_$timestamp.png');
      await file.writeAsBytes(bytes, flush: true);
      return file;
    } catch (e) {
      debugPrint('[LyricImageGenerator] Cache write error: $e');
      return null;
    }
  }

  /// Triggers native OS sharing dialog with the generated image file.
  static Future<ShareResult?> shareImageFile(
    File imageFile, {
    String? subject,
    String? text,
  }) async {
    try {
      final xFile = XFile(imageFile.path, mimeType: 'image/png');
      return await SharePlus.instance.share(
        ShareParams(
          files: [xFile],
          text: text,
          subject: subject,
        ),
      );
    } on MissingPluginException catch (e) {
      debugPrint('[LyricImageGenerator] Native share MissingPluginException: $e');
      rethrow;
    } catch (e) {
      debugPrint('[LyricImageGenerator] Native share error: $e');
      rethrow;
    }
  }

  /// Complete pipeline: capture -> save to public gallery -> trigger native share sheet
  static Future<ShareActionResult> captureAndShare(
    GlobalKey boundaryKey, {
    double pixelRatio = 3.0,
    String? trackTitle,
    String? artistName,
  }) async {
    final bytes = await capturePng(boundaryKey, pixelRatio: pixelRatio);
    if (bytes == null) {
      return const ShareActionResult(
        success: false,
        errorMessage: 'Could not rasterize lyric card.',
      );
    }

    final file = await saveBytesToPublicGallery(bytes);
    if (file == null) {
      return const ShareActionResult(
        success: false,
        errorMessage: 'Could not write image to device storage.',
      );
    }

    final subject = trackTitle != null
        ? 'Lyrics from $trackTitle - $artistName'
        : 'Baydev HiFi Lyric Card';
    final shareText = trackTitle != null
        ? 'Shared from Baydev HiFi • $trackTitle by $artistName'
        : 'Shared from Baydev HiFi Studio';

    try {
      final result = await shareImageFile(
        file,
        subject: subject,
        text: shareText,
      );

      final isOk = result != null && result.status != ShareResultStatus.unavailable;
      return ShareActionResult(
        success: isOk,
        savedFilePath: file.path,
      );
    } on MissingPluginException {
      // Hot-reload session missing native plugin channel: saved to gallery successfully!
      return ShareActionResult(
        success: true,
        savedFilePath: file.path,
        isMissingPlugin: true,
        errorMessage: 'Saved to Gallery! (Restart app to enable direct native share)',
      );
    } catch (e) {
      return ShareActionResult(
        success: true,
        savedFilePath: file.path,
        errorMessage: 'Saved to Gallery! ($e)',
      );
    }
  }
}
