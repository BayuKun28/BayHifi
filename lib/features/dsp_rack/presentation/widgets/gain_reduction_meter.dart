import 'package:flutter/material.dart';

/// Studio Compressor Gain Reduction (GR) Meter
class GainReductionMeter extends StatelessWidget {
  const GainReductionMeter({
    super.key,
    required this.gainReductionDb, // e.g. 0.0 down to -20.0 dB
    required this.isActive,
    this.height = 20,
  });

  final double gainReductionDb;
  final bool isActive;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Map 0 dB (no reduction) to -20 dB (max reduction)
    final clampedGr = gainReductionDb.clamp(-20.0, 0.0).abs();
    final normalized = clampedGr / 20.0; // 0.0 to 1.0

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: const [
            Text(
              'GR (dB)',
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
            ),
            Text(
              '-20  -15  -10   -6   -3   0',
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 8.5,
                color: Colors.white54,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Container(
          height: height,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0A0C10) : const Color(0xFFDCE1EA),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.black12,
              width: 0.8,
            ),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final grWidth = constraints.maxWidth * normalized;
              return Stack(
                children: [
                  // Active GR fill coming from right to left
                  if (isActive && grWidth > 0)
                    Positioned(
                      right: 0,
                      top: 0,
                      bottom: 0,
                      width: grWidth,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.orangeAccent.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  // Subtle vertical tick dividers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(5, (index) {
                      return Container(
                        width: 1,
                        color: isDark ? Colors.white12 : Colors.black12,
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
