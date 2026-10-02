import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../core/widgets/studio_artwork_widget.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../library/presentation/controllers/library_controller.dart';
import '../../../player/domain/track.dart';
import '../../../player/presentation/controllers/player_controller.dart';

class RecentSessionsBentoCarousel extends ConsumerWidget {
  final VoidCallback? onNavigateToLibrary;

  const RecentSessionsBentoCarousel({
    super.key,
    this.onNavigateToLibrary,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isSolid = ref.isSolidStyle;
    final libraryState = ref.watch(unifiedLibraryProvider);
    final tracks = libraryState.tracks;

    if (tracks.isEmpty) {
      return const SizedBox.shrink();
    }

    final recentTracks = tracks.take(8).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: StudioSurfaceTheme.cardDecoration(
        context: context,
        isSolid: isSolid,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: StudioSurfaceTheme.tintedContainer(context, primary, isSolid: isSolid),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedPlayList,
                          size: 15,
                          color: primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'RECENT LOSSLESS SESSIONS',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (onNavigateToLibrary != null)
                  InkWell(
                    onTap: onNavigateToLibrary,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        children: [
                          Text(
                            'View All (${tracks.length})',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w700,
                              color: primary,
                            ),
                          ),
                          const SizedBox(width: 2),
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedArrowRight01,
                            size: 11,
                            color: primary,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Horizontal Carousel
          SizedBox(
            height: 128,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: recentTracks.length,
              separatorBuilder: (context, index) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final track = recentTracks[index];
                return _buildTrackCard(context, ref, track, primary, theme, isSolid);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackCard(
    BuildContext context,
    WidgetRef ref,
    Track track,
    Color primary,
    ThemeData theme,
    bool isSolid,
  ) {
    final playback = ref.watch(playerControllerProvider);
    final isCurrent = playback.currentTrack?.id == track.id;
    final isPlaying = isCurrent && playback.isPlaying;

    return InkWell(
      onTap: () {
        AppHaptics.lightImpact();
        ref.read(playerControllerProvider.notifier).playTrack(track);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 104,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isCurrent
              ? StudioSurfaceTheme.tintedContainer(context, primary, isSolid: isSolid)
              : StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Album Art Thumbnail with Playing Pulse Indicator
            Stack(
              children: [
                Container(
                  width: double.infinity,
                  height: 62,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _buildCover(track, theme),
                  ),
                ),
                if (track.isHiRes)
                  Positioned(
                    top: 3,
                    right: 3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: StudioSurfaceTheme.surface(context, isSolid: isSolid),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'HI-RES',
                        style: TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.w900,
                          color: primary,
                        ),
                      ),
                    ),
                  ),
                if (isPlaying)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.45),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedVolumeHigh,
                          size: 18,
                          color: primary,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 6),

            // Track Title
            Text(
              track.title,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isCurrent ? FontWeight.w900 : FontWeight.w700,
                color: isCurrent ? primary : theme.colorScheme.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 1),

            // Artist & Format
            Text(
              '${track.artist} • ${track.format.name.toUpperCase()}',
              style: TextStyle(
                fontFeatures: AppTypography.audioFigures,
                fontSize: 9,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCover(Track track, ThemeData theme) {
    return StudioArtworkWidget(
      track: track,
      fallbackIconSize: 24,
      fallbackColor: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
    );
  }
}
