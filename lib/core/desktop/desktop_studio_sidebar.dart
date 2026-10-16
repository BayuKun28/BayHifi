import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme/app_haptics.dart';
import '../../audio_engine/virtual_dsp_service.dart';
import '../../features/library/presentation/controllers/library_controller.dart';
import '../../features/navidrome/domain/subsonic_models.dart';
import 'desktop_shortcuts_dispatcher.dart';

/// State provider to track whether the desktop sidebar is collapsed (compact mode).
final desktopSidebarCollapsedProvider = StateProvider<bool>((ref) => false);

/// Studio Sidebar Navigation Rail for Desktop & Tablet layouts.
/// Solid matte obsidian aesthetic matching the new dockbar and taste-skill design mandate.
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
      const _NavDestination(
        icon: LucideIcons.house,
        label: 'Home',
      ),
      const _NavDestination(
        icon: LucideIcons.sliders,
        label: 'DSP Rack',
      ),
      const _NavDestination(
        icon: LucideIcons.library,
        label: 'Library',
      ),
      const _NavDestination(
        icon: LucideIcons.listMusic,
        label: 'Playlists',
      ),
      const _NavDestination(
        icon: LucideIcons.playSquare,
        label: 'YouTube',
      ),
      const _NavDestination(
        icon: LucideIcons.settings,
        label: 'Settings',
      ),
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOutCubic,
      clipBehavior: Clip.hardEdge,
      width: effectiveIsCompact ? 76 : 220,
      decoration: const BoxDecoration(
        color: Color(0xFF0D0E12),
        border: Border(
          right: BorderSide(
            color: Color(0xFF262936),
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
                              color: const Color(0xFF16181F),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFF262936),
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
                                  color: const Color(0xFF1E212B),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF262936),
                                    width: 0.8,
                                  ),
                                ),
                                child: const Icon(
                                  LucideIcons.panelLeftOpen,
                                  size: 14,
                                  color: Color(0xFFA1B2A7),
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
                              color: const Color(0xFF16181F),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: const Color(0xFF262936),
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
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Baydev HiFi',
                                  style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.2,
                                    color: Colors.white,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'STUDIO MASTER',
                                  style: TextStyle(
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.1,
                                    color: Color(0xFF10B981),
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
                                  color: const Color(0xFF1E212B),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFF262936),
                                    width: 0.8,
                                  ),
                                ),
                                child: const Icon(
                                  LucideIcons.panelLeftClose,
                                  size: 14,
                                  color: Color(0xFFA1B2A7),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),

              const Divider(height: 1, color: Color(0xFF262936)),
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
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          curve: Curves.easeOutCubic,
                          height: 44,
                          padding: EdgeInsets.symmetric(horizontal: effectiveIsCompact ? 14 : 14),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF222532)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: isSelected
                                ? Border.all(
                                    color: const Color(0xFF383D50),
                                    width: 0.8,
                                  )
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment:
                                effectiveIsCompact ? MainAxisAlignment.center : MainAxisAlignment.start,
                            children: [
                              Icon(
                                item.icon,
                                color: isSelected
                                    ? Colors.white
                                    : const Color(0xFF8A9A90),
                                size: 18,
                              ),
                              if (!effectiveIsCompact) ...[
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFFA1B2A7),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (index == 1 && isDspActive)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF1E212B),
                                      borderRadius: BorderRadius.circular(5),
                                      border: Border.all(
                                        color: const Color(0xFF262936),
                                        width: 0.8,
                                      ),
                                    ),
                                    child: const Text(
                                      'ACTIVE',
                                      style: TextStyle(
                                        fontSize: 8,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF10B981),
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
                      padding: const EdgeInsets.symmetric(vertical: 2.5),
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
              const Divider(height: 1, color: Color(0xFF262936)),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: effectiveIsCompact ? 8 : 14,
                  vertical: 12,
                ),
                child: Column(
                  children: [
                    if (!effectiveIsCompact)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isNavidromeConnected
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                isNavidromeConnected ? 'Navidrome Sync' : 'Local Storage',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Color(0xFF8A9A90),
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    InkWell(
                      onTap: () {
                        AppHaptics.selectionClick();
                        showDesktopShortcutsCheatsheet(context);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0xFF16181F),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: const Color(0xFF262936),
                            width: 0.8,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: effectiveIsCompact
                            ? const Tooltip(
                                message: 'Studio Shortcuts',
                                child: Icon(
                                  LucideIcons.keyboard,
                                  color: Color(0xFFA1B2A7),
                                  size: 16,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.keyboard,
                                    color: Color(0xFFA1B2A7),
                                    size: 15,
                                  ),
                                  SizedBox(width: 8),
                                  Text(
                                    'Shortcuts',
                                    style: TextStyle(
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFFA1B2A7),
                                    ),
                                  ),
                                ],
                              ),
                      ),
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
  final IconData icon;
  final String label;

  const _NavDestination({
    required this.icon,
    required this.label,
  });
}
