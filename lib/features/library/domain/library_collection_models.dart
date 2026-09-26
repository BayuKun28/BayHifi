import 'package:flutter/foundation.dart';
import '../../player/domain/track.dart';

/// Sub-tab collection navigation
enum CollectionTab {
  tracks('Tracks'),
  albums('Albums'),
  artists('Artists'),
  genres('Genres'),
  folders('Folders');

  final String label;
  const CollectionTab(this.label);
}

/// Sort Criteria
enum SortField {
  title('Title'),
  artist('Artist'),
  album('Album'),
  duration('Duration'),
  dateAdded('Date Added'),
  hiRes('Hi-Res Quality');

  final String label;
  const SortField(this.label);
}

enum SortDirection {
  ascending('Ascending (A-Z)'),
  descending('Descending (Z-A)');

  final String label;
  const SortDirection(this.label);
}

enum ViewLayoutMode {
  list,
  grid;
}

/// Model Pengelompokan Album
@immutable
class AlbumModel {
  final String name;
  final String artist;
  final int? year;
  final List<Track> tracks;
  final String? coverUrl;
  final Uint8List? coverBytes;

  const AlbumModel({
    required this.name,
    required this.artist,
    this.year,
    required this.tracks,
    this.coverUrl,
    this.coverBytes,
  });

  int get trackCount => tracks.length;

  Track? get firstTrack => tracks.isNotEmpty ? tracks.first : null;

  Duration get totalDuration =>
      tracks.fold(Duration.zero, (prev, t) => prev + t.duration);

  bool get isHiRes => tracks.any((t) => t.isHiRes);
}

/// Model Pengelompokan Artis
@immutable
class ArtistModel {
  final String name;
  final List<Track> tracks;
  final String? coverUrl;
  final Uint8List? coverBytes;

  const ArtistModel({
    required this.name,
    required this.tracks,
    this.coverUrl,
    this.coverBytes,
  });

  Track? get firstTrack => tracks.isNotEmpty ? tracks.first : null;

  int get tracksCount => tracks.length;

  int get albumsCount =>
      tracks.map((t) => t.album).toSet().where((a) => a.isNotEmpty).length;
}

/// Model Pengelompokan Genre
@immutable
class GenreModel {
  final String name;
  final List<Track> tracks;

  const GenreModel({
    required this.name,
    required this.tracks,
  });

  int get trackCount => tracks.length;
}

/// Model Playlist Kustom
@immutable
class PlaylistModel {
  final String id;
  final String name;
  final String description;
  final List<Track> tracks;
  final bool isCustom;
  final DateTime createdAt;

  const PlaylistModel({
    required this.id,
    required this.name,
    required this.description,
    required this.tracks,
    this.isCustom = true,
    required this.createdAt,
  });

  int get trackCount => tracks.length;
}

/// Model Folder Direktori Audio
@immutable
class FolderModel {
  final String path;
  final String name;
  final List<Track> tracks;

  const FolderModel({
    required this.path,
    required this.name,
    required this.tracks,
  });

  int get trackCount => tracks.length;
}
