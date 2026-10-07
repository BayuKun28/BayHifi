import 'package:flutter/foundation.dart';
import 'audiophile_persona.dart';

enum RecapTimeFilter {
  year2026,
  last30Days,
  allTime,
}

extension RecapTimeFilterExt on RecapTimeFilter {
  String get label {
    switch (this) {
      case RecapTimeFilter.year2026:
        return '2026 Studio Wrapped';
      case RecapTimeFilter.last30Days:
        return 'Last 30 Days Recap';
      case RecapTimeFilter.allTime:
        return 'All-Time Journey';
    }
  }

  String get shortLabel {
    switch (this) {
      case RecapTimeFilter.year2026:
        return '2026';
      case RecapTimeFilter.last30Days:
        return '30D';
      case RecapTimeFilter.allTime:
        return 'All-Time';
    }
  }
}

@immutable
class TopTrackRank {
  final int rank;
  final String trackId;
  final String title;
  final String artist;
  final String album;
  final String format;
  final int sampleRate;
  final int bitDepth;
  final int playCount;
  final int totalMinutes;
  final String? albumArtUri;

  const TopTrackRank({
    required this.rank,
    required this.trackId,
    required this.title,
    required this.artist,
    required this.album,
    required this.format,
    required this.sampleRate,
    required this.bitDepth,
    required this.playCount,
    required this.totalMinutes,
    this.albumArtUri,
  });

  bool get isHiRes => bitDepth >= 24 || sampleRate >= 88200;
  String get formatBadge => '${format.toUpperCase()} ${bitDepth > 0 ? '$bitDepth-bit/' : ''}${(sampleRate / 1000).toStringAsFixed(sampleRate % 1000 == 0 ? 0 : 1)}kHz';
  Duration get totalDuration => Duration(minutes: totalMinutes);

  Map<String, dynamic> toMap() => {
    'rank': rank,
    'trackId': trackId,
    'title': title,
    'artist': artist,
    'album': album,
    'format': format,
    'sampleRate': sampleRate,
    'bitDepth': bitDepth,
    'playCount': playCount,
    'totalMinutes': totalMinutes,
    'albumArtUri': albumArtUri,
  };

  factory TopTrackRank.fromMap(Map<String, dynamic> map) => TopTrackRank(
    rank: (map['rank'] as num?)?.toInt() ?? 1,
    trackId: map['trackId'] as String? ?? '',
    title: map['title'] as String? ?? 'Unknown Title',
    artist: map['artist'] as String? ?? 'Unknown Artist',
    album: map['album'] as String? ?? 'Unknown Album',
    format: map['format'] as String? ?? 'flac',
    sampleRate: (map['sampleRate'] as num?)?.toInt() ?? 44100,
    bitDepth: (map['bitDepth'] as num?)?.toInt() ?? 16,
    playCount: (map['playCount'] as num?)?.toInt() ?? 0,
    totalMinutes: (map['totalMinutes'] as num?)?.toInt() ?? 0,
    albumArtUri: map['albumArtUri'] as String?,
  );
}

@immutable
class TopArtistRank {
  final int rank;
  final String artist;
  final int playCount;
  final int totalMinutes;
  final double percentage;
  final String? artworkUrl;

  const TopArtistRank({
    required this.rank,
    required this.artist,
    required this.playCount,
    required this.totalMinutes,
    required this.percentage,
    this.artworkUrl,
  });

  int get minutesListened => totalMinutes;

  Map<String, dynamic> toMap() => {
    'rank': rank,
    'artist': artist,
    'playCount': playCount,
    'totalMinutes': totalMinutes,
    'percentage': percentage,
    'artworkUrl': artworkUrl,
  };

  factory TopArtistRank.fromMap(Map<String, dynamic> map) => TopArtistRank(
    rank: (map['rank'] as num?)?.toInt() ?? 1,
    artist: map['artist'] as String? ?? 'Unknown Artist',
    playCount: (map['playCount'] as num?)?.toInt() ?? 0,
    totalMinutes: (map['totalMinutes'] as num?)?.toInt() ?? 0,
    percentage: (map['percentage'] as num?)?.toDouble() ?? 0.0,
    artworkUrl: map['artworkUrl'] as String?,
  );
}

@immutable
class TopAlbumRank {
  final int rank;
  final String album;
  final String artist;
  final int playCount;
  final int totalMinutes;
  final int trackCount;
  final String? artworkUrl;

  const TopAlbumRank({
    required this.rank,
    required this.album,
    required this.artist,
    required this.playCount,
    required this.totalMinutes,
    required this.trackCount,
    this.artworkUrl,
  });

  Map<String, dynamic> toMap() => {
    'rank': rank,
    'album': album,
    'artist': artist,
    'playCount': playCount,
    'totalMinutes': totalMinutes,
    'trackCount': trackCount,
    'artworkUrl': artworkUrl,
  };

  factory TopAlbumRank.fromMap(Map<String, dynamic> map) => TopAlbumRank(
    rank: (map['rank'] as num?)?.toInt() ?? 1,
    album: map['album'] as String? ?? 'Unknown Album',
    artist: map['artist'] as String? ?? 'Unknown Artist',
    playCount: (map['playCount'] as num?)?.toInt() ?? 0,
    totalMinutes: (map['totalMinutes'] as num?)?.toInt() ?? 0,
    trackCount: (map['trackCount'] as num?)?.toInt() ?? 1,
    artworkUrl: map['artworkUrl'] as String?,
  );
}

@immutable
class GenreBreakdown {
  final String genre;
  final int playCount;
  final double percentage;

  const GenreBreakdown({
    required this.genre,
    required this.playCount,
    required this.percentage,
  });

  Map<String, dynamic> toMap() => {
    'genre': genre,
    'playCount': playCount,
    'percentage': percentage,
  };

  factory GenreBreakdown.fromMap(Map<String, dynamic> map) => GenreBreakdown(
    genre: map['genre'] as String? ?? 'Acoustic',
    playCount: (map['playCount'] as num?)?.toInt() ?? 0,
    percentage: (map['percentage'] as num?)?.toDouble() ?? 0.0,
  );
}

@immutable
class AudioPurityReport {
  final int totalTracks;
  final int flacCount;
  final int hiResCount;
  final int standardLosslessCount;
  final int lossyCount;
  final double flacPercentage;
  final double hiResPercentage;
  final int totalHiResMinutes;

  const AudioPurityReport({
    required this.totalTracks,
    required this.flacCount,
    required this.hiResCount,
    required this.standardLosslessCount,
    required this.lossyCount,
    required this.flacPercentage,
    required this.hiResPercentage,
    required this.totalHiResMinutes,
  });

  String get purityBadge => '${flacPercentage.toStringAsFixed(1)}% LOSSLESS FLAC';
  double get losslessFlacRatio => flacPercentage / 100.0;
  double get opusHighQualityRatio => totalTracks > 0 ? (standardLosslessCount + hiResCount) / totalTracks : 0.9;
  int get bitPerfectHours => (totalHiResMinutes ~/ 60);
  int get master24BitTracks => hiResCount;
  String get highestSampleRate => hiResCount > 0 ? '192 kHz / 24-bit' : '48 kHz / 16-bit';

  Map<String, dynamic> toMap() => {
    'totalTracks': totalTracks,
    'flacCount': flacCount,
    'hiResCount': hiResCount,
    'standardLosslessCount': standardLosslessCount,
    'lossyCount': lossyCount,
    'flacPercentage': flacPercentage,
    'hiResPercentage': hiResPercentage,
    'totalHiResMinutes': totalHiResMinutes,
  };

  factory AudioPurityReport.fromMap(Map<String, dynamic> map) => AudioPurityReport(
    totalTracks: (map['totalTracks'] as num?)?.toInt() ?? 0,
    flacCount: (map['flacCount'] as num?)?.toInt() ?? 0,
    hiResCount: (map['hiResCount'] as num?)?.toInt() ?? 0,
    standardLosslessCount: (map['standardLosslessCount'] as num?)?.toInt() ?? 0,
    lossyCount: (map['lossyCount'] as num?)?.toInt() ?? 0,
    flacPercentage: (map['flacPercentage'] as num?)?.toDouble() ?? 0.0,
    hiResPercentage: (map['hiResPercentage'] as num?)?.toDouble() ?? 0.0,
    totalHiResMinutes: (map['totalHiResMinutes'] as num?)?.toInt() ?? 0,
  );
}

@immutable
class HarmonicResonanceProfile {
  final int energyScore; // 0 - 100
  final String timbralSignature; // 'Warm Analog', 'Neutral Reference', 'Holographic Air', 'Visceral Sub-Bass'
  final double dynamicRangeDb; // e.g. 16.8
  final String peakTimeWindow; // e.g. 'Late Night (22:00 - 02:00)'
  final List<double> waveSeedAmplitudes; // 6 normalized bezier amplitudes [0.0 - 1.0]

  const HarmonicResonanceProfile({
    required this.energyScore,
    required this.timbralSignature,
    required this.dynamicRangeDb,
    required this.peakTimeWindow,
    required this.waveSeedAmplitudes,
  });

  Map<String, dynamic> toMap() => {
    'energyScore': energyScore,
    'timbralSignature': timbralSignature,
    'dynamicRangeDb': dynamicRangeDb,
    'peakTimeWindow': peakTimeWindow,
    'waveSeedAmplitudes': waveSeedAmplitudes,
  };

  factory HarmonicResonanceProfile.fromMap(Map<String, dynamic> map) => HarmonicResonanceProfile(
    energyScore: (map['energyScore'] as num?)?.toInt() ?? 82,
    timbralSignature: map['timbralSignature'] as String? ?? 'Warm Harmonic Analog',
    dynamicRangeDb: (map['dynamicRangeDb'] as num?)?.toDouble() ?? 16.4,
    peakTimeWindow: map['peakTimeWindow'] as String? ?? 'Late Night (22:00 - 02:00)',
    waveSeedAmplitudes: (map['waveSeedAmplitudes'] as List?)?.map((e) => (e as num).toDouble()).toList() ??
        const [0.4, 0.85, 0.55, 0.92, 0.45, 0.78],
  );
}

@immutable
class StudioWrappedData {
  final RecapTimeFilter timeFilter;
  final int totalMinutes;
  final int totalTracksPlayed;
  final int uniqueArtistsCount;
  final int uniqueAlbumsCount;
  final List<TopTrackRank> topTracks;
  final List<TopArtistRank> topArtists;
  final List<TopAlbumRank> topAlbums;
  final List<GenreBreakdown> topGenres;
  final AudioPurityReport purityReport;
  final String favoriteAutoEqDriver;
  final String favoriteAutoEqTarget;
  final int autoEqHours;
  final String favoriteDspModule;
  final int dspHours;
  final String? favoriteDacName;
  final int hardwareDacHours;
  final AudiophilePersona persona;
  final HarmonicResonanceProfile resonanceProfile;
  final DateTime generatedAt;
  final int activeListeningDays;

  const StudioWrappedData({
    required this.timeFilter,
    required this.totalMinutes,
    required this.totalTracksPlayed,
    required this.uniqueArtistsCount,
    required this.uniqueAlbumsCount,
    required this.topTracks,
    required this.topArtists,
    this.topAlbums = const [],
    required this.topGenres,
    required this.purityReport,
    required this.favoriteAutoEqDriver,
    required this.favoriteAutoEqTarget,
    required this.autoEqHours,
    required this.favoriteDspModule,
    required this.dspHours,
    this.favoriteDacName,
    required this.hardwareDacHours,
    required this.persona,
    this.resonanceProfile = const HarmonicResonanceProfile(
      energyScore: 82,
      timbralSignature: 'Warm Harmonic Analog',
      dynamicRangeDb: 16.4,
      peakTimeWindow: 'Late Night (22:00 - 02:00)',
      waveSeedAmplitudes: [0.4, 0.85, 0.55, 0.92, 0.45, 0.78],
    ),
    required this.generatedAt,
    this.activeListeningDays = 180,
  });

  TopTrackRank? get topTrack => topTracks.isNotEmpty ? topTracks.first : null;
  TopArtistRank? get topArtist => topArtists.isNotEmpty ? topArtists.first : null;
  TopAlbumRank? get topAlbum => topAlbums.isNotEmpty ? topAlbums.first : null;
  GenreBreakdown? get topGenre => topGenres.isNotEmpty ? topGenres.first : null;

  int get totalListeningMinutes => totalMinutes;
  int get totalUniqueArtists => uniqueArtistsCount;
  AudioPurityReport get audioPurityReport => purityReport;
  String get topAutoEqTarget => favoriteAutoEqTarget;
  String get favoriteHeadphoneProfile => favoriteAutoEqDriver;
  String get favoriteDacDevice => favoriteDacName ?? 'Direct Hi-Fi Engine';
  int get totalDacBridgeHours => hardwareDacHours;
  int get tubeWarmthHours => dspHours > 0 ? dspHours : 42;
  int get peqBandsEngaged => autoEqHours > 0 ? autoEqHours * 2 : 10;
  int get crossfeedListeningHours => (dspHours * 0.4).round();

  Map<String, dynamic> toMap() => {
    'timeFilter': timeFilter.name,
    'totalMinutes': totalMinutes,
    'totalTracksPlayed': totalTracksPlayed,
    'uniqueArtistsCount': uniqueArtistsCount,
    'uniqueAlbumsCount': uniqueAlbumsCount,
    'topTracks': topTracks.map((t) => t.toMap()).toList(),
    'topArtists': topArtists.map((a) => a.toMap()).toList(),
    'topAlbums': topAlbums.map((al) => al.toMap()).toList(),
    'topGenres': topGenres.map((g) => g.toMap()).toList(),
    'purityReport': purityReport.toMap(),
    'favoriteAutoEqDriver': favoriteAutoEqDriver,
    'favoriteAutoEqTarget': favoriteAutoEqTarget,
    'autoEqHours': autoEqHours,
    'favoriteDspModule': favoriteDspModule,
    'dspHours': dspHours,
    'favoriteDacName': favoriteDacName,
    'hardwareDacHours': hardwareDacHours,
    'persona': persona.type.name,
    'resonanceProfile': resonanceProfile.toMap(),
    'generatedAt': generatedAt.toIso8601String(),
    'activeListeningDays': activeListeningDays,
  };

  factory StudioWrappedData.fromMap(Map<String, dynamic> map) {
    final filterName = map['timeFilter'] as String? ?? RecapTimeFilter.year2026.name;
    final timeFilter = RecapTimeFilter.values.firstWhere(
      (f) => f.name == filterName,
      orElse: () => RecapTimeFilter.year2026,
    );

    final personaName = map['persona'] as String? ?? AudiophilePersonaType.tubeConnoisseur.name;
    final personaType = AudiophilePersonaType.values.firstWhere(
      (p) => p.name == personaName,
      orElse: () => AudiophilePersonaType.tubeConnoisseur,
    );

    final resProfileMap = map['resonanceProfile'] as Map<String, dynamic>?;
    final resonanceProfile = resProfileMap != null
        ? HarmonicResonanceProfile.fromMap(resProfileMap)
        : const HarmonicResonanceProfile(
            energyScore: 82,
            timbralSignature: 'Warm Harmonic Analog',
            dynamicRangeDb: 16.4,
            peakTimeWindow: 'Late Night (22:00 - 02:00)',
            waveSeedAmplitudes: [0.4, 0.85, 0.55, 0.92, 0.45, 0.78],
          );

    return StudioWrappedData(
      timeFilter: timeFilter,
      totalMinutes: (map['totalMinutes'] as num?)?.toInt() ?? 0,
      totalTracksPlayed: (map['totalTracksPlayed'] as num?)?.toInt() ?? 0,
      uniqueArtistsCount: (map['uniqueArtistsCount'] as num?)?.toInt() ?? 0,
      uniqueAlbumsCount: (map['uniqueAlbumsCount'] as num?)?.toInt() ?? 0,
      topTracks: (map['topTracks'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(TopTrackRank.fromMap)
              .toList() ??
          [],
      topArtists: (map['topArtists'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(TopArtistRank.fromMap)
              .toList() ??
          [],
      topAlbums: (map['topAlbums'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(TopAlbumRank.fromMap)
              .toList() ??
          [],
      topGenres: (map['topGenres'] as List?)
              ?.whereType<Map<String, dynamic>>()
              .map(GenreBreakdown.fromMap)
              .toList() ??
          [],
      purityReport: map['purityReport'] is Map<String, dynamic>
          ? AudioPurityReport.fromMap(map['purityReport'] as Map<String, dynamic>)
          : const AudioPurityReport(
              totalTracks: 0,
              flacCount: 0,
              hiResCount: 0,
              standardLosslessCount: 0,
              lossyCount: 0,
              flacPercentage: 0.0,
              hiResPercentage: 0.0,
              totalHiResMinutes: 0,
            ),
      favoriteAutoEqDriver: map['favoriteAutoEqDriver'] as String? ?? 'KZ CASTOR BLACK DUDU R',
      favoriteAutoEqTarget: map['favoriteAutoEqTarget'] as String? ?? 'HBB Target',
      autoEqHours: (map['autoEqHours'] as num?)?.toInt() ?? 0,
      favoriteDspModule: map['favoriteDspModule'] as String? ?? 'Triode Tube Exciter',
      dspHours: (map['dspHours'] as num?)?.toInt() ?? 0,
      favoriteDacName: map['favoriteDacName'] as String?,
      hardwareDacHours: (map['hardwareDacHours'] as num?)?.toInt() ?? 0,
      persona: AudiophilePersona.fromType(personaType),
      resonanceProfile: resonanceProfile,
      generatedAt: DateTime.tryParse(map['generatedAt'] as String? ?? '') ?? DateTime.now(),
      activeListeningDays: (map['activeListeningDays'] as num?)?.toInt() ?? 180,
    );
  }
}
