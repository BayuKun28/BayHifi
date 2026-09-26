import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../dsp_rack/presentation/dsp_rack_screen.dart';
import '../../../pro_q_studio/presentation/widgets/band_strip_bar.dart';
import '../../../pro_q_studio/presentation/widgets/interactive_eq_canvas.dart';
import '../../data/lyrics_service.dart';
import '../controllers/player_controller.dart';
import 'synchronized_lyrics_view.dart';

enum WorkstationTab {
  proQ('PRO-Q EQ', HugeIcons.strokeRoundedSlidersVertical),
  dspRack('DSP RACK', HugeIcons.strokeRoundedCpu),
  lyrics('LYRICS', HugeIcons.strokeRoundedTextFont),
  queue('UP NEXT', HugeIcons.strokeRoundedPlaylist01);

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
  WorkstationTab _activeTab = WorkstationTab.proQ;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final playback = ref.watch(playerControllerProvider);
    final playerNotifier = ref.read(playerControllerProvider.notifier);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0C0F16),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF1E2533), width: 1.0),
      ),
      child: Column(
        children: [
          // ─── 1. WORKSTATION TOP TAB BAR ──────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const BoxDecoration(
              color: Color(0xFF0F131C),
              borderRadius: BorderRadius.vertical(top: Radius.circular(17)),
              border: Border(bottom: BorderSide(color: Color(0xFF1E2533), width: 1.0)),
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
                        HapticFeedback.selectionClick();
                        setState(() => _activeTab = tab);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSel ? primary.withValues(alpha: 0.18) : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSel ? primary.withValues(alpha: 0.6) : const Color(0xFF222B38),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            HugeIcon(
                              icon: tab.icon,
                              size: 13,
                              color: isSel ? primary : const Color(0xFF7A8B9E),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              tab.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSel ? FontWeight.w900 : FontWeight.w600,
                                color: isSel ? primary : const Color(0xFF94A3B8),
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
                      color: primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${playback.queue.length} Tracks',
                      style: TextStyle(
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
                child: _buildTabBody(context, playback, playerNotifier, primary),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBody(
    BuildContext context,
    dynamic playback,
    PlayerController playerNotifier,
    Color primary,
  ) {
    switch (_activeTab) {
      case WorkstationTab.proQ:
        return const Column(
          key: ValueKey('tab_proq'),
          children: [
            Expanded(
              child: InteractiveEqCanvas(),
            ),
            BandStripBar(),
          ],
        );

      case WorkstationTab.dspRack:
        return const DspRackScreen(
          key: ValueKey('tab_dsprack'),
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

      case WorkstationTab.queue:
        if (playback.queue.isEmpty) {
          return const Center(
            key: ValueKey('tab_queue_empty'),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                HugeIcon(icon: HugeIcons.strokeRoundedPlaylist01, size: 40, color: Color(0xFF4A5568)),
                SizedBox(height: 10),
                Text(
                  'No tracks currently queued',
                  style: TextStyle(color: Color(0xFF7A8B9E), fontSize: 13, fontWeight: FontWeight.w600),
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
            final isCur = idx == playback.currentIndex;

            return Dismissible(
              key: ValueKey('${track.id}_$idx'),
              direction: DismissDirection.endToStart,
              onDismissed: (_) {
                playerNotifier.removeFromQueue(idx);
              },
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                color: const Color(0xFFFF3B30).withValues(alpha: 0.2),
                child: const HugeIcon(icon: HugeIcons.strokeRoundedDelete02, size: 18, color: Color(0xFFFF3B30)),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isCur ? primary.withValues(alpha: 0.12) : const Color(0xFF131722),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isCur ? primary.withValues(alpha: 0.5) : const Color(0xFF1F2838),
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
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6B7C93)),
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
                              color: isCur ? primary : Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${track.artist} • ${track.format.name.toUpperCase()}',
                            style: const TextStyle(fontSize: 10.5, color: Color(0xFF7A8B9E)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Drag Handle
                    const HugeIcon(icon: HugeIcons.strokeRoundedDrag01, size: 16, color: Color(0xFF5A6A80)),
                  ],
                ),
              ),
            );
          },
        );
    }
  }
}
