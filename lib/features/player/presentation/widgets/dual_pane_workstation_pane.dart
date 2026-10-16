import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../dsp_rack/presentation/dsp_rack_screen.dart';
import '../../data/lyrics_service.dart';
import '../../domain/playback_state.dart';
import '../controllers/player_controller.dart';
import 'add_tracks_to_queue_sheet.dart';
import 'synchronized_lyrics_view.dart';

enum WorkstationTab {
  queue('UP NEXT', LucideIcons.listMusic),
  lyrics('LYRICS', LucideIcons.type),
  dspRack('DSP RACK', LucideIcons.cpu);

  final String label;
  final IconData icon;
  const WorkstationTab(this.label, this.icon);
}

/// Dual-Pane Right Workstation View for Landscape & Tablet NowPlaying
class DualPaneWorkstationPane extends ConsumerStatefulWidget {
  final LyricsResult lyricsResult;
  final bool isLoadingLyrics;
  final VoidCallback? onRefreshLyrics;

  const DualPaneWorkstationPane({
    super.key,
    required this.lyricsResult,
    this.isLoadingLyrics = false,
    this.onRefreshLyrics,
  });

  @override
  ConsumerState<DualPaneWorkstationPane> createState() => _DualPaneWorkstationPaneState();
}

class _DualPaneWorkstationPaneState extends ConsumerState<DualPaneWorkstationPane> {
  WorkstationTab _activeTab = WorkstationTab.queue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isSolid = ref.isSolidStyle;
    final playback = ref.watch(playerControllerProvider);
    final playerNotifier = ref.read(playerControllerProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surface(context, isSolid: isSolid),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: StudioSurfaceTheme.outline(context, isSolid: isSolid),
          width: 1.0,
        ),
      ),
      child: Column(
        children: [
          // ─── 1. WORKSTATION TOP TAB BAR ──────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
              border: Border(
                bottom: BorderSide(
                  color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                  width: 1.0,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...WorkstationTab.values.map((tab) {
                          final isSel = _activeTab == tab;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6.0),
                            child: InkWell(
                              onTap: () {
                                AppHaptics.selectionClick();
                                setState(() => _activeTab = tab);
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5.5),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? StudioSurfaceTheme.tintedContainer(
                                          context,
                                          primary,
                                          isSolid: isSolid,
                                          translucentAlpha: 0.18,
                                          solidBlendAlpha: 0.2,
                                        )
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isSel
                                        ? (isSolid ? theme.colorScheme.outline : primary.withValues(alpha: 0.6))
                                        : StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                                    width: 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      tab.icon,
                                      size: 13,
                                      color: isSel ? primary : theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      tab.label,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: isSel ? FontWeight.w900 : FontWeight.w600,
                                        color: isSel ? primary : theme.colorScheme.onSurfaceVariant,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                if (_activeTab == WorkstationTab.queue) ...[
                  const SizedBox(width: 4),
                  // Track Count Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: StudioSurfaceTheme.tintedContainer(
                        context,
                        primary,
                        isSolid: isSolid,
                        translucentAlpha: 0.15,
                      ),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isSolid ? theme.colorScheme.outline : primary.withValues(alpha: 0.3),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      '${playback.queue.length} Tracks',
                      style: TextStyle(
                        fontFeatures: AppTypography.audioFigures,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),
                  // Add Tracks to Queue / Instant Mix Button (Namida Style)
                  M3EIconButton(
                    variant: M3EIconButtonVariant.standard,
                    onPressed: () {
                      AppHaptics.lightImpact();
                      AddTracksToQueueSheet.show(context);
                    },
                    icon: Icon(
                      LucideIcons.listPlus,
                      size: 18,
                      color: primary,
                    ),
                    tooltip: 'Add Tracks to Queue / Instant Mix',
                  ),
                  // Shuffle Toggle Button
                  M3EIconButton(
                    variant: M3EIconButtonVariant.standard,
                    onPressed: () {
                      AppHaptics.selectionClick();
                      playerNotifier.toggleShuffle();
                    },
                    icon: Icon(
                      LucideIcons.shuffle,
                      size: 18,
                      color: playback.isShuffle ? primary : theme.colorScheme.onSurfaceVariant,
                    ),
                    tooltip: 'Shuffle Queue',
                  ),
                  // Repeat Mode Button
                  M3EIconButton(
                    variant: M3EIconButtonVariant.standard,
                    onPressed: () {
                      AppHaptics.selectionClick();
                      playerNotifier.toggleRepeatMode();
                    },
                    icon: Icon(
                      playback.repeatMode == PlaybackRepeatMode.one
                          ? LucideIcons.repeat1
                          : LucideIcons.repeat,
                      size: 18,
                      color: playback.repeatMode != PlaybackRepeatMode.off
                          ? primary
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                    tooltip: 'Repeat Mode',
                  ),
                ],
              ],
            ),
          ),

          // ─── 2. ACTIVE TAB WORKSTATION CONTENT ─────────────────────────────
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(17)),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 220),
                child: _buildTabBody(context, playback, playerNotifier, primary, isSolid),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBody(
    BuildContext context,
    PlaybackState playback,
    PlayerController playerNotifier,
    Color primary,
    bool isSolid,
  ) {
    final theme = Theme.of(context);
    switch (_activeTab) {
      case WorkstationTab.queue:
        if (playback.queue.isEmpty) {
          return Center(
            key: const ValueKey('tab_queue_empty'),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    LucideIcons.listMusic,
                    size: 40,
                    color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'No tracks currently queued',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  M3EButton.filled(
                    onPressed: () {
                      AppHaptics.lightImpact();
                      AddTracksToQueueSheet.show(context);
                    },
                    icon: Icon(
                      LucideIcons.listPlus,
                      size: 15,
                      color: theme.colorScheme.onPrimary,
                    ),
                    label: Text(
                      'ADD TRACKS / INSTANT MIX',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: theme.colorScheme.onPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return ReorderableListView.builder(
          key: const ValueKey('tab_queue_list'),
          buildDefaultDragHandles: false,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          itemCount: playback.queue.length,
          // ignore: deprecated_member_use
          onReorder: (oldIdx, newIdx) {
            AppHaptics.selectionClick();
            playerNotifier.reorderQueue(oldIdx, newIdx);
          },
          itemBuilder: (context, idx) {
            final track = playback.queue[idx];
            final isCur = idx == playback.queueIndex || (playback.currentTrack != null && track.id == playback.currentTrack!.id);

            return ReorderableDelayedDragStartListener(
              key: ValueKey('dual_pane_queue_${track.id}_$idx'),
              index: idx,
              child: Dismissible(
                key: ValueKey('${track.id}_$idx'),
                direction: DismissDirection.endToStart,
                onDismissed: (_) {
                  playerNotifier.removeFromQueue(idx);
                },
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: theme.colorScheme.error.withValues(alpha: 0.2),
                  child: Icon(
                    LucideIcons.trash2,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
                ),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  child: InkWell(
                    onTap: () {
                      AppHaptics.selectionClick();
                      playerNotifier.skipToQueueIndex(idx);
                    },
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isCur
                            ? StudioSurfaceTheme.tintedContainer(
                                context,
                                primary,
                                isSolid: isSolid,
                                translucentAlpha: 0.12,
                              )
                            : StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isCur
                              ? (isSolid ? theme.colorScheme.outline : primary.withValues(alpha: 0.5))
                              : StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                          width: isCur ? 1.2 : 0.8,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Play indicator or Index
                          Container(
                            width: 24,
                            alignment: Alignment.center,
                            child: isCur
                                ? Icon(LucideIcons.volume2, size: 14, color: primary)
                                : Text(
                                    '${idx + 1}',
                                    style: TextStyle(
                                      fontFeatures: AppTypography.audioFigures,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  track.title,
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: isCur ? FontWeight.bold : FontWeight.w600,
                                    color: isCur ? primary : theme.colorScheme.onSurface,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${track.artist} • ${track.format.name.toUpperCase()}',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Crisp drag handle with ReorderableDragStartListener and generous hit area
                          ReorderableDragStartListener(
                            index: idx,
                            child: Container(
                              color: Colors.transparent,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                              constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                              child: Center(
                                child: Icon(
                                  LucideIcons.gripVertical,
                                  size: 18,
                                  color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        );

      case WorkstationTab.lyrics:
        return SynchronizedLyricsView(
          key: const ValueKey('tab_lyrics'),
          lyricsResult: widget.lyricsResult,
          currentPosition: playback.position,
          isLoading: widget.isLoadingLyrics,
          onRefresh: widget.onRefreshLyrics,
          trackId: playback.currentTrack?.id,
        );

      case WorkstationTab.dspRack:
        return const DspRackScreen(
          key: ValueKey('tab_dsprack'),
        );
    }
  }
}
