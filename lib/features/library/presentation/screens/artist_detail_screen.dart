import 'dart:ui' show ImageFilter, FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../../core/widgets/studio_artwork_widget.dart';
import '../../../player/domain/track.dart';
import '../../../player/presentation/controllers/player_controller.dart';
import '../../data/artist_metadata_service.dart';
import '../../domain/library_collection_models.dart';
import '../controllers/library_controller.dart';
import '../widgets/artist_avatar_widget.dart';
import '../widgets/studio_track_action_sheet.dart';
import 'album_detail_screen.dart';

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

/// Dedicated Studio Artist Detail Screen (Namida & Spotify Grade with Collapsing Sliver Header)
class ArtistDetailScreen extends ConsumerStatefulWidget {
  final ArtistModel artist;

  const ArtistDetailScreen({
    super.key,
    required this.artist,
  });

  @override
  ConsumerState<ArtistDetailScreen> createState() => _ArtistDetailScreenState();
}

class _ArtistDetailScreenState extends ConsumerState<ArtistDetailScreen> {
  final ScrollController _scrollController = ScrollController();
  String? _artistPhotoUrl;

  @override
  void initState() {
    super.initState();
    _fetchArtistPhoto();
  }

  @override
  void didUpdateWidget(covariant ArtistDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.artist.name != widget.artist.name) {
      _fetchArtistPhoto();
    }
  }

  Future<void> _fetchArtistPhoto() async {
    final url = await ArtistMetadataService.instance.getArtistImageUrl(widget.artist.name);
    if (mounted) {
      setState(() {
        _artistPhotoUrl = url;
      });
    }
  }

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
    final libraryState = ref.watch(unifiedLibraryProvider);
    final playback = ref.watch(playerControllerProvider);
    final currentPlayingTrack = playback.currentTrack;
    final isPlaying = playback.isPlaying;
    final isLoading = playback.isLoading;

    final isCurrentArtistActive = currentPlayingTrack != null &&
        widget.artist.tracks.any((t) => t.id == currentPlayingTrack.id);
    final isCurrentArtistBuffering = isLoading && isCurrentArtistActive;
    final isCurrentArtistPlaying = isPlaying && isCurrentArtistActive;
    final isHeaderActive = isCurrentArtistPlaying || isCurrentArtistBuffering;

    // Discover albums by this artist
    final artistAlbums = libraryState.albums.where((a) {
      if (a.artist.toLowerCase() == widget.artist.name.toLowerCase()) return true;
      return widget.artist.tracks.any((t) => t.album.toLowerCase() == a.name.toLowerCase());
    }).toList();

    final totalDuration = widget.artist.tracks.fold(Duration.zero, (sum, t) => sum + t.duration);
    final statusBarHeight = MediaQuery.paddingOf(context).top;
    final expandedHeight = 270.0 + statusBarHeight;
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

                  final hasCollage = artistAlbums.length >= 4;
                  final hasArtistPhoto = _artistPhotoUrl != null && _artistPhotoUrl!.isNotEmpty;
                  final hasSingleCover = artistAlbums.isNotEmpty || widget.artist.coverBytes != null || widget.artist.coverUrl != null;

                  return Stack(
                    fit: StackFit.expand,
                    children: [
                      // DYNAMIC AMBIENT BACKDROP: 2x2 Collage (if >=4 albums) or Artist Photo/Single Cover (if <4 albums)
                      if (hasCollage)
                        ClipRect(
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                            child: Transform.scale(
                              scale: 1.15,
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: StudioArtworkWidget(
                                            track: artistAlbums[0].firstTrack,
                                            bytes: artistAlbums[0].coverBytes,
                                            url: artistAlbums[0].coverUrl,
                                            borderRadius: BorderRadius.zero,
                                          ),
                                        ),
                                        Expanded(
                                          child: StudioArtworkWidget(
                                            track: artistAlbums[1].firstTrack,
                                            bytes: artistAlbums[1].coverBytes,
                                            url: artistAlbums[1].coverUrl,
                                            borderRadius: BorderRadius.zero,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    child: Column(
                                      children: [
                                        Expanded(
                                          child: StudioArtworkWidget(
                                            track: artistAlbums[2].firstTrack,
                                            bytes: artistAlbums[2].coverBytes,
                                            url: artistAlbums[2].coverUrl,
                                            borderRadius: BorderRadius.zero,
                                          ),
                                        ),
                                        Expanded(
                                          child: StudioArtworkWidget(
                                            track: artistAlbums[3].firstTrack,
                                            bytes: artistAlbums[3].coverBytes,
                                            url: artistAlbums[3].coverUrl,
                                            borderRadius: BorderRadius.zero,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else if (hasArtistPhoto)
                        ClipRect(
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(sigmaX: 7.0, sigmaY: 7.0),
                            child: Transform.scale(
                              scale: 1.15,
                              child: Image.network(
                                _artistPhotoUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, _, _) => const SizedBox.shrink(),
                              ),
                            ),
                          ),
                        )
                      else if (hasSingleCover)
                        ClipRect(
                          child: ImageFiltered(
                            imageFilter: ImageFilter.blur(sigmaX: 12.0, sigmaY: 12.0),
                            child: Transform.scale(
                              scale: 1.15,
                              child: StudioArtworkWidget(
                                track: artistAlbums.isNotEmpty ? artistAlbums.first.firstTrack : widget.artist.tracks.firstOrNull,
                                bytes: artistAlbums.isNotEmpty ? artistAlbums.first.coverBytes : widget.artist.coverBytes,
                                url: artistAlbums.isNotEmpty ? artistAlbums.first.coverUrl : widget.artist.coverUrl,
                                borderRadius: BorderRadius.zero,
                              ),
                            ),
                          ),
                        ),

                      // Studio Gradient & Scrim Overlay for Readability and Seamless Bottom Blending
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              (hasCollage || hasArtistPhoto || hasSingleCover)
                                  ? theme.colorScheme.surface.withValues(alpha: 0.40 + (0.55 * collapseRatio))
                                  : primary.withValues(alpha: 0.08 + (0.07 * (1.0 - collapseRatio))),
                              theme.colorScheme.surface.withValues(alpha: 0.72 + (0.26 * collapseRatio)),
                              theme.colorScheme.surface,
                            ],
                            stops: const [0.0, 0.65, 1.0],
                          ),
                        ),
                      ),

                      // EXPANDED STATE (Large Circular Avatar & Discography Meta)
                      if (expandedOpacity > 0.0)
                        Opacity(
                          opacity: expandedOpacity,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(20, statusBarHeight + 48, 20, 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Artist Circular Avatar with Squircle/Circle Glow & Tap to Zoom Lightbox
                                ArtistAvatarWidget(
                                  artistName: widget.artist.name,
                                  fallbackCoverBytes: widget.artist.coverBytes,
                                  fallbackCoverUrl: widget.artist.coverUrl,
                                  radius: 52,
                                  iconSize: 42,
                                  enableLightboxOnTap: true,
                                ),
                                const SizedBox(width: 16),
                                // Artist Details
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
                                          'ARTIST DISCOGRAPHY',
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
                                        widget.artist.name,
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
                                        '${artistAlbums.isNotEmpty ? artistAlbums.length : widget.artist.albumsCount} Albums • ${widget.artist.tracksCount} Tracks • ${_formatTotalDuration(totalDuration)}',
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

                      // COLLAPSED STATE (Compact Sticky Bar with Mini Avatar + Artist Name)
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
                                ArtistAvatarWidget(
                                  artistName: widget.artist.name,
                                  fallbackCoverBytes: widget.artist.coverBytes,
                                  fallbackCoverUrl: widget.artist.coverUrl,
                                  radius: 16,
                                  iconSize: 16,
                                  enableLightboxOnTap: true,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        widget.artist.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        '${widget.artist.tracksCount} Tracks • ${_formatTotalDuration(totalDuration)}',
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
                            if (widget.artist.tracks.isNotEmpty) {
                              AppHaptics.lightImpact();
                              ref.read(playerControllerProvider.notifier).setQueue(
                                    widget.artist.tracks,
                                    initialIndex: 0,
                                  );
                            }
                          },
                          icon: isCurrentArtistBuffering
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
                                  isCurrentArtistPlaying ? LucideIcons.pause : LucideIcons.play,
                                  size: 18,
                                  color: isHeaderActive ? theme.colorScheme.onPrimary : theme.colorScheme.onPrimaryContainer,
                                ),
                          label: Text(
                            isCurrentArtistBuffering
                                ? 'Buffering...'
                                : (isCurrentArtistPlaying ? 'Playing' : 'Play All'),
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
                            if (widget.artist.tracks.isNotEmpty) {
                              AppHaptics.lightImpact();
                              final shuffled = List<Track>.from(widget.artist.tracks)..shuffle();
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

            // DISCOGRAPHY / ALBUMS SECTION (Namida & Spotify Grade Horizontal Carousel)
            if (artistAlbums.isNotEmpty) ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.disc,
                        size: 16,
                        color: primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ALBUMS & RELEASES (${artistAlbums.length})',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 175,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    itemCount: artistAlbums.length,
                    itemBuilder: (context, idx) {
                      final album = artistAlbums[idx];
                      return Container(
                        width: 120,
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            AppHaptics.selectionClick();
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AlbumDetailScreen(album: album),
                              ),
                            );
                          },
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 120,
                                height: 120,
                                decoration: BoxDecoration(
                                  color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                                    width: 0.8,
                                  ),
                                ),
                                child: StudioArtworkWidget(
                                  track: album.firstTrack,
                                  bytes: album.coverBytes,
                                  url: album.coverUrl,
                                  borderRadius: BorderRadius.circular(13),
                                  fallbackIconSize: 32,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                album.name,
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${album.trackCount} Tracks${album.year != null ? " • ${album.year}" : ""}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(
                child: Divider(height: 16, indent: 16, endIndent: 16),
              ),
            ],

            // ALL SONGS SECTION HEADER
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
                child: Row(
                  children: [
                    Icon(
                      LucideIcons.music,
                      size: 16,
                      color: primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ALL SONGS (${widget.artist.tracks.length})',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Tracklist Items
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 140),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, idx) {
                    final track = widget.artist.tracks[idx];
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
                            '${track.album} • ${track.format.name.toUpperCase()}',
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
                                  widget.artist.tracks,
                                  initialIndex: idx,
                                );
                          },
                        ),
                      ),
                    );
                  },
                  childCount: widget.artist.tracks.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
