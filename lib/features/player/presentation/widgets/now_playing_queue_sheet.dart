import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/playback_state.dart';
import '../../domain/track.dart';
import '../controllers/player_controller.dart';

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
    _scrollToActiveTrack(animate: false);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToActiveTrack({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) return;
      final playback = ref.read(playerControllerProvider);
      final index = playback.queueIndex;
      if (index < 0 || index >= playback.queue.length) return;

      // Estimated item tile height: container (54px) + margin (7px) + border = ~62px
      const double estimatedItemHeight = 62.0;
      final viewportHeight = _scrollController.position.viewportDimension;
      final targetOffset = (index * estimatedItemHeight) - (viewportHeight / 2) + (estimatedItemHeight / 2);
      final clampedOffset = targetOffset.clamp(
        0.0,
        _scrollController.position.maxScrollExtent,
      );

      if (animate) {
        _scrollController.animateTo(
          clampedOffset,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
        );
      } else {
        _scrollController.jumpTo(clampedOffset);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Automatically auto-center active track when queue index advances
    ref.listen<int>(
      playerControllerProvider.select((s) => s.queueIndex),
      (prev, next) {
        if (prev != next) {
          _scrollToActiveTrack(animate: true);
        }
      },
    );

    final playback = ref.watch(playerControllerProvider);
    final controller = ref.read(playerControllerProvider.notifier);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: const Color(0xFF0F131C),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: const Color(0xFF222938), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 32,
            offset: Offset(0, -6),
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
                color: const Color(0xFF374151),
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
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF94A3B8),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                Row(
                  children: [
                    // Shuffle Toggle
                    IconButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        controller.toggleShuffle();
                      },
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedShuffle,
                        size: 20,
                        color: playback.isShuffle
                            ? primary
                            : const Color(0xFF64748B),
                      ),
                      tooltip: 'Shuffle Queue',
                    ),
                    // Repeat Mode Toggle
                    IconButton(
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        controller.toggleRepeatMode();
                      },
                      icon: HugeIcon(
                        icon: playback.repeatMode == PlaybackRepeatMode.one
                            ? HugeIcons.strokeRoundedRepeatOne01
                            : HugeIcons.strokeRoundedRepeat,
                        size: 20,
                        color: playback.repeatMode != PlaybackRepeatMode.off
                            ? primary
                            : const Color(0xFF64748B),
                      ),
                      tooltip: 'Repeat Mode',
                    ),
                    // Clear Queue
                    if (playback.queue.isNotEmpty)
                      IconButton(
                        onPressed: () {
                          HapticFeedback.mediumImpact();
                          controller.clearQueue();
                        },
                        icon: const HugeIcon(
                          icon: HugeIcons.strokeRoundedDelete02,
                          size: 20,
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
          const Divider(color: Color(0xFF1E2636), height: 1),

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
                        scrollController: _scrollController,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        itemCount: playback.queue.length,
                        // ignore: deprecated_member_use
                        onReorder: (oldIdx, newIdx) {
                          HapticFeedback.selectionClick();
                          controller.reorderQueue(oldIdx, newIdx);
                        },
                        itemBuilder: (context, index) {
                          final track = playback.queue[index];
                          final isCurrent = index == playback.queueIndex;

                          return _QueueTrackTile(
                            key: ValueKey('queue_track_${track.id}_$index'),
                            index: index,
                            track: track,
                            isCurrent: isCurrent,
                            primaryColor: primary,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              controller.skipToQueueIndex(index);
                            },
                            onRemove: () {
                              HapticFeedback.lightImpact();
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
  final Color primaryColor;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  const _QueueTrackTile({
    super.key,
    required this.index,
    required this.track,
    required this.isCurrent,
    required this.primaryColor,
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 3.5),
      decoration: BoxDecoration(
        color: isCurrent
            ? primaryColor.withValues(alpha: 0.12)
            : const Color(0xFF131824),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCurrent
              ? primaryColor.withValues(alpha: 0.5)
              : const Color(0xFF202838),
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
                  ? primaryColor.withValues(alpha: 0.2)
                  : const Color(0xFF1B2232),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isCurrent
                    ? primaryColor.withValues(alpha: 0.6)
                    : const Color(0xFF2A3448),
                width: 0.8,
              ),
            ),
            child: Center(
              child: isCurrent
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
                    ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  track.title,
                  style: TextStyle(
                    color: isCurrent ? primaryColor : Colors.white,
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
                  style: const TextStyle(
                    color: Color(0xFF8E9EB2),
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (track.duration > Duration.zero)
                Text(
                  _formatDuration(track.duration),
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const HugeIcon(
                  icon: HugeIcons.strokeRoundedCancel01,
                  size: 16,
                  color: Color(0xFFFF3B30),
                ),
                onPressed: onRemove,
                tooltip: 'Remove from Queue',
              ),
              ReorderableDragStartListener(
                index: index,
                child: const HugeIcon(
                  icon: HugeIcons.strokeRoundedDragDropVertical,
                  size: 18,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
