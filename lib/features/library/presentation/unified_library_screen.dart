import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../../app/app.dart';
import '../../../app/theme/app_haptics.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/studio_surface_theme.dart';
import '../../../core/desktop/desktop_layout_controller.dart';
import '../../../core/widgets/two_tone_header.dart';
import '../../player/domain/track.dart';
import '../../player/presentation/controllers/player_controller.dart';
import '../../navidrome/domain/subsonic_models.dart';
import '../../navidrome/presentation/widgets/navidrome_connect_dialog.dart';
import '../domain/library_collection_models.dart';
import 'controllers/library_controller.dart';
import 'screens/album_detail_screen.dart';
import 'screens/artist_detail_screen.dart';
import 'screens/folder_detail_screen.dart';
import 'screens/genre_detail_screen.dart';
import '../../youtube_music/presentation/youtube_discovery_screen.dart';
import 'controllers/library_selection_controller.dart';
import 'widgets/batch_track_tag_editor_modal.dart';
import 'widgets/library_batch_actions_bar.dart';
import 'widgets/library_sort_filter_sheets.dart';
import '../../download_manager/presentation/controllers/download_controller.dart';
import '../../download_manager/presentation/tabs/library_downloads_tab.dart';
import 'tabs/library_tracks_tab.dart';
import 'tabs/library_albums_tab.dart';
import 'tabs/library_artists_tab.dart';
import 'tabs/library_genres_tab.dart';
import 'tabs/library_folders_tab.dart';


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
  final ScrollController _tracksScrollController = ScrollController();
  final ScrollController _albumsScrollController = ScrollController();
  final ScrollController _artistsScrollController = ScrollController();
  final ScrollController _genresScrollController = ScrollController();
  final ScrollController _foldersScrollController = ScrollController();
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
    LibrarySortFilterSheets.showSortSheet(context, ref);
  }

  void _showAddToPlaylistSheet(BuildContext context, Track track) {
    LibrarySortFilterSheets.showAddToPlaylistSheet(context, ref, [track]);
  }

  void _showAddToPlaylistSheetForTracks(BuildContext context, List<Track> tracks) {
    LibrarySortFilterSheets.showAddToPlaylistSheet(context, ref, tracks);
  }

  // ─── DEDICATED SCREEN NAVIGATION (SPOTIFY & NAMIDA GRADE) ─────────────────
  void _openAlbumDetail(BuildContext context, AlbumModel album) {
    AppHaptics.selectionClick();
    _searchFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AlbumDetailScreen(album: album),
      ),
    );
  }

  void _openArtistDetail(BuildContext context, ArtistModel artist) {
    AppHaptics.selectionClick();
    _searchFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArtistDetailScreen(artist: artist),
      ),
    );
  }

  void _openGenreDetail(BuildContext context, GenreModel genre) {
    AppHaptics.selectionClick();
    _searchFocusNode.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => GenreDetailScreen(genre: genre),
      ),
    );
  }

  void _openFolderDetail(BuildContext context, FolderModel folder) {
    AppHaptics.selectionClick();
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
    final isDesktop = MediaQuery.of(context).size.width >= 960 &&
        ref.watch(desktopLayoutModeProvider) != DesktopLayoutMode.mobile;

    ref.listen<UnifiedLibraryState>(unifiedLibraryProvider, (previous, next) {
      if (!next.isScanning && next.statusMessage != null && next.statusMessage != previous?.statusMessage) {
        final messenger = ScaffoldMessenger.maybeOf(context) ?? rootScaffoldMessengerKey.currentState;
        messenger?.hideCurrentSnackBar();
        messenger?.showSnackBar(
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

    final mediaQuery = MediaQuery.of(context);
    final isDesktopLayout = mediaQuery.size.width >= 960;
    final selectionState = ref.watch(librarySelectionProvider);
    final showDesktopShuffleFab = isDesktopLayout &&
        libraryState.currentTab == CollectionTab.tracks &&
        !selectionState.isSelecting;

    return PopScope(
      canPop: !selectionState.isSelecting,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (selectionState.isSelecting) {
          ref.read(librarySelectionProvider.notifier).clear();
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
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.search,
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
                            child: Icon(
                              LucideIcons.x,
                              size: 14,
                              color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                            ),
                          ),
                        ),
                    ],
                  ),
                )
              : const TwoToneHeader(
                  key: ValueKey('library_title'),
                  primaryText: 'MUSIC',
                  accentText: 'LIBRARY',
                  fontSize: 18,
                ),
        ),
        actions: [
          if (libraryState.isSearching) ...[
            IconButton(
              icon: Icon(
                LucideIcons.x,
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
              icon: const Icon(
                LucideIcons.playSquare,
                size: 18,
                color: Color(0xFF34D399),
              ),
              tooltip: 'YouTube Music HiFi Streaming',
              onPressed: () {
                AppHaptics.lightImpact();
                controller.setTab(CollectionTab.youtube);
              },
            ),
            IconButton(
              icon: Icon(
                LucideIcons.search,
                size: 18,
                color: theme.colorScheme.onSurface,
              ),
              tooltip: 'Search Library',
              onPressed: () => controller.toggleSearch(true),
            ),
            IconButton(
              icon: Icon(
                LucideIcons.arrowUpDown,
                size: 18,
                color: theme.colorScheme.onSurface,
              ),
              tooltip: 'Sort Collection',
              onPressed: () => _showSortBottomSheet(context),
            ),
            PopupMenuButton<String>(
              icon: Icon(
                LucideIcons.moreVertical,
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
                if (!kIsWeb) ...[
                  PopupMenuItem(
                    value: 'pick_folder',
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.folder,
                          size: 18,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 10),
                        const Text('Pick & Scan Music Folder', style: TextStyle(fontSize: 12.5)),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'pick_files',
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.music,
                          size: 18,
                          color: primaryColor,
                        ),
                        const SizedBox(width: 10),
                        const Text('Pick Audio Files', style: TextStyle(fontSize: 12.5)),
                      ],
                    ),
                  ),
                ],
                PopupMenuItem(
                  value: 'rescan',
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.refreshCw,
                        size: 18,
                        color: primaryColor,
                      ),
                      const SizedBox(width: 10),
                      Text(kIsWeb ? 'Sync Server Music' : 'Rescan Music Folders', style: const TextStyle(fontSize: 12.5)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'navidrome',
                  child: Row(
                    children: [
                      Icon(
                        isNavidromeConnected ? LucideIcons.cloudCheck : LucideIcons.cloud,
                        size: 18,
                        color: primaryColor,
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
                      Icon(
                        LucideIcons.playSquare,
                        size: 18,
                        color: primaryColor,
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
                PopupMenuItem(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.trash2,
                        size: 18,
                        color: theme.colorScheme.error,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Clear Music Library',
                        style: TextStyle(fontSize: 12.5, color: theme.colorScheme.error),
                      ),
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
              // ─── 0. CATEGORY TABS (TRACKS / ALBUMS / ARTISTS / GENRES / FOLDERS / YOUTUBE) ───
              _buildCategoryTabsRow(context, libraryState, controller, primaryColor, theme, isSolid),

              // ─── 1. SUB-HEADER UTILITY ROW (Item Count & Grid/List Layout Switcher) ───
              if (libraryState.currentTab != CollectionTab.tracks)
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
                          AppHaptics.selectionClick();
                          controller.toggleLayoutMode();
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                libraryState.layoutMode == ViewLayoutMode.grid
                                    ? LucideIcons.list
                                    : LucideIcons.grid,
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

          // ─── 2. SOURCE FILTER CHIPS (ONLY ON TRACKS TAB, DESKTOP ONLY) ───────────
          if (isDesktop && libraryState.currentTab == CollectionTab.tracks)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Primary chips row ─────────────────────────────────────
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildSourceChip(
                          context: context,
                          label: 'All Sources (${libraryState.totalTracksCount})',
                          icon: LucideIcons.music,
                          accentColor: primaryColor,
                          filter: LibrarySourceFilter.all,
                          isSelected: libraryState.selectedFilter == LibrarySourceFilter.all,
                          onTap: () => controller.setFilter(LibrarySourceFilter.all),
                        ),
                        const SizedBox(width: 6),
                        _buildSourceChip(
                          context: context,
                          label: 'Offline Local (${libraryState.offlineTracksCount})',
                          icon: LucideIcons.folder,
                          accentColor: primaryColor,
                          filter: LibrarySourceFilter.offline,
                          isSelected: libraryState.selectedFilter == LibrarySourceFilter.offline,
                          onTap: () => controller.setFilter(LibrarySourceFilter.offline),
                        ),
                        const SizedBox(width: 6),
                        _buildSourceChip(
                          context: context,
                          label: 'Cloud Library (${libraryState.cloudTracksCount})',
                          icon: LucideIcons.cloud,
                          accentColor: primaryColor,
                          filter: LibrarySourceFilter.cloud,
                          isSelected: libraryState.selectedFilter == LibrarySourceFilter.cloud,
                          onTap: () => controller.setFilter(LibrarySourceFilter.cloud),
                        ),
                        const SizedBox(width: 6),
                        _buildSourceChip(
                          context: context,
                          label: 'Hi-Res Lossless (${libraryState.hiResTracksCount})',
                          icon: LucideIcons.disc,
                          accentColor: primaryColor,
                          filter: LibrarySourceFilter.hiRes,
                          isSelected: libraryState.selectedFilter == LibrarySourceFilter.hiRes,
                          onTap: () => controller.setFilter(LibrarySourceFilter.hiRes),
                        ),
                        const SizedBox(width: 6),
                        _buildSourceChip(
                          context: context,
                          label: 'Untagged (${libraryState.untaggedTracksCount})',
                          icon: LucideIcons.alertCircle,
                          accentColor: primaryColor,
                          filter: LibrarySourceFilter.untagged,
                          isSelected: libraryState.selectedFilter == LibrarySourceFilter.untagged,
                          onTap: () => controller.setFilter(LibrarySourceFilter.untagged),
                        ),
                      ],
                    ),
                  ),
                  // ── Cloud sub-chips (animated slide-in) ───────────────────
                  AnimatedSize(
                    duration: const Duration(milliseconds: 220),
                    curve: Curves.easeInOut,
                    child: libraryState.selectedFilter == LibrarySourceFilter.cloud
                        ? Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _buildCloudSubChip(
                                    context: context,
                                    label: 'All Cloud (${libraryState.cloudTracksCount})',
                                    icon: LucideIcons.cloud,
                                    accentColor: primaryColor,
                                    sub: CloudSubFilter.all,
                                    isSelected: libraryState.cloudSubFilter == CloudSubFilter.all,
                                    onTap: () => controller.setCloudSubFilter(CloudSubFilter.all),
                                  ),
                                  const SizedBox(width: 6),
                                  _buildCloudSubChip(
                                    context: context,
                                    label: 'Spotify (${libraryState.spotifyCloudCount})',
                                    icon: LucideIcons.music2,
                                    accentColor: primaryColor,
                                    sub: CloudSubFilter.spotify,
                                    isSelected: libraryState.cloudSubFilter == CloudSubFilter.spotify,
                                    onTap: () => controller.setCloudSubFilter(CloudSubFilter.spotify),
                                  ),
                                  const SizedBox(width: 6),
                                  _buildCloudSubChip(
                                    context: context,
                                    label: 'Navidrome (${libraryState.navidromeCloudCount})',
                                    icon: LucideIcons.cloudSync,
                                    accentColor: primaryColor,
                                    sub: CloudSubFilter.navidrome,
                                    isSelected: libraryState.cloudSubFilter == CloudSubFilter.navidrome,
                                    onTap: () => controller.setCloudSubFilter(CloudSubFilter.navidrome),
                                  ),
                                  const SizedBox(width: 6),
                                  _buildCloudSubChip(
                                    context: context,
                                    label: 'YouTube (${libraryState.youtubeCloudCount})',
                                    icon: LucideIcons.playSquare,
                                    accentColor: primaryColor,
                                    sub: CloudSubFilter.youtube,
                                    isSelected: libraryState.cloudSubFilter == CloudSubFilter.youtube,
                                    onTap: () => controller.setCloudSubFilter(CloudSubFilter.youtube),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),

          // ─── 3. TAB CONTENT VIEWS ─────────────────────────────────────────
          Expanded(
            child: _buildTabContent(context, libraryState, controller),
          ),
        ],
      ),
      bottomNavigationBar: selectionState.isSelecting
          ? SafeArea(
              child: LibraryBatchActionsBar(
                selectedCount: selectionState.count,
                totalCount: libraryState.filteredTracks.length,
                onPlayNext: () {
                  final selected = libraryState.tracks.where((t) => selectionState.isSelected(t.id)).toList();
                  for (final t in selected.reversed) {
                    ref.read(playerControllerProvider.notifier).playNext(t);
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Playing ${selected.length} track${selected.length > 1 ? 's' : ''} next.')),
                  );
                  ref.read(librarySelectionProvider.notifier).clear();
                },
                onAddToQueue: () {
                  final selected = libraryState.tracks.where((t) => selectionState.isSelected(t.id)).toList();
                  for (final t in selected) {
                    ref.read(playerControllerProvider.notifier).addToQueue(t);
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Added ${selected.length} track${selected.length > 1 ? 's' : ''} to Queue.')),
                  );
                  ref.read(librarySelectionProvider.notifier).clear();
                },
                onAddToPlaylist: () {
                  final selected = libraryState.tracks.where((t) => selectionState.isSelected(t.id)).toList();
                  if (selected.isNotEmpty) {
                    _showAddToPlaylistSheetForTracks(context, selected);
                  }
                },
                onBatchEditTags: () {
                  final selected = libraryState.tracks.where((t) => selectionState.isSelected(t.id)).toList();
                  if (selected.isNotEmpty) {
                    BatchTrackTagEditorModal.show(context, selected);
                  }
                },
                onSelectAll: () => ref.read(librarySelectionProvider.notifier).selectAll(libraryState.filteredTracks),
                onDeselectAll: () => ref.read(librarySelectionProvider.notifier).deselectAll(),
                onClose: () => ref.read(librarySelectionProvider.notifier).clear(),
              ),
            )
          : null,
      floatingActionButton: showDesktopShuffleFab
          ? _buildDesktopShuffleFab(context, libraryState, theme)
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }

  Widget _buildDesktopShuffleFab(
    BuildContext context,
    UnifiedLibraryState libraryState,
    ThemeData theme,
  ) {
    return Tooltip(
      message: 'Shuffle All Tracks',
      child: M3EExtendedFab(
        key: const ValueKey('desktop_shuffle_fab'),
        icon: Icon(
          LucideIcons.shuffle,
          size: 20,
          color: theme.colorScheme.onPrimaryContainer,
        ),
        label: 'Shuffle All',
        size: M3EExtendedFabSize.small,
        color: M3EFabColor.primary,
        onPressed: () => _handleShuffleAllTracks(context, libraryState),
      ),
    );
  }

  void _handleShuffleAllTracks(
    BuildContext context,
    UnifiedLibraryState libraryState,
  ) {
    final tracks = libraryState.filteredTracks.isNotEmpty
        ? libraryState.filteredTracks
        : libraryState.tracks;

    if (tracks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No tracks to shuffle.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    AppHaptics.lightImpact();
    final shuffled = List<Track>.from(tracks)..shuffle();
    ref.read(playerControllerProvider.notifier).setQueue(
          shuffled,
          initialIndex: 0,
        );
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Shuffled ${shuffled.length} tracks into queue'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildCategoryTabsRow(
    BuildContext context,
    UnifiedLibraryState state,
    UnifiedLibraryController controller,
    Color primaryColor,
    ThemeData theme,
    bool isSolid,
  ) {
    final downloadState = ref.watch(downloadControllerProvider);
    final activeCount = downloadState.totalActiveCount;

    final tabs = [
      (tab: CollectionTab.tracks, label: 'Tracks', count: state.filteredTracks.length, icon: LucideIcons.music, color: primaryColor),
      (tab: CollectionTab.youtube, label: 'YouTube HiFi', count: null, icon: LucideIcons.playSquare, color: const Color(0xFF34D399)),
      (tab: CollectionTab.albums, label: 'Albums', count: state.albums.length, icon: LucideIcons.disc, color: primaryColor),
      (tab: CollectionTab.artists, label: 'Artists', count: state.artists.length, icon: LucideIcons.mic, color: primaryColor),
      (tab: CollectionTab.genres, label: 'Genres', count: state.genres.length, icon: LucideIcons.listMusic, color: primaryColor),
      (tab: CollectionTab.downloads, label: 'Downloads', count: activeCount > 0 ? activeCount : null, icon: LucideIcons.download, color: primaryColor),
      (tab: CollectionTab.folders, label: 'Folders', count: state.folders.length, icon: LucideIcons.folder, color: primaryColor),
    ];

    return Container(
      height: 38,
      margin: const EdgeInsets.only(top: 6, bottom: 2),
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        scrollDirection: Axis.horizontal,
        itemCount: tabs.length,
        separatorBuilder: (context, index) => const SizedBox(width: 8),
        itemBuilder: (context, idx) {
          final item = tabs[idx];
          final isSelected = state.currentTab == item.tab;
          final accent = item.color;

          return InkWell(
            onTap: () {
              AppHaptics.selectionClick();
              ref.read(librarySelectionProvider.notifier).clear();
              controller.setTab(item.tab);
            },
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isSolid
                        ? StudioSurfaceTheme.tintedContainer(context, accent, isSolid: true, solidBlendAlpha: 0.22)
                        : StudioSurfaceTheme.tintedContainer(context, accent, isSolid: false, translucentAlpha: 0.18))
                    : StudioSurfaceTheme.surfaceContainerLow(context, isSolid: isSolid),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected
                      ? (isSolid ? theme.colorScheme.outline : accent.withValues(alpha: 0.6))
                      : theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  width: isSelected ? 1.4 : 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    item.icon,
                    size: 14,
                    color: isSelected ? accent : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? accent : theme.colorScheme.onSurface.withValues(alpha: 0.8),
                    ),
                  ),
                  if (item.count != null) ...[
                    const SizedBox(width: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? accent.withValues(alpha: 0.2)
                            : theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${item.count}',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: isSelected ? accent : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          fontFeatures: AppTypography.audioFigures,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _getSubheaderSummary(UnifiedLibraryState state) {
    return switch (state.currentTab) {
      CollectionTab.tracks => '${state.filteredTracks.length} Tracks • Sorted by ${state.sortField.label}',
      CollectionTab.albums => '${state.albums.length} Albums • ${state.filteredTracks.length} Tracks',
      CollectionTab.artists => '${state.artists.length} Artists in Library',
      CollectionTab.genres => '${state.genres.length} Audio Genres',
      CollectionTab.downloads => 'Download Manager • Studio Offline Cache',
      CollectionTab.folders => '${state.folders.length} Directory Folders',
      CollectionTab.youtube => 'YouTube Music HiFi • Global Streaming',
    };
  }

  Widget _buildSourceChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color accentColor,
    required LibrarySourceFilter filter,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isSolid = ref.isSolidStyle;

    return InkWell(
      onTap: () {
        AppHaptics.selectionClick();
        ref.read(librarySelectionProvider.notifier).clear();
        onTap();
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4.5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF252834) : theme.colorScheme.primaryContainer)
              : StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected
                ? (isDark ? const Color(0xFF383D50) : theme.colorScheme.primary.withValues(alpha: 0.35))
                : theme.colorScheme.outlineVariant,
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 12,
              color: isSelected
                  ? (isDark ? Colors.white : theme.colorScheme.onPrimaryContainer)
                  : theme.colorScheme.onSurface.withValues(alpha: 0.5),
            ),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? (isDark ? Colors.white : theme.colorScheme.onPrimaryContainer)
                    : theme.colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Smaller indented sub-chip for cloud source breakdown (Spotify / Navidrome / YouTube).
  Widget _buildCloudSubChip({
    required BuildContext context,
    required String label,
    required IconData icon,
    required Color accentColor,
    required CloudSubFilter sub,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        AppHaptics.selectionClick();
        onTap();
      },
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primaryContainer
              : theme.colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? theme.colorScheme.primary.withValues(alpha: 0.4)
                : theme.colorScheme.outlineVariant,
            width: 0.8,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 11,
              color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
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
      CollectionTab.tracks => LibraryTracksTab(
          tracks: state.filteredTracks,
          scrollController: _tracksScrollController,
          bottomPadding: bottomPadding,
          emptyView: _buildEmptyState(context, 'No audio tracks found.'),
          onDismissKeyboard: () {
            _searchFocusNode.unfocus();
          },
          onAddToPlaylist: (track) => _showAddToPlaylistSheet(context, track),
        ),
      CollectionTab.albums => LibraryAlbumsTab(
          scrollController: _albumsScrollController,
          bottomPadding: bottomPadding,
          onOpenAlbum: (album) => _openAlbumDetail(context, album),
          emptyView: _buildEmptyState(context, 'No albums found.'),
        ),
      CollectionTab.artists => LibraryArtistsTab(
          scrollController: _artistsScrollController,
          bottomPadding: bottomPadding,
          onOpenArtist: (artist) => _openArtistDetail(context, artist),
          emptyView: _buildEmptyState(context, 'No artists found.'),
        ),
      CollectionTab.genres => LibraryGenresTab(
          scrollController: _genresScrollController,
          bottomPadding: bottomPadding,
          onOpenGenre: (genre) => _openGenreDetail(context, genre),
          emptyView: _buildEmptyState(context, 'No genres found.'),
        ),
      CollectionTab.downloads => const LibraryDownloadsTab(),
      CollectionTab.folders => LibraryFoldersTab(
          scrollController: _foldersScrollController,
          bottomPadding: bottomPadding,
          onOpenFolder: (folder) => _openFolderDetail(context, folder),
          emptyView: _buildEmptyState(context, 'No audio folders found.'),
        ),
      CollectionTab.youtube => _buildYouTubeDiscoveryView(context, bottomPadding),
    };
  }

  Widget _buildYouTubeDiscoveryView(BuildContext context, double bottomPadding) {
    return YouTubeDiscoveryScreen(
      showAppBar: false,
      bottomPadding: bottomPadding,
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
          M3EButton.text(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          M3EButton.filled(
            onPressed: () {
              Navigator.of(ctx).pop();
              ref.read(unifiedLibraryProvider.notifier).clearLibrary();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Music library cleared.')),
              );
            },
            label: const Text('Clear Library', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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

    if (libraryState.selectedFilter == LibrarySourceFilter.cloud &&
        libraryState.cloudSubFilter == CloudSubFilter.navidrome &&
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
                  ),
                  child: Center(
                    child: Icon(
                      LucideIcons.cloudOff,
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
                  child: M3EButton.filled(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const NavidromeConnectDialog(),
                      );
                    },
                    icon: const Icon(LucideIcons.cloudSync, size: 18, color: Colors.black),
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
                  ),
                  child: Center(
                    child: Icon(
                      LucideIcons.folder,
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
                  kIsWeb
                      ? 'Stream your lossless audio library (FLAC, WAV, DSD, ALAC, MP3) directly from the BayHifi home server.'
                      : 'Select your local music folder or pick audio files (FLAC, WAV, DSD, ALAC, MP3) to build your bit-perfect studio library.',
                  style: TextStyle(
                    fontSize: 12,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                if (kIsWeb) ...[
                  SizedBox(
                    width: double.infinity,
                    child: M3EButton.filled(
                      onPressed: () => controller.syncFromServer(),
                      icon: const Icon(LucideIcons.cloudSync, size: 18, color: Colors.black),
                      label: const Text(
                        'LOAD SERVER MUSIC LIBRARY',
                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    child: M3EButton.filled(
                      onPressed: () => controller.pickAndScanDirectory(),
                      icon: const Icon(LucideIcons.folder, size: 18, color: Colors.black),
                      label: const Text(
                        'SELECT MUSIC FOLDER',
                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: M3EButton.tonal(
                      onPressed: () => controller.pickAudioFiles(),
                      icon: Icon(LucideIcons.music, size: 18, color: primary),
                      label: const Text(
                        'PICK AUDIO FILES',
                        style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                SizedBox(
                  width: double.infinity,
                  child: M3EButton.outlined(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const NavidromeConnectDialog(),
                      );
                    },
                    icon: Icon(
                      LucideIcons.cloud,
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
                  child: M3EButton.outlined(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const YouTubeDiscoveryScreen()),
                      );
                    },
                    icon: Icon(
                      LucideIcons.playSquare,
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
          Icon(LucideIcons.search, size: 44, color: theme.dividerColor),
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
