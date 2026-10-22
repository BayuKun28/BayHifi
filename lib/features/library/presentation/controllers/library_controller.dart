import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../player/domain/track.dart';
import '../../../navidrome/data/subsonic_client.dart';
import '../../../navidrome/data/navidrome_sync_service.dart';
import '../../../navidrome/domain/subsonic_models.dart';
import '../../../../core/database/local_persistence_service.dart';
import '../../../../core/storage/storage_permission_service.dart';
import '../../../settings/data/backup_restore_service.dart';
import '../../data/library_scanner_service.dart';
import '../../data/local_audio_scanner.dart';
import '../../data/metadata_tagger_service.dart';
import '../../data/online_metadata_service.dart';
import '../../../cloud_sync/data/cloud_sync_service.dart';
import '../../../../audio_engine/audio_cache_service.dart';
import '../../domain/library_collection_models.dart';
import '../../domain/smart_playlist_models.dart';
import '../../domain/smart_playlist_evaluator.dart';

enum LibrarySourceFilter { all, offline, cloud, hiRes, untagged }

/// Sub-filter applied when [LibrarySourceFilter.cloud] is active.
enum CloudSubFilter { all, spotify, navidrome, youtube }

@immutable
class UnifiedLibraryState {
  const UnifiedLibraryState({
    this.tracks = const [],
    this.selectedFilter = LibrarySourceFilter.all,
    this.cloudSubFilter = CloudSubFilter.all,
    this.currentTab = CollectionTab.tracks,
    this.sortField = SortField.title,
    this.sortDirection = SortDirection.ascending,
    this.layoutMode = ViewLayoutMode.grid,
    this.searchQuery = '',
    this.isSearching = false,
    this.isScanning = false,
    this.isConnectingNavidrome = false,
    this.navidromeConnectionStatus = NavidromeConnectionStatus.disconnected,
    this.navidromeConfig,
    this.statusMessage,
    this.customPlaylists = const [],
    this.smartPlaylists = const [],
    this.favoriteTrackIds = const {},
  });

  final List<Track> tracks;
  final LibrarySourceFilter selectedFilter;
  final CloudSubFilter cloudSubFilter;
  final CollectionTab currentTab;
  final SortField sortField;
  final SortDirection sortDirection;
  final ViewLayoutMode layoutMode;
  final String searchQuery;
  final bool isSearching;
  final bool isScanning;
  final bool isConnectingNavidrome;
  final NavidromeConnectionStatus navidromeConnectionStatus;
  final SubsonicServerConfig? navidromeConfig;
  final String? statusMessage;
  final List<PlaylistModel> customPlaylists;
  final List<SmartPlaylist> smartPlaylists;
  final Set<String> favoriteTrackIds;

  /// Whether a track belongs to the "cloud" category (not yet downloaded to local storage).
  static bool _isCloudTrack(Track t) {
    final hasLocal = t.filePath != null && t.filePath!.isNotEmpty;
    if (hasLocal) return false;
    return (t.remoteUrl != null && t.remoteUrl!.isNotEmpty) ||
        t.id.startsWith('spotify_') ||
        t.id.startsWith('yt_');
  }

  static bool _isSpotifyCloudTrack(Track t) =>
      !_hasLocalFile(t) &&
      (t.id.startsWith('spotify_') || (t.remoteUrl?.startsWith('spotify') ?? false));

  static bool _isNavidromeCloudTrack(Track t) =>
      !_hasLocalFile(t) &&
      !(t.id.startsWith('spotify_')) &&
      !(t.id.startsWith('yt_')) &&
      (t.remoteUrl != null && t.remoteUrl!.isNotEmpty);

  static bool _isYouTubeCloudTrack(Track t) =>
      !_hasLocalFile(t) &&
      (t.id.startsWith('yt_') || (t.remoteUrl?.contains('youtube') ?? false) || (t.remoteUrl?.contains('googlevideo') ?? false));

  static bool _hasLocalFile(Track t) {
    if (kIsWeb) {
      return !(t.id.startsWith('spotify_')) && !(t.id.startsWith('yt_'));
    }
    return t.filePath != null && t.filePath!.isNotEmpty;
  }

  /// Daftar lagu yang telah difilter dan diurutkan
  List<Track> get filteredTracks {
    final list = tracks.where((t) {
      // 1. Source filter
      bool matchesSource;
      switch (selectedFilter) {
        case LibrarySourceFilter.all:
          matchesSource = true;
          break;
        case LibrarySourceFilter.offline:
          matchesSource = _hasLocalFile(t);
          break;
        case LibrarySourceFilter.cloud:
          if (!_isCloudTrack(t)) {
            matchesSource = false;
          } else {
            matchesSource = switch (cloudSubFilter) {
              CloudSubFilter.all => true,
              CloudSubFilter.spotify => _isSpotifyCloudTrack(t),
              CloudSubFilter.navidrome => _isNavidromeCloudTrack(t),
              CloudSubFilter.youtube => _isYouTubeCloudTrack(t),
            };
          }
          break;
        case LibrarySourceFilter.hiRes:
          matchesSource = t.isHiRes;
          break;
        case LibrarySourceFilter.untagged:
          matchesSource = t.isUntagged;
          break;
      }

      if (!matchesSource) return false;

      // 2. Search query filter
      if (searchQuery.trim().isEmpty) return true;
      final q = searchQuery.toLowerCase().trim();
      return t.title.toLowerCase().contains(q) ||
          t.artist.toLowerCase().contains(q) ||
          t.album.toLowerCase().contains(q);
    }).toList();

    // 3. Sorting
    list.sort((a, b) {
      int cmp = 0;
      switch (sortField) {
        case SortField.title:
          cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;
        case SortField.artist:
          cmp = a.artist.toLowerCase().compareTo(b.artist.toLowerCase());
          break;
        case SortField.album:
          cmp = a.album.toLowerCase().compareTo(b.album.toLowerCase());
          break;
        case SortField.duration:
          cmp = a.duration.compareTo(b.duration);
          break;
        case SortField.dateAdded:
          cmp = a.id.compareTo(b.id);
          break;
        case SortField.hiRes:
          final aScore = (a.bitDepth ?? 16) * 1000000 + (a.sampleRate ?? 44100);
          final bScore = (b.bitDepth ?? 16) * 1000000 + (b.sampleRate ?? 44100);
          cmp = bScore.compareTo(aScore);
          break;
      }
      return sortDirection == SortDirection.ascending ? cmp : -cmp;
    });

    return list;
  }

  /// Koleksi Album
  List<AlbumModel> get albums {
    final map = <String, List<Track>>{};
    for (final t in filteredTracks) {
      final albumName = t.album.trim().isEmpty ? 'Unknown Album' : t.album.trim();
      final artistName = t.artist.trim().isEmpty ? 'Unknown Artist' : t.artist.trim();
      final key = '${albumName.toLowerCase()}__${artistName.toLowerCase()}';
      map.putIfAbsent(key, () => []).add(t);
    }

    final result = map.entries.map((e) {
      final tracksList = e.value;
      final first = tracksList.first;
      final coverTrack = tracksList.firstWhere(
        (t) =>
            (t.albumArtBytes != null && t.albumArtBytes!.isNotEmpty) ||
            (t.albumArtUrl != null && t.albumArtUrl!.isNotEmpty) ||
            (t.filePath != null && t.filePath!.isNotEmpty),
        orElse: () => first,
      );
      return AlbumModel(
        name: first.album.isEmpty ? 'Unknown Album' : first.album,
        artist: first.artist.isEmpty ? 'Unknown Artist' : first.artist,
        tracks: tracksList,
        coverUrl: coverTrack.albumArtUrl,
        coverBytes: coverTrack.albumArtBytes,
      );
    }).toList();

    result.sort((a, b) {
      int cmp = 0;
      switch (sortField) {
        case SortField.album:
        case SortField.title:
          cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case SortField.artist:
          cmp = a.artist.toLowerCase().compareTo(b.artist.toLowerCase());
          break;
        case SortField.duration:
          final aDur = a.tracks.fold<Duration>(Duration.zero, (prev, t) => prev + t.duration);
          final bDur = b.tracks.fold<Duration>(Duration.zero, (prev, t) => prev + t.duration);
          cmp = aDur.compareTo(bDur);
          break;
        case SortField.dateAdded:
          cmp = a.tracks.length.compareTo(b.tracks.length);
          break;
        case SortField.hiRes:
          final aHi = a.isHiRes ? 1 : 0;
          final bHi = b.isHiRes ? 1 : 0;
          cmp = bHi.compareTo(aHi);
          break;
      }
      return sortDirection == SortDirection.ascending ? cmp : -cmp;
    });

    return result;
  }

  /// Koleksi Artis
  List<ArtistModel> get artists {
    final map = <String, List<Track>>{};
    for (final t in filteredTracks) {
      final key = t.artist.trim().isEmpty ? 'Unknown Artist' : t.artist.trim();
      map.putIfAbsent(key, () => []).add(t);
    }

    final result = map.entries.map((e) {
      final tracksList = e.value;
      final coverTrack = tracksList.firstWhere(
        (t) =>
            (t.albumArtBytes != null && t.albumArtBytes!.isNotEmpty) ||
            (t.albumArtUrl != null && t.albumArtUrl!.isNotEmpty) ||
            (t.filePath != null && t.filePath!.isNotEmpty),
        orElse: () => tracksList.first,
      );
      return ArtistModel(
        name: e.key,
        tracks: tracksList,
        coverUrl: coverTrack.albumArtUrl,
        coverBytes: coverTrack.albumArtBytes,
      );
    }).toList();

    result.sort((a, b) {
      int cmp = 0;
      switch (sortField) {
        case SortField.artist:
        case SortField.title:
        case SortField.album:
          cmp = a.name.toLowerCase().compareTo(b.name.toLowerCase());
          break;
        case SortField.duration:
        case SortField.dateAdded:
          cmp = a.tracksCount.compareTo(b.tracksCount);
          break;
        case SortField.hiRes:
          final aHi = a.tracks.where((t) => t.isHiRes).length;
          final bHi = b.tracks.where((t) => t.isHiRes).length;
          cmp = bHi.compareTo(aHi);
          break;
      }
      return sortDirection == SortDirection.ascending ? cmp : -cmp;
    });
    return result;
  }

  /// Koleksi Genre
  List<GenreModel> get genres {
    final map = <String, List<Track>>{};
    for (final t in filteredTracks) {
      final g = t.genre != null && t.genre!.trim().isNotEmpty
          ? t.genre!.trim()
          : (t.isHiRes ? 'Hi-Res Lossless' : 'Other / Unknown');
      map.putIfAbsent(g, () => []).add(t);
    }

    final result = map.entries.map((e) {
      return GenreModel(name: e.key, tracks: e.value);
    }).toList();

    result.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    return result;
  }

  /// Koleksi Playlist (Favorit + Hi-Res Masters + Custom User Playlists)
  List<PlaylistModel> get playlists {
    final favTracks = tracks.where((t) => favoriteTrackIds.contains(t.id)).toList();
    final hiResTracks = tracks.where((t) => t.isHiRes).toList();

    final builtIn = [
      PlaylistModel(
        id: 'favorites',
        name: 'Favorite Tracks',
        description: 'Collection of starred and liked tracks',
        tracks: favTracks,
        isCustom: false,
        createdAt: DateTime(2026, 1, 1),
      ),
      PlaylistModel(
        id: 'hires_master',
        name: 'Hi-Res Lossless Masters',
        description: '24-bit / 96kHz+ FLAC studio masters',
        tracks: hiResTracks,
        isCustom: false,
        createdAt: DateTime(2026, 1, 1),
      ),
    ];

    return [...builtIn, ...customPlaylists];
  }

  /// Koleksi Folder
  List<FolderModel> get folders {
    final map = <String, List<Track>>{};
    final pathMap = <String, String>{};

    for (final t in filteredTracks) {
      if (t.filePath != null && t.filePath!.isNotEmpty) {
        final normalized = t.filePath!.replaceAll('\\', '/');
        final lastSlash = normalized.lastIndexOf('/');
        final parentPath = lastSlash != -1 ? normalized.substring(0, lastSlash) : normalized;
        final folderName = parentPath.split('/').where((s) => s.isNotEmpty).isNotEmpty
            ? parentPath.split('/').where((s) => s.isNotEmpty).last
            : 'Music Folder';

        map.putIfAbsent(folderName, () => []).add(t);
        pathMap.putIfAbsent(folderName, () => parentPath);
      } else if (t.id.startsWith('spotify_') || (t.remoteUrl?.startsWith('spotify') ?? false)) {
        map.putIfAbsent('Spotify Cloud Library', () => []).add(t);
        pathMap.putIfAbsent('Spotify Cloud Library', () => 'spotify://cloud');
      } else if (t.remoteUrl != null && t.remoteUrl!.isNotEmpty) {
        map.putIfAbsent('Navidrome Cloud Library', () => []).add(t);
        pathMap.putIfAbsent('Navidrome Cloud Library', () => 'subsonic://cloud');
      } else {
        map.putIfAbsent('Cloud & Streaming', () => []).add(t);
        pathMap.putIfAbsent('Cloud & Streaming', () => 'cloud://streaming');
      }
    }

    return map.entries.map((e) {
      final folderPath = pathMap[e.key] ?? e.key;
      return FolderModel(path: folderPath, name: e.key, tracks: e.value);
    }).toList();
  }

  List<String> get configuredFolderPaths =>
      LocalPersistenceService.instance.getMusicFolders();

  int get totalTracksCount => tracks.length;
  int get offlineTracksCount => tracks.where(_hasLocalFile).length;
  int get cloudTracksCount => tracks.where(_isCloudTrack).length;
  int get spotifyCloudCount => tracks.where(_isSpotifyCloudTrack).length;
  int get navidromeCloudCount => tracks.where(_isNavidromeCloudTrack).length;
  int get youtubeCloudCount => tracks.where(_isYouTubeCloudTrack).length;
  // Keep for backward compat
  int get navidromeTracksCount => navidromeCloudCount;
  int get hiResTracksCount => tracks.where((t) => t.isHiRes).length;
  int get untaggedTracksCount => tracks.where((t) => t.isUntagged).length;

  List<Track> getSmartPlaylistTracks(SmartPlaylist playlist) {
    return const SmartPlaylistEvaluator().evaluate(
      playlist: playlist,
      allTracks: tracks,
      favoriteTrackIds: favoriteTrackIds,
    );
  }

  UnifiedLibraryState copyWith({
    List<Track>? tracks,
    LibrarySourceFilter? selectedFilter,
    CloudSubFilter? cloudSubFilter,
    CollectionTab? currentTab,
    SortField? sortField,
    SortDirection? sortDirection,
    ViewLayoutMode? layoutMode,
    String? searchQuery,
    bool? isSearching,
    bool? isScanning,
    bool? isConnectingNavidrome,
    NavidromeConnectionStatus? navidromeConnectionStatus,
    SubsonicServerConfig? navidromeConfig,
    String? statusMessage,
    List<PlaylistModel>? customPlaylists,
    List<SmartPlaylist>? smartPlaylists,
    Set<String>? favoriteTrackIds,
    bool clearStatusMessage = false,
  }) {
    return UnifiedLibraryState(
      tracks: tracks ?? this.tracks,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      cloudSubFilter: cloudSubFilter ?? this.cloudSubFilter,
      currentTab: currentTab ?? this.currentTab,
      sortField: sortField ?? this.sortField,
      sortDirection: sortDirection ?? this.sortDirection,
      layoutMode: layoutMode ?? this.layoutMode,
      searchQuery: searchQuery ?? this.searchQuery,
      isSearching: isSearching ?? this.isSearching,
      isScanning: isScanning ?? this.isScanning,
      isConnectingNavidrome: isConnectingNavidrome ?? this.isConnectingNavidrome,
      navidromeConnectionStatus:
          navidromeConnectionStatus ?? this.navidromeConnectionStatus,
      navidromeConfig: navidromeConfig ?? this.navidromeConfig,
      statusMessage: clearStatusMessage ? null : (statusMessage ?? this.statusMessage),
      customPlaylists: customPlaylists ?? this.customPlaylists,
      smartPlaylists: smartPlaylists ?? this.smartPlaylists,
      favoriteTrackIds: favoriteTrackIds ?? this.favoriteTrackIds,
    );
  }
}

final onlineMetadataServiceProvider = Provider<OnlineMetadataService>((ref) {
  return OnlineMetadataService();
});

final unifiedLibraryProvider =
    StateNotifierProvider<UnifiedLibraryController, UnifiedLibraryState>((ref) {
  return UnifiedLibraryController();
});

class UnifiedLibraryController extends StateNotifier<UnifiedLibraryState> {
  UnifiedLibraryController({
    LocalAudioScanner? scanner,
    SubsonicClient? subsonicClient,
    MetadataTaggerService? tagger,
    OnlineMetadataService? onlineTagger,
    LibraryScannerService? scannerService,
    NavidromeSyncService? navidromeSyncService,
    List<Track>? initialTracks,
    List<PlaylistModel>? initialCustomPlaylists,
    List<SmartPlaylist>? initialSmartPlaylists,
  })  : _scanner = scanner ?? const LocalAudioScanner(),
        _subsonicClient = subsonicClient ?? SubsonicClient(),
        _tagger = tagger ?? const MetadataTaggerService(),
        _onlineTagger = onlineTagger ?? OnlineMetadataService(),
        _scannerService = scannerService ?? LibraryScannerService(scanner: scanner ?? const LocalAudioScanner()),
        _navidromeSyncService = navidromeSyncService ?? NavidromeSyncService(client: subsonicClient ?? SubsonicClient()),
        super(UnifiedLibraryState(
          tracks: initialTracks ?? _loadSavedTracks(),
          customPlaylists: initialCustomPlaylists ?? _loadSavedCustomPlaylists(),
          smartPlaylists: initialSmartPlaylists ?? _loadSavedSmartPlaylists(),
          favoriteTrackIds: LocalPersistenceService.instance.getFavoriteTrackIds().toSet(),
        )) {
    // Non-blocking differential startup sync for newly added tracks, missing artwork, and Navidrome session
    Future.microtask(() async {
      final didRestore = await BackupRestoreService.instance.autoRestoreIfDatabaseEmpty();
      if (didRestore) {
        state = state.copyWith(
          tracks: _loadSavedTracks(),
          customPlaylists: _loadSavedCustomPlaylists(),
          smartPlaylists: _loadSavedSmartPlaylists(),
          favoriteTrackIds: LocalPersistenceService.instance.getFavoriteTrackIds().toSet(),
        );
      }
      if (kIsWeb) {
        await syncFromServer();
      } else {
        await syncNewTracksOnStartup();
        await recoverMissingArtwork();
        await restoreNavidromeSession();
      }
    });
  }

  final LocalAudioScanner _scanner;
  final SubsonicClient _subsonicClient;
  final MetadataTaggerService _tagger;
  final OnlineMetadataService _onlineTagger;
  final LibraryScannerService _scannerService;
  final NavidromeSyncService _navidromeSyncService;

  LocalAudioScanner get scanner => _scanner;
  SubsonicClient get subsonicClient => _subsonicClient;
  MetadataTaggerService get tagger => _tagger;
  OnlineMetadataService get onlineTagger => _onlineTagger;
  LibraryScannerService get scannerService => _scannerService;
  NavidromeSyncService get navidromeSyncService => _navidromeSyncService;

  static List<SmartPlaylist> _loadSavedSmartPlaylists() {
    try {
      final savedMaps = LocalPersistenceService.instance.getSmartPlaylists();
      if (savedMaps.isNotEmpty) {
        return savedMaps.map(SmartPlaylist.fromMap).toList();
      }
    } catch (e) {
      debugPrint('[UnifiedLibraryController] Error loading smart playlists: $e');
    }
    return SmartPlaylistEvaluator.defaultPresets;
  }

  static List<PlaylistModel> _loadSavedCustomPlaylists() {
    try {
      final savedMaps = LocalPersistenceService.instance.getCustomPlaylists();
      if (savedMaps.isNotEmpty) {
        return savedMaps.map(PlaylistModel.fromMap).toList();
      }
    } catch (e) {
      debugPrint('[UnifiedLibraryController] Error loading custom playlists: $e');
    }
    return const [];
  }

  static List<Track> _loadSavedTracks() {
    try {
      final savedMaps = LocalPersistenceService.instance.getSavedLibraryTracks();
      if (savedMaps.isNotEmpty) {
        return savedMaps.map(Track.fromMap).toList();
      }
    } catch (e) {
      debugPrint('[UnifiedLibraryController] Error loading saved tracks: $e');
    }
    return LocalAudioScanner.defaultLocalTracks;
  }

  void reloadFromPersistence() {
    final tracks = _loadSavedTracks();
    final customPlaylists = _loadSavedCustomPlaylists();
    final smartPlaylists = _loadSavedSmartPlaylists();
    final favIds = LocalPersistenceService.instance.getFavoriteTrackIds().toSet();
    state = state.copyWith(
      tracks: tracks,
      customPlaylists: customPlaylists,
      smartPlaylists: smartPlaylists,
      favoriteTrackIds: favIds,
    );
  }

  void saveLibraryTracks(List<Track> updatedTracks) {
    state = state.copyWith(tracks: updatedTracks);
    LocalPersistenceService.instance.saveLibraryTracks(
      updatedTracks.map((t) => t.toMap()).toList(),
    );
  }

  void setTab(CollectionTab tab) {
    state = state.copyWith(currentTab: tab);
  }

  void setFilter(LibrarySourceFilter filter) {
    state = state.copyWith(
      selectedFilter: filter,
      // Reset sub-filter when switching to a different top-level filter
      cloudSubFilter: CloudSubFilter.all,
    );
  }

  void setCloudSubFilter(CloudSubFilter sub) {
    state = state.copyWith(cloudSubFilter: sub);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void toggleSearch([bool? force]) {
    final next = force ?? !state.isSearching;
    state = state.copyWith(isSearching: next, searchQuery: next ? state.searchQuery : '');
  }

  void setSortField(SortField field) {
    state = state.copyWith(sortField: field);
  }

  void setSortDirection(SortDirection direction) {
    state = state.copyWith(sortDirection: direction);
  }

  void toggleSortDirection() {
    state = state.copyWith(
      sortDirection: state.sortDirection == SortDirection.ascending
          ? SortDirection.descending
          : SortDirection.ascending,
    );
  }

  void toggleLayoutMode() {
    state = state.copyWith(
      layoutMode: state.layoutMode == ViewLayoutMode.list
          ? ViewLayoutMode.grid
          : ViewLayoutMode.list,
    );
  }

  void toggleFavorite(String trackId) {
    final favs = Set<String>.from(state.favoriteTrackIds);
    if (favs.contains(trackId)) {
      favs.remove(trackId);
    } else {
      favs.add(trackId);
    }
    LocalPersistenceService.instance.saveFavoriteTrackIds(favs);
    state = state.copyWith(favoriteTrackIds: favs);
  }

  void createPlaylist(String name, String description) {
    final newPlaylist = PlaylistModel(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      tracks: const [],
      isCustom: true,
      createdAt: DateTime.now(),
    );
    final updated = [...state.customPlaylists, newPlaylist];
    _persistCustomPlaylists(updated);
    state = state.copyWith(
      customPlaylists: updated,
      statusMessage: 'Playlist "$name" successfully created.',
    );
  }

  /// Imports a streaming playlist (Spotify / YouTube) into user collections
  void importStreamingPlaylist(PlaylistModel playlist) {
    final existingIndex = state.customPlaylists.indexWhere((p) => p.id == playlist.id);
    final updated = List<PlaylistModel>.from(state.customPlaylists);
    if (existingIndex >= 0) {
      updated[existingIndex] = playlist;
    } else {
      updated.add(playlist);
    }
    _persistCustomPlaylists(updated);

    // Also register or update newly imported tracks in library with rich metadata/artwork
    final Map<String, Track> trackMap = {
      for (final t in state.tracks) t.id: t,
    };
    for (final t in playlist.tracks) {
      if (!trackMap.containsKey(t.id) || (trackMap[t.id]?.albumArtUrl == null && t.albumArtUrl != null)) {
        trackMap[t.id] = t;
      }
    }
    final combined = trackMap.values.toList();
    _persistTracks(combined);
    state = state.copyWith(
      tracks: combined,
      customPlaylists: updated,
      statusMessage: 'Imported "${playlist.name}" (${playlist.tracks.length} tracks).',
    );
  }

  void addTrackToPlaylist(String playlistId, Track track) {
    final updated = state.customPlaylists.map((p) {
      if (p.id == playlistId) {
        if (p.tracks.any((t) => t.id == track.id)) return p;
        return p.copyWith(tracks: [...p.tracks, track]);
      }
      return p;
    }).toList();

    _persistCustomPlaylists(updated);
    state = state.copyWith(
      customPlaylists: updated,
      statusMessage: 'Track added to playlist.',
    );
  }

  /// Updates a single track in the library state, persistence, and any custom playlists (e.g. after download)
  void updateTrack(Track updatedTrack) {
    final existingIndex = state.tracks.indexWhere((t) => t.id == updatedTrack.id);
    final updatedTracks = List<Track>.from(state.tracks);
    if (existingIndex >= 0) {
      updatedTracks[existingIndex] = updatedTrack;
    } else {
      updatedTracks.add(updatedTrack);
    }

    final updatedCustomPlaylists = state.customPlaylists.map((p) {
      final trackIndex = p.tracks.indexWhere((t) => t.id == updatedTrack.id);
      if (trackIndex >= 0) {
        final newPlaylistTracks = List<Track>.from(p.tracks);
        newPlaylistTracks[trackIndex] = updatedTrack;
        return p.copyWith(tracks: newPlaylistTracks);
      }
      return p;
    }).toList();

    _persistTracks(updatedTracks);
    _persistCustomPlaylists(updatedCustomPlaylists);

    state = state.copyWith(
      tracks: updatedTracks,
      customPlaylists: updatedCustomPlaylists,
    );
  }

  /// Check and request storage & notification permissions (Android audio & external storage access)
  Future<bool> ensureStoragePermissions() async {
    return _scannerService.ensureStoragePermissions();
  }

  /// Open directory picker to select and scan user's custom music folder
  Future<void> pickAndScanDirectory() async {
    try {
      state = state.copyWith(
        isScanning: true,
        statusMessage: 'Scanning audio folder...',
      );

      final result = await _scannerService.pickAndScanDirectory(
        currentTracks: state.tracks,
        onProgress: (count, folder) {
          state = state.copyWith(
            statusMessage: 'Scanning: $folder ($count tracks found)...',
          );
        },
      );

      if (result == null) {
        state = state.copyWith(isScanning: false);
        return;
      }

      state = state.copyWith(
        tracks: result.allTracks,
        isScanning: false,
        selectedFilter: LibrarySourceFilter.all,
        searchQuery: '',
        isSearching: false,
        statusMessage: result.statusMessage,
      );
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        statusMessage: 'Failed to scan directory: $e',
      );
    }
  }

  /// Open file picker to choose specific audio files
  Future<void> pickAudioFiles() async {
    try {
      state = state.copyWith(
        isScanning: true,
        statusMessage: 'Importing selected audio files...',
      );

      final result = await _scannerService.pickAudioFiles(
        currentTracks: state.tracks,
      );

      if (result == null) {
        state = state.copyWith(isScanning: false);
        return;
      }

      state = state.copyWith(
        tracks: result.allTracks,
        isScanning: false,
        selectedFilter: LibrarySourceFilter.all,
        searchQuery: '',
        isSearching: false,
        statusMessage: result.statusMessage,
      );
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        statusMessage: 'Failed to import audio files: $e',
      );
    }
  }

  /// Sinkronisasi daftar lagu dari server (Docker Backend / Navidrome / Cloud)
  Future<void> syncFromServer({String? serverUrl}) async {
    state = state.copyWith(isScanning: true, statusMessage: 'Syncing music from server...');
    try {
      final syncService = CloudSyncService();
      final url = serverUrl ?? (kIsWeb ? Uri.base.origin : 'http://localhost:8111');
      final rawTracks = await syncService.fetchLibraryTracks(
        serverUrl: url,
        limit: 10000,
      );

      if (rawTracks.isNotEmpty) {
        final serverTracks = rawTracks.map((m) {
          final id = m['id']?.toString() ?? '';
          final title = m['title']?.toString() ?? 'Unknown Title';
          final artist = m['artist']?.toString() ?? 'Unknown Artist';
          final album = m['album']?.toString() ?? 'Unknown Album';
          final durationMs = (m['duration'] as num?)?.toInt() ??
              (((m['duration_ms'] as num?)?.toInt() ?? 180000));
          final formatStr = m['format']?.toString().toLowerCase() ?? 'mp3';
          final streamUrl = kIsWeb ? '/api/library/stream/$id' : '$url/api/library/stream/$id';
          final coverUrl = (m['hasEmbeddedArtwork'] == true || m['has_embedded_artwork'] == true)
              ? (kIsWeb ? '/api/library/cover/$id' : '$url/api/library/cover/$id')
              : null;

          return Track(
            id: id,
            title: title,
            artist: artist,
            album: album,
            duration: Duration(milliseconds: durationMs),
            filePath: null,
            remoteUrl: streamUrl,
            albumArtUrl: coverUrl,
            format: _resolveFormatFromStr(formatStr),
            bitrate: (m['bitrate'] as num?)?.toInt(),
            sampleRate: (m['sampleRate'] as num?)?.toInt() ?? (m['sample_rate'] as num?)?.toInt(),
            bitDepth: (m['bitDepth'] as num?)?.toInt() ?? (m['bit_depth'] as num?)?.toInt(),
            genre: m['genre']?.toString(),
            year: (m['year'] as num?)?.toInt(),
            trackNumber: (m['trackNumber'] as num?)?.toInt() ?? (m['track_number'] as num?)?.toInt(),
            fileSize: (m['fileSize'] as num?)?.toInt() ?? (m['file_size_bytes'] as num?)?.toInt(),
          );
        }).toList();

        // Merge with existing cloud tracks (Spotify / YouTube)
        final existingCloud = state.tracks.where((t) => t.id.startsWith('spotify_') || t.id.startsWith('yt_')).toList();
        final combined = [...serverTracks, ...existingCloud];
        await _persistTracks(combined);
        state = state.copyWith(
          tracks: combined,
          isScanning: false,
          statusMessage: 'Discovered ${serverTracks.length} tracks from server.',
        );
        return;
      }
    } catch (e) {
      debugPrint('[UnifiedLibraryController] Error syncing from server: $e');
    } finally {
      if (mounted) {
        state = state.copyWith(isScanning: false);
      }
    }
  }

  static AudioFormat _resolveFormatFromStr(String ext) {
    switch (ext) {
      case 'flac':
        return AudioFormat.flac;
      case 'wav':
        return AudioFormat.wav;
      case 'mp3':
        return AudioFormat.mp3;
      case 'opus':
        return AudioFormat.opus;
      case 'ogg':
        return AudioFormat.ogg;
      case 'alac':
      case 'm4a':
      case 'aac':
        return AudioFormat.alac;
      case 'dsd':
      case 'dsf':
      case 'dff':
        return AudioFormat.dsd;
      default:
        return AudioFormat.unknown;
    }
  }

  /// Rescan all previously configured music folders
  Future<void> rescanSavedFolders() async {
    if (kIsWeb) {
      await syncFromServer();
      return;
    }
    final savedFolders = LocalPersistenceService.instance.getMusicFolders();
    if (savedFolders.isEmpty) {
      await pickAndScanDirectory();
      return;
    }

    state = state.copyWith(
      isScanning: true,
      statusMessage: 'Rescanning ${savedFolders.length} music folders...',
    );

    try {
      final combined = await _scannerService.rescanSavedFolders(
        currentTracks: state.tracks,
        savedFolders: savedFolders,
        onProgress: (count, path) {
          state = state.copyWith(
            statusMessage: 'Scanning $path ($count tracks found)...',
          );
        },
      );

      state = state.copyWith(
        tracks: combined,
        isScanning: false,
        selectedFilter: LibrarySourceFilter.all,
        searchQuery: '',
        isSearching: false,
        statusMessage: 'Rescan complete. Found ${combined.length} local audio tracks.',
      );
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        statusMessage: 'Rescan failed: $e',
      );
    }
  }

  /// Scan local music library (picks a directory if none saved, or rescans saved folders)
  Future<void> scanLocalMusic() async {
    var savedFolders = LocalPersistenceService.instance.getMusicFolders();
    if (savedFolders.isEmpty && !kIsWeb && Platform.isAndroid) {
      try {
        final publicMusicDir = await StoragePermissionService.instance.getPublicMusicDirectory();
        if (publicMusicDir.existsSync()) {
          savedFolders = [publicMusicDir.path];
          await LocalPersistenceService.instance.saveMusicFolders(savedFolders);
        }
      } catch (_) {}
    }

    if (savedFolders.isNotEmpty) {
      await rescanSavedFolders();
    } else {
      await pickAndScanDirectory();
    }
  }

  /// Silent background sync on startup: only parses new or modified files
  Future<void> syncNewTracksOnStartup() async {
    try {
      final updated = await _scannerService.syncNewTracksOnStartup(
        currentTracks: state.tracks,
      );
      if (updated != null) {
        state = state.copyWith(tracks: updated);
      }
    } catch (e) {
      debugPrint('[UnifiedLibraryController] Background startup sync notice: $e');
    }
  }

  /// Memulihkan album artwork yang hilang di latar belakang
  Future<void> recoverMissingArtwork() async {
    try {
      final updated = await _scannerService.recoverMissingArtwork(
        currentTracks: state.tracks,
      );
      if (updated != null) {
        state = state.copyWith(tracks: updated);
      }
    } catch (e) {
      debugPrint('[UnifiedLibraryController] Artwork recovery notice: $e');
    }
  }

  /// Scan physical local directory
  Future<void> scanDirectory(dynamic directory) async {
    state = state.copyWith(isScanning: true, statusMessage: 'Scanning audio folder...');
    try {
      final dir = directory is Directory ? directory : Directory(directory.toString());
      final scanned = await _scanner.scanDirectory(dir);

      final existingTrackPaths = state.tracks.map((t) => t.filePath).whereType<String>().toSet();
      final newTracks = scanned
          .where((t) => t.filePath == null || !existingTrackPaths.contains(t.filePath))
          .toList();
      final combined = [...state.tracks, ...newTracks];

      await _persistTracks(combined);

      state = state.copyWith(
        tracks: combined,
        isScanning: false,
        statusMessage: '${scanned.length} local audio files discovered.',
      );
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        statusMessage: 'Failed to scan local folder: $e',
      );
    }
  }

  /// Clear all local audio tracks from library
  Future<void> clearLibrary() async {
    final existingCloud = state.tracks.where((t) => t.remoteUrl != null).toList();

    await LocalPersistenceService.instance.saveLibraryTracks(
      existingCloud.map((t) => t.toMap()).toList(),
    );
    await LocalPersistenceService.instance.saveMusicFolders([]);

    state = state.copyWith(
      tracks: existingCloud,
      statusMessage: 'Music library cleared.',
    );
  }

  Future<void> _persistTracks(List<Track> tracks) async {
    try {
      final maps = tracks.map((t) => t.toMap()).toList();
      await LocalPersistenceService.instance.saveLibraryTracks(maps);
    } catch (e) {
      debugPrint('[UnifiedLibraryController] Error persisting tracks: $e');
    }
  }

  /// Connect to Navidrome Subsonic API server
  Future<bool> connectNavidrome(SubsonicServerConfig config, {bool isSilent = false}) async {
    state = state.copyWith(
      isConnectingNavidrome: true,
      navidromeConnectionStatus: NavidromeConnectionStatus.connecting,
      statusMessage: isSilent ? null : 'Connecting to ${config.sanitizedUrl}...',
      clearStatusMessage: isSilent,
    );

    try {
      final isOnline = await _navidromeSyncService.connect(config);

      if (isOnline) {
        state = state.copyWith(
          isConnectingNavidrome: false,
          navidromeConnectionStatus: NavidromeConnectionStatus.connected,
          navidromeConfig: config,
          statusMessage: isSilent ? null : 'Connected to Navidrome server.',
          clearStatusMessage: isSilent,
        );

        await syncNavidromeLibrary(isSilent: isSilent);
        return true;
      } else {
        state = state.copyWith(
          isConnectingNavidrome: false,
          navidromeConnectionStatus: NavidromeConnectionStatus.error,
          statusMessage: 'Failed to connect to Navidrome server. Please verify URL and credentials.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isConnectingNavidrome: false,
        navidromeConnectionStatus: NavidromeConnectionStatus.error,
        statusMessage: 'Navidrome connection error: $e',
      );
      return false;
    }
  }

  /// Restore saved Navidrome session on startup (silent unless error)
  Future<void> restoreNavidromeSession({bool isSilent = true}) async {
    if (state.navidromeConnectionStatus == NavidromeConnectionStatus.connected || state.isConnectingNavidrome) {
      return;
    }
    final config = _navidromeSyncService.getSavedConfig();
    if (config != null) {
      await connectNavidrome(config, isSilent: isSilent);
    }
  }

  /// Synchronize catalog from Navidrome
  Future<void> syncNavidromeLibrary({bool isSilent = false}) async {
    final config = state.navidromeConfig;
    if (config == null) return;

    state = state.copyWith(
      isScanning: true,
      statusMessage: isSilent ? null : 'Syncing Navidrome library...',
      clearStatusMessage: isSilent,
    );

    try {
      final cloudTracks = await _navidromeSyncService.fetchRemoteTracks(config);

      final existingLocal = state.tracks.where((t) => t.filePath != null).toList();
      final combined = [...existingLocal, ...cloudTracks];

      state = state.copyWith(
        tracks: combined,
        isScanning: false,
        statusMessage: isSilent ? null : '${cloudTracks.length} cloud tracks successfully synchronized.',
        clearStatusMessage: isSilent,
      );
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        statusMessage: 'Failed to sync Navidrome: $e',
      );
    }
  }

  /// Disconnect Navidrome
  void disconnectNavidrome() {
    final existingLocal = state.tracks.where((t) => t.filePath != null).toList();
    _navidromeSyncService.disconnect();
    state = state.copyWith(
      tracks: existingLocal,
      navidromeConnectionStatus: NavidromeConnectionStatus.disconnected,
      navidromeConfig: null,
      statusMessage: 'Navidrome disconnected.',
    );
  }

  /// Updates metadata for a track in the unified library
  void updateTrackMetadata(
    String trackId, {
    required String title,
    required String artist,
    required String album,
    String? genre,
    int? year,
    int? trackNumber,
    int? trackTotal,
    int? discNumber,
    int? discTotal,
    String? albumArtist,
    String? lyrics,
  }) {
    final updatedTracks = state.tracks.map((t) {
      if (t.id == trackId) {
        return t.copyWith(
          title: title.trim().isNotEmpty ? title.trim() : t.title,
          artist: artist.trim().isNotEmpty ? artist.trim() : t.artist,
          album: album.trim().isNotEmpty ? album.trim() : t.album,
          genre: genre?.trim(),
          year: year,
          trackNumber: trackNumber,
          trackTotal: trackTotal,
          discNumber: discNumber,
          discTotal: discTotal,
          albumArtist: albumArtist?.trim(),
          lyrics: lyrics?.trim(),
        );
      }
      return t;
    }).toList();

    _persistTracks(updatedTracks);
    state = state.copyWith(tracks: updatedTracks);
  }

  /// Save updated metadata tags for a single track (writes to file and syncs DB)
  Future<Track?> updateTrackTags(
    String trackId,
    AudioTagData tagData, {
    bool writeToFile = true,
  }) async {
    final idx = state.tracks.indexWhere((t) => t.id == trackId);
    if (idx < 0) return null;
    final original = state.tracks[idx];

    String? cachedArtPath;
    if (tagData.artworkBytes != null && tagData.artworkBytes!.isNotEmpty) {
      cachedArtPath = await _tagger.cacheCoverArt(tagData.artworkBytes!, original.id);
    }

    PhysicalTagWriteResult writeResult =
        const PhysicalTagWriteResult(status: PhysicalTagWriteStatus.virtualTrack);
    if (writeToFile && original.filePath != null && original.filePath!.isNotEmpty) {
      writeResult = await _tagger.writePhysicalTags(original.filePath!, tagData);
    }

    final updated = tagData.applyToTrack(original, newAlbumArtUrl: cachedArtPath);
    final updatedList = List<Track>.from(state.tracks);
    updatedList[idx] = updated;

    await _persistTracks(updatedList);
    BackupRestoreService.instance.scheduleAutoBackup();

    final statusSuffix = writeResult.isPhysicalSuccess
        ? ' (Saved to audio file)'
        : (writeResult.isPermissionDenied
            ? ' (App storage only — grant storage access for file write)'
            : '');

    state = state.copyWith(
      tracks: updatedList,
      statusMessage: 'Updated tags for "${updated.title}"$statusSuffix.',
    );
    return updated;
  }

  /// Save updated metadata tags for multiple tracks (batch processing)
  Future<BatchTaggingResult> updateBatchTracksTags(
    List<BatchTaggingItem> items, {
    void Function(int current, int total, String currentFile)? onProgress,
  }) async {
    state = state.copyWith(isScanning: true, statusMessage: 'Writing metadata tags...');
    try {
      final result = await _tagger.writeBatchTags(items, onProgress: onProgress);

      final updatedMap = {for (final t in result.updatedTracks) t.id: t};
      final updatedList = state.tracks.map((t) {
        return updatedMap[t.id] ?? t;
      }).toList();

      await _persistTracks(updatedList);
      BackupRestoreService.instance.scheduleAutoBackup();
      state = state.copyWith(
        tracks: updatedList,
        isScanning: false,
        statusMessage: 'Updated metadata for ${result.successCount} of ${result.totalCount} tracks.',
      );
      return result;
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        statusMessage: 'Batch tag update notice: $e',
      );
      rethrow;
    }
  }

  /// Remove a music source folder and purge its tracks from local library
  Future<void> removeMusicFolder(String folderPath) async {
    final currentFolders = LocalPersistenceService.instance.getMusicFolders();
    final updatedFolders = currentFolders.where((f) => f != folderPath).toList();
    await LocalPersistenceService.instance.saveMusicFolders(updatedFolders);

    // Filter out tracks that reside within the removed folder
    final remainingTracks = state.tracks.where((t) {
      if (t.filePath == null) return true; // keep cloud tracks
      return !t.filePath!.startsWith(folderPath);
    }).toList();

    await _persistTracks(remainingTracks);

    final folderName = folderPath.split(Platform.pathSeparator).last;
    state = state.copyWith(
      tracks: remainingTracks,
      statusMessage: 'Removed folder "$folderName" from library sources.',
    );
  }

  /// Delete a custom playlist with optional removal of exclusive online tracks
  void deletePlaylist(String playlistId, {bool removeOnlineTracks = false}) {
    final playlistIndex = state.customPlaylists.indexWhere((p) => p.id == playlistId);
    if (playlistIndex < 0) return;
    final targetPlaylist = state.customPlaylists[playlistIndex];

    final updatedPlaylists = state.customPlaylists.where((p) => p.id != playlistId).toList();
    _persistCustomPlaylists(updatedPlaylists);

    List<Track> updatedTracks = state.tracks;
    int removedCount = 0;

    if (removeOnlineTracks && targetPlaylist.tracks.isNotEmpty) {
      // Find candidate online tracks from the deleted playlist
      final candidateOnlineTrackIds = targetPlaylist.tracks
          .where((t) => t.isRemote)
          .map((t) => t.id)
          .toSet();

      // Find tracks that MUST be preserved:
      // 1. In user's favorites
      // 2. In any other custom playlists
      final preservedTrackIds = <String>{
        ...state.favoriteTrackIds,
        for (final p in updatedPlaylists) ...p.tracks.map((t) => t.id),
      };

      final trackIdsToRemove = candidateOnlineTrackIds.difference(preservedTrackIds);

      if (trackIdsToRemove.isNotEmpty) {
        // Purge audio cache for removed tracks in background
        for (final id in trackIdsToRemove) {
          AudioCacheService.instance.deleteCachedTrack(id).ignore();
        }

        updatedTracks = state.tracks
            .where((t) => !trackIdsToRemove.contains(t.id))
            .toList();
        _persistTracks(updatedTracks);
        removedCount = trackIdsToRemove.length;
      }
    }

    state = state.copyWith(
      customPlaylists: updatedPlaylists,
      tracks: updatedTracks,
      statusMessage: removedCount > 0
          ? 'Playlist deleted and $removedCount online track${removedCount == 1 ? '' : 's'} removed from library.'
          : 'Playlist deleted.',
    );
  }

  /// Removes a track from library, custom playlists, and purges cached audio if remote
  void removeTrackFromLibrary(String trackId) {
    final trackIndex = state.tracks.indexWhere((t) => t.id == trackId);
    if (trackIndex < 0) return;
    final track = state.tracks[trackIndex];

    final updatedTracks = state.tracks.where((t) => t.id != trackId).toList();
    _persistTracks(updatedTracks);

    // Also remove from any custom playlists
    final updatedPlaylists = state.customPlaylists.map((p) {
      if (p.tracks.any((t) => t.id == trackId)) {
        return p.copyWith(tracks: p.tracks.where((t) => t.id != trackId).toList());
      }
      return p;
    }).toList();
    _persistCustomPlaylists(updatedPlaylists);

    // Also remove from favorites if present
    Set<String> updatedFavorites = state.favoriteTrackIds;
    if (state.favoriteTrackIds.contains(trackId)) {
      updatedFavorites = Set<String>.from(state.favoriteTrackIds)..remove(trackId);
      LocalPersistenceService.instance.saveFavoriteTrackIds(updatedFavorites);
    }

    // Purge cached audio if remote
    if (track.isRemote) {
      AudioCacheService.instance.deleteCachedTrack(trackId).ignore();
    }

    state = state.copyWith(
      tracks: updatedTracks,
      customPlaylists: updatedPlaylists,
      favoriteTrackIds: updatedFavorites,
      statusMessage: 'Removed "${track.title}" from library.',
    );
  }

  /// Batch remove multiple tracks from library, custom playlists, and cache
  void removeTracksBatch(Iterable<String> trackIds) {
    final idSet = trackIds.toSet();
    if (idSet.isEmpty) return;

    final tracksToRemove = state.tracks.where((t) => idSet.contains(t.id)).toList();
    if (tracksToRemove.isEmpty) return;

    final updatedTracks = state.tracks.where((t) => !idSet.contains(t.id)).toList();
    _persistTracks(updatedTracks);

    final updatedPlaylists = state.customPlaylists.map((p) {
      if (p.tracks.any((t) => idSet.contains(t.id))) {
        return p.copyWith(tracks: p.tracks.where((t) => !idSet.contains(t.id)).toList());
      }
      return p;
    }).toList();
    _persistCustomPlaylists(updatedPlaylists);

    Set<String> updatedFavorites = state.favoriteTrackIds;
    final favsToRemove = state.favoriteTrackIds.intersection(idSet);
    if (favsToRemove.isNotEmpty) {
      updatedFavorites = Set<String>.from(state.favoriteTrackIds)..removeAll(favsToRemove);
      LocalPersistenceService.instance.saveFavoriteTrackIds(updatedFavorites);
    }

    for (final track in tracksToRemove) {
      if (track.isRemote) {
        AudioCacheService.instance.deleteCachedTrack(track.id).ignore();
      }
    }

    final count = tracksToRemove.length;
    state = state.copyWith(
      tracks: updatedTracks,
      customPlaylists: updatedPlaylists,
      favoriteTrackIds: updatedFavorites,
      statusMessage: 'Removed $count track${count == 1 ? '' : 's'} from library.',
    );
  }

  /// Removes a track from a specific custom playlist without removing it from library
  void removeTrackFromPlaylist(String playlistId, String trackId) {
    String? trackTitle;
    final updated = state.customPlaylists.map((p) {
      if (p.id == playlistId) {
        final found = p.tracks.where((t) => t.id == trackId).firstOrNull;
        if (found != null) trackTitle = found.title;
        return p.copyWith(tracks: p.tracks.where((t) => t.id != trackId).toList());
      }
      return p;
    }).toList();

    _persistCustomPlaylists(updated);
    state = state.copyWith(
      customPlaylists: updated,
      statusMessage: trackTitle != null
          ? 'Removed "$trackTitle" from playlist.'
          : 'Track removed from playlist.',
    );
  }

  /// Rename and update description for a custom playlist
  void renamePlaylist(String playlistId, String newName, {String? newDescription}) {
    final updated = state.customPlaylists.map((p) {
      if (p.id == playlistId) {
        return p.copyWith(
          name: newName,
          description: newDescription ?? p.description,
        );
      }
      return p;
    }).toList();
    _persistCustomPlaylists(updated);
    state = state.copyWith(
      customPlaylists: updated,
      statusMessage: 'Playlist "$newName" updated.',
    );
  }

  /// Duplicate a custom playlist
  void duplicatePlaylist(String playlistId) {
    final index = state.customPlaylists.indexWhere((p) => p.id == playlistId);
    if (index < 0) return;
    final original = state.customPlaylists[index];
    final copy = original.copyWith(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: '${original.name} (Copy)',
      tracks: List.from(original.tracks),
      createdAt: DateTime.now(),
    );
    final updated = [...state.customPlaylists, copy];
    _persistCustomPlaylists(updated);
    state = state.copyWith(
      customPlaylists: updated,
      statusMessage: 'Playlist "${original.name}" duplicated.',
    );
  }

  Future<void> _persistCustomPlaylists(List<PlaylistModel> list) async {
    try {
      final maps = list.map((p) => p.toMap()).toList();
      await LocalPersistenceService.instance.saveCustomPlaylists(maps);
    } catch (e) {
      debugPrint('[UnifiedLibraryController] Error persisting custom playlists: $e');
    }
  }

  // ─── SMART PLAYLISTS METHODS ───────────────────────────────────────────────

  /// Save (create or update) a dynamic smart playlist
  void saveSmartPlaylist(SmartPlaylist smartPlaylist) {
    final existingIndex = state.smartPlaylists.indexWhere((p) => p.id == smartPlaylist.id);
    final updated = List<SmartPlaylist>.from(state.smartPlaylists);
    if (existingIndex >= 0) {
      updated[existingIndex] = smartPlaylist;
    } else {
      updated.add(smartPlaylist);
    }
    _persistSmartPlaylists(updated);
    state = state.copyWith(
      smartPlaylists: updated,
      statusMessage: 'Smart playlist "${smartPlaylist.name}" saved.',
    );
  }

  /// Delete a smart playlist by ID
  void deleteSmartPlaylist(String id) {
    final updated = state.smartPlaylists.where((p) => p.id != id).toList();
    _persistSmartPlaylists(updated);
    state = state.copyWith(
      smartPlaylists: updated,
      statusMessage: 'Smart playlist deleted.',
    );
  }

  /// Duplicate an existing smart playlist
  void duplicateSmartPlaylist(String id) {
    final index = state.smartPlaylists.indexWhere((p) => p.id == id);
    if (index < 0) return;
    final original = state.smartPlaylists[index];
    final copy = original.copyWith(
      id: 'smart_${DateTime.now().millisecondsSinceEpoch}',
      name: '${original.name} (Copy)',
      createdAt: DateTime.now(),
      isPreset: false,
    );
    final updated = [...state.smartPlaylists, copy];
    _persistSmartPlaylists(updated);
    state = state.copyWith(
      smartPlaylists: updated,
      statusMessage: 'Duplicated "${original.name}".',
    );
  }

  /// Reset smart playlists to factory default presets
  void resetSmartPlaylistsToPresets() {
    final presets = SmartPlaylistEvaluator.defaultPresets;
    _persistSmartPlaylists(presets);
    state = state.copyWith(
      smartPlaylists: presets,
      statusMessage: 'Smart playlists reset to factory presets.',
    );
  }

  Future<void> _persistSmartPlaylists(List<SmartPlaylist> list) async {
    try {
      final maps = list.map((p) => p.toMap()).toList();
      await LocalPersistenceService.instance.saveSmartPlaylists(maps);
    } catch (e) {
      debugPrint('[UnifiedLibraryController] Error persisting smart playlists: $e');
    }
  }
}

