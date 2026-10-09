import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../audio_engine/fft_processor.dart';
import '../../../settings/domain/player_customization_settings.dart';
import '../../../settings/presentation/controllers/player_customization_controller.dart';

import '../../../../audio_engine/soloud_controller.dart';

/// Widget visualizer spektrum FFT (RTA bars / Wave / Dots / Beam / Mirror Wave / VU Meter / Circular) real-time.
class SpectrumVisualizer extends ConsumerStatefulWidget {
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
  ConsumerState<SpectrumVisualizer> createState() => _SpectrumVisualizerState();
}

class _SpectrumVisualizerState extends ConsumerState<SpectrumVisualizer> {
  late final String _demandKey;

  @override
  void initState() {
    super.initState();
    _demandKey = 'SpectrumVisualizer_${identityHashCode(this)}';
    SoLoudController.instance.acquireVisualizationDemand(_demandKey);
  }

  @override
  void dispose() {
    SoLoudController.instance.releaseVisualizationDemand(_demandKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rtaAsync = ref.watch(rtaSpectrumProvider);
    final settings = ref.watch(playerCustomizationProvider);
    final primary = Theme.of(context).colorScheme.primary;
    final activeColor = widget.barColor ?? primary;

    return RepaintBoundary(
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: rtaAsync.when(
          data: (magnitudes) => CustomPaint(
            painter: _RtaCustomPainter(
              magnitudes: magnitudes,
              barColor: activeColor,
              showPeakHold: widget.showPeakHold,
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
      case SpectrumStyle.m3Expressive:
        _paintM3Expressive(canvas, size, count);
        break;
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
      case SpectrumStyle.mirrorWave:
        _paintMirrorWave(canvas, size, count);
        break;
      case SpectrumStyle.vuMeter:
        _paintVuMeter(canvas, size, count);
        break;
      case SpectrumStyle.circular:
        _paintCircular(canvas, size, count);
        break;
    }
  }

  void _paintM3Expressive(Canvas canvas, Size size, int count) {
    const double spacing = 2.5;
    final double totalSpacing = (count - 1) * spacing;
    final double barWidth = (size.width - totalSpacing) / count;
    if (barWidth <= 0) return;

    final radius = Radius.circular(math.min(barWidth / 2, 4.0));

    // Baseline soft glow
    final baselinePaint = Paint()
      ..color = barColor.withValues(alpha: 0.15)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, size.height - 0.5), Offset(size.width, size.height - 0.5), baselinePaint);

    for (int i = 0; i < count; i++) {
      final double mag = magnitudes[i].clamp(0.0, 1.0);
      final double barHeight = math.max(3.0, mag * (size.height - 6));
      final double x = i * (barWidth + spacing);
      final double y = size.height - barHeight;

      // Dynamic Material 3 Expressive gradient along column
      final rectBounds = Rect.fromLTWH(x, y, barWidth, barHeight);
      final gradient = LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [
          barColor.withValues(alpha: 0.45 + (mag * 0.35)),
          barColor.withValues(alpha: 0.95),
        ],
      ).createShader(rectBounds);

      _paint.shader = gradient;
      _paint.style = PaintingStyle.fill;

      final rrect = RRect.fromRectAndRadius(rectBounds, radius);
      canvas.drawRRect(rrect, _paint);
      _paint.shader = null;

      // Floating M3 squircle peak hold pill
      if (showPeakHold && mag > 0.04) {
        final peakY = math.max(0.0, y - 4.0);
        final peakRect = RRect.fromRectAndRadius(
          Rect.fromLTWH(x, peakY, barWidth, 2.2),
          const Radius.circular(1.1),
        );
        _peakPaint.color = barColor.withValues(alpha: 0.9);
        canvas.drawRRect(peakRect, _peakPaint);
      }
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

    final Paint centerLine = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.9)
      ..strokeWidth = 1.0;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), centerLine);
  }

  void _paintMirrorWave(Canvas canvas, Size size, int count) {
    final double midY = size.height * 0.5;
    final Path topPath = Path();
    final Path btmPath = Path();
    final Path fillArea = Path();

    final double step = size.width / (count - 1);
    topPath.moveTo(0, midY - (magnitudes[0].clamp(0.0, 1.0) * midY * 0.9));
    btmPath.moveTo(0, midY + (magnitudes[0].clamp(0.0, 1.0) * midY * 0.9));
    fillArea.moveTo(0, midY);

    for (int i = 1; i < count; i++) {
      final double x = i * step;
      final double amp = magnitudes[i].clamp(0.0, 1.0) * midY * 0.9;
      final double prevX = (i - 1) * step;
      final double prevAmp = magnitudes[i - 1].clamp(0.0, 1.0) * midY * 0.9;

      final double cX = prevX + (x - prevX) / 2;
      topPath.cubicTo(cX, midY - prevAmp, cX, midY - amp, x, midY - amp);
      btmPath.cubicTo(cX, midY + prevAmp, cX, midY + amp, x, midY + amp);
    }

    // Fill area between curves
    fillArea.addPath(topPath, Offset.zero);
    fillArea.lineTo(size.width, midY);
    fillArea.addPath(btmPath, Offset.zero);
    fillArea.close();

    _paint.color = barColor.withValues(alpha: 0.18);
    _paint.style = PaintingStyle.fill;
    canvas.drawPath(fillArea, _paint);

    _strokePaint.color = barColor;
    _strokePaint.strokeWidth = 1.8;
    canvas.drawPath(topPath, _strokePaint);
    canvas.drawPath(btmPath, _strokePaint);

    // Subtle 1px axis line
    final axisPaint = Paint()
      ..color = barColor.withValues(alpha: 0.4)
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), axisPaint);
  }

  void _paintVuMeter(Canvas canvas, Size size, int count) {
    final halfWidth = size.width / 2;

    // Calculate RMS energy for Left (lower half) & Right (upper half)
    double leftEnergy = 0.0;
    double rightEnergy = 0.0;
    final halfCount = count ~/ 2;

    for (int i = 0; i < halfCount; i++) {
      leftEnergy += magnitudes[i];
    }
    for (int i = halfCount; i < count; i++) {
      rightEnergy += magnitudes[i];
    }
    leftEnergy = (leftEnergy / halfCount * 2.2).clamp(0.0, 1.0);
    rightEnergy = (rightEnergy / (count - halfCount) * 2.2).clamp(0.0, 1.0);

    _paintSingleVuDial(canvas, Rect.fromLTWH(4, 2, halfWidth - 8, size.height - 4), leftEnergy, 'CH-L');
    _paintSingleVuDial(canvas, Rect.fromLTWH(halfWidth + 4, 2, halfWidth - 8, size.height - 4), rightEnergy, 'CH-R');
  }

  void _paintSingleVuDial(Canvas canvas, Rect bounds, double energy, String label) {
    // Dial frame background
    final frameRRect = RRect.fromRectAndRadius(bounds, const Radius.circular(6));
    final bgPaint = Paint()..color = const Color(0xFF14171E);
    canvas.drawRRect(frameRRect, bgPaint);

    final borderPaint = Paint()
      ..color = const Color(0xFF262D3D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawRRect(frameRRect, borderPaint);

    // Arc track
    final pivot = Offset(bounds.center.dx, bounds.bottom + 6);
    final radius = bounds.height * 1.1;

    final arcPaint = Paint()
      ..color = const Color(0xFF334155)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawArc(
      Rect.fromCircle(center: pivot, radius: radius),
      math.pi * 1.25,
      math.pi * 0.5,
      false,
      arcPaint,
    );

    // Needle Angle: -40 deg to +40 deg
    final needleAngle = (math.pi * 1.5) + ((energy - 0.5) * (math.pi * 0.45));
    final needleEnd = Offset(
      pivot.dx + radius * math.cos(needleAngle),
      pivot.dy + radius * math.sin(needleAngle),
    );

    final needlePaint = Paint()
      ..color = energy > 0.85 ? const Color(0xFFFF453A) : barColor
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(pivot, needleEnd, needlePaint);

    // Pivot cap
    canvas.drawCircle(pivot, 3, Paint()..color = const Color(0xFF64748B));
  }

  void _paintCircular(Canvas canvas, Size size, int count) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.height * 0.35;

    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * math.pi;
      final mag = magnitudes[i].clamp(0.0, 1.0);
      final barLen = 2.0 + (mag * size.height * 0.45);

      final startOffset = Offset(
        center.dx + baseRadius * math.cos(angle),
        center.dy + baseRadius * math.sin(angle),
      );
      final endOffset = Offset(
        center.dx + (baseRadius + barLen) * math.cos(angle),
        center.dy + (baseRadius + barLen) * math.sin(angle),
      );

      final color = Color.lerp(
        barColor.withValues(alpha: 0.5),
        const Color(0xFF00E5FF),
        mag,
      )!;

      final paint = Paint()
        ..color = color
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(startOffset, endOffset, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _RtaCustomPainter oldDelegate) {
    return oldDelegate.magnitudes != magnitudes ||
        oldDelegate.style != style ||
        oldDelegate.barColor != barColor;
  }
}
