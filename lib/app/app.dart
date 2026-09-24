import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/theme/theme_mode_controller.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/library/presentation/unified_library_screen.dart';
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
  Widget build(BuildContext context) {
    final themeState = ref.watch(themeControllerProvider);

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

          // 4 Tab Utama (Tanpa Tab Khusus Player, sesuai arsitektur Namida)
          final pages = [
            DashboardScreen(
              onNavigateToPlayer: () =>
                  ref.read(playerExpansionProvider.notifier).expand(),
              onNavigateToLibrary: () => setState(() => _selectedNavIndex = 2),
              onNavigateToDsp: () => setState(() => _selectedNavIndex = 1),
            ),
            _buildPlaceholderScreen(
              'DSP MASTERING RACK',
              'Tube Exciter, Dynamic Compressor, Binaural Crossfeed & Limiter',
              theme,
            ),
            const UnifiedLibraryScreen(),
            const SettingsScreen(),
          ];

          if (isMobile) {
            return Stack(
              children: [
                // Layer 1: Scaffold Utama dengan NavigationBar
                Scaffold(
                  backgroundColor: theme.scaffoldBackgroundColor,
                  body: Padding(
                    padding: const EdgeInsets.only(bottom: 74.0),
                    child: IndexedStack(
                      index: _selectedNavIndex,
                      children: pages,
                    ),
                  ),
                  bottomNavigationBar: NavigationBar(
                    backgroundColor: theme.colorScheme.surface,
                    selectedIndex: _selectedNavIndex,
                    onDestinationSelected: (idx) =>
                        setState(() => _selectedNavIndex = idx),
                    destinations: const [
                      NavigationDestination(
                        icon: Icon(Icons.dashboard_outlined),
                        selectedIcon: Icon(Icons.dashboard_rounded),
                        label: 'Dashboard',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.tune_outlined),
                        selectedIcon: Icon(Icons.tune_rounded),
                        label: 'DSP Rack',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.library_music_outlined),
                        selectedIcon: Icon(Icons.library_music_rounded),
                        label: 'Library',
                      ),
                      NavigationDestination(
                        icon: Icon(Icons.settings_outlined),
                        selectedIcon: Icon(Icons.settings_rounded),
                        label: 'Settings',
                      ),
                    ],
                  ),
                ),

                // Layer 2: Namida Omnipresent Expandable MiniPlayer (menutupi seluruh layar saat di-expand)
                const NamidaExpandableMiniPlayer(
                  collapsedBottomOffset: 88.0,
                ),
              ],
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
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Icon(
                            Icons.graphic_eq,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                        ),
                      ),
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.dashboard_outlined),
                          selectedIcon: Icon(Icons.dashboard_rounded),
                          label: Text('Dashboard', style: TextStyle(fontSize: 11)),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.tune_outlined),
                          selectedIcon: Icon(Icons.tune_rounded),
                          label: Text('DSP Rack', style: TextStyle(fontSize: 11)),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.library_music_outlined),
                          selectedIcon: Icon(Icons.library_music_rounded),
                          label: Text('Library', style: TextStyle(fontSize: 11)),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.settings_outlined),
                          selectedIcon: Icon(Icons.settings_rounded),
                          label: Text('Settings', style: TextStyle(fontSize: 11)),
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
                const NamidaExpandableMiniPlayer(
                  collapsedBottomOffset: 12.0,
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaceholderScreen(
    String title,
    String subtitle,
    ThemeData theme,
  ) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}
