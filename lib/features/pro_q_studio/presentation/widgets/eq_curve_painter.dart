import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../domain/biquad_math.dart';
import '../../domain/eq_band.dart';
import '../../domain/fr_curve_data.dart';

/// CustomPainter untuk Pro-Q Studio EQ Canvas
class EqCurvePainter extends CustomPainter {
  final List<EqBand> bands;
  final int? selectedBandIndex;
  final bool isEnabled;
  final bool showFrCurves;
  final bool isRtaEnabled;
  final List<double>? rtaSpectrum;
  final FrCurveData? driverFr;
  final FrCurveData? targetFr;
  final bool isRawBypassed;

  // Pre-calculated sampling points (256 log-spaced points)
  static final List<double> _sampleFrequencies = List.generate(256, (i) {
    return 20.0 * math.pow(1000.0, i / 255.0);
  });

  // Pre-instantiated Paint objects (Zero allocations in paint)
  final Paint _bgPaint = Paint()..color = const Color(0xFF0D0F14);

  final Paint _gridMajorPaint = Paint()
    ..color = const Color(0xFF1F242D)
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;

  final Paint _gridMinorPaint = Paint()
    ..color = const Color(0xFF14181F)
    ..strokeWidth = 0.5
    ..style = PaintingStyle.stroke;

  final Paint _zeroLinePaint = Paint()
    ..color = const Color(0xFF37474F)
    ..strokeWidth = 1.2
    ..style = PaintingStyle.stroke;

  final Paint _zoneDividerPaint = Paint()
    ..color = const Color(0x332A323D)
    ..strokeWidth = 1.0
    ..style = PaintingStyle.stroke;

  final Paint _zoneFillPaint = Paint()..style = PaintingStyle.fill;

  final Paint _bottomAccentPaint = Paint()
    ..color = const Color(0xFFAB47BC)
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke;

  final Paint _eqGlowPaint = Paint()
    ..color = const Color(0x66FFB74D)
    ..strokeWidth = 5.0
    ..style = PaintingStyle.stroke
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

  final Paint _eqCurvePaint = Paint()
    ..color = const Color(0xFFFFA726)
    ..strokeWidth = 2.2
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  final Paint _eqFillPaint = Paint()..style = PaintingStyle.fill;

  final Paint _driverFrPaint = Paint()
    ..color = const Color(0xFF29B6F6)
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke;

  final Paint _targetFrPaint = Paint()
    ..color = const Color(0xFF00E676)
    ..strokeWidth = 1.5
    ..style = PaintingStyle.stroke;

  final Paint _rtaBarPaint = Paint()..style = PaintingStyle.fill;

  final Paint _nodeBodyPaint = Paint()
    ..color = const Color(0xFF101318)
    ..style = PaintingStyle.fill;

  final Paint _nodeRingPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2.2;

  final Paint _nodeGlowPaint = Paint()
    ..style = PaintingStyle.stroke
    ..strokeWidth = 5.0
    ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);

  // Pre-instantiated Path objects
  final Path _eqPath = Path();
  final Path _fillPath = Path();
  final Path _driverPath = Path();
  final Path _targetPath = Path();

  // Pre-instantiated TextPainter
  final TextPainter _textPainter = TextPainter(
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  );

  EqCurvePainter({
    required this.bands,
    required this.selectedBandIndex,
    required this.isEnabled,
    required this.showFrCurves,
    required this.isRtaEnabled,
    required this.rtaSpectrum,
    required this.driverFr,
    required this.targetFr,
    this.isRawBypassed = false,
  });

  // Koordinat konversi logaritmik
  static double freqToX(double f, double width) {
    const minLog = 1.3010299956639813; // log10(20)
    const maxLog = 4.301029995663981; // log10(20000)
    const logSpan = maxLog - minLog; // 3.0
    final logF = math.log(f.clamp(20.0, 20000.0)) / math.ln10;
    return ((logF - minLog) / logSpan) * width;
  }

  static double xToFreq(double x, double width) {
    final t = (x / width).clamp(0.0, 1.0);
    return 20.0 * math.pow(1000.0, t);
  }

  static double gainToY(
    double gainDb,
    double height, {
    double topMargin = 32.0,
    double bottomMargin = 28.0,
    double minDb = -24.0,
    double maxDb = 24.0,
  }) {
    final availableHeight = height - topMargin - bottomMargin;
    final clamped = gainDb.clamp(minDb, maxDb);
    final t = (maxDb - clamped) / (maxDb - minDb);
    return topMargin + t * availableHeight;
  }

  static double yToGain(
    double y,
    double height, {
    double topMargin = 32.0,
    double bottomMargin = 28.0,
    double minDb = -24.0,
    double maxDb = 24.0,
  }) {
    final availableHeight = height - topMargin - bottomMargin;
    final t = ((y - topMargin) / availableHeight).clamp(0.0, 1.0);
    return maxDb - t * (maxDb - minDb);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    if (w <= 0 || h <= 0) return;

    const topMargin = 32.0;
    const bottomMargin = 28.0;
    final zeroY = gainToY(0.0, h, topMargin: topMargin, bottomMargin: bottomMargin);

    // 1. Background
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), _bgPaint);

    // 2. Frequency Zones (7 Zona)
    _drawFrequencyZones(canvas, w, h, topMargin, bottomMargin);

    // 3. Grid Lines (Horizontal & Vertical)
    _drawGridLines(canvas, w, h, topMargin, bottomMargin, zeroY);

    // 4. Background RTA Spectrum Analyzer (jika diaktifkan)
    if (isRtaEnabled && rtaSpectrum != null && rtaSpectrum!.isNotEmpty) {
      _drawRtaSpectrum(canvas, w, h, topMargin, bottomMargin);
    }

    // 5. Driver FR & Target FR curves (Cyan & Mint dashed curves)
    if (showFrCurves) {
      _drawFrCurves(canvas, w, h, topMargin, bottomMargin);
    }

    // 6. Glowing Amber Composite EQ Curve & Translucent Fill
    _drawCompositeEqCurve(canvas, w, h, topMargin, bottomMargin, zeroY);

    // 7. Interactive Node Handles
    _drawNodeHandles(canvas, w, h, topMargin, bottomMargin);

    // 8. Dual Y-Axis & X-Axis Labels
    _drawAxisLabels(canvas, w, h, topMargin, bottomMargin, zeroY);
  }

  /// 7 Zona Frekuensi Standar Studio dengan background tint dan header pill
  void _drawFrequencyZones(
    Canvas canvas,
    double w,
    double h,
    double topMargin,
    double bottomMargin,
  ) {
    final zones = const [
      (20.0, 60.0, 'SUB BASS', 'SUB', Color(0xFFFF5252)),
      (60.0, 250.0, 'MID BASS', 'BASS', Color(0xFFFFB74D)),
      (250.0, 500.0, 'LOWER MIDRANGE', 'LO MID', Color(0xFF69F0AE)),
      (500.0, 2000.0, 'UPPER MIDRANGE', 'HI MID', Color(0xFF40C4FF)),
      (2000.0, 4000.0, 'PRESENCE REGION', 'PRES', Color(0xFF7C4DFF)),
      (4000.0, 10000.0, 'MID TREBLE', 'TREBLE', Color(0xFFFF4081)),
      (10000.0, 20000.0, 'AIR', 'AIR', Color(0xFF00E5FF)),
    ];

    for (final zone in zones) {
      final xStart = freqToX(zone.$1, w);
      final xEnd = freqToX(zone.$2, w);
      final zoneWidth = xEnd - xStart;

      // Subtle column tint
      _zoneFillPaint.color = zone.$5.withValues(alpha: 0.035);
      canvas.drawRect(
        Rect.fromLTWH(xStart, topMargin, zoneWidth, h - topMargin - bottomMargin),
        _zoneFillPaint,
      );

      // Vertical separator
      canvas.drawLine(
        Offset(xStart, 0),
        Offset(xStart, h - bottomMargin),
        _zoneDividerPaint,
      );

      // Top Header Zone Capsule Pill
      final pillWidth = math.max(16.0, zoneWidth - 4.0).clamp(20.0, 110.0);
      final pillRect = RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(xStart + zoneWidth / 2, 16),
          width: pillWidth,
          height: 18,
        ),
        const Radius.circular(9),
      );

      _zoneFillPaint.color = zone.$5.withValues(alpha: 0.12);
      canvas.drawRRect(pillRect, _zoneFillPaint);

      final pillBorderPaint = Paint()
        ..color = zone.$5.withValues(alpha: 0.4)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;
      canvas.drawRRect(pillRect, pillBorderPaint);

      // Choose full or short name depending on available width
      final labelText = pillWidth < 68.0 ? zone.$4 : zone.$3;
      final fontSize = pillWidth < 40.0 ? 6.5 : (pillWidth < 60.0 ? 7.5 : 8.5);

      // Zone Label Text
      _textPainter.text = TextSpan(
        text: labelText,
        style: TextStyle(
          color: zone.$5,
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      );
      _textPainter.layout();
      _textPainter.paint(
        canvas,
        Offset(
          xStart + (zoneWidth - _textPainter.width) / 2,
          16 - _textPainter.height / 2,
        ),
      );
    }
  }

  /// Grid garis horizontal (+24 s/d -24 dB) dan vertikal (frekuensi)
  void _drawGridLines(
    Canvas canvas,
    double w,
    double h,
    double topMargin,
    double bottomMargin,
    double zeroY,
  ) {
    // Horizontal dB lines: +24, +18, +12, +6, 0, -6, -12, -18, -24
    const dbLevels = [24.0, 18.0, 12.0, 6.0, -6.0, -12.0, -18.0, -24.0];
    for (final db in dbLevels) {
      final y = gainToY(db, h, topMargin: topMargin, bottomMargin: bottomMargin);
      canvas.drawLine(
        Offset(0, y),
        Offset(w, y),
        _gridMinorPaint,
      );
    }

    // 0 dB Baseline (Bold)
    canvas.drawLine(
      Offset(0, zeroY),
      Offset(w, zeroY),
      _zeroLinePaint,
    );

    // Minor vertical frequency gridlines
    const minorFreqs = [
      30.0, 40.0, 50.0, 80.0, 100.0, 150.0, 200.0, 300.0, 400.0,
      700.0, 1000.0, 1500.0, 3000.0, 6000.0, 8000.0, 15000.0
    ];
    for (final f in minorFreqs) {
      final x = freqToX(f, w);
      canvas.drawLine(
        Offset(x, topMargin),
        Offset(x, h - bottomMargin),
        _gridMinorPaint,
      );
    }

    // Major vertical lines
    const majorFreqs = [20.0, 60.0, 250.0, 500.0, 2000.0, 4000.0, 10000.0, 20000.0];
    for (final f in majorFreqs) {
      final x = freqToX(f, w);
      canvas.drawLine(
        Offset(x, topMargin),
        Offset(x, h - bottomMargin),
        _gridMajorPaint,
      );
    }

    // Bottom horizontal accent line
    canvas.drawLine(
      Offset(0, h - bottomMargin),
      Offset(w, h - bottomMargin),
      _bottomAccentPaint,
    );
  }

  /// Real-time RTA Spectrum overlay
  void _drawRtaSpectrum(
    Canvas canvas,
    double w,
    double h,
    double topMargin,
    double bottomMargin,
  ) {
    final spec = rtaSpectrum!;
    final numBars = spec.length;
    if (numBars == 0) return;

    final availableHeight = h - topMargin - bottomMargin;
    final barWidth = w / numBars;

    for (int i = 0; i < numBars; i++) {
      final mag = spec[i].clamp(0.0, 1.0);
      if (mag <= 0.01) continue;

      final barHeight = mag * availableHeight * 0.75;
      final x = i * barWidth;
      final y = (h - bottomMargin) - barHeight;

      // Cyan to teal gradient bar with low opacity
      _rtaBarPaint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF00E5FF).withValues(alpha: 0.22),
          const Color(0xFF00B0FF).withValues(alpha: 0.04),
        ],
      ).createShader(Rect.fromLTWH(x, y, barWidth * 0.85, barHeight));

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x + barWidth * 0.08, y, barWidth * 0.84, barHeight),
          const Radius.circular(2.0),
        ),
        _rtaBarPaint,
      );
    }
  }

  /// Driver & Target FR curves (dashed lines)
  void _drawFrCurves(
    Canvas canvas,
    double w,
    double h,
    double topMargin,
    double bottomMargin,
  ) {
    if (driverFr != null && driverFr!.frequencies.isNotEmpty) {
      _driverPath.reset();
      bool first = true;
      for (int i = 0; i < _sampleFrequencies.length; i += 2) {
        final f = _sampleFrequencies[i];
        final splNorm = driverFr!.interpolateSpl(f);
        // Map normalized SPL to visual grid (scaling: 0dB norm -> visual baseline)
        final y = gainToY(splNorm, h, topMargin: topMargin, bottomMargin: bottomMargin);
        final x = freqToX(f, w);
        if (first) {
          _driverPath.moveTo(x, y);
          first = false;
        } else {
          _driverPath.lineTo(x, y);
        }
      }
      _drawDashedPath(canvas, _driverPath, _driverFrPaint, 6.0, 4.0);
    }

    if (targetFr != null && targetFr!.frequencies.isNotEmpty) {
      _targetPath.reset();
      bool first = true;
      for (int i = 0; i < _sampleFrequencies.length; i += 2) {
        final f = _sampleFrequencies[i];
        final splNorm = targetFr!.interpolateSpl(f);
        final y = gainToY(splNorm, h, topMargin: topMargin, bottomMargin: bottomMargin);
        final x = freqToX(f, w);
        if (first) {
          _targetPath.moveTo(x, y);
          first = false;
        } else {
          _targetPath.lineTo(x, y);
        }
      }
      _drawDashedPath(canvas, _targetPath, _targetFrPaint, 6.0, 4.0);
    }
  }

  /// Gambar kurva garis putus-putus efisien
  void _drawDashedPath(
    Canvas canvas,
    Path source,
    Paint paint,
    double dashWidth,
    double dashSpace,
  ) {
    for (final metric in source.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        final length = math.min(dashWidth, metric.length - distance);
        final extract = metric.extractPath(distance, distance + length);
        canvas.drawPath(extract, paint);
        distance += dashWidth + dashSpace;
      }
    }
  }

  /// Glowing Amber EQ Curve & Translucent Fill
  void _drawCompositeEqCurve(
    Canvas canvas,
    double w,
    double h,
    double topMargin,
    double bottomMargin,
    double zeroY,
  ) {
    final gains = (isEnabled && !isRawBypassed)
        ? BiquadMath.evaluateCompositeCurve(bands, _sampleFrequencies)
        : List.filled(_sampleFrequencies.length, 0.0);

    _eqPath.reset();
    _fillPath.reset();

    final firstX = freqToX(_sampleFrequencies.first, w);
    final firstY = gainToY(gains.first, h, topMargin: topMargin, bottomMargin: bottomMargin);

    _eqPath.moveTo(firstX, firstY);
    _fillPath.moveTo(firstX, zeroY);
    _fillPath.lineTo(firstX, firstY);

    for (int i = 1; i < _sampleFrequencies.length; i++) {
      final f = _sampleFrequencies[i];
      final x = freqToX(f, w);
      final y = gainToY(gains[i], h, topMargin: topMargin, bottomMargin: bottomMargin);

      _eqPath.lineTo(x, y);
      _fillPath.lineTo(x, y);
    }

    final lastX = freqToX(_sampleFrequencies.last, w);
    _fillPath.lineTo(lastX, zeroY);
    _fillPath.close();

    // 1. Shading Gradien Translusen Kurva EQ
    _eqFillPaint.shader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        const Color(0xFFFF9F0A).withValues(alpha: 0.25),
        const Color(0xFFFF9F0A).withValues(alpha: 0.03),
      ],
    ).createShader(Rect.fromLTWH(0, topMargin, w, h - topMargin - bottomMargin));

    canvas.drawPath(_fillPath, _eqFillPaint);

    // 2. Glow Layer
    canvas.drawPath(_eqPath, _eqGlowPaint);

    // 3. Crisp Amber Curve Line
    canvas.drawPath(_eqPath, _eqCurvePaint);
  }

  /// Interactive Draggable Node Handles
  void _drawNodeHandles(
    Canvas canvas,
    double w,
    double h,
    double topMargin,
    double bottomMargin,
  ) {
    for (final band in bands) {
      final x = freqToX(band.frequency, w);
      final y = (isEnabled && !isRawBypassed)
          ? gainToY(band.gainDb, h, topMargin: topMargin, bottomMargin: bottomMargin)
          : gainToY(0.0, h, topMargin: topMargin, bottomMargin: bottomMargin);

      final isSelected = band.index == selectedBandIndex;
      final nodeRadius = isSelected ? 12.0 : 9.5;

      // Outer Selection Halo
      if (isSelected) {
        _nodeGlowPaint.color = band.color.withValues(alpha: 0.45);
        canvas.drawCircle(Offset(x, y), nodeRadius + 5.0, _nodeGlowPaint);

        final selRingPaint = Paint()
          ..color = Colors.white.withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;
        canvas.drawCircle(Offset(x, y), nodeRadius + 3.0, selRingPaint);
      }

      // Dark Center
      canvas.drawCircle(Offset(x, y), nodeRadius, _nodeBodyPaint);

      // Colored Border Ring
      _nodeRingPaint.color = band.isEnabled ? band.color : band.color.withValues(alpha: 0.35);
      canvas.drawCircle(Offset(x, y), nodeRadius, _nodeRingPaint);

      // Node Index Number
      _textPainter.text = TextSpan(
        text: '${band.index}',
        style: TextStyle(
          color: Colors.white,
          fontSize: isSelected ? 10.0 : 8.5,
          fontWeight: FontWeight.bold,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      );
      _textPainter.layout();
      _textPainter.paint(
        canvas,
        Offset(x - _textPainter.width / 2, y - _textPainter.height / 2),
      );
    }
  }

  /// Dual Y-Axis & X-Axis Frequency Labels
  void _drawAxisLabels(
    Canvas canvas,
    double w,
    double h,
    double topMargin,
    double bottomMargin,
    double zeroY,
  ) {
    // 1. Right Y-Axis (EQ Gain in dB, Amber/Orange text)
    const rightLevels = [24.0, 18.0, 12.0, 6.0, 0.0, -6.0, -12.0, -18.0, -24.0];
    for (final db in rightLevels) {
      final y = gainToY(db, h, topMargin: topMargin, bottomMargin: bottomMargin);
      final text = db == 0.0 ? '0' : (db > 0 ? '${db.toInt()}' : '${db.toInt()}');
      _textPainter.text = TextSpan(
        text: text,
        style: const TextStyle(
          color: Color(0xFFFFB74D),
          fontSize: 9.0,
          fontWeight: FontWeight.w600,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      );
      _textPainter.layout();
      _textPainter.paint(canvas, Offset(w - _textPainter.width - 6.0, y - _textPainter.height / 2));
    }

    // 2. Left Y-Axis (Signal Level in dBFS, Cyan text)
    // 0 dBFS, -12, -24, -36, -48, -60
    const leftLevels = [
      (0.0, '0 dBFS'),
      (0.2, '-12'),
      (0.4, '-24'),
      (0.6, '-36'),
      (0.8, '-48'),
      (1.0, '-60'),
    ];
    final availableHeight = h - topMargin - bottomMargin;
    for (final lvl in leftLevels) {
      final y = topMargin + lvl.$1 * availableHeight;
      _textPainter.text = TextSpan(
        text: lvl.$2,
        style: const TextStyle(
          color: Color(0xFF00E5FF),
          fontSize: 8.5,
          fontWeight: FontWeight.w600,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      );
      _textPainter.layout();
      _textPainter.paint(canvas, Offset(6.0, y - _textPainter.height / 2));
    }

    // 3. Bottom X-Axis Frequency Labels (20, 60, 250, 500, 2k, 4k, 10k, 20k)
    final xLabels = [
      (20.0, '20'),
      (60.0, '60'),
      (250.0, '250'),
      (500.0, '500'),
      (2000.0, '2k'),
      (4000.0, '4k'),
      (10000.0, '10k'),
      (20000.0, '20k'),
    ];

    for (final lbl in xLabels) {
      final x = freqToX(lbl.$1, w);
      _textPainter.text = TextSpan(
        text: lbl.$2,
        style: const TextStyle(
          color: Color(0xFF9E9E9E),
          fontSize: 9.0,
          fontWeight: FontWeight.w600,
          fontFeatures: [FontFeature.tabularFigures()],
        ),
      );
      _textPainter.layout();
      _textPainter.paint(
        canvas,
        Offset(x - _textPainter.width / 2, h - bottomMargin + 8.0),
      );
    }
  }

  @override
  bool shouldRepaint(covariant EqCurvePainter oldDelegate) {
    return oldDelegate.bands != bands ||
        oldDelegate.selectedBandIndex != selectedBandIndex ||
        oldDelegate.isEnabled != isEnabled ||
        oldDelegate.showFrCurves != showFrCurves ||
        oldDelegate.isRtaEnabled != isRtaEnabled ||
        oldDelegate.rtaSpectrum != rtaSpectrum ||
        oldDelegate.driverFr != driverFr ||
        oldDelegate.targetFr != targetFr;
  }
}
