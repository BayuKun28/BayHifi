import 'package:flutter/foundation.dart';

/// Manajer Kebijakan Interupsi Audio & Pencopotan Headphone / DAC (Namida Flow)
class AudioInterruptionManager {
  AudioInterruptionManager._();
  static final AudioInterruptionManager instance = AudioInterruptionManager._();

  DateTime? _unpluggedAt;
  bool _wasPlayingBeforeUnplug = false;

  bool get wasPlayingBeforeUnplug => _wasPlayingBeforeUnplug;
  DateTime? get unpluggedAt => _unpluggedAt;

  /// Dipanggil saat headphone, DAC USB, atau Bluetooth terputus/dicopot
  void handleHeadphoneUnplugged({
    required bool isCurrentlyPlaying,
    required VoidCallback onPause,
    bool pauseEnabled = true,
  }) {
    if (!pauseEnabled) return;

    if (isCurrentlyPlaying) {
      _wasPlayingBeforeUnplug = true;
      _unpluggedAt = DateTime.now();
      debugPrint('[AudioInterruption] Headphone unplugged during active playback. Pausing.');
      onPause();
    } else {
      _wasPlayingBeforeUnplug = false;
      _unpluggedAt = null;
    }
  }

  /// Dipanggil saat headphone, DAC USB, atau Bluetooth tersambung kembali
  void handleHeadphonePlugged({
    required VoidCallback onResume,
    bool resumeEnabled = true,
    int timeoutSeconds = 10,
  }) {
    if (!resumeEnabled || !_wasPlayingBeforeUnplug || _unpluggedAt == null) {
      resetInterruptionState();
      return;
    }

    final elapsedSeconds = DateTime.now().difference(_unpluggedAt!).inSeconds;
    if (elapsedSeconds <= timeoutSeconds) {
      debugPrint('[AudioInterruption] Reconnected within ${elapsedSeconds}s (timeout: ${timeoutSeconds}s). Resuming.');
      resetInterruptionState();
      onResume();
    } else {
      debugPrint('[AudioInterruption] Reconnected after ${elapsedSeconds}s (> ${timeoutSeconds}s). Ignoring resume.');
      resetInterruptionState();
    }
  }

  /// Dipanggil saat volume sistem / perangkat bernilai 0
  void handleVolumeChanged({
    required double volume,
    required bool isCurrentlyPlaying,
    required VoidCallback onPause,
    bool pauseOnZeroEnabled = true,
  }) {
    if (!pauseOnZeroEnabled) return;

    if (volume <= 0.001 && isCurrentlyPlaying) {
      debugPrint('[AudioInterruption] System volume set to 0 during playback. Auto-pausing.');
      onPause();
    }
  }

  void resetInterruptionState() {
    _wasPlayingBeforeUnplug = false;
    _unpluggedAt = null;
  }
}
