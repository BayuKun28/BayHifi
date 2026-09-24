import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/theme/app_typography.dart';
import '../../domain/track.dart';
import '../controllers/player_controller.dart';
import '../controllers/player_expansion_controller.dart';
import '../now_playing_screen.dart';
import '../../../pro_q_studio/presentation/pro_q_studio_screen.dart';

/// Namida-inspired Expandable MiniPlayer
/// Melayang tepat di atas Bottom Navigation Bar dan dapat di-expand secara mulus ke full NowPlayingScreen.
class NamidaExpandableMiniPlayer extends ConsumerStatefulWidget {
  final double collapsedBottomOffset;

  const NamidaExpandableMiniPlayer({
    super.key,
    this.collapsedBottomOffset = 86.0,
  });

  @override
  ConsumerState<NamidaExpandableMiniPlayer> createState() =>
      _NamidaExpandableMiniPlayerState();
}

class _NamidaExpandableMiniPlayerState
    extends ConsumerState<NamidaExpandableMiniPlayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
    _expandAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.easeInCubic,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _onExpand() {
    ref.read(playerExpansionProvider.notifier).expand();
  }

  void _onCollapse() {
    ref.read(playerExpansionProvider.notifier).collapse();
  }

  @override
  Widget build(BuildContext context) {
    final isExpanded = ref.watch(playerExpansionProvider);
    final playback = ref.watch(playerControllerProvider);
    final track = playback.currentTrack;
    final theme = Theme.of(context);
    final mediaQuery = MediaQuery.of(context);
    final screenHeight = mediaQuery.size.height;

    // Sinkronkan controller animasi dengan state
    if (isExpanded && _animController.status != AnimationStatus.completed) {
      _animController.forward();
    } else if (!isExpanded && _animController.status != AnimationStatus.dismissed) {
      _animController.reverse();
    }

    // Track aktif atau fallback demo
    final currentTrack = track ??
        const Track(
          id: 'demo_track',
          title: 'Ketuk untuk Memutar Audio',
          artist: 'Baydev HiFi Audiophile Player',
          album: 'Studio Engine Ready',
          duration: Duration(minutes: 3, seconds: 45),
          format: AudioFormat.flac,
          sampleRate: 96000,
          bitDepth: 24,
        );

    return AnimatedBuilder(
      animation: _expandAnimation,
      builder: (context, child) {
        final progress = _expandAnimation.value;

        // Animasikan bottom offset: dari collapsedBottomOffset (86px) ke 0px
        final double currentBottom = (1.0 - progress) * widget.collapsedBottomOffset;

        // Animasikan tinggi: dari 66px ke screenHeight
        const double miniPlayerHeight = 66.0;
        final double currentHeight =
            miniPlayerHeight + progress * (screenHeight - miniPlayerHeight);

        // Animasikan margin samping: dari 10px ke 0px
        final double horizontalMargin = (1.0 - progress) * 10.0;
        final double borderRadius = (1.0 - progress) * 16.0;

        return Positioned(
          left: horizontalMargin,
          right: horizontalMargin,
          bottom: currentBottom,
          height: currentHeight,
          child: GestureDetector(
            onVerticalDragUpdate: (details) {
              if (details.primaryDelta != null) {
                if (details.primaryDelta! < -6 && !isExpanded) {
                  _onExpand();
                } else if (details.primaryDelta! > 6 && isExpanded) {
                  _onCollapse();
                }
              }
            },
            child: Material(
              color: Colors.transparent,
              elevation: progress > 0.05 ? 24 : 10,
              borderRadius: BorderRadius.circular(borderRadius),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(borderRadius),
                child: Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(borderRadius),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: (1.0 - progress * 0.8)),
                      width: 1.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.4),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Stack(
                    children: [
                      // Layer 1: Full NowPlayingScreen (Fade in saat di-expand)
                      if (progress > 0.01)
                        Positioned.fill(
                          child: Opacity(
                            opacity: progress.clamp(0.0, 1.0),
                            child: NowPlayingScreen(
                              onCollapse: _onCollapse,
                              onOpenProQStudio: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => const ProQStudioScreen(),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),

                      // Layer 2: Collapsed MiniPlayer Bar (Fade out saat di-expand)
                      if (progress < 0.99)
                        Positioned(
                          top: 0,
                          left: 0,
                          right: 0,
                          height: miniPlayerHeight,
                          child: Opacity(
                            opacity: (1.0 - progress * 2.0).clamp(0.0, 1.0),
                            child: _buildMiniPlayerContent(
                              context,
                              currentTrack,
                              playback,
                              theme,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniPlayerContent(
    BuildContext context,
    Track track,
    dynamic playback,
    ThemeData theme,
  ) {
    final isPlaying = playback.isPlaying as bool;
    final position = playback.position as Duration;
    final duration = playback.duration as Duration;

    final progressRatio = duration.inMilliseconds > 0
        ? (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0)
        : 0.0;

    return InkWell(
      onTap: _onExpand,
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          // Bar Content Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
            child: Row(
              children: [
                // Squircle Album Art Thumbnail
                Hero(
                  tag: 'miniplayer_album_art',
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.dividerColor,
                        width: 1.0,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (isPlaying ? theme.colorScheme.primary : Colors.black)
                              .withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(11),
                      child: Center(
                        child: Icon(
                          Icons.album,
                          size: 26,
                          color: isPlaying
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),

                // Title, Artist, & Hi-Res Badge
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              track.title,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.2,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 5,
                              vertical: 1.5,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: theme.colorScheme.primary.withValues(alpha: 0.5),
                                width: 0.8,
                              ),
                            ),
                            child: Text(
                              '${track.format.name.toUpperCase()} 24/96',
                              style: TextStyle(
                                color: theme.colorScheme.primary,
                                fontSize: 8.5,
                                fontWeight: FontWeight.w900,
                                fontFeatures: AppTypography.audioFigures,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${track.artist} • ${track.album}',
                        style: TextStyle(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Play / Pause Circle Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      ref.read(playerControllerProvider.notifier).togglePlayPause();
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: theme.colorScheme.primary.withValues(alpha: 0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(
                        isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        color: theme.colorScheme.onPrimary,
                        size: 22,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                // Next Button
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      ref.read(playerControllerProvider.notifier).skipNext();
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      child: Icon(
                        Icons.skip_next_rounded,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                        size: 22,
                      ),
                    ),
                  ),
                ),

                // Expand Chevron Icon
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _onExpand,
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      child: Icon(
                        Icons.keyboard_arrow_up_rounded,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Micro Progress Bar at the bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: SizedBox(
              height: 2.5,
              child: LinearProgressIndicator(
                value: progressRatio,
                backgroundColor: theme.dividerColor.withValues(alpha: 0.3),
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
