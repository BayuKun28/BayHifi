import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../../../app/theme/app_haptics.dart';
import '../controllers/cloud_auth_controller.dart';
import 'change_password_dialog.dart';

/// Modal bottom sheet untuk melihat detail profil user & aksi sinkronisasi
class UserProfileSheet extends ConsumerWidget {
  const UserProfileSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const UserProfileSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(cloudAuthControllerProvider);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final user = authState.user;
    final username = user?.username ?? 'Audiophile';
    final email = user?.email;
    final serverUrl = authState.serverUrl;
    final lastSynced = authState.lastSyncedAt;

    final String lastSyncedText;
    if (lastSynced != null) {
      lastSyncedText = DateFormat('MMM dd, yyyy • HH:mm').format(lastSynced);
    } else {
      lastSyncedText = 'Not yet synced';
    }

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
            width: 1.0,
          ),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outline.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // User Profile Header
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: primary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  username.isNotEmpty ? username[0].toUpperCase() : 'U',
                  style: TextStyle(
                    color: theme.colorScheme.onPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    if (email != null && email.isNotEmpty)
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 13,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Cloud Connected',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Server Connection Card
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedServer,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'SERVER HOST',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  serverUrl,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const Divider(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Last Studio Sync:',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      lastSyncedText,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Change Password Button
          M3EButton.tonal(
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedLockKey,
              size: 18,
              color: theme.colorScheme.onSecondaryContainer,
            ),
            decoration: M3EButtonDecoration(
              foregroundColor: WidgetStateProperty.all(theme.colorScheme.onSecondaryContainer),
              textStyle: TextStyle(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
            label: Text(
              'CHANGE PASSWORD',
              style: TextStyle(
                color: theme.colorScheme.onSecondaryContainer,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
            onPressed: () {
              AppHaptics.selectionClick();
              Navigator.of(context).pop();
              ChangePasswordDialog.show(context);
            },
          ),
          const SizedBox(height: 12),

          // Actions Row
          Row(
            children: [
              Expanded(
                flex: 2,
                child: M3EButton.filled(
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedCloudSync,
                    size: 18,
                    color: theme.colorScheme.onPrimary,
                  ),
                  decoration: M3EButtonDecoration(
                    foregroundColor: WidgetStateProperty.all(theme.colorScheme.onPrimary),
                    textStyle: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                  label: Text(
                    'SYNC NOW',
                    style: TextStyle(
                      color: theme.colorScheme.onPrimary,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                  onPressed: () async {
                    AppHaptics.selectionClick();
                    await ref.read(cloudAuthControllerProvider.notifier).syncNow();
                    if (context.mounted) {
                      AppHaptics.mediumImpact();
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: M3EButton.outlined(
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedLogout01,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
                  decoration: M3EButtonDecoration(
                    foregroundColor: WidgetStateProperty.all(theme.colorScheme.error),
                    side: WidgetStateProperty.all(
                      BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
                    ),
                    textStyle: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                  label: Text(
                    'LOG OUT',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                  onPressed: () async {
                    AppHaptics.selectionClick();
                    await ref.read(cloudAuthControllerProvider.notifier).logout();
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
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
