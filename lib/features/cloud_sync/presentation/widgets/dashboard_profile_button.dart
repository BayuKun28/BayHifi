import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_haptics.dart';
import '../controllers/cloud_auth_controller.dart';
import 'cloud_auth_dialog.dart';
import 'user_profile_sheet.dart';

/// Tombol profil pengguna di pojok kiri atas Dashboard
class DashboardProfileButton extends ConsumerWidget {
  const DashboardProfileButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(cloudAuthControllerProvider);
    final theme = Theme.of(context);
    final isAuthenticated = authState.isAuthenticated;
    final username = authState.user?.username ?? 'Guest';

    return GestureDetector(
      onTap: () {
        AppHaptics.selectionClick();
        if (isAuthenticated) {
          UserProfileSheet.show(context);
        } else {
          CloudAuthDialog.show(context);
        }
      },
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: isAuthenticated
                ? theme.colorScheme.primary.withValues(alpha: 0.4)
                : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar Icon or Initial
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: isAuthenticated
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHigh,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: isAuthenticated
                  ? Text(
                      username.isNotEmpty ? username[0].toUpperCase() : 'U',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    )
                  : Icon(
                      LucideIcons.user,
                      size: 13,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
            ),
            const SizedBox(width: 6),
            // Username or Guest Label
            Text(
              isAuthenticated ? username : 'Guest',
              style: TextStyle(
                color: theme.colorScheme.onSurface,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(width: 5),
            // Status Dot
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: isAuthenticated ? const Color(0xFF10B981) : theme.colorScheme.outline,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
