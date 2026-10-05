import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Pure Material 3 Expressive Card for adjusting the hardware USB DAC's Master Preamp Gain
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
    final colorScheme = theme.colorScheme;
    final clampedGain = globalGainDb.clamp(-18.0, 3.0);

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: 1.0,
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
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isConnected
                        ? colorScheme.primaryContainer
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedVolumeHigh,
                    color: isConnected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
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
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'Hardware analog volume / digital headroom',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                // Readout Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: clampedGain > 0
                        ? colorScheme.tertiaryContainer
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: clampedGain > 0
                          ? colorScheme.tertiary.withValues(alpha: 0.5)
                          : colorScheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${clampedGain >= 0 ? '+' : ''}${clampedGain.toStringAsFixed(1)} dB',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: clampedGain > 0
                          ? colorScheme.onTertiaryContainer
                          : colorScheme.onSurface,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Slider Row
            Row(
              children: [
                SizedBox(
                  width: 42,
                  child: Text(
                    'GAIN',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 10,
                    ),
                  ),
                ),
                Expanded(
                  child: M3ESlider(
                    value: clampedGain,
                    min: -18.0,
                    max: 3.0,
                    divisions: 210, // 0.1 dB step
                    onChanged: isConnected
                        ? (val) {
                            final rounded = (val * 10).round() / 10.0;
                            onChanged(rounded);
                          }
                        : null,
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: Text(
                    '${clampedGain >= 0 ? '+' : ''}${clampedGain.toStringAsFixed(1)} dB',
                    textAlign: TextAlign.end,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurface,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Quick Preset Chips
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _buildQuickGainChip(context, label: '-6.0 dB', value: -6.0),
                _buildQuickGainChip(context, label: '-3.0 dB', value: -3.0),
                _buildQuickGainChip(context, label: '-1.0 dB', value: -1.0),
                _buildQuickGainChip(context, label: '0.0 dB (Unity)', value: 0.0),
                _buildQuickGainChip(context, label: '+1.5 dB', value: 1.5),
                _buildQuickGainChip(context, label: '+3.0 dB', value: 3.0),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickGainChip(
    BuildContext context, {
    required String label,
    required double value,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isSelected = (globalGainDb - value).abs() < 0.05;

    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: isConnected ? () => onChanged(value) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: isSelected
                ? colorScheme.onPrimary
                : colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
            fontSize: 10,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
      ),
    );
  }
}
