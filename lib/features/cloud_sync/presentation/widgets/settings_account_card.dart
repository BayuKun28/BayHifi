import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
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
    final isDark = theme.brightness == Brightness.dark;
    final isAuthenticated = authState.isAuthenticated;
    final user = authState.user;

    if (!isAuthenticated) {
      // Guest / Offline Mode Card
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF16181F) : theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? const Color(0xFF262936) : theme.colorScheme.outlineVariant,
            width: 0.8,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF20232E) : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? const Color(0xFF2E3242) : theme.colorScheme.outlineVariant,
                      width: 0.8,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Icon(
                    LucideIcons.cloudUpload,
                    size: 18,
                    color: isDark ? Colors.white : theme.colorScheme.onSurface,
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
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: isDark ? Colors.white : theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Offline Mode (Local Storage Only)',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Sign in to synchronize your listening analytics, Studio Wrapped, and AutoEQ headphone profiles across all your devices.',
              style: TextStyle(
                fontSize: 11.5,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.75),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () {
                  AppHaptics.selectionClick();
                  CloudAuthDialog.show(context);
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF252834) : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? const Color(0xFF383D50) : theme.colorScheme.outline,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.logIn,
                        size: 14,
                        color: isDark ? Colors.white : theme.colorScheme.onSurface,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'CONNECT & SIGN IN',
                        style: TextStyle(
                          color: isDark ? Colors.white : theme.colorScheme.onSurface,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
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
        color: isDark ? const Color(0xFF16181F) : theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF262936) : theme.colorScheme.outlineVariant,
          width: 0.8,
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
                  color: isDark ? const Color(0xFF252834) : theme.colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isDark ? const Color(0xFF383D50) : theme.colorScheme.outline,
                    width: 0.8,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  username.isNotEmpty ? username[0].toUpperCase() : 'U',
                  style: TextStyle(
                    color: isDark ? Colors.white : theme.colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
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
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : theme.colorScheme.onSurface,
                      ),
                    ),
                    if (email != null && email.isNotEmpty)
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                        ),
                      ),
                    Text(
                      syncText,
                      style: TextStyle(
                        fontSize: 10.5,
                        color: isDark ? const Color(0xFF94A3B8) : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
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
                child: InkWell(
                  onTap: authState.isSyncing
                      ? null
                      : () async {
                          AppHaptics.selectionClick();
                          final success = await ref.read(cloudAuthControllerProvider.notifier).syncNow();
                          if (!context.mounted) return;
                          AppHaptics.mediumImpact();

                          final err = ref.read(cloudAuthControllerProvider).errorMessage ?? 'Unable to connect to sync server';
                          final messenger = ScaffoldMessenger.of(context);
                          messenger.hideCurrentSnackBar();
                          messenger.showSnackBar(
                            SnackBar(
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: success ? const Color(0xFF10B981) : theme.colorScheme.error,
                              duration: Duration(seconds: success ? 3 : 4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              content: Row(
                                children: [
                                  Icon(
                                    success ? LucideIcons.checkCircle2 : LucideIcons.alertCircle,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      success
                                          ? 'Studio Cloud sync completed. All profiles & telemetry updated.'
                                          : 'Sync failed: $err',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF252834) : theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? const Color(0xFF383D50) : theme.colorScheme.outline,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (authState.isSyncing)
                          SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: isDark ? Colors.white : theme.colorScheme.onSurface,
                            ),
                          )
                        else
                          Icon(
                            LucideIcons.refreshCw,
                            size: 14,
                            color: isDark ? Colors.white : theme.colorScheme.onSurface,
                          ),
                        const SizedBox(width: 7),
                        Text(
                          authState.isSyncing ? 'SYNCING...' : 'SYNC NOW',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : theme.colorScheme.onSurface,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InkWell(
                  onTap: () {
                    AppHaptics.selectionClick();
                    UserProfileSheet.show(context);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 9),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E212B) : theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? const Color(0xFF262936) : theme.colorScheme.outlineVariant,
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.user,
                          size: 14,
                          color: isDark ? const Color(0xFF94A3B8) : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          'DETAILS',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF94A3B8) : theme.colorScheme.onSurfaceVariant,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
