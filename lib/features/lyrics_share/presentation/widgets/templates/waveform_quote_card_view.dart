import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/lyrics/east_asian_romanizer.dart';
import '../../../../../core/widgets/studio_artwork_widget.dart';
import '../../../domain/models/lyric_card_theme.dart';
import '../../../domain/models/lyric_share_config.dart';
import '../components/audiophile_telemetry_stamp.dart';
import '../components/lyric_qr_link_badge.dart';
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

    if (isLandscape) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: (14 * scale).clamp(10.0, 20.0),
          vertical: (8 * scale).clamp(6.0, 14.0),
        ),
        decoration: BoxDecoration(
          color: colors.backgroundColor,
          borderRadius: BorderRadius.circular(20 * scale),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Waveform HUD Header
            _buildHeader(scale, startDur, endDur),

            SizedBox(height: 4 * scale),

            // Compact Waveform Graphic Visualizer
            _buildWaveformBars(scale * 0.75),

            SizedBox(height: 4 * scale),

            // Centered Lyrics (Directly expanded without inflexible Spacers)
            Expanded(
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

            if (config.personalNote != null && config.personalNote!.trim().isNotEmpty) ...[
              SizedBox(height: 2 * scale),
              Center(
                child: Text(
                  '— “${config.personalNote!.trim()}”',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: config.textAlign,
                  style: TextStyle(
                    color: colors.accentColor,
                    fontSize: (8.5 * scale).clamp(7.0, 12.0),
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],

            if (config.audiophileStamp.hasAnyEnabled) ...[
              SizedBox(height: 3 * scale),
              AudiophileTelemetryStamp(
                track: track,
                stampConfig: config.audiophileStamp,
                colors: colors,
                scale: scale * 0.75,
                isCompact: true,
              ),
            ],

            SizedBox(height: 4 * scale),

            // Footer
            _buildFooter(context, scale * 0.85),
          ],
        ),
      );
    }

    // Portrait / Square Layout (1:1, 4:5, 9:16)
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.all((14 * scale).clamp(10.0, 20.0)),
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        borderRadius: BorderRadius.circular(20 * scale),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Waveform HUD Header
          _buildHeader(scale, startDur, endDur),

          SizedBox(height: 10 * scale),

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

          if (config.personalNote != null && config.personalNote!.trim().isNotEmpty) ...[
            SizedBox(height: 4 * scale),
            Center(
              child: Text(
                '— “${config.personalNote!.trim()}”',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: config.textAlign,
                style: TextStyle(
                  color: colors.accentColor,
                  fontSize: (9.5 * scale).clamp(8.0, 14.0),
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

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

  Widget _buildHeader(double scale, Duration startDur, Duration endDur) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          flex: 6,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (config.showBranding) ...[
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 4 * scale, vertical: 2 * scale),
                  decoration: BoxDecoration(
                    color: colors.surfaceColor,
                    borderRadius: BorderRadius.circular(4 * scale),
                    border: Border.all(color: colors.borderColor, width: 0.6 * scale),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.audioWaveform,
                        size: (10 * scale).clamp(8.0, 14.0),
                        color: colors.accentColor,
                      ),
                      SizedBox(width: 3 * scale),
                      Text(
                        'BAYDEV',
                        style: TextStyle(
                          fontFamily: 'monospace',
                          color: colors.primaryTextColor,
                          fontSize: (7.5 * scale).clamp(6.0, 10.0),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 3 * scale),
              ],
              Flexible(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 4 * scale, vertical: 2 * scale),
                  decoration: BoxDecoration(
                    color: colors.surfaceColor,
                    borderRadius: BorderRadius.circular(4 * scale),
                    border: Border.all(color: colors.borderColor, width: 0.6 * scale),
                  ),
                  child: Text(
                    '${_formatDuration(startDur)} — ${_formatDuration(endDur)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: colors.primaryTextColor,
                      fontSize: (7.5 * scale).clamp(6.0, 11.0),
                      fontWeight: FontWeight.w800,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 4 * scale),
        Flexible(
          flex: 4,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (config.showAudioSpecsBadge) ...[
                Flexible(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 4 * scale, vertical: 2 * scale),
                    decoration: BoxDecoration(
                      color: colors.surfaceColor,
                      borderRadius: BorderRadius.circular(4 * scale),
                      border: Border.all(color: colors.borderColor, width: 0.6 * scale),
                    ),
                    child: Text(
                      config.customAudioSpec ?? 'LOSSLESS',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: colors.badgeTextColor,
                        fontSize: (7.0 * scale).clamp(6.0, 10.0),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 3 * scale),
              ],
              if (config.selectedStickers.isNotEmpty)
                LyricStickerBadge(
                  sticker: config.selectedStickers.first,
                  scale: scale * 0.75,
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWaveformBars(double scale) {
    const barHeights = [
      0.35, 0.65, 0.45, 0.85, 0.95, 0.60, 0.30, 0.55, 0.80, 1.00,
      0.75, 0.40, 0.65, 0.90, 0.85, 0.50, 0.35, 0.70, 0.90, 0.60,
      0.45, 0.75, 0.85, 0.55, 0.35, 0.65, 0.80, 0.95, 0.70, 0.40,
    ];

    return SizedBox(
      height: (20 * scale).clamp(10.0, 26.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: barHeights.map((h) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: (1.0 * scale).clamp(0.5, 2.0)),
              child: Center(
                child: Container(
                  height: (20 * scale * h).clamp(3.0 * scale, 20.0 * scale),
                  decoration: BoxDecoration(
                    color: colors.accentColor.withValues(alpha: 0.75),
                    borderRadius: BorderRadius.circular(2 * scale),
                  ),
                ),
              ),
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
            borderRadius: BorderRadius.circular(6 * scale),
            child: StudioArtworkWidget(
              track: track,
              width: (34 * scale).clamp(24.0, 48.0),
              height: (34 * scale).clamp(24.0, 48.0),
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
                  fontSize: (11 * scale).clamp(8.5, 15.0),
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${track.artist} • ${track.album}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.secondaryTextColor,
                  fontSize: (9.0 * scale).clamp(7.0, 13.0),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        if (config.showQrCode) ...[
          SizedBox(width: 6 * scale),
          LyricQrLinkBadge(
            track: track,
            colors: colors,
            scale: scale * 0.75,
            size: 28,
          ),
        ],
      ],
    );
  }
}
