import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/simple_as_f_theme.dart';
import '../../../../core/database/local_persistence_service.dart';
import '../../../../core/widgets/studio_artwork_widget.dart';
import '../../../library/domain/library_collection_models.dart';
import '../../../library/presentation/controllers/library_controller.dart';
import '../../../library/presentation/screens/album_detail_screen.dart';
import '../../../player/domain/track.dart';
import '../../../player/presentation/controllers/player_controller.dart';

/// 2-Column squircle grid for albums and playlists adhering to Screen 1 of Dribbble 27089924.
/// Connected directly to persistent playback history with 2x2 mobile grid enforcement.
class SimpleAsFDiscoveryGrid extends ConsumerWidget {
  const SimpleAsFDiscoveryGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(unifiedLibraryProvider);
    final history = LocalPersistenceService.instance.getPlaybackHistory();
    final trackMap = {for (final t in libraryState.tracks) t.id: t};

    // Extract real recently played tracks from persistent history without duplicates
    final recentTracks = <Track>[];
    for (final h in history) {
      final t = trackMap[h['id']];
      if (t != null && !recentTracks.any((rt) => rt.id == t.id)) {
        recentTracks.add(t);
      }
    }

    final hasRecent = recentTracks.isNotEmpty;
    final albums = libraryState.albums;

    if (!hasRecent && albums.isEmpty) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: SimpleAsFTheme.surfaceElevatedColor(context),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? Colors.white.withValues(alpha: 0.06) : Theme.of(context).colorScheme.outlineVariant,
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: SimpleAsFTheme.accent(context).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Center(
                child: Icon(
                  LucideIcons.music,
                  size: 20,
                  color: SimpleAsFTheme.accent(context),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No playback history yet',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: SimpleAsFTheme.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Play your favorite tracks to populate Recently Played.',
                    style: TextStyle(
                      fontSize: 11,
                      color: SimpleAsFTheme.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int crossAxisCount;
        if (width >= 1200) {
          crossAxisCount = 5;
        } else if (width >= 900) {
          crossAxisCount = 4;
        } else if (width >= 600) {
          crossAxisCount = 3;
        } else {
          crossAxisCount = 2;
        }

        // Enforce 2x2 grid (4 items) on mobile (<600px)
        final int maxItems = crossAxisCount == 2 ? 4 : 8;
        final int itemCount = hasRecent
            ? math.min(recentTracks.length, maxItems)
            : math.min(albums.length, maxItems);

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 14,
            mainAxisSpacing: 16,
            childAspectRatio: 0.78,
          ),
          itemCount: itemCount,
          itemBuilder: (context, index) {
            if (hasRecent) {
              final track = recentTracks[index];
              return _buildTrackCard(context, ref, track, recentTracks, index);
            } else {
              final album = albums[index];
              return _buildAlbumCard(context, ref, album);
            }
          },
        );
      },
    );
  }

  Widget _buildTrackCard(
    BuildContext context,
    WidgetRef ref,
    Track track,
    List<Track> queue,
    int index,
  ) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        AppHaptics.mediumImpact();
        ref.read(playerControllerProvider.notifier).setQueue(queue, initialIndex: index);
      },
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Squircle Cover Art Card
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : theme.colorScheme.outlineVariant,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(19),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    StudioArtworkWidget(
                      track: track,
                      width: double.infinity,
                      height: double.infinity,
                      borderRadius: BorderRadius.circular(19),
                      fallbackIcon: LucideIcons.music,
                      fallbackIconSize: 32,
                    ),

                    // Subtle play button overlay
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: GestureDetector(
                        onTap: () {
                          AppHaptics.mediumImpact();
                          ref.read(playerControllerProvider.notifier).setQueue(queue, initialIndex: index);
                        },
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: SimpleAsFTheme.accent(context),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              LucideIcons.play,
                              size: 16,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Title below artwork
          Text(
            track.title,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : theme.colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),

          // Artist below title
          Text(
            track.artist,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? SimpleAsFTheme.sageSlate : theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildAlbumCard(BuildContext context, WidgetRef ref, AlbumModel album) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final firstTrack = album.tracks.isNotEmpty ? album.tracks.first : null;

    return InkWell(
      onTap: () {
        AppHaptics.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => AlbumDetailScreen(album: album),
          ),
        );
      },
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Squircle Album Art Card
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : theme.colorScheme.outlineVariant,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(19),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (firstTrack != null)
                      StudioArtworkWidget(
                        track: firstTrack,
                        width: double.infinity,
                        height: double.infinity,
                        borderRadius: BorderRadius.circular(19),
                        fallbackIcon: LucideIcons.disc,
                        fallbackIconSize: 32,
                      )
                    else
                      Container(
                        color: isDark ? const Color(0xFF14221A) : theme.colorScheme.surfaceContainerHighest,
                        child: Center(
                          child: Icon(
                            LucideIcons.disc,
                            size: 32,
                            color: isDark ? SimpleAsFTheme.sageSlate : theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),

                    // Subtle play button overlay
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: GestureDetector(
                        onTap: () {
                          if (album.tracks.isNotEmpty) {
                            AppHaptics.mediumImpact();
                            ref.read(playerControllerProvider.notifier).setQueue(
                              album.tracks,
                              initialIndex: 0,
                            );
                          }
                        },
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: SimpleAsFTheme.accent(context),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              LucideIcons.play,
                              size: 16,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Title below artwork
          Text(
            album.name,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : theme.colorScheme.onSurface,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),

          // Subtitle / Artist below title
          Text(
            album.artist.isNotEmpty ? album.artist : '${album.tracks.length} Tracks',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isDark ? SimpleAsFTheme.sageSlate : theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
