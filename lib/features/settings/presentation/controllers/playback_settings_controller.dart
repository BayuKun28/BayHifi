import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/local_persistence_service.dart';
import '../../domain/player_playback_settings.dart';

final playbackSettingsProvider =
    StateNotifierProvider<PlaybackSettingsController, PlayerPlaybackSettings>((ref) {
  return PlaybackSettingsController();
});

class PlaybackSettingsController extends StateNotifier<PlayerPlaybackSettings> {
  static const String _storageKey = 'player_playback_settings';

  PlaybackSettingsController() : super(const PlayerPlaybackSettings()) {
    _loadSettings();
  }

  void _loadSettings() {
    try {
      final db = LocalPersistenceService.instance;
      final saved = db.getSetting<Map<String, dynamic>>(_storageKey);
      if (saved != null) {
        state = PlayerPlaybackSettings.fromMap(saved);
      }
    } catch (e) {
      debugPrint('[PlaybackSettingsController] Error loading settings: $e');
    }
  }

  void _saveSettings() {
    try {
      final db = LocalPersistenceService.instance;
      db.saveSetting(_storageKey, state.toMap());
    } catch (e) {
      debugPrint('[PlaybackSettingsController] Error saving settings: $e');
    }
  }

  void toggleSmoothFade([bool? value]) {
    state = state.copyWith(enableSmoothFade: value ?? !state.enableSmoothFade);
    _saveSettings();
  }

  void setFadeInDurationMs(int ms) {
    state = state.copyWith(fadeInDurationMs: ms.clamp(100, 1500));
    _saveSettings();
  }

  void setFadeOutDurationMs(int ms) {
    state = state.copyWith(fadeOutDurationMs: ms.clamp(100, 1500));
    _saveSettings();
  }

  void togglePauseOnHeadphoneUnplug([bool? value]) {
    state = state.copyWith(pauseOnHeadphoneUnplug: value ?? !state.pauseOnHeadphoneUnplug);
    _saveSettings();
  }

  void toggleResumeOnHeadphonePlug([bool? value]) {
    state = state.copyWith(resumeOnHeadphonePlug: value ?? !state.resumeOnHeadphonePlug);
    _saveSettings();
  }

  void setHeadphoneReconnectTimeoutSec(int sec) {
    state = state.copyWith(headphoneReconnectTimeoutSec: sec.clamp(3, 60));
    _saveSettings();
  }

  void togglePauseOnZeroVolume([bool? value]) {
    state = state.copyWith(pauseOnZeroVolume: value ?? !state.pauseOnZeroVolume);
    _saveSettings();
  }

  void setPlaybackSpeed(double speed) {
    state = state.copyWith(playbackSpeed: speed.clamp(0.25, 3.0));
    _saveSettings();
  }

  void setPitchSemitones(double semitones) {
    state = state.copyWith(pitchSemitones: semitones.clamp(-12.0, 12.0));
    _saveSettings();
  }

  void setPitchFineCents(double cents) {
    state = state.copyWith(pitchFineCents: cents.clamp(-50.0, 50.0));
    _saveSettings();
  }

  void toggleLinkSpeedAndPitch([bool? value]) {
    state = state.copyWith(linkSpeedAndPitch: value ?? !state.linkSpeedAndPitch);
    _saveSettings();
  }

  void setReplayGainMode(ReplayGainMode mode) {
    state = state.copyWith(replayGainMode: mode);
    _saveSettings();
  }

  void setReplayGainPreampDb(double db) {
    state = state.copyWith(replayGainPreampDb: db.clamp(-12.0, 12.0));
    _saveSettings();
  }

  void toggleReplayGainPreventClipping([bool? value]) {
    state = state.copyWith(replayGainPreventClipping: value ?? !state.replayGainPreventClipping);
    _saveSettings();
  }

  void toggleEnableSkipSilence([bool? value]) {
    state = state.copyWith(enableSkipSilence: value ?? !state.enableSkipSilence);
    _saveSettings();
  }

  void setSilenceThresholdDb(double db) {
    state = state.copyWith(silenceThresholdDb: db.clamp(-70.0, -40.0));
    _saveSettings();
  }

  void setSeekStepMode(SeekStepMode mode) {
    state = state.copyWith(seekStepMode: mode);
    _saveSettings();
  }

  void setSeekStepSeconds(int seconds) {
    state = state.copyWith(seekStepSeconds: seconds.clamp(5, 60));
    _saveSettings();
  }

  void setSeekStepPercent(double percent) {
    state = state.copyWith(seekStepPercent: percent.clamp(0.01, 0.20));
    _saveSettings();
  }

  void toggleTimeDisplayMode() {
    final next = state.timeDisplayMode == TimeDisplayMode.remaining
        ? TimeDisplayMode.total
        : TimeDisplayMode.remaining;
    state = state.copyWith(timeDisplayMode: next);
    _saveSettings();
  }

  void setTimeDisplayMode(TimeDisplayMode mode) {
    state = state.copyWith(timeDisplayMode: mode);
    _saveSettings();
  }

  void resetToDefaults() {
    state = const PlayerPlaybackSettings();
    _saveSettings();
  }
}
