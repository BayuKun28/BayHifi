import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../../app/theme/studio_surface_theme.dart';
import '../../../../player/domain/track.dart';
import '../../../domain/models/audiophile_stamp_config.dart';
import '../../../domain/models/lyric_card_theme.dart';

/// Studio Audiophile Telemetry Stamp component for Lyric Cards
class AudiophileTelemetryStamp extends StatelessWidget {
  final Track track;
  final AudiophileStampConfig stampConfig;
  final LyricCardColors colors;
  final double scale;
  final bool isCompact;

  const AudiophileTelemetryStamp({
    super.key,
    required this.track,
    required this.stampConfig,
    required this.colors,
    this.scale = 1.0,
    this.isCompact = false,
  });

  String _formatTimestamp(DateTime? dt) {
    if (dt == null) return '';
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    final day = dt.day.toString().padLeft(2, '0');
    final month = months[(dt.month - 1).clamp(0, 11)];
    final year = dt.year;
    final hour = dt.hour.toString().padLeft(2, '0');
    final min = dt.minute.toString().padLeft(2, '0');
    return '$day $month $year // $hour:$min';
  }

  @override
  Widget build(BuildContext context) {
    if (!stampConfig.hasAnyEnabled) return const SizedBox.shrink();

    final fontSize = (isCompact ? 8.0 : 8.5) * scale;
    final iconSize = (isCompact ? 10.0 : 11.0) * scale;

    final formatLabel = switch (track.format) {
      AudioFormat.flac => 'FLAC LOSSLESS',
      AudioFormat.wav => 'WAV PCM',
      AudioFormat.dsd => 'DSD MASTER',
      AudioFormat.alac => 'ALAC LOSSLESS',
      AudioFormat.opus => 'OPUS HD',
      AudioFormat.ogg => 'OGG VORBIS',
      AudioFormat.mp3 => 'MP3',
      _ => track.format.name.toUpperCase(),
    };

    final sampleRateKhz = ((track.sampleRate ?? 44100) / 1000.0).toStringAsFixed(1);
    final bitDepth = track.bitDepth ?? 16;
    final isHiRes = bitDepth >= 24 || (track.sampleRate ?? 0) >= 88200;

    final List<Widget> items = [];

    // 1. Audio Format & Bitrate
    if (stampConfig.showSignalChain) {
      items.add(
        _buildChip(
          icon: isHiRes ? HugeIcons.strokeRoundedShieldEnergy : HugeIcons.strokeRoundedMusicNote01,
          label: '$formatLabel $bitDepth-BIT / ${sampleRateKhz}kHz',
          highlight: isHiRes,
          fontSize: fontSize,
          iconSize: iconSize,
        ),
      );
    }

    // 2. AutoEQ Profile
    if (stampConfig.showAutoEq && stampConfig.autoEqProfileName != null && stampConfig.autoEqProfileName!.isNotEmpty) {
      items.add(
        _buildChip(
          icon: HugeIcons.strokeRoundedSlidersVertical,
          label: 'AUTOEQ: ${stampConfig.autoEqProfileName!.toUpperCase()}',
          fontSize: fontSize,
          iconSize: iconSize,
        ),
      );
    }

    // 3. Virtual DSP Units
    if (stampConfig.showDspUnits && stampConfig.dspProfileName != null && stampConfig.dspProfileName!.isNotEmpty) {
      items.add(
        _buildChip(
          icon: HugeIcons.strokeRoundedAudioWave01,
          label: 'DSP: ${stampConfig.dspProfileName!.toUpperCase()}',
          fontSize: fontSize,
          iconSize: iconSize,
        ),
      );
    }

    // 4. Hardware USB DAC Bridge
    if (stampConfig.showDacBridge && stampConfig.dacDeviceName != null && stampConfig.dacDeviceName!.isNotEmpty) {
      items.add(
        _buildChip(
          icon: HugeIcons.strokeRoundedCpu,
          label: 'DAC: ${stampConfig.dacDeviceName!.toUpperCase()}',
          fontSize: fontSize,
          iconSize: iconSize,
          highlight: true,
        ),
      );
    }

    // 5. Custom Gear Text
    if (stampConfig.customGearText != null && stampConfig.customGearText!.trim().isNotEmpty) {
      items.add(
        _buildChip(
          icon: HugeIcons.strokeRoundedHeadphones,
          label: stampConfig.customGearText!.trim().toUpperCase(),
          fontSize: fontSize,
          iconSize: iconSize,
        ),
      );
    }

    // 6. Listening Timestamp
    if (stampConfig.showTimestamp && stampConfig.timestamp != null) {
      items.add(
        _buildChip(
          icon: HugeIcons.strokeRoundedClock01,
          label: _formatTimestamp(stampConfig.timestamp),
          fontSize: fontSize,
          iconSize: iconSize,
        ),
      );
    }

    if (items.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 8.0 * scale,
        vertical: 4.0 * scale,
      ),
      decoration: BoxDecoration(
        color: colors.badgeBackgroundColor.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(8.0 * scale),
        border: Border.all(
          color: colors.borderColor.withValues(alpha: 0.6),
          width: 0.6 * scale,
        ),
      ),
      child: Wrap(
        spacing: 6.0 * scale,
        runSpacing: 4.0 * scale,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: items,
      ),
    );
  }

  Widget _buildChip({
    required dynamic icon,
    required String label,
    required double fontSize,
    required double iconSize,
    bool highlight = false,
  }) {
    final chipColor = highlight ? StudioCategoryColors.hiResGold : colors.secondaryTextColor;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        HugeIcon(
          icon: icon,
          size: iconSize,
          color: chipColor,
        ),
        SizedBox(width: 3.5 * scale),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: chipColor,
              fontSize: fontSize,
              fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
              letterSpacing: 0.3,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}
