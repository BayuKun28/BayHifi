import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/lyrics/east_asian_romanizer.dart';
import '../../../../../core/widgets/studio_artwork_widget.dart';
import '../../../domain/models/lyric_card_theme.dart';
import '../../../domain/models/lyric_share_config.dart';
import '../components/audiophile_telemetry_stamp.dart';
import '../components/lyric_qr_link_badge.dart';
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
    final spineTitle = config.showBranding ? 'BAYDEV C-90 // STEREO' : 'CASSETTE C-90 // STEREO';
    final tapeSpec = config.showAudioSpecsBadge
        ? (config.customAudioSpec ?? 'TYPE II CHROME')
        : 'TYPE II CHROME';

    if (isLandscape) {
      return Container(
        width: double.infinity,
        height: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: (12 * scale).clamp(8.0, 18.0),
          vertical: (8 * scale).clamp(6.0, 14.0),
        ),
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
            // Cassette Header Spine (Compact)
            _buildSpine(scale, spineTitle, tapeSpec),

            SizedBox(height: 6 * scale),

            // Side-by-Side 2-Column Unfolded J-Card Layout
            Expanded(
              child: Row(
                children: [
                  // Left Column: Artwork + Track Details
                  Expanded(
                    flex: 7,
                    child: Container(
                      padding: EdgeInsets.all(6 * scale),
                      decoration: BoxDecoration(
                        color: colors.surfaceColor.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8 * scale),
                        border: Border.all(color: colors.borderColor.withValues(alpha: 0.4), width: 0.6 * scale),
                      ),
                      child: Row(
                        children: [
                          if (config.showArtwork) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6 * scale),
                              child: StudioArtworkWidget(
                                track: track,
                                width: (38 * scale).clamp(26.0, 52.0),
                                height: (38 * scale).clamp(26.0, 52.0),
                                fit: BoxFit.cover,
                              ),
                            ),
                            SizedBox(width: 6 * scale),
                          ],
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SIDE A',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    color: colors.accentColor,
                                    fontSize: (7.0 * scale).clamp(6.0, 10.0),
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  track.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    color: colors.primaryTextColor,
                                    fontSize: (9.0 * scale).clamp(7.5, 13.0),
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Text(
                                  track.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    color: colors.secondaryTextColor,
                                    fontSize: (7.5 * scale).clamp(6.5, 11.0),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(width: 8 * scale),

                  // Right Column: Lined Index Section with Lyrics & QR Code
                  Expanded(
                    flex: 12,
                    child: Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(6 * scale),
                      decoration: BoxDecoration(
                        color: colors.surfaceColor.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8 * scale),
                        border: Border.all(color: colors.borderColor.withValues(alpha: 0.5), width: 0.6 * scale),
                      ),
                      child: Row(
                        children: [
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
                          if (config.showQrCode) ...[
                            SizedBox(width: 6 * scale),
                            LyricQrLinkBadge(
                              track: track,
                              colors: colors,
                              scale: scale * 0.68,
                              size: 26,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            if (config.audiophileStamp.hasAnyEnabled) ...[
              SizedBox(height: 4 * scale),
              AudiophileTelemetryStamp(
                track: track,
                stampConfig: config.audiophileStamp,
                colors: colors,
                scale: scale * 0.80,
                isCompact: true,
              ),
            ],
          ],
        ),
      );
    }

    // Portrait Layout (1:1, 4:5, 9:16)
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: EdgeInsets.all((14 * scale).clamp(10.0, 20.0)),
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
          _buildSpine(scale, spineTitle, tapeSpec),

          if (config.selectedStickers.isNotEmpty) ...[
            SizedBox(height: 6 * scale),
            Wrap(
              spacing: 6.0 * scale,
              runSpacing: 4.0 * scale,
              children: config.selectedStickers.map((s) => LyricStickerBadge(sticker: s, scale: scale * 0.85)).toList(),
            ),
          ],

          SizedBox(height: 8 * scale),

          // Lined Index Section with Lyrics
          Expanded(
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(10 * scale),
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

          SizedBox(height: 8 * scale),

          // Lower Audio Telemetry
          if (config.audiophileStamp.hasAnyEnabled) ...[
            AudiophileTelemetryStamp(
              track: track,
              stampConfig: config.audiophileStamp,
              colors: colors,
              scale: scale * 0.9,
              isCompact: true,
            ),
            SizedBox(height: 6 * scale),
          ],

          // Footer Track Info & QR Link
          Row(
            children: [
              if (config.showArtwork) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(6 * scale),
                  child: StudioArtworkWidget(
                    track: track,
                    width: (32 * scale).clamp(22.0, 44.0),
                    height: (32 * scale).clamp(22.0, 44.0),
                    fit: BoxFit.cover,
                  ),
                ),
                SizedBox(width: 6 * scale),
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
                        fontSize: (9.5 * scale).clamp(7.5, 14.0),
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
                        fontSize: (8.0 * scale).clamp(6.5, 12.0),
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
          ),
        ],
      ),
    );
  }

  Widget _buildSpine(double scale, String spineTitle, String tapeSpec) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 3 * scale),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(6 * scale),
        border: Border.all(color: colors.borderColor, width: 0.6 * scale),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            flex: 6,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.disc,
                  size: (12 * scale).clamp(10.0, 18.0),
                  color: colors.accentColor,
                ),
                SizedBox(width: 4 * scale),
                Flexible(
                  child: Text(
                    spineTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: colors.primaryTextColor,
                      fontSize: (8.5 * scale).clamp(7.0, 12.0),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 4 * scale),
          Flexible(
            flex: 4,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4 * scale, vertical: 1.5 * scale),
              decoration: BoxDecoration(
                color: colors.accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4 * scale),
                border: Border.all(color: colors.accentColor, width: 0.6 * scale),
              ),
              child: Text(
                tapeSpec,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: colors.accentColor,
                  fontSize: (7.0 * scale).clamp(6.0, 10.0),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.4,
                ),
              ),
            ),
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
