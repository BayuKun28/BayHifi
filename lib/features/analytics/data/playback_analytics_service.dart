import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../audio_engine/virtual_dsp_service.dart';
import '../../../core/database/local_persistence_service.dart';
import '../../hardware_dac/presentation/controllers/dac_bridge_controller.dart';
import '../../library/presentation/controllers/library_controller.dart';
import '../../player/domain/track.dart';
import '../../pro_q_studio/presentation/controllers/eq_controller.dart';
import '../domain/playback_log_entry.dart';
import '../domain/studio_wrapped_calculator.dart';
import '../domain/studio_wrapped_data.dart';

final playbackAnalyticsServiceProvider = Provider<PlaybackAnalyticsService>((ref) {
  return PlaybackAnalyticsService(ref);
});

final studioWrappedFilterProvider = StateProvider<RecapTimeFilter>((ref) {
  return RecapTimeFilter.year2026;
});

final studioWrappedDataProvider = Provider<StudioWrappedData>((ref) {
  final service = ref.watch(playbackAnalyticsServiceProvider);
  final timeFilter = ref.watch(studioWrappedFilterProvider);
  return service.getWrappedSummary(timeFilter: timeFilter);
});

class PlaybackAnalyticsService {
  final Ref _ref;

  PlaybackAnalyticsService(this._ref);

  /// Logs a qualified playback session into LocalPersistenceService
  Future<void> logPlaySession({
    required Track track,
    required Duration durationPlayed,
  }) async {
    // Only log if played at least 30 seconds or at least half of the song
    if (durationPlayed.inSeconds < 30 && durationPlayed < (track.duration * 0.5)) {
      return;
    }

    try {
      final eqState = _ref.read(eqControllerProvider);
      final dacState = _ref.read(dacBridgeControllerProvider);
      final dspService = VirtualDspService.instance;

      int activeDsp = 0;
      if (dspService.tubeEnabled) activeDsp++;
      if (dspService.bassBoostEnabled) activeDsp++;
      if (dspService.compressorEnabled) activeDsp++;
      if (dspService.stereoWidthEnabled) activeDsp++;
      if (dspService.crossfeedEnabled) activeDsp++;
      if (dspService.reverbEnabled) activeDsp++;
      if (dspService.pitchShiftEnabled) activeDsp++;
      if (dspService.limiterEnabled) activeDsp++;

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
        driverName: eqState.driverFr?.name,
        targetName: eqState.targetFr?.name,
        isAutoEqActive: eqState.isAutoEqActive,
        activeDspCount: activeDsp,
        dacDeviceName: dacState.isConnected ? dacState.device?.productName : null,
        artworkUrl: track.albumArtUrl,
      );

      await LocalPersistenceService.instance.logPlaybackSession(log.toMap());
    } catch (e) {
      debugPrint('[PlaybackAnalyticsService] Failed to log session: $e');
    }
  }

  /// Calculates and returns the Studio Wrapped data
  StudioWrappedData getWrappedSummary({
    RecapTimeFilter timeFilter = RecapTimeFilter.year2026,
  }) {
    final rawList = LocalPersistenceService.instance.getPlaybackHistoryLogs();
    final logs = rawList.map(PlaybackLogEntry.fromMap).toList();
    List<Track>? libraryTracks;
    try {
      libraryTracks = _ref.read(unifiedLibraryProvider).tracks;
    } catch (_) {}

    const calculator = StudioWrappedCalculator();
    return calculator.calculate(
      rawLogs: logs,
      timeFilter: timeFilter,
      libraryFallback: libraryTracks,
    );
  }
}
