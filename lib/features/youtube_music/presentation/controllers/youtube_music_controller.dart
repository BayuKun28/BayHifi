import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../player/domain/track.dart';
import '../../../player/presentation/controllers/player_controller.dart';
import '../../data/youtube_music_service.dart';

@immutable
class YouTubeMusicState {
  final String query;
  final List<Track> searchResults;
  final List<Track> trendingTracks;
  final bool isSearching;
  final bool isLoadingTrending;
  final String? errorMessage;

  const YouTubeMusicState({
    this.query = '',
    this.searchResults = const [],
    this.trendingTracks = const [],
    this.isSearching = false,
    this.isLoadingTrending = false,
    this.errorMessage,
  });

  YouTubeMusicState copyWith({
    String? query,
    List<Track>? searchResults,
    List<Track>? trendingTracks,
    bool? isSearching,
    bool? isLoadingTrending,
    String? errorMessage,
  }) {
    return YouTubeMusicState(
      query: query ?? this.query,
      searchResults: searchResults ?? this.searchResults,
      trendingTracks: trendingTracks ?? this.trendingTracks,
      isSearching: isSearching ?? this.isSearching,
      isLoadingTrending: isLoadingTrending ?? this.isLoadingTrending,
      errorMessage: errorMessage,
    );
  }
}

final youtubeMusicControllerProvider =
    StateNotifierProvider<YouTubeMusicController, YouTubeMusicState>((ref) {
  return YouTubeMusicController(ref);
});

class YouTubeMusicController extends StateNotifier<YouTubeMusicState> {
  final Ref _ref;
  Timer? _debounceTimer;

  YouTubeMusicController(this._ref) : super(const YouTubeMusicState()) {
    fetchTrending();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  /// Sets search query with debounce
  void onQueryChanged(String newQuery) {
    state = state.copyWith(query: newQuery);
    _debounceTimer?.cancel();

    if (newQuery.trim().isEmpty) {
      state = state.copyWith(searchResults: [], isSearching: false);
      return;
    }

    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      search(newQuery);
    });
  }

  /// Executes search on YouTube Music
  Future<void> search(String query) async {
    if (query.trim().isEmpty) return;

    state = state.copyWith(isSearching: true, errorMessage: null);

    try {
      final results = await YouTubeMusicService.instance.search(query);
      state = state.copyWith(
        searchResults: results,
        isSearching: false,
      );
    } catch (e) {
      state = state.copyWith(
        isSearching: false,
        errorMessage: 'Failed to search YouTube Music: $e',
      );
    }
  }

  /// Fetches top trending tracks
  Future<void> fetchTrending({bool force = false}) async {
    if (state.trendingTracks.isNotEmpty && !force) return;

    state = state.copyWith(
      isLoadingTrending: true,
      errorMessage: null,
      trendingTracks: force ? [] : state.trendingTracks,
    );
    try {
      final trending = await YouTubeMusicService.instance.getTrendingMusic();
      state = state.copyWith(
        trendingTracks: trending,
        isLoadingTrending: false,
        errorMessage: trending.isEmpty ? 'Unable to load charts. Tap refresh to try again.' : null,
      );
    } catch (e) {
      state = state.copyWith(
        isLoadingTrending: false,
        errorMessage: 'Failed to load global charts: $e',
      );
    }
  }

  /// Starts smart algorithmic radio from a track
  Future<void> startRadio(Track track) async {
    try {
      final related = await YouTubeMusicService.instance.getRelatedTracks(track.id);
      final queue = [track, ...related.where((t) => t.id != track.id)];

      await _ref.read(playerControllerProvider.notifier).setQueue(queue, initialIndex: 0);
    } catch (e) {
      debugPrint('[YouTubeMusicController] Start radio error: $e');
      await _ref.read(playerControllerProvider.notifier).playTrack(track);
    }
  }

  /// Imports a YouTube playlist from URL/ID and returns tracks
  Future<List<Track>> importPlaylist(String urlOrId) async {
    state = state.copyWith(isSearching: true);
    try {
      final tracks = await YouTubeMusicService.instance.getPlaylistTracks(urlOrId);
      state = state.copyWith(isSearching: false);
      return tracks;
    } catch (e) {
      state = state.copyWith(
        isSearching: false,
        errorMessage: 'Failed to import playlist: $e',
      );
      return [];
    }
  }
}
