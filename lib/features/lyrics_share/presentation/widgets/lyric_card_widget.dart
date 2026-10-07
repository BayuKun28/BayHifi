import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../../domain/models/lyric_card_layout_style.dart';
import '../../domain/models/lyric_card_theme.dart';
import '../../domain/models/lyric_share_config.dart';
import 'templates/abstract_aura_lyric_view.dart';
import 'templates/cassette_jcard_lyric_view.dart';
import 'templates/classic_minimal_card_view.dart';
import 'templates/cyber_hud_lyric_view.dart';
import 'templates/polaroid_frame_card_view.dart';
import 'templates/waveform_quote_card_view.dart';
import '../../../../core/widgets/studio_artwork_widget.dart';

/// Pure renderable Studio Lyric Card widget.
/// Dispatches to the 6 dedicated layout style templates.
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
    final layoutStyle = config.layoutStyle;

    Widget cardContent = LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = constraints.maxWidth.isFinite ? constraints.maxWidth : 300.0;
        final scale = (cardWidth / 340.0).clamp(0.65, 2.5);
        final isLandscape = ratio == LyricCardRatio.landscape_16_9;
        final isBlurredBg = config.backgroundMode == LyricCardBackgroundMode.blurredArtwork;

        // Dedicated Templates
        switch (layoutStyle) {
          case LyricCardLayoutStyle.polaroidFrame:
            return ClipRRect(
              borderRadius: BorderRadius.circular(20 * scale),
              child: PolaroidFrameCardView(
                config: config,
                colors: colors,
                scale: scale,
                isLandscape: isLandscape,
              ),
            );

          case LyricCardLayoutStyle.cassetteJCard:
            return ClipRRect(
              borderRadius: BorderRadius.circular(20 * scale),
              child: CassetteJCardLyricView(
                config: config,
                colors: colors,
                scale: scale,
                isLandscape: isLandscape,
              ),
            );

          case LyricCardLayoutStyle.waveformQuote:
            return ClipRRect(
              borderRadius: BorderRadius.circular(20 * scale),
              child: WaveformQuoteCardView(
                config: config,
                colors: colors,
                scale: scale,
                isLandscape: isLandscape,
              ),
            );

          case LyricCardLayoutStyle.cyberHUD:
            return ClipRRect(
              borderRadius: BorderRadius.circular(16 * scale),
              child: CyberHudLyricView(
                config: config,
                colors: colors,
                scale: scale,
                isLandscape: isLandscape,
              ),
            );

          case LyricCardLayoutStyle.abstractAura:
            return ClipRRect(
              borderRadius: BorderRadius.circular(24 * scale),
              child: AbstractAuraLyricView(
                config: config,
                colors: colors,
                scale: scale,
                isLandscape: isLandscape,
              ),
            );

          case LyricCardLayoutStyle.classicMinimal:
            final paddingH = (20.0 * scale).clamp(12.0, 32.0);
            final paddingV = (20.0 * scale).clamp(12.0, 32.0);

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
                          imageFilter: ui.ImageFilter.blur(
                            sigmaX: config.backgroundBlurSigma,
                            sigmaY: config.backgroundBlurSigma,
                          ),
                          child: Transform.scale(
                            scale: 1.15,
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
                                Colors.black.withValues(alpha: (config.backgroundDimOpacity * 0.75).clamp(0.0, 1.0)),
                                Colors.black.withValues(alpha: config.backgroundDimOpacity.clamp(0.0, 1.0)),
                                Colors.black.withValues(alpha: (config.backgroundDimOpacity * 1.25).clamp(0.0, 1.0)),
                              ],
                              stops: const [0.0, 0.45, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
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

                    // Content
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isLandscape ? paddingH * 1.1 : paddingH,
                        vertical: isLandscape ? paddingV * 0.85 : paddingV,
                      ),
                      child: ClassicMinimalCardView(
                        config: config,
                        colors: colors,
                        scale: scale,
                        isLandscape: isLandscape,
                      ),
                    ),
                  ],
                ),
              ),
            );
        }
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
}
