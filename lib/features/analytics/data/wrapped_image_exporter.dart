import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

/// Helper utility for capturing high-definition PNG screenshots from RepaintBoundary and native sharing.
class WrappedImageExporter {
  WrappedImageExporter._();

  /// Captures a RepaintBoundary widget into high-resolution PNG bytes (pixelRatio 3.0 = 1080p+)
  static Future<Uint8List?> capturePng(
    GlobalKey boundaryKey, {
    double pixelRatio = 3.0,
  }) async {
    try {
      final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return null;

      final image = await boundary.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      return byteData?.buffer.asUint8List();
    } catch (e) {
      debugPrint('[WrappedImageExporter] Failed to capture widget to image: $e');
      return null;
    }
  }

  /// Exports the card image and invokes native OS share dialog via share_plus
  static Future<bool> shareRecapCard(
    GlobalKey boundaryKey, {
    String subject = 'Baydev HiFi Studio Wrapped',
  }) async {
    final bytes = await capturePng(boundaryKey);
    if (bytes == null) return false;

    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/baydev_hifi_wrapped_${DateTime.now().millisecondsSinceEpoch}.png';
      final file = File(filePath);
      await file.writeAsBytes(bytes, flush: true);

      final result = await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: 'image/png')],
          text: 'My Studio Wrapped on Baydev HiFi — Lossless Audio & DSP Mastering Workstation!',
          subject: subject,
        ),
      );
      return result.status == ShareResultStatus.success || result.status == ShareResultStatus.dismissed;
    } catch (e) {
      debugPrint('[WrappedImageExporter] Failed to share image: $e');
      return false;
    }
  }
}
