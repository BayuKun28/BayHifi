import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../domain/models/dac_band_config.dart';

/// Pure Material 3 Expressive Card for adjusting individual hardware biquad filter parameters
/// (Frequency, Gain, Q-Factor, and Bypass) in real-time.
class DacBandSliderTile extends StatelessWidget {
  const DacBandSliderTile({
    super.key,
    required this.band,
    required this.isSelected,
    required this.onChanged,
    this.onTap,
  });

  final DacBandConfig band;
  final bool isSelected;
  final ValueChanged<DacBandConfig> onChanged;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? colorScheme.surfaceContainerHigh
            : colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: isSelected ? 1.5 : 1.0,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row: Band Pill, Filter Type, Readouts, and Bypass
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: band.isBypassed
                          ? colorScheme.surfaceContainerHighest
                          : (isSelected
                              ? colorScheme.primary
                              : colorScheme.primaryContainer),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${band.bandIndex + 1}',
                        style: TextStyle(
                          color: band.isBypassed
                              ? colorScheme.onSurfaceVariant
                              : (isSelected
                                  ? colorScheme.onPrimary
                                  : colorScheme.onPrimaryContainer),
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    band.filterType.displayName,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: band.isBypassed
                          ? colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
                          : colorScheme.onSurface,
                    ),
                  ),
                  const Spacer(),

                  // Readouts Pill (Freq, Gain, Q)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${band.formattedFrequency} • ${band.formattedGain} • ${band.formattedQ}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontFeatures: const [FontFeature.tabularFigures()],
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Bypass toggle button
                  M3EIconButton(
                    icon: HugeIcon(
                      icon: band.isBypassed
                          ? HugeIcons.strokeRoundedVolumeOff
                          : HugeIcons.strokeRoundedVolumeHigh,
                      size: 18,
                      color: band.isBypassed
                          ? colorScheme.error
                          : colorScheme.onSurfaceVariant,
                    ),
                    tooltip: band.isBypassed ? 'Unbypass Band' : 'Bypass Band',
                    onPressed: () {
                      onChanged(band.copyWith(isBypassed: !band.isBypassed));
                    },
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Frequency Slider (Logarithmic 20Hz - 20,000Hz)
              _buildSliderRow(
                context,
                label: 'FREQ',
                valueString: band.formattedFrequency,
                slider: M3ESlider(
                  value: _freqToLogSlider(band.frequency),
                  min: 0.0,
                  max: 1.0,
                  onChanged: band.isBypassed
                      ? null
                      : (val) {
                          final newFreq = _logSliderToFreq(val);
                          onChanged(band.copyWith(frequency: newFreq));
                        },
                ),
              ),

              // Gain Slider (-12.0 dB .. +12.0 dB)
              _buildSliderRow(
                context,
                label: 'GAIN',
                valueString: band.formattedGain,
                slider: M3ESlider(
                  value: band.gainDb.clamp(-12.0, 12.0),
                  min: -12.0,
                  max: 12.0,
                  divisions: 240, // 0.1 dB step
                  onChanged: band.isBypassed
                      ? null
                      : (val) {
                          onChanged(band.copyWith(gainDb: (val * 10).round() / 10.0));
                        },
                ),
              ),

              // Q-Factor Slider (0.10 .. 10.00)
              _buildSliderRow(
                context,
                label: 'Q',
                valueString: band.formattedQ,
                slider: M3ESlider(
                  value: band.qFactor.clamp(0.10, 10.00),
                  min: 0.10,
                  max: 10.00,
                  divisions: 198, // 0.05 step
                  onChanged: band.isBypassed
                      ? null
                      : (val) {
                          onChanged(band.copyWith(qFactor: (val * 100).round() / 100.0));
                        },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSliderRow(
    BuildContext context, {
    required String label,
    required String valueString,
    required Widget slider,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        SizedBox(
          width: 42,
          child: Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurfaceVariant,
              fontSize: 10,
            ),
          ),
        ),
        Expanded(child: slider),
        SizedBox(
          width: 60,
          child: Text(
            valueString,
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
    );
  }

  static double _freqToLogSlider(double freq) {
    const minLog = 1.30103; // log10(20)
    const maxLog = 4.30103; // log10(20000)
    final logVal = math.log(freq.clamp(20.0, 20000.0)) / math.ln10;
    return ((logVal - minLog) / (maxLog - minLog)).clamp(0.0, 1.0);
  }

  static double _logSliderToFreq(double sliderVal) {
    const minLog = 1.30103;
    const maxLog = 4.30103;
    final logFreq = minLog + sliderVal * (maxLog - minLog);
    return math.pow(10, logFreq).toDouble().clamp(20.0, 20000.0);
  }
}
