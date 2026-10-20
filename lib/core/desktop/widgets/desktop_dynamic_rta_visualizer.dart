import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:baydev_hifi/app/theme/app_colors.dart';
import 'package:baydev_hifi/audio_engine/fft_processor.dart';
import 'package:baydev_hifi/audio_engine/soloud_controller.dart';
import 'package:baydev_hifi/features/player/presentation/controllers/player_controller.dart';
import 'package:baydev_hifi/features/settings/domain/player_customization_settings.dart';

/// Dynamic Live Mini RTA Visualizer for Desktop Master Transport Deck
class DesktopDynamicRtaVisualizer extends ConsumerStatefulWidget {
  final SpectrumStyle style;

  const DesktopDynamicRtaVisualizer({super.key, required this.style});

  @override
  ConsumerState<DesktopDynamicRtaVisualizer> createState() => _DesktopDynamicRtaVisualizerState();
}

class _DesktopDynamicRtaVisualizerState extends ConsumerState<DesktopDynamicRtaVisualizer> {
  late final String _demandKey;

  @override
  void initState() {
    super.initState();
    _demandKey = 'DesktopDynamicRtaVisualizer_${identityHashCode(this)}';
    SoLoudController.instance.acquireVisualizationDemand(_demandKey);
  }

  @override
  void dispose() {
    SoLoudController.instance.releaseVisualizationDemand(_demandKey);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isPlaying = ref.watch(playerControllerProvider.select((s) => s.isPlaying));
    final rtaAsync = ref.watch(rtaSpectrumProvider);

    return rtaAsync.when(
      data: (magnitudes) {
        final rawFft = isPlaying ? magnitudes : <double>[];
        return CustomPaint(
          painter: DesktopMiniRtaPainter(
            fft: rawFft,
            color: theme.colorScheme.primary,
            style: widget.style,
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }
}

class DesktopMiniRtaPainter extends CustomPainter {
  final List<double> fft;
  final Color color;
  final SpectrumStyle style;

  DesktopMiniRtaPainter({
    required this.fft,
    required this.color,
    required this.style,
  });

  @override
  void paint(Canvas canvas, Size size) {
    switch (style) {
      case SpectrumStyle.m3Expressive:
        _paintM3Expressive(canvas, size);
        break;
      case SpectrumStyle.bars:
        _paintBars(canvas, size);
        break;
      case SpectrumStyle.wave:
        _paintWave(canvas, size);
        break;
      case SpectrumStyle.dots:
        _paintDots(canvas, size);
        break;
      case SpectrumStyle.beam:
        _paintBeam(canvas, size);
        break;
      case SpectrumStyle.mirrorWave:
        _paintMirrorWave(canvas, size);
        break;
      case SpectrumStyle.vuMeter:
        _paintVuMeter(canvas, size);
        break;
      case SpectrumStyle.circular:
        _paintCircular(canvas, size);
        break;
    }
  }

  void _paintM3Expressive(Canvas canvas, Size size) {
    const numBars = 8;
    final barWidth = size.width / numBars;
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < numBars; i++) {
      double mag = 0.08;
      if (fft.isNotEmpty) {
        final idx = ((i + 1) * (fft.length ~/ (numBars + 2))).clamp(0, fft.length - 1);
        mag = (fft[idx] * 1.5).clamp(0.08, 1.0);
      }
      final barHeight = size.height * mag;
      final x = i * barWidth + 0.8;
      final y = size.height - barHeight;

      paint.color = color.withValues(alpha: 0.5 + mag * 0.45);
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, (barWidth - 1.4).clamp(1.0, 10.0), barHeight),
        const Radius.circular(1.5),
      );
      canvas.drawRRect(rrect, paint);
    }
  }

  void _paintBars(Canvas canvas, Size size) {
    const numBars = 8;
    final barWidth = size.width / numBars;
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < numBars; i++) {
      double mag = 0.08;
      if (fft.isNotEmpty) {
        final idx = ((i + 1) * (fft.length ~/ (numBars + 2))).clamp(0, fft.length - 1);
        mag = (fft[idx] * 1.4).clamp(0.08, 1.0);
      }
      final barHeight = size.height * mag;
      final x = i * barWidth + 0.8;
      final y = size.height - barHeight;

      paint.color = Color.lerp(color.withValues(alpha: 0.6), AppColors.mintTarget, mag)!;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, (barWidth - 1.2).clamp(1.0, 10.0), barHeight),
        const Radius.circular(1.0),
      );
      canvas.drawRRect(rrect, paint);
    }
  }

  void _paintWave(Canvas canvas, Size size) {
    final count = fft.isNotEmpty ? math.min(16, fft.length) : 8;
    final path = Path();
    final fillPath = Path();

    final step = size.width / (count - 1);
    final firstMag = fft.isNotEmpty ? fft[0].clamp(0.05, 1.0) : 0.08;
    path.moveTo(0, size.height - (firstMag * size.height));
    fillPath.moveTo(0, size.height);
    fillPath.lineTo(0, size.height - (firstMag * size.height));

    for (int i = 1; i < count; i++) {
      final x = i * step;
      final mag = fft.isNotEmpty ? fft[(i * (fft.length ~/ count)).clamp(0, fft.length - 1)].clamp(0.05, 1.0) : 0.08;
      final y = size.height - (mag * size.height);
      path.lineTo(x, y);
      fillPath.lineTo(x, y);
    }

    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    canvas.drawPath(path, strokePaint);
  }

  void _paintDots(Canvas canvas, Size size) {
    const count = 7;
    final step = size.width / count;
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      double mag = 0.1;
      if (fft.isNotEmpty) {
        final idx = (i * (fft.length ~/ count)).clamp(0, fft.length - 1);
        mag = (fft[idx] * 1.5).clamp(0.1, 1.0);
      }
      final x = (i + 0.5) * step;
      final y = size.height - (mag * size.height * 0.85);
      paint.color = Color.lerp(color.withValues(alpha: 0.6), const Color(0xFF00E5FF), mag)!;
      canvas.drawCircle(Offset(x, y), 1.6 + mag * 1.2, paint);
    }
  }

  void _paintBeam(Canvas canvas, Size size) {
    final midY = size.height * 0.5;
    final count = fft.isNotEmpty ? math.min(12, fft.length) : 8;
    final step = size.width / (count - 1);

    final topPath = Path()..moveTo(0, midY);
    final btmPath = Path()..moveTo(0, midY);

    for (int i = 0; i < count; i++) {
      final x = i * step;
      double mag = 0.08;
      if (fft.isNotEmpty) {
        final idx = (i * (fft.length ~/ count)).clamp(0, fft.length - 1);
        mag = (fft[idx] * 1.5).clamp(0.08, 1.0);
      }
      final halfAmp = mag * size.height * 0.45;
      topPath.lineTo(x, midY - halfAmp);
      btmPath.lineTo(x, midY + halfAmp);
    }

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(topPath, strokePaint);
    canvas.drawPath(btmPath, strokePaint);

    final centerLine = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: 0.8)
      ..strokeWidth = 0.8;
    canvas.drawLine(Offset(0, midY), Offset(size.width, midY), centerLine);
  }

  void _paintMirrorWave(Canvas canvas, Size size) {
    final midY = size.height * 0.5;
    final count = 8;
    final step = size.width / (count - 1);
    final topPath = Path()..moveTo(0, midY);
    final btmPath = Path()..moveTo(0, midY);

    for (int i = 0; i < count; i++) {
      final x = i * step;
      double mag = 0.08;
      if (fft.isNotEmpty) {
        final idx = (i * (fft.length ~/ count)).clamp(0, fft.length - 1);
        mag = (fft[idx] * 1.4).clamp(0.08, 1.0);
      }
      final amp = mag * midY * 0.9;
      topPath.lineTo(x, midY - amp);
      btmPath.lineTo(x, midY + amp);
    }

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawPath(topPath, strokePaint);
    canvas.drawPath(btmPath, strokePaint);
  }

  void _paintVuMeter(Canvas canvas, Size size) {
    final halfWidth = size.width / 2;
    double leftEnergy = 0.08;
    double rightEnergy = 0.08;

    if (fft.isNotEmpty) {
      final halfCount = fft.length ~/ 2;
      for (int i = 0; i < halfCount; i++) {
        leftEnergy += fft[i];
      }
      for (int i = halfCount; i < fft.length; i++) {
        rightEnergy += fft[i];
      }
      leftEnergy = (leftEnergy / halfCount * 2.5).clamp(0.08, 1.0);
      rightEnergy = (rightEnergy / (fft.length - halfCount) * 2.5).clamp(0.08, 1.0);
    }

    _paintMiniDial(canvas, Rect.fromLTWH(2, 2, halfWidth - 3, size.height - 4), leftEnergy);
    _paintMiniDial(canvas, Rect.fromLTWH(halfWidth + 1, 2, halfWidth - 3, size.height - 4), rightEnergy);
  }

  void _paintMiniDial(Canvas canvas, Rect bounds, double energy) {
    final rrect = RRect.fromRectAndRadius(bounds, const Radius.circular(3));
    final bgPaint = Paint()..color = const Color(0xFF14171E);
    canvas.drawRRect(rrect, bgPaint);

    final pivot = Offset(bounds.center.dx, bounds.bottom + 2);
    final radius = bounds.height * 1.1;

    final needleAngle = (math.pi * 1.5) + ((energy - 0.5) * (math.pi * 0.4));
    final needleEnd = Offset(
      pivot.dx + radius * math.cos(needleAngle),
      pivot.dy + radius * math.sin(needleAngle),
    );

    final needlePaint = Paint()
      ..color = energy > 0.85 ? const Color(0xFFFF453A) : color
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(pivot, needleEnd, needlePaint);
  }

  void _paintCircular(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.height * 0.3;
    const count = 10;

    for (int i = 0; i < count; i++) {
      final angle = (i / count) * 2 * math.pi;
      double mag = 0.08;
      if (fft.isNotEmpty) {
        final idx = (i * (fft.length ~/ count)).clamp(0, fft.length - 1);
        mag = (fft[idx] * 1.5).clamp(0.08, 1.0);
      }
      final barLen = 1.5 + (mag * size.height * 0.4);

      final start = Offset(
        center.dx + baseRadius * math.cos(angle),
        center.dy + baseRadius * math.sin(angle),
      );
      final end = Offset(
        center.dx + (baseRadius + barLen) * math.cos(angle),
        center.dy + (baseRadius + barLen) * math.sin(angle),
      );

      final paint = Paint()
        ..color = Color.lerp(color.withValues(alpha: 0.6), const Color(0xFF00E5FF), mag)!
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant DesktopMiniRtaPainter oldDelegate) => true;
}
