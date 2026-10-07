import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../app/theme/app_haptics.dart';
import '../../features/dsp_rack/presentation/controllers/dsp_rack_controller.dart';
import '../../features/hardware_dac/presentation/controllers/dac_bridge_controller.dart';
import '../../features/lyrics_share/presentation/widgets/lyric_share_sheet.dart';
import '../../features/player/data/lyrics_service.dart';
import '../../features/player/domain/track.dart';
import '../../features/player/presentation/controllers/player_controller.dart';
import '../../features/player/presentation/widgets/synchronized_lyrics_view.dart';
import '../../features/pro_q_studio/presentation/controllers/eq_controller.dart';

/// Modal dialog lirik tersinkronisasi untuk platform Desktop
class DesktopLyricsDialog extends ConsumerStatefulWidget {
  final Track? track;

  const DesktopLyricsDialog({super.key, this.track});

  static Future<void> show(BuildContext context, Track? track) {
    return showDialog(
      context: context,
      builder: (_) => DesktopLyricsDialog(track: track),
    );
  }

  @override
  ConsumerState<DesktopLyricsDialog> createState() => _DesktopLyricsDialogState();
}

class _DesktopLyricsDialogState extends ConsumerState<DesktopLyricsDialog> {
  LyricsResult _lyricsResult = LyricsResult.empty();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.track != null) {
      _fetchLyrics(widget.track!);
    }
  }

  Future<void> _fetchLyrics(Track track, {bool forceOnline = false}) async {
    if (forceOnline) {
      LyricsService.instance.clearCacheForTrack(track.id);
    }
    setState(() => _isLoading = true);

    try {
      final result = await LyricsService.instance.getLyricsForTrack(track);
      if (mounted) {
        setState(() {
          _lyricsResult = result;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _lyricsResult = const LyricsResult.empty();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final playback = ref.watch(playerControllerProvider);
    final currentTrack = widget.track ?? playback.currentTrack;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      child: Container(
        width: 620,
        height: 540,
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedMusicNote01,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          currentTrack?.title ?? 'Lyrics',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          currentTrack?.artist ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Share Lyric Card Button
                  if (_lyricsResult.lines.isNotEmpty) ...[
                    Tooltip(
                      message: 'Share Lyric Card',
                      child: M3EIconButton(
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedShare08,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                          size: 18,
                        ),
                        onPressed: () {
                          if (currentTrack != null && _lyricsResult.lines.isNotEmpty) {
                            final eqState = ref.read(eqControllerProvider);
                            final dspState = ref.read(dspRackControllerProvider);
                            final dacState = ref.read(dacBridgeControllerProvider);

                            final autoEqName = eqState.targetFr?.name ?? eqState.activePresetName;
                            final dspName = dspState.activePresetId ?? (dspState.isBypassed ? 'Bypassed' : 'Studio Mastering');
                            final dacName = dacState.isConnected ? (dacState.device?.formattedTitle ?? 'Hardware USB DAC') : 'Bit-Perfect Direct Out';

                            AppHaptics.selectionClick();
                            LyricShareSheet.show(
                              context,
                              track: currentTrack,
                              allLines: _lyricsResult.lines,
                              audioSpec: currentTrack.format.name.isNotEmpty &&
                                      currentTrack.format.name != 'unknown'
                                  ? '${currentTrack.format.name.toUpperCase()} MASTER'
                                  : 'STUDIO MASTER',
                              autoEqProfileName: autoEqName.isNotEmpty ? autoEqName : null,
                              dspProfileName: dspName.isNotEmpty ? dspName : null,
                              dacDeviceName: dacName.isNotEmpty ? dacName : null,
                              timestamp: DateTime.now(),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 4),
                  ],
                  M3EIconButton(
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedRefresh,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      size: 18,
                    ),
                    onPressed: () {
                      if (currentTrack != null) {
                        _fetchLyrics(currentTrack, forceOnline: true);
                      }
                    },
                  ),
                  const SizedBox(width: 4),
                  M3EIconButton(
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedCancel01,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      size: 18,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.5)),
            // Body
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                child: SynchronizedLyricsView(
                  lyricsResult: _lyricsResult,
                  currentPosition: playback.position,
                  isLoading: _isLoading,
                  trackId: currentTrack?.id,
                  onRefresh: () {
                    if (currentTrack != null) {
                      _fetchLyrics(currentTrack, forceOnline: true);
                    }
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
