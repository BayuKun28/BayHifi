import 'dart:io';
import 'package:dbus/dbus.dart';
import 'package:flutter/foundation.dart';
import '../../features/player/domain/track.dart';

/// Service integrasi Linux Desktop MPRIS v2 D-Bus (`org.mpris.MediaPlayer2`).
/// Memungkinkan kontrol pemutaran dari GNOME Shell, KDE Plasma, Waybar, Polybar,
/// dan hardware media keys pada keyboard PC.
class LinuxMprisService {
  static LinuxMprisService? _instance;
  static LinuxMprisService get instance => _instance ??= LinuxMprisService._();

  LinuxMprisService._();

  DBusClient? _client;
  _BaydevMprisObject? _mprisObject;
  bool _isInitialized = false;

  bool get isInitialized => _isInitialized;

  // Callbacks yang dihubungkan ke PlayerController
  VoidCallback? onPlay;
  VoidCallback? onPause;
  VoidCallback? onPlayPause;
  VoidCallback? onNext;
  VoidCallback? onPrevious;
  VoidCallback? onStop;
  void Function(Duration position)? onSeek;
  void Function(double volume)? onSetVolume;

  /// Inisialisasi MPRIS v2 D-Bus daemon pada Linux Desktop
  Future<void> init() async {
    if (kIsWeb || !Platform.isLinux) return;
    if (_isInitialized) return;

    try {
      _client = DBusClient.session();
      _mprisObject = _BaydevMprisObject(this);
      await _client!.registerObject(_mprisObject!);

      final result = await _client!.requestName(
        'org.mpris.MediaPlayer2.baydev_hifi',
        flags: {
          DBusRequestNameFlag.replaceExisting,
          DBusRequestNameFlag.doNotQueue,
        },
      );

      _isInitialized = true;
      debugPrint('[LinuxMprisService] Registered D-Bus name: org.mpris.MediaPlayer2.baydev_hifi (result: $result)');
    } catch (e) {
      debugPrint('[LinuxMprisService] DBus init bypassed or failed: $e');
    }
  }

  /// Memperbarui metadata trek aktif ke D-Bus MPRIS
  void updateTrack(Track? track, Duration duration) {
    if (!_isInitialized || _mprisObject == null) return;
    try {
      _mprisObject!.updateMetadata(track, duration);
    } catch (e) {
      debugPrint('[LinuxMprisService] Error updating track metadata: $e');
    }
  }

  /// Memperbarui status pemutaran (Playing/Paused/Stopped) & posisi
  void updatePlaybackState({
    required bool isPlaying,
    required Duration position,
    required Duration duration,
    double volume = 1.0,
  }) {
    if (!_isInitialized || _mprisObject == null) return;
    try {
      _mprisObject!.updatePlaybackState(
        isPlaying: isPlaying,
        position: position,
        duration: duration,
        volume: volume,
      );
    } catch (e) {
      debugPrint('[LinuxMprisService] Error updating playback state: $e');
    }
  }

  /// Menutup koneksi DBus saat aplikasi ditutup
  Future<void> dispose() async {
    if (!_isInitialized) return;
    try {
      if (_client != null) {
        await _client!.close();
      }
      _isInitialized = false;
    } catch (e) {
      debugPrint('[LinuxMprisService] Error closing DBus client: $e');
    }
  }
}

class _BaydevMprisObject extends DBusObject {
  final LinuxMprisService _service;

  String _playbackStatus = 'Stopped';
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1.0;
  Track? _currentTrack;

  _BaydevMprisObject(this._service)
      : super(DBusObjectPath('/org/mpris/MediaPlayer2'));

  void updateMetadata(Track? track, Duration duration) {
    _currentTrack = track;
    _duration = duration;
    emitPropertiesChanged(
      'org.mpris.MediaPlayer2.Player',
      changedProperties: {
        'Metadata': _buildMetadataVariant(),
      },
    );
  }

  void updatePlaybackState({
    required bool isPlaying,
    required Duration position,
    required Duration duration,
    required double volume,
  }) {
    final newStatus = isPlaying ? 'Playing' : 'Paused';
    final statusChanged = _playbackStatus != newStatus;
    final volumeChanged = (_volume - volume).abs() > 0.01;

    _playbackStatus = newStatus;
    _position = position;
    _duration = duration;
    _volume = volume;

    final Map<String, DBusValue> changed = {};
    if (statusChanged) {
      changed['PlaybackStatus'] = DBusString(_playbackStatus);
    }
    if (volumeChanged) {
      changed['Volume'] = DBusDouble(_volume);
    }
    if (changed.isNotEmpty) {
      emitPropertiesChanged(
        'org.mpris.MediaPlayer2.Player',
        changedProperties: changed,
      );
    }
  }

  DBusValue _buildMetadataVariant() {
    final Map<DBusValue, DBusValue> map = {};

    if (_currentTrack != null) {
      final safeId = _currentTrack!.id.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
      map[const DBusString('mpris:trackid')] = DBusVariant(
        DBusObjectPath('/org/mpris/MediaPlayer2/Track/$safeId'),
      );
      map[const DBusString('xesam:title')] = DBusVariant(DBusString(_currentTrack!.title));
      map[const DBusString('xesam:artist')] = DBusVariant(
        DBusArray.string([_currentTrack!.artist]),
      );
      if (_currentTrack!.album.isNotEmpty) {
        map[const DBusString('xesam:album')] = DBusVariant(DBusString(_currentTrack!.album));
      }
      if (_currentTrack!.albumArtUrl != null && _currentTrack!.albumArtUrl!.isNotEmpty) {
        map[const DBusString('mpris:artUrl')] = DBusVariant(DBusString(_currentTrack!.albumArtUrl!));
      }
      map[const DBusString('mpris:length')] = DBusVariant(
        DBusInt64(_duration.inMicroseconds > 0 ? _duration.inMicroseconds : _currentTrack!.duration.inMicroseconds),
      );
    } else {
      map[const DBusString('mpris:trackid')] = DBusVariant(
        DBusObjectPath('/org/mpris/MediaPlayer2/Track/none'),
      );
      map[const DBusString('xesam:title')] = const DBusVariant(DBusString('No Track Loaded'));
      map[const DBusString('xesam:artist')] = DBusVariant(DBusArray.string(['Baydev HiFi']));
    }

    return DBusDict(DBusSignature('s'), DBusSignature('v'), map);
  }

  @override
  List<DBusIntrospectInterface> introspect() {
    return [
      DBusIntrospectInterface(
        'org.mpris.MediaPlayer2',
        methods: [
          DBusIntrospectMethod('Raise'),
          DBusIntrospectMethod('Quit'),
        ],
        properties: [
          DBusIntrospectProperty('CanQuit', DBusSignature('b'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('CanRaise', DBusSignature('b'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('HasTrackList', DBusSignature('b'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('Identity', DBusSignature('s'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('SupportedUriSchemes', DBusSignature('as'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('SupportedMimeTypes', DBusSignature('as'), access: DBusPropertyAccess.read),
        ],
      ),
      DBusIntrospectInterface(
        'org.mpris.MediaPlayer2.Player',
        methods: [
          DBusIntrospectMethod('Next'),
          DBusIntrospectMethod('Previous'),
          DBusIntrospectMethod('Pause'),
          DBusIntrospectMethod('PlayPause'),
          DBusIntrospectMethod('Stop'),
          DBusIntrospectMethod('Play'),
          DBusIntrospectMethod(
            'Seek',
            args: [
              DBusIntrospectArgument(DBusSignature('x'), DBusArgumentDirection.in_, name: 'Offset'),
            ],
          ),
          DBusIntrospectMethod(
            'SetPosition',
            args: [
              DBusIntrospectArgument(DBusSignature('o'), DBusArgumentDirection.in_, name: 'TrackId'),
              DBusIntrospectArgument(DBusSignature('x'), DBusArgumentDirection.in_, name: 'Position'),
            ],
          ),
          DBusIntrospectMethod(
            'OpenUri',
            args: [
              DBusIntrospectArgument(DBusSignature('s'), DBusArgumentDirection.in_, name: 'Uri'),
            ],
          ),
        ],
        properties: [
          DBusIntrospectProperty('PlaybackStatus', DBusSignature('s'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('LoopStatus', DBusSignature('s'), access: DBusPropertyAccess.readwrite),
          DBusIntrospectProperty('Rate', DBusSignature('d'), access: DBusPropertyAccess.readwrite),
          DBusIntrospectProperty('Shuffle', DBusSignature('b'), access: DBusPropertyAccess.readwrite),
          DBusIntrospectProperty('Metadata', DBusSignature('a{sv}'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('Volume', DBusSignature('d'), access: DBusPropertyAccess.readwrite),
          DBusIntrospectProperty('Position', DBusSignature('x'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('MinimumRate', DBusSignature('d'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('MaximumRate', DBusSignature('d'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('CanControl', DBusSignature('b'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('CanPlay', DBusSignature('b'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('CanPause', DBusSignature('b'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('CanSeek', DBusSignature('b'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('CanGoNext', DBusSignature('b'), access: DBusPropertyAccess.read),
          DBusIntrospectProperty('CanGoPrevious', DBusSignature('b'), access: DBusPropertyAccess.read),
        ],
      ),
    ];
  }

  @override
  Future<DBusMethodResponse> handleMethodCall(DBusMethodCall methodCall) async {
    if (methodCall.interface == 'org.mpris.MediaPlayer2') {
      if (methodCall.name == 'Raise') {
        return DBusMethodSuccessResponse();
      } else if (methodCall.name == 'Quit') {
        exit(0);
      }
    } else if (methodCall.interface == 'org.mpris.MediaPlayer2.Player') {
      if (methodCall.name == 'Play') {
        _service.onPlay?.call();
        return DBusMethodSuccessResponse();
      } else if (methodCall.name == 'Pause') {
        _service.onPause?.call();
        return DBusMethodSuccessResponse();
      } else if (methodCall.name == 'PlayPause') {
        _service.onPlayPause?.call();
        return DBusMethodSuccessResponse();
      } else if (methodCall.name == 'Next') {
        _service.onNext?.call();
        return DBusMethodSuccessResponse();
      } else if (methodCall.name == 'Previous') {
        _service.onPrevious?.call();
        return DBusMethodSuccessResponse();
      } else if (methodCall.name == 'Stop') {
        _service.onStop?.call();
        return DBusMethodSuccessResponse();
      } else if (methodCall.name == 'Seek') {
        final offsetUs = (methodCall.values.first as DBusInt64).value;
        final target = _position + Duration(microseconds: offsetUs);
        _service.onSeek?.call(target < Duration.zero ? Duration.zero : target);
        return DBusMethodSuccessResponse();
      } else if (methodCall.name == 'SetPosition') {
        final posUs = (methodCall.values[1] as DBusInt64).value;
        _service.onSeek?.call(Duration(microseconds: posUs));
        return DBusMethodSuccessResponse();
      }
    }
    return DBusMethodErrorResponse.unknownMethod();
  }

  @override
  Future<DBusMethodResponse> getProperty(String interface, String name) async {
    if (interface == 'org.mpris.MediaPlayer2') {
      switch (name) {
        case 'CanQuit':
          return DBusMethodSuccessResponse([const DBusBoolean(true)]);
        case 'CanRaise':
          return DBusMethodSuccessResponse([const DBusBoolean(true)]);
        case 'HasTrackList':
          return DBusMethodSuccessResponse([const DBusBoolean(false)]);
        case 'Identity':
          return DBusMethodSuccessResponse([const DBusString('Baydev HiFi')]);
        case 'SupportedUriSchemes':
          return DBusMethodSuccessResponse([
            DBusArray.string(['file', 'http', 'https']),
          ]);
        case 'SupportedMimeTypes':
          return DBusMethodSuccessResponse([
            DBusArray.string([
              'audio/flac',
              'audio/wav',
              'audio/mpeg',
              'audio/ogg',
              'audio/aac',
              'audio/x-m4a',
            ]),
          ]);
      }
    } else if (interface == 'org.mpris.MediaPlayer2.Player') {
      switch (name) {
        case 'PlaybackStatus':
          return DBusMethodSuccessResponse([DBusString(_playbackStatus)]);
        case 'LoopStatus':
          return DBusMethodSuccessResponse([const DBusString('None')]);
        case 'Rate':
          return DBusMethodSuccessResponse([const DBusDouble(1.0)]);
        case 'Shuffle':
          return DBusMethodSuccessResponse([const DBusBoolean(false)]);
        case 'Metadata':
          return DBusMethodSuccessResponse([_buildMetadataVariant()]);
        case 'Volume':
          return DBusMethodSuccessResponse([DBusDouble(_volume)]);
        case 'Position':
          return DBusMethodSuccessResponse([DBusInt64(_position.inMicroseconds)]);
        case 'MinimumRate':
          return DBusMethodSuccessResponse([const DBusDouble(1.0)]);
        case 'MaximumRate':
          return DBusMethodSuccessResponse([const DBusDouble(1.0)]);
        case 'CanControl':
        case 'CanPlay':
        case 'CanPause':
        case 'CanSeek':
        case 'CanGoNext':
        case 'CanGoPrevious':
          return DBusMethodSuccessResponse([const DBusBoolean(true)]);
      }
    }
    return DBusMethodErrorResponse.unknownProperty();
  }

  @override
  Future<DBusMethodResponse> setProperty(
    String interface,
    String name,
    DBusValue value,
  ) async {
    if (interface == 'org.mpris.MediaPlayer2.Player' && name == 'Volume') {
      if (value is DBusDouble) {
        _volume = value.value.clamp(0.0, 1.0);
        _service.onSetVolume?.call(_volume);
        return DBusMethodSuccessResponse();
      }
    }
    return DBusMethodErrorResponse.propertyReadOnly();
  }
}
