import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

import '../../../../app/theme/studio_surface_theme.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/studio_artwork_widget.dart';
import '../../../player/domain/track.dart';
import '../../../player/presentation/controllers/player_controller.dart';
import '../../domain/library_collection_models.dart';
import '../../domain/m3u8_playlist_service.dart';
import '../../domain/smart_playlist_models.dart';
import '../controllers/library_controller.dart';
import '../widgets/create_custom_playlist_modal.dart';
import '../widgets/create_smart_playlist_dialog.dart';
import '../widgets/studio_playlist_action_sheet.dart';
import '../widgets/track_tile.dart';
import '../../../download_manager/presentation/controllers/download_controller.dart';
import '../../../../app/theme/app_haptics.dart';

/// Sticky Action Bar Header Delegate
class _StickyPlaylistActionBarDelegate extends SliverPersistentHeaderDelegate {
  final double height;
  final Widget child;

  _StickyPlaylistActionBarDelegate({
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
  bool shouldRebuild(covariant _StickyPlaylistActionBarDelegate oldDelegate) {
    return oldDelegate.height != height || oldDelegate.child != child;
  }
}

/// Dedicated Studio Playlist & Smart Playlist Detail Screen
class PlaylistDetailScreen extends ConsumerStatefulWidget {
  final PlaylistModel? playlist;
  final SmartPlaylist? smartPlaylist;

  const PlaylistDetailScreen({
    super.key,
    this.playlist,
    this.smartPlaylist,
  }) : assert(playlist != null || smartPlaylist != null, 'Must provide either playlist or smartPlaylist');

  @override
  ConsumerState<PlaylistDetailScreen> createState() => _PlaylistDetailScreenState();
}

class _PlaylistDetailScreenState extends ConsumerState<PlaylistDetailScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _formatTotalDuration(Duration duration) {
    if (duration.inHours > 0) {
      final hrs = duration.inHours;
      final mins = duration.inMinutes.remainder(60);
      return '${hrs}h ${mins}m';
    }
    return '${duration.inMinutes} mins';
  }

  void _exportM3u8(BuildContext context, String name, List<Track> tracks) async {
    final m3u8 = M3u8PlaylistService.generateM3u8(playlistName: name, tracks: tracks);
    await Clipboard.setData(ClipboardData(text: m3u8));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Playlist "$name" exported as M3U8 (${tracks.length} tracks copied to clipboard).',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isSolid = ref.isSolidStyle;
    final libraryState = ref.watch(unifiedLibraryProvider);
    final activeTrackId =
        ref.watch(playerControllerProvider.select((s) => s.currentTrack?.id));
    final isPlaying =
        ref.watch(playerControllerProvider.select((s) => s.isPlaying));

    // Resolve active playlist and track list
    PlaylistModel? currentPlaylist;
    SmartPlaylist? currentSmartPlaylist;
    List<Track> tracks = [];

    if (widget.smartPlaylist != null) {
      currentSmartPlaylist = libraryState.smartPlaylists.firstWhere(
        (p) => p.id == widget.smartPlaylist!.id,
        orElse: () => widget.smartPlaylist!,
      );
      tracks = libraryState.getSmartPlaylistTracks(currentSmartPlaylist);
    } else if (widget.playlist != null) {
      currentPlaylist = libraryState.playlists.firstWhere(
        (p) => p.id == widget.playlist!.id,
        orElse: () => widget.playlist!,
      );
      tracks = currentPlaylist.tracks;
    }

    final title = currentPlaylist?.name ?? currentSmartPlaylist?.name ?? 'Playlist';
    final description = currentPlaylist?.description ?? currentSmartPlaylist?.description ?? '';
    final isPreset = currentSmartPlaylist?.isPreset ?? false;
    final totalDuration = tracks.fold(Duration.zero, (sum, t) => sum + t.duration);
    final durationText = _formatTotalDuration(totalDuration);

    final coverUrl = currentPlaylist?.coverUrl ??
        (tracks.isNotEmpty ? tracks.firstWhere((t) => t.albumArtUrl != null && t.albumArtUrl!.isNotEmpty, orElse: () => tracks.first).albumArtUrl : null);

    final statusBarHeight = MediaQuery.paddingOf(context).top;
    final isSmart = currentSmartPlaylist != null;
    final expandedHeight = (isSmart ? 290.0 : 255.0) + statusBarHeight;
    final minHeight = kToolbarHeight + statusBarHeight;

    final accentColor = isSmart
        ? primary
        : (currentPlaylist?.id == 'favorites'
            ? theme.colorScheme.tertiary
            : (currentPlaylist?.id == 'hires_master'
                ? theme.colorScheme.secondary
                : primary));

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Scrollbar(
        controller: _scrollController,
        thumbVisibility: true,
        interactive: true,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            // Studio Collapsing Sliver AppBar
            SliverAppBar(
              expandedHeight: expandedHeight,
              collapsedHeight: kToolbarHeight,
              pinned: true,
              backgroundColor: StudioSurfaceTheme.surface(context, isSolid: isSolid),
              surfaceTintColor: Colors.transparent,
              leading: M3EIconButton(
                variant: M3EIconButtonVariant.standard,
                icon: Icon(
                  LucideIcons.arrowLeft,
                  size: 20,
                  color: theme.colorScheme.onSurface,
                ),
                onPressed: () => Navigator.of(context).pop(),
              ),
              actions: [
                M3EIconButton(
                  variant: M3EIconButtonVariant.standard,
                  icon: Icon(
                    LucideIcons.moreVertical,
                    size: 20,
                    color: theme.colorScheme.onSurface,
                  ),
                  onPressed: () {
                    if (isSmart) {
                      StudioPlaylistActionSheet.showForSmartPlaylist(
                        context,
                        smartPlaylist: currentSmartPlaylist!,
                        tracks: tracks,
                        onDeleted: () {
                          if (context.mounted && Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                      );
                    } else {
                      StudioPlaylistActionSheet.showForPlaylist(
                        context,
                        playlist: currentPlaylist!,
                        onDeleted: () {
                          if (context.mounted && Navigator.of(context).canPop()) {
                            Navigator.of(context).pop();
                          }
                        },
                      );
                    }
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
                      // Ambient Tint Background
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              accentColor.withValues(alpha: isSolid ? 0.20 : 0.12 + (0.08 * (1.0 - collapseRatio))),
                              theme.colorScheme.surfaceContainerHighest.withValues(alpha: isSolid ? 0.35 : 0.2),
                              StudioSurfaceTheme.surface(context, isSolid: isSolid),
                            ],
                            stops: const [0.0, 0.7, 1.0],
                          ),
                        ),
                      ),

                      // EXPANDED HEADER
                      if (expandedOpacity > 0.0)
                        Opacity(
                          opacity: expandedOpacity,
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(20, statusBarHeight + 16, 20, 12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.end,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 72,
                                      height: 72,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: accentColor.withValues(alpha: 0.35),
                                          width: 1.0,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(15),
                                        child: StudioArtworkWidget(
                                          url: coverUrl,
                                          width: 72,
                                          height: 72,
                                          fallbackIcon: isSmart
                                              ? LucideIcons.slidersHorizontal
                                              : (currentPlaylist?.id == 'favorites'
                                                  ? LucideIcons.heart
                                                  : (currentPlaylist?.id == 'hires_master'
                                                      ? LucideIcons.sparkles
                                                      : LucideIcons.listMusic)),
                                          fallbackIconSize: 32,
                                          fallbackColor: accentColor,
                                          backgroundColor: StudioSurfaceTheme.tintedContainer(
                                            context,
                                            accentColor,
                                            isSolid: isSolid,
                                            translucentAlpha: 0.18,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Expanded(
                                                child: Text(
                                                  title,
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w900,
                                                    letterSpacing: -0.2,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                              if (isPreset)
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: StudioSurfaceTheme.tintedContainer(
                                                      context,
                                                      theme.colorScheme.tertiary,
                                                      isSolid: isSolid,
                                                      translucentAlpha: 0.15,
                                                    ),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: Text(
                                                    'PRESET',
                                                    style: TextStyle(
                                                      fontSize: 9,
                                                      fontWeight: FontWeight.w900,
                                                      color: theme.colorScheme.tertiary,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            description.isNotEmpty
                                                ? description
                                                : (isSmart ? 'Dynamic Smart Rule Playlist' : 'Studio Playlist Collection'),
                                            style: TextStyle(
                                              fontSize: 11.5,
                                              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 5),
                                          Row(
                                            children: [
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                                decoration: BoxDecoration(
                                                  color: StudioSurfaceTheme.tintedContainer(
                                                    context,
                                                    accentColor,
                                                    isSolid: isSolid,
                                                    translucentAlpha: 0.12,
                                                  ),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(
                                                    color: accentColor.withValues(alpha: 0.35),
                                                    width: 0.8,
                                                  ),
                                                ),
                                                child: Text(
                                                  '${tracks.length} TRACKS',
                                                  style: TextStyle(
                                                    fontSize: 9.5,
                                                    fontWeight: FontWeight.w800,
                                                    color: accentColor,
                                                    fontFeatures: AppTypography.audioFigures,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                durationText,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                                  fontFeatures: AppTypography.audioFigures,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                // Smart Playlist Rules Bar
                                if (isSmart && currentSmartPlaylist!.rules.isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    physics: const BouncingScrollPhysics(),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                          decoration: BoxDecoration(
                                            color: StudioSurfaceTheme.tintedContainer(
                                              context,
                                              primary,
                                              isSolid: isSolid,
                                              translucentAlpha: 0.15,
                                            ),
                                            borderRadius: BorderRadius.circular(6),
                                            border: Border.all(color: primary.withValues(alpha: 0.4), width: 0.8),
                                          ),
                                          child: Text(
                                            currentSmartPlaylist.matchMode == SmartPlaylistMatchMode.all
                                                ? 'MATCH ALL (AND)'
                                                : 'MATCH ANY (OR)',
                                            style: TextStyle(
                                              fontSize: 9.5,
                                              fontWeight: FontWeight.w900,
                                              color: primary,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        ...currentSmartPlaylist.rules.map(
                                          (r) => Container(
                                            margin: const EdgeInsets.only(right: 6),
                                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                            decoration: BoxDecoration(
                                              color: isSolid
                                                  ? theme.colorScheme.surfaceContainerHighest
                                                  : StudioSurfaceTheme.surfaceContainer(context, isSolid: false),
                                              borderRadius: BorderRadius.circular(6),
                                              border: Border.all(
                                                color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                                                width: 0.8,
                                              ),
                                            ),
                                            child: Text(
                                              '${r.field.label} ${r.operator.label} ${r.value}',
                                              style: TextStyle(
                                                fontSize: 9.5,
                                                fontWeight: FontWeight.w600,
                                                color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),

                      // COLLAPSED TITLE
                      if (isCollapsed)
                        Opacity(
                          opacity: collapsedOpacity,
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Padding(
                              padding: const EdgeInsets.only(left: 60, right: 60),
                              child: Row(
                                children: [
                                  if (coverUrl != null && coverUrl.isNotEmpty) ...[
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: SizedBox(
                                        width: 28,
                                        height: 28,
                                        child: StudioArtworkWidget(
                                          url: coverUrl,
                                          width: 28,
                                          height: 28,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                  ],
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: const TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.4,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),

            // Sticky Action Bar
            SliverPersistentHeader(
              pinned: true,
              delegate: _StickyPlaylistActionBarDelegate(
                height: 56.0,
                child: Container(
                  color: StudioSurfaceTheme.surface(context, isSolid: isSolid),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: M3EButton.filled(
                          onPressed: () {
                            if (tracks.isNotEmpty) {
                              ref.read(playerControllerProvider.notifier).setQueue(tracks, initialIndex: 0);
                            }
                          },
                          icon: const Icon(
                            LucideIcons.play,
                            size: 18,
                            color: Colors.black,
                          ),
                          label: const Text('Play All', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      M3EButton.outlined(
                        onPressed: () {
                          if (tracks.isNotEmpty) {
                            final list = List<Track>.from(tracks)..shuffle();
                            ref.read(playerControllerProvider.notifier).setQueue(list, initialIndex: 0);
                          }
                        },
                        icon: Icon(
                          LucideIcons.shuffle,
                          size: 16,
                          color: accentColor,
                        ),
                        label: const Text('Shuffle', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: 8),
                      M3EIconButton(
                        variant: M3EIconButtonVariant.tonal,
                        icon: Icon(LucideIcons.download, size: 20, color: accentColor),
                        tooltip: 'Download All Tracks',
                        onPressed: () {
                          if (tracks.isNotEmpty) {
                            AppHaptics.mediumImpact();
                            ref.read(downloadControllerProvider.notifier).enqueueTracks(tracks);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Enqueued ${tracks.length} tracks for download.'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                      ),
                      const SizedBox(width: 4),
                      if (isSmart)
                        M3EIconButton(
                          variant: M3EIconButtonVariant.tonal,
                          icon: Icon(LucideIcons.pencil, size: 20, color: accentColor),
                          tooltip: 'Edit Rules',
                          onPressed: () => CreateSmartPlaylistDialog.show(context, initialPlaylist: currentSmartPlaylist),
                        )
                      else if (currentPlaylist?.isCustom == true)
                        M3EIconButton(
                          variant: M3EIconButtonVariant.tonal,
                          icon: Icon(LucideIcons.pencil, size: 20, color: accentColor),
                          tooltip: 'Edit Details',
                          onPressed: () => CreateCustomPlaylistModal.show(context, initialPlaylist: currentPlaylist),
                        ),
                      const SizedBox(width: 4),
                      M3EIconButton(
                        variant: M3EIconButtonVariant.tonal,
                        icon: Icon(LucideIcons.share2, size: 20, color: accentColor),
                        tooltip: 'Export M3U8',
                        onPressed: () => _exportM3u8(context, title, tracks),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Track List or Empty State
            if (tracks.isEmpty)
              SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
                      decoration: BoxDecoration(
                        color: StudioSurfaceTheme.surfaceContainerLow(context, isSolid: isSolid, translucentAlpha: 0.3),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isSmart
                                ? LucideIcons.slidersHorizontal
                                : LucideIcons.listMusic,
                            size: 36,
                            color: theme.dividerColor,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            isSmart ? 'NO MATCHING TRACKS' : 'NO TRACKS IN PLAYLIST',
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isSmart
                                ? 'No audio tracks in your library currently match these smart conditions.'
                                : 'Add tracks to this playlist from your library or song action menus.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 120),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final track = tracks[index];
                      final isTrackPlaying = activeTrackId == track.id && isPlaying;
                      return TrackTile(
                        track: track,
                        isPlaying: isTrackPlaying,
                        onTap: () {
                          ref.read(playerControllerProvider.notifier).setQueue(tracks, initialIndex: index);
                        },
                      );
                    },
                    childCount: tracks.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
