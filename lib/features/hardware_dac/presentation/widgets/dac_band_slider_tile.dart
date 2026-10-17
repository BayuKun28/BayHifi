import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../domain/models/dac_band_config.dart';

/// Solid Matte Card for adjusting individual hardware biquad filter parameters
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
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? (isDark ? const Color(0xFF1E212B) : theme.colorScheme.primaryContainer)
            : (isDark ? const Color(0xFF16181F) : theme.colorScheme.surfaceContainer),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? (isDark ? const Color(0xFF383D50) : theme.colorScheme.primary.withValues(alpha: 0.35))
              : (isDark ? const Color(0xFF262936) : theme.colorScheme.outlineVariant),
          width: isSelected ? 1.2 : 0.8,
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
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: band.isBypassed
                          ? (isDark ? const Color(0xFF2E3242) : theme.colorScheme.surfaceContainerHighest)
                          : (isSelected
                              ? const Color(0xFF10B981)
                              : (isDark ? const Color(0xFF252834) : theme.colorScheme.surfaceContainerHighest)),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF10B981)
                            : (isDark ? const Color(0xFF383D50) : theme.colorScheme.outlineVariant),
                        width: 0.8,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${band.bandIndex + 1}',
                      style: TextStyle(
                        color: band.isBypassed
                            ? (isDark ? const Color(0xFF8A9A90) : theme.colorScheme.onSurfaceVariant)
                            : (isSelected
                                ? Colors.white
                                : (isDark ? Colors.white : theme.colorScheme.onSurface)),
                        fontWeight: FontWeight.w800,
                        fontSize: 11.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      band.filterType.displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                        color: band.isBypassed
                            ? (isDark ? const Color(0xFF64748B) : theme.colorScheme.outline)
                            : (isDark ? Colors.white : theme.colorScheme.onSurface),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Readouts Pill (Freq, Gain, Q)
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E212B) : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: isDark ? const Color(0xFF262936) : theme.colorScheme.outlineVariant,
                          width: 0.8,
                        ),
                      ),
                      child: Text(
                        '${band.formattedFrequency} • ${band.formattedGain} • ${band.formattedQ}',
                        style: TextStyle(
                          color: isDark ? const Color(0xFFE6EAE7) : theme.colorScheme.onSurface,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          fontWeight: FontWeight.w600,
                          fontSize: 10.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Bypass toggle button
                  Tooltip(
                    message: band.isBypassed ? 'Unbypass Band' : 'Bypass Band',
                    child: InkWell(
                      onTap: () {
                        onChanged(band.copyWith(isBypassed: !band.isBypassed));
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E212B) : theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? const Color(0xFF262936) : theme.colorScheme.outlineVariant,
                            width: 0.8,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          band.isBypassed ? LucideIcons.volumeX : LucideIcons.volume2,
                          size: 15,
                          color: band.isBypassed
                              ? const Color(0xFFEF4444)
                              : (isDark ? const Color(0xFFA1B2A7) : theme.colorScheme.onSurfaceVariant),
                        ),
                      ),
                    ),
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
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        SizedBox(
          width: 38,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF8A9A90) : theme.colorScheme.onSurfaceVariant,
              fontSize: 10,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Expanded(child: slider),
        SizedBox(
          width: 54,
          child: Text(
            valueString,
            textAlign: TextAlign.end,
            style: TextStyle(
              color: isDark ? Colors.white : theme.colorScheme.onSurface,
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
