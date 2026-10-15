import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../domain/models/dac_peq_profile.dart';
import '../controllers/dac_bridge_controller.dart';
import 'save_dac_profile_dialog.dart';

/// Modal bottom sheet for viewing, managing, loading, burning, exporting, and importing
/// hardware DAC configuration profiles.
class DacProfileManagerModal extends ConsumerWidget {
  const DacProfileManagerModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DacProfileManagerModal(),
    );
  }

  Future<void> _handleImportFile(BuildContext context, WidgetRef ref) async {
    try {
      final files = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['dac', 'json'],
      );

      if (files.isNotEmpty && files.first.path != null) {
        final file = File(files.first.path!);
        final jsonStr = await file.readAsString();
        final controller = ref.read(dacBridgeControllerProvider.notifier);
        final profile = await controller.importProfileFromJson(jsonStr);

        if (profile != null) {
          AppHaptics.mediumImpact();
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Successfully imported DAC profile: "${profile.name}"'),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Invalid DAC profile format'),
                backgroundColor: Theme.of(context).colorScheme.error,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to import file: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _handleExportFile(BuildContext context, DacPeqProfile profile) async {
    try {
      final jsonStr = profile.exportToJsonString();
      final cleanName = '${profile.name.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_')}.dac';
      final bytes = Uint8List.fromList(utf8.encode(jsonStr));

      final savedUri = await FilePicker.saveFile(
        dialogTitle: 'Export DAC Profile',
        fileName: cleanName,
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: ['dac', 'json'],
      );

      if (savedUri != null) {
        AppHaptics.mediumImpact();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Profile exported: $cleanName'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to export profile: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final dacState = ref.watch(dacBridgeControllerProvider);
    final controller = ref.read(dacBridgeControllerProvider.notifier);

    final userProfiles = dacState.availablePresets.where((p) => !p.isBuiltIn).toList();
    final builtInProfiles = dacState.availablePresets.where((p) => p.isBuiltIn).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedBookmark02,
                    size: 20,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DAC PROFILE LIBRARY',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'User custom tunings and factory hardware presets',
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                M3EIconButton(
                  variant: M3EIconButtonVariant.tonal,
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedCancel01,
                    size: 22,
                    color: colorScheme.onSurface,
                  ),
                  tooltip: 'Close',
                  onPressed: () {
                    AppHaptics.selectionClick();
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),

          // Action Toolbar (Save Current & Import)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: M3EButton.filled(
                    icon: const HugeIcon(
                      icon: HugeIcons.strokeRoundedBookmark02,
                      size: 16,
                    ),
                    label: const Text('SAVE CURRENT TUNING'),
                    onPressed: () {
                      SaveDacProfileDialog.show(context);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                M3EButton.tonal(
                  icon: const HugeIcon(
                    icon: HugeIcons.strokeRoundedDownload01,
                    size: 16,
                  ),
                  label: const Text('IMPORT FILE'),
                  onPressed: () => _handleImportFile(context, ref),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Profiles Scrollable List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                // ─── SECTION 1: USER CUSTOM PROFILES ─────────────────────────
                _buildSectionTitle(
                  title: 'USER CUSTOM PROFILES',
                  count: userProfiles.length,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 8),
                if (userProfiles.isEmpty)
                  _buildEmptyUserProfiles(colorScheme)
                else
                  ...userProfiles.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _buildProfileCard(
                        context: context,
                        profile: p,
                        isActive: dacState.currentProfile.id == p.id,
                        isConnected: dacState.isConnected,
                        controller: controller,
                        colorScheme: colorScheme,
                        onExport: () => _handleExportFile(context, p),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // ─── SECTION 2: FACTORY STOCK PRESETS ───────────────────────
                _buildSectionTitle(
                  title: 'FACTORY STOCK PRESETS',
                  count: builtInProfiles.length,
                  colorScheme: colorScheme,
                ),
                const SizedBox(height: 8),
                ...builtInProfiles.map(
                  (p) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildProfileCard(
                      context: context,
                      profile: p,
                      isActive: dacState.currentProfile.id == p.id,
                      isConnected: dacState.isConnected,
                      controller: controller,
                      colorScheme: colorScheme,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle({
    required String title,
    required int count,
    required ColorScheme colorScheme,
  }) {
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.6,
            color: colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyUserProfiles(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Center(
        child: Column(
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedBookmark02,
              size: 28,
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 8),
            Text(
              'No custom DAC profiles saved yet',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Tune your 5-band PEQ and tap SAVE CURRENT TUNING.',
              style: TextStyle(
                fontSize: 11.5,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard({
    required BuildContext context,
    required DacPeqProfile profile,
    required bool isActive,
    required bool isConnected,
    required DacBridgeController controller,
    required ColorScheme colorScheme,
    VoidCallback? onExport,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isActive
            ? colorScheme.primaryContainer.withValues(alpha: 0.35)
            : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? colorScheme.primary : colorScheme.outlineVariant.withValues(alpha: 0.4),
          width: isActive ? 1.5 : 1.0,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isActive ? colorScheme.primary : colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedSlidersVertical,
                  size: 16,
                  color: isActive ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (profile.description.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        profile.description,
                        style: TextStyle(
                          fontSize: 11,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),

              // Preamp Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${profile.preampGainDb >= 0 ? "+" : ""}${profile.preampGainDb.toStringAsFixed(1)} dB',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Bands Summary Pills
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: profile.bands.map((b) {
                final fStr = b.frequency >= 1000
                    ? '${(b.frequency / 1000).toStringAsFixed(1)}k'
                    : '${b.frequency.round()}';
                final gStr = '${b.gainDb >= 0 ? "+" : ""}${b.gainDb.toStringAsFixed(1)}dB';

                return Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: colorScheme.outlineVariant.withValues(alpha: 0.3),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    'B${b.bandIndex + 1}: $fStr $gStr',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: b.gainDb != 0.0 ? colorScheme.primary : colorScheme.onSurfaceVariant,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 12),

          // Actions Row
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Export file button (Custom profiles only)
              if (!profile.isBuiltIn && onExport != null)
                M3EIconButton(
                  variant: M3EIconButtonVariant.standard,
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedDownload01,
                    size: 16,
                    color: colorScheme.onSurface,
                  ),
                  tooltip: 'Export as .dac file',
                  onPressed: onExport,
                ),

              // Delete button (Custom profiles only)
              if (!profile.isBuiltIn)
                M3EIconButton(
                  variant: M3EIconButtonVariant.standard,
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedDelete02,
                    size: 16,
                    color: colorScheme.error,
                  ),
                  tooltip: 'Delete profile',
                  onPressed: () async {
                    AppHaptics.mediumImpact();
                    await controller.deleteCustomProfile(profile.id);
                  },
                ),

              const SizedBox(width: 6),

              // Load to DAC Button
              M3EButton.outlined(
                decoration: const M3EButtonDecoration(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                onPressed: isActive
                    ? null
                    : () async {
                        AppHaptics.selectionClick();
                        await controller.applyProfile(profile);
                        if (context.mounted) Navigator.pop(context);
                      },
                child: Text(
                  isActive ? 'ACTIVE' : 'LOAD TO DAC',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),

              const SizedBox(width: 6),

              // Burn to Flash Button
              M3EButton.filled(
                decoration: const M3EButtonDecoration(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                ),
                onPressed: !isConnected
                    ? null
                    : () async {
                        AppHaptics.heavyImpact();
                        await controller.applyProfile(profile);
                        await controller.burnToFlash();
                        if (context.mounted) Navigator.pop(context);
                      },
                child: const Text(
                  'BURN FLASH',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
