import 'dart:math' as math;
import '../../player/domain/track.dart';
import 'audiophile_persona.dart';
import 'playback_log_entry.dart';
import 'studio_wrapped_data.dart';

class StudioWrappedCalculator {
  const StudioWrappedCalculator();

  StudioWrappedData calculate({
    required List<PlaybackLogEntry> rawLogs,
    RecapTimeFilter timeFilter = RecapTimeFilter.year2026,
    List<Track>? libraryFallback,
  }) {
    final now = DateTime.now();

    // 1. Filter logs based on RecapTimeFilter
    final filteredLogs = rawLogs.where((log) {
      switch (timeFilter) {
        case RecapTimeFilter.year2026:
          return log.timestamp.year == 2026;
        case RecapTimeFilter.last30Days:
          final thirtyDaysAgo = now.subtract(const Duration(days: 30));
          return log.timestamp.isAfter(thirtyDaysAgo);
        case RecapTimeFilter.allTime:
          return true;
      }
    }).toList();

    // 2. If no logs available for the given time range, generate realistic demo recap data
    if (filteredLogs.isEmpty) {
      return _generateSampleWrappedData(timeFilter: timeFilter, libraryTracks: libraryFallback);
    }

    // 3. Compute Top Tracks
    final trackMap = <String, _TrackAggregator>{};
    for (final log in filteredLogs) {
      final key = log.trackId.isNotEmpty ? log.trackId : '${log.title}_${log.artist}';
      final agg = trackMap.putIfAbsent(
        key,
        () => _TrackAggregator(
          trackId: log.trackId,
          title: log.title,
          artist: log.artist,
          album: log.album,
          format: log.format,
          sampleRate: log.sampleRate,
          bitDepth: log.bitDepth,
        ),
      );
      agg.playCount++;
      agg.totalDurationMs += log.durationPlayedMs > 0 ? log.durationPlayedMs : log.trackDurationMs;
    }

    final sortedTracks = trackMap.values.toList()
      ..sort((a, b) => b.totalDurationMs.compareTo(a.totalDurationMs));

    final topTracks = sortedTracks.take(10).toList().asMap().entries.map((e) {
      final agg = e.value;
      return TopTrackRank(
        rank: e.key + 1,
        trackId: agg.trackId,
        title: agg.title,
        artist: agg.artist,
        album: agg.album,
        format: agg.format,
        sampleRate: agg.sampleRate,
        bitDepth: agg.bitDepth,
        playCount: agg.playCount,
        totalMinutes: math.max(1, (agg.totalDurationMs / 60000).round()),
      );
    }).toList();

    // 4. Compute Top Artists
    final artistMap = <String, _ArtistAggregator>{};
    for (final log in filteredLogs) {
      final artistName = log.artist.trim().isNotEmpty ? log.artist.trim() : 'Unknown Artist';
      final agg = artistMap.putIfAbsent(artistName, () => _ArtistAggregator(artist: artistName));
      agg.playCount++;
      agg.totalDurationMs += log.durationPlayedMs > 0 ? log.durationPlayedMs : log.trackDurationMs;
    }

    final totalListeningMs = filteredLogs.fold<int>(
      0,
      (sum, l) => sum + (l.durationPlayedMs > 0 ? l.durationPlayedMs : l.trackDurationMs),
    );
    final totalMinutes = math.max(1, (totalListeningMs / 60000).round());

    final sortedArtists = artistMap.values.toList()
      ..sort((a, b) => b.totalDurationMs.compareTo(a.totalDurationMs));

    final topArtists = sortedArtists.take(5).toList().asMap().entries.map((e) {
      final agg = e.value;
      final pct = totalListeningMs > 0 ? (agg.totalDurationMs / totalListeningMs) * 100 : 0.0;
      return TopArtistRank(
        rank: e.key + 1,
        artist: agg.artist,
        playCount: agg.playCount,
        totalMinutes: math.max(1, (agg.totalDurationMs / 60000).round()),
        percentage: (pct * 10).round() / 10.0,
      );
    }).toList();

    // 5. Compute Genres Breakdown
    final genreMap = <String, int>{};
    for (final log in filteredLogs) {
      final g = log.genre.trim().isNotEmpty ? log.genre.trim() : 'Studio Acoustic';
      genreMap[g] = (genreMap[g] ?? 0) + 1;
    }
    final sortedGenres = genreMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final topGenres = sortedGenres.take(5).map((e) {
      final pct = filteredLogs.isNotEmpty ? (e.value / filteredLogs.length) * 100 : 0.0;
      return GenreBreakdown(
        genre: e.key,
        playCount: e.value,
        percentage: (pct * 10).round() / 10.0,
      );
    }).toList();

    // 6. Compute Audio Purity (Lossless & Hi-Res %)
    int flacCount = 0;
    int hiResCount = 0;
    int standardLosslessCount = 0;
    int lossyCount = 0;
    int totalHiResMs = 0;

    for (final log in filteredLogs) {
      if (log.isLossless) {
        flacCount++;
        if (log.isHiRes) {
          hiResCount++;
          totalHiResMs += log.durationPlayedMs > 0 ? log.durationPlayedMs : log.trackDurationMs;
        } else {
          standardLosslessCount++;
        }
      } else {
        lossyCount++;
      }
    }

    final flacPct = filteredLogs.isNotEmpty ? (flacCount / filteredLogs.length) * 100 : 0.0;
    final hiResPct = filteredLogs.isNotEmpty ? (hiResCount / filteredLogs.length) * 100 : 0.0;

    final purityReport = AudioPurityReport(
      totalTracks: filteredLogs.length,
      flacCount: flacCount,
      hiResCount: hiResCount,
      standardLosslessCount: standardLosslessCount,
      lossyCount: lossyCount,
      flacPercentage: (flacPct * 10).round() / 10.0,
      hiResPercentage: (hiResPct * 10).round() / 10.0,
      totalHiResMinutes: (totalHiResMs / 60000).round(),
    );

    // 7. Compute AutoEQ, DSP & DAC Usage
    final driverCounts = <String, int>{};
    final targetCounts = <String, int>{};
    int autoEqActiveCount = 0;
    int dspActiveCount = 0;
    int dacConnectedCount = 0;
    final dacDeviceNames = <String, int>{};

    for (final log in filteredLogs) {
      if (log.isAutoEqActive && log.driverName != null) {
        autoEqActiveCount++;
        driverCounts[log.driverName!] = (driverCounts[log.driverName!] ?? 0) + 1;
        if (log.targetName != null) {
          targetCounts[log.targetName!] = (targetCounts[log.targetName!] ?? 0) + 1;
        }
      }
      if (log.activeDspCount > 0) {
        dspActiveCount++;
      }
      if (log.dacDeviceName != null && log.dacDeviceName!.isNotEmpty) {
        dacConnectedCount++;
        dacDeviceNames[log.dacDeviceName!] = (dacDeviceNames[log.dacDeviceName!] ?? 0) + 1;
      }
    }

    final favDriver = driverCounts.isNotEmpty
        ? (driverCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key
        : 'KZ CASTOR BLACK DUDU R';
    final favTarget = targetCounts.isNotEmpty
        ? (targetCounts.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key
        : 'HBB Target';
    final favDac = dacDeviceNames.isNotEmpty
        ? (dacDeviceNames.entries.toList()..sort((a, b) => b.value.compareTo(a.value))).first.key
        : null;

    final autoEqHours = math.max(1, (autoEqActiveCount * 4 / 60).round());
    final dspHours = math.max(1, (dspActiveCount * 4 / 60).round());
    final dacHours = math.max(1, (dacConnectedCount * 4 / 60).round());

    // 8. Classify Audiophile Persona
    final persona = _classifyPersona(
      flacPercentage: flacPct,
      hiResPercentage: hiResPct,
      dspActiveCount: dspActiveCount,
      autoEqActiveCount: autoEqActiveCount,
      dacConnectedCount: dacConnectedCount,
      topGenres: topGenres,
    );

    final uniqueArtists = artistMap.length;
    final uniqueAlbums = trackMap.values.map((t) => t.album).toSet().length;

    return StudioWrappedData(
      timeFilter: timeFilter,
      totalMinutes: totalMinutes,
      totalTracksPlayed: filteredLogs.length,
      uniqueArtistsCount: uniqueArtists,
      uniqueAlbumsCount: uniqueAlbums,
      topTracks: topTracks,
      topArtists: topArtists,
      topGenres: topGenres,
      purityReport: purityReport,
      favoriteAutoEqDriver: favDriver,
      favoriteAutoEqTarget: favTarget,
      autoEqHours: autoEqHours,
      favoriteDspModule: 'Triode Tube Exciter',
      dspHours: dspHours,
      favoriteDacName: favDac,
      hardwareDacHours: dacHours,
      persona: persona,
      generatedAt: now,
    );
  }

  AudiophilePersona _classifyPersona({
    required double flacPercentage,
    required double hiResPercentage,
    required int dspActiveCount,
    required int autoEqActiveCount,
    required int dacConnectedCount,
    required List<GenreBreakdown> topGenres,
  }) {
    if (dacConnectedCount >= 10) {
      return AudiophilePersona.dacArtisan;
    }
    if (hiResPercentage >= 65.0) {
      return AudiophilePersona.analyticalPurist;
    }
    if (dspActiveCount >= 15) {
      return AudiophilePersona.tubeConnoisseur;
    }
    if (autoEqActiveCount >= 15) {
      return AudiophilePersona.studioVirtuoso;
    }

    final topGenre = topGenres.isNotEmpty ? topGenres.first.genre.toLowerCase() : '';
    if (topGenre.contains('electronic') || topGenre.contains('rock') || topGenre.contains('metal') || topGenre.contains('dance')) {
      return AudiophilePersona.subBassExplorer;
    }

    return AudiophilePersona.midnightListener;
  }

  StudioWrappedData _generateSampleWrappedData({
    required RecapTimeFilter timeFilter,
    List<Track>? libraryTracks,
  }) {
    final now = DateTime.now();

    final sampleTracks = <TopTrackRank>[
      const TopTrackRank(
        rank: 1,
        trackId: 'rec_1',
        title: 'Comfortably Numb',
        artist: 'Pink Floyd',
        album: 'The Wall (Lossless Remaster)',
        format: 'flac',
        sampleRate: 96000,
        bitDepth: 24,
        playCount: 142,
        totalMinutes: 852,
      ),
      const TopTrackRank(
        rank: 2,
        trackId: 'rec_2',
        title: 'Time',
        artist: 'Pink Floyd',
        album: 'The Dark Side of the Moon',
        format: 'flac',
        sampleRate: 96000,
        bitDepth: 24,
        playCount: 98,
        totalMinutes: 686,
      ),
      const TopTrackRank(
        rank: 3,
        trackId: 'rec_3',
        title: 'Bohemian Rhapsody',
        artist: 'Queen',
        album: 'A Night at the Opera',
        format: 'flac',
        sampleRate: 44100,
        bitDepth: 16,
        playCount: 76,
        totalMinutes: 456,
      ),
      const TopTrackRank(
        rank: 4,
        trackId: 'rec_4',
        title: 'Hotel California',
        artist: 'Eagles',
        album: 'Hotel California (High-Res 192k)',
        format: 'flac',
        sampleRate: 192000,
        bitDepth: 24,
        playCount: 64,
        totalMinutes: 416,
      ),
      const TopTrackRank(
        rank: 5,
        trackId: 'rec_5',
        title: 'Starboy',
        artist: 'The Weeknd',
        album: 'Starboy',
        format: 'flac',
        sampleRate: 44100,
        bitDepth: 16,
        playCount: 52,
        totalMinutes: 208,
      ),
    ];

    final sampleArtists = <TopArtistRank>[
      const TopArtistRank(rank: 1, artist: 'Pink Floyd', playCount: 240, totalMinutes: 1538, percentage: 38.5),
      const TopArtistRank(rank: 2, artist: 'Queen', playCount: 120, totalMinutes: 640, percentage: 16.0),
      const TopArtistRank(rank: 3, artist: 'Eagles', playCount: 95, totalMinutes: 520, percentage: 13.0),
      const TopArtistRank(rank: 4, artist: 'The Weeknd', playCount: 80, totalMinutes: 380, percentage: 9.5),
      const TopArtistRank(rank: 5, artist: 'Daft Punk', playCount: 65, totalMinutes: 310, percentage: 7.8),
    ];

    final sampleGenres = <GenreBreakdown>[
      const GenreBreakdown(genre: 'Progressive Rock', playCount: 260, percentage: 42.0),
      const GenreBreakdown(genre: 'Classic Rock', playCount: 180, percentage: 28.0),
      const GenreBreakdown(genre: 'Studio Acoustic', playCount: 110, percentage: 18.0),
      const GenreBreakdown(genre: 'Synthwave & Electronic', playCount: 75, percentage: 12.0),
    ];

    const samplePurity = AudioPurityReport(
      totalTracks: 625,
      flacCount: 552,
      hiResCount: 380,
      standardLosslessCount: 172,
      lossyCount: 73,
      flacPercentage: 88.4,
      hiResPercentage: 60.8,
      totalHiResMinutes: 8680,
    );

    return StudioWrappedData(
      timeFilter: timeFilter,
      totalMinutes: 14280,
      totalTracksPlayed: 625,
      uniqueArtistsCount: 48,
      uniqueAlbumsCount: 86,
      topTracks: sampleTracks,
      topArtists: sampleArtists,
      topGenres: sampleGenres,
      purityReport: samplePurity,
      favoriteAutoEqDriver: 'KZ CASTOR BLACK DUDU R',
      favoriteAutoEqTarget: 'HBB Target',
      autoEqHours: 64,
      favoriteDspModule: 'Triode Tube Exciter',
      dspHours: 82,
      favoriteDacName: 'Kiwi Ears AD1',
      hardwareDacHours: 42,
      persona: AudiophilePersona.tubeConnoisseur,
      generatedAt: now,
    );
  }
}

class _TrackAggregator {
  final String trackId;
  final String title;
  final String artist;
  final String album;
  final String format;
  final int sampleRate;
  final int bitDepth;
  int playCount = 0;
  int totalDurationMs = 0;

  _TrackAggregator({
    required this.trackId,
    required this.title,
    required this.artist,
    required this.album,
    required this.format,
    required this.sampleRate,
    required this.bitDepth,
  });
}

class _ArtistAggregator {
  final String artist;
  int playCount = 0;
  int totalDurationMs = 0;

  _ArtistAggregator({required this.artist});
}
