import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
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
              IconButton(
                onPressed: () {
                  AppHaptics.selectionClick();
                  onClose();
                },
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedCancel01,
                  size: 18,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                tooltip: 'Cancel Selection',
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: StudioSurfaceTheme.tintedContainer(context, primary, isSolid: isSolid),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$selectedCount',
                  style: TextStyle(
                    fontSize: 12,
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
              const SizedBox(width: 4),
              _buildActionButton(
                context: context,
                isSolid: isSolid,
                icon: HugeIcons.strokeRoundedPlaylist01,
                tooltip: 'Add to Queue',
                onTap: onAddToQueue,
                theme: theme,
                primary: primary,
              ),
              const SizedBox(width: 4),
              _buildActionButton(
                context: context,
                isSolid: isSolid,
                icon: HugeIcons.strokeRoundedFolderAdd,
                tooltip: 'Add to Playlist',
                onTap: onAddToPlaylist,
                theme: theme,
                primary: primary,
              ),
              const SizedBox(width: 4),
              _buildActionButton(
                context: context,
                isSolid: isSolid,
                icon: HugeIcons.strokeRoundedTextFont,
                tooltip: 'Batch Edit Tags',
                onTap: onBatchEditTags,
                theme: theme,
                primary: primary,
              ),
              const SizedBox(width: 4),
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
    return IconButton(
      onPressed: () {
        AppHaptics.lightImpact();
        onTap();
      },
      icon: HugeIcon(
        icon: icon,
        size: 18,
        color: isActive ? primary : theme.colorScheme.onSurface,
      ),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: isActive
            ? StudioSurfaceTheme.tintedContainer(context, primary, isSolid: isSolid)
            : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
