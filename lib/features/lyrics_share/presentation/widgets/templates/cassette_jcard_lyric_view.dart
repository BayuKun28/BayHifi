import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../../core/lyrics/east_asian_romanizer.dart';
import '../../../../../core/widgets/studio_artwork_widget.dart';
import '../../../domain/models/lyric_card_theme.dart';
import '../../../domain/models/lyric_share_config.dart';
import '../components/audiophile_telemetry_stamp.dart';
import '../components/lyric_sticker_badge.dart';

/// Template 3: Cassette J-Card Analog Tape Lyric View
class CassetteJCardLyricView extends StatelessWidget {
  final LyricShareConfig config;
  final LyricCardColors colors;
  final double scale;
  final bool isLandscape;

  const CassetteJCardLyricView({
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
      padding: EdgeInsets.all(14 * scale),
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        borderRadius: BorderRadius.circular(20 * scale),
        border: Border.all(
          color: colors.borderColor.withValues(alpha: 0.8),
          width: 1.5 * scale,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cassette Header Spine
          Container(
            padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 6 * scale),
            decoration: BoxDecoration(
              color: colors.surfaceColor,
              borderRadius: BorderRadius.circular(8 * scale),
              border: Border.all(color: colors.borderColor, width: 0.8 * scale),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedAlbum01,
                        size: 16 * scale,
                        color: colors.accentColor,
                      ),
                      SizedBox(width: 6 * scale),
                      Expanded(
                        child: Text(
                          'BAYDEV C-90 // STEREO',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            color: colors.primaryTextColor,
                            fontSize: 9.5 * scale,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 6 * scale),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 2 * scale),
                  decoration: BoxDecoration(
                    color: colors.accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4 * scale),
                    border: Border.all(color: colors.accentColor, width: 0.6 * scale),
                  ),
                  child: Text(
                    'TYPE II CHROME',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: colors.accentColor,
                      fontSize: 8.0 * scale,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (config.selectedStickers.isNotEmpty) ...[
            SizedBox(height: 8 * scale),
            Wrap(
              spacing: 6.0 * scale,
              runSpacing: 4.0 * scale,
              children: config.selectedStickers.map((s) => LyricStickerBadge(sticker: s, scale: scale * 0.85)).toList(),
            ),
          ],

          SizedBox(height: 10 * scale),

          // Lined Index Section with Lyrics
          Expanded(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(12 * scale),
              decoration: BoxDecoration(
                color: colors.surfaceColor.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10 * scale),
                border: Border.all(color: colors.borderColor.withValues(alpha: 0.5), width: 0.6 * scale),
              ),
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
          ),

          SizedBox(height: 10 * scale),

          // Lower Audio Telemetry
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

          // Footer Track Info
          Row(
            children: [
              if (config.showArtwork) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8 * scale),
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
                      'SIDE A • ${track.title}',
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
                      '${track.artist} — ${track.album}',
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
    );
  }

  Widget _buildLyricsContent(BuildContext context) {
    final lines = config.selectedLines;
    if (lines.isEmpty) return const SizedBox.shrink();

    final baseFontSize = (19.0 * scale * config.fontSizeMultiplier).clamp(13.0, 38.0);
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
                  letterSpacing: 0.2,
                  height: 1.3,
                ),
              ),
              if (config.showDualLineRomanized && hasRom && !config.showRomanized) ...[
                SizedBox(height: 2.0 * scale),
                Text(
                  effectiveRom,
                  textAlign: config.textAlign,
                  style: TextStyle(
                    fontFamily: fontFam,
                    fontSize: baseFontSize * 0.7,
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
