import 'package:flutter/material.dart';
import '../../../domain/models/lyric_sticker_model.dart';

/// Decorative angled audiophile stamp sticker badge
class LyricStickerBadge extends StatelessWidget {
  final LyricStickerType sticker;
  final double scale;
  final double angle;

  const LyricStickerBadge({
    super.key,
    required this.sticker,
    this.scale = 1.0,
    this.angle = -0.06, // Slight tilt in radians
  });

  @override
  Widget build(BuildContext context) {
    final color = sticker.badgeColor;

    return Transform.rotate(
      angle: angle,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: 9.0 * scale,
          vertical: 4.5 * scale,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(6.0 * scale),
          border: Border.all(
            color: color.withValues(alpha: 0.85),
            width: 1.2 * scale,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              sticker.icon,
              size: 11.5 * scale,
              color: color,
            ),
            SizedBox(width: 4.5 * scale),
            Text(
              sticker.label,
              style: TextStyle(
                color: color,
                fontSize: 8.5 * scale,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.7,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
