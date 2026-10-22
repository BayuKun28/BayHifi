import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/simple_as_f_theme.dart';
import '../../domain/playback_state.dart';
import '../../domain/track.dart';
import '../controllers/player_controller.dart';
import 'add_tracks_to_queue_sheet.dart';

class NowPlayingQueueSheet extends ConsumerStatefulWidget {
  final bool isDialog;

  const NowPlayingQueueSheet({
    super.key,
    this.isDialog = false,
  });

  static Future<void> show(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 650) {
      return showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.65),
        builder: (_) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
              child: const NowPlayingQueueSheet(isDialog: true),
            ),
          ),
        ),
      );
    }

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NowPlayingQueueSheet(isDialog: false),
    );
  }

  @override
  ConsumerState<NowPlayingQueueSheet> createState() => _NowPlayingQueueSheetState();
}

class _NowPlayingQueueSheetState extends ConsumerState<NowPlayingQueueSheet> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
    _scrollToActiveTrack(animate: false, delayMs: 150);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActiveTrack({bool animate = true, int delayMs = 0}) {
    void executeScroll() {
      if (!mounted || !_scrollController.hasClients) return;
      final playback = ref.read(playerControllerProvider);
      final index = playback.queueIndex;
      if (index < 0 || index >= playback.queue.length) return;

      const double estimatedItemHeight = 60.0;
      final viewportHeight = _scrollController.position.viewportDimension;
      final targetOffset = (index * estimatedItemHeight) - (viewportHeight / 2) + (estimatedItemHeight / 2);
      final maxExtent = _scrollController.position.maxScrollExtent;
      final clampedOffset = targetOffset.clamp(
        0.0,
        maxExtent > 0 ? maxExtent : double.infinity,
      );

      if (animate && _scrollController.hasClients) {
        _scrollController.animateTo(
          clampedOffset,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      } else if (_scrollController.hasClients) {
        _scrollController.jumpTo(clampedOffset);
      }
    }

    if (delayMs > 0) {
      Future.delayed(Duration(milliseconds: delayMs), () {
        if (mounted) {
          WidgetsBinding.instance.addPostFrameCallback((_) => executeScroll());
        }
      });
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => executeScroll());
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(
      playerControllerProvider.select((s) => s.queueIndex),
      (prev, next) {
        if (prev != next) {
          _scrollToActiveTrack(animate: true, delayMs: 50);
        }
      },
    );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final controller = ref.read(playerControllerProvider.notifier);
    final queue =
        ref.watch(playerControllerProvider.select((s) => s.queue));
    final queueIndex =
        ref.watch(playerControllerProvider.select((s) => s.queueIndex));
    final isShuffle =
        ref.watch(playerControllerProvider.select((s) => s.isShuffle));
    final repeatMode =
        ref.watch(playerControllerProvider.select((s) => s.repeatMode));
    final status =
        ref.watch(playerControllerProvider.select((s) => s.status));
    final currentTrack =
        ref.watch(playerControllerProvider.select((s) => s.currentTrack));

    final playback = PlaybackState(
      queue: queue,
      queueIndex: queueIndex,
      isShuffle: isShuffle,
      repeatMode: repeatMode,
      status: status,
      currentTrack: currentTrack,
    );
    final isDialog = widget.isDialog;

    return Container(
      height: isDialog ? 640 : MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF16181F) : theme.colorScheme.surfaceContainer,
        borderRadius: isDialog
            ? BorderRadius.circular(24)
            : SimpleAsFTheme.sheetTopBorderRadius,
        border: Border.all(
          color: isDark ? const Color(0xFF262936) : theme.colorScheme.outlineVariant,
          width: 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // ─── 1. TOP DRAG HANDLE (Mobile only) ───────────────────────────
          if (!isDialog) ...[
            const SizedBox(height: 12),
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF2E3242) : theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ] else
            const SizedBox(height: 16),

          // ─── 2. HEADER & ACTIONS ─────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'UP NEXT QUEUE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      playback.queue.isNotEmpty
                          ? '${playback.queueIndex + 1} of ${playback.queue.length} Tracks'
                          : 'Queue Empty',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF8A9A90) : theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                        fontFeatures: AppTypography.audioFigures,
                      ),
                    ),
                  ],
                ),

                Row(
                  children: [
                    // Add Tracks to Queue
                    _buildActionButton( 
                      icon: LucideIcons.listPlus,
                      tooltip: 'Add Tracks to Queue',
                      onPressed: () => AddTracksToQueueSheet.show(context),
                    ),
                    const SizedBox(width: 4),
                    // Shuffle Toggle
                    _buildActionButton( 
                      icon: LucideIcons.shuffle,
                      tooltip: 'Shuffle Queue',
                      isActive: playback.isShuffle,
                      onPressed: () {
                        AppHaptics.selectionClick();
                        controller.toggleShuffle();
                      },
                    ),
                    const SizedBox(width: 4),
                    // Repeat Mode Toggle
                    _buildActionButton( 
                      icon: playback.repeatMode == PlaybackRepeatMode.one
                          ? LucideIcons.repeat1
                          : LucideIcons.repeat,
                      tooltip: 'Repeat Mode',
                      isActive: playback.repeatMode != PlaybackRepeatMode.off,
                      onPressed: () {
                        AppHaptics.selectionClick();
                        controller.toggleRepeatMode();
                      },
                    ),
                    // Clear Queue
                    if (playback.queue.isNotEmpty) ...[
                      const SizedBox(width: 4),
                      _buildActionButton( 
                        icon: LucideIcons.trash2,
                        tooltip: 'Clear Queue',
                        iconColor: const Color(0xFFEF4444),
                        onPressed: () {
                          AppHaptics.mediumImpact();
                          controller.clearQueue();
                        },
                      ),
                    ],
                    if (isDialog) ...[
                      const SizedBox(width: 4),
                      _buildActionButton( 
                        icon: LucideIcons.x,
                        tooltip: 'Close Dialog',
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),
          Divider(color: isDark ? const Color(0xFF262936) : theme.colorScheme.outlineVariant, height: 1),

          // ─── 3. REORDERABLE QUEUE LIST ──────────────────────────────────
          Expanded(
            child: playback.queue.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.listMusic,
                          size: 48,
                          color: isDark ? const Color(0xFF2E3242) : theme.colorScheme.outlineVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No Tracks in Queue',
                          style: TextStyle(
                            color: isDark ? Colors.white : theme.colorScheme.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Add songs from Library or Playlists to stream',
                          style: TextStyle(
                            color: isDark ? const Color(0xFF8A9A90) : theme.colorScheme.onSurfaceVariant,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  )
                : Scrollbar(
                    controller: _scrollController,
                    thumbVisibility: true,
                    child: ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      scrollController: _scrollController,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      itemCount: playback.queue.length,
                      // ignore: deprecated_member_use
                      onReorder: (oldIdx, newIdx) {
                        AppHaptics.selectionClick();
                        controller.reorderQueue(oldIdx, newIdx);
                      },
                      itemBuilder: (context, index) {
                        final track = playback.queue[index];
                        final isCurrent = index == playback.queueIndex;
                        final isBuffering = isCurrent && playback.isLoading;

                        return ReorderableDelayedDragStartListener(
                          key: ValueKey('queue_track_${track.id}_$index'),
                          index: index,
                          child: _QueueTrackTile(
                            index: index,
                            track: track,
                            isCurrent: isCurrent,
                            isBuffering: isBuffering,
                            onTap: () {
                              AppHaptics.lightImpact();
                              controller.skipToQueueIndex(index);
                            },
                            onRemove: () {
                              AppHaptics.lightImpact();
                              controller.removeFromQueue(index);
                            },
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
    bool isActive = false,
    Color? iconColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: isActive
                ? (isDark ? const Color(0xFF222532) : theme.colorScheme.surfaceContainerHighest)
                : (isDark ? const Color(0xFF1E212B) : theme.colorScheme.surfaceContainer),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                  ? (isDark ? const Color(0xFF383D50) : theme.colorScheme.outline)
                  : (isDark ? const Color(0xFF262936) : theme.colorScheme.outlineVariant),
              width: 0.8,
            ),
          ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 15,
            color: iconColor ??
                (isActive ? const Color(0xFF10B981) : (isDark ? const Color(0xFFA1B2A7) : theme.colorScheme.onSurfaceVariant)),
          ),
        ),
      ),
    );
  }
}

class _QueueTrackTile extends StatelessWidget {
  final int index;
  final Track track;
  final bool isCurrent;
  final bool isBuffering;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _QueueTrackTile({
    required this.index,
    required this.track,
    required this.isCurrent,
    this.isBuffering = false,
    required this.onTap,
    required this.onRemove,
  });

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final tileBg = isCurrent
        ? (isDark ? const Color(0xFF20232E) : theme.colorScheme.surfaceContainerHighest)
        : (isDark ? const Color(0xFF12141A) : theme.colorScheme.surfaceContainer);
    final tileBorder = isCurrent
        ? (isDark ? const Color(0xFF383D50) : theme.colorScheme.outline)
        : (isDark ? const Color(0xFF262936) : theme.colorScheme.outlineVariant);
    final indexBoxBg = isCurrent
        ? (isDark ? const Color(0xFF252834) : theme.colorScheme.surfaceContainerHigh)
        : (isDark ? const Color(0xFF16181F) : theme.colorScheme.surfaceContainer);
    final indexBoxBorder = isCurrent
        ? (isDark ? const Color(0xFF383D50) : theme.colorScheme.outline)
        : (isDark ? const Color(0xFF262936) : theme.colorScheme.outlineVariant);
    final metaColor = isDark ? const Color(0xFF8A9A90) : theme.colorScheme.onSurfaceVariant;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3.0),
      decoration: BoxDecoration(
        color: tileBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: tileBorder,
          width: isCurrent ? 1.0 : 0.8,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: Row(
              children: [
                // Playing indicator / Track Index
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: indexBoxBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: indexBoxBorder,
                      width: 0.8,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: isBuffering
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 1.8,
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                          ),
                        )
                      : (isCurrent
                          ? const Icon(
                              LucideIcons.audioLines,
                              size: 15,
                              color: Color(0xFF10B981),
                            )
                          : Text(
                              (index + 1).toString().padLeft(2, '0'),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: metaColor,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            )),
                ),
                const SizedBox(width: 12),

                // Track Title & Artist
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        track.title.isNotEmpty ? track.title : 'Unknown Title',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                          color: isCurrent
                              ? (isDark ? Colors.white : theme.colorScheme.onSurface)
                              : (isDark ? const Color(0xFFE6EAE7) : theme.colorScheme.onSurface),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              track.artist.isNotEmpty ? track.artist : 'Unknown Artist',
                              style: TextStyle(
                                fontSize: 11,
                                color: metaColor,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _formatDuration(track.duration),
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                              color: metaColor,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Remove Track Button
                InkWell(
                  onTap: onRemove,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      LucideIcons.x,
                      size: 14,
                      color: metaColor,
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // Drag Handle
                ReorderableDragStartListener(
                  index: index,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      LucideIcons.gripVertical,
                      size: 16,
                      color: metaColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
