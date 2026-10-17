import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../domain/studio_wrapped_data.dart';

/// Template 1: Thermal Receipt (Receiptify Audiophile Edition)
/// Features realistic paper texture, saw-tooth paper tear edges, monospaced tabular figures, and dynamic studio barcode.
class ThermalReceiptView extends StatelessWidget {
  final StudioWrappedData data;
  final bool isDarkMode;

  const ThermalReceiptView({
    super.key,
    required this.data,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final paperColor = isDarkMode ? const Color(0xFF18181B) : const Color(0xFFFAFAFA);
    final inkColor = isDarkMode ? const Color(0xFFF4F4F5) : const Color(0xFF18181B);
    final mutedInk = isDarkMode ? const Color(0xFFA1A1AA) : const Color(0xFF71717A);
    final dividerColor = isDarkMode ? const Color(0xFF3F3F46) : const Color(0xFFD4D4D8);

    const monoStyle = TextStyle(
      fontFamily: 'monospace',
      fontFeatures: [FontFeature.tabularFigures()],
      letterSpacing: -0.2,
    );

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: Colors.transparent,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDarkMode ? 0.4 : 0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ─── TOP SAW-TOOTH TORN EDGE ────────────────────────────────
          CustomPaint(
            size: const Size(double.infinity, 12),
            painter: _SawtoothEdgePainter(
              color: paperColor,
              pointingUp: true,
            ),
          ),

          // ─── RECEIPT PAPER BODY ─────────────────────────────────────
          Container(
            color: paperColor,
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Header
                Center(
                  child: Column(
                    children: [
                      Text(
                        'BAYDEV HIFI STORE',
                        style: monoStyle.copyWith(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: inkColor,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'LOSSLESS AUDIO & DSP MASTERING STUDIO',
                        style: monoStyle.copyWith(
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          color: mutedInk,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        'WWW.BAYDEVHIFI.AUDIO',
                        style: monoStyle.copyWith(
                          fontSize: 8.0,
                          color: mutedInk,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                _buildDashedLine(dividerColor),
                const SizedBox(height: 8),

                // 2. Metadata Info
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ORDER #2026-RECAP',
                      style: monoStyle.copyWith(fontSize: 9.5, fontWeight: FontWeight.w700, color: inkColor),
                    ),
                    Text(
                      'DATE: 2026-10-07',
                      style: monoStyle.copyWith(fontSize: 9.5, fontWeight: FontWeight.w600, color: inkColor),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        'TERMINAL: BIT-PERFECT FLAC',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: monoStyle.copyWith(fontSize: 8.5, color: mutedInk),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'AUTH: MASTERED',
                      style: monoStyle.copyWith(fontSize: 8.5, color: mutedInk),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                _buildDashedLine(dividerColor),
                const SizedBox(height: 8),

                // 3. Table Column Headers
                Row(
                  children: [
                    SizedBox(
                      width: 28,
                      child: Text('QTY', style: monoStyle.copyWith(fontSize: 8.5, fontWeight: FontWeight.w800, color: mutedInk)),
                    ),
                    Expanded(
                      child: Text('ITEM / TRACK DESCRIPTION', style: monoStyle.copyWith(fontSize: 8.5, fontWeight: FontWeight.w800, color: mutedInk)),
                    ),
                    SizedBox(
                      width: 44,
                      child: Text('MINS', textAlign: TextAlign.right, style: monoStyle.copyWith(fontSize: 8.5, fontWeight: FontWeight.w800, color: mutedInk)),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 52,
                      child: Text('FORMAT', textAlign: TextAlign.right, style: monoStyle.copyWith(fontSize: 8.5, fontWeight: FontWeight.w800, color: mutedInk)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                _buildDashedLine(dividerColor),
                const SizedBox(height: 8),

                // 4. Itemized Top Tracks
                ...data.topTracks.take(5).map((track) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 7.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 28,
                          child: Text(
                            track.playCount.toString().padLeft(3, '0'),
                            style: monoStyle.copyWith(fontSize: 9.0, fontWeight: FontWeight.w700, color: inkColor),
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                track.title.toUpperCase(),
                                style: monoStyle.copyWith(fontSize: 9.5, fontWeight: FontWeight.w800, color: inkColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                track.artist.toUpperCase(),
                                style: monoStyle.copyWith(fontSize: 8.0, color: mutedInk),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(
                          width: 44,
                          child: Text(
                            '${track.totalMinutes}m',
                            textAlign: TextAlign.right,
                            style: monoStyle.copyWith(fontSize: 9.0, fontWeight: FontWeight.w700, color: inkColor),
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          width: 52,
                          child: Text(
                            track.format.toUpperCase(),
                            textAlign: TextAlign.right,
                            style: monoStyle.copyWith(fontSize: 8.0, fontWeight: FontWeight.w700, color: mutedInk),
                          ),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 6),
                _buildDashedLine(dividerColor),
                const SizedBox(height: 8),

                // 5. Totals & Audiophile Purity
                _buildReceiptSummaryRow('TOTAL TRACKS PLAYED:', '${data.totalTracksPlayed} TRKS', inkColor, monoStyle),
                const SizedBox(height: 4),
                _buildReceiptSummaryRow('TOTAL LISTENING TIME:', '${data.totalMinutes} MINS', inkColor, monoStyle, isBold: true),
                const SizedBox(height: 4),
                _buildReceiptSummaryRow('HI-RES PURITY RATE:', '${data.purityReport.flacPercentage.toStringAsFixed(1)}% FLAC', inkColor, monoStyle),
                const SizedBox(height: 4),
                _buildReceiptSummaryRow('FAVORITE DSP MODULE:', data.favoriteDspModule.toUpperCase(), inkColor, monoStyle),
                const SizedBox(height: 4),
                _buildReceiptSummaryRow('FAVORITE IEM TUNING:', data.favoriteAutoEqDriver.toUpperCase(), inkColor, monoStyle),

                const SizedBox(height: 10),
                _buildDashedLine(dividerColor),
                const SizedBox(height: 10),

                // 6. Persona Archetype Box
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: inkColor, width: 1.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'AUDIOPHILE PERSONA ARCHETYPE:',
                        style: monoStyle.copyWith(fontSize: 8.0, fontWeight: FontWeight.w700, color: mutedInk, letterSpacing: 1.0),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '>>> ${data.persona.title} <<<',
                        textAlign: TextAlign.center,
                        style: monoStyle.copyWith(fontSize: 10.0, fontWeight: FontWeight.w900, color: inkColor, letterSpacing: 0.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        data.persona.subtitle.toUpperCase(),
                        textAlign: TextAlign.center,
                        style: monoStyle.copyWith(fontSize: 7.5, color: mutedInk),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // 7. Dynamic Barcode
                Center(
                  child: CustomPaint(
                    size: const Size(260, 36),
                    painter: _BarcodePainter(color: inkColor),
                  ),
                ),
                const SizedBox(height: 4),
                Center(
                  child: Text(
                    '9 8 2 0 2 6  ${data.totalMinutes}  ${data.purityReport.flacPercentage.toInt()} 0 1',
                    style: monoStyle.copyWith(fontSize: 8.5, letterSpacing: 3.5, color: inkColor),
                  ),
                ),
                const SizedBox(height: 10),

                // 8. Receipt Footer
                Center(
                  child: Text(
                    'THANK YOU FOR LISTENING IN HI-RES!',
                    style: monoStyle.copyWith(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      color: inkColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── BOTTOM SAW-TOOTH TORN EDGE ─────────────────────────────
          CustomPaint(
            size: const Size(double.infinity, 12),
            painter: _SawtoothEdgePainter(
              color: paperColor,
              pointingUp: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashedLine(Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 4.0;
        const dashSpace = 3.0;
        final dashCount = (boxWidth / (dashWidth + dashSpace)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: 1.0,
              child: DecoratedBox(
                decoration: BoxDecoration(color: color),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildReceiptSummaryRow(String label, String value, Color color, TextStyle style, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: style.copyWith(
            fontSize: isBold ? 9.5 : 8.5,
            fontWeight: isBold ? FontWeight.w900 : FontWeight.w600,
            color: color,
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: style.copyWith(
              fontSize: isBold ? 10.0 : 8.5,
              fontWeight: isBold ? FontWeight.w900 : FontWeight.w700,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

/// Custom painter for jagged/sawtooth torn receipt edges
class _SawtoothEdgePainter extends CustomPainter {
  final Color color;
  final bool pointingUp;

  _SawtoothEdgePainter({required this.color, required this.pointingUp});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    const toothWidth = 8.0;
    final teethCount = (size.width / toothWidth).ceil();

    if (pointingUp) {
      path.moveTo(0, size.height);
      for (int i = 0; i < teethCount; i++) {
        final x = i * toothWidth;
        path.lineTo(x + toothWidth / 2, 0);
        path.lineTo(x + toothWidth, size.height);
      }
      path.lineTo(size.width, size.height);
      path.close();
    } else {
      path.moveTo(0, 0);
      for (int i = 0; i < teethCount; i++) {
        final x = i * toothWidth;
        path.lineTo(x + toothWidth / 2, size.height);
        path.lineTo(x + toothWidth, 0);
      }
      path.lineTo(size.width, 0);
      path.close();
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SawtoothEdgePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.pointingUp != pointingUp;
}

/// Custom painter for dynamic barcode rendering
class _BarcodePainter extends CustomPainter {
  final Color color;

  _BarcodePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    final random = math.Random(42);
    double x = 4.0;
    while (x < size.width - 4.0) {
      final width = random.nextDouble() > 0.6 ? 3.0 : 1.5;
      paint.strokeWidth = width;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      x += width + (random.nextDouble() * 3.0 + 1.5);
    }
  }

  @override
  bool shouldRepaint(covariant _BarcodePainter oldDelegate) => oldDelegate.color != color;
}
