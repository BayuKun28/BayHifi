import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
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
    HapticFeedback.mediumImpact();
    final jsonStr = BackupRestoreService.instance.createBackupJson(
      includeHistory: _includeHistory,
      includeLibrary: _includeLibrary,
    );

    final file = await BackupRestoreService.instance.saveBackupToFile(jsonStr);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Backup saved: ${file.path.split('/').last}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _copyBackupJson() async {
    HapticFeedback.lightImpact();
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
                      fillColor: theme.colorScheme.surfaceContainerHighest,
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
                        border: Border.all(
                          color: validation.isValid ? primary : theme.colorScheme.error,
                          width: 0.8,
                        ),
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
                    child: FilledButton(
                      onPressed: validation?.isValid == true
                          ? () async {
                              Navigator.of(ctx).pop();
                              await _performRestore(textController.text);
                            }
                          : null,
                      style: FilledButton.styleFrom(
                        backgroundColor: primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: Text(
                        'Apply & Restore Configuration',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onPrimary,
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
    HapticFeedback.heavyImpact();
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

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: const Text('BACKUP & RESTORE'),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. Hero Backup Engine Banner
          _buildHeroBanner(theme, primary),
          const SizedBox(height: 16),

          // 2. Export Section Header
          _buildSectionHeader(context, 'CREATE SNAPSHOT ARCHIVE', HugeIcons.strokeRoundedCloudDownload),
          const SizedBox(height: 8),

          // Export Configuration Card
          Material(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: theme.colorScheme.outlineVariant, width: 1.0),
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
                  const SizedBox(height: 12),

                  // Include History Toggle
                  SwitchListTile(
                    title: const Text('Include Playback History', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Listening statistics and last played timestamps', style: TextStyle(fontSize: 10.5)),
                    value: _includeHistory,
                    onChanged: (val) => setState(() => _includeHistory = val),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),

                  // Include Library Tracks Toggle
                  SwitchListTile(
                    title: const Text('Include Cached Library Database', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    subtitle: const Text('Cached track metadata and album catalog', style: TextStyle(fontSize: 10.5)),
                    value: _includeLibrary,
                    onChanged: (val) => setState(() => _includeLibrary = val),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                  const SizedBox(height: 14),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _copyBackupJson,
                          icon: HugeIcon(icon: HugeIcons.strokeRoundedCopy01, size: 14, color: primary),
                          label: Text('Copy JSON', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: primary)),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: primary.withValues(alpha: 0.5)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _exportBackupFile,
                          icon: HugeIcon(icon: HugeIcons.strokeRoundedCloudDownload, size: 14, color: theme.colorScheme.onPrimary),
                          label: Text('Save .bayhifi File', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: theme.colorScheme.onPrimary)),
                          style: FilledButton.styleFrom(
                            backgroundColor: primary,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // 3. Restore Section Header
          _buildSectionHeader(context, 'RESTORE FROM SNAPSHOT', HugeIcons.strokeRoundedCloudSync),
          const SizedBox(height: 8),

          // Restore Card
          Material(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            child: InkWell(
              onTap: _showRestoreDialog,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6), width: 1.0),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.12),
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
          ),
          const SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(ThemeData theme, Color primary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant, width: 1.0),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: HugeIcon(icon: HugeIcons.strokeRoundedDatabase, size: 24, color: primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '.BAYHIFI SNAPSHOT ENGINE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: primary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '100% portable JSON snapshot architecture for seamless device migration.',
                  style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, dynamic icon) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 4, top: 8),
      child: Row(
        children: [
          HugeIcon(icon: icon, size: 14, color: primary),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
