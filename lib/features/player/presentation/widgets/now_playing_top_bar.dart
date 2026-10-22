import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/simple_as_f_theme.dart';
import '../../../../core/widgets/meta_tracking_label.dart';
import '../../domain/track.dart';
import '../controllers/sleep_timer_controller.dart';
import 'sleep_timer_sheet.dart';

/// Studio Now Playing Top Action Bar
/// Provides back/collapse navigation, bespoke tracking album label,
/// sleep timer pill indicator, and playback options trigger.
class NowPlayingTopBar extends StatelessWidget {
  final Track? track;
  final VoidCallback? onCollapse;
  final bool isLandscape;
  final bool isFavorite;
  final VoidCallback? onToggleFavorite;
  final SleepTimerState sleepTimer;
  final VoidCallback onOptionsPressed;

  const NowPlayingTopBar({
    super.key,
    required this.track,
    this.onCollapse,
    this.isLandscape = false,
    this.isFavorite = false,
    this.onToggleFavorite,
    required this.sleepTimer,
    required this.onOptionsPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left: Back / Collapse Chevron Button
        if (onCollapse != null)
          IconButton(
            onPressed: onCollapse,
            icon: Icon(
              LucideIcons.chevronDown,
              size: 22,
              color: theme.colorScheme.onSurface,
            ),
            tooltip: 'Collapse to MiniPlayer',
          )
        else if (Navigator.canPop(context))
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              LucideIcons.arrowLeft,
              size: 22,
              color: theme.colorScheme.onSurface,
            ),
            tooltip: 'Back',
          )
        else
          const SizedBox(width: 48),

        // Center: Bespoke Tracking Header (Album Name)
        Expanded(
          child: MetaTrackingLabel(
            (track != null && track!.album.isNotEmpty)
                ? track!.album.toUpperCase()
                : 'NOW PLAYING',
            fontSize: 11,
            letterSpacing: 1.4,
            textAlign: TextAlign.center,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),

        // Right Actions: Sleep Timer Pill (if active) + Favorite (if landscape) + Options Menu
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (sleepTimer.isActive)
              GestureDetector(
                onTap: () {
                  AppHaptics.lightImpact();
                  SleepTimerSheet.show(context);
                },
                child: Container(
                  margin: EdgeInsets.only(right: isLandscape ? 6 : 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: SimpleAsFTheme.emeraldMint.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: SimpleAsFTheme.emeraldMint.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        LucideIcons.timer,
                        size: 14,
                        color: SimpleAsFTheme.emeraldMint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        sleepTimer.formattedRemaining,
                        style: TextStyle(
                          fontFeatures: AppTypography.audioFigures,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: SimpleAsFTheme.emeraldMint,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Favorite Button (rendered in top bar only in landscape layout)
            if (isLandscape && track != null && onToggleFavorite != null)
              IconButton(
                onPressed: () {
                  AppHaptics.selectionClick();
                  onToggleFavorite!();
                },
                icon: Icon(
                  LucideIcons.heart,
                  size: 20,
                  color: isFavorite
                      ? const Color(0xFFFF2D55)
                      : theme.colorScheme.onSurfaceVariant,
                ),
                tooltip: isFavorite
                    ? 'Remove from Favorites'
                    : 'Add to Favorites',
              ),

            // More Options Button
            IconButton(
              onPressed: () {
                AppHaptics.lightImpact();
                onOptionsPressed();
              },
              icon: Icon(
                LucideIcons.moreVertical,
                size: 22,
                color: theme.colorScheme.onSurface,
              ),
              tooltip: 'Playback Options',
            ),
          ],
        ),
      ],
    );
  }
}
