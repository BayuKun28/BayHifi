import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../core/widgets/studio_artwork_widget.dart';
import '../../player/domain/track.dart';
import '../../player/presentation/controllers/player_controller.dart';
import '../../player/presentation/widgets/audio_file_inspector_sheet.dart';
import '../domain/library_collection_models.dart';
import '../domain/m3u8_playlist_service.dart';
import '../domain/smart_playlist_models.dart';
import 'controllers/library_controller.dart';
import 'widgets/create_smart_playlist_dialog.dart';
import 'widgets/metadata_tag_editor_sheet.dart';

/// Studio Dedicated Playlists Screen
/// Displays Curated Collections, Dynamic Smart Playlists, and Custom User Playlists.
class PlaylistsScreen extends ConsumerStatefulWidget {
  const PlaylistsScreen({super.key});

  @override
  ConsumerState<PlaylistsScreen> createState() => _PlaylistsScreenState();
}

class _PlaylistsScreenState extends ConsumerState<PlaylistsScreen> {
  void _showCreatePlaylistDialog(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final theme = Theme.of(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'CREATE NEW PLAYLIST',
          style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, letterSpacing: 0.8),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Playlist Name',
                hintText: 'e.g. Audiophile Acoustic Sessions',
                prefixIcon: HugeIcon(
                  icon: HugeIcons.strokeRoundedPlaylist01,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Description (Optional)',
                hintText: 'Master quality listening list',
                prefixIcon: HugeIcon(
                  icon: HugeIcons.strokeRoundedNote01,
                  size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (nameController.text.trim().isNotEmpty) {
                ref.read(unifiedLibraryProvider.notifier).createPlaylist(
                      nameController.text.trim(),
                      descController.text.trim(),
                    );
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Create Playlist', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _exportPlaylistM3u8(BuildContext context, String name, List<Track> tracks) async {
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

  void _showSmartPlaylistDetailSheet(BuildContext context, SmartPlaylist playlist) {
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
        return Consumer(
          builder: (context, ref, _) {
            final lib = ref.watch(unifiedLibraryProvider);
            final tracks = lib.getSmartPlaylistTracks(playlist);

            return DraggableScrollableSheet(
              initialChildSize: 0.78,
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
                                icon: HugeIcons.strokeRoundedFilterHorizontal,
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
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        playlist.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w900,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (playlist.isPreset)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.tertiary.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          'PRESET',
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w900,
                                            color: theme.colorScheme.tertiary,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  playlist.description.isNotEmpty
                                      ? playlist.description
                                      : 'Dynamic Smart Playlist',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${tracks.length} Evaluated Tracks in Library',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: primary,
                                    fontWeight: FontWeight.bold,
                                    fontFeatures: const [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Rules Summary Chips
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              playlist.matchMode == SmartPlaylistMatchMode.all
                                  ? 'MATCH ALL'
                                  : 'MATCH ANY',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          ...playlist.rules.map(
                            (r) => Container(
                              margin: const EdgeInsets.only(right: 6),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                '${r.field.label}: ${r.operator.label} ${r.value}',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Action buttons bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                if (tracks.isNotEmpty) {
                                  ref
                                      .read(playerControllerProvider.notifier)
                                      .setQueue(tracks, initialIndex: 0);
                                  Navigator.of(ctx).pop();
                                }
                              },
                              icon: const HugeIcon(
                                icon: HugeIcons.strokeRoundedPlay,
                                size: 18,
                                color: Colors.black,
                              ),
                              label: const Text('Play All', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: () {
                              if (tracks.isNotEmpty) {
                                final list = List<Track>.from(tracks)..shuffle();
                                ref
                                    .read(playerControllerProvider.notifier)
                                    .setQueue(list, initialIndex: 0);
                                Navigator.of(ctx).pop();
                              }
                            },
                            icon: HugeIcon(
                              icon: HugeIcons.strokeRoundedShuffle,
                              size: 18,
                              color: primary,
                            ),
                            label: const Text('Shuffle'),
                          ),
                          const SizedBox(width: 8),
                          IconButton.outlined(
                            icon: HugeIcon(
                              icon: HugeIcons.strokeRoundedEdit02,
                              size: 18,
                              color: primary,
                            ),
                            tooltip: 'Edit Rules',
                            onPressed: () {
                              Navigator.of(ctx).pop();
                              CreateSmartPlaylistDialog.show(context, initialPlaylist: playlist);
                            },
                          ),
                          const SizedBox(width: 4),
                          IconButton.outlined(
                            icon: HugeIcon(
                              icon: HugeIcons.strokeRoundedShare01,
                              size: 18,
                              color: primary,
                            ),
                            tooltip: 'Export M3U8',
                            onPressed: () => _exportPlaylistM3u8(context, playlist.name, tracks),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 24),
                    Expanded(
                      child: tracks.isEmpty
                          ? Center(
                              child: Text(
                                'No tracks currently match these smart rules.',
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                                  fontSize: 13,
                                ),
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              itemCount: tracks.length,
                              itemBuilder: (context, idx) {
                                final track = tracks[idx];
                                return ListTile(
                                  leading: StudioArtworkWidget(
                                    track: track,
                                    width: 40,
                                    height: 40,
                                    borderRadius: BorderRadius.circular(8),
                                    fallbackIcon: HugeIcons.strokeRoundedMusicNote01,
                                    fallbackIconSize: 18,
                                  ),
                                  title: Text(
                                    track.title,
                                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Text(
                                    '${track.artist} • ${track.format.name.toUpperCase()}',
                                    style: const TextStyle(fontSize: 10.5),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  trailing: IconButton(
                                    icon: const HugeIcon(
                                      icon: HugeIcons.strokeRoundedMoreVertical,
                                      size: 18,
                                      color: null,
                                    ),
                                    onPressed: () => _showTrackMenu(context, track),
                                  ),
                                  onTap: () {
                                    ref
                                        .read(playerControllerProvider.notifier)
                                        .setQueue(tracks, initialIndex: idx);
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
      },
    );
  }

  void _showPlaylistDetailSheet(BuildContext context, PlaylistModel playlist) {
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
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: playlist.id == 'favorites'
                              ? theme.colorScheme.tertiary.withValues(alpha: 0.15)
                              : (playlist.id == 'hires_master'
                                  ? theme.colorScheme.secondary.withValues(alpha: 0.15)
                                  : primary.withValues(alpha: 0.15)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: playlist.id == 'favorites'
                                ? theme.colorScheme.tertiary.withValues(alpha: 0.4)
                                : (playlist.id == 'hires_master'
                                    ? theme.colorScheme.secondary.withValues(alpha: 0.4)
                                    : primary.withValues(alpha: 0.4)),
                          ),
                        ),
                        child: Center(
                          child: HugeIcon(
                            icon: playlist.id == 'favorites'
                                ? HugeIcons.strokeRoundedFavourite
                                : (playlist.id == 'hires_master'
                                    ? HugeIcons.strokeRoundedSparkles
                                    : HugeIcons.strokeRoundedPlayList),
                            size: 34,
                            color: playlist.id == 'favorites'
                                ? theme.colorScheme.tertiary
                                : (playlist.id == 'hires_master'
                                    ? theme.colorScheme.secondary
                                    : primary),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              playlist.name,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              playlist.description.isNotEmpty
                                  ? playlist.description
                                  : 'Studio Playlist',
                              style: TextStyle(
                                fontSize: 12,
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${playlist.trackCount} Tracks in Collection',
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
                            if (playlist.tracks.isNotEmpty) {
                              ref
                                  .read(playerControllerProvider.notifier)
                                  .setQueue(playlist.tracks, initialIndex: 0);
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
                          if (playlist.tracks.isNotEmpty) {
                            final list = List<Track>.from(playlist.tracks)..shuffle();
                            ref
                                .read(playerControllerProvider.notifier)
                                .setQueue(list, initialIndex: 0);
                            Navigator.of(ctx).pop();
                          }
                        },
                        icon: HugeIcon(icon: HugeIcons.strokeRoundedShuffle, size: 18, color: primary),
                        label: const Text('Shuffle'),
                      ),
                      const SizedBox(width: 8),
                      IconButton.outlined(
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedShare01,
                          size: 18,
                          color: primary,
                        ),
                        tooltip: 'Export M3U8',
                        onPressed: () => _exportPlaylistM3u8(context, playlist.name, playlist.tracks),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 24),
                Expanded(
                  child: playlist.tracks.isEmpty
                      ? Center(
                          child: Text(
                            'No tracks in this playlist yet.',
                            style: TextStyle(
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              fontSize: 13,
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          itemCount: playlist.tracks.length,
                          itemBuilder: (context, idx) {
                            final track = playlist.tracks[idx];
                            return ListTile(
                              leading: StudioArtworkWidget(
                                track: track,
                                width: 40,
                                height: 40,
                                borderRadius: BorderRadius.circular(8),
                                fallbackIcon: HugeIcons.strokeRoundedMusicNote01,
                                fallbackIconSize: 18,
                              ),
                              title: Text(
                                track.title,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${track.artist} • ${track.format.name.toUpperCase()}',
                                style: const TextStyle(fontSize: 10.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: IconButton(
                                icon: const HugeIcon(
                                  icon: HugeIcons.strokeRoundedMoreVertical,
                                  size: 18,
                                  color: null,
                                ),
                                onPressed: () => _showTrackMenu(context, track),
                              ),
                              onTap: () {
                                ref
                                    .read(playerControllerProvider.notifier)
                                    .setQueue(playlist.tracks, initialIndex: idx);
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
                },
              ),
              ListTile(
                leading: HugeIcon(
                  icon: HugeIcons.strokeRoundedEdit02,
                  size: 20,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.8),
                ),
                title: const Text('Edit Metadata Tags'),
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
                title: const Text('Audio Codec & Technical Specs'),
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

  void _confirmDeletePlaylist(BuildContext context, PlaylistModel playlist) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: const Text('DELETE PLAYLIST?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete playlist "${playlist.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF453A)),
            onPressed: () {
              ref.read(unifiedLibraryProvider.notifier).deletePlaylist(playlist.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSmartPlaylist(BuildContext context, SmartPlaylist playlist) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        title: const Text('DELETE SMART PLAYLIST?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to delete smart playlist "${playlist.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF453A)),
            onPressed: () {
              ref.read(unifiedLibraryProvider.notifier).deleteSmartPlaylist(playlist.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(unifiedLibraryProvider);
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final studioPlaylists = libraryState.playlists.where((p) => !p.isCustom).toList();
    final customPlaylists = libraryState.customPlaylists;
    final smartPlaylists = libraryState.smartPlaylists;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: 56.0,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: primary.withValues(alpha: 0.4)),
              ),
              child: HugeIcon(icon: HugeIcons.strokeRoundedPlayList, color: primary, size: 18),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'STUDIO PLAYLISTS',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, letterSpacing: 0.8),
                ),
                Text(
                  '${smartPlaylists.length + customPlaylists.length + studioPlaylists.length} Playlists & Collections',
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            icon: HugeIcon(icon: HugeIcons.strokeRoundedAddCircle, size: 20, color: primary),
            tooltip: 'Create Playlist Options',
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'smart',
                child: Row(
                  children: [
                    HugeIcon(icon: HugeIcons.strokeRoundedFilterHorizontal, size: 18, color: null),
                    SizedBox(width: 10),
                    Text('New Dynamic Smart Playlist'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'custom',
                child: Row(
                  children: [
                    HugeIcon(icon: HugeIcons.strokeRoundedPlaylist01, size: 18, color: null),
                    SizedBox(width: 10),
                    Text('New Custom Playlist'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'reset_presets',
                child: Row(
                  children: [
                    HugeIcon(icon: HugeIcons.strokeRoundedRefresh, size: 18, color: null),
                    SizedBox(width: 10),
                    Text('Restore Default Smart Presets'),
                  ],
                ),
              ),
            ],
            onSelected: (val) {
              if (val == 'smart') {
                CreateSmartPlaylistDialog.show(context);
              } else if (val == 'custom') {
                _showCreatePlaylistDialog(context);
              } else if (val == 'reset_presets') {
                ref.read(unifiedLibraryProvider.notifier).resetSmartPlaylistsToPresets();
              }
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          // ─── 1. STUDIO COLLECTIONS HEADER ─────────────────────────────────
          Text(
            'STUDIO COLLECTIONS',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 10),

          // Studio Curated Collections (Favorites & Hi-Res)
          ...studioPlaylists.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: p.id == 'favorites'
                        ? theme.colorScheme.tertiary.withValues(alpha: 0.4)
                        : theme.colorScheme.secondary.withValues(alpha: 0.4),
                    width: 1.0,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: p.id == 'favorites'
                          ? theme.colorScheme.tertiary.withValues(alpha: 0.15)
                          : theme.colorScheme.secondary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: HugeIcon(
                        icon: p.id == 'favorites'
                            ? HugeIcons.strokeRoundedFavourite
                            : HugeIcons.strokeRoundedSparkles,
                        color: p.id == 'favorites' ? theme.colorScheme.tertiary : theme.colorScheme.secondary,
                        size: 22,
                      ),
                    ),
                  ),
                  title: Text(
                    p.name,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                  ),
                  subtitle: Text(
                    '${p.description} • ${p.trackCount} Tracks',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: HugeIcon(
                    icon: HugeIcons.strokeRoundedArrowRight01,
                    size: 16,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                  ),
                  onTap: () => _showPlaylistDetailSheet(context, p),
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // ─── 2. DYNAMIC SMART PLAYLISTS HEADER ─────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'DYNAMIC SMART PLAYLISTS (${smartPlaylists.length})',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              InkWell(
                onTap: () => CreateSmartPlaylistDialog.show(context),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    '+ Smart Rule',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Smart Playlists Items
          ...smartPlaylists.map((p) {
            final tracks = libraryState.getSmartPlaylistTracks(p);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: theme.colorScheme.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: primary.withValues(alpha: 0.25),
                    width: 1.0,
                  ),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: HugeIcon(
                        icon: HugeIcons.strokeRoundedFilterHorizontal,
                        color: primary,
                        size: 22,
                      ),
                    ),
                  ),
                  title: Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.name,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (p.isPreset)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.tertiary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(5),
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
                  subtitle: Text(
                    '${tracks.length} Tracks • ${p.rules.length} Rule${p.rules.length == 1 ? '' : 's'} (${p.matchMode == SmartPlaylistMatchMode.all ? 'AND' : 'OR'})',
                    style: const TextStyle(fontSize: 11),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PopupMenuButton<String>(
                        icon: HugeIcon(
                          icon: HugeIcons.strokeRoundedMoreVertical,
                          size: 18,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                        ),
                        itemBuilder: (ctx) => [
                          const PopupMenuItem(
                            value: 'play',
                            child: Row(
                              children: [
                                HugeIcon(icon: HugeIcons.strokeRoundedPlay, size: 16, color: null),
                                SizedBox(width: 8),
                                Text('Play All'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'shuffle',
                            child: Row(
                              children: [
                                HugeIcon(icon: HugeIcons.strokeRoundedShuffle, size: 16, color: null),
                                SizedBox(width: 8),
                                Text('Shuffle'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                HugeIcon(icon: HugeIcons.strokeRoundedEdit02, size: 16, color: null),
                                SizedBox(width: 8),
                                Text('Edit Rules'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'duplicate',
                            child: Row(
                              children: [
                                HugeIcon(icon: HugeIcons.strokeRoundedCopy01, size: 16, color: null),
                                SizedBox(width: 8),
                                Text('Duplicate'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'export',
                            child: Row(
                              children: [
                                HugeIcon(icon: HugeIcons.strokeRoundedShare01, size: 16, color: null),
                                SizedBox(width: 8),
                                Text('Export M3U8'),
                              ],
                            ),
                          ),
                          if (!p.isPreset) ...[
                            const PopupMenuDivider(),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Row(
                                children: [
                                  HugeIcon(icon: HugeIcons.strokeRoundedDelete02, size: 16, color: Colors.red),
                                  SizedBox(width: 8),
                                  Text('Delete', style: TextStyle(color: Colors.red)),
                                ],
                              ),
                            ),
                          ],
                        ],
                        onSelected: (action) {
                          if (action == 'play') {
                            if (tracks.isNotEmpty) {
                              ref.read(playerControllerProvider.notifier).setQueue(tracks, initialIndex: 0);
                            }
                          } else if (action == 'shuffle') {
                            if (tracks.isNotEmpty) {
                              final list = List<Track>.from(tracks)..shuffle();
                              ref.read(playerControllerProvider.notifier).setQueue(list, initialIndex: 0);
                            }
                          } else if (action == 'edit') {
                            CreateSmartPlaylistDialog.show(context, initialPlaylist: p);
                          } else if (action == 'duplicate') {
                            ref.read(unifiedLibraryProvider.notifier).duplicateSmartPlaylist(p.id);
                          } else if (action == 'export') {
                            _exportPlaylistM3u8(context, p.name, tracks);
                          } else if (action == 'delete') {
                            _confirmDeleteSmartPlaylist(context, p);
                          }
                        },
                      ),
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedArrowRight01,
                        size: 16,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                      ),
                    ],
                  ),
                  onTap: () => _showSmartPlaylistDetailSheet(context, p),
                ),
              ),
            );
          }),

          const SizedBox(height: 18),

          // ─── 3. CUSTOM USER PLAYLISTS HEADER ───────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'USER PLAYLISTS (${customPlaylists.length})',
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                ),
              ),
              InkWell(
                onTap: () => _showCreatePlaylistDialog(context),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Text(
                    '+ New Playlist',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: primary,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (customPlaylists.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 20),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: theme.dividerColor.withValues(alpha: 0.4)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedPlaylist01,
                    size: 36,
                    color: theme.dividerColor,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'NO CUSTOM PLAYLISTS',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Create your first custom playlist to curate your favorite tracks and mastering sessions.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.5,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonalIcon(
                    onPressed: () => _showCreatePlaylistDialog(context),
                    icon: HugeIcon(icon: HugeIcons.strokeRoundedAddCircle, size: 16, color: primary),
                    label: const Text('CREATE PLAYLIST'),
                  ),
                ],
              ),
            )
          else
            ...customPlaylists.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: theme.dividerColor.withValues(alpha: 0.4)),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: HugeIcon(
                          icon: HugeIcons.strokeRoundedPlayList,
                          color: primary,
                          size: 22,
                        ),
                      ),
                    ),
                    title: Text(
                      p.name,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                    ),
                    subtitle: Text(
                      p.description.isNotEmpty
                          ? '${p.description} • ${p.trackCount} Tracks'
                          : '${p.trackCount} Tracks',
                      style: const TextStyle(fontSize: 11),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: HugeIcon(
                            icon: HugeIcons.strokeRoundedDelete02,
                            size: 18,
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                          ),
                          onPressed: () => _confirmDeletePlaylist(context, p),
                          tooltip: 'Delete Playlist',
                        ),
                        HugeIcon(
                          icon: HugeIcons.strokeRoundedArrowRight01,
                          size: 16,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                        ),
                      ],
                    ),
                    onTap: () => _showPlaylistDetailSheet(context, p),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
