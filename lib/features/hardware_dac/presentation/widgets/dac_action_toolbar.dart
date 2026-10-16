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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF16181F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF262936), width: 1.0),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Preset Quick Selection
          Row(
            children: [
              const Icon(
                LucideIcons.bookmark,
                size: 15,
                color: Color(0xFF8A9A90),
              ),
              const SizedBox(width: 8),
              const Text(
                'PRESETS:',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: Color(0xFF8A9A90),
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
                                color: const Color(0xFF1E212B),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: const Color(0xFF262936), width: 0.8),
                              ),
                              child: Text(
                                preset.name,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFE6EAE7),
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
                              color: const Color(0xFF252834),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFF383D50), width: 0.8),
                            ),
                            child: const Text(
                              'MANAGE ALL',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: Color(0xFF10B981),
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
          const Divider(height: 1, color: Color(0xFF262936)),
          const SizedBox(height: 12),

          // Row 2: Action Buttons
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              // Burn to Flash (Primary Action)
              _buildButton(
                label: 'Burn to Flash',
                icon: LucideIcons.save,
                isPrimary: true,
                onPressed: isConnected && !isBusy ? onBurnToFlash : null,
              ),

              // Save Current Tuning as Named Profile
              _buildButton(
                label: 'Save Profile',
                icon: LucideIcons.bookmarkPlus,
                onPressed: isConnected && !isBusy ? () => SaveDacProfileDialog.show(context) : null,
              ),

              // Import AutoEQ
              _buildButton(
                label: 'AutoEQ Import',
                icon: LucideIcons.download,
                onPressed: isConnected && !isBusy ? onImportAutoEq : null,
              ),

              // Sync / Read from Hardware
              _buildButton(
                label: 'Read DAC',
                icon: LucideIcons.refreshCw,
                onPressed: isConnected && !isBusy ? onReadFromHardware : null,
              ),

              // Factory Reset
              _buildButton(
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

  Widget _buildButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    bool isPrimary = false,
  }) {
    return SizedBox(
      height: 36,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? const Color(0xFF252834) : const Color(0xFF1E212B),
          foregroundColor: isPrimary ? const Color(0xFF10B981) : Colors.white,
          disabledBackgroundColor: const Color(0xFF16181F),
          disabledForegroundColor: const Color(0xFF4B5563),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(
              color: isPrimary ? const Color(0xFF383D50) : const Color(0xFF262936),
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
