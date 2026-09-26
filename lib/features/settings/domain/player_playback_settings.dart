import 'package:flutter/foundation.dart';

enum ReplayGainMode {
  off('Off', 'No loudness normalization applied'),
  track('Track Gain', 'Normalizes each track individually to -18 LUFS (89 dB SPL)'),
  album('Album Gain', 'Preserves album dynamics while adjusting overall album volume');

  final String label;
  final String description;
  const ReplayGainMode(this.label, this.description);

  static ReplayGainMode fromString(String? val) {
    for (final m in ReplayGainMode.values) {
      if (m.name == val) return m;
    }
    return ReplayGainMode.track;
  }
}

enum SeekStepMode {
  constantSeconds('Constant Seconds', 'Fixed step duration (e.g. 5s, 10s, 15s, 30s)'),
  percentage('Percentage', 'Relative percentage of track duration (e.g. 2%, 5%, 10%)');

  final String label;
  final String description;
  const SeekStepMode(this.label, this.description);

  static SeekStepMode fromString(String? val) {
    for (final s in SeekStepMode.values) {
      if (s.name == val) return s;
    }
    return SeekStepMode.constantSeconds;
  }
}

enum TimeDisplayMode {
  remaining('Remaining Time', 'Shows negative countdown time until track ends (-mm:ss)'),
  total('Total Duration', 'Shows total elapsed duration of the track (mm:ss)');

  final String label;
  final String description;
  const TimeDisplayMode(this.label, this.description);

  static TimeDisplayMode fromString(String? val) {
    for (final t in TimeDisplayMode.values) {
      if (t.name == val) return t;
    }
    return TimeDisplayMode.remaining;
  }
}

@immutable
class PlayerPlaybackSettings {
  // 16.1 Smooth Play/Pause Volume Fade Engine
  final bool enableSmoothFade;
  final int fadeInDurationMs; // 100ms - 1500ms
  final int fadeOutDurationMs; // 100ms - 1500ms

  // 16.2 Audio Device Interruption & Headphone Unplug Manager
  final bool pauseOnHeadphoneUnplug;
  final bool resumeOnHeadphonePlug;
  final int headphoneReconnectTimeoutSec; // 3s - 60s
  final bool pauseOnZeroVolume;

  // 16.3 Speed & Pitch Semitone Engine
  final double playbackSpeed; // 0.25x - 3.0x
  final double pitchSemitones; // -12.0 to +12.0
  final double pitchFineCents; // -50.0 to +50.0
  final bool linkSpeedAndPitch; // Link pitch with playback speed

  // 16.4 ReplayGain Normalization & Skip Silence Engine
  final ReplayGainMode replayGainMode;
  final double replayGainPreampDb; // -12.0 dB to +12.0 dB
  final bool replayGainPreventClipping;
  final bool enableSkipSilence;
  final double silenceThresholdDb; // -70.0 dB to -40.0 dB

  // 16.5 Custom Seek Stepper & Time Display Modes
  final SeekStepMode seekStepMode;
  final int seekStepSeconds; // 5s to 60s
  final double seekStepPercent; // 0.01 to 0.20 (1% to 20%)
  final TimeDisplayMode timeDisplayMode;

  const PlayerPlaybackSettings({
    this.enableSmoothFade = true,
    this.fadeInDurationMs = 300,
    this.fadeOutDurationMs = 300,
    this.pauseOnHeadphoneUnplug = true,
    this.resumeOnHeadphonePlug = true,
    this.headphoneReconnectTimeoutSec = 10,
    this.pauseOnZeroVolume = true,
    this.playbackSpeed = 1.0,
    this.pitchSemitones = 0.0,
    this.pitchFineCents = 0.0,
    this.linkSpeedAndPitch = false,
    this.replayGainMode = ReplayGainMode.track,
    this.replayGainPreampDb = 0.0,
    this.replayGainPreventClipping = true,
    this.enableSkipSilence = false,
    this.silenceThresholdDb = -55.0,
    this.seekStepMode = SeekStepMode.constantSeconds,
    this.seekStepSeconds = 10,
    this.seekStepPercent = 0.05,
    this.timeDisplayMode = TimeDisplayMode.remaining,
  });

  PlayerPlaybackSettings copyWith({
    bool? enableSmoothFade,
    int? fadeInDurationMs,
    int? fadeOutDurationMs,
    bool? pauseOnHeadphoneUnplug,
    bool? resumeOnHeadphonePlug,
    int? headphoneReconnectTimeoutSec,
    bool? pauseOnZeroVolume,
    double? playbackSpeed,
    double? pitchSemitones,
    double? pitchFineCents,
    bool? linkSpeedAndPitch,
    ReplayGainMode? replayGainMode,
    double? replayGainPreampDb,
    bool? replayGainPreventClipping,
    bool? enableSkipSilence,
    double? silenceThresholdDb,
    SeekStepMode? seekStepMode,
    int? seekStepSeconds,
    double? seekStepPercent,
    TimeDisplayMode? timeDisplayMode,
  }) {
    return PlayerPlaybackSettings(
      enableSmoothFade: enableSmoothFade ?? this.enableSmoothFade,
      fadeInDurationMs: fadeInDurationMs ?? this.fadeInDurationMs,
      fadeOutDurationMs: fadeOutDurationMs ?? this.fadeOutDurationMs,
      pauseOnHeadphoneUnplug: pauseOnHeadphoneUnplug ?? this.pauseOnHeadphoneUnplug,
      resumeOnHeadphonePlug: resumeOnHeadphonePlug ?? this.resumeOnHeadphonePlug,
      headphoneReconnectTimeoutSec: headphoneReconnectTimeoutSec ?? this.headphoneReconnectTimeoutSec,
      pauseOnZeroVolume: pauseOnZeroVolume ?? this.pauseOnZeroVolume,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      pitchSemitones: pitchSemitones ?? this.pitchSemitones,
      pitchFineCents: pitchFineCents ?? this.pitchFineCents,
      linkSpeedAndPitch: linkSpeedAndPitch ?? this.linkSpeedAndPitch,
      replayGainMode: replayGainMode ?? this.replayGainMode,
      replayGainPreampDb: replayGainPreampDb ?? this.replayGainPreampDb,
      replayGainPreventClipping: replayGainPreventClipping ?? this.replayGainPreventClipping,
      enableSkipSilence: enableSkipSilence ?? this.enableSkipSilence,
      silenceThresholdDb: silenceThresholdDb ?? this.silenceThresholdDb,
      seekStepMode: seekStepMode ?? this.seekStepMode,
      seekStepSeconds: seekStepSeconds ?? this.seekStepSeconds,
      seekStepPercent: seekStepPercent ?? this.seekStepPercent,
      timeDisplayMode: timeDisplayMode ?? this.timeDisplayMode,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enableSmoothFade': enableSmoothFade,
      'fadeInDurationMs': fadeInDurationMs,
      'fadeOutDurationMs': fadeOutDurationMs,
      'pauseOnHeadphoneUnplug': pauseOnHeadphoneUnplug,
      'resumeOnHeadphonePlug': resumeOnHeadphonePlug,
      'headphoneReconnectTimeoutSec': headphoneReconnectTimeoutSec,
      'pauseOnZeroVolume': pauseOnZeroVolume,
      'playbackSpeed': playbackSpeed,
      'pitchSemitones': pitchSemitones,
      'pitchFineCents': pitchFineCents,
      'linkSpeedAndPitch': linkSpeedAndPitch,
      'replayGainMode': replayGainMode.name,
      'replayGainPreampDb': replayGainPreampDb,
      'replayGainPreventClipping': replayGainPreventClipping,
      'enableSkipSilence': enableSkipSilence,
      'silenceThresholdDb': silenceThresholdDb,
      'seekStepMode': seekStepMode.name,
      'seekStepSeconds': seekStepSeconds,
      'seekStepPercent': seekStepPercent,
      'timeDisplayMode': timeDisplayMode.name,
    };
  }

  factory PlayerPlaybackSettings.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const PlayerPlaybackSettings();
    return PlayerPlaybackSettings(
      enableSmoothFade: map['enableSmoothFade'] as bool? ?? true,
      fadeInDurationMs: (map['fadeInDurationMs'] as num?)?.toInt() ?? 300,
      fadeOutDurationMs: (map['fadeOutDurationMs'] as num?)?.toInt() ?? 300,
      pauseOnHeadphoneUnplug: map['pauseOnHeadphoneUnplug'] as bool? ?? true,
      resumeOnHeadphonePlug: map['resumeOnHeadphonePlug'] as bool? ?? true,
      headphoneReconnectTimeoutSec: (map['headphoneReconnectTimeoutSec'] as num?)?.toInt() ?? 10,
      pauseOnZeroVolume: map['pauseOnZeroVolume'] as bool? ?? true,
      playbackSpeed: (map['playbackSpeed'] as num?)?.toDouble() ?? 1.0,
      pitchSemitones: (map['pitchSemitones'] as num?)?.toDouble() ?? 0.0,
      pitchFineCents: (map['pitchFineCents'] as num?)?.toDouble() ?? 0.0,
      linkSpeedAndPitch: map['linkSpeedAndPitch'] as bool? ?? false,
      replayGainMode: ReplayGainMode.fromString(map['replayGainMode'] as String?),
      replayGainPreampDb: (map['replayGainPreampDb'] as num?)?.toDouble() ?? 0.0,
      replayGainPreventClipping: map['replayGainPreventClipping'] as bool? ?? true,
      enableSkipSilence: map['enableSkipSilence'] as bool? ?? false,
      silenceThresholdDb: (map['silenceThresholdDb'] as num?)?.toDouble() ?? -55.0,
      seekStepMode: SeekStepMode.fromString(map['seekStepMode'] as String?),
      seekStepSeconds: (map['seekStepSeconds'] as num?)?.toInt() ?? 10,
      seekStepPercent: (map['seekStepPercent'] as num?)?.toDouble() ?? 0.05,
      timeDisplayMode: TimeDisplayMode.fromString(map['timeDisplayMode'] as String?),
    );
  }
}
