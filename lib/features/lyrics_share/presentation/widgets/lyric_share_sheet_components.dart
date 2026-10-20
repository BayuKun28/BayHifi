import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../domain/models/lyric_card_layout_style.dart';
import '../../domain/models/lyric_card_theme.dart';
import '../controllers/lyric_share_controller.dart';

/// Reusable Bento section container for Lyric Studio Share tabs
class LyricShareBentoSection extends StatelessWidget {
  final ThemeData theme;
  final String title;
  final IconData icon;
  final Widget child;

  const LyricShareBentoSection({
    super.key,
    required this.theme,
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 14,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

/// Standardized toggle row with switch and title/subtitle
class LyricShareToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ThemeData theme;
  final ValueChanged<bool> onChanged;

  const LyricShareToggleRow({
    super.key,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.theme,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeTrackColor: theme.colorScheme.primary,
          ),
        ],
      ),
    );
  }
}

/// Wireframe ratio option selector
class LyricShareRatioOption extends StatelessWidget {
  final LyricCardRatio ratio;
  final LyricCardRatio currentRatio;
  final ThemeData theme;
  final VoidCallback onTap;

  const LyricShareRatioOption({
    super.key,
    required this.ratio,
    required this.currentRatio,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = ratio == currentRatio;

    Widget ratioWireframe() {
      double w = 14;
      double h = 14;
      switch (ratio) {
        case LyricCardRatio.story_9_16:
          w = 9;
          h = 16;
          break;
        case LyricCardRatio.square_1_1:
          w = 14;
          h = 14;
          break;
        case LyricCardRatio.portrait_4_5:
          w = 11;
          h = 14;
          break;
        case LyricCardRatio.landscape_16_9:
          w = 16;
          h = 9;
          break;
      }
      return Container(
        width: w,
        height: h,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(2.5),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            width: 1.2,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.15)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 18,
              child: Center(child: ratioWireframe()),
            ),
            const SizedBox(height: 4),
            Text(
              ratio.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact toggle card for quick attributes (Branding, Telemetry, QR Code)
class LyricShareQuickToggleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool isActive;
  final ThemeData theme;
  final VoidCallback onTap;

  const LyricShareQuickToggleCard({
    super.key,
    required this.title,
    required this.icon,
    required this.isActive,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.primary.withValues(alpha: 0.15)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive ? theme.colorScheme.primary : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 14,
              color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Layout style template card
class LyricShareTemplateStyleCard extends StatelessWidget {
  final LyricCardLayoutStyle style;
  final LyricCardLayoutStyle currentStyle;
  final ThemeData theme;
  final VoidCallback onTap;

  const LyricShareTemplateStyleCard({
    super.key,
    required this.style,
    required this.currentStyle,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = style == currentStyle;

    IconData getStyleIcon() {
      switch (style) {
        case LyricCardLayoutStyle.classicMinimal:
          return LucideIcons.layoutTemplate;
        case LyricCardLayoutStyle.polaroidFrame:
          return LucideIcons.image;
        case LyricCardLayoutStyle.cassetteJCard:
          return LucideIcons.disc;
        case LyricCardLayoutStyle.waveformQuote:
          return LucideIcons.audioWaveform;
        case LyricCardLayoutStyle.cyberHUD:
          return LucideIcons.terminal;
        case LyricCardLayoutStyle.abstractAura:
          return LucideIcons.sparkles;
      }
    }

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 104,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary.withValues(alpha: 0.15)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                getStyleIcon(),
                size: 16,
                color: isSelected
                    ? theme.colorScheme.onPrimary
                    : theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              style.label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              style.subtitle,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Color theme preset chip
class LyricShareThemePresetChip extends StatelessWidget {
  final LyricCardThemePreset preset;
  final LyricShareState state;
  final ThemeData theme;
  final VoidCallback onTap;

  const LyricShareThemePresetChip({
    super.key,
    required this.preset,
    required this.state,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = preset == state.config.preset;
    final presetColors = LyricCardColors.fromPreset(
      preset,
      dominantAlbumColor: state.dominantAlbumColor,
      vibrantAlbumColor: state.vibrantAlbumColor,
      lightVibrantAlbumColor: state.lightVibrantAlbumColor,
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: presetColors.backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : presetColors.borderColor,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: presetColors.accentColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              preset.label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: presetColors.primaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
