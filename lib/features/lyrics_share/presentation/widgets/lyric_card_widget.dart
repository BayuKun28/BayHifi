import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../core/widgets/studio_artwork_widget.dart';
import '../../../player/domain/track.dart';
import '../../domain/models/lyric_card_theme.dart';
import '../../domain/models/lyric_share_config.dart';

/// Pure renderable Studio Lyric Card widget.
/// Designed to be captured via [RepaintBoundary] into high-definition PNG social media cards.
class LyricCardWidget extends StatelessWidget {
  final LyricShareConfig config;
  final LyricCardColors colors;
  final GlobalKey? repaintBoundaryKey;

  const LyricCardWidget({
    super.key,
    required this.config,
    required this.colors,
    this.repaintBoundaryKey,
  });

  @override
  Widget build(BuildContext context) {
    final track = config.track;
    final ratio = config.ratio;

    Widget cardContent = LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : 300.0;
        final scale = (cardWidth / 340.0).clamp(0.65, 2.5);
        final paddingH = (20.0 * scale).clamp(12.0, 32.0);
        final paddingV = (20.0 * scale).clamp(12.0, 32.0);
        final isBlurredBg = config.backgroundMode == LyricCardBackgroundMode.blurredArtwork;

        final isLandscape = ratio == LyricCardRatio.landscape_16_9;

        return ClipRRect(
          borderRadius: BorderRadius.circular(24 * scale),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            decoration: BoxDecoration(
              color: isBlurredBg ? const Color(0xFF0F1218) : colors.backgroundColor,
              borderRadius: BorderRadius.circular(24 * scale),
            ),
            child: Stack(
              children: [
                // Blurred Album Art Background
                if (isBlurredBg) ...[
                  Positioned.fill(
                    child: ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                      child: Transform.scale(
                        scale: 1.15, // Scale up slightly to prevent blur edge bleeding
                        child: StudioArtworkWidget(
                          track: track,
                          fit: BoxFit.cover,
                          backgroundColor: const Color(0xFF14171E),
                        ),
                      ),
                    ),
                  ),
                  // Dark Studio Vignette & Readability Shield Overlay
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.black.withValues(alpha: 0.50),
                            Colors.black.withValues(alpha: 0.65),
                            Colors.black.withValues(alpha: 0.85),
                          ],
                          stops: const [0.0, 0.45, 1.0],
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  // Functional Studio Gradient Overlay / Light Sheen for Solid Palette
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            colors.accentColor.withValues(alpha: 0.08),
                            colors.surfaceColor.withValues(alpha: 0.15),
                            colors.backgroundColor,
                          ],
                          stops: const [0.0, 0.4, 1.0],
                        ),
                      ),
                    ),
                  ),
                ],

                // Main Card Content Layout (Dedicated Landscape vs Vertical)
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: isLandscape ? paddingH * 1.1 : paddingH,
                    vertical: isLandscape ? paddingV * 0.85 : paddingV,
                  ),
                  child: isLandscape
                      ? _buildLandscapeContent(context, track, scale)
                      : _buildVerticalContent(context, track, scale),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (repaintBoundaryKey != null) {
      cardContent = RepaintBoundary(
        key: repaintBoundaryKey,
        child: AspectRatio(
          aspectRatio: ratio.aspectRatio,
          child: cardContent,
        ),
      );
    } else {
      cardContent = AspectRatio(
        aspectRatio: ratio.aspectRatio,
        child: cardContent,
      );
    }

    return cardContent;
  }

  Widget _buildVerticalContent(BuildContext context, Track track, double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Header: Official App Branding & Audio Specs Telemetry Badge
        _buildHeader(context, track, scale),

        const Spacer(),

        // Center: Scaled Bold Lyric Quotes
        Expanded(
          flex: 8,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: config.textAlign == TextAlign.center
                  ? Alignment.center
                  : (config.textAlign == TextAlign.right ? Alignment.centerRight : Alignment.centerLeft),
              child: _buildLyricsSection(context, scale),
            ),
          ),
        ),

        const Spacer(),

        // Bottom Footer: Album Art, Track Title, Artist & Album
        _buildFooter(context, track, scale),
      ],
    );
  }

  Widget _buildLandscapeContent(BuildContext context, Track track, double scale) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top Header
        _buildHeader(context, track, scale),

        const SizedBox(height: 6),

        // Body: Left Lyrics & Right Compact Studio Track Badge
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left Lyrics Section
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
                    child: _buildLyricsSection(context, scale),
                  ),
                ),
              ),
              SizedBox(width: 14 * scale),
              // Right Proportional Track Badge
              Expanded(
                flex: 8,
                child: Center(
                  child: _buildLandscapeTrackBadge(context, track, scale),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context, Track track, double scale) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (config.showBranding)
          Flexible(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Official Baydev HiFi Studio Logo
                Container(
                  width: 26 * scale,
                  height: 26 * scale,
                  decoration: BoxDecoration(
                    color: colors.badgeBackgroundColor,
                    borderRadius: BorderRadius.circular(8 * scale),
                    border: Border.all(
                      color: colors.borderColor,
                      width: 0.8,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7 * scale),
                    child: Image.asset(
                      'assets/images/baydev_logo.png',
                      width: 24 * scale,
                      height: 24 * scale,
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Center(
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedAudioWave01,
                          size: 15 * scale,
                          color: colors.accentColor,
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 8 * scale),
                Flexible(
                  child: Text(
                    'BAYDEV HIFI',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.primaryTextColor,
                      fontSize: (11.5 * scale).clamp(9.0, 16.0),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        SizedBox(width: 6 * scale),
        if (config.showAudioSpecsBadge)
          Flexible(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8 * scale, vertical: 4 * scale),
              decoration: BoxDecoration(
                color: colors.badgeBackgroundColor,
                borderRadius: BorderRadius.circular(8 * scale),
                border: Border.all(
                  color: colors.borderColor,
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedMusicNote01,
                    size: 11 * scale,
                    color: colors.badgeTextColor,
                  ),
                  SizedBox(width: 4 * scale),
                  Flexible(
                    child: Text(
                      config.customAudioSpec ?? _formatAudioSpec(track),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.badgeTextColor,
                        fontSize: (9.5 * scale).clamp(7.5, 14.0),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildLyricsSection(BuildContext context, double scale) {
    if (config.selectedLines.isEmpty) {
      return Center(
        child: Text(
          'Select lyrics to share',
          style: TextStyle(
            color: colors.secondaryTextColor,
            fontSize: 16 * scale,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    final lineCount = config.selectedLines.length;
    final double baseFontSize = _calculateFontSize(lineCount, config.ratio) * scale;
    final double fontSize = baseFontSize * config.fontSizeMultiplier;
    final double lineSpacing = (lineCount > 3 ? 8.0 : 14.0) * scale;

    final crossAxis = config.textAlign == TextAlign.center
        ? CrossAxisAlignment.center
        : (config.textAlign == TextAlign.right ? CrossAxisAlignment.end : CrossAxisAlignment.start);

    return Column(
      crossAxisAlignment: crossAxis,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Decorative Minimal Studio Quote Icon
        Padding(
          padding: EdgeInsets.only(bottom: 10 * scale),
          child: HugeIcon(
            icon: HugeIcons.strokeRoundedQuoteUp,
            size: 22 * scale,
            color: colors.accentColor.withValues(alpha: 0.8),
          ),
        ),
        for (int i = 0; i < config.selectedLines.length; i++) ...[
          if (i > 0) SizedBox(height: lineSpacing),
          _buildLyricLine(config.selectedLines[i], fontSize, scale, crossAxis),
        ],
      ],
    );
  }

  Widget _buildLyricLine(
    dynamic line,
    double fontSize,
    double scale,
    CrossAxisAlignment crossAxis,
  ) {
    final String mainText = line.text;
    final String? romanized = line.romanizedText;
    final bool showRoman =
        config.showRomanized && romanized != null && romanized.isNotEmpty && romanized != mainText;

    return Column(
      crossAxisAlignment: crossAxis,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          mainText,
          textAlign: config.textAlign,
          style: TextStyle(
            fontFamily: config.fontFamily.fontFamily,
            color: colors.primaryTextColor,
            fontSize: fontSize,
            fontWeight: config.fontWeight,
            fontStyle: config.isItalic ? FontStyle.italic : FontStyle.normal,
            height: 1.25,
            letterSpacing: -0.2,
          ),
        ),
        if (showRoman) ...[
          SizedBox(height: 3 * scale),
          Text(
            romanized,
            textAlign: config.textAlign,
            style: TextStyle(
              fontFamily: config.fontFamily.fontFamily,
              color: colors.secondaryTextColor,
              fontSize: fontSize * 0.68,
              fontWeight: FontWeight.w500,
              fontStyle: FontStyle.italic,
              height: 1.2,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildFooter(BuildContext context, Track track, double scale) {
    final artSize = (36.0 * scale).clamp(28.0, 50.0);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10 * scale, vertical: 7 * scale),
      decoration: BoxDecoration(
        color: colors.surfaceColor,
        borderRadius: BorderRadius.circular(14 * scale),
        border: Border.all(
          color: colors.borderColor,
          width: 0.8,
        ),
      ),
      child: Row(
        children: [
          // Album Artwork Squircle Thumbnail via Unified StudioArtworkWidget
          StudioArtworkWidget(
            track: track,
            width: artSize,
            height: artSize,
            borderRadius: BorderRadius.circular(8 * scale),
            fit: BoxFit.cover,
            fallbackIcon: HugeIcons.strokeRoundedMusicNote03,
            fallbackIconSize: 18 * scale,
            fallbackColor: colors.accentColor,
            backgroundColor: colors.badgeBackgroundColor,
          ),
          SizedBox(width: 10 * scale),
          // Track Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  track.title.isNotEmpty ? track.title : 'Unknown Title',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.primaryTextColor,
                    fontSize: (12.0 * scale).clamp(9.5, 15.0),
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                  ),
                ),
                SizedBox(height: 1.5 * scale),
                Text(
                  '${track.artist.isNotEmpty ? track.artist : 'Unknown Artist'}${track.album.isNotEmpty ? ' • ${track.album}' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.secondaryTextColor,
                    fontSize: (10.0 * scale).clamp(8.0, 13.0),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLandscapeTrackBadge(BuildContext context, Track track, double scale) {
    final artSize = (46.0 * scale).clamp(34.0, 64.0);
    return Container(
      padding: EdgeInsets.all(9 * scale),
      decoration: BoxDecoration(
        color: colors.surfaceColor.withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(14 * scale),
        border: Border.all(
          color: colors.borderColor,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 8 * scale,
            offset: Offset(0, 2 * scale),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              StudioArtworkWidget(
                track: track,
                width: artSize,
                height: artSize,
                borderRadius: BorderRadius.circular(9 * scale),
                fit: BoxFit.cover,
                fallbackIcon: HugeIcons.strokeRoundedMusicNote03,
                fallbackIconSize: 20 * scale,
                fallbackColor: colors.accentColor,
                backgroundColor: colors.badgeBackgroundColor,
              ),
              SizedBox(width: 9 * scale),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      track.title.isNotEmpty ? track.title : 'Unknown Title',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.primaryTextColor,
                        fontSize: (11.5 * scale).clamp(9.0, 14.5),
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                        height: 1.15,
                      ),
                    ),
                    SizedBox(height: 2.5 * scale),
                    Text(
                      track.artist.isNotEmpty ? track.artist : 'Unknown Artist',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.secondaryTextColor,
                        fontSize: (9.5 * scale).clamp(7.5, 12.0),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (track.album.isNotEmpty) ...[
            SizedBox(height: 5 * scale),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 5 * scale, vertical: 2 * scale),
              decoration: BoxDecoration(
                color: colors.badgeBackgroundColor,
                borderRadius: BorderRadius.circular(5 * scale),
                border: Border.all(color: colors.borderColor, width: 0.6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedAlbum01,
                    size: 8.5 * scale,
                    color: colors.accentColor,
                  ),
                  SizedBox(width: 3.5 * scale),
                  Flexible(
                    child: Text(
                      track.album,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: colors.secondaryTextColor,
                        fontSize: (8.0 * scale).clamp(6.5, 10.5),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  double _calculateFontSize(int count, LyricCardRatio ratio) {
    if (ratio == LyricCardRatio.story_9_16) {
      if (count == 1) return 23.0;
      if (count == 2) return 20.0;
      if (count == 3) return 17.5;
      if (count == 4) return 15.5;
      return 14.0;
    } else if (ratio == LyricCardRatio.landscape_16_9) {
      if (count == 1) return 17.5;
      if (count == 2) return 15.0;
      if (count == 3) return 13.0;
      if (count == 4) return 11.5;
      return 10.5;
    } else if (ratio == LyricCardRatio.square_1_1) {
      if (count == 1) return 19.5;
      if (count == 2) return 17.0;
      if (count == 3) return 15.0;
      if (count == 4) return 13.5;
      return 12.0;
    } else {
      // Portrait 4:5
      if (count == 1) return 20.5;
      if (count == 2) return 18.0;
      if (count == 3) return 15.5;
      if (count == 4) return 14.0;
      return 12.5;
    }
  }

  String _formatAudioSpec(Track track) {
    final format = track.format.name.toUpperCase();
    if (format == 'FLAC' || format == 'WAV' || format == 'ALAC' || format == 'DSD') {
      return 'LOSSLESS MASTER • $format';
    }
    if (format.isNotEmpty && format != 'UNKNOWN') {
      return 'STUDIO AUDIO • $format';
    }
    return 'STUDIO MASTER';
  }
}
