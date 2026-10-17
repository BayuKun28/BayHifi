import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/models/dac_band_config.dart';

/// Renders a real-time logarithmic frequency response curve (20 Hz - 20,000 Hz)
/// representing the combined response of the 5 hardware PEQ biquad filters.
class HardwareCurveVisualizer extends StatelessWidget {
  const HardwareCurveVisualizer({
    super.key,
    required this.bands,
    required this.isEqEnabled,
    this.preampDb = 0.0,
    this.selectedBandIndex,
    this.onBandSelected,
    this.onBandDragged,
    this.height = 200,
  });

  final List<DacBandConfig> bands;
  final bool isEqEnabled;
  final double preampDb;
  final int? selectedBandIndex;
  final ValueChanged<int>? onBandSelected;
  final void Function(int index, double frequency, double gainDb)? onBandDragged;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final isDark = theme.brightness == Brightness.dark;

    return Container(
      height: height,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16181F) : colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF262936) : colorScheme.outlineVariant,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
            // CustomPainter for grid, zones, and composite curve
            CustomPaint(
              size: Size.infinite,
              painter: _HardwareCurvePainter(
                bands: bands,
                isEqEnabled: isEqEnabled,
                preampDb: preampDb,
                colorScheme: colorScheme,
                selectedBandIndex: selectedBandIndex,
              ),
            ),

            // Gesture detector for dragging band nodes
            if (onBandDragged != null)
              Positioned.fill(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return GestureDetector(
                      onPanDown: (details) {
                        final touchedBand = _findClosestBand(
                          details.localPosition,
                          constraints.biggest,
                        );
                        if (touchedBand != null) {
                          onBandSelected?.call(touchedBand);
                        }
                      },
                      onPanUpdate: (details) {
                        final activeIndex = selectedBandIndex ??
                            _findClosestBand(
                              details.localPosition,
                              constraints.biggest,
                            );
                        if (activeIndex != null) {
                          final newFreq = _xToFrequency(
                            details.localPosition.dx,
                            constraints.maxWidth,
                          );
                          final newGain = _yToGain(
                            details.localPosition.dy,
                            constraints.maxHeight,
                          );
                          onBandDragged?.call(activeIndex, newFreq, newGain);
                        }
                      },
                    );
                  },
                ),
              ),

            // Preamp readout pill
            if (preampDb != 0.0)
              Positioned(
                top: 8,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: colorScheme.outlineVariant),
                  ),
                  child: Text(
                    'Preamp: ${preampDb.toStringAsFixed(1)} dB',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      );
  }

  int? _findClosestBand(Offset touchPos, Size size) {
    const double touchRadius = 24.0;
    int? closestIndex;
    double minDistance = double.infinity;

    for (int i = 0; i < bands.length; i++) {
      final band = bands[i];
      final nodeX = _frequencyToX(band.frequency, size.width);
      final nodeY = _gainToY(isEqEnabled && !band.isBypassed ? band.gainDb : 0.0, size.height);
      final dist = (touchPos - Offset(nodeX, nodeY)).distance;

      if (dist < touchRadius && dist < minDistance) {
        minDistance = dist;
        closestIndex = i;
      }
    }
    return closestIndex;
  }

  static double _frequencyToX(double freq, double width) {
    const minLog = 1.30103; // log10(20)
    const maxLog = 4.30103; // log10(20000)
    final logFreq = math.log(freq.clamp(20.0, 20000.0)) / math.ln10;
    return ((logFreq - minLog) / (maxLog - minLog)) * width;
  }

  static double _xToFrequency(double x, double width) {
    const minLog = 1.30103;
    const maxLog = 4.30103;
    final normalizedX = (x / width).clamp(0.0, 1.0);
    final logFreq = minLog + normalizedX * (maxLog - minLog);
    return math.pow(10, logFreq).toDouble().clamp(20.0, 20000.0);
  }

  static double _gainToY(double gainDb, double height) {
    const maxGain = 12.0;
    const minGain = -12.0;
    final normalizedY = (gainDb.clamp(minGain, maxGain) - maxGain) / (minGain - maxGain);
    return normalizedY * height;
  }

  static double _yToGain(double y, double height) {
    const maxGain = 12.0;
    const minGain = -12.0;
    final normalized = (y / height).clamp(0.0, 1.0);
    return maxGain - normalized * (maxGain - minGain);
  }
}

class _HardwareCurvePainter extends CustomPainter {
  const _HardwareCurvePainter({
    required this.bands,
    required this.isEqEnabled,
    required this.preampDb,
    required this.colorScheme,
    this.selectedBandIndex,
  });

  final List<DacBandConfig> bands;
  final bool isEqEnabled;
  final double preampDb;
  final ColorScheme colorScheme;
  final int? selectedBandIndex;

  @override
  void paint(Canvas canvas, Size size) {
    _drawGrid(canvas, size);
    _drawCurve(canvas, size);
    _drawBandNodes(canvas, size);
  }

  void _drawGrid(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.3)
      ..strokeWidth = 1.0;

    final zeroDbPaint = Paint()
      ..color = colorScheme.outline.withValues(alpha: 0.6)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Zero dB baseline (center)
    final zeroY = size.height / 2;
    canvas.drawLine(Offset(0, zeroY), Offset(size.width, zeroY), zeroDbPaint);

    // +6dB and -6dB horizontal lines
    final plus6Y = HardwareCurveVisualizer._gainToY(6.0, size.height);
    final minus6Y = HardwareCurveVisualizer._gainToY(-6.0, size.height);
    canvas.drawLine(Offset(0, plus6Y), Offset(size.width, plus6Y), gridPaint);
    canvas.drawLine(Offset(0, minus6Y), Offset(size.width, minus6Y), gridPaint);

    // Standard frequency vertical grid lines
    final gridFreqs = [50.0, 100.0, 250.0, 500.0, 1000.0, 2000.0, 5000.0, 10000.0];
    for (final f in gridFreqs) {
      final x = HardwareCurveVisualizer._frequencyToX(f, size.width);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
  }

  void _drawCurve(Canvas canvas, Size size) {
    if (bands.isEmpty) return;

    final path = Path();
    final fillPath = Path();

    final curvePaint = Paint()
      ..color = isEqEnabled ? colorScheme.primary : colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = isEqEnabled
          ? colorScheme.primary.withValues(alpha: 0.12)
          : Colors.transparent
      ..style = PaintingStyle.fill;

    const int pointsCount = 120;
    const minLog = 1.30103;
    const maxLog = 4.30103;

    final zeroY = size.height / 2;
    fillPath.moveTo(0, zeroY);

    for (int i = 0; i <= pointsCount; i++) {
      final t = i / pointsCount;
      final logFreq = minLog + t * (maxLog - minLog);
      final freq = math.pow(10, logFreq).toDouble();

      double totalGain = 0.0;
      if (isEqEnabled) {
        for (final band in bands) {
          if (!band.isBypassed) {
            totalGain += _evaluateBiquadGain(band, freq);
          }
        }
      }

      final x = t * size.width;
      final y = HardwareCurveVisualizer._gainToY(totalGain, size.height);

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(size.width, zeroY);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, curvePaint);
  }

  void _drawBandNodes(Canvas canvas, Size size) {
    for (int i = 0; i < bands.length; i++) {
      final band = bands[i];
      final isSelected = selectedBandIndex == i;
      final effectiveGain = isEqEnabled && !band.isBypassed ? band.gainDb : 0.0;

      final nodeX = HardwareCurveVisualizer._frequencyToX(band.frequency, size.width);
      final nodeY = HardwareCurveVisualizer._gainToY(effectiveGain, size.height);

      // Node background circle
      final nodeColor = isSelected ? colorScheme.primary : colorScheme.secondary;
      final bgPaint = Paint()
        ..color = colorScheme.surface
        ..style = PaintingStyle.fill;

      final borderPaint = Paint()
        ..color = nodeColor
        ..strokeWidth = isSelected ? 2.5 : 1.8
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(Offset(nodeX, nodeY), 10, bgPaint);
      canvas.drawCircle(Offset(nodeX, nodeY), 10, borderPaint);

      // Node text (1, 2, 3, 4, 5)
      final textPainter = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: TextStyle(
            color: nodeColor,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      textPainter.paint(
        canvas,
        Offset(nodeX - textPainter.width / 2, nodeY - textPainter.height / 2),
      );
    }
  }

  double _evaluateBiquadGain(DacBandConfig band, double targetFreq) {
    final f0 = band.frequency;
    final gain = band.gainDb;
    final q = band.qFactor;

    if (gain.abs() < 0.01) return 0.0;

    // Logarithmic distance
    final logRatio = (math.log(targetFreq / f0) / math.ln2).abs();
    final bandwidth = 1.0 / q;

    if (band.filterType == DacFilterType.lowShelf) {
      if (targetFreq <= f0) {
        return gain;
      }
      final falloff = math.exp(-math.pow(logRatio / bandwidth, 2));
      return gain * falloff;
    } else if (band.filterType == DacFilterType.highShelf) {
      if (targetFreq >= f0) {
        return gain;
      }
      final falloff = math.exp(-math.pow(logRatio / bandwidth, 2));
      return gain * falloff;
    } else {
      // Peaking bell curve
      final response = gain * math.exp(-math.pow(logRatio * q * 1.5, 2));
      return response;
    }
  }

  @override
  bool shouldRepaint(covariant _HardwareCurvePainter oldDelegate) {
    return oldDelegate.bands != bands ||
        oldDelegate.isEqEnabled != isEqEnabled ||
        oldDelegate.preampDb != preampDb ||
        oldDelegate.selectedBandIndex != selectedBandIndex ||
        oldDelegate.colorScheme != colorScheme;
  }
}
