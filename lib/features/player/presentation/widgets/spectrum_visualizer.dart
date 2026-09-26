import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../audio_engine/fft_processor.dart';
import '../../../settings/domain/player_customization_settings.dart';
import '../../../settings/presentation/controllers/player_customization_controller.dart';

/// Widget visualizer spektrum FFT (RTA bars / Wave / Dots / Beam) real-time 60fps dengan Material 3 Expressive glow.
class SpectrumVisualizer extends ConsumerWidget {
  final double height;
  final Color? barColor;
  final bool showPeakHold;

  const SpectrumVisualizer({
    super.key,
    this.height = 40,
    this.barColor,
    this.showPeakHold = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rtaAsync = ref.watch(rtaSpectrumProvider);
    final settings = ref.watch(playerCustomizationProvider);
    final primary = Theme.of(context).colorScheme.primary;
    final activeColor = barColor ?? primary;

    return RepaintBoundary(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: rtaAsync.when(
          data: (magnitudes) => CustomPaint(
            painter: _RtaCustomPainter(
              magnitudes: magnitudes,
              barColor: activeColor,
              showPeakHold: showPeakHold,
              style: settings.spectrumStyle,
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (err, stack) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _RtaCustomPainter extends CustomPainter {
  final List<double> magnitudes;
  final Color barColor;
  final bool showPeakHold;
  final SpectrumStyle style;

  // Cached paint objects
  final Paint _paint = Paint()..isAntiAlias = true;
  final Paint _strokePaint = Paint()
    ..isAntiAlias = true
    ..style = PaintingStyle.stroke;
  final Paint _peakPaint = Paint()
    ..isAntiAlias = true
    ..strokeWidth = 2.0;

  _RtaCustomPainter({
    required this.magnitudes,
    required this.barColor,
    required this.showPeakHold,
    required this.style,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (magnitudes.isEmpty) return;

    final int count = magnitudes.length;

    switch (style) {
      case SpectrumStyle.bars:
        _paintBars(canvas, size, count);
        break;
      case SpectrumStyle.wave:
        _paintWave(canvas, size, count);
        break;
      case SpectrumStyle.dots:
        _paintDots(canvas, size, count);
        break;
      case SpectrumStyle.beam:
        _paintBeam(canvas, size, count);
        break;
    }
  }

  void _paintBars(Canvas canvas, Size size, int count) {
    const double spacing = 2.0;
    final double totalSpacing = (count - 1) * spacing;
    final double barWidth = (size.width - totalSpacing) / count;
    if (barWidth <= 0) return;

    for (int i = 0; i < count; i++) {
      final double mag = magnitudes[i].clamp(0.0, 1.0);
      final double barHeight = math.max(2.0, mag * size.height);
      final double x = i * (barWidth + spacing);
      final double y = size.height - barHeight;

      final color = Color.lerp(
        barColor.withValues(alpha: 0.6),
        AppColors.mintTarget,
        mag,
      )!;

      _paint.color = color;
      _paint.style = PaintingStyle.fill;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(2),
      );

      canvas.drawRRect(rect, _paint);

      if (showPeakHold && mag > 0.05) {
        _peakPaint.color = color.withValues(alpha: 0.9);
        canvas.drawLine(
          Offset(x, y - 2),
          Offset(x + barWidth, y - 2),
          _peakPaint,
        );
      }
    }
  }

  void _paintWave(Canvas canvas, Size size, int count) {
    final Path path = Path();
    final Path fillPath = Path();

    final double step = size.width / (count - 1);
    path.moveTo(0, size.height - (magnitudes[0].clamp(0.0, 1.0) * size.height));
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(0, size.height - (magnitudes[0].clamp(0.0, 1.0) * size.height));

    for (int i = 1; i < count; i++) {
      final double x = i * step;
      final double y = size.height - (magnitudes[i].clamp(0.0, 1.0) * size.height);
      final double prevX = (i - 1) * step;
      final double prevY = size.height - (magnitudes[i - 1].clamp(0.0, 1.0) * size.height);

      final double cX1 = prevX + (x - prevX) / 2;
      final double cY1 = prevY;
      final double cX2 = prevX + (x - prevX) / 2;
      final double cY2 = y;

      path.cubicTo(cX1, cY1, cX2, cY2, x, y);
      fillPath.cubicTo(cX1, cY1, cX2, cY2, x, y);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    // Fill gradient
    final fillGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        barColor.withValues(alpha: 0.35),
        barColor.withValues(alpha: 0.0),
      ],
    ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    _paint.shader = fillGradient;
    _paint.style = PaintingStyle.fill;
    canvas.drawPath(fillPath, _paint);
    _paint.shader = null;

    // Stroke line
    _strokePaint.color = barColor;
    _strokePaint.strokeWidth = 2.0;
    canvas.drawPath(path, _strokePaint);
  }

  void _paintDots(Canvas canvas, Size size, int count) {
    final double step = size.width / count;
    for (int i = 0; i < count; i++) {
      final double mag = magnitudes[i].clamp(0.0, 1.0);
      final double x = (i + 0.5) * step;
      final double y = size.height - (mag * size.height);
      final double radius = 2.0 + (mag * 2.5);

      final color = Color.lerp(
        barColor.withValues(alpha: 0.5),
        const Color(0xFF00E5FF),
        mag,
      )!;

      _paint.color = color;
      _paint.style = PaintingStyle.fill;
      canvas.drawCircle(Offset(x, y), radius, _paint);

      if (mag > 0.3) {
        _strokePaint.color = color.withValues(alpha: 0.3);
        _strokePaint.strokeWidth = 1.0;
        canvas.drawCircle(Offset(x, y), radius + 2.5, _strokePaint);
      }
    }
  }

  void _paintBeam(Canvas canvas, Size size, int count) {
    final double midY = size.height * 0.5;
    final Path topPath = Path();
    final Path btmPath = Path();

    final double step = size.width / (count - 1);
    topPath.moveTo(0, midY);
    btmPath.moveTo(0, midY);

    for (int i = 0; i < count; i++) {
      final double x = i * step;
      final double halfAmp = (magnitudes[i].clamp(0.0, 1.0) * size.height * 0.45);
      topPath.lineTo(x, midY - halfAmp);
      btmPath.lineTo(x, midY + halfAmp);
    }

    _strokePaint.color = barColor;
    _strokePaint.strokeWidth = 1.8;
    canvas.drawPath(topPath, _strokePaint);

    _strokePaint.color = barColor.withValues(alpha: 0.7);
    _strokePaint.strokeWidth = 1.4;
    canvas.drawPath(btmPath, _strokePaint);

    // Center laser line
    final Paint centerLine = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.9)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), centerLine);
  }

  @override
  bool shouldRepaint(covariant _RtaCustomPainter oldDelegate) {
    return oldDelegate.magnitudes != magnitudes ||
        oldDelegate.style != style ||
        oldDelegate.barColor != barColor;
  }
}
