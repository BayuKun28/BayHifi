import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../audio_engine/fft_processor.dart';

/// Widget visualizer spektrum FFT (RTA bars) real-time 60fps dengan Material 3 Expressive glow.
class SpectrumVisualizer extends ConsumerWidget {
  final double height;
  final Color barColor;
  final bool showPeakHold;

  const SpectrumVisualizer({
    super.key,
    this.height = 80,
    this.barColor = AppColors.rtaBar,
    this.showPeakHold = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rtaAsync = ref.watch(rtaSpectrumProvider);

    return RepaintBoundary(
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: rtaAsync.when(
          data: (magnitudes) => CustomPaint(
            painter: _RtaPainter(
              magnitudes: magnitudes,
              barColor: barColor,
              showPeakHold: showPeakHold,
            ),
          ),
          loading: () => const SizedBox.shrink(),
          error: (err, stack) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _RtaPainter extends CustomPainter {
  final List<double> magnitudes;
  final Color barColor;
  final bool showPeakHold;

  // Cached paint objects to guarantee 0 allocations in paint()
  final Paint _barPaint = Paint()..isAntiAlias = true;
  final Paint _peakPaint = Paint()
    ..isAntiAlias = true
    ..strokeWidth = 2.0;

  _RtaPainter({
    required this.magnitudes,
    required this.barColor,
    required this.showPeakHold,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (magnitudes.isEmpty) return;

    final int count = magnitudes.length;
    final double spacing = 2.0;
    final double totalSpacing = (count - 1) * spacing;
    final double barWidth = (size.width - totalSpacing) / count;

    if (barWidth <= 0) return;

    for (int i = 0; i < count; i++) {
      final double mag = magnitudes[i].clamp(0.0, 1.0);
      final double barHeight = mag * size.height;
      final double x = i * (barWidth + spacing);
      final double y = size.height - barHeight;

      // Gradient color from Cyan to Mint/Amber as magnitude increases
      final color = Color.lerp(
        barColor.withValues(alpha: 0.6),
        AppColors.mintTarget,
        mag,
      )!;

      _barPaint.color = color;

      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        const Radius.circular(2),
      );

      canvas.drawRRect(rect, _barPaint);

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

  @override
  bool shouldRepaint(covariant _RtaPainter oldDelegate) {
    return oldDelegate.magnitudes != magnitudes;
  }
}
