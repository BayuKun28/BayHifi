import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../app/theme/studio_surface_theme.dart';
import '../../../core/widgets/studio_alphabetical_scroller.dart';
import '../../../core/widgets/studio_artwork_widget.dart';
import '../../player/domain/track.dart';
import '../../player/presentation/controllers/player_controller.dart';
import '../../navidrome/domain/subsonic_models.dart';
import '../../navidrome/presentation/widgets/navidrome_connect_dialog.dart';
import '../domain/genre_icon_helper.dart';
import '../domain/library_collection_models.dart';
import 'controllers/library_controller.dart';
import 'screens/album_detail_screen.dart';
import 'screens/artist_detail_screen.dart';
import 'screens/folder_detail_screen.dart';
import 'screens/genre_detail_screen.dart';
import '../../youtube_music/presentation/youtube_discovery_screen.dart';
import 'widgets/artist_avatar_widget.dart';
import 'widgets/batch_track_tag_editor_modal.dart';
import 'widgets/library_batch_actions_bar.dart';
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
  final _searchFocusNode = FocusNode();
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
    _searchFocusNode.dispose();
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

  // ─── DEDICATED SCREEN NAVIGATION (SPOTIFY & NAMIDA GRADE) ─────────────────
  void _openAlbumDetail(BuildContext context, AlbumModel album) {
    HapticFeedback.selectionClick();
    _searchFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AlbumDetailScreen(album: album),
      ),
    );
  }

  void _openArtistDetail(BuildContext context, ArtistModel artist) {
    HapticFeedback.selectionClick();
    _searchFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArtistDetailScreen(artist: artist),
      ),
    );
  }

  void _openGenreDetail(BuildContext context, GenreModel genre) {
    HapticFeedback.selectionClick();
    _searchFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GenreDetailScreen(genre: genre),
      ),
    );
  }

  void _openFolderDetail(BuildContext context, FolderModel folder) {
    HapticFeedback.selectionClick();
    _searchFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FolderDetailScreen(folder: folder),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(unifiedLibraryProvider);
    final controller = ref.read(unifiedLibraryProvider.notifier);
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;
    final isSolid = ref.isSolidStyle;

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
                    color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSolid ? theme.colorScheme.outline : primaryColor.withValues(alpha: 0.4),
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
                          focusNode: _searchFocusNode,
                          autofocus: true,
                          textInputAction: TextInputAction.search,
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
                          onSubmitted: (_) {
                            _searchFocusNode.unfocus();
                            FocusManager.instance.primaryFocus?.unfocus();
                          },
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
                        color: StudioSurfaceTheme.tintedContainer(context, primaryColor, isSolid: isSolid),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSolid ? theme.colorScheme.outline : primaryColor.withValues(alpha: 0.4),
                        ),
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
                _searchFocusNode.unfocus();
                FocusManager.instance.primaryFocus?.unfocus();
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
                } else if (val == 'youtube') {
                  controller.setTab(CollectionTab.youtube);
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
                PopupMenuItem(
                  value: 'youtube',
                  child: Row(
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedPlayList,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'YouTube Music HiFi',
                        style: TextStyle(fontSize: 12.5),
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
          if (libraryState.currentTab != CollectionTab.youtube)
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

          // ─── 2b. YOUTUBE MUSIC HIFI QUICK ACTION CAPSULE ───
          if (libraryState.currentTab != CollectionTab.youtube)
            _buildYouTubeQuickRibbon(context, primaryColor, theme, controller),

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

  Widget _buildYouTubeQuickRibbon(
    BuildContext context,
    Color primaryColor,
    ThemeData theme,
    UnifiedLibraryController controller,
  ) {
    final isSolid = ref.isSolidStyle;
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 2, 14, 4),
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          controller.setTab(CollectionTab.youtube);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: StudioSurfaceTheme.tintedContainer(context, primaryColor, isSolid: isSolid, translucentAlpha: 0.08, solidBlendAlpha: 0.14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSolid ? theme.colorScheme.outline : primaryColor.withValues(alpha: 0.25),
              width: 0.9,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: StudioSurfaceTheme.tintedContainer(context, primaryColor, isSolid: isSolid),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: HugeIcon(
                  icon: HugeIcons.strokeRoundedPlayList,
                  size: 13,
                  color: primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'YOUTUBE MUSIC HIFI HUB',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                        color: primaryColor,
                      ),
                    ),
                    Text(
                      'Search & stream bit-perfect Opus audio through DSP chain',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: StudioSurfaceTheme.tintedContainer(context, primaryColor, isSolid: isSolid),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Explore',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 2),
                    HugeIcon(
                      icon: HugeIcons.strokeRoundedArrowRight01,
                      size: 10,
                      color: primaryColor,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
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
      CollectionTab.youtube => 'YouTube Music HiFi • Global Streaming',
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
    final isSolid = ref.isSolidStyle;

    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? StudioSurfaceTheme.tintedContainer(context, primary, isSolid: isSolid)
              : StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? (isSolid ? primary : primary.withValues(alpha: 0.4))
                : StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
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
      CollectionTab.youtube => _buildYouTubeDiscoveryView(context, bottomPadding),
    };
  }

  Widget _buildYouTubeDiscoveryView(BuildContext context, double bottomPadding) {
    return YouTubeDiscoveryScreen(
      showAppBar: false,
      bottomPadding: bottomPadding,
    );
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
              _searchFocusNode.unfocus();
              FocusManager.instance.primaryFocus?.unfocus();
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
    final isSolid = ref.isSolidStyle;

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
                color: StudioSurfaceTheme.surface(context, isSolid: isSolid),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid)),
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
                  onTap: () => _openAlbumDetail(context, album),
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
              onTap: () => _openAlbumDetail(context, album),
              borderRadius: BorderRadius.circular(18),
              child: Container(
                decoration: BoxDecoration(
                  color: StudioSurfaceTheme.surface(context, isSolid: isSolid),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: album.isHiRes
                        ? (isSolid ? theme.colorScheme.primary : const Color(0xFFFF9F0A).withValues(alpha: 0.4))
                        : StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid),
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
                                    color: StudioSurfaceTheme.tintedContainer(context, theme.colorScheme.primary, isSolid: isSolid),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                  child: Text(
                                    'HI-RES',
                                    style: TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w900,
                                      color: theme.colorScheme.primary,
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
    final isSolid = ref.isSolidStyle;

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
              color: StudioSurfaceTheme.surface(context, isSolid: isSolid),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid)),
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
                onTap: () => _openArtistDetail(context, artist),
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
    final isSolid = ref.isSolidStyle;

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
                color: StudioSurfaceTheme.surface(context, isSolid: isSolid),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid)),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: StudioSurfaceTheme.tintedContainer(context, theme.colorScheme.primary, isSolid: isSolid),
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
                  onTap: () => _openGenreDetail(context, genre),
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
    final isSolid = ref.isSolidStyle;

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
                color: StudioSurfaceTheme.surface(context, isSolid: isSolid),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: StudioSurfaceTheme.subtleOutline(context, isSolid: isSolid)),
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(14),
                child: ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: StudioSurfaceTheme.tintedContainer(context, theme.colorScheme.primary, isSolid: isSolid),
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
                  onTap: () => _openFolderDetail(context, folder),
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
    final isSolid = ref.isSolidStyle;
    final controller = ref.read(unifiedLibraryProvider.notifier);
    final libraryState = ref.watch(unifiedLibraryProvider);
    final totalCount = libraryState.totalTracksCount;

    if (libraryState.selectedFilter == LibrarySourceFilter.navidrome &&
        libraryState.navidromeConnectionStatus != NavidromeConnectionStatus.connected) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: StudioSurfaceTheme.cardDecoration(
              context: context,
              isSolid: isSolid,
              radius: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: StudioSurfaceTheme.tintedContainer(context, primary, isSolid: isSolid),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSolid ? theme.colorScheme.outline : primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Center(
                    child: HugeIcon(
                      icon: HugeIcons.strokeRoundedCloudOff,
                      size: 32,
                      color: primary,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'NO NAVIDROME SERVER CONNECTED',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.8,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Stream lossless FLAC and Opus audio directly from your personal Subsonic or Navidrome music server.',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const NavidromeConnectDialog(),
                      );
                    },
                    icon: const HugeIcon(icon: HugeIcons.strokeRoundedCloudSync, size: 18, color: Colors.black),
                    label: const Text(
                      'CONNECT TO NAVIDROME',
                      style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'SUBSONIC API • LOSSLESS FLAC • OPUS STREAMING',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (totalCount == 0) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: StudioSurfaceTheme.cardDecoration(
              context: context,
              isSolid: isSolid,
              radius: 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: StudioSurfaceTheme.tintedContainer(context, primary, isSolid: isSolid),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSolid ? theme.colorScheme.outline : primary.withValues(alpha: 0.3),
                    ),
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
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const YouTubeDiscoveryScreen()),
                      );
                    },
                    icon: HugeIcon(
                      icon: HugeIcons.strokeRoundedPlayList,
                      size: 18,
                      color: primary,
                    ),
                    label: const Text(
                      'EXPLORE YOUTUBE MUSIC HIFI',
                      style: TextStyle(letterSpacing: 0.5, fontWeight: FontWeight.bold),
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
