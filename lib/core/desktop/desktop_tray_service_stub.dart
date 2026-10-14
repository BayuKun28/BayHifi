import 'package:flutter/foundation.dart';
import '../../features/player/domain/track.dart';

/// Web/Stub implementation of DesktopTrayService with zero FFI / native dependencies.
class DesktopTrayService {
  static DesktopTrayService? _instance;
  static DesktopTrayService get instance => _instance ??= DesktopTrayService._();

  DesktopTrayService._();

  bool get isInitialized => false;

  VoidCallback? onPlay;
  VoidCallback? onPause;
  VoidCallback? onPlayPause;
  VoidCallback? onNext;
  VoidCallback? onPrevious;
  VoidCallback? onToggleMute;
  void Function(double volume)? onSetVolume;
  VoidCallback? onToggleDspRack;
  VoidCallback? onOpenAutoEq;
  VoidCallback? onQuit;

  Future<void> init() async {}

  Future<void> updatePlaybackState({
    Track? currentTrack,
    required bool isPlaying,
    required double volume,
    bool isMuted = false,
    String? dspPresetName,
    String? autoEqTarget,
    bool isDspActive = false,
  }) async {}

  Future<void> updateTrayMenu() async {}

  Future<void> toggleWindowVisibility() async {}

  Future<void> quitApplication() async {}

  Future<void> dispose() async {}
}
