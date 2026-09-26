import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

/// Studio Floating Rounded Dock Navigation Bar
/// Clean, ergonomic, anti-AI-slop floating capsule dock with HugeIcons.
class FloatingRoundedDock extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;

  const FloatingRoundedDock({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final items = [
      _DockItemData(
        title: 'Dashboard',
        icon: HugeIcons.strokeRoundedDashboardSquare01,
        selectedIcon: HugeIcons.strokeRoundedDashboardSquare01,
      ),
      _DockItemData(
        title: 'DSP Rack',
        icon: HugeIcons.strokeRoundedSlidersVertical,
        selectedIcon: HugeIcons.strokeRoundedSlidersVertical,
      ),
      _DockItemData(
        title: 'Library',
        icon: HugeIcons.strokeRoundedMusicNote01,
        selectedIcon: HugeIcons.strokeRoundedMusicNote01,
      ),
      _DockItemData(
        title: 'Playlists',
        icon: HugeIcons.strokeRoundedPlayList,
        selectedIcon: HugeIcons.strokeRoundedPlayList,
      ),
      _DockItemData(
        title: 'Settings',
        icon: HugeIcons.strokeRoundedSettings01,
        selectedIcon: HugeIcons.strokeRoundedSettings01,
      ),
    ];

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(4, 0, 4, 6),
        height: 66,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface.withValues(alpha: 0.94),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: theme.dividerColor.withValues(alpha: 0.6),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: List.generate(items.length, (index) {
                  final item = items[index];
                  final isSelected = selectedIndex == index;

                  return Expanded(
                    child: InkWell(
                      onTap: () {
                        if (!isSelected) {
                          HapticFeedback.selectionClick();
                          onItemSelected(index);
                        }
                      },
                      borderRadius: BorderRadius.circular(20),
                      splashColor: primary.withValues(alpha: 0.1),
                      highlightColor: Colors.transparent,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOutCubic,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? primary.withValues(alpha: 0.16)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                          border: isSelected
                              ? Border.all(
                                  color: primary.withValues(alpha: 0.4),
                                  width: 1.0,
                                )
                              : Border.all(color: Colors.transparent),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            HugeIcon(
                              icon: isSelected ? item.selectedIcon : item.icon,
                              color: isSelected
                                  ? primary
                                  : theme.colorScheme.onSurface.withValues(alpha: 0.55),
                              size: 20,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              item.title,
                              style: TextStyle(
                                fontSize: 10.5,
                                fontWeight: isSelected
                                    ? FontWeight.w800
                                    : FontWeight.w500,
                                color: isSelected
                                    ? primary
                                    : theme.colorScheme.onSurface.withValues(alpha: 0.65),
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
        ),
      ),
    );
  }
}

class _DockItemData {
  final String title;
  final dynamic icon;
  final dynamic selectedIcon;

  _DockItemData({
    required this.title,
    required this.icon,
    required this.selectedIcon,
  });
}
