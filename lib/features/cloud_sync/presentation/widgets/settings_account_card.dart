import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../../../app/theme/app_haptics.dart';
import '../controllers/cloud_auth_controller.dart';
import 'cloud_auth_dialog.dart';
import 'user_profile_sheet.dart';

/// Kartu akun Cloud di bagian atas layar Settings
class SettingsAccountCard extends ConsumerWidget {
  const SettingsAccountCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(cloudAuthControllerProvider);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isAuthenticated = authState.isAuthenticated;
    final user = authState.user;

    if (!isAuthenticated) {
      // Guest / Offline Mode Card
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1.0,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: HugeIcon(
                    icon: HugeIcons.strokeRoundedCloudUpload,
                    size: 22,
                    color: primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BAYHIFI CLOUD ACCOUNT',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.8,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Offline Mode (Local Storage Only)',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Sign in to synchronize your listening analytics, Studio Wrapped, and AutoEQ headphone profiles across all your devices.',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: M3EButton.filled(
                label: const Text('CONNECT & SIGN IN'),
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedLogin01,
                  size: 18,
                  color: theme.colorScheme.onPrimary,
                ),
                onPressed: () {
                  AppHaptics.selectionClick();
                  CloudAuthDialog.show(context);
                },
              ),
            ),
          ],
        ),
      );
    }

    // Authenticated Card
    final username = user?.username ?? 'Audiophile';
    final email = user?.email;
    final lastSynced = authState.lastSyncedAt;
    final syncText = lastSynced != null
        ? 'Last synced: ${DateFormat('HH:mm, MMM d').format(lastSynced)}'
        : 'Pending initial sync';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: primary.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  username.isNotEmpty ? username[0].toUpperCase() : 'U',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (email != null && email.isNotEmpty)
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    Text(
                      syncText,
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: M3EButton.tonal(
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedCloudSync,
                    size: 18,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                  label: const Text('SYNC NOW'),
                  onPressed: () async {
                    AppHaptics.selectionClick();
                    await ref.read(cloudAuthControllerProvider.notifier).syncNow();
                    AppHaptics.mediumImpact();
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: M3EButton.outlined(
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedUser,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                  label: const Text('DETAILS'),
                  onPressed: () {
                    AppHaptics.selectionClick();
                    UserProfileSheet.show(context);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
