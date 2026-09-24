import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Soundstage Width Arc Visualizer (Mid-Side Matrix representation)
class SoundstageWidthVisualizer extends StatelessWidget {
  const SoundstageWidthVisualizer({
    super.key,
    required this.widthFactor, // 0.0 (Mono) to 3.0 (Super-Wide)
    required this.isActive,
    this.height = 36,
  });

  final double widthFactor;
  final bool isActive;
  final double height;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size(double.infinity, height),
        painter: _SoundstagePainter(
          widthFactor: widthFactor,
          isActive: isActive,
          colorScheme: Theme.of(context).colorScheme,
        ),
      ),
    );
  }
}

class _SoundstagePainter extends CustomPainter {
  _SoundstagePainter({
    required this.widthFactor,
    required this.isActive,
    required this.colorScheme,
  });

  final double widthFactor;
  final bool isActive;
  final ColorScheme colorScheme;

  static final Paint _arcPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round;

  static final Paint _centerPaint = Paint()..style = PaintingStyle.fill;

  @override
  void paint(Canvas canvas, Size size) {
    final centerX = size.width / 2;
    final bottomY = size.height - 4;
    final radius = size.height * 0.9;

    // Draw center listener dot
    _centerPaint.color = isActive ? colorScheme.primary : Colors.white24;
    canvas.drawCircle(Offset(centerX, bottomY), 3.0, _centerPaint);

    // Baseline 100% stereo arc
    _arcPaint.color = Colors.white.withValues(alpha: 0.1);
    _arcPaint.strokeWidth = 2.0;
    canvas.drawArc(
      Rect.fromCircle(center: Offset(centerX, bottomY), radius: radius),
      math.pi * 1.15,
      math.pi * 0.7,
      false,
      _arcPaint,
    );

    // Active expanded soundstage angle
    if (isActive) {
      // 1.0 factor = ~90 deg spread. 3.0 factor = ~160 deg spread. 0.0 = 0 deg (mono)
      final spreadAngle = (widthFactor / 3.0) * (math.pi * 0.85);
      final startAngle = (math.pi * 1.5) - (spreadAngle / 2);

      _arcPaint.color = colorScheme.primary;
      _arcPaint.strokeWidth = 3.5;
      canvas.drawArc(
        Rect.fromCircle(center: Offset(centerX, bottomY), radius: radius),
        startAngle,
        spreadAngle,
        false,
        _arcPaint,
      );

      // Left & Right speaker vector indicators
      final endLeftX = centerX + radius * math.cos(startAngle);
      final endLeftY = bottomY + radius * math.sin(startAngle);
      final endRightX = centerX + radius * math.cos(startAngle + spreadAngle);
      final endRightY = bottomY + radius * math.sin(startAngle + spreadAngle);

      canvas.drawCircle(Offset(endLeftX, endLeftY), 3.0, _centerPaint);
      canvas.drawCircle(Offset(endRightX, endRightY), 3.0, _centerPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SoundstagePainter oldDelegate) {
    return oldDelegate.widthFactor != widthFactor ||
        oldDelegate.isActive != isActive ||
        oldDelegate.colorScheme != colorScheme;
  }
}
