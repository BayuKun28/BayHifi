import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../audio_engine/virtual_dsp_service.dart';
import '../../features/library/presentation/controllers/library_controller.dart';
import '../../features/navidrome/domain/subsonic_models.dart';
import 'desktop_shortcuts_dispatcher.dart';

/// Studio Sidebar Navigation Rail khusus tampilan Desktop (layar lebar $\ge 960$px).
class DesktopStudioSidebar extends ConsumerWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool isCompact;

  const DesktopStudioSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final libraryState = ref.watch(unifiedLibraryProvider);
    final isNavidromeConnected =
        libraryState.navidromeConnectionStatus == NavidromeConnectionStatus.connected;
    final dspState = ref.watch(virtualDspServiceProvider);
    final isDspActive = dspState.eqEnabled || dspState.bassBoostEnabled || dspState.compressorEnabled;

    final destinations = [
      _NavDestination(
        icon: HugeIcons.strokeRoundedDashboardSquare01,
        label: 'Dashboard',
      ),
      _NavDestination(
        icon: HugeIcons.strokeRoundedSlidersVertical,
        label: 'DSP Rack',
      ),
      _NavDestination(
        icon: HugeIcons.strokeRoundedMusicNote01,
        label: 'Library',
      ),
      _NavDestination(
        icon: HugeIcons.strokeRoundedPlayList,
        label: 'Playlists',
      ),
      _NavDestination(
        icon: HugeIcons.strokeRoundedYoutube,
        label: 'YouTube',
      ),
      _NavDestination(
        icon: HugeIcons.strokeRoundedSettings01,
        label: 'Settings',
      ),
    ];

    return Container(
      width: isCompact ? 76 : 220,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.6),
            width: 1.0,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── Header: App Branding ──────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 16 : 20,
              vertical: 20,
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.25),
                      width: 1.0,
                    ),
                  ),
                  padding: const EdgeInsets.all(7),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/images/baydev_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                if (!isCompact) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Baydev HiFi',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.2,
                            color: theme.colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'STUDIO MASTER',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.4)),
          const SizedBox(height: 12),

          // ─── Navigation Items ──────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 8 : 12),
              itemCount: destinations.length,
              itemBuilder: (context, index) {
                final item = destinations[index];
                final isSelected = selectedIndex == index;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => onDestinationSelected(index),
                      child: Container(
                        height: 44,
                        padding: EdgeInsets.symmetric(horizontal: isCompact ? 14 : 16),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? theme.colorScheme.primary.withValues(alpha: 0.14)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(12),
                          border: isSelected
                              ? Border.all(
                                  color: theme.colorScheme.primary.withValues(alpha: 0.25),
                                  width: 1.0,
                                )
                              : null,
                        ),
                        child: Row(
                          mainAxisAlignment:
                              isCompact ? MainAxisAlignment.center : MainAxisAlignment.start,
                          children: [
                            HugeIcon(
                              icon: item.icon,
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.onSurface.withValues(alpha: 0.65),
                              size: 20,
                            ),
                            if (!isCompact) ...[
                              const SizedBox(width: 14),
                              Expanded(
                                child: Text(
                                  item.label,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                    color: isSelected
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurface.withValues(alpha: 0.85),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (index == 1 && isDspActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.tertiary.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'ACTIVE',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w800,
                                      color: theme.colorScheme.tertiary,
                                    ),
                                  ),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ─── Footer: Telemetry & Shortcuts ──────────────────
          Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.4)),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isCompact ? 8 : 16,
              vertical: 12,
            ),
            child: Column(
              children: [
                if (!isCompact)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isNavidromeConnected ? const Color(0xFF10B981) : Colors.grey,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isNavidromeConnected ? 'Navidrome Sync' : 'Local Storage',
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                M3EButton(
                  label: isCompact
                      ? HugeIcon(
                          icon: HugeIcons.strokeRoundedKeyboard,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                          size: 18,
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedKeyboard,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              size: 16,
                            ),
                            const SizedBox(width: 8),
                            const Text('Shortcuts', style: TextStyle(fontSize: 12)),
                          ],
                        ),
                  style: M3EButtonStyle.tonal,
                  onPressed: () => showDesktopShortcutsCheatsheet(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavDestination {
  final dynamic icon;
  final String label;

  const _NavDestination({
    required this.icon,
    required this.label,
  });
}
