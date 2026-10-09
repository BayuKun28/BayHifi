import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../app/theme/app_haptics.dart';
import '../../audio_engine/virtual_dsp_service.dart';
import '../../features/library/presentation/controllers/library_controller.dart';
import '../../features/navidrome/domain/subsonic_models.dart';
import 'desktop_shortcuts_dispatcher.dart';

/// State provider to track whether the desktop sidebar is collapsed (compact mode).
final desktopSidebarCollapsedProvider = StateProvider<bool>((ref) => false);

/// Studio Sidebar Navigation Rail khusus tampilan Desktop (layar lebar $\ge 960$px).
class DesktopStudioSidebar extends ConsumerWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool? isCompact;
  final VoidCallback? onToggleCompact;

  const DesktopStudioSidebar({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.isCompact,
    this.onToggleCompact,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isStateCollapsed = ref.watch(desktopSidebarCollapsedProvider);
    final effectiveIsCompact = isCompact ?? isStateCollapsed;
    final effectiveOnToggle = onToggleCompact ??
        () {
          ref.read(desktopSidebarCollapsedProvider.notifier).update((state) => !state);
        };

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

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOutCubic,
      clipBehavior: Clip.hardEdge,
      width: effectiveIsCompact ? 76 : 220,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          right: BorderSide(
            color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
            width: 1.0,
          ),
        ),
      ),
      child: OverflowBox(
        minWidth: 0,
        maxWidth: 220,
        alignment: Alignment.topLeft,
        child: SizedBox(
          width: effectiveIsCompact ? 76 : 220,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          // ─── Header: App Branding & Expand/Collapse Toggle ──────
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            child: effectiveIsCompact
                ? Column(
                    mainAxisSize: MainAxisSize.min,
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
                      const SizedBox(height: 10),
                      Tooltip(
                        message: 'Expand sidebar (Ctrl+B)',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            AppHaptics.selectionClick();
                            effectiveOnToggle();
                          },
                          child: Container(
                            width: 38,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
                                width: 0.8,
                              ),
                            ),
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedArrowRight01,
                              size: 15,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: theme.colorScheme.primary.withValues(alpha: 0.25),
                            width: 1.0,
                          ),
                        ),
                        padding: const EdgeInsets.all(6),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.asset(
                            'assets/images/baydev_logo.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Baydev HiFi',
                              style: TextStyle(
                                fontSize: 14.5,
                                fontWeight: FontWeight.bold,
                                letterSpacing: -0.2,
                                color: theme.colorScheme.onSurface,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              'STUDIO MASTER',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Tooltip(
                        message: 'Collapse sidebar (Ctrl+B)',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: () {
                            AppHaptics.selectionClick();
                            effectiveOnToggle();
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
                                width: 0.8,
                              ),
                            ),
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedArrowLeft01,
                              size: 15,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),

          Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25)),
          const SizedBox(height: 10),

          // ─── Navigation Items ──────────────────────────────
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: effectiveIsCompact ? 8 : 12),
              itemCount: destinations.length,
              itemBuilder: (context, index) {
                final item = destinations[index];
                final isSelected = selectedIndex == index;

                final destinationTile = Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      AppHaptics.selectionClick();
                      onDestinationSelected(index);
                    },
                    child: Container(
                      height: 44,
                      padding: EdgeInsets.symmetric(horizontal: effectiveIsCompact ? 14 : 16),
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
                            effectiveIsCompact ? MainAxisAlignment.center : MainAxisAlignment.start,
                        children: [
                          HugeIcon(
                            icon: item.icon,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface.withValues(alpha: 0.65),
                            size: 20,
                          ),
                          if (!effectiveIsCompact) ...[
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
                );

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3.0),
                  child: effectiveIsCompact
                      ? Tooltip(
                          message: item.label,
                          preferBelow: false,
                          child: destinationTile,
                        )
                      : destinationTile,
                );
              },
            ),
          ),

          // ─── Footer: Telemetry & Shortcuts ──────────────────
          Divider(height: 1, color: theme.colorScheme.outlineVariant.withValues(alpha: 0.25)),
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: effectiveIsCompact ? 8 : 16,
              vertical: 12,
            ),
            child: Column(
              children: [
                if (!effectiveIsCompact)
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
                  label: effectiveIsCompact
                      ? Tooltip(
                          message: 'Studio Shortcuts',
                          child: HugeIcon(
                            icon: HugeIcons.strokeRoundedKeyboard,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            size: 18,
                          ),
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
    ),
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
