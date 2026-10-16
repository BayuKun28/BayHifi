import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../app/theme/app_haptics.dart';
import '../../app/theme/studio_surface_theme.dart';

/// Studio Floating Rounded Dock Navigation Bar
/// Clean, ergonomic, anti-AI-slop floating capsule dock with LucideIcons and solid matte styling.
class FloatingRoundedDock extends ConsumerWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const FloatingRoundedDock({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isSolid = ref.isSolidStyle;

    final items = [
      _DockItemData(
        title: 'Home',
        icon: LucideIcons.house,
      ),
      _DockItemData(
        title: 'DSP Rack',
        icon: LucideIcons.sliders,
      ),
      _DockItemData(
        title: 'Library',
        icon: LucideIcons.library,
      ),
      _DockItemData(
        title: 'Playlists',
        icon: LucideIcons.listMusic,
      ),
      _DockItemData(
        title: 'Settings',
        icon: LucideIcons.settings,
      ),
    ];

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(8, 0, 8, 6),
        height: 64,
        decoration: BoxDecoration(
          color: isSolid
              ? const Color(0xFF12141A)
              : StudioSurfaceTheme.surfaceContainer(context, isSolid: true),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF262936),
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (index) {
              final item = items[index];
              final isSelected = selectedIndex == index;

              return Expanded(
                child: InkWell(
                  onTap: () {
                    if (!isSelected) {
                      AppHaptics.selectionClick();
                      onItemSelected(index);
                    }
                  },
                  borderRadius: BorderRadius.circular(18),
                  splashColor: Colors.white.withValues(alpha: 0.05),
                  highlightColor: Colors.transparent,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFF222532)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(18),
                      border: isSelected
                          ? Border.all(
                              color: const Color(0xFF383D50),
                              width: 0.8,
                            )
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          item.icon,
                          color: isSelected
                              ? Colors.white
                              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                          size: 19,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.title,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                            letterSpacing: 0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _DockItemData {
  final String title;
  final IconData icon;

  _DockItemData({
    required this.title,
    required this.icon,
  });
}
