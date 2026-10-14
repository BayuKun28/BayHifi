import 'package:flutter/foundation.dart';
import '../../features/player/domain/track.dart';

/// Web/Stub implementation of LinuxMprisService with zero D-Bus native dependencies.
class LinuxMprisService {
  static LinuxMprisService? _instance;
  static LinuxMprisService get instance => _instance ??= LinuxMprisService._();

  LinuxMprisService._();

  bool get isInitialized => false;

  VoidCallback? onPlay;
  VoidCallback? onPause;
  VoidCallback? onPlayPause;
  VoidCallback? onNext;
  VoidCallback? onPrevious;
  VoidCallback? onStop;
  VoidCallback? onRaise;
  void Function(Duration position)? onSeek;
  void Function(double volume)? onSetVolume;

  Future<void> init() async {}

  void updateTrack(Track? track, Duration duration) {}

  void updatePlaybackState({
    required bool isPlaying,
    required Duration position,
    required Duration duration,
    double volume = 1.0,
  }) {}

  Future<void> dispose() async {}
}
