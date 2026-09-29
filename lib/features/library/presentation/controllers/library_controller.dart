import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../player/domain/track.dart';
import '../../../navidrome/data/subsonic_client.dart';
import '../../../navidrome/domain/subsonic_models.dart';
import '../../../../core/database/local_persistence_service.dart';
import '../../data/local_audio_scanner.dart';
import '../../data/metadata_tagger_service.dart';
import '../../domain/library_collection_models.dart';
import '../../domain/smart_playlist_models.dart';
import '../../domain/smart_playlist_evaluator.dart';

enum LibrarySourceFilter { all, offline, navidrome, hiRes }

@immutable
class UnifiedLibraryState {
  const UnifiedLibraryState({
    this.tracks = const [],
    this.selectedFilter = LibrarySourceFilter.all,
    this.currentTab = CollectionTab.tracks,
    this.sortField = SortField.title,
    this.sortDirection = SortDirection.ascending,
    this.layoutMode = ViewLayoutMode.list,
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

  /// Daftar lagu yang telah difilter dan diurutkan
  List<Track> get filteredTracks {
    final list = tracks.where((t) {
      // 1. Source filter
      final matchesSource = switch (selectedFilter) {
        LibrarySourceFilter.all => true,
        LibrarySourceFilter.offline => t.filePath != null && t.filePath!.isNotEmpty,
        LibrarySourceFilter.navidrome => t.remoteUrl != null && t.remoteUrl!.isNotEmpty,
        LibrarySourceFilter.hiRes => t.isHiRes,
      };

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
    for (final t in filteredTracks) {
      final path = t.filePath ?? 'Navidrome Cloud Library';
      final folderName = path.contains('/')
          ? path.substring(0, path.lastIndexOf('/')).split('/').last
          : 'Root Audio Directory';
      map.putIfAbsent(folderName, () => []).add(t);
    }

    return map.entries.map((e) {
      return FolderModel(path: e.key, name: e.key, tracks: e.value);
    }).toList();
  }

  List<String> get configuredFolderPaths =>
      LocalPersistenceService.instance.getMusicFolders();

  int get totalTracksCount => tracks.length;
  int get offlineTracksCount =>
      tracks.where((t) => t.filePath != null && t.filePath!.isNotEmpty).length;
  int get navidromeTracksCount =>
      tracks.where((t) => t.remoteUrl != null && t.remoteUrl!.isNotEmpty).length;
  int get hiResTracksCount => tracks.where((t) => t.isHiRes).length;

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

final unifiedLibraryProvider =
    StateNotifierProvider<UnifiedLibraryController, UnifiedLibraryState>((ref) {
  return UnifiedLibraryController();
});

class UnifiedLibraryController extends StateNotifier<UnifiedLibraryState> {
  UnifiedLibraryController({
    LocalAudioScanner? scanner,
    SubsonicClient? subsonicClient,
    MetadataTaggerService? tagger,
    List<Track>? initialTracks,
    List<PlaylistModel>? initialCustomPlaylists,
    List<SmartPlaylist>? initialSmartPlaylists,
  })  : _scanner = scanner ?? const LocalAudioScanner(),
        _subsonicClient = subsonicClient ?? SubsonicClient(),
        _tagger = tagger ?? const MetadataTaggerService(),
        super(UnifiedLibraryState(
          tracks: initialTracks ?? _loadSavedTracks(),
          customPlaylists: initialCustomPlaylists ?? const [],
          smartPlaylists: initialSmartPlaylists ?? _loadSavedSmartPlaylists(),
          favoriteTrackIds: LocalPersistenceService.instance.getFavoriteTrackIds().toSet(),
        )) {
    // Non-blocking differential startup sync for newly added tracks, missing artwork, and Navidrome session
    Future.microtask(() async {
      await syncNewTracksOnStartup();
      await recoverMissingArtwork();
      await restoreNavidromeSession();
    });
  }

  final LocalAudioScanner _scanner;
  final SubsonicClient _subsonicClient;
  final MetadataTaggerService _tagger;

  LocalAudioScanner get scanner => _scanner;
  SubsonicClient get subsonicClient => _subsonicClient;
  MetadataTaggerService get tagger => _tagger;

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
    final smartPlaylists = _loadSavedSmartPlaylists();
    final favIds = LocalPersistenceService.instance.getFavoriteTrackIds().toSet();
    state = state.copyWith(
      tracks: tracks,
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
    state = state.copyWith(selectedFilter: filter);
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
    state = state.copyWith(
      customPlaylists: [...state.customPlaylists, newPlaylist],
      statusMessage: 'Playlist "$name" successfully created.',
    );
  }

  void addTrackToPlaylist(String playlistId, Track track) {
    final updated = state.customPlaylists.map((p) {
      if (p.id == playlistId) {
        if (p.tracks.any((t) => t.id == track.id)) return p;
        return PlaylistModel(
          id: p.id,
          name: p.name,
          description: p.description,
          tracks: [...p.tracks, track],
          isCustom: p.isCustom,
          createdAt: p.createdAt,
        );
      }
      return p;
    }).toList();

    state = state.copyWith(
      customPlaylists: updated,
      statusMessage: 'Track added to playlist.',
    );
  }

  /// Check and request storage & notification permissions (Android audio & external storage access)
  Future<bool> ensureStoragePermissions() async {
    if (kIsWeb || !Platform.isAndroid) return true;
    try {
      // Request notification permission for Android 13+ (API 33+) media status bar playback
      try {
        await Permission.notification.request();
      } catch (_) {}

      final manageStatus = await Permission.manageExternalStorage.status;
      if (!manageStatus.isGranted) {
        final res = await Permission.manageExternalStorage.request();
        if (res.isGranted) return true;
      } else {
        return true;
      }

      final audio = await Permission.audio.request();
      final storage = await Permission.storage.request();
      return audio.isGranted || storage.isGranted || manageStatus.isGranted;
    } catch (e) {
      debugPrint('[UnifiedLibraryController] Permission plugin not yet bound (requires full app restart): $e');
      return true;
    }
  }

  Future<bool> _checkManageStorageGranted() async {
    try {
      return await Permission.manageExternalStorage.isGranted;
    } catch (_) {
      return false;
    }
  }

  /// Open directory picker to select and scan user's custom music folder
  Future<void> pickAndScanDirectory() async {
    try {
      await ensureStoragePermissions();

      final selectedDirectory = await FilePicker.getDirectoryPath(
        dialogTitle: 'Select Music Folder to Scan',
      );

      if (selectedDirectory == null || selectedDirectory.isEmpty) {
        return;
      }

      state = state.copyWith(
        isScanning: true,
        statusMessage: 'Scanning audio folder...',
      );

      // Save folder to persisted music folders list
      final currentFolders = LocalPersistenceService.instance.getMusicFolders();
      if (!currentFolders.contains(selectedDirectory)) {
        final updatedFolders = [...currentFolders, selectedDirectory];
        await LocalPersistenceService.instance.saveMusicFolders(updatedFolders);
      }

      final existingMap = <String, Track>{
        for (final t in state.tracks)
          if (t.filePath != null && t.filePath!.isNotEmpty) t.filePath!: t,
      };

      final scanned = await _scanner.scanDirectory(
        Directory(selectedDirectory),
        existingTracksByPath: existingMap,
        onProgress: (count, folder) {
          state = state.copyWith(
            statusMessage: 'Scanning: $folder ($count tracks found)...',
          );
        },
      );

      // Merge scanned tracks with existing tracks (avoiding duplicate filePath)
      final existingTrackPaths = state.tracks.map((t) => t.filePath).whereType<String>().toSet();
      final newTracks = scanned
          .where((t) => t.filePath == null || !existingTrackPaths.contains(t.filePath))
          .toList();

      final updatedList = [...state.tracks, ...newTracks];
      await _persistTracks(updatedList);

      final folderName = selectedDirectory.split(Platform.pathSeparator).last;
      final isExternalSd = selectedDirectory.startsWith('/storage/') &&
          !selectedDirectory.startsWith('/storage/emulated/0');

      String statusMsg;
      if (newTracks.isNotEmpty) {
        statusMsg = 'Added ${newTracks.length} tracks from $folderName.';
      } else if (scanned.isEmpty) {
        final hasManagePermission = await _checkManageStorageGranted();
        if (isExternalSd && !hasManagePermission) {
          statusMsg = 'No files found in $folderName. Please grant "All files access" in Android Settings for SD card access.';
        } else {
          statusMsg = 'No audio files found in $folderName (FLAC, WAV, MP3, OPUS, OGG, M4A, DSD).';
        }
      } else {
        statusMsg = 'All ${scanned.length} tracks in $folderName are already in your library.';
      }

      state = state.copyWith(
        tracks: updatedList,
        isScanning: false,
        selectedFilter: LibrarySourceFilter.all,
        searchQuery: '',
        isSearching: false,
        statusMessage: statusMsg,
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
      final pickedFiles = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const [
          'flac',
          'wav',
          'mp3',
          'opus',
          'ogg',
          'alac',
          'dsf',
          'dff',
          'm4a',
          'aac',
          'aiff',
          'aif',
          'wma',
          'ape',
          'mp4',
          'webm'
        ],
      );

      if (pickedFiles.isEmpty) {
        return;
      }

      state = state.copyWith(
        isScanning: true,
        statusMessage: 'Importing selected audio files...',
      );

      final files = pickedFiles
          .map((f) => f.path)
          .whereType<String>()
          .where((p) => p.isNotEmpty)
          .map((p) => File(p))
          .toList();

      final parsed = await _scanner.parseFiles(files);

      final existingTrackPaths = state.tracks.map((t) => t.filePath).whereType<String>().toSet();
      final newTracks = parsed
          .where((t) => t.filePath == null || !existingTrackPaths.contains(t.filePath))
          .toList();

      final updatedList = [...state.tracks, ...newTracks];
      await _persistTracks(updatedList);

      state = state.copyWith(
        tracks: updatedList,
        isScanning: false,
        selectedFilter: LibrarySourceFilter.all,
        searchQuery: '',
        isSearching: false,
        statusMessage: newTracks.isNotEmpty
            ? 'Added ${newTracks.length} audio files to library.'
            : (parsed.isEmpty
                ? 'Could not parse selected audio files.'
                : 'Selected files are already in your library.'),
      );
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        statusMessage: 'Failed to import audio files: $e',
      );
    }
  }

  /// Rescan all previously configured music folders
  Future<void> rescanSavedFolders() async {
    final savedFolders = LocalPersistenceService.instance.getMusicFolders();
    if (savedFolders.isEmpty) {
      await pickAndScanDirectory();
      return;
    }

    await ensureStoragePermissions();

    state = state.copyWith(
      isScanning: true,
      statusMessage: 'Rescanning ${savedFolders.length} music folders...',
    );

    try {
      final existingMap = <String, Track>{
        for (final t in state.tracks)
          if (t.filePath != null && t.filePath!.isNotEmpty) t.filePath!: t,
      };

      final scanned = await _scanner.scanPaths(
        savedFolders,
        existingTracksByPath: existingMap,
        onProgress: (count, path) {
          state = state.copyWith(
            statusMessage: 'Scanning $path ($count tracks found)...',
          );
        },
      );

      // Keep any remote Navidrome tracks
      final existingCloud = state.tracks.where((t) => t.remoteUrl != null).toList();
      final combined = [...scanned, ...existingCloud];

      await _persistTracks(combined);

      state = state.copyWith(
        tracks: combined,
        isScanning: false,
        selectedFilter: LibrarySourceFilter.all,
        searchQuery: '',
        isSearching: false,
        statusMessage: 'Rescan complete. Found ${scanned.length} local audio tracks.',
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
    final savedFolders = LocalPersistenceService.instance.getMusicFolders();
    if (savedFolders.isNotEmpty) {
      await rescanSavedFolders();
    } else {
      await pickAndScanDirectory();
    }
  }

  /// Silent background sync on startup: only parses new or modified files
  Future<void> syncNewTracksOnStartup() async {
    final autoScan = LocalPersistenceService.instance.getSetting<bool>('auto_scan_on_startup', true) ?? true;
    if (!autoScan) return;

    final savedFolders = LocalPersistenceService.instance.getMusicFolders();
    if (savedFolders.isEmpty) return;

    try {
      final existingMap = <String, Track>{
        for (final t in state.tracks)
          if (t.filePath != null && t.filePath!.isNotEmpty) t.filePath!: t,
      };

      final scanned = await _scanner.scanPaths(
        savedFolders,
        existingTracksByPath: existingMap,
      );

      if (scanned.isEmpty && state.tracks.isNotEmpty) return;

      final existingPaths = state.tracks.map((t) => t.filePath).whereType<String>().toSet();
      final scannedPaths = scanned.map((t) => t.filePath).whereType<String>().toSet();

      final hasChanges = scanned.length != state.tracks.where((t) => t.filePath != null).length ||
          !setEquals(existingPaths, scannedPaths);

      if (hasChanges) {
        final existingCloud = state.tracks.where((t) => t.remoteUrl != null).toList();
        final combined = [...scanned, ...existingCloud];
        await _persistTracks(combined);
        state = state.copyWith(tracks: combined);
      }
    } catch (e) {
      debugPrint('[UnifiedLibraryController] Background startup sync notice: $e');
    }
  }

  /// Memulihkan album artwork yang hilang di latar belakang
  Future<void> recoverMissingArtwork() async {
    final needsRecovery = state.tracks.where(
      (t) => (t.albumArtBytes == null || t.albumArtBytes!.isEmpty) &&
             (t.albumArtUrl == null || t.albumArtUrl!.isEmpty) &&
             t.filePath != null && t.filePath!.isNotEmpty,
    ).toList();

    if (needsRecovery.isEmpty) return;

    bool hasAnyUpdated = false;
    final updatedList = List<Track>.from(state.tracks);

    for (int i = 0; i < updatedList.length; i++) {
      final t = updatedList[i];
      if ((t.albumArtBytes == null || t.albumArtBytes!.isEmpty) &&
          (t.albumArtUrl == null || t.albumArtUrl!.isEmpty) &&
          t.filePath != null && t.filePath!.isNotEmpty) {
        final updated = await LocalAudioScanner.extractAndCacheCoverArt(t);
        if (updated.albumArtUrl != null || updated.albumArtBytes != null) {
          updatedList[i] = updated;
          hasAnyUpdated = true;
        }
      }
    }

    if (hasAnyUpdated) {
      await _persistTracks(updatedList);
      state = state.copyWith(tracks: updatedList);
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
      final isOnline = await _subsonicClient.ping(config);

      if (isOnline) {
        state = state.copyWith(
          isConnectingNavidrome: false,
          navidromeConnectionStatus: NavidromeConnectionStatus.connected,
          navidromeConfig: config,
          statusMessage: isSilent ? null : 'Connected to Navidrome server.',
          clearStatusMessage: isSilent,
        );

        await LocalPersistenceService.instance.saveSetting('navidrome_config', config.toMap());
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
    try {
      final configMap = LocalPersistenceService.instance.getSetting<Map<String, dynamic>>('navidrome_config');
      if (configMap != null) {
        final config = SubsonicServerConfig.fromMap(configMap);
        if (config.serverUrl.isNotEmpty && config.username.isNotEmpty) {
          await connectNavidrome(config, isSilent: isSilent);
        }
      }
    } catch (e) {
      debugPrint('[UnifiedLibraryController] Error restoring Navidrome session: $e');
      state = state.copyWith(
        statusMessage: 'Failed to restore Navidrome session: $e',
      );
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
      final songs = await _subsonicClient.fetchAllSongs(config);
      final cloudTracks = songs.map((s) => s.toTrack(config)).toList();

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
    LocalPersistenceService.instance.removeSetting('navidrome_config');
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

    if (writeToFile && original.filePath != null && original.filePath!.isNotEmpty) {
      await _tagger.writePhysicalTags(original.filePath!, tagData);
    }

    final updated = tagData.applyToTrack(original, newAlbumArtUrl: cachedArtPath);
    final updatedList = List<Track>.from(state.tracks);
    updatedList[idx] = updated;

    await _persistTracks(updatedList);
    state = state.copyWith(
      tracks: updatedList,
      statusMessage: 'Updated tags for "${updated.title}".',
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

  /// Delete a custom playlist
  void deletePlaylist(String playlistId) {
    final updated = state.customPlaylists.where((p) => p.id != playlistId).toList();
    state = state.copyWith(
      customPlaylists: updated,
      statusMessage: 'Playlist deleted.',
    );
  }

  /// Rename and update description for a custom playlist
  void renamePlaylist(String playlistId, String newName, {String? newDescription}) {
    final updated = state.customPlaylists.map((p) {
      if (p.id == playlistId) {
        return PlaylistModel(
          id: p.id,
          name: newName,
          description: newDescription ?? p.description,
          tracks: p.tracks,
          isCustom: true,
          createdAt: p.createdAt,
        );
      }
      return p;
    }).toList();
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
    final copy = PlaylistModel(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: '${original.name} (Copy)',
      description: original.description,
      tracks: List.from(original.tracks),
      isCustom: true,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      customPlaylists: [...state.customPlaylists, copy],
      statusMessage: 'Playlist "${original.name}" duplicated.',
    );
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

