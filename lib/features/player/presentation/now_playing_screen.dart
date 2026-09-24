import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../domain/track.dart';
import 'controllers/player_controller.dart';
import 'widgets/spectrum_visualizer.dart';

class NowPlayingScreen extends ConsumerStatefulWidget {
  final VoidCallback onOpenProQStudio;

  const NowPlayingScreen({
    super.key,
    required this.onOpenProQStudio,
  });

  @override
  ConsumerState<NowPlayingScreen> createState() => _NowPlayingScreenState();
}

class _NowPlayingScreenState extends ConsumerState<NowPlayingScreen> {
  Future<void> _pickAndPlayFile() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['mp3', 'flac', 'wav', 'ogg', 'opus', 'aac', 'm4a'],
    );

    if (files.isNotEmpty && files.first.path != null) {
      final file = files.first;
      final ext = file.extension?.toLowerCase() ?? '';

      AudioFormat format = AudioFormat.unknown;
      if (ext == 'flac') {
        format = AudioFormat.flac;
      } else if (ext == 'mp3') {
        format = AudioFormat.mp3;
      } else if (ext == 'wav') {
        format = AudioFormat.wav;
      } else if (ext == 'opus') {
        format = AudioFormat.opus;
      } else if (ext == 'ogg') {
        format = AudioFormat.ogg;
      }

      final track = Track(
        id: file.path!,
        title: file.name.replaceAll('.$ext', ''),
        artist: 'Local Audio',
        album: 'Offline Storage',
        duration: Duration.zero,
        filePath: file.path,
        format: format,
        sampleRate: format == AudioFormat.flac ? 96000 : 44100,
        bitDepth: format == AudioFormat.flac ? 24 : 16,
      );

      await ref.read(playerControllerProvider.notifier).playTrack(track);
    }
  }

  String _formatDuration(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final playback = ref.watch(playerControllerProvider);
    final track = playback.currentTrack;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BAYDEV HIFI',
                        style: AppTypography.badge(color: AppColors.amberEq),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Studio Audiophile Player',
                        style: AppTypography.subtitle(AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton.filledTonal(
                        onPressed: widget.onOpenProQStudio,
                        icon: const Icon(Icons.equalizer, size: 20),
                        tooltip: 'Buka Pro-Q Studio',
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.amberEq.withValues(alpha: 0.15),
                          foregroundColor: AppColors.amberEq,
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filledTonal(
                        onPressed: _pickAndPlayFile,
                        icon: const Icon(Icons.file_open, size: 20),
                        tooltip: 'Pilih File Audio Lokal',
                      ),
                    ],
                  ),
                ],
              ),
              const Spacer(),

              // Album Art with Ambient Glow
              Center(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.surfaceBorder, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: (playback.isPlaying ? AppColors.amberEq : Colors.black)
                            .withValues(alpha: 0.25),
                        blurRadius: 40,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(26),
                    child: Center(
                      child: Icon(
                        Icons.album,
                        size: 96,
                        color: playback.isPlaying
                            ? AppColors.amberEq
                            : AppColors.textMuted,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Title, Artist, & Hi-Res Badge
              Column(
                children: [
                  Text(
                    track?.title ?? 'Belum ada lagu yang diputar',
                    style: AppTypography.title(AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    track?.artist ?? 'Tekan tombol folder untuk memilih lagu',
                    style: AppTypography.body(AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  if (track != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: track.isHiRes
                            ? AppColors.amberEq.withValues(alpha: 0.15)
                            : AppColors.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: track.isHiRes
                              ? AppColors.amberEq.withValues(alpha: 0.6)
                              : AppColors.surfaceBorder,
                        ),
                      ),
                      child: Text(
                        track.hiResBadgeText,
                        style: AppTypography.badge(
                          color: track.isHiRes ? AppColors.amberEq : AppColors.textSecondary,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // RTA Spectrum Visualizer Bar
              const SpectrumVisualizer(height: 54),

              const SizedBox(height: 12),

              // Progress Bar & Duration
              Column(
                children: [
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 3,
                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                    ),
                    child: Slider(
                      value: playback.duration.inMilliseconds > 0
                          ? playback.position.inMilliseconds /
                              playback.duration.inMilliseconds
                          : 0.0,
                      onChanged: (val) {
                        final newMs = (val * playback.duration.inMilliseconds).toInt();
                        ref
                            .read(playerControllerProvider.notifier)
                            .seek(Duration(milliseconds: newMs));
                      },
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _formatDuration(playback.position),
                          style: AppTypography.audioValue(color: AppColors.textSecondary),
                        ),
                        Text(
                          _formatDuration(playback.duration),
                          style: AppTypography.audioValue(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Playback Controls Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: () {
                      final cur = playback.position;
                      final target = cur - const Duration(seconds: 10);
                      ref
                          .read(playerControllerProvider.notifier)
                          .seek(target < Duration.zero ? Duration.zero : target);
                    },
                    icon: const Icon(Icons.replay_10, size: 28),
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 16),
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.amberEq,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.amberEq.withValues(alpha: 0.4),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    child: IconButton(
                      iconSize: 38,
                      color: Colors.black,
                      onPressed: () => ref
                          .read(playerControllerProvider.notifier)
                          .togglePlayPause(),
                      icon: Icon(
                        playback.isPlaying ? Icons.pause : Icons.play_arrow,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    onPressed: () {
                      final cur = playback.position;
                      final target = cur + const Duration(seconds: 30);
                      ref.read(playerControllerProvider.notifier).seek(target);
                    },
                    icon: const Icon(Icons.forward_30, size: 28),
                    color: AppColors.textSecondary,
                  ),
                ],
              ),

              const Spacer(),

              // Pre-amp Gain & Volume Strip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Row(
                  children: [
                    Text(
                      'PRE-AMP',
                      style: AppTypography.badge(color: AppColors.amberEq),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${playback.preAmpDb >= 0 ? "+" : ""}${playback.preAmpDb.toStringAsFixed(1)} dB',
                      style: AppTypography.audioValue(
                        color: playback.preAmpDb > 0
                            ? AppColors.crimsonAlert
                            : AppColors.textPrimary,
                        fontSize: 11,
                      ),
                    ),
                    Expanded(
                      child: Slider(
                        value: playback.preAmpDb,
                        min: -18.0,
                        max: 6.0,
                        onChanged: (val) {
                          ref
                              .read(playerControllerProvider.notifier)
                              .setPreamp(val);
                        },
                      ),
                    ),
                    const VerticalDivider(width: 16, thickness: 1),
                    const Icon(Icons.volume_up, size: 16, color: AppColors.textSecondary),
                    SizedBox(
                      width: 90,
                      child: Slider(
                        value: playback.volume,
                        min: 0.0,
                        max: 1.0,
                        onChanged: (val) {
                          ref
                              .read(playerControllerProvider.notifier)
                              .setVolume(val);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
