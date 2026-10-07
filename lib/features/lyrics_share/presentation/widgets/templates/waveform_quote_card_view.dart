import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../../core/lyrics/east_asian_romanizer.dart';
import '../../../../../core/widgets/studio_artwork_widget.dart';
import '../../../domain/models/lyric_card_theme.dart';
import '../../../domain/models/lyric_share_config.dart';
import '../components/audiophile_telemetry_stamp.dart';
import '../components/lyric_sticker_badge.dart';

/// Template 4: Waveform Timeline Studio Lyric Card View
class WaveformQuoteCardView extends StatelessWidget {
  final LyricShareConfig config;
  final LyricCardColors colors;
  final double scale;
  final bool isLandscape;

  const WaveformQuoteCardView({
    super.key,
    required this.config,
    required this.colors,
    required this.scale,
    this.isLandscape = false,
  });

  String _formatDuration(Duration d) {
    final mins = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final secs = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$mins:$secs';
  }

  @override
  Widget build(BuildContext context) {
    final track = config.track;
    final lines = config.selectedLines;

    Duration startDur = Duration.zero;
    Duration endDur = track.duration;
    if (lines.isNotEmpty) {
      startDur = lines.first.timestamp;
      endDur = lines.last.timestamp + const Duration(seconds: 4);
    }

    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        borderRadius: BorderRadius.circular(20 * scale),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Waveform HUD Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 4 * scale),
                decoration: BoxDecoration(
                  color: colors.surfaceColor,
                  borderRadius: BorderRadius.circular(6 * scale),
                  border: Border.all(color: colors.borderColor, width: 0.8 * scale),
                ),
                child: Row(
                  children: [
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedAudioWave01,
                      size: 13 * scale,
                      color: colors.accentColor,
                    ),
                    SizedBox(width: 5 * scale),
                    Text(
                      '${_formatDuration(startDur)} — ${_formatDuration(endDur)}',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: colors.primaryTextColor,
                        fontSize: 9.5 * scale,
                        fontWeight: FontWeight.w800,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
              if (config.selectedStickers.isNotEmpty)
                LyricStickerBadge(
                  sticker: config.selectedStickers.first,
                  scale: scale * 0.85,
                ),
            ],
          ),

          SizedBox(height: 12 * scale),

          // Waveform Graphic Visualizer
          _buildWaveformBars(scale),

          const Spacer(),

          // Centered Lyrics
          Expanded(
            flex: 8,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: config.textAlign == TextAlign.center
                    ? Alignment.center
                    : (config.textAlign == TextAlign.right ? Alignment.centerRight : Alignment.centerLeft),
                child: _buildLyricsContent(context),
              ),
            ),
          ),

          const Spacer(),

          if (config.audiophileStamp.hasAnyEnabled) ...[
            AudiophileTelemetryStamp(
              track: track,
              stampConfig: config.audiophileStamp,
              colors: colors,
              scale: scale * 0.9,
              isCompact: true,
            ),
            SizedBox(height: 8 * scale),
          ],

          // Footer
          _buildFooter(context, scale),
        ],
      ),
    );
  }

  Widget _buildWaveformBars(double scale) {
    const barHeights = [
      0.35, 0.65, 0.45, 0.85, 0.95, 0.60, 0.30, 0.55, 0.80, 1.00,
      0.75, 0.40, 0.65, 0.90, 0.85, 0.50, 0.35, 0.70, 0.90, 0.60,
      0.45, 0.75, 0.85, 0.55, 0.35, 0.65, 0.80, 0.95, 0.70, 0.40,
    ];

    return SizedBox(
      height: 24 * scale,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: barHeights.map((h) {
          return Container(
            width: 3.2 * scale,
            height: (24 * scale * h).clamp(4.0 * scale, 24.0 * scale),
            decoration: BoxDecoration(
              color: colors.accentColor.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(2 * scale),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLyricsContent(BuildContext context) {
    final lines = config.selectedLines;
    if (lines.isEmpty) return const SizedBox.shrink();

    final baseFontSize = (21.0 * scale * config.fontSizeMultiplier).clamp(14.0, 44.0);
    final fontFam = config.fontFamily.fontFamily;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: config.textAlign == TextAlign.center
          ? CrossAxisAlignment.center
          : (config.textAlign == TextAlign.right ? CrossAxisAlignment.end : CrossAxisAlignment.start),
      children: lines.map((line) {
        final text = line.text;
        final romanized = line.effectiveRomanized;
        final hasRom = line.hasRomanization || EastAsianRomanizer.needsRomanization(text);
        final effectiveRom = romanized.isNotEmpty ? romanized : EastAsianRomanizer.romanize(text);

        return Padding(
          padding: EdgeInsets.symmetric(vertical: 3.5 * scale * config.lineSpacingMultiplier),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: config.textAlign == TextAlign.center
                ? CrossAxisAlignment.center
                : (config.textAlign == TextAlign.right ? CrossAxisAlignment.end : CrossAxisAlignment.start),
            children: [
              Text(
                config.showRomanized && hasRom ? effectiveRom : text,
                textAlign: config.textAlign,
                style: TextStyle(
                  fontFamily: fontFam,
                  fontSize: baseFontSize,
                  fontWeight: config.fontWeight,
                  fontStyle: config.isItalic ? FontStyle.italic : FontStyle.normal,
                  color: colors.primaryTextColor,
                  letterSpacing: config.letterSpacing,
                  height: 1.25,
                ),
              ),
              if (config.showDualLineRomanized && hasRom && !config.showRomanized) ...[
                SizedBox(height: 2.0 * scale),
                Text(
                  effectiveRom,
                  textAlign: config.textAlign,
                  style: TextStyle(
                    fontFamily: fontFam,
                    fontSize: baseFontSize * 0.68,
                    fontWeight: FontWeight.w500,
                    color: colors.accentColor.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildFooter(BuildContext context, double scale) {
    final track = config.track;

    return Row(
      children: [
        if (config.showArtwork) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(8 * scale),
            child: StudioArtworkWidget(
              track: track,
              width: 38 * scale,
              height: 38 * scale,
              fit: BoxFit.cover,
            ),
          ),
          SizedBox(width: 8 * scale),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                track.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.primaryTextColor,
                  fontSize: 12 * scale,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${track.artist} • ${track.album}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.secondaryTextColor,
                  fontSize: 9.5 * scale,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
