import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/studio_surface_theme.dart';

/// Floating capsule action bar for multi-track batch operations in the library
class LibraryBatchActionsBar extends ConsumerWidget {
  final int selectedCount;
  final int totalCount;
  final VoidCallback onPlayNext;
  final VoidCallback onAddToQueue;
  final VoidCallback onAddToPlaylist;
  final VoidCallback onBatchEditTags;
  final VoidCallback onSelectAll;
  final VoidCallback onDeselectAll;
  final VoidCallback onClose;

  const LibraryBatchActionsBar({
    super.key,
    required this.selectedCount,
    required this.totalCount,
    required this.onPlayNext,
    required this.onAddToQueue,
    required this.onAddToPlaylist,
    required this.onBatchEditTags,
    required this.onSelectAll,
    required this.onDeselectAll,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isSolid = ref.isSolidStyle;
    final isAllSelected = selectedCount > 0 && selectedCount == totalCount;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: StudioSurfaceTheme.outline(context, isSolid: isSolid),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isSolid ? 0.22 : 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 1. Close Button & Selected Counter
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              M3EIconButton(
                onPressed: () {
                  AppHaptics.selectionClick();
                  onClose();
                },
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedCancel01,
                  size: 17,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                tooltip: 'Cancel Selection',
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: StudioSurfaceTheme.tintedContainer(context, primary, isSolid: isSolid),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$selectedCount',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w800,
                    color: primary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),

          // 2. Action Icons
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildActionButton(
                context: context,
                isSolid: isSolid,
                icon: HugeIcons.strokeRoundedPlay,
                tooltip: 'Play Next',
                onTap: onPlayNext,
                theme: theme,
                primary: primary,
              ),
              const SizedBox(width: 3),
              _buildActionButton(
                context: context,
                isSolid: isSolid,
                icon: HugeIcons.strokeRoundedPlaylist01,
                tooltip: 'Add to Queue',
                onTap: onAddToQueue,
                theme: theme,
                primary: primary,
              ),
              const SizedBox(width: 3),
              _buildActionButton(
                context: context,
                isSolid: isSolid,
                icon: HugeIcons.strokeRoundedFolderAdd,
                tooltip: 'Add to Playlist',
                onTap: onAddToPlaylist,
                theme: theme,
                primary: primary,
              ),
              const SizedBox(width: 3),
              _buildActionButton(
                context: context,
                isSolid: isSolid,
                icon: HugeIcons.strokeRoundedTextFont,
                tooltip: 'Batch Edit Tags',
                onTap: onBatchEditTags,
                theme: theme,
                primary: primary,
              ),
              const SizedBox(width: 3),
              _buildActionButton(
                context: context,
                isSolid: isSolid,
                icon: isAllSelected
                    ? HugeIcons.strokeRoundedCheckmarkCircle02
                    : HugeIcons.strokeRoundedCheckmarkSquare02,
                tooltip: isAllSelected ? 'Deselect All' : 'Select All',
                onTap: isAllSelected ? onDeselectAll : onSelectAll,
                theme: theme,
                primary: primary,
                isActive: isAllSelected,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required bool isSolid,
    required dynamic icon,
    required String tooltip,
    required VoidCallback onTap,
    required ThemeData theme,
    required Color primary,
    bool isActive = false,
  }) {
    return M3EIconButton(
      onPressed: () {
        AppHaptics.lightImpact();
        onTap();
      },
      icon: HugeIcon(
        icon: icon,
        size: 17,
        color: isActive ? primary : theme.colorScheme.onSurface,
      ),
      tooltip: tooltip,
    );
  }
}
