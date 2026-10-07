import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../../audio_engine/audio_cache_service.dart';
import '../../../../core/widgets/studio_artwork_widget.dart';
import '../../../player/domain/track.dart';
import '../../../player/presentation/controllers/player_controller.dart';
import '../../../player/presentation/widgets/audio_file_inspector_sheet.dart';
import '../../../dsp_rack/domain/dsp_models.dart';
import '../../../dsp_rack/presentation/controllers/dsp_rack_controller.dart';
import '../../../dsp_rack/presentation/widgets/studio_track_dsp_preset_sheet.dart';
import '../../domain/library_collection_models.dart';
import '../controllers/library_controller.dart';
import '../screens/album_detail_screen.dart';
import '../screens/artist_detail_screen.dart';
import 'instant_mix_config_sheet.dart';
import 'metadata_tag_editor_sheet.dart';
import '../../../download_manager/presentation/controllers/download_controller.dart';

/// Unified Material 3 Expressive Studio Track Action Bottom Sheet (Spotify & Namida Grade)
class StudioTrackActionSheet extends ConsumerWidget {
  final Track track;

  const StudioTrackActionSheet({
    super.key,
    required this.track,
  });

  /// Opens the unified track action bottom sheet
  static Future<void> show(BuildContext context, Track track) {
    AppHaptics.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StudioTrackActionSheet(track: track),
    );
  }

  void _showAddToPlaylistSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetCtx) => Consumer(
        builder: (ctx, ref, _) {
          final playlists = ref.watch(unifiedLibraryProvider).customPlaylists;
          final theme = Theme.of(ctx);

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'ADD TRACK TO PLAYLIST',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                  ),
                  const SizedBox(height: 8),
                  if (playlists.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No custom playlists found. Create a new playlist first.',
                          style: TextStyle(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  else
                    ...playlists.map(
                      (p) => ListTile(
                        leading: HugeIcon(
                          icon: HugeIcons.strokeRoundedPlayList,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        title: Text(p.name),
                        subtitle: Text('${p.trackCount} tracks'),
                        onTap: () {
                          ref.read(unifiedLibraryProvider.notifier).addTrackToPlaylist(p.id, track);
                          Navigator.of(ctx).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Added "${track.title}" to "${p.name}".')),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _navigateToAlbum(BuildContext context, WidgetRef ref) {
    final libraryState = ref.read(unifiedLibraryProvider);
    final album = libraryState.albums.firstWhere(
      (a) => a.name.toLowerCase() == track.album.toLowerCase(),
      orElse: () => AlbumModel(
        name: track.album,
        artist: track.artist,
        tracks: [track],
      ),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AlbumDetailScreen(album: album),
      ),
    );
  }

  void _navigateToArtist(BuildContext context, WidgetRef ref) {
    final libraryState = ref.read(unifiedLibraryProvider);
    final artist = libraryState.artists.firstWhere(
      (a) => a.name.toLowerCase() == track.artist.toLowerCase(),
      orElse: () => ArtistModel(
        name: track.artist,
        tracks: [track],
      ),
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArtistDetailScreen(artist: artist),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isSolid = ref.isSolidStyle;
    final libraryState = ref.watch(unifiedLibraryProvider);
    final isFav = libraryState.favoriteTrackIds.contains(track.id);
    final isRemote = (track.filePath?.startsWith('http') ?? false) ||
        track.id.startsWith('subsonic_') ||
        (track.streamUrl?.isNotEmpty ?? false);
    final isCached = isRemote && AudioCacheService.instance.isCached(track.id);

    final dspController = ref.watch(dspRackControllerProvider.notifier);
    final dspResolution = dspController.resolvePresetForTrack(track);
    final isDspPinned = dspController.isTrackPinned(track.id);
    final dspSubtitle = isDspPinned
        ? 'Pinned: ${dspResolution.preset.name}'
        : (dspResolution.source == DspResolutionSource.genreAuto
            ? 'Auto (${dspResolution.matchedGenre?.toUpperCase() ?? "Genre"}): ${dspResolution.preset.name}'
            : 'Default: ${dspResolution.preset.name}');

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ─── TRACK HEADER SUMMARY ───────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
                child: Row(
                  children: [
                    // Squircle Artwork
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
                          width: 0.8,
                        ),
                      ),
                      child: StudioArtworkWidget(
                        track: track,
                        borderRadius: BorderRadius.circular(11),
                        fallbackIconSize: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Track Information
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            track.title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14.5,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${track.artist} • ${track.album}',
                            style: TextStyle(
                              fontSize: 12,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (track.isHiRes) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: StudioSurfaceTheme.tintedContainer(context, primary, isSolid: isSolid),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: isSolid ? theme.colorScheme.outline : primary.withValues(alpha: 0.4),
                                      width: 0.8,
                                    ),
                                  ),
                                  child: Text(
                                    'HI-RES',
                                    style: TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w900,
                                      color: primary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 6),
                              ],
                              Text(
                                track.format.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: primary,
                                ),
                              ),
                              if (isCached) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                  decoration: BoxDecoration(
                                    color: StudioSurfaceTheme.tintedContainer(context, theme.colorScheme.secondary, isSolid: isSolid),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    'OFFLINE CACHED',
                                    style: TextStyle(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w900,
                                      color: theme.colorScheme.secondary,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 16),

              // ─── ACTION MENU ITEMS ──────────────────────────────────────────
              // 1. Play Next
              ListTile(
                leading: HugeIcon(
                  icon: HugeIcons.strokeRoundedNext,
                  size: 20,
                  color: primary,
                ),
                title: const Text('Play Next', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                onTap: () {
                  AppHaptics.lightImpact();
                  ref.read(playerControllerProvider.notifier).playNext(track);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Playing "${track.title}" next'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),

              // 2. Add to Queue
              ListTile(
                leading: HugeIcon(
                  icon: HugeIcons.strokeRoundedPlaylist01,
                  size: 20,
                  color: theme.colorScheme.onSurface,
                ),
                title: const Text('Add to Queue', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                onTap: () {
                  AppHaptics.lightImpact();
                  ref.read(playerControllerProvider.notifier).addToQueue(track);
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added "${track.title}" to Queue'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),

              // 3. Instant Mix
              ListTile(
                leading: HugeIcon(
                  icon: HugeIcons.strokeRoundedSparkles,
                  size: 20,
                  color: primary,
                ),
                title: const Text('Instant Mix', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  'Generate smart queue from this track',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  InstantMixConfigSheet.show(context, seedTrack: track);
                },
              ),

              // 2.1 Download Track
              if (track.filePath == null || track.filePath!.isEmpty || track.remoteUrl != null)
                ListTile(
                  leading: const HugeIcon(
                    icon: HugeIcons.strokeRoundedDownload01,
                    size: 20,
                    color: Color(0xFF10B981),
                  ),
                  title: const Text('Download Track', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    'Download stream & embed studio tags for offline playback',
                    style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
                  ),
                  onTap: () {
                    AppHaptics.mediumImpact();
                    ref.read(downloadControllerProvider.notifier).enqueueTrack(track);
                    final messenger = ScaffoldMessenger.maybeOf(context);
                    Navigator.of(context).pop();
                    messenger?.showSnackBar(
                      SnackBar(
                        content: Text('Downloading "${track.title}" in background...'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),

              // 3. Add to Playlist
              ListTile(
                leading: HugeIcon(
                  icon: HugeIcons.strokeRoundedAddCircleHalfDot,
                  size: 20,
                  color: theme.colorScheme.onSurface,
                ),
                title: const Text('Add to Playlist', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.of(context).pop();
                  _showAddToPlaylistSheet(context);
                },
              ),

              // 4. Go to Album
              if (track.album.isNotEmpty && track.album != 'Unknown Album')
                ListTile(
                  leading: HugeIcon(
                    icon: HugeIcons.strokeRoundedAlbum01,
                    size: 20,
                    color: theme.colorScheme.onSurface,
                  ),
                  title: const Text('Go to Album', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  subtitle: Text(track.album, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.55))),
                  onTap: () {
                    Navigator.of(context).pop();
                    _navigateToAlbum(context, ref);
                  },
                ),

              // 5. Go to Artist
              if (track.artist.isNotEmpty && track.artist != 'Unknown Artist')
                ListTile(
                  leading: HugeIcon(
                    icon: HugeIcons.strokeRoundedUser,
                    size: 20,
                    color: theme.colorScheme.onSurface,
                  ),
                  title: const Text('Go to Artist', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  subtitle: Text(track.artist, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.55))),
                  onTap: () {
                    Navigator.of(context).pop();
                    _navigateToArtist(context, ref);
                  },
                ),

              // 6. Add to / Remove from Favorites
              ListTile(
                leading: HugeIcon(
                  icon: HugeIcons.strokeRoundedFavourite,
                  size: 22,
                  color: isFav ? const Color(0xFFFF2D55) : theme.colorScheme.onSurface,
                ),
                title: Text(
                  isFav ? 'Remove from Favorites' : 'Add to Favorites',
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                ),
                onTap: () {
                  AppHaptics.selectionClick();
                  ref.read(unifiedLibraryProvider.notifier).toggleFavorite(track.id);
                  Navigator.of(context).pop();
                },
              ),

              // 7. Download for Offline (if remote)
              if (isRemote && !isCached)
                ListTile(
                  leading: HugeIcon(
                    icon: HugeIcons.strokeRoundedDownload04,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  title: const Text('Download for Offline Playback', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                  onTap: () {
                    AppHaptics.selectionClick();
                    AudioCacheService.instance.cacheTrack(track);
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Downloading "${track.title}" for offline playback...'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                ),

              // 7.5 DSP Mastering Preset
              ListTile(
                leading: HugeIcon(
                  icon: isDspPinned
                      ? HugeIcons.strokeRoundedPin
                      : (dspResolution.source == DspResolutionSource.genreAuto
                          ? HugeIcons.strokeRoundedSparkles
                          : HugeIcons.strokeRoundedSlidersHorizontal),
                  size: 20,
                  color: isDspPinned ? primary : theme.colorScheme.onSurface,
                ),
                title: const Text('DSP Mastering Preset', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                subtitle: Text(
                  dspSubtitle,
                  style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.55)),
                ),
                trailing: isDspPinned
                    ? Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'PINNED',
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                            color: primary,
                          ),
                        ),
                      )
                    : null,
                onTap: () {
                  Navigator.of(context).pop();
                  StudioTrackDspPresetSheet.show(context, track);
                },
              ),

              const Divider(height: 12),

              // 8. Edit Metadata Tags
              ListTile(
                leading: HugeIcon(
                  icon: HugeIcons.strokeRoundedEdit02,
                  size: 20,
                  color: theme.colorScheme.onSurface,
                ),
                title: const Text('Edit Metadata Tags', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.of(context).pop();
                  MetadataTagEditorSheet.show(context, track);
                },
              ),

              // 9. Inspect Audio File Specs
              ListTile(
                leading: HugeIcon(
                  icon: HugeIcons.strokeRoundedInformationCircle,
                  size: 20,
                  color: theme.colorScheme.onSurface,
                ),
                title: const Text('Inspect Audio Specs', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                onTap: () {
                  Navigator.of(context).pop();
                  AudioFileInspectorSheet.show(context, track);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
