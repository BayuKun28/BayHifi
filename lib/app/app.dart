import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../app/theme/theme_mode_controller.dart';
import '../core/desktop/desktop_bottom_master_transport_deck.dart';
import '../core/desktop/desktop_drag_drop_zone.dart';
import '../core/desktop/desktop_shortcuts_dispatcher.dart';
import '../core/desktop/desktop_studio_sidebar.dart';
import '../core/widgets/floating_rounded_dock.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/dsp_rack/presentation/dsp_rack_screen.dart';
import '../features/library/presentation/playlists_screen.dart';
import '../features/library/presentation/unified_library_screen.dart';
import '../features/player/presentation/controllers/player_controller.dart';
import '../features/player/presentation/controllers/player_expansion_controller.dart';
import '../features/player/presentation/widgets/namida_expandable_miniplayer.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/youtube_music/presentation/youtube_discovery_screen.dart';

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

    final isDark = themeState.themeMode == AppThemeMode.dark ||
        (themeState.themeMode == AppThemeMode.system &&
            WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);
    final themeData = AppThemeBuilder.buildTheme(themeState.currentPalette, isDark: isDark);
    final m3eThemeData = AppThemeBuilder.buildM3ETheme(themeState.currentPalette, isDark: isDark);

    return Theme(
      data: themeData,
      child: M3EMaterialApp(
        title: 'Baydev HiFi',
        debugShowCheckedModeBanner: false,
        drawUnderSystemBars: true,
        data: m3eThemeData,
        localizationsDelegates: const [
          DefaultMaterialLocalizations.delegate,
          DefaultWidgetsLocalizations.delegate,
        ],
        home: Theme(
          data: themeData,
          child: DesktopShortcutsDispatcher(
            onSearchRequested: () => setState(() => _selectedNavIndex = 2),
            child: DesktopDragDropZone(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final theme = Theme.of(context);
                  final isDesktop = constraints.maxWidth >= 960;
                  final isMobile = constraints.maxWidth < 650;

                  // 6 Studio Pages
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
                    const YouTubeDiscoveryScreen(),
                    const SettingsScreen(),
                  ];

                  // Pastikan indeks navigasi dalam batas array pages
                  final safeIndex = _selectedNavIndex.clamp(0, pages.length - 1);

                  // ─── 1. MOBILE PHONE LAYOUT (< 650px) ─────────────────────────
                  if (isMobile) {
                    final mobileNavIndex = safeIndex > 4 ? 4 : (safeIndex == 4 ? 3 : safeIndex);
                    return Scaffold(
                      backgroundColor: theme.scaffoldBackgroundColor,
                      resizeToAvoidBottomInset: false,
                      body: Stack(
                        children: [
                          // Layer 1: Page Content
                          Padding(
                            padding: const EdgeInsets.only(bottom: 80.0),
                            child: IndexedStack(
                              index: safeIndex,
                              children: pages,
                            ),
                          ),

                          // Layer 2: Floating Rounded Dock
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: FloatingRoundedDock(
                              selectedIndex: mobileNavIndex,
                              onItemSelected: (idx) {
                                // Map 5 mobile items: 0->0, 1->1, 2->2, 3->3, 4->5 (Settings)
                                final mapped = idx == 4 ? 5 : idx;
                                setState(() => _selectedNavIndex = mapped);
                              },
                            ),
                          ),

                          // Layer 3: Namida Omnipresent Expandable MiniPlayer
                          NamidaExpandableMiniPlayer(
                            collapsedBottomOffset: 78.0,
                            isLibraryTab: safeIndex == 2,
                          ),
                        ],
                      ),
                    );
                  }

                  // ─── 2. TABLET / COMPACT LANDSCAPE LAYOUT (650px - 959px) ──────
                  if (!isDesktop) {
                    return Scaffold(
                      backgroundColor: theme.scaffoldBackgroundColor,
                      body: Stack(
                        children: [
                          Row(
                            children: [
                              DesktopStudioSidebar(
                                isCompact: true,
                                selectedIndex: safeIndex,
                                onDestinationSelected: (idx) =>
                                    setState(() => _selectedNavIndex = idx),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.only(bottom: 74.0),
                                  child: IndexedStack(
                                    index: safeIndex,
                                    children: pages,
                                  ),
                                ),
                              ),
                            ],
                          ),

                          // Namida Expandable MiniPlayer on Tablet
                          NamidaExpandableMiniPlayer(
                            collapsedBottomOffset: 12.0,
                            isLibraryTab: safeIndex == 2,
                          ),
                        ],
                      ),
                    );
                  }

                  // ─── 3. DESKTOP STUDIO MASTER LAYOUT (>= 960px) ───────────────
                  return Scaffold(
                    backgroundColor: theme.scaffoldBackgroundColor,
                    body: Stack(
                      children: [
                        Row(
                          children: [
                            DesktopStudioSidebar(
                              isCompact: false,
                              selectedIndex: safeIndex,
                              onDestinationSelected: (idx) =>
                                  setState(() => _selectedNavIndex = idx),
                            ),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: 84.0),
                                child: IndexedStack(
                                  index: safeIndex,
                                  children: pages,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Layer 2: Persistent Studio Master Transport Deck at bottom
                        const Positioned(
                          left: 0,
                          right: 0,
                          bottom: 0,
                          child: DesktopBottomMasterTransportDeck(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
