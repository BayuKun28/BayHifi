import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Solid Matte Card for adjusting the hardware USB DAC's Master Preamp Gain
/// (-18.0 dB .. +3.0 dB) in real-time on register 0x3B.
class DacGlobalGainCard extends StatelessWidget {
  const DacGlobalGainCard({
    super.key,
    required this.globalGainDb,
    required this.isConnected,
    required this.onChanged,
  });

  final double globalGainDb;
  final bool isConnected;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final clampedGain = globalGainDb.clamp(-18.0, 3.0);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16181F) : theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF262936) : theme.colorScheme.outlineVariant,
          width: 0.8,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isConnected
                        ? (isDark ? const Color(0xFF222532) : theme.colorScheme.primaryContainer)
                        : (isDark ? const Color(0xFF1E212B) : theme.colorScheme.surfaceContainerHighest),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? const Color(0xFF262936) : theme.colorScheme.outlineVariant,
                      width: 0.8,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    LucideIcons.volume2,
                    color: isConnected
                        ? (isDark ? const Color(0xFF10B981) : theme.colorScheme.primary)
                        : (isDark ? const Color(0xFF8A9A90) : theme.colorScheme.onSurfaceVariant),
                    size: 16,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Master Pre-Amp Gain',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : theme.colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Hardware analog volume / digital headroom',
                        style: TextStyle(
                          color: isDark ? const Color(0xFF8A9A90) : theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                // Readout Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: clampedGain > 0
                        ? (isDark ? const Color(0xFF2A2416) : const Color(0xFFFEF3C7))
                        : (isDark ? const Color(0xFF1E212B) : theme.colorScheme.surfaceContainerHighest),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: clampedGain > 0
                          ? const Color(0xFFF59E0B)
                          : (isDark ? const Color(0xFF262936) : theme.colorScheme.outlineVariant),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    '${clampedGain >= 0 ? '+' : ''}${clampedGain.toStringAsFixed(1)} dB',
                    style: TextStyle(
                      color: clampedGain > 0
                          ? const Color(0xFFD97706)
                          : (isDark ? Colors.white : theme.colorScheme.onSurface),
                      fontFeatures: const [FontFeature.tabularFigures()],
                      fontWeight: FontWeight.w700,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Slider & Range Labels
            Row(
              children: [
                const Text(
                  '-18 dB',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF8A9A90),
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                Expanded(
                  child: M3ESlider(
                    value: clampedGain,
                    min: -18.0,
                    max: 3.0,
                    divisions: 42, // 0.5 dB steps
                    onChanged: isConnected
                        ? (val) {
                            final rounded = (val * 2).round() / 2.0;
                            onChanged(rounded);
                          }
                        : null,
                  ),
                ),
                const Text(
                  '+3 dB',
                  style: TextStyle(
                    fontSize: 10,
                    color: Color(0xFF8A9A90),
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
