import 'package:flutter/material.dart';
import '../../../../player/domain/track.dart';
import '../../../domain/models/lyric_card_theme.dart';
import 'studio_qr_encoder.dart';

/// Studio QR Deep Link Badge for Lyric Cards.
/// Renders a crisp vector QR code with squircle modules linking to the audio track.
class LyricQrLinkBadge extends StatelessWidget {
  final Track track;
  final LyricCardColors colors;
  final double scale;
  final double size;
  final bool showLabel;
  final String? customUrl;

  const LyricQrLinkBadge({
    super.key,
    required this.track,
    required this.colors,
    this.scale = 1.0,
    this.size = 44.0,
    this.showLabel = true,
    this.customUrl,
  });

  String _buildTrackUrl() {
    if (customUrl != null && customUrl!.isNotEmpty) {
      return customUrl!;
    }
    if (track.remoteUrl != null && track.remoteUrl!.startsWith('http')) {
      return track.remoteUrl!;
    }
    // Deep link fallback
    final title = Uri.encodeComponent(track.title);
    final artist = Uri.encodeComponent(track.artist);
    return 'https://baydev.hifi/track?title=$title&artist=$artist';
  }

  @override
  Widget build(BuildContext context) {
    final url = _buildTrackUrl();
    final effectiveSize = size * scale;
    final grid = StudioQrEncoder.encode(url);

    return Container(
      padding: EdgeInsets.all(4.0 * scale),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6.0 * scale),
        border: Border.all(
          color: colors.borderColor.withValues(alpha: 0.8),
          width: 0.8 * scale,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 6 * scale,
            offset: Offset(0, 2 * scale),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: effectiveSize,
            height: effectiveSize,
            child: CustomPaint(
              painter: _StudioQrPainter(
                grid: grid,
                moduleColor: const Color(0xFF0F1218),
              ),
            ),
          ),
          if (showLabel) ...[
            SizedBox(height: 2.0 * scale),
            Text(
              'SCAN // PLAY',
              style: TextStyle(
                fontFamily: 'monospace',
                color: const Color(0xFF0F1218),
                fontSize: (6.0 * scale).clamp(4.5, 9.0),
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StudioQrPainter extends CustomPainter {
  final List<List<bool>> grid;
  final Color moduleColor;
  final Paint _paint;

  _StudioQrPainter({
    required this.grid,
    required this.moduleColor,
  }) : _paint = Paint()
          ..isAntiAlias = true
          ..color = moduleColor
          ..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    if (grid.isEmpty) return;
    final count = grid.length;
    final moduleSize = size.width / count;
    final radius = Radius.circular(moduleSize * 0.28);

    for (int r = 0; r < count; r++) {
      for (int c = 0; c < count; c++) {
        if (grid[r][c]) {
          final rect = Rect.fromLTWH(
            c * moduleSize,
            r * moduleSize,
            moduleSize,
            moduleSize,
          );
          canvas.drawRRect(
            RRect.fromRectAndRadius(rect, radius),
            _paint,
          );
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StudioQrPainter oldDelegate) {
    return oldDelegate.grid != grid || oldDelegate.moduleColor != moduleColor;
  }
}
