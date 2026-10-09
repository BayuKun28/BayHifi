import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../domain/playback_state.dart';
import '../../domain/track.dart';
import '../controllers/player_controller.dart';
import 'add_tracks_to_queue_sheet.dart';

class NowPlayingQueueSheet extends ConsumerStatefulWidget {
  const NowPlayingQueueSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const NowPlayingQueueSheet(),
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
    _scrollToActiveTrack(animate: false, delayMs: 350);
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

      // Estimated item tile height: container (54px) + margin (7px) + border = ~62px
      const double estimatedItemHeight = 62.0;
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
          duration: const Duration(milliseconds: 350),
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
    // Automatically auto-center active track when queue index advances
    ref.listen<int>(
      playerControllerProvider.select((s) => s.queueIndex),
      (prev, next) {
        if (prev != next) {
          _scrollToActiveTrack(animate: true, delayMs: 50);
        }
      },
    );

    final playback = ref.watch(playerControllerProvider);
    final controller = ref.read(playerControllerProvider.notifier);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isSolid = ref.isSolidStyle;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(
          color: StudioSurfaceTheme.outline(context, isSolid: isSolid),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(
              alpha: theme.brightness == Brightness.dark ? 0.35 : 0.08,
            ),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ─── 1. TOP DRAG HANDLE & HEADER ─────────────────────────────────
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 38,
              height: 4.5,
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          const SizedBox(height: 14),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0),
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
                          decoration: BoxDecoration(
                            color: primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'UP NEXT QUEUE',
                          style: AppTypography.badge(color: primary),
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
                        color: theme.colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                Row(
                  children: [
                    // Add Tracks to Queue (Namida Style)
                    M3EIconButton(
                      variant: M3EIconButtonVariant.standard,
                      onPressed: () {
                        AddTracksToQueueSheet.show(context);
                      },
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedPlayList,
                        size: 22,
                        color: primary,
                      ),
                      tooltip: 'Add Tracks to Queue',
                    ),
                    // Shuffle Toggle
                    M3EIconButton(
                      variant: M3EIconButtonVariant.standard,
                      onPressed: () {
                        AppHaptics.selectionClick();
                        controller.toggleShuffle();
                      },
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedShuffle,
                        size: 22,
                        color: playback.isShuffle
                            ? primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      tooltip: 'Shuffle Queue',
                    ),
                    // Repeat Mode Toggle
                    M3EIconButton(
                      variant: M3EIconButtonVariant.standard,
                      onPressed: () {
                        AppHaptics.selectionClick();
                        controller.toggleRepeatMode();
                      },
                      icon: HugeIcon(
                        icon: playback.repeatMode == PlaybackRepeatMode.one
                            ? HugeIcons.strokeRoundedRepeatOne01
                            : HugeIcons.strokeRoundedRepeat,
                        size: 22,
                        color: playback.repeatMode != PlaybackRepeatMode.off
                            ? primary
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      tooltip: 'Repeat Mode',
                    ),
                    // Clear Queue
                    if (playback.queue.isNotEmpty)
                      M3EIconButton(
                        variant: M3EIconButtonVariant.standard,
                        onPressed: () {
                          AppHaptics.mediumImpact();
                          controller.clearQueue();
                        },
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedDelete02,
                          size: 22,
                          color: Color(0xFFFF3B30),
                        ),
                        tooltip: 'Clear Queue',
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
          Divider(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4), height: 1),

          // ─── 2. REORDERABLE QUEUE LIST WITH SCROLLBAR & AUTO-CENTERING ────
          Expanded(
            child: playback.queue.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const HugeIcon(
                          icon: HugeIcons.strokeRoundedPlaylist01,
                          size: 54,
                          color: Color(0xFF334155),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'No Tracks in Queue',
                          style: TextStyle(
                            color: Color(0xFFE2E8F0),
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Add songs from Library or Playlists to stream',
                          style: TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  )
                : Theme(
                    data: theme.copyWith(
                      scrollbarTheme: ScrollbarThemeData(
                        thumbColor: WidgetStatePropertyAll(primary.withValues(alpha: 0.5)),
                        trackColor: WidgetStatePropertyAll(Colors.white.withValues(alpha: 0.04)),
                        trackBorderColor: const WidgetStatePropertyAll(Colors.transparent),
                        radius: const Radius.circular(8),
                        thickness: const WidgetStatePropertyAll(4.5),
                        minThumbLength: 36,
                      ),
                    ),
                    child: Scrollbar(
                      controller: _scrollController,
                      thumbVisibility: true,
                      interactive: true,
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

                          return _QueueTrackTile(
                            key: ValueKey('queue_track_${track.id}_$index'),
                            index: index,
                            track: track,
                            isCurrent: isCurrent,
                            isBuffering: isBuffering,
                            primaryColor: primary,
                            isSolid: isSolid,
                            onTap: () {
                              AppHaptics.lightImpact();
                              controller.skipToQueueIndex(index);
                            },
                            onRemove: () {
                              AppHaptics.lightImpact();
                              controller.removeFromQueue(index);
                            },
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _QueueTrackTile extends StatelessWidget {
  final int index;
  final Track track;
  final bool isCurrent;
  final bool isBuffering;
  final Color primaryColor;
  final bool isSolid;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _QueueTrackTile({
    super.key,
    required this.index,
    required this.track,
    required this.isCurrent,
    this.isBuffering = false,
    required this.primaryColor,
    required this.isSolid,
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3.5),
      decoration: BoxDecoration(
        color: isCurrent
            ? StudioSurfaceTheme.tintedContainer(
                context,
                primaryColor,
                isSolid: isSolid,
              )
            : StudioSurfaceTheme.surfaceContainerLow(
                context,
                isSolid: isSolid,
              ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent
              ? primaryColor.withValues(alpha: isSolid ? 0.8 : 0.5)
              : StudioSurfaceTheme.subtleOutline(
                  context,
                  isSolid: isSolid,
                ),
          width: isCurrent ? 1.2 : 0.8,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          onTap: onTap,
          leading: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isCurrent
                  ? (isSolid
                      ? primaryColor.withValues(alpha: 0.25)
                      : primaryColor.withValues(alpha: 0.2))
                  : StudioSurfaceTheme.surfaceContainer(
                      context,
                      isSolid: isSolid,
                    ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCurrent
                    ? primaryColor.withValues(alpha: isSolid ? 0.7 : 0.6)
                    : StudioSurfaceTheme.outline(
                        context,
                        isSolid: isSolid,
                      ),
                width: 0.8,
              ),
            ),
            child: Center(
              child: isBuffering
                  ? SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.8,
                        valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                      ),
                    )
                  : (isCurrent
                      ? HugeIcon(
                          icon: HugeIcons.strokeRoundedAudioWaveform,
                          size: 16,
                          color: primaryColor,
                        )
                      : Text(
                          (index + 1).toString().padLeft(2, '0'),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        )),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  track.title,
                  style: TextStyle(
                    color: isCurrent ? primaryColor : theme.colorScheme.onSurface,
                    fontSize: 13,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (track.isHiRes) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF9F0A).withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color(0xFFFF9F0A).withValues(alpha: 0.6),
                      width: 0.6,
                    ),
                  ),
                  child: const Text(
                    'Hi-Res',
                    style: TextStyle(
                      color: Color(0xFFFF9F0A),
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ],
          ),
          subtitle: Row(
            children: [
              Expanded(
                child: Text(
                  '${track.artist} • ${track.album}',
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (track.duration > Duration.zero)
                Text(
                  _formatDuration(track.duration),
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              M3EIconButton(
                variant: M3EIconButtonVariant.standard,
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedCancel01,
                  size: 20,
                  color: Color(0xFFFF3B30),
                ),
                onPressed: onRemove,
                tooltip: 'Remove from Queue',
              ),
              ReorderableDragStartListener(
                index: index,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 15,
                        height: 2,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                      const SizedBox(height: 3.5),
                      Container(
                        width: 15,
                        height: 2,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
