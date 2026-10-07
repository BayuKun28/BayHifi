import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../../core/lyrics/east_asian_romanizer.dart';
import '../../../../../core/widgets/studio_artwork_widget.dart';
import '../../../../player/domain/track.dart';
import '../../../domain/models/lyric_card_theme.dart';
import '../../../domain/models/lyric_share_config.dart';
import '../components/audiophile_telemetry_stamp.dart';
import '../components/lyric_sticker_badge.dart';

/// Template 1: Classic Minimal Studio Card View
class ClassicMinimalCardView extends StatelessWidget {
  final LyricShareConfig config;
  final LyricCardColors colors;
  final double scale;
  final bool isLandscape;

  const ClassicMinimalCardView({
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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, scale),
          const SizedBox(height: 6),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 11,
                  child: Align(
                    alignment: config.textAlign == TextAlign.center
                        ? Alignment.center
                        : (config.textAlign == TextAlign.right ? Alignment.centerRight : Alignment.centerLeft),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: config.textAlign == TextAlign.center
                          ? Alignment.center
                          : (config.textAlign == TextAlign.right ? Alignment.centerRight : Alignment.centerLeft),
                      child: _buildLyricsContent(context),
                    ),
                  ),
                ),
                SizedBox(width: 14 * scale),
                Expanded(
                  flex: 8,
                  child: Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: _buildLandscapeTrackBadge(context, scale),
                    ),
                  ),
                ),
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
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Header
        _buildHeader(context, scale),

        if (config.selectedStickers.isNotEmpty) ...[
          SizedBox(height: 8 * scale),
          Wrap(
            spacing: 8.0 * scale,
            runSpacing: 6.0 * scale,
            children: config.selectedStickers.map((s) => LyricStickerBadge(sticker: s, scale: scale)).toList(),
          ),
        ],

        const Spacer(),

        // Center Lyrics Quote
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
          SizedBox(height: 6 * scale),
          Align(
            alignment: config.textAlign == TextAlign.center ? Alignment.center : Alignment.centerLeft,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 3.5 * scale),
              decoration: BoxDecoration(
                color: colors.badgeBackgroundColor.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(6 * scale),
              ),
              child: Text(
                '“${config.personalNote!.trim()}”',
                style: TextStyle(
                  color: colors.accentColor,
                  fontSize: 10 * scale,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],

        const Spacer(),

        // Audiophile Telemetry Stamp
        if (config.audiophileStamp.hasAnyEnabled) ...[
          AudiophileTelemetryStamp(
            track: track,
            stampConfig: config.audiophileStamp,
            colors: colors,
            scale: scale,
          ),
          SizedBox(height: 8 * scale),
        ],

        // Bottom Footer: Album Art & Track Meta
        _buildFooter(context, scale),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, double scale) {
    final formatLabel = switch (config.track.format) {
      AudioFormat.flac => 'FLAC',
      AudioFormat.wav => 'WAV',
      AudioFormat.dsd => 'DSD',
      AudioFormat.alac => 'ALAC',
      AudioFormat.opus => 'OPUS',
      AudioFormat.ogg => 'OGG',
      AudioFormat.mp3 => 'MP3',
      _ => config.track.format.name.toUpperCase(),
    };
    final audioSpecText = config.customAudioSpec ?? 'LOSSLESS MASTER • $formatLabel';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (config.showBranding)
          Flexible(
            flex: 5,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24 * scale,
                  height: 24 * scale,
                  decoration: BoxDecoration(
                    color: colors.badgeBackgroundColor,
                    borderRadius: BorderRadius.circular(7 * scale),
                    border: Border.all(color: colors.borderColor, width: 0.8),
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedAudioWave01,
                      size: 13 * scale,
                      color: colors.accentColor,
                    ),
                  ),
                ),
                SizedBox(width: 7 * scale),
                Flexible(
                  child: Text(
                    'BAYDEV HIFI',
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      color: colors.primaryTextColor,
                      fontSize: 9.5 * scale,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
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
            flex: 6,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 3.5 * scale),
              decoration: BoxDecoration(
                color: colors.badgeBackgroundColor,
                borderRadius: BorderRadius.circular(6 * scale),
                border: Border.all(color: colors.borderColor, width: 0.8),
              ),
              child: Text(
                audioSpecText,
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
                style: TextStyle(
                  color: colors.badgeTextColor,
                  fontSize: 8.5 * scale,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLyricsContent(BuildContext context) {
    final lines = config.selectedLines;
    if (lines.isEmpty) return const SizedBox.shrink();

    final baseFontSize = (22.0 * scale * config.fontSizeMultiplier).clamp(14.0, 48.0);
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
              _buildStyledText(
                text: config.showRomanized && hasRom ? effectiveRom : text,
                fontSize: baseFontSize,
                fontFam: fontFam,
                color: colors.primaryTextColor,
                scale: scale,
              ),
              if (config.showDualLineRomanized && hasRom && !config.showRomanized) ...[
                SizedBox(height: 2.0 * scale),
                _buildStyledText(
                  text: effectiveRom,
                  fontSize: baseFontSize * 0.68,
                  fontFam: fontFam,
                  color: colors.accentColor.withValues(alpha: 0.9),
                  scale: scale,
                  isSecondary: true,
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildStyledText({
    required String text,
    required double fontSize,
    required String? fontFam,
    required Color color,
    required double scale,
    bool isSecondary = false,
  }) {
    final style = TextStyle(
      fontFamily: fontFam,
      fontSize: fontSize,
      fontWeight: isSecondary ? FontWeight.w600 : config.fontWeight,
      fontStyle: config.isItalic ? FontStyle.italic : FontStyle.normal,
      color: color,
      letterSpacing: config.letterSpacing,
      height: 1.25,
      shadows: config.highlightStyle == LyricCardHighlightStyle.dropShadow
          ? [
              Shadow(
                color: Colors.black.withValues(alpha: 0.75),
                blurRadius: 10.0 * scale,
                offset: Offset(0, 2.0 * scale),
              ),
            ]
          : null,
    );

    if (config.highlightStyle == LyricCardHighlightStyle.stroke) {
      final strokeStyle = style.copyWith(
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = config.strokeWidth * scale
          ..color = colors.backgroundColor,
        color: null,
      );
      return Stack(
        alignment: config.textAlign == TextAlign.center
            ? Alignment.center
            : (config.textAlign == TextAlign.right ? Alignment.centerRight : Alignment.centerLeft),
        children: [
          Text(text, textAlign: config.textAlign, style: strokeStyle),
          Text(text, textAlign: config.textAlign, style: style),
        ],
      );
    }

    if (config.highlightStyle == LyricCardHighlightStyle.highlighterPill) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 6 * scale, vertical: 2 * scale),
        decoration: BoxDecoration(
          color: colors.backgroundColor.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(6 * scale),
        ),
        child: Text(text, textAlign: config.textAlign, style: style),
      );
    }

    return Text(text, textAlign: config.textAlign, style: style);
  }

  Widget _buildFooter(BuildContext context, double scale) {
    final track = config.track;

    return Row(
      children: [
        if (config.showArtwork) ...[
          Container(
            width: 44 * scale,
            height: 44 * scale,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10 * scale),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  blurRadius: 8 * scale,
                  offset: Offset(0, 3 * scale),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10 * scale),
              child: StudioArtworkWidget(
                track: track,
                fit: BoxFit.cover,
                width: 44 * scale,
                height: 44 * scale,
              ),
            ),
          ),
          SizedBox(width: 10 * scale),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                track.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.primaryTextColor,
                  fontSize: 12.5 * scale,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 2 * scale),
              Text(
                '${track.artist} • ${track.album}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: colors.secondaryTextColor,
                  fontSize: 10 * scale,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeTrackBadge(BuildContext context, double scale) {
    final track = config.track;

    return Container(
      padding: EdgeInsets.all(12 * scale),
      decoration: BoxDecoration(
        color: colors.badgeBackgroundColor.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(16 * scale),
        border: Border.all(color: colors.borderColor, width: 0.8),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (config.showArtwork)
            ClipRRect(
              borderRadius: BorderRadius.circular(12 * scale),
              child: StudioArtworkWidget(
                track: track,
                fit: BoxFit.cover,
                width: 72 * scale,
                height: 72 * scale,
              ),
            ),
          SizedBox(height: 8 * scale),
          Text(
            track.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.primaryTextColor,
              fontSize: 11.5 * scale,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            track.artist,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: colors.secondaryTextColor,
              fontSize: 9.5 * scale,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
