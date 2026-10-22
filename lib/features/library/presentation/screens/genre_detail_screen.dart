import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../../core/widgets/studio_artwork_widget.dart';
import '../../../player/domain/track.dart';
import '../../../player/presentation/controllers/player_controller.dart';
import '../../domain/genre_icon_helper.dart';
import '../../domain/library_collection_models.dart';
import '../widgets/studio_track_action_sheet.dart';

/// Reusable Sticky Action Bar Delegate for Detail Screens
class _StickyActionBarDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  _StickyActionBarDelegate({
    this.height = 54.0,
    required this.child,
  });

  @override
  double get minExtent => height;

  @override
  double get maxExtent => height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(covariant _StickyActionBarDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}

/// Dedicated Studio Genre Detail Screen (Namida & Spotify Grade with Collapsing Sliver Header)
class GenreDetailScreen extends ConsumerStatefulWidget {
  final GenreModel genre;

  const GenreDetailScreen({
    super.key,
    required this.genre,
  });

  @override
  ConsumerState<GenreDetailScreen> createState() => _GenreDetailScreenState();
}

class _GenreDetailScreenState extends ConsumerState<GenreDetailScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  String _formatTotalDuration(Duration duration) {
    if (duration.inHours > 0) {
      final hrs = duration.inHours;
      final mins = duration.inMinutes.remainder(60);
      return '${hrs}h ${mins}m';
    }
    return '${duration.inMinutes} mins';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isSolid = ref.isSolidStyle;
    final currentPlayingTrack =
        ref.watch(playerControllerProvider.select((s) => s.currentTrack));
    final isPlaying =
        ref.watch(playerControllerProvider.select((s) => s.isPlaying));
    final isLoading =
        ref.watch(playerControllerProvider.select((s) => s.isLoading));

    final isCurrentGenreActive = currentPlayingTrack != null &&
        widget.genre.tracks.any((t) => t.id == currentPlayingTrack.id);
    final isCurrentGenreBuffering = isLoading && isCurrentGenreActive;
    final isCurrentGenrePlaying = isPlaying && isCurrentGenreActive;
    final isHeaderActive = isCurrentGenrePlaying || isCurrentGenreBuffering;

    final totalDuration = widget.genre.tracks.fold(Duration.zero, (sum, t) => sum + t.duration);
    final statusBarHeight = MediaQuery.paddingOf(context).top;
    final expandedHeight = 250.0 + statusBarHeight;
    final minHeight = kToolbarHeight + statusBarHeight;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        interactive: true,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Studio Collapsing Sliver AppBar with Shrink Parallax
            SliverAppBar(
              expandedHeight: expandedHeight,
              collapsedHeight: kToolbarHeight,
              pinned: true,
              backgroundColor: StudioSurfaceTheme.surface(context, isSolid: isSolid),
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid, translucentAlpha: 0.85),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid, translucentAlpha: 0.5)),
                  ),
                  child: Icon(
                    LucideIcons.arrowLeft,
                    size: 18,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              flexibleSpace: LayoutBuilder(
                builder: (context, constraints) {
                  final currentHeight = constraints.biggest.height;
                  final collapseRatio = ((expandedHeight - currentHeight) / (expandedHeight - minHeight)).clamp(0.0, 1.0);
                  final isCollapsed = collapseRatio > 0.65;
                  final collapsedOpacity = ((collapseRatio - 0.65) / 0.35).clamp(0.0, 1.0);
                  final expandedOpacity = (1.0 - (collapseRatio / 0.65)).clamp(0.0, 1.0);

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // Ambient Subtle Gradient Background
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              primary.withValues(alpha: 0.08 + (0.07 * (1.0 - collapseRatio))),
                              theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                              theme.colorScheme.surface,
                            ],
                            stops: const [0.0, 0.65, 1.0],
                          ),
                        ),
                      ),

                      // EXPANDED STATE (Large Genre Icon Box & Genre Info)
                      if (expandedOpacity > 0.0)
                        Opacity(
                          opacity: expandedOpacity,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(20, statusBarHeight + 48, 20, 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Genre Icon Container with Studio Border
                                Container(
                                  width: 96,
                                  height: 96,
                                  decoration: BoxDecoration(
                                    color: StudioSurfaceTheme.tintedContainer(context, primary, isSolid: isSolid, translucentAlpha: 0.15),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: primary.withValues(alpha: isSolid ? 0.6 : 0.4),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      GenreIconHelper.getGenreIcon(widget.genre.name),
                                      size: 42,
                                      color: primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Genre Details
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: StudioSurfaceTheme.tintedContainer(
                                            context,
                                            primary,
                                            isSolid: isSolid,
                                            translucentAlpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: primary.withValues(alpha: isSolid ? 0.6 : 0.4),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Text(
                                          'GENRE COLLECTION',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.6,
                                            color: primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        widget.genre.name,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          height: 1.2,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${widget.genre.trackCount} Tracks • ${_formatTotalDuration(totalDuration)}',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                                          fontFeatures: const [FontFeature.tabularFigures()],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // COLLAPSED STATE (Compact Sticky Bar with Mini Genre Icon + Name)
                      if (isCollapsed && collapsedOpacity > 0.0)
                        Positioned(
                          left: 56,
                          right: 16,
                          top: statusBarHeight,
                          height: kToolbarHeight,
                          child: Opacity(
                            opacity: collapsedOpacity,
                            child: Row(
                              children: [
                                Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: StudioSurfaceTheme.tintedContainer(context, primary, isSolid: isSolid, translucentAlpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: primary.withValues(alpha: isSolid ? 0.6 : 0.35),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      GenreIconHelper.getGenreIcon(widget.genre.name),
                                      size: 16,
                                      color: primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.genre.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${widget.genre.trackCount} Tracks • ${_formatTotalDuration(totalDuration)}',
                                        style: TextStyle(
                                          fontSize: 10.5,
                                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                          fontFeatures: const [FontFeature.tabularFigures()],
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),

            // PINNED STICKY ACTION BAR (Play All & Shuffle stays accessible while scrolling)
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyActionBarDelegate(
                height: 56,
                child: Container(
                  color: StudioSurfaceTheme.surface(context, isSolid: isSolid),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      // Play All Button
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            backgroundColor: isHeaderActive ? primary : theme.colorScheme.primaryContainer,
                            foregroundColor: isHeaderActive ? theme.colorScheme.onPrimary : theme.colorScheme.onPrimaryContainer,
                          ),
                          onPressed: () {
                            if (widget.genre.tracks.isNotEmpty) {
                              AppHaptics.lightImpact();
                              ref.read(playerControllerProvider.notifier).setQueue(
                                    widget.genre.tracks,
                                    initialIndex: 0,
                                  );
                            }
                          },
                          icon: isCurrentGenreBuffering
                              ? SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isHeaderActive
                                          ? theme.colorScheme.onPrimary
                                          : theme.colorScheme.onPrimaryContainer,
                                    ),
                                  ),
                                )
                              : Icon(
                                  isCurrentGenrePlaying ? LucideIcons.pause : LucideIcons.play,
                                  size: 18,
                                  color: isHeaderActive ? theme.colorScheme.onPrimary : theme.colorScheme.onPrimaryContainer,
                                ),
                          label: Text(
                            isCurrentGenreBuffering
                                ? 'Buffering...'
                                : (isCurrentGenrePlaying ? 'Playing' : 'Play All'),
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      // Shuffle Button
                      Expanded(
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            side: BorderSide(color: StudioSurfaceTheme.outline(context, isSolid: isSolid)),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () {
                            if (widget.genre.tracks.isNotEmpty) {
                              AppHaptics.lightImpact();
                              final shuffled = List<Track>.from(widget.genre.tracks)..shuffle();
                              ref.read(playerControllerProvider.notifier).setQueue(
                                    shuffled,
                                    initialIndex: 0,
                                  );
                            }
                          },
                          icon: Icon(
                            LucideIcons.shuffle,
                            size: 18,
                            color: primary,
                          ),
                          label: const Text(
                            'Shuffle',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Tracklist Items
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 140),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, idx) {
                    final track = widget.genre.tracks[idx];
                    final isCurrent = currentPlayingTrack?.id == track.id;
                    final isTrackBuffering = isCurrent && isLoading;
                    final isTrackPlaying = isCurrent && isPlaying;
                    final isTrackActive = isTrackPlaying || isTrackBuffering;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 4),
                      decoration: BoxDecoration(
                        color: isTrackActive
                            ? StudioSurfaceTheme.tintedContainer(context, primary, isSolid: isSolid, translucentAlpha: 0.1, solidBlendAlpha: 0.14)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isTrackActive
                            ? Border.all(color: isSolid ? theme.colorScheme.outline : primary.withValues(alpha: 0.35), width: 0.8)
                            : null,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                width: 20,
                                child: Center(
                                  child: isTrackBuffering
                                      ? SizedBox(
                                          width: 14,
                                          height: 14,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.8,
                                            valueColor: AlwaysStoppedAnimation<Color>(primary),
                                          ),
                                        )
                                      : (isTrackPlaying
                                          ? Icon(
                                              LucideIcons.audioLines,
                                              size: 15,
                                              color: primary,
                                            )
                                          : Text(
                                              (idx + 1).toString().padLeft(2, '0'),
                                              style: TextStyle(
                                                fontSize: 10.5,
                                                fontWeight: FontWeight.w700,
                                                color: isCurrent
                                                    ? primary
                                                    : theme.colorScheme.onSurface.withValues(alpha: 0.4),
                                                fontFeatures: const [FontFeature.tabularFigures()],
                                              ),
                                            )),
                                ),
                              ),
                              const SizedBox(width: 6),
                              StudioArtworkWidget(
                                track: track,
                                width: 38,
                                height: 38,
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ],
                          ),
                          title: Text(
                            track.title,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                              color: isCurrent ? primary : theme.colorScheme.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${track.artist} • ${track.album}',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatDuration(track.duration),
                                style: TextStyle(
                                  fontSize: 11,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                              IconButton(
                                icon: Icon(
                                  LucideIcons.moreVertical,
                                  size: 18,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                                onPressed: () => StudioTrackActionSheet.show(context, track),
                              ),
                            ],
                          ),
                          onTap: () {
                            AppHaptics.selectionClick();
                            ref.read(playerControllerProvider.notifier).setQueue(
                                  widget.genre.tracks,
                                  initialIndex: idx,
                                );
                          },
                        ),
                      ),
                    );
                  },
                  childCount: widget.genre.tracks.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
