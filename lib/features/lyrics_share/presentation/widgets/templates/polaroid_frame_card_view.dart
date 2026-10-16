import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/lyrics/east_asian_romanizer.dart';
import '../../../../../core/widgets/studio_artwork_widget.dart';
import '../../../../player/domain/track.dart';
import '../../../domain/models/lyric_card_theme.dart';
import '../../../domain/models/lyric_share_config.dart';
import '../components/audiophile_telemetry_stamp.dart';
import '../components/lyric_qr_link_badge.dart';
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
            // Top Branding & Specs Bar
            if (config.showBranding || config.showAudioSpecsBadge) ...[
              _buildHeader(scale),
              SizedBox(height: 4 * scale),
            ],

            // Main Content: 2-Column Side-by-Side in Landscape Mode
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Left: Polaroid Photo Unit
                  AspectRatio(
                    aspectRatio: 0.84,
                    child: _buildPolaroidPhotoCard(track, scale, isLandscapeLayout: true),
                  ),

                  SizedBox(width: 12 * scale),

                  // Right: Lyrics Quote, Personal Note & QR Code
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: config.textAlign == TextAlign.center
                                  ? Alignment.center
                                  : (config.textAlign == TextAlign.right
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft),
                              child: _buildLyricsContent(context),
                            ),
                          ),
                        ),
                        if (config.personalNote != null && config.personalNote!.trim().isNotEmpty) ...[
                          SizedBox(height: 3 * scale),
                          Text(
                            '— “${config.personalNote!.trim()}”',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            textAlign: config.textAlign,
                            style: TextStyle(
                              color: colors.accentColor,
                              fontSize: (8.5 * scale).clamp(7.0, 13.0),
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        if (config.showQrCode) ...[
                          SizedBox(height: 3 * scale),
                          Align(
                            alignment: Alignment.centerRight,
                            child: LyricQrLinkBadge(
                              track: track,
                              colors: colors,
                              scale: scale * 0.70,
                              size: 26,
                            ),
                          ),
                        ],
                      ],
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
        children: [
          // Optional Top Branding / Specs Bar
          if (config.showBranding || config.showAudioSpecsBadge) ...[
            _buildHeader(scale),
            SizedBox(height: 8 * scale),
          ],

          // Top Polaroid Frame Unit
          Expanded(
            flex: 7,
            child: _buildPolaroidPhotoCard(track, scale, isLandscapeLayout: false),
          ),

          SizedBox(height: 8 * scale),

          // Lower Section: Lyrics Quotes, Note & QR
          Expanded(
            flex: 5,
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Center(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: config.textAlign == TextAlign.center
                                ? Alignment.center
                                : (config.textAlign == TextAlign.right
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft),
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
                            fontSize: (9.5 * scale).clamp(8.0, 15.0),
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (config.showQrCode) ...[
                  SizedBox(width: 8 * scale),
                  LyricQrLinkBadge(
                    track: track,
                    colors: colors,
                    scale: scale * 0.82,
                    size: 34,
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

  Widget _buildHeader(double scale) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (config.showBranding)
          Flexible(
            flex: 5,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.camera,
                  size: (11 * scale).clamp(9.0, 16.0),
                  color: colors.accentColor,
                ),
                SizedBox(width: 4 * scale),
                Flexible(
                  child: Text(
                    'BAYDEV HIFI',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: colors.primaryTextColor,
                      fontSize: (8.0 * scale).clamp(6.5, 12.0),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          const SizedBox.shrink(),
        if (config.showAudioSpecsBadge)
          Flexible(
            flex: 5,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 5 * scale, vertical: 2 * scale),
              decoration: BoxDecoration(
                color: colors.surfaceColor,
                borderRadius: BorderRadius.circular(4 * scale),
                border: Border.all(color: colors.borderColor, width: 0.6 * scale),
              ),
              child: Text(
                config.customAudioSpec ?? 'STUDIO MASTER',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'monospace',
                  color: colors.badgeTextColor,
                  fontSize: (7.0 * scale).clamp(6.0, 11.0),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildPolaroidPhotoCard(Track track, double scale, {required bool isLandscapeLayout}) {
    final pad = (isLandscapeLayout ? 6.0 * scale : 10.0 * scale).clamp(5.0, 14.0);
    final bottomPad = (isLandscapeLayout ? 8.0 * scale : 16.0 * scale).clamp(6.0, 20.0);

    return Container(
      padding: EdgeInsets.fromLTRB(pad, pad, pad, bottomPad),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(10 * scale),
        border: Border.all(
          color: colors.borderColor.withValues(alpha: 0.6),
          width: 0.8 * scale,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 10 * scale,
            offset: Offset(0, 2 * scale),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Photo Section with Artwork & Sticker
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5 * scale),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  StudioArtworkWidget(
                    track: track,
                    fit: BoxFit.cover,
                  ),
                  if (config.selectedStickers.isNotEmpty)
                    Positioned(
                      top: 4 * scale,
                      right: 4 * scale,
                      child: LyricStickerBadge(
                        sticker: config.selectedStickers.first,
                        scale: scale * 0.80,
                      ),
                    ),
                ],
              ),
            ),
          ),
          SizedBox(height: (isLandscapeLayout ? 4.0 * scale : 8.0 * scale).clamp(3.0, 10.0)),
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
                    fontSize: (isLandscapeLayout ? 8.5 * scale : 10.0 * scale).clamp(7.0, 14.0),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
              SizedBox(width: 4 * scale),
              Flexible(
                child: Text(
                  track.artist,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.secondaryTextColor,
                    fontSize: (isLandscapeLayout ? 7.5 * scale : 9.0 * scale).clamp(6.0, 12.0),
                    fontWeight: FontWeight.w600,
                  ),
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
