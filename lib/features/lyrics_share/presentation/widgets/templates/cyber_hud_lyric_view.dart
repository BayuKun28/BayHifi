import 'package:flutter/material.dart';
import '../../../../../core/lyrics/east_asian_romanizer.dart';
import '../../../../../core/widgets/studio_artwork_widget.dart';
import '../../../domain/models/lyric_card_theme.dart';
import '../../../domain/models/lyric_share_config.dart';
import '../components/audiophile_telemetry_stamp.dart';
import '../components/lyric_sticker_badge.dart';

/// Template 5: CyberSpec Studio HUD Lyric View
class CyberHudLyricView extends StatelessWidget {
  final LyricShareConfig config;
  final LyricCardColors colors;
  final double scale;
  final bool isLandscape;

  const CyberHudLyricView({
    super.key,
    required this.config,
    required this.colors,
    required this.scale,
    this.isLandscape = false,
  });

  @override
  Widget build(BuildContext context) {
    final track = config.track;

    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.all(16 * scale),
      decoration: BoxDecoration(
        color: const Color(0xFF090C12),
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(
          color: colors.accentColor.withValues(alpha: 0.6),
          width: 1.2 * scale,
        ),
      ),
      child: Stack(
        children: [
          // Corner Tech Brackets
          Positioned(
            top: 0,
            left: 0,
            child: Text(
              '┌──[ 0x7F ]',
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: TextStyle(
                fontFamily: 'monospace',
                color: colors.accentColor.withValues(alpha: 0.7),
                fontSize: 8.5 * scale,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Text(
              '[ SYNC ]──┐',
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: TextStyle(
                fontFamily: 'monospace',
                color: colors.accentColor.withValues(alpha: 0.7),
                fontSize: 8.5 * scale,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            child: Text(
              '└──[ HIFI ]',
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: TextStyle(
                fontFamily: 'monospace',
                color: colors.accentColor.withValues(alpha: 0.7),
                fontSize: 8.5 * scale,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: Text(
              '[ DSP ]──┘',
              maxLines: 1,
              overflow: TextOverflow.clip,
              style: TextStyle(
                fontFamily: 'monospace',
                color: colors.accentColor.withValues(alpha: 0.7),
                fontSize: 8.5 * scale,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 14 * scale),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (config.selectedStickers.isNotEmpty) ...[
                  Wrap(
                    spacing: 6.0 * scale,
                    runSpacing: 4.0 * scale,
                    children: config.selectedStickers
                        .map((s) => LyricStickerBadge(sticker: s, scale: scale * 0.85, angle: 0))
                        .toList(),
                  ),
                  SizedBox(height: 8 * scale),
                ],

                const Spacer(),

                // Center Monospace / Bold Lyrics
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
                Row(
                  children: [
                    if (config.showArtwork) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4 * scale),
                        child: StudioArtworkWidget(
                          track: track,
                          width: 36 * scale,
                          height: 36 * scale,
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
                            '> ${track.title.toUpperCase()}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              color: colors.primaryTextColor,
                              fontSize: 11 * scale,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            '// ${track.artist.toUpperCase()}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              color: colors.secondaryTextColor,
                              fontSize: 9 * scale,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLyricsContent(BuildContext context) {
    final lines = config.selectedLines;
    if (lines.isEmpty) return const SizedBox.shrink();

    final baseFontSize = (21.0 * scale * config.fontSizeMultiplier).clamp(14.0, 42.0);
    final fontFam = config.fontFamily.fontFamily ?? 'monospace';

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
                  letterSpacing: 0.3,
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
                    color: colors.accentColor,
                  ),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }
}
