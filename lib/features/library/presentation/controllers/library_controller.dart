import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../player/domain/track.dart';
import '../../../navidrome/data/subsonic_client.dart';
import '../../../navidrome/domain/subsonic_models.dart';
import '../../data/local_audio_scanner.dart';

enum LibrarySourceFilter { all, offline, navidrome, hiRes }

@immutable
class UnifiedLibraryState {
  const UnifiedLibraryState({
    this.tracks = const [],
    this.selectedFilter = LibrarySourceFilter.all,
    this.searchQuery = '',
    this.isScanning = false,
    this.isConnectingNavidrome = false,
    this.navidromeConnectionStatus = NavidromeConnectionStatus.disconnected,
    this.navidromeConfig,
    this.statusMessage,
  });

  final List<Track> tracks;
  final LibrarySourceFilter selectedFilter;
  final String searchQuery;
  final bool isScanning;
  final bool isConnectingNavidrome;
  final NavidromeConnectionStatus navidromeConnectionStatus;
  final SubsonicServerConfig? navidromeConfig;
  final String? statusMessage;

  /// Daftar lagu yang telah difilter berdasarkan sumber dan kata kunci pencarian
  List<Track> get filteredTracks {
    return tracks.where((t) {
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
  }

  int get totalTracksCount => tracks.length;
  int get offlineTracksCount => tracks.where((t) => t.filePath != null && t.filePath!.isNotEmpty).length;
  int get navidromeTracksCount => tracks.where((t) => t.remoteUrl != null && t.remoteUrl!.isNotEmpty).length;
  int get hiResTracksCount => tracks.where((t) => t.isHiRes).length;

  UnifiedLibraryState copyWith({
    List<Track>? tracks,
    LibrarySourceFilter? selectedFilter,
    String? searchQuery,
    bool? isScanning,
    bool? isConnectingNavidrome,
    NavidromeConnectionStatus? navidromeConnectionStatus,
    SubsonicServerConfig? navidromeConfig,
    String? statusMessage,
    bool clearStatusMessage = false,
  }) {
    return UnifiedLibraryState(
      tracks: tracks ?? this.tracks,
      selectedFilter: selectedFilter ?? this.selectedFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      isScanning: isScanning ?? this.isScanning,
      isConnectingNavidrome: isConnectingNavidrome ?? this.isConnectingNavidrome,
      navidromeConnectionStatus: navidromeConnectionStatus ?? this.navidromeConnectionStatus,
      navidromeConfig: navidromeConfig ?? this.navidromeConfig,
      statusMessage: clearStatusMessage ? null : (statusMessage ?? this.statusMessage),
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
  })  : _scanner = scanner ?? const LocalAudioScanner(),
        _subsonicClient = subsonicClient ?? SubsonicClient(),
        super(UnifiedLibraryState(tracks: LocalAudioScanner.defaultLocalTracks));

  final LocalAudioScanner _scanner;
  final SubsonicClient _subsonicClient;

  LocalAudioScanner get scanner => _scanner;
  SubsonicClient get subsonicClient => _subsonicClient;

  void setFilter(LibrarySourceFilter filter) {
    state = state.copyWith(selectedFilter: filter);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  /// Pindai musik lokal
  Future<void> scanLocalMusic() async {
    state = state.copyWith(isScanning: true, statusMessage: 'Memindai musik lokal...');
    try {
      // Gunakan default sample tracks dan gabungkan jika ada file baru
      await Future<void>.delayed(const Duration(milliseconds: 600));
      final localTracks = LocalAudioScanner.defaultLocalTracks;

      // Pertahankan cloud tracks yang sudah ada
      final existingCloud = state.tracks.where((t) => t.remoteUrl != null).toList();
      final combined = [...localTracks, ...existingCloud];

      state = state.copyWith(
        tracks: combined,
        isScanning: false,
        statusMessage: '${localTracks.length} lagu lokal berhasil dimuat.',
      );
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        statusMessage: 'Gagal memindai folder lokal: $e',
      );
    }
  }

  /// Pindai direktori penyimpanan fisik lokal
  Future<void> scanDirectory(dynamic directory) async {
    state = state.copyWith(isScanning: true, statusMessage: 'Memindai folder audio...');
    try {
      final scanned = await _scanner.scanDirectory(directory);
      final existingCloud = state.tracks.where((t) => t.remoteUrl != null).toList();
      final combined = [...scanned, ...existingCloud];
      state = state.copyWith(
        tracks: combined,
        isScanning: false,
        statusMessage: '${scanned.length} file audio lokal ditemukan.',
      );
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        statusMessage: 'Gagal memindai folder lokal: $e',
      );
    }
  }

  /// Hubungkan server Navidrome Subsonic API
  Future<bool> connectNavidrome(SubsonicServerConfig config) async {
    state = state.copyWith(
      isConnectingNavidrome: true,
      navidromeConnectionStatus: NavidromeConnectionStatus.connecting,
      statusMessage: 'Menghubungkan ke ${config.sanitizedUrl}...',
    );

    try {
      final isOnline = await _subsonicClient.ping(config);

      if (isOnline) {
        state = state.copyWith(
          isConnectingNavidrome: false,
          navidromeConnectionStatus: NavidromeConnectionStatus.connected,
          navidromeConfig: config,
          statusMessage: 'Terhubung ke server Navidrome.',
        );

        // Langsung sinkronkan lagu cloud
        await syncNavidromeLibrary();
        return true;
      } else {
        state = state.copyWith(
          isConnectingNavidrome: false,
          navidromeConnectionStatus: NavidromeConnectionStatus.error,
          statusMessage: 'Gagal menghubungi server Navidrome. Periksa URL dan kredensial.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isConnectingNavidrome: false,
        navidromeConnectionStatus: NavidromeConnectionStatus.error,
        statusMessage: 'Error koneksi Navidrome: $e',
      );
      return false;
    }
  }

  /// Sinkronkan katalog lagu dari Navidrome
  Future<void> syncNavidromeLibrary() async {
    final config = state.navidromeConfig;
    if (config == null) return;

    state = state.copyWith(isScanning: true, statusMessage: 'Menyinkronkan pustaka Navidrome...');

    try {
      final songs = await _subsonicClient.getRandomSongs(config, size: 50);
      final cloudTracks = songs.map((s) => s.toTrack(config)).toList();

      // Gabungkan tracks lokal yang sudah ada
      final existingLocal = state.tracks.where((t) => t.filePath != null).toList();
      final combined = [...existingLocal, ...cloudTracks];

      state = state.copyWith(
        tracks: combined,
        isScanning: false,
        statusMessage: '${cloudTracks.length} lagu cloud berhasil disinkronkan.',
      );
    } catch (e) {
      state = state.copyWith(
        isScanning: false,
        statusMessage: 'Gagal sinkronisasi Navidrome: $e',
      );
    }
  }

  /// Putuskan sambungan Navidrome
  void disconnectNavidrome() {
    final existingLocal = state.tracks.where((t) => t.filePath != null).toList();
    state = state.copyWith(
      tracks: existingLocal,
      navidromeConnectionStatus: NavidromeConnectionStatus.disconnected,
      navidromeConfig: null,
      statusMessage: 'Koneksi Navidrome diputus.',
    );
  }
}
