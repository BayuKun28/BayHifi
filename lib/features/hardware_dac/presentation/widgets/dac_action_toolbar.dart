import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../domain/models/dac_peq_profile.dart';
import 'dac_profile_manager_modal.dart';
import 'save_dac_profile_dialog.dart';

/// Solid Matte Action Toolbar for Hardware DAC operations:
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
    final isDark = theme.brightness == Brightness.dark;

    final metaColor = isDark ? const Color(0xFF8A9A90) : colorScheme.onSurfaceVariant;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16181F) : colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF262936) : colorScheme.outlineVariant,
          width: 1.0,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Preset Quick Selection
          Row(
            children: [
              Icon(
                LucideIcons.bookmark,
                size: 15,
                color: metaColor,
              ),
              const SizedBox(width: 8),
              Text(
                'PRESETS:',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: metaColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...presets.map((preset) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 6.0),
                          child: InkWell(
                            onTap: isConnected && !isBusy ? () => onSelectPreset(preset) : null,
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF1E212B) : colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isDark ? const Color(0xFF262936) : colorScheme.outlineVariant,
                                  width: 0.8,
                                ),
                              ),
                              child: Text(
                                preset.name,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? const Color(0xFFE6EAE7) : colorScheme.onSurface,
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      Padding(
                        padding: const EdgeInsets.only(right: 6.0),
                        child: InkWell(
                          onTap: () => DacProfileManagerModal.show(context),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF252834) : colorScheme.primaryContainer,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isDark ? const Color(0xFF383D50) : colorScheme.outlineVariant,
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              'MANAGE ALL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: isDark ? const Color(0xFF10B981) : colorScheme.onPrimaryContainer,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: isDark ? const Color(0xFF262936) : colorScheme.outlineVariant,
          ),
          const SizedBox(height: 12),

          // Row 2: Action Buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              // Burn to Flash (Primary Action)
              _buildButton(
                context,
                label: 'Burn to Flash',
                icon: LucideIcons.save,
                isPrimary: true,
                onPressed: isConnected && !isBusy ? onBurnToFlash : null,
              ),

              // Save Current Tuning as Named Profile
              _buildButton(
                context,
                label: 'Save Profile',
                icon: LucideIcons.bookmarkPlus,
                onPressed: isConnected && !isBusy ? () => SaveDacProfileDialog.show(context) : null,
              ),

              // Import AutoEQ
              _buildButton(
                context,
                label: 'AutoEQ Import',
                icon: LucideIcons.download,
                onPressed: isConnected && !isBusy ? onImportAutoEq : null,
              ),

              // Sync / Read from Hardware
              _buildButton(
                context,
                label: 'Read DAC',
                icon: LucideIcons.refreshCw,
                onPressed: isConnected && !isBusy ? onReadFromHardware : null,
              ),

              // Factory Reset
              _buildButton(
                context,
                label: 'Reset Flat',
                icon: LucideIcons.rotateCcw,
                onPressed: isConnected && !isBusy ? onResetDefault : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    bool isPrimary = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final primaryBg = isDark ? const Color(0xFF252834) : colorScheme.primaryContainer;
    final primaryFg = isDark ? const Color(0xFF10B981) : colorScheme.onPrimaryContainer;
    final secondaryBg = isDark ? const Color(0xFF1E212B) : colorScheme.surfaceContainerHighest;
    final secondaryFg = isDark ? Colors.white : colorScheme.onSurface;

    return SizedBox(
      height: 36,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? primaryBg : secondaryBg,
          foregroundColor: isPrimary ? primaryFg : secondaryFg,
          disabledBackgroundColor: isDark ? const Color(0xFF16181F) : colorScheme.surfaceContainerLow,
          disabledForegroundColor: isDark ? const Color(0xFF4B5563) : colorScheme.onSurface.withValues(alpha: 0.38),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isPrimary
                  ? (isDark ? const Color(0xFF383D50) : colorScheme.primary.withValues(alpha: 0.4))
                  : (isDark ? const Color(0xFF262936) : colorScheme.outlineVariant),
              width: 0.8,
            ),
          ),
        ),
        icon: Icon(icon, size: 14),
        label: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isPrimary ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
