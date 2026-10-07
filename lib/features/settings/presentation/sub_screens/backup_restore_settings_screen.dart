import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../../app/theme/theme_mode_controller.dart';
import '../../../library/presentation/controllers/library_controller.dart';
import '../../data/backup_restore_service.dart';

/// Backup & Restore Settings Sub-Screen (.bayhifi JSON Archive Engine)
class BackupRestoreSettingsScreen extends ConsumerStatefulWidget {
  const BackupRestoreSettingsScreen({super.key});

  @override
  ConsumerState<BackupRestoreSettingsScreen> createState() => _BackupRestoreSettingsScreenState();
}

class _BackupRestoreSettingsScreenState extends ConsumerState<BackupRestoreSettingsScreen> {
  bool _includeHistory = true;
  bool _includeLibrary = true;

  Future<void> _exportBackupFile() async {
    AppHaptics.mediumImpact();
    final jsonStr = BackupRestoreService.instance.createBackupJson(
      includeHistory: _includeHistory,
      includeLibrary: _includeLibrary,
    );

    final file = await BackupRestoreService.instance.saveBackupToFile(jsonStr);
    await BackupRestoreService.instance.autoExportToPublicDirectory();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup saved to storage: ${file.path.split('/').last}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _copyBackupJson() async {
    AppHaptics.lightImpact();
    final jsonStr = BackupRestoreService.instance.createBackupJson(
      includeHistory: _includeHistory,
      includeLibrary: _includeLibrary,
    );

    await Clipboard.setData(ClipboardData(text: jsonStr));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Backup JSON copied to clipboard.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _showRestoreDialog() async {
    final textController = TextEditingController();

    // Check if clipboard has JSON
    final clipData = await Clipboard.getData(Clipboard.kTextPlain);
    if (clipData?.text != null && clipData!.text!.contains('Baydev HiFi')) {
      textController.text = clipData.text!;
    }

    if (!mounted) return;

    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isSolid = ref.read(themeControllerProvider).isSolidStyle;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: StudioSurfaceTheme.surface(context, isSolid: isSolid),
      shape: RoundedRectangleBorder(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(
          color: StudioSurfaceTheme.outline(context, isSolid: isSolid),
          width: 1.0,
        ),
      ),
      builder: (modalCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final text = textController.text;
            final validation = text.isNotEmpty
                ? BackupRestoreService.instance.validateBackup(text)
                : null;

            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      HugeIcon(icon: HugeIcons.strokeRoundedCloudSync, size: 20, color: primary),
                      const SizedBox(width: 8),
                      Text(
                        'RESTORE FROM BACKUP',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: textController,
                    maxLines: 4,
                    onChanged: (_) => setModalState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Paste .bayhifi backup JSON payload here...',
                      hintStyle: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant),
                      filled: true,
                      fillColor: StudioSurfaceTheme.surfaceContainerLow(ctx, isSolid: isSolid),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 12),

                  if (validation != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: validation.isValid
                            ? primary.withValues(alpha: 0.1)
                            : theme.colorScheme.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: validation.isValid
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    HugeIcon(
                                      icon: HugeIcons.strokeRoundedCheckmarkCircle02,
                                      size: 16,
                                      color: primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Valid Baydev HiFi Snapshot',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: primary,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Contains ${validation.customPlaylistsCount} playlists, ${validation.smartPlaylistsCount} smart rules, and ${validation.favoritesCount} favorites.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ],
                            )
                          : Text(
                              validation.errorMessage ?? 'Invalid backup format.',
                              style: TextStyle(
                                fontSize: 11,
                                color: theme.colorScheme.error,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  SizedBox(
                    width: double.infinity,
                    child: M3EButton.filled(
                      onPressed: validation?.isValid == true
                          ? () async {
                              Navigator.of(ctx).pop();
                              await _performRestore(textController.text);
                            }
                          : null,
                      label: const Text(
                        'Apply & Restore Configuration',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _performRestore(String jsonStr) async {
    AppHaptics.heavyImpact();
    final result = await BackupRestoreService.instance.restoreFromBackupJson(jsonStr);

    if (result.success) {
      // Re-initialize theme controller and library
      ref.read(themeControllerProvider.notifier).reloadPersistedTheme();
      ref.read(unifiedLibraryProvider.notifier).reloadFromPersistence();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message), behavior: SnackBarBehavior.floating),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Restore failed: ${result.message}'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isSolid = ref.isSolidStyle;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('BACKUP & RESTORE'),
        leading: M3EIconButton(
          icon: HugeIcon(
            icon: HugeIcons.strokeRoundedArrowLeft01,
            size: 20,
            color: theme.colorScheme.onSurface,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
        children: [
          // ─── 1. STATUS HERO BANNER ──────────────────────────────────────────
          _buildHeroBanner(theme, primary, isSolid),
          const SizedBox(height: 18),

          // ─── 2. CREATE SNAPSHOT ARCHIVE ─────────────────────────────────────
          _buildSectionHeader(context, 'CREATE SNAPSHOT ARCHIVE', HugeIcons.strokeRoundedCloudDownload),
          const SizedBox(height: 8),
          _buildExportCard(context, theme, primary, isSolid),
          const SizedBox(height: 20),

          // ─── 3. RESTORE FROM SNAPSHOT ───────────────────────────────────────
          _buildSectionHeader(context, 'RESTORE FROM SNAPSHOT', HugeIcons.strokeRoundedCloudSync),
          const SizedBox(height: 8),
          _buildRestoreCard(context, theme, primary, isSolid),
        ],
      ),
    );
  }

  Widget _buildExportCard(BuildContext context, ThemeData theme, Color primary, bool isSolid) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: StudioSurfaceTheme.cardDecoration(
        context: context,
        isSolid: isSolid,
        radius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Export .bayhifi Configuration',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Includes theme styling, custom playlists, smart rules, DSP presets, and favorite tracks.',
            style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 14),

          // Include History Toggle
          _buildSwitchRow(
            theme: theme,
            primary: primary,
            title: 'Include Playback History',
            subtitle: 'Listening statistics and last played timestamps',
            value: _includeHistory,
            onChanged: (val) => setState(() => _includeHistory = val),
          ),
          const Divider(height: 16),

          // Include Library Tracks Toggle
          _buildSwitchRow(
            theme: theme,
            primary: primary,
            title: 'Include Cached Library Database',
            subtitle: 'Cached track metadata and album catalog',
            value: _includeLibrary,
            onChanged: (val) => setState(() => _includeLibrary = val),
          ),
          const SizedBox(height: 16),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: M3EButton.outlined(
                  onPressed: _copyBackupJson,
                  icon: HugeIcon(icon: HugeIcons.strokeRoundedCopy01, size: 14, color: primary),
                  label: Text('Copy JSON', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: primary)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: M3EButton.filled(
                  onPressed: _exportBackupFile,
                  icon: HugeIcon(icon: HugeIcons.strokeRoundedCloudDownload, size: 14, color: theme.colorScheme.onPrimary),
                  label: Text('Save .bayhifi File', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: theme.colorScheme.onPrimary)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRestoreCard(BuildContext context, ThemeData theme, Color primary, bool isSolid) {
    return Material(
      color: isSolid
          ? theme.colorScheme.surfaceContainer
          : StudioSurfaceTheme.surfaceContainer(context, isSolid: false),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: StudioSurfaceTheme.outline(context, isSolid: isSolid),
          width: 0.8,
        ),
      ),
      child: InkWell(
        onTap: () {
          AppHaptics.lightImpact();
          _showRestoreDialog();
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: StudioSurfaceTheme.tintedContainer(
                    context,
                    primary,
                    isSolid: isSolid,
                    translucentAlpha: 0.12,
                    solidBlendAlpha: 0.16,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: HugeIcon(icon: HugeIcons.strokeRoundedCloudSync, size: 24, color: primary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Restore Snapshot / JSON Payload',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Load settings, smart rules, and playlists from a .bayhifi backup payload',
                      style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, size: 16, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchRow({
    required ThemeData theme,
    required Color primary,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 10,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
        M3ESwitch(
          value: value,
          onChanged: (val) {
            AppHaptics.lightImpact();
            onChanged(val);
          },
        ),
      ],
    );
  }

  Widget _buildHeroBanner(ThemeData theme, Color primary, bool isSolid) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: StudioSurfaceTheme.cardDecoration(
        context: context,
        isSolid: isSolid,
        radius: 16,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: StudioSurfaceTheme.tintedContainer(
                    context,
                    primary,
                    isSolid: isSolid,
                    translucentAlpha: 0.12,
                    solidBlendAlpha: 0.16,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedDatabase,
                  size: 18,
                  color: primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '.BAYHIFI SNAPSHOT ENGINE',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '100% portable JSON snapshot architecture for seamless device migration',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusPill(
                context,
                theme,
                label: 'Format: .bayhifi v1 JSON',
                isActive: true,
                color: primary,
                isSolid: isSolid,
              ),
              _buildStatusPill(
                context,
                theme,
                label: 'Profiles, EQ & Playlists: Included',
                isActive: true,
                color: theme.colorScheme.secondary,
                isSolid: isSolid,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPill(
    BuildContext context,
    ThemeData theme, {
    required String label,
    required bool isActive,
    required Color color,
    required bool isSolid,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
      decoration: BoxDecoration(
        color: isSolid
            ? (isActive
                ? color.withValues(alpha: 0.16)
                : theme.colorScheme.surfaceContainerHighest)
            : (isActive
                ? color.withValues(alpha: 0.14)
                : theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: isActive ? color : theme.colorScheme.onSurface.withValues(alpha: 0.65),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, dynamic icon) {
    final theme = Theme.of(context);
    return Row(
      children: [
        HugeIcon(icon: icon, size: 15, color: theme.colorScheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
          ),
        ),
      ],
    );
  }
}

