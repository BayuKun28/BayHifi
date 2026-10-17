import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Reusable Audio Parameter Slider with tabular figures readout
class RackKnobSlider extends StatelessWidget {
  const RackKnobSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.formattedValue,
    required this.onChanged,
    this.accentColor,
    this.divisions,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final String formattedValue;
  final ValueChanged<double> onChanged;
  final Color? accentColor;
  final int? divisions;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.8,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E212B) : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: isDark ? const Color(0xFF262936) : theme.colorScheme.outlineVariant,
                  width: 0.8,
                ),
              ),
              child: Text(
                formattedValue,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: isDark ? Colors.white : theme.colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        M3ESlider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: (divisions != null && divisions! > 0) ? divisions : null,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
