import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../app/theme/app_haptics.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/studio_surface_theme.dart';
import 'storage_permission_service.dart';

/// Material 3 Expressive dialog explaining the need for All Files Access permission
class StoragePermissionDialog extends StatelessWidget {
  final String featureName;
  final String rationale;

  const StoragePermissionDialog({
    super.key,
    this.featureName = 'Physical Audio Tagging & Storage',
    this.rationale =
        'Baydev HiFi requires "All Files Access" (MANAGE_EXTERNAL_STORAGE) to permanently write ID3 tags directly into your audio files and save downloaded music to your device storage without being erased on app cache resets.',
  });

  static Future<bool> show(
    BuildContext context, {
    String? featureName,
    String? rationale,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => StoragePermissionDialog(
        featureName: featureName ?? 'Physical Audio Tagging & Storage',
        rationale: rationale ??
            'Baydev HiFi requires "All Files Access" (MANAGE_EXTERNAL_STORAGE) to permanently write ID3 tags directly into your audio files and save downloaded music to your device storage without being erased on app cache resets.',
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Dialog(
      backgroundColor: StudioSurfaceTheme.surface(context, isSolid: true),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24.0),
        side: BorderSide(
          color: StudioSurfaceTheme.subtleOutline(context, isSolid: true),
          width: 1.0,
        ),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480.0),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12.0),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Icon(
                      LucideIcons.folderLock,
                      color: cs.onPrimaryContainer,
                      size: 28.0,
                    ),
                  ),
                  const SizedBox(width: 16.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Storage Permission',
                          style: AppTypography.title(cs.onSurface),
                        ),
                        const SizedBox(height: 2.0),
                        Text(
                          featureName,
                          style: AppTypography.badge(color: cs.primary, fontSize: 11.0),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20.0),
              Text(
                rationale,
                style: AppTypography.body(cs.onSurfaceVariant).copyWith(height: 1.45),
              ),
              const SizedBox(height: 16.0),
              Container(
                padding: const EdgeInsets.all(14.0),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16.0),
                  border: Border.all(
                    color: cs.outlineVariant.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.shieldCheck,
                      color: cs.tertiary,
                      size: 20.0,
                    ),
                    const SizedBox(width: 12.0),
                    Expanded(
                      child: Text(
                        'Your files remain safe in public storage even if app data is cleared.',
                        style: AppTypography.body(cs.onSurface).copyWith(fontSize: 12.0),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24.0),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  M3EButton(
                    label: const Text('Not Now'),
                    style: M3EButtonStyle.text,
                    onPressed: () {
                      AppHaptics.lightImpact();
                      Navigator.of(context).pop(false);
                    },
                  ),
                  const SizedBox(width: 12.0),
                  M3EButton(
                    label: const Text('Grant Access'),
                    style: M3EButtonStyle.filled,
                    onPressed: () async {
                      AppHaptics.mediumImpact();
                      Navigator.of(context).pop(true);
                      await StoragePermissionService.instance.requestManageExternalStoragePermission();
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
