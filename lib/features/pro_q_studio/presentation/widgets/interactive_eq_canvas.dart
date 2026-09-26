import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../audio_engine/fft_processor.dart';
import '../../domain/eq_band.dart';
import '../controllers/eq_controller.dart';
import 'eq_curve_painter.dart';

class InteractiveEqCanvas extends ConsumerStatefulWidget {
  const InteractiveEqCanvas({super.key});

  @override
  ConsumerState<InteractiveEqCanvas> createState() => _InteractiveEqCanvasState();
}

class _InteractiveEqCanvasState extends ConsumerState<InteractiveEqCanvas> {
  int? _draggedBandIndex;
  Offset? _dragPosition;
  double _baseQ = 1.41;

  static const double _topMargin = 32.0;
  static const double _bottomMargin = 28.0;
  static const double _hitRadius = 36.0;

  @override
  Widget build(BuildContext context) {
    final eqState = ref.watch(eqControllerProvider);
    final rtaSpectrum = ref.watch(rtaSpectrumProvider).value;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;

        final selectedBand = eqState.selectedBand;

        return Stack(
          children: [
            // 1. Core CustomPainter Canvas wrapped in RepaintBoundary
            Positioned.fill(
              child: RepaintBoundary(
                child: CustomPaint(
                  size: Size(w, h),
                  painter: EqCurvePainter(
                    bands: eqState.bands,
                    selectedBandIndex: eqState.selectedBandIndex,
                    isEnabled: eqState.isEnabled,
                    showFrCurves: eqState.showFrCurves,
                    isRtaEnabled: eqState.isRtaEnabled,
                    rtaSpectrum: rtaSpectrum,
                    driverFr: eqState.driverFr,
                    targetFr: eqState.targetFr,
                    isRawBypassed: eqState.isRawBypassed,
                  ),
                ),
              ),
            ),

            // 2. Gesture Detector Layer
            Positioned.fill(
              child: Listener(
                onPointerSignal: (pointerSignal) {
                  if (pointerSignal is PointerScrollEvent && eqState.selectedBandIndex != null) {
                    // Scroll wheel adjusting Q factor
                    final delta = pointerSignal.scrollDelta.dy;
                    final currentBand = eqState.selectedBand;
                    if (currentBand != null) {
                      final newQ = (currentBand.q - (delta > 0 ? 0.15 : -0.15)).clamp(0.1, 18.0);
                      ref.read(eqControllerProvider.notifier).updateBandQ(currentBand.index, newQ);
                    }
                  }
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onScaleStart: (details) {
                    final pos = details.localFocalPoint;
                    final hitIndex = _hitTestBand(pos, eqState.bands, w, h);
                    if (hitIndex != null) {
                      _draggedBandIndex = hitIndex;
                      _dragPosition = pos;
                      final b = eqState.bands.firstWhere((b) => b.index == hitIndex);
                      _baseQ = b.q;
                      ref.read(eqControllerProvider.notifier).selectBand(hitIndex);
                      setState(() {});
                    }
                  },
                  onScaleUpdate: (details) {
                    if (_draggedBandIndex == null) return;
                    final index = _draggedBandIndex!;
                    final notifier = ref.read(eqControllerProvider.notifier);

                    // If pinch gesture (scale != 1.0)
                    if (details.scale != 1.0) {
                      final newQ = (_baseQ * details.scale).clamp(0.1, 18.0);
                      notifier.updateBandQ(index, newQ);
                    }

                    // Position drag
                    final pos = details.localFocalPoint;
                    _dragPosition = pos;

                    final newFreq = EqCurvePainter.xToFreq(pos.dx, w);
                    double newGain = EqCurvePainter.yToGain(
                      pos.dy,
                      h,
                      topMargin: _topMargin,
                      bottomMargin: _bottomMargin,
                    );

                    // Snap to zero dB if within +/- 0.4 dB
                    if (newGain.abs() < 0.4) {
                      newGain = 0.0;
                    }

                    notifier.updateBandFreq(index, newFreq);
                    notifier.updateBandGain(index, newGain);
                    setState(() {});
                  },
                  onScaleEnd: (details) {
                    _draggedBandIndex = null;
                    _dragPosition = null;
                    setState(() {});
                  },
                  onTapDown: (details) {
                    final pos = details.localPosition;
                    final hitIndex = _hitTestBand(pos, eqState.bands, w, h);
                    ref.read(eqControllerProvider.notifier).selectBand(hitIndex);
                  },
                  onDoubleTapDown: (details) {
                    final pos = details.localPosition;
                    final hitIndex = _hitTestBand(pos, eqState.bands, w, h);
                    if (hitIndex != null) {
                      // Double tap on node: reset to 0 dB
                      ref.read(eqControllerProvider.notifier).updateBandGain(hitIndex, 0.0);
                    } else {
                      // Double tap on empty space: Add band at this position
                      final freq = EqCurvePainter.xToFreq(pos.dx, w);
                      final gain = EqCurvePainter.yToGain(
                        pos.dy,
                        h,
                        topMargin: _topMargin,
                        bottomMargin: _bottomMargin,
                      );
                      ref.read(eqControllerProvider.notifier).addBand(freq: freq, gain: gain);
                    }
                  },
                ),
              ),
            ),

            // Overlay indicator if A: RAW BYPASSED is active
            if (eqState.isRawBypassed)
              Positioned(
                top: 42,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xE61A222D),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF0288D1), width: 1.0),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedSlidersVertical,
                          size: 12,
                          color: Color(0xFF29B6F6),
                        ),
                        SizedBox(width: 6),
                        Text(
                          'A: RAW AUDIOPHILE DIRECT (EQ BYPASSED)',
                          style: TextStyle(
                            color: Color(0xFF29B6F6),
                            fontSize: 10.0,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // 3. Floating HUD Tooltip when dragging
            if (_draggedBandIndex != null && selectedBand != null && _dragPosition != null)
              _buildFloatingHud(selectedBand, _dragPosition!, w, h),
          ],
        );
      },
    );
  }

  int? _hitTestBand(Offset touchPos, List<EqBand> bands, double w, double h) {
    int? closestIndex;
    double minDistance = _hitRadius;

    for (final band in bands) {
      final bx = EqCurvePainter.freqToX(band.frequency, w);
      final by = EqCurvePainter.gainToY(
        band.gainDb,
        h,
        topMargin: _topMargin,
        bottomMargin: _bottomMargin,
      );

      final distance = (touchPos - Offset(bx, by)).distance;
      if (distance < minDistance) {
        minDistance = distance;
        closestIndex = band.index;
      }
    }

    return closestIndex;
  }

  Widget _buildFloatingHud(EqBand band, Offset pos, double w, double h) {
    // Offset HUD slightly above the node
    final hudX = pos.dx.clamp(90.0, w - 90.0);
    final hudY = (pos.dy - 44.0).clamp(38.0, h - 60.0);

    return Positioned(
      left: hudX - 85,
      top: hudY,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: const Color(0xE6141820),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: band.color.withValues(alpha: 0.8), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: band.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              'B${band.index}',
              style: TextStyle(
                color: band.color,
                fontWeight: FontWeight.bold,
                fontSize: 11,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${band.formattedFreq}Hz',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 11,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${band.formattedGain}dB',
              style: TextStyle(
                color: band.gainDb > 0 ? const Color(0xFFFF9F0A) : const Color(0xFF64D2FF),
                fontWeight: FontWeight.w600,
                fontSize: 11,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Q ${band.q.toStringAsFixed(2)}',
              style: const TextStyle(
                color: Color(0xFFB0BEC5),
                fontSize: 10,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
