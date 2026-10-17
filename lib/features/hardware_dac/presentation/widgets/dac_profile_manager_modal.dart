import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../domain/models/dac_peq_profile.dart';
import '../controllers/dac_bridge_controller.dart';
import 'save_dac_profile_dialog.dart';

/// Modal dialog or bottom sheet for viewing, managing, loading, burning, exporting, and importing
/// hardware DAC configuration profiles.
///
/// Responsive across mobile (bottom sheet) and desktop/tablet (centered dialog).
class DacProfileManagerModal extends ConsumerWidget {
  final bool isDialog;

  const DacProfileManagerModal({
    super.key,
    this.isDialog = false,
  });

  static Future<void> show(BuildContext context) {
    final isDesktopOrTablet = MediaQuery.of(context).size.width >= 650;
    if (isDesktopOrTablet) {
      return showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.65),
        builder: (_) => const Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: DacProfileManagerModal(isDialog: true),
        ),
      );
    }
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const DacProfileManagerModal(isDialog: false),
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
              const SnackBar(
                content: Text('Invalid DAC profile format'),
                backgroundColor: Color(0xFF381E24),
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
            backgroundColor: const Color(0xFF381E24),
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
            backgroundColor: const Color(0xFF381E24),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dacState = ref.watch(dacBridgeControllerProvider);
    final controller = ref.read(dacBridgeControllerProvider.notifier);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final userProfiles = dacState.availablePresets.where((p) => !p.isBuiltIn).toList();
    final builtInProfiles = dacState.availablePresets.where((p) => p.isBuiltIn).toList();

    return Container(
      constraints: BoxConstraints(
        maxWidth: isDialog ? 560 : double.infinity,
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16181F) : colorScheme.surfaceContainer,
        borderRadius: isDialog
            ? BorderRadius.circular(20)
            : const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: isDark ? const Color(0xFF262936) : colorScheme.outlineVariant,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle (Mobile bottom sheet only)
          if (!isDialog)
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2E3344) : colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E212B) : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? const Color(0xFF262936) : colorScheme.outlineVariant,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    LucideIcons.bookmark,
                    size: 18,
                    color: Color(0xFF4ADE80),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DAC PROFILE LIBRARY',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: isDark ? Colors.white : colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        'User custom tunings and factory hardware presets',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF8A9A90) : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(
                    LucideIcons.x,
                    size: 18,
                    color: isDark ? const Color(0xFF8A9A90) : colorScheme.onSurfaceVariant,
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
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF4ADE80),
                      foregroundColor: const Color(0xFF0B110E),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 11),
                    ),
                    icon: const Icon(LucideIcons.bookmark, size: 15),
                    label: const Text(
                      'SAVE CURRENT TUNING',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.4),
                    ),
                    onPressed: () {
                      SaveDacProfileDialog.show(context);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF222532) : colorScheme.surfaceContainerHighest,
                    foregroundColor: isDark ? Colors.white : colorScheme.onSurface,
                    side: BorderSide(
                      color: isDark ? const Color(0xFF262936) : colorScheme.outlineVariant,
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 14),
                  ),
                  icon: Icon(
                    LucideIcons.download,
                    size: 15,
                    color: isDark ? const Color(0xFF8A9A90) : colorScheme.onSurfaceVariant,
                  ),
                  label: const Text(
                    'IMPORT FILE',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.4),
                  ),
                  onPressed: () => _handleImportFile(context, ref),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Profiles Scrollable List
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                // ─── SECTION 1: USER CUSTOM PROFILES ─────────────────────────
                _buildSectionTitle(
                  context: context,
                  title: 'USER CUSTOM PROFILES',
                  count: userProfiles.length,
                ),
                const SizedBox(height: 8),
                if (userProfiles.isEmpty)
                  _buildEmptyUserProfiles(context)
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
                        onExport: () => _handleExportFile(context, p),
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

                // ─── SECTION 2: FACTORY STOCK PRESETS ───────────────────────
                _buildSectionTitle(
                  context: context,
                  title: 'FACTORY STOCK PRESETS',
                  count: builtInProfiles.length,
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
    required BuildContext context,
    required String title,
    required int count,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
            color: isDark ? const Color(0xFF8A9A90) : colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E212B) : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isDark ? const Color(0xFF262936) : colorScheme.outlineVariant,
            ),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
              color: isDark ? const Color(0xFF8A9A90) : colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyUserProfiles(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16181F) : colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF262936) : colorScheme.outlineVariant,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              LucideIcons.bookmark,
              size: 24,
              color: isDark ? const Color(0xFF555D6E) : colorScheme.outline,
            ),
            const SizedBox(height: 8),
            Text(
              'No custom DAC profiles saved yet',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Tune your 5-band PEQ and tap SAVE CURRENT TUNING.',
              style: TextStyle(
                fontSize: 11.5,
                color: isDark ? const Color(0xFF8A9A90) : colorScheme.onSurfaceVariant,
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
    VoidCallback? onExport,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final activeCardBg = isDark ? const Color(0xFF222532) : colorScheme.primaryContainer.withValues(alpha: 0.35);
    final inactiveCardBg = isDark ? const Color(0xFF1E212B) : colorScheme.surfaceContainerHighest;
    final activeBorder = isDark ? const Color(0xFF4ADE80) : colorScheme.primary;
    final inactiveBorder = isDark ? const Color(0xFF262936) : colorScheme.outlineVariant;
    final metaColor = isDark ? const Color(0xFF8A9A90) : colorScheme.onSurfaceVariant;
    final capsuleBg = isDark ? const Color(0xFF16181F) : colorScheme.surfaceContainer;

    return Container(
      decoration: BoxDecoration(
        color: isActive ? activeCardBg : inactiveCardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isActive ? activeBorder : inactiveBorder,
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
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isActive
                      ? (isDark ? const Color(0xFF4ADE80) : colorScheme.primary)
                      : capsuleBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isActive ? activeBorder : inactiveBorder,
                  ),
                ),
                alignment: Alignment.center,
                child: Icon(
                  LucideIcons.sliders,
                  size: 15,
                  color: isActive
                      ? (isDark ? const Color(0xFF0B110E) : colorScheme.onPrimary)
                      : metaColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name,
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : colorScheme.onSurface,
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
                          color: metaColor,
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
                  color: capsuleBg,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: inactiveBorder),
                ),
                child: Text(
                  '${profile.preampGainDb >= 0 ? "+" : ""}${profile.preampGainDb.toStringAsFixed(1)} dB',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                    color: metaColor,
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
                    color: capsuleBg,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: inactiveBorder,
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    'B${b.bandIndex + 1}: $fStr $gStr',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: b.gainDb != 0.0
                          ? (isDark ? const Color(0xFF4ADE80) : colorScheme.primary)
                          : metaColor,
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
                IconButton(
                  icon: Icon(
                    LucideIcons.download,
                    size: 16,
                    color: metaColor,
                  ),
                  tooltip: 'Export as .dac file',
                  onPressed: onExport,
                ),

              // Delete button (Custom profiles only)
              if (!profile.isBuiltIn)
                IconButton(
                  icon: const Icon(
                    LucideIcons.trash2,
                    size: 16,
                    color: Color(0xFFF87171),
                  ),
                  tooltip: 'Delete profile',
                  onPressed: () async {
                    AppHaptics.mediumImpact();
                    await controller.deleteCustomProfile(profile.id);
                  },
                ),

              const SizedBox(width: 6),

              // Load to DAC Button
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: isActive ? activeBorder : (isDark ? const Color(0xFF383D50) : colorScheme.outlineVariant),
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: isActive ? activeBorder : (isDark ? Colors.white : colorScheme.onSurface),
                  ),
                ),
              ),

              const SizedBox(width: 6),

              // Burn to Flash Button
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF252834) : colorScheme.primaryContainer,
                  foregroundColor: isDark ? Colors.white : colorScheme.onPrimaryContainer,
                  side: BorderSide(
                    color: isDark ? const Color(0xFF383D50) : colorScheme.outlineVariant,
                  ),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
