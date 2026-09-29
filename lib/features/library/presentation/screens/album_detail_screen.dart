import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../../../app/theme/studio_surface_theme.dart';
import '../../../../core/widgets/studio_artwork_widget.dart';
import '../../../player/domain/track.dart';
import '../../../player/presentation/controllers/player_controller.dart';
import '../../domain/library_collection_models.dart';
import '../controllers/library_controller.dart';
import '../widgets/batch_track_tag_editor_modal.dart';
import '../widgets/studio_track_action_sheet.dart';
import 'artist_detail_screen.dart';

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

/// Dedicated Studio Album Detail Screen (Namida & Spotify Grade with Collapsing Sliver Header)
class AlbumDetailScreen extends ConsumerStatefulWidget {
  final AlbumModel album;

  const AlbumDetailScreen({
    super.key,
    required this.album,
  });

  @override
  ConsumerState<AlbumDetailScreen> createState() => _AlbumDetailScreenState();
}

class _AlbumDetailScreenState extends ConsumerState<AlbumDetailScreen> {
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

  void _navigateToArtist(BuildContext context, String artistName) {
    final libraryState = ref.read(unifiedLibraryProvider);
    final artist = libraryState.artists.firstWhere(
      (a) => a.name.toLowerCase() == artistName.toLowerCase(),
      orElse: () => ArtistModel(
        name: artistName,
        tracks: widget.album.tracks.where((t) => t.artist.toLowerCase() == artistName.toLowerCase()).toList(),
      ),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArtistDetailScreen(artist: artist),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isSolid = ref.isSolidStyle;
    final playback = ref.watch(playerControllerProvider);
    final currentPlayingTrack = playback.currentTrack;
    final isPlaying = playback.isPlaying;
    final isLoading = playback.isLoading;
    final isCurrentAlbumActive = currentPlayingTrack != null &&
        widget.album.tracks.any((t) => t.id == currentPlayingTrack.id);
    final isCurrentAlbumBuffering = isLoading && isCurrentAlbumActive;
    final isCurrentAlbumPlaying = isPlaying && isCurrentAlbumActive;
    final isHeaderActive = isCurrentAlbumPlaying || isCurrentAlbumBuffering;

    final statusBarHeight = MediaQuery.paddingOf(context).top;
    final expandedHeight = 290.0 + statusBarHeight;
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
                  child: const HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowLeft01,
                    size: 18,
                    color: null,
                  ),
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                IconButton(
                  tooltip: 'Batch Edit Album Tags',
                  icon: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid, translucentAlpha: 0.85),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid, translucentAlpha: 0.5)),
                    ),
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedEdit02,
                      size: 18,
                      color: primary,
                    ),
                  ),
                  onPressed: () {
                    BatchTrackTagEditorModal.show(context, widget.album.tracks);
                  },
                ),
                const SizedBox(width: 8),
              ],
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

                      // EXPANDED STATE (Large Artwork & Full Album Metadata)
                      if (expandedOpacity > 0.0)
                        Opacity(
                          opacity: expandedOpacity,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(20, statusBarHeight + 48, 20, 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Album Cover Art with Squircle Studio Border
                                Hero(
                                  tag: 'album_art_${widget.album.name}_${widget.album.artist}',
                                  child: Container(
                                    width: 130,
                                    height: 130,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: theme.colorScheme.outlineVariant.withValues(alpha: 0.6),
                                        width: 1.0,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.25),
                                          blurRadius: 16,
                                          offset: const Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: StudioArtworkWidget(
                                      track: widget.album.firstTrack,
                                      bytes: widget.album.coverBytes,
                                      url: widget.album.coverUrl,
                                      borderRadius: BorderRadius.circular(17),
                                      fallbackIconSize: 44,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                // Album Details
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
                                            widget.album.isHiRes ? const Color(0xFFFFD700) : primary,
                                            isSolid: isSolid,
                                            translucentAlpha: 0.15,
                                          ),
                                          borderRadius: BorderRadius.circular(6),
                                          border: Border.all(
                                            color: (widget.album.isHiRes
                                                    ? const Color(0xFFFFD700)
                                                    : primary)
                                                .withValues(alpha: isSolid ? 0.6 : 0.4),
                                            width: 0.8,
                                          ),
                                        ),
                                        child: Text(
                                          widget.album.isHiRes ? 'HI-RES LOSSLESS' : 'STUDIO ALBUM',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: 0.6,
                                            color: widget.album.isHiRes
                                                ? const Color(0xFFFFD700)
                                                : primary,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        widget.album.name,
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          height: 1.2,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      InkWell(
                                        onTap: () => _navigateToArtist(context, widget.album.artist),
                                        borderRadius: BorderRadius.circular(4),
                                        child: Text(
                                          widget.album.artist,
                                          style: TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: primary,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${widget.album.trackCount} Tracks • ${_formatTotalDuration(widget.album.totalDuration)}${widget.album.year != null ? " • ${widget.album.year}" : ""}',
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

                      // COLLAPSED STATE (Compact Sticky Bar with Mini Artwork + Album Title + Artist)
                      if (isCollapsed && collapsedOpacity > 0.0)
                        Positioned(
                          left: 56,
                          right: 56,
                          top: statusBarHeight,
                          height: kToolbarHeight,
                          child: Opacity(
                            opacity: collapsedOpacity,
                            child: Row(
                              children: [
                                Container(
                                  width: 34,
                                  height: 34,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: StudioArtworkWidget(
                                    track: widget.album.firstTrack,
                                    bytes: widget.album.coverBytes,
                                    url: widget.album.coverUrl,
                                    borderRadius: BorderRadius.circular(7),
                                    fallbackIconSize: 18,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.album.name,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        widget.album.artist,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: primary,
                                          fontWeight: FontWeight.w600,
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
                            if (widget.album.tracks.isNotEmpty) {
                              HapticFeedback.lightImpact();
                              ref.read(playerControllerProvider.notifier).setQueue(
                                    widget.album.tracks,
                                    initialIndex: 0,
                                  );
                            }
                          },
                          icon: isCurrentAlbumBuffering
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
                              : HugeIcon(
                                  icon: isCurrentAlbumPlaying ? HugeIcons.strokeRoundedPause : HugeIcons.strokeRoundedPlay,
                                  size: 18,
                                  color: isHeaderActive ? theme.colorScheme.onPrimary : theme.colorScheme.onPrimaryContainer,
                                ),
                          label: Text(
                            isCurrentAlbumBuffering
                                ? 'Buffering...'
                                : (isCurrentAlbumPlaying ? 'Playing' : 'Play All'),
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
                            if (widget.album.tracks.isNotEmpty) {
                              HapticFeedback.lightImpact();
                              final shuffled = List<Track>.from(widget.album.tracks)..shuffle();
                              ref.read(playerControllerProvider.notifier).setQueue(
                                    shuffled,
                                    initialIndex: 0,
                                  );
                            }
                          },
                          icon: HugeIcon(
                            icon: HugeIcons.strokeRoundedShuffle,
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
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 140),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, idx) {
                    final track = widget.album.tracks[idx];
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
                                width: 24,
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
                                          ? HugeIcon(
                                              icon: HugeIcons.strokeRoundedAudioWaveform,
                                              size: 16,
                                              color: primary,
                                            )
                                          : Text(
                                              (idx + 1).toString().padLeft(2, '0'),
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w800,
                                                color: isCurrent
                                                    ? primary
                                                    : theme.colorScheme.onSurface.withValues(alpha: 0.45),
                                                fontFeatures: const [FontFeature.tabularFigures()],
                                              ),
                                            )),
                                ),
                              ),
                              const SizedBox(width: 8),
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
                          subtitle: Row(
                            children: [
                              if (track.isHiRes) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFD700).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: const Text(
                                    'HI-RES',
                                    style: TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFFFD700),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                              ],
                              Text(
                                track.format.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
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
                                icon: HugeIcon(
                                  icon: HugeIcons.strokeRoundedMoreVertical,
                                  size: 18,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                ),
                                onPressed: () => StudioTrackActionSheet.show(context, track),
                              ),
                            ],
                          ),
                          onTap: () {
                            HapticFeedback.selectionClick();
                            ref.read(playerControllerProvider.notifier).setQueue(
                                  widget.album.tracks,
                                  initialIndex: idx,
                                );
                          },
                        ),
                      ),
                    );
                  },
                  childCount: widget.album.tracks.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
