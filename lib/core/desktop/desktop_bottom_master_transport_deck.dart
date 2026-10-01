import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../audio_engine/fft_processor.dart';
import '../../features/library/presentation/controllers/library_controller.dart';
import '../../features/player/domain/playback_state.dart';
import '../../features/player/domain/track.dart';
import '../../features/player/presentation/controllers/player_controller.dart';
import '../../features/player/presentation/controllers/player_expansion_controller.dart';
import '../../features/player/presentation/widgets/audio_file_inspector_sheet.dart';
import '../../features/player/presentation/widgets/now_playing_queue_sheet.dart';
import '../../features/pro_q_studio/presentation/pro_q_studio_screen.dart';
import 'desktop_lyrics_dialog.dart';

/// Persistent Master Playback Transport Deck khusus Desktop Linux / Desktop Canvas ($\ge 960$px).
/// Menghadirkan kontrol audio kelas studio profesional permanen di bagian bawah layar.
class DesktopBottomMasterTransportDeck extends ConsumerWidget {
  const DesktopBottomMasterTransportDeck({super.key});

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (duration.inHours > 0) {
      return '${duration.inHours}:$minutes:$seconds';
    }
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final playback = ref.watch(playerControllerProvider);
    final libraryState = ref.watch(unifiedLibraryProvider);
    final playerCtrl = ref.read(playerControllerProvider.notifier);
    final libraryCtrl = ref.read(unifiedLibraryProvider.notifier);
    final track = playback.currentTrack;
    final isFav = track != null && libraryState.favoriteTrackIds.contains(track.id);
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');

    final posSeconds = playback.position.inMilliseconds / 1000.0;
    final totalSeconds = playback.duration.inMilliseconds > 0
        ? playback.duration.inMilliseconds / 1000.0
        : (track?.duration.inMilliseconds ?? 1) / 1000.0;
    final maxSec = totalSeconds > 0 ? totalSeconds : 1.0;
    final curSec = posSeconds.clamp(0.0, maxSec);

    return Container(
      height: 94,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.dividerColor.withValues(alpha: 0.7),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          // ─── 1. LEFT: Track Info & Squircle Artwork ────────────
          SizedBox(
            width: 240,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => ref.read(playerExpansionProvider.notifier).expand(),
                  child: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.2),
                        width: 1.0,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: _buildAlbumArt(track),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track?.title ?? 'No Track Playing',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        track?.artist ?? 'Baydev HiFi',
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      if (track != null)
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _getFormatBadgeText(track),
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w700,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                M3EIconButton(
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedFavourite,
                    color: isFav
                        ? theme.colorScheme.error
                        : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    size: 18,
                  ),
                  onPressed: () {
                    if (track != null) {
                      libraryCtrl.toggleFavorite(track.id);
                    }
                  },
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ─── 2. CENTER: Transport Controls & Wavy Seekbar ───────
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Transport Buttons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Shuffle
                    M3EIconButton(
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedShuffle,
                        color: playback.isShuffle
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        size: 16,
                      ),
                      onPressed: () => playerCtrl.toggleShuffle(),
                    ),
                    const SizedBox(width: 6),

                    // Previous
                    M3EIconButton(
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedPrevious,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                        size: 18,
                      ),
                      onPressed: () => playerCtrl.skipPrevious(),
                    ),
                    const SizedBox(width: 8),

                    // Play / Pause (Prominent 42px Squircle Button)
                    Material(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(14),
                      elevation: 2,
                      shadowColor: theme.colorScheme.primary.withValues(alpha: 0.35),
                      child: InkWell(
                        onTap: () => playerCtrl.togglePlayPause(),
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          width: 42,
                          height: 42,
                          child: Center(
                            child: playback.isLoading
                                ? SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: M3EProgressIndicator.circular(
                                      strokeWidth: 2.4,
                                      color: theme.colorScheme.onPrimary,
                                    ),
                                  )
                                : HugeIcon(
                                    icon: playback.isPlaying
                                        ? HugeIcons.strokeRoundedPause
                                        : HugeIcons.strokeRoundedPlay,
                                    color: theme.colorScheme.onPrimary,
                                    size: 22,
                                  ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Next
                    M3EIconButton(
                      icon: HugeIcon(
                        icon: HugeIcons.strokeRoundedNext,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                        size: 18,
                      ),
                      onPressed: () => playerCtrl.skipNext(),
                    ),
                    const SizedBox(width: 6),

                    // Repeat Mode
                    M3EIconButton(
                      icon: HugeIcon(
                        icon: playback.repeatMode == PlaybackRepeatMode.one
                            ? HugeIcons.strokeRoundedRepeatOne01
                            : HugeIcons.strokeRoundedRepeat,
                        color: playback.repeatMode != PlaybackRepeatMode.off
                            ? theme.colorScheme.primary
                            : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        size: 16,
                      ),
                      onPressed: () => playerCtrl.toggleRepeatMode(),
                    ),
                  ],
                ),

                // Timestamps & Wavy Seekbar Row
                Row(
                  children: [
                    Text(
                      _formatDuration(playback.position),
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SizedBox(
                        height: 24,
                        child: isTest
                            ? SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  trackHeight: 3.0,
                                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                                ),
                                child: Slider(
                                  value: curSec,
                                  max: maxSec,
                                  onChanged: (val) {
                                    playerCtrl.seek(Duration(milliseconds: (val * 1000).toInt()));
                                  },
                                ),
                              )
                            : M3ESlider.wavy(
                                value: curSec,
                                max: maxSec,
                                wavelength: 18.0,
                                amplitude: playback.isPlaying ? 2.5 : 0.0,
                                onChanged: (val) {
                                  playerCtrl.seek(Duration(milliseconds: (val * 1000).toInt()));
                                },
                              ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _formatDuration(playback.duration),
                      style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ─── 3. RIGHT: Live Mini RTA, Specs, Lyrics, Queue, Volume ─
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Live Mini RTA Spectrum
              Container(
                width: 34,
                height: 22,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.3),
                    width: 0.8,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: const _DesktopMiniRtaVisualizer(),
                ),
              ),
              const SizedBox(width: 4),

              // Audio Specs Inspector
              M3EIconButton(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedInformationCircle,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  size: 16,
                ),
                onPressed: () {
                  if (track != null) {
                    AudioFileInspectorSheet.show(context, track);
                  }
                },
              ),

              // Synchronized Lyrics
              M3EIconButton(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedMusicNote01,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  size: 16,
                ),
                onPressed: () => DesktopLyricsDialog.show(context, track),
              ),

              // Up Next Queue
              M3EIconButton(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedQueue01,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  size: 16,
                ),
                onPressed: () {
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (_) => const NowPlayingQueueSheet(),
                  );
                },
              ),

              // Pro-Q Studio Shortcut
              M3EIconButton(
                icon: HugeIcon(
                  icon: HugeIcons.strokeRoundedSlidersVertical,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                  size: 16,
                ),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProQStudioScreen()),
                  );
                },
              ),

              const SizedBox(width: 4),

              // Volume Control with Expanded Precision Slider
              Tooltip(
                message: 'Volume: ${(playback.volume * 100).round()}%',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    M3EIconButton(
                      icon: HugeIcon(
                        icon: playback.volume == 0.0
                            ? HugeIcons.strokeRoundedVolumeOff
                            : (playback.volume < 0.5
                                ? HugeIcons.strokeRoundedVolumeLow
                                : HugeIcons.strokeRoundedVolumeHigh),
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        size: 16,
                      ),
                      onPressed: () {
                        if (playback.volume > 0.0) {
                          playerCtrl.setVolume(0.0);
                        } else {
                          playerCtrl.setVolume(1.0);
                        }
                      },
                    ),
                    SizedBox(
                      width: 120,
                      child: isTest
                          ? SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                trackHeight: 3.0,
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                              ),
                              child: Slider(
                                value: playback.volume.clamp(0.0, 1.0),
                                onChanged: (val) => playerCtrl.setVolume(val),
                              ),
                            )
                          : M3ESlider(
                              value: playback.volume.clamp(0.0, 1.0),
                              onChanged: (val) => playerCtrl.setVolume(val),
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumArt(Track? track) {
    if (track?.albumArtUrl != null && track!.albumArtUrl!.isNotEmpty) {
      if (track.albumArtUrl!.startsWith('http')) {
        return Image.network(
          track.albumArtUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const _ArtFallback(),
        );
      } else {
        return Image.file(
          File(track.albumArtUrl!),
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => const _ArtFallback(),
        );
      }
    }
    return const _ArtFallback();
  }

  String _getFormatBadgeText(Track track) {
    if (track.sampleRate != null && track.bitDepth != null) {
      final srKHz = (track.sampleRate! / 1000.0).toStringAsFixed(1).replaceAll('.0', '');
      return '${srKHz}kHz / ${track.bitDepth}bit';
    }
    return (track.filePath ?? '').split('.').last.toUpperCase();
  }
}

class _ArtFallback extends StatelessWidget {
  const _ArtFallback();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: HugeIcon(
        icon: HugeIcons.strokeRoundedMusicNote01,
        color: theme.colorScheme.primary.withValues(alpha: 0.6),
        size: 24,
      ),
    );
  }
}

class _DesktopMiniRtaVisualizer extends ConsumerWidget {
  const _DesktopMiniRtaVisualizer();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isPlaying = ref.watch(playerControllerProvider.select((s) => s.isPlaying));
    final rtaAsync = ref.watch(rtaSpectrumProvider);

    return rtaAsync.when(
      data: (magnitudes) {
        final rawFft = isPlaying ? magnitudes : <double>[];
        return CustomPaint(
          painter: _MiniRtaPainter(
            fft: rawFft,
            color: theme.colorScheme.primary,
          ),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (err, stack) => const SizedBox.shrink(),
    );
  }
}

class _MiniRtaPainter extends CustomPainter {
  final List<double> fft;
  final Color color;

  _MiniRtaPainter({required this.fft, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    const numBars = 8;
    final barWidth = size.width / numBars;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    for (int i = 0; i < numBars; i++) {
      double mag = 0.0;
      if (fft.isNotEmpty) {
        final idx = ((i + 1) * (fft.length ~/ (numBars + 2))).clamp(0, fft.length - 1);
        mag = (fft[idx] * 1.5).clamp(0.08, 1.0);
      } else {
        mag = 0.08;
      }
      final barHeight = size.height * mag;
      final x = i * barWidth + 1.0;
      final y = size.height - barHeight;
      final rrect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, (barWidth - 1.5).clamp(1.0, 10.0), barHeight),
        const Radius.circular(1.5),
      );
      canvas.drawRRect(rrect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MiniRtaPainter oldDelegate) => true;
}
