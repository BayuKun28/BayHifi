import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../app/theme/app_colors.dart';
import '../app/theme/color_schemes.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/library/presentation/unified_library_screen.dart';
import '../features/player/presentation/now_playing_screen.dart';
import '../features/pro_q_studio/presentation/pro_q_studio_screen.dart';

class BaydevHiFiApp extends ConsumerStatefulWidget {
  const BaydevHiFiApp({super.key});

  @override
  ConsumerState<BaydevHiFiApp> createState() => _BaydevHiFiAppState();
}

class _BaydevHiFiAppState extends ConsumerState<BaydevHiFiApp> {
  int _selectedNavIndex = 0; // Default index 0: Dashboard saat aplikasi pertama dibuka

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baydev HiFi',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkStudioTheme,
      home: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 650;

          final pages = [
            DashboardScreen(
              onNavigateToPlayer: () => setState(() => _selectedNavIndex = 1),
              onNavigateToLibrary: () => setState(() => _selectedNavIndex = 3),
              onNavigateToDsp: () => setState(() => _selectedNavIndex = 2),
            ),
            NowPlayingScreen(
              onOpenProQStudio: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProQStudioScreen()),
                );
              },
            ),
            _buildPlaceholderScreen('DSP MASTERING RACK', 'Tube Exciter, Compressor, Binaural & Limiter'),
            const UnifiedLibraryScreen(),
            _buildPlaceholderScreen('SETTINGS', 'Theme Colors, Waveforms, Album Art & DAC'),
          ];

          if (isMobile) {
            return Scaffold(
              backgroundColor: AppColors.background,
              body: IndexedStack(
                index: _selectedNavIndex,
                children: pages,
              ),
              bottomNavigationBar: NavigationBar(
                backgroundColor: AppColors.surface,
                indicatorColor: AppColors.amberEq.withValues(alpha: 0.2),
                selectedIndex: _selectedNavIndex,
                onDestinationSelected: (idx) => setState(() => _selectedNavIndex = idx),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined),
                    selectedIcon: Icon(Icons.dashboard, color: AppColors.amberEq),
                    label: 'Dashboard',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.music_note_outlined),
                    selectedIcon: Icon(Icons.music_note, color: AppColors.amberEq),
                    label: 'Player',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.tune_outlined),
                    selectedIcon: Icon(Icons.tune, color: AppColors.amberEq),
                    label: 'DSP Rack',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.library_music_outlined),
                    selectedIcon: Icon(Icons.library_music, color: AppColors.amberEq),
                    label: 'Library',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.settings_outlined),
                    selectedIcon: Icon(Icons.settings, color: AppColors.amberEq),
                    label: 'Settings',
                  ),
                ],
              ),
            );
          }

          // Desktop / Tablet / Landscape View with Studio NavigationRail
          final isShortHeight = constraints.maxHeight < 550;

          return Scaffold(
            backgroundColor: AppColors.background,
            body: Row(
              children: [
                NavigationRail(
                  backgroundColor: AppColors.surface,
                  selectedIndex: _selectedNavIndex,
                  onDestinationSelected: (idx) => setState(() => _selectedNavIndex = idx),
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
                        color: AppColors.amberEq.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.amberEq.withValues(alpha: 0.5)),
                      ),
                      child: const Icon(
                        Icons.graphic_eq,
                        color: AppColors.amberEq,
                        size: 20,
                      ),
                    ),
                  ),
                  destinations: const [
                    NavigationRailDestination(
                      icon: Icon(Icons.dashboard_outlined),
                      selectedIcon: Icon(Icons.dashboard, color: AppColors.amberEq),
                      label: Text('Dashboard', style: TextStyle(fontSize: 11)),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.music_note_outlined),
                      selectedIcon: Icon(Icons.music_note, color: AppColors.amberEq),
                      label: Text('Player', style: TextStyle(fontSize: 11)),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.tune_outlined),
                      selectedIcon: Icon(Icons.tune, color: AppColors.amberEq),
                      label: Text('DSP Rack', style: TextStyle(fontSize: 11)),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.library_music_outlined),
                      selectedIcon: Icon(Icons.library_music, color: AppColors.amberEq),
                      label: Text('Library', style: TextStyle(fontSize: 11)),
                    ),
                    NavigationRailDestination(
                      icon: Icon(Icons.settings_outlined),
                      selectedIcon: Icon(Icons.settings, color: AppColors.amberEq),
                      label: Text('Settings', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
                const VerticalDivider(width: 1, thickness: 1, color: AppColors.surfaceBorder),
                Expanded(
                  child: IndexedStack(
                    index: _selectedNavIndex,
                    children: pages,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaceholderScreen(String title, String subtitle) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: AppColors.amberEq,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
