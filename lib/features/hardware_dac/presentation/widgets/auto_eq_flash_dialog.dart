import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../../pro_q_studio/domain/eq_band.dart';
import '../../domain/models/dac_device.dart';
import '../../domain/models/dac_peq_profile.dart';
import '../../domain/services/auto_eq_to_hardware_fitter.dart';
import 'hardware_curve_visualizer.dart';

/// Modal dialog to preview a 5-band optimized approximation of an AutoEQ / Pro-Q curve
/// and flash it directly to the connected USB DAC hardware.
class AutoEqFlashDialog extends StatefulWidget {
  const AutoEqFlashDialog({
    super.key,
    required this.device,
    required this.sourceBands,
    required this.profileTitle,
    required this.onConfirmFlash,
  });

  final DacDevice device;
  final List<EqBand> sourceBands;
  final String profileTitle;
  final ValueChanged<DacPeqProfile> onConfirmFlash;

  static Future<void> show({
    required BuildContext context,
    required DacDevice device,
    required List<EqBand> sourceBands,
    required String profileTitle,
    required ValueChanged<DacPeqProfile> onConfirmFlash,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AutoEqFlashDialog(
        device: device,
        sourceBands: sourceBands,
        profileTitle: profileTitle,
        onConfirmFlash: onConfirmFlash,
      ),
    );
  }

  @override
  State<AutoEqFlashDialog> createState() => _AutoEqFlashDialogState();
}

class _AutoEqFlashDialogState extends State<AutoEqFlashDialog> {
  late DacPeqProfile _fittedProfile;
  final AutoEqToHardwareFitter _fitter = const AutoEqToHardwareFitter();

  @override
  void initState() {
    super.initState();
    _fittedProfile = _fitter.fitFromEqBands(
      widget.sourceBands,
      name: widget.profileTitle,
      targetChipset: widget.device.chipset,
      targetBandCount: widget.device.maxBands,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      backgroundColor: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      LucideIcons.cpu,
                      color: colorScheme.onPrimaryContainer,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Flash AutoEQ to ${widget.device.productName}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '5-Band Hardware Fitting Preview',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  M3EIconButton(
                    icon: const Icon(LucideIcons.x, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Curve Preview
              HardwareCurveVisualizer(
                bands: _fittedProfile.bands,
                isEqEnabled: true,
                preampDb: _fittedProfile.preampGainDb,
                height: 140,
              ),

              const SizedBox(height: 14),

              // Band Summary Table
              Text(
                'Fitted Hardware Biquads (${_fittedProfile.bands.length} Bands):',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: _fittedProfile.bands.map((band) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'B${band.bandIndex + 1} (${band.filterType.displayName}):',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${band.formattedFrequency}  •  ${band.formattedGain}  •  ${band.formattedQ}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 12),

              // Safe Preamp Info Note
              Row(
                children: [
                  Icon(
                    LucideIcons.shieldCheck,
                    size: 16,
                    color: colorScheme.primary,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Auto-Preamp: ${_fittedProfile.preampGainDb.toStringAsFixed(1)} dB (Digital Clipping Guard)',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  M3EButton.outlined(
                    label: const Text('Cancel'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 8),
                  M3EButton.filled(
                    icon: const Icon(
                      LucideIcons.save,
                      size: 18,
                    ),
                    label: const Text('Flash to Hardware'),
                    onPressed: () {
                      Navigator.of(context).pop();
                      widget.onConfirmFlash(_fittedProfile);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
