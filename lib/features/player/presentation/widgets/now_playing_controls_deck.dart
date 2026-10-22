import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../domain/playback_state.dart';

/// Studio Playback Controls Deck
/// Minimalist transport controls: Shuffle, Previous (with Long-press rewind),
/// Play/Pause (Pure solid circle without neon glow), Next (with Long-press forward),
/// and Repeat Mode.
class NowPlayingControlsDeck extends StatelessWidget {
  final bool isPlaying;
  final bool isLoading;
  final bool isShuffle;
  final PlaybackRepeatMode repeatMode;
  final Color primaryColor;
  final VoidCallback onPlayPause;
  final VoidCallback onSkipNext;
  final VoidCallback onSkipPrevious;
  final VoidCallback onSeekForward;
  final VoidCallback onSeekBackward;
  final VoidCallback onToggleShuffle;
  final VoidCallback onToggleRepeat;

  const NowPlayingControlsDeck({
    super.key,
    required this.isPlaying,
    required this.isLoading,
    required this.isShuffle,
    required this.repeatMode,
    required this.primaryColor,
    required this.onPlayPause,
    required this.onSkipNext,
    required this.onSkipPrevious,
    required this.onSeekForward,
    required this.onSeekBackward,
    required this.onToggleShuffle,
    required this.onToggleRepeat,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 320;
        final playSize = isCompact ? 54.0 : 64.0;
        final iconPadding = isCompact ? EdgeInsets.zero : const EdgeInsets.all(8.0);
        final iconBoxConstraints =
            isCompact ? const BoxConstraints(minWidth: 34, minHeight: 34) : null;
        final iconVisualDensity = isCompact ? VisualDensity.compact : null;

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Shuffle
            IconButton(
              padding: iconPadding,
              constraints: iconBoxConstraints,
              visualDensity: iconVisualDensity,
              onPressed: () {
                AppHaptics.selectionClick();
                onToggleShuffle();
              },
              icon: Icon(
                LucideIcons.shuffle,
                color: isShuffle
                    ? primaryColor
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                size: 20,
              ),
              tooltip: 'Shuffle Playback',
            ),

            // Previous
            GestureDetector(
              onLongPress: () {
                AppHaptics.mediumImpact();
                onSeekBackward();
              },
              child: IconButton(
                padding: iconPadding,
                constraints: iconBoxConstraints,
                visualDensity: iconVisualDensity,
                onPressed: () {
                  AppHaptics.lightImpact();
                  onSkipPrevious();
                },
                icon: Icon(
                  LucideIcons.stepBack,
                  size: isCompact ? 22 : 26,
                  color: theme.colorScheme.onSurface,
                ),
                tooltip: 'Previous Track',
              ),
            ),

            // Play/Pause Centerpiece (Solid color, zero neon glow)
            GestureDetector(
              onTap: () {
                AppHaptics.mediumImpact();
                onPlayPause();
              },
              child: Container(
                width: playSize,
                height: playSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primaryColor,
                ),
                child: Center(
                  child: isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: theme.colorScheme.onPrimary,
                          ),
                        )
                      : Icon(
                          isPlaying ? LucideIcons.pause : LucideIcons.play,
                          color: theme.colorScheme.onPrimary,
                          size: isCompact ? 22 : 26,
                        ),
                ),
              ),
            ),

            // Next
            GestureDetector(
              onLongPress: () {
                AppHaptics.mediumImpact();
                onSeekForward();
              },
              child: IconButton(
                padding: iconPadding,
                constraints: iconBoxConstraints,
                visualDensity: iconVisualDensity,
                onPressed: () {
                  AppHaptics.lightImpact();
                  onSkipNext();
                },
                icon: Icon(
                  LucideIcons.stepForward,
                  size: isCompact ? 22 : 26,
                  color: theme.colorScheme.onSurface,
                ),
                tooltip: 'Next Track',
              ),
            ),

            // Repeat
            IconButton(
              padding: iconPadding,
              constraints: iconBoxConstraints,
              visualDensity: iconVisualDensity,
              onPressed: () {
                AppHaptics.selectionClick();
                onToggleRepeat();
              },
              icon: Icon(
                repeatMode == PlaybackRepeatMode.one
                    ? LucideIcons.repeat1
                    : LucideIcons.repeat,
                color: repeatMode != PlaybackRepeatMode.off
                    ? primaryColor
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                size: 20,
              ),
              tooltip: 'Repeat Mode (${repeatMode.name.toUpperCase()})',
            ),
          ],
        );
      },
    );
  }
}
