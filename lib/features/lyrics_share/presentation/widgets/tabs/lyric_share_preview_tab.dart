import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:baydev_hifi/app/theme/app_haptics.dart';
import 'package:baydev_hifi/features/lyrics_share/domain/models/lyric_card_layout_style.dart';
import 'package:baydev_hifi/features/lyrics_share/domain/models/lyric_card_theme.dart';
import 'package:baydev_hifi/features/lyrics_share/presentation/controllers/lyric_share_controller.dart';
import '../lyric_card_fullscreen_lightbox.dart';
import '../lyric_card_widget.dart';
import '../lyric_share_sheet_components.dart';

/// Tab 0: Studio Live Preview, Layout Style Templates, Aspect Ratio & Quick Badges
class LyricSharePreviewTab extends StatelessWidget {
  final LyricShareState state;
  final LyricShareController controller;
  final GlobalKey repaintBoundaryKey;

  const LyricSharePreviewTab({
    super.key,
    required this.state,
    required this.controller,
    required this.repaintBoundaryKey,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = state.config.ratio;

    final double maxStageWidth = ratio == LyricCardRatio.landscape_16_9
        ? 340.0
        : (ratio == LyricCardRatio.story_9_16 ? 210.0 : 250.0);
    final double maxStageHeight = ratio == LyricCardRatio.landscape_16_9
        ? 192.0
        : (ratio == LyricCardRatio.story_9_16 ? 330.0 : 260.0);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Live Card Preview Stage (Clickable for Full Screen Lightbox)
          GestureDetector(
            onTap: () {
              AppHaptics.mediumImpact();
              LyricCardFullScreenLightbox.show(
                context,
                config: state.config,
                colors: state.colors,
                controller: controller,
                parentRepaintKey: repaintBoundaryKey,
              );
            },
            child: Stack(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: theme.colorScheme.outline.withValues(alpha: 0.12),
                      width: 1.0,
                    ),
                  ),
                  child: Center(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeInOutCubic,
                      constraints: BoxConstraints(
                        maxWidth: maxStageWidth,
                        maxHeight: maxStageHeight,
                      ),
                      child: LyricCardWidget(
                        config: state.config,
                        colors: state.colors,
                        repaintBoundaryKey: repaintBoundaryKey,
                      ),
                    ),
                  ),
                ),
                // Full Screen Preview Badge
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface.withValues(alpha: 0.90),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outline.withValues(alpha: 0.25),
                        width: 0.8,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.12),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.maximize2,
                          size: 12,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Full Screen',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fade(duration: 250.ms).scale(begin: const Offset(0.96, 0.96)),

          const SizedBox(height: 14),

          // 2. Layout Style Templates Bento
          LyricShareBentoSection(
            theme: theme,
            title: 'LAYOUT TEMPLATES (6 STYLES)',
            icon: LucideIcons.layoutGrid,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: LyricCardLayoutStyle.values.map((style) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: LyricShareTemplateStyleCard(
                      style: style,
                      currentStyle: state.config.layoutStyle,
                      theme: theme,
                      onTap: () {
                        AppHaptics.selectionClick();
                        controller.setLayoutStyle(style);
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 3. Aspect Ratio Bento
          LyricShareBentoSection(
            theme: theme,
            title: 'ASPECT RATIO',
            icon: LucideIcons.proportions,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                children: LyricCardRatio.values.map((r) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 86,
                      child: LyricShareRatioOption(
                        ratio: r,
                        currentRatio: state.config.ratio,
                        theme: theme,
                        onTap: () {
                          AppHaptics.selectionClick();
                          controller.setRatio(r);
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // 4. Quick Branding & Specs Toggles
          LyricShareBentoSection(
            theme: theme,
            title: 'QUICK BADGES',
            icon: LucideIcons.sparkles,
            child: Row(
              children: [
                Expanded(
                  child: LyricShareQuickToggleCard(
                    title: 'Branding',
                    icon: LucideIcons.sparkles,
                    isActive: state.config.showBranding,
                    theme: theme,
                    onTap: () {
                      AppHaptics.selectionClick();
                      controller.toggleBranding(!state.config.showBranding);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LyricShareQuickToggleCard(
                    title: 'Telemetry',
                    icon: LucideIcons.slidersHorizontal,
                    isActive: state.config.audiophileStamp.enabled,
                    theme: theme,
                    onTap: () {
                      AppHaptics.selectionClick();
                      controller.updateAudiophileStamp(enabled: !state.config.audiophileStamp.enabled);
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: LyricShareQuickToggleCard(
                    title: 'QR Link',
                    icon: LucideIcons.qrCode,
                    isActive: state.config.showQrCode,
                    theme: theme,
                    onTap: () {
                      AppHaptics.selectionClick();
                      controller.toggleQrCode(!state.config.showQrCode);
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
