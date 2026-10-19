import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../audio_engine/virtual_dsp_service.dart';
import '../../../core/database/local_persistence_service.dart';
import '../../library/presentation/controllers/library_controller.dart';
import '../../player/domain/track.dart';
import '../domain/playback_log_entry.dart';
import '../domain/studio_wrapped_calculator.dart';
import '../domain/studio_wrapped_data.dart';

final playbackAnalyticsServiceProvider = Provider<PlaybackAnalyticsService>((ref) {
  return PlaybackAnalyticsService(ref);
});

final studioWrappedFilterProvider = StateProvider<RecapTimeFilter>((ref) {
  return RecapTimeFilter.year2026;
});

final analyticsRevisionProvider = StateProvider<int>((ref) {
  return 0;
});

final studioWrappedDataProvider = Provider<StudioWrappedData>((ref) {
  final service = ref.watch(playbackAnalyticsServiceProvider);
  final timeFilter = ref.watch(studioWrappedFilterProvider);
  ref.watch(analyticsRevisionProvider);
  return service.getWrappedSummary(timeFilter: timeFilter);
});

class PlaybackAnalyticsService {
  final Ref _ref;

  PlaybackAnalyticsService(this._ref);

  /// Logs a qualified playback session into LocalPersistenceService and triggers reactive UI update
  Future<void> logPlaySession({
    required Track track,
    required Duration durationPlayed,
  }) async {
    // Only log if played at least 30 seconds or at least half of the song
    if (durationPlayed.inSeconds < 30 && durationPlayed < (track.duration * 0.5)) {
      return;
    }

    try {
      String? driverName;
      String? targetName;
      bool isAutoEqActive = false;
      String? dacDeviceName;

      final eqData = LocalPersistenceService.instance.getActiveEqState();
      if (eqData != null) {
        driverName = eqData['lastDriverName'] as String?;
        targetName = eqData['lastTargetName'] as String?;
        isAutoEqActive = eqData['isAutoEqActive'] as bool? ?? false;
      }

      int activeDsp = 0;
      try {
        final dspService = VirtualDspService.instance;
        if (dspService.tubeEnabled) activeDsp++;
        if (dspService.bassBoostEnabled) activeDsp++;
        if (dspService.compressorEnabled) activeDsp++;
        if (dspService.stereoWidthEnabled) activeDsp++;
        if (dspService.crossfeedEnabled) activeDsp++;
        if (dspService.reverbEnabled) activeDsp++;
        if (dspService.pitchShiftEnabled) activeDsp++;
        if (dspService.limiterEnabled) activeDsp++;
      } catch (_) {}

      String? artwork = track.albumArtUrl?.trim();
      if (artwork == null || artwork.isEmpty) {
        try {
          final libTracks = _ref.read(unifiedLibraryProvider).tracks;
          final match = libTracks.firstWhere(
            (t) =>
                t.id == track.id ||
                (t.title.trim().toLowerCase() == track.title.trim().toLowerCase() &&
                    t.artist.trim().toLowerCase() == track.artist.trim().toLowerCase()),
            orElse: () => track,
          );
          if (match.albumArtUrl != null && match.albumArtUrl!.trim().isNotEmpty) {
            artwork = match.albumArtUrl!.trim();
          }
        } catch (_) {}
      }

      final log = PlaybackLogEntry(
        id: 'log_${DateTime.now().millisecondsSinceEpoch}_${track.id}',
        trackId: track.id,
        title: track.title,
        artist: track.artist,
        album: track.album,
        genre: track.genre ?? 'Studio Master',
        durationPlayedMs: durationPlayed.inMilliseconds,
        trackDurationMs: track.duration.inMilliseconds,
        format: track.format.name,
        sampleRate: track.sampleRate ?? 44100,
        bitDepth: track.bitDepth ?? 16,
        timestamp: DateTime.now(),
        driverName: driverName,
        targetName: targetName,
        isAutoEqActive: isAutoEqActive,
        activeDspCount: activeDsp,
        dacDeviceName: dacDeviceName,
        artworkUrl: artwork,
      );

      await LocalPersistenceService.instance.logPlaybackSession(log.toMap());
      _ref.read(analyticsRevisionProvider.notifier).state++;
    } catch (e) {
      debugPrint('[PlaybackAnalyticsService] Failed to log session: $e');
    }
  }

  /// Clears logs and invalidates reactive analytics providers
  Future<void> clearLogs() async {
    await LocalPersistenceService.instance.clearPlaybackHistoryLogs();
    _ref.read(analyticsRevisionProvider.notifier).state++;
  }

  /// Calculates and returns the Studio Wrapped data
  StudioWrappedData getWrappedSummary({
    RecapTimeFilter timeFilter = RecapTimeFilter.year2026,
  }) {
    final rawList = LocalPersistenceService.instance.getPlaybackHistoryLogs();
    final logs = rawList.map(PlaybackLogEntry.fromMap).toList();
    List<Track>? libraryTracks;
    try {
      final inMemory = _ref.read(unifiedLibraryProvider).tracks;
      if (inMemory.isNotEmpty) {
        libraryTracks = inMemory;
      }
    } catch (_) {}

    if (libraryTracks == null || libraryTracks.isEmpty) {
      try {
        final rawSaved = LocalPersistenceService.instance.getSavedLibraryTracks();
        if (rawSaved.isNotEmpty) {
          libraryTracks = rawSaved.map(Track.fromMap).toList();
        }
      } catch (_) {}
    }

    // Lazy asynchronous backfill for past saved logs that had missing artwork URLs
    if (libraryTracks != null && libraryTracks.isNotEmpty) {
      _backfillPersistedLogsIfMissing(rawList, libraryTracks);
    }

    const calculator = StudioWrappedCalculator();
    return calculator.calculate(
      rawLogs: logs,
      timeFilter: timeFilter,
      libraryFallback: libraryTracks,
    );
  }

  void _backfillPersistedLogsIfMissing(
    List<Map<String, dynamic>> rawList,
    List<Track> libraryTracks,
  ) {
    bool hasMissing = false;
    for (final m in rawList) {
      final art = m['artworkUrl'] as String?;
      if (art == null || art.trim().isEmpty) {
        hasMissing = true;
        break;
      }
    }
    if (!hasMissing) return;

    final libById = <String, String>{};
    final libByTitleArtist = <String, String>{};
    for (final t in libraryTracks) {
      if (t.albumArtUrl != null && t.albumArtUrl!.trim().isNotEmpty) {
        final art = t.albumArtUrl!.trim();
        if (t.id.isNotEmpty) libById[t.id] = art;
        final key = '${t.title.trim().toLowerCase()}_${t.artist.trim().toLowerCase()}';
        libByTitleArtist.putIfAbsent(key, () => art);
      }
    }

    bool modified = false;
    for (final map in rawList) {
      final existing = map['artworkUrl'] as String?;
      if (existing == null || existing.trim().isEmpty) {
        final trackId = map['trackId'] as String? ?? '';
        final title = map['title'] as String? ?? '';
        final artist = map['artist'] as String? ?? '';
        String? art = libById[trackId];
        art ??= libByTitleArtist['${title.trim().toLowerCase()}_${artist.trim().toLowerCase()}'];
        if (art == null && trackId.startsWith('yt_')) {
          final vid = trackId.replaceFirst('yt_', '');
          art = 'https://i.ytimg.com/vi/$vid/hqdefault.jpg';
        }
        if (art != null && art.isNotEmpty) {
          map['artworkUrl'] = art;
          modified = true;
        }
      }
    }

    if (modified) {
      // Persist in background without awaiting or blocking UI
      LocalPersistenceService.instance.updatePlaybackHistoryLogs(rawList);
    }
  }
}
