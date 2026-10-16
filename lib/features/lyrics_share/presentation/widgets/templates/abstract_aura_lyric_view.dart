import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/lyrics/east_asian_romanizer.dart';
import '../../../../../core/widgets/studio_artwork_widget.dart';
import '../../../domain/models/lyric_card_theme.dart';
import '../../../domain/models/lyric_share_config.dart';
import '../components/audiophile_telemetry_stamp.dart';
import '../components/lyric_qr_link_badge.dart';
import '../components/lyric_sticker_badge.dart';

/// Template 6: Abstract Aura Harmonic Color Mesh Lyric View
class AbstractAuraLyricView extends StatelessWidget {
  final LyricShareConfig config;
  final LyricCardColors colors;
  final double scale;
  final bool isLandscape;

  const AbstractAuraLyricView({
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
      decoration: BoxDecoration(
        color: colors.backgroundColor,
        borderRadius: BorderRadius.circular(24 * scale),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.accentColor.withValues(alpha: 0.35),
            colors.surfaceColor.withValues(alpha: 0.55),
            colors.backgroundColor,
          ],
          stops: const [0.0, 0.45, 1.0],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(16 * scale),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (config.showBranding)
                  Flexible(
                    flex: 5,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 4 * scale),
                      decoration: BoxDecoration(
                        color: colors.backgroundColor.withValues(alpha: 0.75),
                        borderRadius: BorderRadius.circular(20 * scale),
                        border: Border.all(color: colors.borderColor, width: 0.8 * scale),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            LucideIcons.sun,
                            size: 13 * scale,
                            color: colors.accentColor,
                          ),
                          SizedBox(width: 5 * scale),
                          Flexible(
                            child: Text(
                              'SONIC AURA // 2026',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.primaryTextColor,
                                fontSize: 9 * scale,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                Flexible(
                  flex: 6,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (config.showAudioSpecsBadge) ...[
                        Flexible(
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 3 * scale),
                            decoration: BoxDecoration(
                              color: colors.backgroundColor.withValues(alpha: 0.75),
                              borderRadius: BorderRadius.circular(6 * scale),
                              border: Border.all(color: colors.borderColor, width: 0.6 * scale),
                            ),
                            child: Text(
                              config.customAudioSpec ?? 'STUDIO MASTER',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                color: colors.badgeTextColor,
                                fontSize: 7.5 * scale,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 6 * scale),
                      ],
                      if (config.selectedStickers.isNotEmpty)
                        LyricStickerBadge(
                          sticker: config.selectedStickers.first,
                          scale: scale * 0.85,
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const Spacer(),

            // Centered Lyrics with Frosted Text Pill Backing
            Expanded(
              flex: 8,
              child: Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: config.textAlign == TextAlign.center
                      ? Alignment.center
                      : (config.textAlign == TextAlign.right ? Alignment.centerRight : Alignment.centerLeft),
                  child: Container(
                    padding: EdgeInsets.all(14 * scale),
                    decoration: BoxDecoration(
                      color: colors.backgroundColor.withValues(alpha: 0.82),
                      borderRadius: BorderRadius.circular(16 * scale),
                      border: Border.all(
                        color: colors.borderColor.withValues(alpha: 0.5),
                        width: 0.8 * scale,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 16 * scale,
                          offset: Offset(0, 4 * scale),
                        ),
                      ],
                    ),
                    child: _buildLyricsContent(context),
                  ),
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

            // Footer Track Info & QR
            Row(
              children: [
                if (config.showArtwork) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10 * scale),
                    child: StudioArtworkWidget(
                      track: track,
                      width: 40 * scale,
                      height: 40 * scale,
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
                if (config.showQrCode) ...[
                  SizedBox(width: 8 * scale),
                  LyricQrLinkBadge(
                    track: track,
                    colors: colors,
                    scale: scale * 0.82,
                    size: 32,
                  ),
                ],
              ],
            ),
          ],
        ),
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
                    color: colors.accentColor.withValues(alpha: 0.95),
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
