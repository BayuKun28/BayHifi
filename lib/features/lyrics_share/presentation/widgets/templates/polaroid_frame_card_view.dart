import 'package:flutter/material.dart';
import '../../../../../core/lyrics/east_asian_romanizer.dart';
import '../../../../../core/widgets/studio_artwork_widget.dart';
import '../../../domain/models/lyric_card_theme.dart';
import '../../../domain/models/lyric_share_config.dart';
import '../components/audiophile_telemetry_stamp.dart';
import '../components/lyric_sticker_badge.dart';

/// Template 2: Polaroid Frame Studio Lyric Card View
class PolaroidFrameCardView extends StatelessWidget {
  final LyricShareConfig config;
  final LyricCardColors colors;
  final double scale;
  final bool isLandscape;

  const PolaroidFrameCardView({
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
        color: colors.backgroundColor,
        borderRadius: BorderRadius.circular(20 * scale),
      ),
      child: Column(
        children: [
          // Top Polaroid Frame Unit
          Expanded(
            flex: isLandscape ? 10 : 7,
            child: Container(
              padding: EdgeInsets.fromLTRB(
                12 * scale,
                12 * scale,
                12 * scale,
                24 * scale,
              ),
              decoration: BoxDecoration(
                color: colors.surfaceColor,
                borderRadius: BorderRadius.circular(12 * scale),
                border: Border.all(
                  color: colors.borderColor.withValues(alpha: 0.6),
                  width: 0.8 * scale,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 14 * scale,
                    offset: Offset(0, 4 * scale),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Square Photo Section
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6 * scale),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          StudioArtworkWidget(
                            track: track,
                            fit: BoxFit.cover,
                          ),
                          if (config.selectedStickers.isNotEmpty)
                            Positioned(
                              top: 8 * scale,
                              right: 8 * scale,
                              child: LyricStickerBadge(
                                sticker: config.selectedStickers.first,
                                scale: scale * 0.9,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 10 * scale),
                  // Track title & artist in polaroid caption
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          track.title.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.primaryTextColor,
                            fontSize: 10.5 * scale,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      SizedBox(width: 6 * scale),
                      Flexible(
                        child: Text(
                          track.artist,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: colors.secondaryTextColor,
                            fontSize: 9.0 * scale,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 12 * scale),

          // Lower Section: Lyrics Quotes & Note
          Expanded(
            flex: isLandscape ? 6 : 5,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
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
                if (config.personalNote != null && config.personalNote!.trim().isNotEmpty) ...[
                  SizedBox(height: 4 * scale),
                  Text(
                    '— “${config.personalNote!.trim()}”',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: config.textAlign,
                    style: TextStyle(
                      color: colors.accentColor,
                      fontSize: 9.5 * scale,
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (config.audiophileStamp.hasAnyEnabled) ...[
            SizedBox(height: 6 * scale),
            AudiophileTelemetryStamp(
              track: track,
              stampConfig: config.audiophileStamp,
              colors: colors,
              scale: scale * 0.9,
              isCompact: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLyricsContent(BuildContext context) {
    final lines = config.selectedLines;
    if (lines.isEmpty) return const SizedBox.shrink();

    final baseFontSize = (20.0 * scale * config.fontSizeMultiplier).clamp(13.0, 42.0);
    final fontFam = config.fontFamily.fontFamily ?? 'serif';

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
          padding: EdgeInsets.symmetric(vertical: 3.0 * scale * config.lineSpacingMultiplier),
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
                    fontStyle: FontStyle.italic,
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
}
