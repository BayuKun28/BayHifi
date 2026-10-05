import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../domain/models/dac_peq_profile.dart';

/// Pure Material 3 Expressive Action Toolbar for Hardware DAC operations:
/// Flashing to EEPROM, Reading from DAC, Preset Selection, and Factory Reset.
class DacActionToolbar extends StatelessWidget {
  const DacActionToolbar({
    super.key,
    required this.isConnected,
    required this.isBusy,
    required this.hasUnsavedChanges,
    required this.presets,
    required this.onBurnToFlash,
    required this.onReadFromHardware,
    required this.onImportAutoEq,
    required this.onSelectPreset,
    required this.onResetDefault,
  });

  final bool isConnected;
  final bool isBusy;
  final bool hasUnsavedChanges;
  final List<DacPeqProfile> presets;
  final VoidCallback onBurnToFlash;
  final VoidCallback onReadFromHardware;
  final VoidCallback onImportAutoEq;
  final ValueChanged<DacPeqProfile> onSelectPreset;
  final VoidCallback onResetDefault;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Preset Quick Selection
          Row(
            children: [
              HugeIcon(
                icon: HugeIcons.strokeRoundedBookmark02,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Text(
                'Hardware Presets:',
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: presets.map((preset) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: M3EChip(
                          label: preset.name,
                          onPressed: isConnected && !isBusy
                              ? () => onSelectPreset(preset)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),

          // Row 2: Action Buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              // Burn to Flash (Primary Action)
              M3EButton.filled(
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedFloppyDisk,
                  size: 18,
                ),
                label: const Text('Burn to Flash'),
                onPressed: isConnected && !isBusy ? onBurnToFlash : null,
              ),

              // Import AutoEQ / Pro-Q
              M3EButton.tonal(
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedCloudDownload,
                  size: 18,
                ),
                label: const Text('AutoEQ Import'),
                onPressed: isConnected && !isBusy ? onImportAutoEq : null,
              ),

              // Sync / Read from Hardware
              M3EButton.elevated(
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedDownload01,
                  size: 18,
                ),
                label: const Text('Read DAC'),
                onPressed: isConnected && !isBusy ? onReadFromHardware : null,
              ),

              // Factory Reset
              M3EButton.outlined(
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedRefresh,
                  size: 18,
                ),
                label: const Text('Reset Flat'),
                onPressed: isConnected && !isBusy ? onResetDefault : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
