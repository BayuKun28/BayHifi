import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Analog VU Level Meter dengan zero allocation pada paint() dan RepaintBoundary
class VuLevelMeter extends StatelessWidget {
  const VuLevelMeter({
    super.key,
    required this.levelDb,
    this.peakDb = 0.0,
    this.height = 28,
  });

  final double levelDb; // e.g. -24.0 s/d +12.0 dB
  final double peakDb;
  final double height;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        size: Size(double.infinity, height),
        painter: _VuMeterPainter(
          levelDb: levelDb,
          peakDb: peakDb,
          isDark: Theme.of(context).brightness == Brightness.dark,
        ),
      ),
    );
  }
}

class _VuMeterPainter extends CustomPainter {
  _VuMeterPainter({
    required this.levelDb,
    required this.peakDb,
    required this.isDark,
  });

  final double levelDb;
  final double peakDb;
  final bool isDark;

  static final Paint _bgPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _barPaint = Paint()..style = PaintingStyle.fill;
  static final Paint _tickPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 1.0;

  @override
  void paint(Canvas canvas, Size size) {
    _bgPaint.color = isDark ? const Color(0xFF0D0F14) : const Color(0xFFE2E6ED);
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(6),
    );
    canvas.drawRRect(rrect, _bgPaint);

    // Map -24 dB s/d +12 dB to 0.0 s/d 1.0
    // 0 dB is at (24 / 36) = 66.7% of the width
    final clampedDb = levelDb.clamp(-24.0, 12.0);
    final normalized = (clampedDb + 24.0) / 36.0;
    final fillWidth = size.width * normalized;

    if (fillWidth > 0) {
      // Draw segmented or smooth gradient bar
      final zeroDbX = size.width * (24.0 / 36.0);

      // Green / Normal zone (up to 0 dB)
      final greenWidth = math.min(fillWidth, zeroDbX);
      if (greenWidth > 0) {
        _barPaint.color = const Color(0xFF00E676);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(2, 2, greenWidth - 2, size.height - 4),
            const Radius.circular(4),
          ),
          _barPaint,
        );
      }

      // Amber / Headroom zone (0 dB to +6 dB)
      final sixDbX = size.width * (30.0 / 36.0);
      if (fillWidth > zeroDbX) {
        final amberWidth = math.min(fillWidth, sixDbX) - zeroDbX;
        _barPaint.color = const Color(0xFFFF9F0A);
        canvas.drawRect(
          Rect.fromLTWH(zeroDbX, 2, amberWidth, size.height - 4),
          _barPaint,
        );
      }

      // Red / Clip zone (+6 dB to +12 dB)
      if (fillWidth > sixDbX) {
        final redWidth = fillWidth - sixDbX;
        _barPaint.color = const Color(0xFFFF3B30);
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(sixDbX, 2, redWidth - 2, size.height - 4),
            const Radius.circular(4),
          ),
          _barPaint,
        );
      }
    }

    // Draw reference tick marks at -18, -12, -6, 0 dB
    _tickPaint.color = isDark ? Colors.white24 : Colors.black26;
    final ticks = [-18.0, -12.0, -6.0, 0.0, 6.0];
    for (final tick in ticks) {
      final x = size.width * ((tick + 24.0) / 36.0);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), _tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _VuMeterPainter oldDelegate) {
    return oldDelegate.levelDb != levelDb ||
        oldDelegate.peakDb != peakDb ||
        oldDelegate.isDark != isDark;
  }
}
