import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';

/// Floating capsule action bar for multi-track batch operations in the library
class LibraryBatchActionsBar extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isAllSelected = selectedCount > 0 && selectedCount == totalCount;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
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
                  HapticFeedback.selectionClick();
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
                  color: primary.withValues(alpha: 0.15),
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
                icon: HugeIcons.strokeRoundedPlay,
                tooltip: 'Play Next',
                onTap: onPlayNext,
                theme: theme,
                primary: primary,
              ),
              const SizedBox(width: 4),
              _buildActionButton(
                icon: HugeIcons.strokeRoundedPlaylist01,
                tooltip: 'Add to Queue',
                onTap: onAddToQueue,
                theme: theme,
                primary: primary,
              ),
              const SizedBox(width: 4),
              _buildActionButton(
                icon: HugeIcons.strokeRoundedFolderAdd,
                tooltip: 'Add to Playlist',
                onTap: onAddToPlaylist,
                theme: theme,
                primary: primary,
              ),
              const SizedBox(width: 4),
              _buildActionButton(
                icon: HugeIcons.strokeRoundedTextFont,
                tooltip: 'Batch Edit Tags',
                onTap: onBatchEditTags,
                theme: theme,
                primary: primary,
              ),
              const SizedBox(width: 4),
              _buildActionButton(
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
    required dynamic icon,
    required String tooltip,
    required VoidCallback onTap,
    required ThemeData theme,
    required Color primary,
    bool isActive = false,
  }) {
    return IconButton(
      onPressed: () {
        HapticFeedback.lightImpact();
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
        backgroundColor: isActive ? primary.withValues(alpha: 0.15) : Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
