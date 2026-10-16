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
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF1E212B) : const Color(0xFF16181F),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? const Color(0xFF383D50) : const Color(0xFF262936),
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
                          ? const Color(0xFF2E3242)
                          : (isSelected ? const Color(0xFF10B981) : const Color(0xFF252834)),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? const Color(0xFF10B981) : const Color(0xFF383D50),
                        width: 0.8,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${band.bandIndex + 1}',
                      style: TextStyle(
                        color: band.isBypassed
                            ? const Color(0xFF8A9A90)
                            : (isSelected ? Colors.black : Colors.white),
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
                            ? const Color(0xFF64748B)
                            : Colors.white,
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
                        color: const Color(0xFF1E212B),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFF262936), width: 0.8),
                      ),
                      child: Text(
                        '${band.formattedFrequency} • ${band.formattedGain} • ${band.formattedQ}',
                        style: const TextStyle(
                          color: Color(0xFFE6EAE7),
                          fontFeatures: [FontFeature.tabularFigures()],
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
                          color: const Color(0xFF1E212B),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF262936), width: 0.8),
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          band.isBypassed ? LucideIcons.volumeX : LucideIcons.volume2,
                          size: 15,
                          color: band.isBypassed
                              ? const Color(0xFFEF4444)
                              : const Color(0xFFA1B2A7),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Frequency Slider (Logarithmic 20Hz - 20,000Hz)
              _buildSliderRow(
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

  Widget _buildSliderRow({
    required String label,
    required String valueString,
    required Widget slider,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 38,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF8A9A90),
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
            style: const TextStyle(
              color: Colors.white,
              fontFeatures: [FontFeature.tabularFigures()],
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
