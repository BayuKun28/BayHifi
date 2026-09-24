import 'package:flutter/material.dart';

/// Visual Tube Glow Filament — merepresentasikan tabung vakum triode analog
class TubeGlowIndicator extends StatelessWidget {
  const TubeGlowIndicator({
    super.key,
    required this.drive,
    required this.warmth,
    required this.isActive,
    this.height = 42,
  });

  final double drive; // 0.0 - 10.0
  final double warmth; // 0.0 - 1.0
  final bool isActive;
  final double height;

  @override
  Widget build(BuildContext context) {
    final intensity = isActive ? ((drive / 10.0) * 0.6 + warmth * 0.4).clamp(0.1, 1.0) : 0.05;
    final glowColor = Color.lerp(
      const Color(0xFFFF9F0A),
      const Color(0xFFFF5722),
      (drive / 10.0).clamp(0.0, 1.0),
    )!;

    return Container(
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isActive ? glowColor.withValues(alpha: 0.4) : Colors.white10,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: List.generate(4, (index) {
          return _buildTubeFilament(index, intensity, glowColor);
        }),
      ),
    );
  }

  Widget _buildTubeFilament(int index, double intensity, Color glowColor) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Tube Glass Bulb Shape
        Container(
          width: 16,
          height: 24,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(8),
              bottom: Radius.circular(3),
            ),
            border: Border.all(
              color: isActive ? glowColor.withValues(alpha: 0.3) : Colors.white12,
              width: 0.8,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: glowColor.withValues(alpha: intensity * 0.6),
                      blurRadius: 10 + (intensity * 8),
                      spreadRadius: 1,
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Container(
              width: 2.5,
              height: 14,
              decoration: BoxDecoration(
                color: isActive ? glowColor : Colors.white24,
                borderRadius: BorderRadius.circular(2),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: Colors.white.withValues(alpha: 0.9),
                          blurRadius: 4,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
