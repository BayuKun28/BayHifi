import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../../core/utils/audio_file_inspector.dart';
import '../../domain/track.dart';

class AudioFileInspectorSheet extends ConsumerWidget {
  final Track track;

  const AudioFileInspectorSheet({super.key, required this.track});

  static Future<void> show(BuildContext context, Track track) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AudioFileInspectorSheet(track: track),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isSolid = ref.isSolidStyle;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surface(context, isSolid: isSolid),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: StudioSurfaceTheme.outline(context, isSolid: isSolid), width: 1.2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black87,
            blurRadius: 32,
            offset: Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── DRAG HANDLE ───────────────────────────────────────────────
            Center(
              child: Container(
                width: 38,
                height: 4.5,
                decoration: BoxDecoration(
                  color: StudioSurfaceTheme.outline(context, isSolid: isSolid),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ─── HEADER ───────────────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedAudioWaveform,
                      size: 20,
                      color: primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'AUDIO FILE INSPECTOR',
                      style: AppTypography.badge(color: primary),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: track.isHiRes
                        ? StudioSurfaceTheme.tintedContainer(
                            context,
                            const Color(0xFFFF9F0A),
                            isSolid: isSolid,
                            translucentAlpha: 0.15,
                            solidBlendAlpha: 0.18,
                          )
                        : StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: track.isHiRes
                          ? (isSolid ? theme.colorScheme.outline : const Color(0xFFFF9F0A).withValues(alpha: 0.6))
                          : StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    track.hiResBadgeText,
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      color: track.isHiRes
                          ? const Color(0xFFFF9F0A)
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ─── TRACK SUMMARY CARD ────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid), width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.title,
                    style: TextStyle(
                      color: theme.colorScheme.onSurface,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${track.artist} • ${track.album}',
                    style: TextStyle(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontSize: 11.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // ─── TECHNICAL DETAILS ASYNC LOADER ────────────────────────────
            Expanded(
              child: FutureBuilder<AudioTechnicalDetails>(
                future: AudioFileInspector.inspectTrack(track),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData) {
                    return Center(
                      child: Text(
                        'Failed to inspect file: ${snapshot.error}',
                        style: TextStyle(color: theme.colorScheme.error, fontSize: 12),
                      ),
                    );
                  }

                  final data = snapshot.data!;

                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ─── METADATA TAGS SECTION ───
                        Row(
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedTag01,
                              size: 14,
                              color: primary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'METADATA TAGS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                                color: primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildInspectorRow(
                          context,
                          isSolid,
                          'Title',
                          track.title,
                          'Track Name',
                          HugeIcons.strokeRoundedMusicNote01,
                        ),
                        const SizedBox(height: 8),
                        _buildInspectorRow(
                          context,
                          isSolid,
                          'Artist',
                          track.artist,
                          'Performer / Band',
                          HugeIcons.strokeRoundedUser,
                        ),
                        const SizedBox(height: 8),
                        _buildInspectorRow(
                          context,
                          isSolid,
                          'Album',
                          track.album,
                          'Release Collection',
                          HugeIcons.strokeRoundedAlbum01,
                        ),
                        const SizedBox(height: 8),
                        _buildInspectorRow(
                          context,
                          isSolid,
                          'Genre & Year',
                          '${track.genre ?? "Unknown Genre"}${track.year != null ? " • ${track.year}" : ""}',
                          'Musical Classification',
                          HugeIcons.strokeRoundedSparkles,
                        ),
                        const SizedBox(height: 8),
                        _buildInspectorRow(
                          context,
                          isSolid,
                          'Duration & Track #',
                          '${track.duration.inMinutes}:${(track.duration.inSeconds % 60).toString().padLeft(2, '0')}${track.trackNumber != null ? " • Track #${track.trackNumber}" : ""}',
                          'Playback Length',
                          HugeIcons.strokeRoundedClock01,
                        ),
                        const SizedBox(height: 16),

                        // ─── TECHNICAL SPECS SECTION ───
                        Row(
                          children: [
                            HugeIcon(
                              icon: HugeIcons.strokeRoundedCpu,
                              size: 14,
                              color: const Color(0xFF00E5FF),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'TECHNICAL AUDIO SPECIFICATIONS',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.6,
                                color: Color(0xFF00E5FF),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _buildInspectorRow(
                          context,
                          isSolid,
                          'Container / Codec',
                          data.containerFormat,
                          data.codecProfile,
                          HugeIcons.strokeRoundedAlbum01,
                        ),
                        const SizedBox(height: 8),
                        _buildInspectorRow(
                          context,
                          isSolid,
                          'Sample Rate',
                          '${data.sampleRate} Hz (${(data.sampleRate / 1000).toStringAsFixed(1)} kHz)',
                          data.sampleRate >= 88200 ? 'Studio Master Hi-Res' : 'CD Quality Baseline',
                          HugeIcons.strokeRoundedAudioWaveform,
                        ),
                        const SizedBox(height: 8),
                        _buildInspectorRow(
                          context,
                          isSolid,
                          'Bit Depth & Channels',
                          '${data.bitDepth}-bit • ${data.channels == 2 ? "Stereo (2.0)" : "Mono (1.0)"}',
                          '${data.bitDepth * 6.02} dB Dynamic Range',
                          HugeIcons.strokeRoundedSlidersVertical,
                        ),
                        const SizedBox(height: 8),
                        _buildInspectorRow(
                          context,
                          isSolid,
                          'Estimated Bitrate',
                          '${data.bitrateKbps} kbps',
                          data.isHiRes ? 'Hi-Res Lossless Audio' : 'Standard Lossy / Lossless Stream',
                          HugeIcons.strokeRoundedZap,
                        ),
                        const SizedBox(height: 8),
                        _buildInspectorRow(
                          context,
                          isSolid,
                          'File Size',
                          data.formattedFileSize,
                          data.isLocal ? 'Local Storage File' : 'Remote Network Stream',
                          HugeIcons.strokeRoundedFolder01,
                        ),
                        const SizedBox(height: 8),
                        _buildInspectorRow(
                          context,
                          isSolid,
                          'Magic Bytes Header',
                          data.magicBytesHex,
                          'ASCII: [${data.magicBytesAscii}]',
                          HugeIcons.strokeRoundedCpu,
                        ),
                        if (data.md5Checksum != null) ...[
                          const SizedBox(height: 8),
                          _buildCopyableRow(
                            context,
                            isSolid,
                            'MD5 Checksum',
                            data.md5Checksum!,
                            HugeIcons.strokeRoundedShieldEnergy,
                          ),
                        ],
                        const SizedBox(height: 8),
                        _buildCopyableRow(
                          context,
                          isSolid,
                          'Location / File Path',
                          data.location,
                          HugeIcons.strokeRoundedCompass01,
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInspectorRow(
    BuildContext context,
    bool isSolid,
    String title,
    String value,
    String subtitle,
    dynamic icon,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid), width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
              borderRadius: BorderRadius.circular(8),
            ),
            child: HugeIcon(icon: icon, size: 16, color: const Color(0xFF00E5FF)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyableRow(
    BuildContext context,
    bool isSolid,
    String title,
    String value,
    dynamic icon,
  ) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid), width: 0.8),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
              borderRadius: BorderRadius.circular(8),
            ),
            child: HugeIcon(icon: icon, size: 16, color: const Color(0xFFFFB74D)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontFamily: 'monospace',
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          M3EIconButton(
            variant: M3EIconButtonVariant.standard,
            icon: HugeIcon(
              icon: HugeIcons.strokeRoundedCopy01,
              size: 20,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            tooltip: 'Copy $title',
            onPressed: () {
              AppHaptics.lightImpact();
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('$title copied to clipboard'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

