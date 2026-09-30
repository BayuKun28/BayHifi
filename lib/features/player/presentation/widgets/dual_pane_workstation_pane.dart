import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../dsp_rack/presentation/dsp_rack_screen.dart';
import '../../data/lyrics_service.dart';
import '../../domain/playback_state.dart';
import '../controllers/player_controller.dart';
import 'synchronized_lyrics_view.dart';

enum WorkstationTab {
  queue('UP NEXT', HugeIcons.strokeRoundedPlaylist01),
  lyrics('LYRICS', HugeIcons.strokeRoundedTextFont),
  dspRack('DSP RACK', HugeIcons.strokeRoundedCpu);

  final String label;
  final dynamic icon;
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
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
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
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                              HugeIcon(
                                icon: tab.icon,
                                size: 13,
                                color: isSel ? primary : theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                tab.label,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSel ? FontWeight.w900 : FontWeight.w600,
                                  color: isSel ? primary : theme.colorScheme.onSurfaceVariant,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(width: 8),
                  if (_activeTab == WorkstationTab.queue)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
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
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: primary,
                        ),
                      ),
                    ),
                ],
              ),
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
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HugeIcon(
                  icon: HugeIcons.strokeRoundedPlaylist01,
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
              ],
            ),
          );
        }

        return ReorderableListView.builder(
          key: const ValueKey('tab_queue_list'),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          itemCount: playback.queue.length,
          // ignore: deprecated_member_use
          onReorder: (oldIdx, newIdx) {
            playerNotifier.reorderQueue(oldIdx, newIdx);
          },
          itemBuilder: (context, idx) {
            final track = playback.queue[idx];
            final isCur = idx == playback.queueIndex || (playback.currentTrack != null && track.id == playback.currentTrack!.id);

            return Dismissible(
              key: ValueKey('${track.id}_$idx'),
              direction: DismissDirection.endToStart,
              onDismissed: (_) {
                playerNotifier.removeFromQueue(idx);
              },
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: theme.colorScheme.error.withValues(alpha: 0.2),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedDelete02,
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
                              ? HugeIcon(icon: HugeIcons.strokeRoundedVolumeHigh, size: 14, color: primary)
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
                        // Drag Handle
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedDrag01,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                        ),
                      ],
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
