import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/widgets/studio_alphabetical_scroller.dart';
import '../../../core/widgets/studio_artwork_widget.dart';
import '../../player/domain/track.dart';
import '../../player/presentation/controllers/player_controller.dart';
import '../../player/presentation/widgets/audio_file_inspector_sheet.dart';
import '../../navidrome/domain/subsonic_models.dart';
import '../../navidrome/presentation/widgets/navidrome_connect_dialog.dart';
import '../domain/genre_icon_helper.dart';
import '../domain/library_collection_models.dart';
import 'controllers/library_controller.dart';
import 'widgets/artist_avatar_widget.dart';
import 'widgets/batch_track_tag_editor_modal.dart';
import 'widgets/library_batch_actions_bar.dart';
import 'widgets/metadata_tag_editor_sheet.dart';
import 'widgets/track_tile.dart';


/// Studio Music Library Screen (Unified Collection: Tracks, Albums, Artists, Genres, Playlists, Folders)
/// Ergonomic, stable 56px TopBar without layout jitter when switching views.
class UnifiedLibraryScreen extends ConsumerStatefulWidget {
  const UnifiedLibraryScreen({super.key});

  @override
  ConsumerState<UnifiedLibraryScreen> createState() => _UnifiedLibraryScreenState();
}

class _UnifiedLibraryScreenState extends ConsumerState<UnifiedLibraryScreen> {
  final _searchController = TextEditingController();
  final Set<String> _selectedTrackIds = {};
  final ScrollController _tracksScrollController = ScrollController();
  final ScrollController _albumsScrollController = ScrollController();
  final ScrollController _artistsScrollController = ScrollController();
  final ScrollController _genresScrollController = ScrollController();
  final ScrollController _foldersScrollController = ScrollController();

  bool get _isMultiSelecting => _selectedTrackIds.isNotEmpty;

  void _toggleTrackSelection(String trackId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedTrackIds.contains(trackId)) {
        _selectedTrackIds.remove(trackId);
      } else {
        _selectedTrackIds.add(trackId);
      }
    });
  }

  void _selectAllTracks(List<Track> tracks) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedTrackIds.addAll(tracks.map((t) => t.id));
    });
  }

  void _deselectAllTracks() {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedTrackIds.clear();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tracksScrollController.dispose();
    _albumsScrollController.dispose();
    _artistsScrollController.dispose();
    _genresScrollController.dispose();
    _foldersScrollController.dispose();
    super.dispose();
  }

  void _showSortBottomSheet(BuildContext context) {
    final controller = ref.read(unifiedLibraryProvider.notifier);
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final curState = ref.watch(unifiedLibraryProvider);
            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: theme.dividerColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'SORT COLLECTION',
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.8,
                          ),
                        ),
                        IconButton.filledTonal(
                          onPressed: () {
                            HapticFeedback.selectionClick();
                            controller.toggleSortDirection();
                            setModalState(() {});
                          },
                          icon: HugeIcon(
                            icon: curState.sortDirection == SortDirection.ascending
                                ? HugeIcons.strokeRoundedArrowUp01
                                : HugeIcons.strokeRoundedArrowDown01,
                            size: 18,
                            color: theme.colorScheme.onSurface,
                          ),
                          tooltip: curState.sortDirection.label,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: SortField.values.map((field) {
                        final isSelected = curState.sortField == field;
                        return ChoiceChip(
                          label: Text(field.label),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) {
                              HapticFeedback.selectionClick();
                              controller.setSortField(field);
                              setModalState(() {});
                            }
                          },
                          selectedColor: theme.colorScheme.primary.withValues(alpha: 0.2),
                          labelStyle: TextStyle(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : theme.colorScheme.onSurface,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
                            fontSize: 12,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  void _showTrackMenu(BuildContext context, Track track) {
    final state = ref.read(unifiedLibraryProvider);
    final isFav = state.favoriteTrackIds.contains(track.id);
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 46,
                    height: 46,
                    color: theme.colorScheme.surfaceContainerHighest,
                    child: track.albumArtBytes != null
                        ? Image.memory(track.albumArtBytes!, fit: BoxFit.cover)
                        : Center(
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedMusicNote01,
                              size: 22,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                  ),
                ),
                title: Text(track.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                subtitle: Text('${track.artist} • ${track.hiResBadgeText}', maxLines: 1),
                trailing: IconButton(
                  icon: HugeIcon(
                    icon: HugeIcons.strokeRoundedFavourite,
                    color: isFav ? const Color(0xFFFF2D55) : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    size: 20,
                  ),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    ref.read(unifiedLibraryProvider.notifier).toggleFavorite(track.id);
                    Navigator.of(ctx).pop();
                  },
                ),
              ),
              const Divider(),
              ListTile(
                leading: HugeIcon(
                  icon: HugeIcons.strokeRoundedPlay,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                title: const Text('Play Now'),
                onTap: () {
                  ref.read(playerControllerProvider.notifier).playTrack(track);
                  Navigator.of(ctx).pop();
                },
              ),
              ListTile(
                leading: HugeIcon(
                  icon: HugeIcons.strokeRoundedNext,
                  size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
                title: const Text('Play Next'),
                onTap: () {
                  ref.read(playerControllerProvider.notifier).playNext(track);
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"${track.title}" added to play next'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                leading: HugeIcon(
                  icon: HugeIcons.strokeRoundedPlayList,
                  size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
                title: const Text('Add to Queue'),
                onTap: () {
                  ref.read(playerControllerProvider.notifier).addToQueue(track);
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"${track.title}" added to queue'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              ListTile(
                leading: HugeIcon(
                  icon: HugeIcons.strokeRoundedPlaylist01,
                  size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
                title: const Text('Add to Playlist'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _showAddToPlaylistSheet(context, track);
                },
              ),
              ListTile(
                leading: HugeIcon(
                  icon: HugeIcons.strokeRoundedEdit02,
                  size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
                title: const Text('Edit Metadata Tags'),
                subtitle: const Text(
                  'Edit Title, Artist, Album, Year',
                  style: TextStyle(fontSize: 11),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  MetadataTagEditorSheet.show(context, track);
                },
              ),
              ListTile(
                leading: HugeIcon(
                  icon: HugeIcons.strokeRoundedAudioWaveform,
                  size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
                title: const Text('View All Metadata & Audio Specs'),
                subtitle: Text(
                  'Full ID3 tags, ${track.format.name.toUpperCase()} • ${track.sampleRate ?? 44100} Hz • ${track.bitDepth ?? 16}-bit',
                  style: const TextStyle(fontSize: 11),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  AudioFileInspectorSheet.show(context, track);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddToPlaylistSheet(BuildContext context, Track track) {
    _showAddToPlaylistSheetForTracks(context, [track]);
  }

  void _showAddToPlaylistSheetForTracks(BuildContext context, List<Track> tracks) {
    final playlists = ref.read(unifiedLibraryProvider).customPlaylists;
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ADD ${tracks.length} TRACK${tracks.length > 1 ? 'S' : ''} TO PLAYLIST',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
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
                      for (final t in tracks) {
                        ref.read(unifiedLibraryProvider.notifier).addTrackToPlaylist(p.id, t);
                      }
                      Navigator.of(ctx).pop();
                      _deselectAllTracks();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Added ${tracks.length} track${tracks.length > 1 ? 's' : ''} to "${p.name}".')),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── ALBUM DETAIL MODAL SHEET ─────────────────────────────────────────────
  void _showAlbumDetailSheet(BuildContext context, AlbumModel album) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: theme.dividerColor),
                        ),
                        child: StudioArtworkWidget(
                          track: album.firstTrack,
                          bytes: album.coverBytes,
                          url: album.coverUrl,
                          borderRadius: BorderRadius.circular(15),
                          fallbackIconSize: 36,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              album.name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              album.artist,
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${album.trackCount} Tracks • ${album.isHiRes ? "Hi-Res FLAC" : "Lossless"}',
                              style: TextStyle(fontSize: 11, color: primary, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              if (album.tracks.isNotEmpty) {
                                ref.read(playerControllerProvider.notifier).setQueue(album.tracks, initialIndex: 0);
                                Navigator.of(ctx).pop();
                              }
                            },
                            icon: const HugeIcon(icon: HugeIcons.strokeRoundedPlay, size: 18, color: Colors.black),
                            label: const Text('Play All'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () {
                            if (album.tracks.isNotEmpty) {
                              final list = List<Track>.from(album.tracks)..shuffle();
                              ref.read(playerControllerProvider.notifier).setQueue(list, initialIndex: 0);
                              Navigator.of(ctx).pop();
                            }
                          },
                          icon: HugeIcon(icon: HugeIcons.strokeRoundedShuffle, size: 18, color: primary),
                          label: const Text('Shuffle'),
                        ),
                        const SizedBox(width: 8),
                        IconButton.outlined(
                          tooltip: 'Edit Album Tags',
                          onPressed: () {
                            Navigator.of(ctx).pop();
                            BatchTrackTagEditorModal.show(context, album.tracks);
                          },
                          icon: HugeIcon(
                            icon: HugeIcons.strokeRoundedEdit02,
                            size: 18,
                            color: primary,
                          ),
                          style: IconButton.styleFrom(
                            side: BorderSide(color: theme.dividerColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const Divider(height: 24),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    itemCount: album.tracks.length,
                    itemBuilder: (context, idx) {
                      final track = album.tracks[idx];
                      return ListTile(
                        leading: StudioArtworkWidget(
                          track: track,
                          width: 36,
                          height: 36,
                          borderRadius: BorderRadius.circular(8),
                          fallbackIcon: HugeIcons.strokeRoundedMusicNote01,
                          fallbackIconSize: 18,
                        ),
                        title: Text(track.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: Text(track.format.name.toUpperCase(), style: const TextStyle(fontSize: 10.5)),
                        trailing: IconButton(
                          icon: const HugeIcon(icon: HugeIcons.strokeRoundedMoreVertical, size: 18, color: null),
                          onPressed: () => _showTrackMenu(context, track),
                        ),
                        onTap: () {
                          ref.read(playerControllerProvider.notifier).setQueue(album.tracks, initialIndex: idx);
                          Navigator.of(ctx).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─── ARTIST DETAIL MODAL SHEET ────────────────────────────────────────────
  void _showArtistDetailSheet(BuildContext context, ArtistModel artist) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      ArtistAvatarWidget(
                        artistName: artist.name,
                        fallbackCoverBytes: artist.coverBytes,
                        fallbackCoverUrl: artist.coverUrl,
                        radius: 36,
                        iconSize: 32,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              artist.name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${artist.albumsCount} Albums • ${artist.tracksCount} Tracks',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            if (artist.tracks.isNotEmpty) {
                              ref.read(playerControllerProvider.notifier).setQueue(artist.tracks, initialIndex: 0);
                              Navigator.of(ctx).pop();
                            }
                          },
                          icon: const HugeIcon(icon: HugeIcons.strokeRoundedPlay, size: 18, color: Colors.black),
                          label: const Text('Play All'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () {
                          if (artist.tracks.isNotEmpty) {
                            final list = List<Track>.from(artist.tracks)..shuffle();
                            ref.read(playerControllerProvider.notifier).setQueue(list, initialIndex: 0);
                            Navigator.of(ctx).pop();
                          }
                        },
                        icon: HugeIcon(icon: HugeIcons.strokeRoundedShuffle, size: 18, color: primary),
                        label: const Text('Shuffle'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 24),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    itemCount: artist.tracks.length,
                    itemBuilder: (context, idx) {
                      final track = artist.tracks[idx];
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 40,
                            height: 40,
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: track.albumArtBytes != null
                                ? Image.memory(track.albumArtBytes!, fit: BoxFit.cover)
                                : Center(
                                    child: HugeIcon(icon: HugeIcons.strokeRoundedMusicNote01, size: 20, color: primary),
                                  ),
                          ),
                        ),
                        title: Text(track.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: Text('${track.album} • ${track.format.name.toUpperCase()}', style: const TextStyle(fontSize: 10.5)),
                        trailing: IconButton(
                          icon: const HugeIcon(icon: HugeIcons.strokeRoundedMoreVertical, size: 18, color: null),
                          onPressed: () => _showTrackMenu(context, track),
                        ),
                        onTap: () {
                          ref.read(playerControllerProvider.notifier).setQueue(artist.tracks, initialIndex: idx);
                          Navigator.of(ctx).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ─── GENRE DETAIL MODAL SHEET ─────────────────────────────────────────────
  void _showGenreDetailSheet(BuildContext context, GenreModel genre) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          expand: false,
          builder: (_, scrollController) {
            return Column(
              children: [
                const SizedBox(height: 12),
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: primary.withValues(alpha: 0.4)),
                        ),
                        child: Center(
                          child: HugeIcon(
                            icon: GenreIconHelper.getGenreIcon(genre.name),
                            size: 30,
                            color: primary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              genre.name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${genre.trackCount} Tracks in Genre Collection',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () {
                            if (genre.tracks.isNotEmpty) {
                              ref.read(playerControllerProvider.notifier).setQueue(genre.tracks, initialIndex: 0);
                              Navigator.of(ctx).pop();
                            }
                          },
                          icon: const HugeIcon(icon: HugeIcons.strokeRoundedPlay, size: 18, color: Colors.black),
                          label: const Text('Play All', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton.icon(
                        onPressed: () {
                          if (genre.tracks.isNotEmpty) {
                            final list = List<Track>.from(genre.tracks)..shuffle();
                            ref.read(playerControllerProvider.notifier).setQueue(list, initialIndex: 0);
                            Navigator.of(ctx).pop();
                          }
                        },
                        icon: HugeIcon(icon: HugeIcons.strokeRoundedShuffle, size: 18, color: primary),
                        label: const Text('Shuffle'),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 24),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    itemCount: genre.tracks.length,
                    itemBuilder: (context, idx) {
                      final track = genre.tracks[idx];
                      return ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            width: 40,
                            height: 40,
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: track.albumArtBytes != null
                                ? Image.memory(track.albumArtBytes!, fit: BoxFit.cover)
                                : Center(
                                    child: HugeIcon(
                                      icon: HugeIcons.strokeRoundedMusicNote01,
                                      size: 20,
                                      color: primary,
                                    ),
                                  ),
                          ),
                        ),
                        title: Text(track.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        subtitle: Text('${track.artist} • ${track.album}', style: const TextStyle(fontSize: 10.5)),
                        trailing: IconButton(
                          icon: const HugeIcon(icon: HugeIcons.strokeRoundedMoreVertical, size: 18, color: null),
                          onPressed: () => _showTrackMenu(context, track),
                        ),
                        onTap: () {
                          ref.read(playerControllerProvider.notifier).setQueue(genre.tracks, initialIndex: idx);
                          Navigator.of(ctx).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(unifiedLibraryProvider);
    final controller = ref.read(unifiedLibraryProvider.notifier);
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    ref.listen<UnifiedLibraryState>(unifiedLibraryProvider, (previous, next) {
      if (!next.isScanning && next.statusMessage != null && next.statusMessage != previous?.statusMessage) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.statusMessage!),
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });

    final isNavidromeConnected =
        libraryState.navidromeConnectionStatus == NavidromeConnectionStatus.connected;

    final hasGridToggle = libraryState.currentTab == CollectionTab.albums ||
        libraryState.currentTab == CollectionTab.artists;

    return PopScope(
      canPop: !_isMultiSelecting,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isMultiSelecting) {
          _deselectAllTracks();
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        toolbarHeight: 56.0,
        elevation: 0,
        titleSpacing: libraryState.isSearching ? 12.0 : 16.0,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: libraryState.isSearching
              ? Container(
                  key: const ValueKey('search_bar_container'),
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: primaryColor.withValues(alpha: 0.4),
                      width: 1.0,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedSearch01,
                        size: 16,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          key: const ValueKey('search_field'),
                          controller: _searchController,
                          autofocus: true,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                          decoration: InputDecoration(
                            isDense: true,
                            hintText: 'Search tracks, artists, albums...',
                            hintStyle: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                              fontSize: 12.5,
                              fontWeight: FontWeight.normal,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          onChanged: controller.setSearchQuery,
                        ),
                      ),
                      if (libraryState.searchQuery.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _searchController.clear();
                            controller.setSearchQuery('');
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedCancel01,
                              size: 14,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              : Row(
                  key: const ValueKey('library_title'),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: primaryColor.withValues(alpha: 0.4)),
                      ),
                      child: HugeIcon(icon: HugeIcons.strokeRoundedMusicNote01, color: primaryColor, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'MUSIC LIBRARY',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '${libraryState.totalTracksCount} Tracks Available',
                            style: TextStyle(
                              fontSize: 9.5,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
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
        actions: [
          if (libraryState.isSearching) ...[
            IconButton(
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedCancel01,
                size: 18,
                color: theme.colorScheme.onSurface,
              ),
              tooltip: 'Close Search',
              onPressed: () {
                _searchController.clear();
                controller.toggleSearch(false);
              },
            ),
          ] else ...[
            IconButton(
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedSearch01,
                size: 18,
                color: theme.colorScheme.onSurface,
              ),
              tooltip: 'Search Library',
              onPressed: () => controller.toggleSearch(true),
            ),
            IconButton(
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedSorting01,
                size: 18,
                color: theme.colorScheme.onSurface,
              ),
              tooltip: 'Sort Collection',
              onPressed: () => _showSortBottomSheet(context),
            ),
            PopupMenuButton<String>(
              icon: HugeIcon(
                icon: HugeIcons.strokeRoundedMoreVertical,
                size: 18,
                color: theme.colorScheme.onSurface,
              ),
              tooltip: 'Library Actions',
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onSelected: (val) {
                if (val == 'pick_folder') {
                  controller.pickAndScanDirectory();
                } else if (val == 'pick_files') {
                  controller.pickAudioFiles();
                } else if (val == 'rescan') {
                  controller.rescanSavedFolders();
                } else if (val == 'navidrome') {
                  showDialog(
                    context: context,
                    builder: (_) => const NavidromeConnectDialog(),
                  );
                } else if (val == 'clear') {
                  _confirmClearLibrary(context);
                }
              },
              itemBuilder: (ctx) => [
                PopupMenuItem(
                  value: 'pick_folder',
                  child: Row(
                    children: [
                      HugeIcon(icon: HugeIcons.strokeRoundedFolder01, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      const Text('Pick & Scan Music Folder', style: TextStyle(fontSize: 12.5)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'pick_files',
                  child: Row(
                    children: [
                      HugeIcon(icon: HugeIcons.strokeRoundedMusicNote01, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      const Text('Pick Audio Files', style: TextStyle(fontSize: 12.5)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'rescan',
                  child: Row(
                    children: [
                      HugeIcon(icon: HugeIcons.strokeRoundedRefresh, size: 18, color: theme.colorScheme.primary),
                      const SizedBox(width: 10),
                      const Text('Rescan Music Folders', style: TextStyle(fontSize: 12.5)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'navidrome',
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: isNavidromeConnected ? HugeIcons.strokeRoundedCloudCheck : HugeIcons.strokeRoundedCloud,
                        size: 18,
                        color: isNavidromeConnected ? const Color(0xFF00E676) : theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        isNavidromeConnected ? 'Navidrome Server (Connected)' : 'Connect Navidrome Cloud',
                        style: const TextStyle(fontSize: 12.5),
                      ),
                    ],
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      HugeIcon(icon: HugeIcons.strokeRoundedDelete02, size: 18, color: Color(0xFFFF453A)),
                      SizedBox(width: 10),
                      Text('Clear Music Library', style: TextStyle(fontSize: 12.5, color: Color(0xFFFF453A))),
                    ],
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          // ─── 1. SUB-HEADER UTILITY ROW (Item Count & Grid/List Layout Switcher) ───
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Summary pill
                Expanded(
                  child: Text(
                    _getSubheaderSummary(libraryState),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),

                // Layout Switcher (Only on Albums / Artists)
                if (hasGridToggle)
                  InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      controller.toggleLayoutMode();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: theme.dividerColor, width: 0.8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HugeIcon(
                            icon: libraryState.layoutMode == ViewLayoutMode.grid
                                ? HugeIcons.strokeRoundedMenu01
                                : HugeIcons.strokeRoundedDashboardSquare01,
                            size: 14,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            libraryState.layoutMode == ViewLayoutMode.grid ? 'List' : 'Grid',
                            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: primaryColor),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ─── 2. SOURCE FILTER CHIPS (ALL / OFFLINE / NAVIDROME / HI-RES) ───
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSourceChip(
                    context: context,
                    label: 'All Sources (${libraryState.totalTracksCount})',
                    filter: LibrarySourceFilter.all,
                    isSelected: libraryState.selectedFilter == LibrarySourceFilter.all,
                    onTap: () => controller.setFilter(LibrarySourceFilter.all),
                  ),
                  const SizedBox(width: 6),
                  _buildSourceChip(
                    context: context,
                    label: 'Offline Local (${libraryState.offlineTracksCount})',
                    filter: LibrarySourceFilter.offline,
                    isSelected: libraryState.selectedFilter == LibrarySourceFilter.offline,
                    onTap: () => controller.setFilter(LibrarySourceFilter.offline),
                  ),
                  const SizedBox(width: 6),
                  _buildSourceChip(
                    context: context,
                    label: 'Navidrome Cloud (${libraryState.navidromeTracksCount})',
                    filter: LibrarySourceFilter.navidrome,
                    isSelected: libraryState.selectedFilter == LibrarySourceFilter.navidrome,
                    onTap: () => controller.setFilter(LibrarySourceFilter.navidrome),
                  ),
                  const SizedBox(width: 6),
                  _buildSourceChip(
                    context: context,
                    label: 'Hi-Res Lossless (${libraryState.hiResTracksCount})',
                    filter: LibrarySourceFilter.hiRes,
                    isSelected: libraryState.selectedFilter == LibrarySourceFilter.hiRes,
                    onTap: () => controller.setFilter(LibrarySourceFilter.hiRes),
                  ),
                ],
              ),
            ),
          ),

          // ─── 3. TAB CONTENT VIEWS ─────────────────────────────────────────
          Expanded(
            child: _buildTabContent(context, libraryState, controller),
          ),
        ],
      ),
      bottomNavigationBar: _isMultiSelecting
          ? SafeArea(
              child: LibraryBatchActionsBar(
                selectedCount: _selectedTrackIds.length,
                totalCount: libraryState.filteredTracks.length,
                onPlayNext: () {
                  final selected = libraryState.tracks.where((t) => _selectedTrackIds.contains(t.id)).toList();
                  for (final t in selected.reversed) {
                    ref.read(playerControllerProvider.notifier).playNext(t);
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Playing ${selected.length} track${selected.length > 1 ? 's' : ''} next.')),
                  );
                  _deselectAllTracks();
                },
                onAddToQueue: () {
                  final selected = libraryState.tracks.where((t) => _selectedTrackIds.contains(t.id)).toList();
                  for (final t in selected) {
                    ref.read(playerControllerProvider.notifier).addToQueue(t);
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added ${selected.length} track${selected.length > 1 ? 's' : ''} to Queue.')),
                  );
                  _deselectAllTracks();
                },
                onAddToPlaylist: () {
                  final selected = libraryState.tracks.where((t) => _selectedTrackIds.contains(t.id)).toList();
                  if (selected.isNotEmpty) {
                    _showAddToPlaylistSheetForTracks(context, selected);
                  }
                },
                onBatchEditTags: () {
                  final selected = libraryState.tracks.where((t) => _selectedTrackIds.contains(t.id)).toList();
                  if (selected.isNotEmpty) {
                    BatchTrackTagEditorModal.show(context, selected);
                  }
                },
                onSelectAll: () => _selectAllTracks(libraryState.filteredTracks),
                onDeselectAll: _deselectAllTracks,
                onClose: _deselectAllTracks,
              ),
            )
          : null,
      ),
    );
  }

  String _getSubheaderSummary(UnifiedLibraryState state) {
    return switch (state.currentTab) {
      CollectionTab.tracks => '${state.filteredTracks.length} Tracks • Sorted by ${state.sortField.label}',
      CollectionTab.albums => '${state.albums.length} Albums • ${state.totalTracksCount} Total Tracks',
      CollectionTab.artists => '${state.artists.length} Artists in Library',
      CollectionTab.genres => '${state.genres.length} Audio Genres',
      CollectionTab.folders => '${state.folders.length} Directory Folders',
    };
  }

  Widget _buildSourceChip({
    required BuildContext context,
    required String label,
    required LibrarySourceFilter filter,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? primary.withValues(alpha: 0.15) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? primary.withValues(alpha: 0.4) : theme.dividerColor,
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
            color: isSelected ? primary : theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(
    BuildContext context,
    UnifiedLibraryState state,
    UnifiedLibraryController controller,
  ) {
    if (state.isScanning) {
      final theme = Theme.of(context);
      return Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: theme.dividerColor, width: 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(strokeWidth: 2.5),
              ),
              const SizedBox(height: 18),
              Text(
                state.statusMessage ?? 'Scanning audio collection...',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Parsing ID3 tags, sample rates, and bit depths...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final viewInsetsBottom = MediaQuery.viewInsetsOf(context).bottom;
    final isKeyboardOpen = viewInsetsBottom > 0;
    final bottomPadding = isKeyboardOpen ? (viewInsetsBottom + 16.0) : 96.0;

    return switch (state.currentTab) {
      CollectionTab.tracks => _buildTracksList(context, state.filteredTracks, bottomPadding),
      CollectionTab.albums => _buildAlbumsView(context, state, bottomPadding),
      CollectionTab.artists => _buildArtistsView(context, state, bottomPadding),
      CollectionTab.genres => _buildGenresView(context, state, bottomPadding),
      CollectionTab.folders => _buildFoldersView(context, state, bottomPadding),
    };
  }

  // ─── TRACKS LIST ──────────────────────────────────────────────────────────
  Widget _buildTracksList(BuildContext context, List<Track> tracks, double bottomPadding) {
    final playback = ref.watch(playerControllerProvider);
    final libraryState = ref.watch(unifiedLibraryProvider);
    final currentPlayingId = playback.currentTrack?.id;

    if (tracks.isEmpty) {
      return _buildEmptyState(context, 'No audio tracks found.');
    }

    final isAlphabetical = libraryState.sortField == SortField.title ||
        libraryState.sortField == SortField.artist ||
        libraryState.sortField == SortField.album;

    return StudioAlphabeticalScroller(
      scrollController: _tracksScrollController,
      itemCount: tracks.length,
      itemHeight: 74.0,
      isAlphabetical: isAlphabetical,
      letterSelector: (index) {
        if (index < 0 || index >= tracks.length) return '';
        final track = tracks[index];
        return switch (libraryState.sortField) {
          SortField.artist => track.artist,
          SortField.album => track.album,
          _ => track.title,
        };
      },
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: ListView.builder(
        controller: _tracksScrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(14, 4, isAlphabetical ? 28 : 14, bottomPadding),
        itemCount: tracks.length,
        itemBuilder: (ctx, index) {
          final track = tracks[index];
          final isPlayingThis = currentPlayingId == track.id;

          final isSelected = _selectedTrackIds.contains(track.id);

          return TrackTile(
            track: track,
            isPlaying: isPlayingThis,
            isMultiSelecting: _isMultiSelecting,
            isSelected: isSelected,
            onTap: () {
              if (_isMultiSelecting) {
                _toggleTrackSelection(track.id);
              } else {
                ref.read(playerControllerProvider.notifier).setQueue(tracks, initialIndex: index);
              }
            },
            onLongPress: () => _toggleTrackSelection(track.id),
            onPlayNext: () => ref.read(playerControllerProvider.notifier).playNext(track),
            onAddToQueue: () => ref.read(playerControllerProvider.notifier).addToQueue(track),
            onAddToPlaylist: () => _showAddToPlaylistSheet(context, track),
          );
        },
      ),
    );
  }

  // ─── ALBUMS VIEW (GRID / LIST) ────────────────────────────────────────────
  Widget _buildAlbumsView(BuildContext context, UnifiedLibraryState state, double bottomPadding) {
    final albums = state.albums;
    final theme = Theme.of(context);

    if (albums.isEmpty) {
      return _buildEmptyState(context, 'No albums found.');
    }

    if (state.layoutMode == ViewLayoutMode.list) {
      return StudioAlphabeticalScroller(
        scrollController: _albumsScrollController,
        itemCount: albums.length,
        itemHeight: 72.0,
        isAlphabetical: true,
        letterSelector: (i) => i < albums.length ? albums[i].name : '',
        padding: EdgeInsets.only(bottom: bottomPadding),
        child: ListView.builder(
          controller: _albumsScrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(14, 4, 28, bottomPadding),
          itemCount: albums.length,
          itemBuilder: (ctx, index) {
            final album = albums[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: ListTile(
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: SizedBox(
                      width: 46,
                      height: 46,
                      child: StudioArtworkWidget(
                        track: album.firstTrack,
                        bytes: album.coverBytes,
                        url: album.coverUrl,
                        borderRadius: BorderRadius.circular(10),
                        fallbackIcon: HugeIcons.strokeRoundedAlbum01,
                        fallbackIconSize: 22,
                      ),
                    ),
                  ),
                  title: Text(album.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  subtitle: Text('${album.artist} • ${album.trackCount} tracks', style: const TextStyle(fontSize: 11)),
                  trailing: HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                  onTap: () => _showAlbumDetailSheet(context, album),
                ),
              ),
            );
          },
        ),
      );
    }

    // Grid View (2-Column Squircle) with standard Studio Scrollbar
    return Theme(
      data: theme.copyWith(
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStatePropertyAll(theme.colorScheme.primary.withValues(alpha: 0.5)),
          radius: const Radius.circular(8),
          thickness: const WidgetStatePropertyAll(4.5),
        ),
      ),
      child: Scrollbar(
        controller: _albumsScrollController,
        thumbVisibility: true,
        interactive: true,
        child: GridView.builder(
          controller: _albumsScrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(14, 8, 14, bottomPadding),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.8,
          ),
          itemCount: albums.length,
          itemBuilder: (ctx, index) {
            final album = albums[index];
            return InkWell(
              onTap: () => _showAlbumDetailSheet(context, album),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: album.isHiRes
                        ? const Color(0xFFFF9F0A).withValues(alpha: 0.4)
                        : theme.dividerColor.withValues(alpha: 0.4),
                    width: 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                        ),
                        child: StudioArtworkWidget(
                          track: album.firstTrack,
                          bytes: album.coverBytes,
                          url: album.coverUrl,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(17)),
                          fallbackIconSize: 48,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            album.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            album.artist,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${album.trackCount} Tracks',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (album.isHiRes)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFF9F0A).withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: const Text(
                                    'HI-RES',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFFFF9F0A),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── ARTISTS VIEW ─────────────────────────────────────────────────────────
  Widget _buildArtistsView(BuildContext context, UnifiedLibraryState state, double bottomPadding) {
    final artists = state.artists;
    final theme = Theme.of(context);

    if (artists.isEmpty) {
      return _buildEmptyState(context, 'No artists found.');
    }

    return StudioAlphabeticalScroller(
      scrollController: _artistsScrollController,
      itemCount: artists.length,
      itemHeight: 72.0,
      isAlphabetical: true,
      letterSelector: (i) => i < artists.length ? artists[i].name : '',
      padding: EdgeInsets.only(bottom: bottomPadding),
      child: ListView.builder(
        controller: _artistsScrollController,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: EdgeInsets.fromLTRB(14, 4, 28, bottomPadding),
        itemCount: artists.length,
        itemBuilder: (ctx, index) {
          final artist = artists[index];
          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
            ),
            child: Material(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(14),
              child: ListTile(
                leading: ArtistAvatarWidget(
                  artistName: artist.name,
                  fallbackCoverBytes: artist.coverBytes,
                  fallbackCoverUrl: artist.coverUrl,
                  radius: 22,
                  iconSize: 20,
                ),
                title: Text(artist.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                subtitle: Text('${artist.albumsCount} Albums • ${artist.tracksCount} Tracks', style: const TextStyle(fontSize: 11)),
                trailing: HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                onTap: () => _showArtistDetailSheet(context, artist),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── GENRES VIEW ──────────────────────────────────────────────────────────
  Widget _buildGenresView(BuildContext context, UnifiedLibraryState state, double bottomPadding) {
    final genres = state.genres;
    final theme = Theme.of(context);

    if (genres.isEmpty) {
      return _buildEmptyState(context, 'No genres found.');
    }

    return Theme(
      data: theme.copyWith(
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStatePropertyAll(theme.colorScheme.primary.withValues(alpha: 0.5)),
          radius: const Radius.circular(8),
          thickness: const WidgetStatePropertyAll(4.5),
        ),
      ),
      child: Scrollbar(
        controller: _genresScrollController,
        thumbVisibility: true,
        interactive: true,
        child: ListView.builder(
          controller: _genresScrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(14, 4, 14, bottomPadding),
          itemCount: genres.length,
          itemBuilder: (ctx, index) {
            final genre = genres[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: HugeIcon(
                      icon: GenreIconHelper.getGenreIcon(genre.name),
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  ),
                  title: Text(genre.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  subtitle: Text('${genre.trackCount} Tracks', style: const TextStyle(fontSize: 11)),
                  trailing: HugeIcon(icon: HugeIcons.strokeRoundedArrowRight01, size: 16, color: theme.colorScheme.onSurface.withValues(alpha: 0.4)),
                  onTap: () => _showGenreDetailSheet(context, genre),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── FOLDERS VIEW ─────────────────────────────────────────────────────────
  Widget _buildFoldersView(BuildContext context, UnifiedLibraryState state, double bottomPadding) {
    final folders = state.folders;
    final theme = Theme.of(context);

    if (folders.isEmpty) {
      return _buildEmptyState(context, 'No audio folders found.');
    }

    return Theme(
      data: theme.copyWith(
        scrollbarTheme: ScrollbarThemeData(
          thumbColor: WidgetStatePropertyAll(theme.colorScheme.primary.withValues(alpha: 0.5)),
          radius: const Radius.circular(8),
          thickness: const WidgetStatePropertyAll(4.5),
        ),
      ),
      child: Scrollbar(
        controller: _foldersScrollController,
        thumbVisibility: true,
        interactive: true,
        child: ListView.builder(
          controller: _foldersScrollController,
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.fromLTRB(14, 4, 14, bottomPadding),
          itemCount: folders.length,
          itemBuilder: (ctx, index) {
            final folder = folders[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: HugeIcon(icon: HugeIcons.strokeRoundedFolder01, color: theme.colorScheme.primary, size: 20),
                  ),
                  title: Text(folder.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  subtitle: Text('${folder.path} • ${folder.trackCount} Tracks', style: const TextStyle(fontSize: 10.5)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Batch Edit Folder Tags',
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedEdit02,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        onPressed: () {
                          BatchTrackTagEditorModal.show(context, folder.tracks);
                        },
                      ),
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowRight01,
                        size: 16,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ],
                  ),
                  onTap: () {
                    if (folder.tracks.isNotEmpty) {
                      ref.read(playerControllerProvider.notifier).setQueue(folder.tracks, initialIndex: 0);
                    }
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _confirmClearLibrary(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: const Text('CLEAR MUSIC LIBRARY?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: const Text(
          'This will remove all local audio tracks and folders from your Baydev HiFi library. Your physical audio files on disk will NOT be deleted.',
          style: TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF453A)),
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(unifiedLibraryProvider.notifier).clearLibrary();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Music library cleared.')),
              );
            },
            child: const Text('Clear Library', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, String message) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final controller = ref.read(unifiedLibraryProvider.notifier);
    final totalCount = ref.watch(unifiedLibraryProvider).totalTracksCount;

    if (totalCount == 0) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5), width: 1.0),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: primary.withValues(alpha: 0.3)),
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedFolder01,
                      size: 32,
                      color: primary,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'NO AUDIO TRACKS LOADED',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Select your local music folder or pick audio files (FLAC, WAV, DSD, ALAC, MP3) to build your bit-perfect studio library.',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => controller.pickAndScanDirectory(),
                    icon: const HugeIcon(icon: HugeIcons.strokeRoundedFolder01, size: 18, color: Colors.black),
                    label: const Text(
                      'SELECT MUSIC FOLDER',
                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonalIcon(
                    onPressed: () => controller.pickAudioFiles(),
                    icon: HugeIcon(icon: HugeIcons.strokeRoundedMusicNote01, size: 18, color: primary),
                    label: const Text(
                      'PICK AUDIO FILES',
                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const NavidromeConnectDialog(),
                      );
                    },
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedCloud,
                      size: 18,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                    label: const Text(
                      'CONNECT NAVIDROME CLOUD',
                      style: TextStyle(letterSpacing: 0.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          HugeIcon(icon: HugeIcons.strokeRoundedSearch01, size: 44, color: theme.dividerColor),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}
