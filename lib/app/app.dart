import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../app/theme/theme_mode_controller.dart';
import '../core/widgets/floating_rounded_dock.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/dsp_rack/presentation/dsp_rack_screen.dart';
import '../features/library/presentation/playlists_screen.dart';
import '../features/library/presentation/unified_library_screen.dart';
import '../features/player/presentation/controllers/player_controller.dart';
import '../features/player/presentation/controllers/player_expansion_controller.dart';
import '../features/player/presentation/widgets/namida_expandable_miniplayer.dart';
import '../features/settings/presentation/settings_screen.dart';

class BaydevHiFiApp extends ConsumerStatefulWidget {
  const BaydevHiFiApp({super.key});

  @override
  ConsumerState<BaydevHiFiApp> createState() => _BaydevHiFiAppState();
}

class _BaydevHiFiAppState extends ConsumerState<BaydevHiFiApp> {
  int _selectedNavIndex = 0; // Default: Dashboard (Index 0)

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final current = ref.read(playerControllerProvider).currentTrack;
      if (current != null) {
        ref.read(themeControllerProvider.notifier).updateDynamicPaletteFromTrack(current);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeControllerProvider);

    // Automatically update dynamic palette when current track changes
    ref.listen(playerControllerProvider.select((s) => s.currentTrack), (previous, current) {
      if (current != null) {
        ref.read(themeControllerProvider.notifier).updateDynamicPaletteFromTrack(current);
      }
    });

    return MaterialApp(
      title: 'Baydev HiFi',
      debugShowCheckedModeBanner: false,
      themeMode: themeState.themeMode.mode,
      theme: AppThemeBuilder.buildTheme(themeState.currentPalette, isDark: false),
      darkTheme: AppThemeBuilder.buildTheme(themeState.currentPalette, isDark: true),
      home: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 650;
          final theme = Theme.of(context);

          // 5 Main Studio Tabs
          final pages = [
            DashboardScreen(
              onNavigateToPlayer: () =>
                  ref.read(playerExpansionProvider.notifier).expand(),
              onNavigateToLibrary: () => setState(() => _selectedNavIndex = 2),
              onNavigateToDsp: () => setState(() => _selectedNavIndex = 1),
            ),
            const DspRackScreen(),
            const UnifiedLibraryScreen(),
            const PlaylistsScreen(),
            const SettingsScreen(),
          ];

          if (isMobile) {
            return Scaffold(
              backgroundColor: theme.scaffoldBackgroundColor,
              resizeToAvoidBottomInset: false,
              body: Stack(
                children: [
                  // Layer 1: Page Content
                  Padding(
                    padding: const EdgeInsets.only(bottom: 80.0),
                    child: IndexedStack(
                      index: _selectedNavIndex,
                      children: pages,
                    ),
                  ),

                  // Layer 2: Floating Rounded Dock
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: FloatingRoundedDock(
                      selectedIndex: _selectedNavIndex,
                      onItemSelected: (idx) =>
                          setState(() => _selectedNavIndex = idx),
                    ),
                  ),

                  // Layer 3: Namida Omnipresent Expandable MiniPlayer
                  NamidaExpandableMiniPlayer(
                    collapsedBottomOffset: 78.0,
                    isLibraryTab: _selectedNavIndex == 2,
                  ),
                ],
              ),
            );
          }

          // Desktop / Tablet / Landscape View with Studio NavigationRail
          final isShortHeight = constraints.maxHeight < 550;

          return Scaffold(
            backgroundColor: theme.scaffoldBackgroundColor,
            body: Stack(
              children: [
                Row(
                  children: [
                    NavigationRail(
                      backgroundColor: theme.colorScheme.surface,
                      selectedIndex: _selectedNavIndex,
                      onDestinationSelected: (idx) =>
                          setState(() => _selectedNavIndex = idx),
                      labelType: isShortHeight
                          ? NavigationRailLabelType.none
                          : NavigationRailLabelType.all,
                      leading: Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: isShortHeight ? 6.0 : 16.0,
                        ),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(alpha: 0.4),
                            ),
                          ),
                          child: Center(
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedAudioWaveform,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                      destinations: [
                        NavigationRailDestination(
                          icon: HugeIcon(
                            icon: HugeIcons.strokeRoundedDashboardSquare01,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            size: 22,
                          ),
                          selectedIcon: HugeIcon(
                            icon: HugeIcons.strokeRoundedDashboardSquare01,
                            color: theme.colorScheme.primary,
                            size: 22,
                          ),
                          label: const Text('Dashboard', style: TextStyle(fontSize: 11)),
                        ),
                        NavigationRailDestination(
                          icon: HugeIcon(
                            icon: HugeIcons.strokeRoundedSlidersVertical,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            size: 22,
                          ),
                          selectedIcon: HugeIcon(
                            icon: HugeIcons.strokeRoundedSlidersVertical,
                            color: theme.colorScheme.primary,
                            size: 22,
                          ),
                          label: const Text('DSP Rack', style: TextStyle(fontSize: 11)),
                        ),
                        NavigationRailDestination(
                          icon: HugeIcon(
                            icon: HugeIcons.strokeRoundedMusicNote01,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            size: 22,
                          ),
                          selectedIcon: HugeIcon(
                            icon: HugeIcons.strokeRoundedMusicNote01,
                            color: theme.colorScheme.primary,
                            size: 22,
                          ),
                          label: const Text('Library', style: TextStyle(fontSize: 11)),
                        ),
                        NavigationRailDestination(
                          icon: HugeIcon(
                            icon: HugeIcons.strokeRoundedPlayList,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            size: 22,
                          ),
                          selectedIcon: HugeIcon(
                            icon: HugeIcons.strokeRoundedPlayList,
                            color: theme.colorScheme.primary,
                            size: 22,
                          ),
                          label: const Text('Playlists', style: TextStyle(fontSize: 11)),
                        ),
                        NavigationRailDestination(
                          icon: HugeIcon(
                            icon: HugeIcons.strokeRoundedSettings01,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            size: 22,
                          ),
                          selectedIcon: HugeIcon(
                            icon: HugeIcons.strokeRoundedSettings01,
                            color: theme.colorScheme.primary,
                            size: 22,
                          ),
                          label: const Text('Settings', style: TextStyle(fontSize: 11)),
                        ),
                      ],
                    ),
                    VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: theme.dividerColor,
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 74.0),
                        child: IndexedStack(
                          index: _selectedNavIndex,
                          children: pages,
                        ),
                      ),
                    ),
                  ],
                ),

                // Namida Expandable MiniPlayer on Desktop/Tablet
                NamidaExpandableMiniPlayer(
                  collapsedBottomOffset: 12.0,
                  isLibraryTab: _selectedNavIndex == 2,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

