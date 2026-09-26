import '../../player/domain/track.dart';
import 'smart_playlist_models.dart';

/// Pure Dart deterministic evaluator for Smart Playlist rules
class SmartPlaylistEvaluator {
  const SmartPlaylistEvaluator();

  /// Default curated smart playlists presets
  static List<SmartPlaylist> get defaultPresets => [
        SmartPlaylist(
          id: 'preset_hires_studio',
          name: 'Hi-Res Studio Masters',
          description: 'Tracks with 24-bit or >= 88.2 kHz sample rate',
          matchMode: SmartPlaylistMatchMode.all,
          rules: const [
            SmartPlaylistRule(
              field: SmartPlaylistField.isHiRes,
              operator: SmartPlaylistOperator.isTrue,
              value: 'true',
            ),
          ],
          sortBy: 'sampleRate',
          sortAscending: false,
          createdAt: DateTime(2026, 1, 1),
          isPreset: true,
        ),
        SmartPlaylist(
          id: 'preset_long_acoustic',
          name: 'Acoustic & Extended Epics',
          description: 'Tracks with duration of 5 minutes or longer',
          matchMode: SmartPlaylistMatchMode.all,
          rules: const [
            SmartPlaylistRule(
              field: SmartPlaylistField.duration,
              operator: SmartPlaylistOperator.greaterThanOrEqual,
              value: '300',
            ),
          ],
          sortBy: 'duration',
          sortAscending: false,
          createdAt: DateTime(2026, 1, 1),
          isPreset: true,
        ),
        SmartPlaylist(
          id: 'preset_24bit_lossless',
          name: '24-Bit / 32-Bit Audiophile',
          description: 'True high bit-depth studio masters',
          matchMode: SmartPlaylistMatchMode.all,
          rules: const [
            SmartPlaylistRule(
              field: SmartPlaylistField.bitDepth,
              operator: SmartPlaylistOperator.greaterThanOrEqual,
              value: '24',
            ),
          ],
          sortBy: 'bitDepth',
          sortAscending: false,
          createdAt: DateTime(2026, 1, 1),
          isPreset: true,
        ),
        SmartPlaylist(
          id: 'preset_offline_local',
          name: 'Offline Local Library',
          description: 'Physical audio files stored on device storage',
          matchMode: SmartPlaylistMatchMode.all,
          rules: const [
            SmartPlaylistRule(
              field: SmartPlaylistField.isOffline,
              operator: SmartPlaylistOperator.isTrue,
              value: 'true',
            ),
          ],
          sortBy: 'title',
          sortAscending: true,
          createdAt: DateTime(2026, 1, 1),
          isPreset: true,
        ),
        SmartPlaylist(
          id: 'preset_starred_favorites',
          name: 'Starred Audiophile Picks',
          description: 'Dynamically aggregated favorite tracks',
          matchMode: SmartPlaylistMatchMode.all,
          rules: const [
            SmartPlaylistRule(
              field: SmartPlaylistField.isFavorite,
              operator: SmartPlaylistOperator.isTrue,
              value: 'true',
            ),
          ],
          sortBy: 'title',
          sortAscending: true,
          createdAt: DateTime(2026, 1, 1),
          isPreset: true,
        ),
      ];

  /// Evaluates the list of tracks matching the smart playlist specification
  List<Track> evaluate({
    required SmartPlaylist playlist,
    required List<Track> allTracks,
    Set<String>? favoriteTrackIds,
  }) {
    if (allTracks.isEmpty) return const [];

    final favs = favoriteTrackIds ?? const <String>{};

    final matched = allTracks.where((track) {
      if (playlist.rules.isEmpty) {
        return true;
      }

      if (playlist.matchMode == SmartPlaylistMatchMode.all) {
        return playlist.rules.every(
          (rule) => evaluateRule(track, rule, favoriteTrackIds: favs),
        );
      } else {
        return playlist.rules.any(
          (rule) => evaluateRule(track, rule, favoriteTrackIds: favs),
        );
      }
    }).toList();

    // Sort matching tracks
    _sortTracks(matched, playlist.sortBy, playlist.sortAscending);

    // Apply limit if specified
    if (playlist.limit != null && playlist.limit! > 0 && matched.length > playlist.limit!) {
      return matched.take(playlist.limit!).toList();
    }

    return matched;
  }

  /// Evaluates an individual rule condition on a single track
  bool evaluateRule(
    Track track,
    SmartPlaylistRule rule, {
    Set<String> favoriteTrackIds = const {},
  }) {
    switch (rule.field.type) {
      case SmartPlaylistFieldType.text:
        final actualText = _extractTrackText(track, rule.field);
        return _evaluateTextOperator(actualText, rule.operator, rule.value);

      case SmartPlaylistFieldType.number:
        final actualNum = _extractTrackNumber(track, rule.field);
        final targetNum = double.tryParse(rule.value);
        if (targetNum == null) return false;
        final secondaryNum = rule.secondaryValue != null
            ? double.tryParse(rule.secondaryValue!)
            : null;
        return _evaluateNumberOperator(
          actualNum,
          rule.operator,
          targetNum,
          secondaryNum,
        );

      case SmartPlaylistFieldType.boolean:
        final actualBool = _extractTrackBoolean(track, rule.field, favoriteTrackIds);
        return _evaluateBooleanOperator(actualBool, rule.operator);
    }
  }

  String _extractTrackText(Track track, SmartPlaylistField field) {
    switch (field) {
      case SmartPlaylistField.title:
        return track.title;
      case SmartPlaylistField.artist:
        return track.artist;
      case SmartPlaylistField.album:
        return track.album;
      case SmartPlaylistField.genre:
        return track.genre ?? '';
      case SmartPlaylistField.filePath:
        return track.filePath ?? track.remoteUrl ?? '';
      default:
        return '';
    }
  }

  num _extractTrackNumber(Track track, SmartPlaylistField field) {
    switch (field) {
      case SmartPlaylistField.duration:
        return track.duration.inSeconds;
      case SmartPlaylistField.sampleRate:
        return track.sampleRate ?? 44100;
      case SmartPlaylistField.bitDepth:
        return track.bitDepth ?? 16;
      case SmartPlaylistField.bitrate:
        return track.bitrate ?? 0;
      case SmartPlaylistField.year:
        return track.year ?? 0;
      default:
        return 0;
    }
  }

  bool _extractTrackBoolean(
    Track track,
    SmartPlaylistField field,
    Set<String> favoriteTrackIds,
  ) {
    switch (field) {
      case SmartPlaylistField.isHiRes:
        return track.isHiRes;
      case SmartPlaylistField.isFavorite:
        return favoriteTrackIds.contains(track.id);
      case SmartPlaylistField.isOffline:
        return track.filePath != null && track.filePath!.isNotEmpty;
      default:
        return false;
    }
  }

  bool _evaluateTextOperator(
    String actual,
    SmartPlaylistOperator operator,
    String target,
  ) {
    final a = actual.toLowerCase().trim();
    final t = target.toLowerCase().trim();

    switch (operator) {
      case SmartPlaylistOperator.contains:
        return a.contains(t);
      case SmartPlaylistOperator.notContains:
        return !a.contains(t);
      case SmartPlaylistOperator.equals:
        return a == t;
      case SmartPlaylistOperator.notEquals:
        return a != t;
      case SmartPlaylistOperator.startsWith:
        return a.startsWith(t);
      case SmartPlaylistOperator.endsWith:
        return a.endsWith(t);
      default:
        return false;
    }
  }

  bool _evaluateNumberOperator(
    num actual,
    SmartPlaylistOperator operator,
    double target,
    double? secondary,
  ) {
    switch (operator) {
      case SmartPlaylistOperator.equals:
        return (actual - target).abs() < 0.0001;
      case SmartPlaylistOperator.greaterThan:
        return actual > target;
      case SmartPlaylistOperator.greaterThanOrEqual:
        return actual >= target;
      case SmartPlaylistOperator.lessThan:
        return actual < target;
      case SmartPlaylistOperator.lessThanOrEqual:
        return actual <= target;
      case SmartPlaylistOperator.between:
        if (secondary == null) return actual >= target;
        final minVal = target <= secondary ? target : secondary;
        final maxVal = target <= secondary ? secondary : target;
        return actual >= minVal && actual <= maxVal;
      default:
        return false;
    }
  }

  bool _evaluateBooleanOperator(
    bool actual,
    SmartPlaylistOperator operator,
  ) {
    switch (operator) {
      case SmartPlaylistOperator.isTrue:
        return actual == true;
      case SmartPlaylistOperator.isFalse:
        return actual == false;
      default:
        return false;
    }
  }

  void _sortTracks(List<Track> list, String sortBy, bool ascending) {
    list.sort((a, b) {
      int cmp = 0;
      switch (sortBy) {
        case 'artist':
          cmp = a.artist.toLowerCase().compareTo(b.artist.toLowerCase());
          break;
        case 'album':
          cmp = a.album.toLowerCase().compareTo(b.album.toLowerCase());
          break;
        case 'duration':
          cmp = a.duration.compareTo(b.duration);
          break;
        case 'sampleRate':
          final aRate = (a.sampleRate ?? 44100) * 100 + (a.bitDepth ?? 16);
          final bRate = (b.sampleRate ?? 44100) * 100 + (b.bitDepth ?? 16);
          cmp = aRate.compareTo(bRate);
          break;
        case 'bitDepth':
          final aBits = a.bitDepth ?? 16;
          final bBits = b.bitDepth ?? 16;
          cmp = aBits.compareTo(bBits);
          break;
        case 'dateAdded':
          cmp = a.id.compareTo(b.id);
          break;
        case 'title':
        default:
          cmp = a.title.toLowerCase().compareTo(b.title.toLowerCase());
          break;
      }
      return ascending ? cmp : -cmp;
    });
  }
}
