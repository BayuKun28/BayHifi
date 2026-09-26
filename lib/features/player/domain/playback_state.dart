import 'package:flutter/foundation.dart';
import '../../settings/domain/player_playback_settings.dart';
import 'track.dart';

enum PlaybackStatus {
  idle,
  loading,
  playing,
  paused,
  stopped,
  error,
}

enum PlaybackRepeatMode {
  off,
  all,
  one,
}

@immutable
class PlaybackState {
  final PlaybackStatus status;
  final Track? currentTrack;
  final List<Track> queue;
  final List<Track> originalQueue;
  final int queueIndex;
  final bool isShuffle;
  final PlaybackRepeatMode repeatMode;
  final Duration position;
  final Duration duration;
  final double volume;
  final double preAmpDb;
  final bool isMuted;
  final bool isLooping;
  final String? errorMessage;

  // Fase 16: Advanced Playback Engine properties
  final double playbackSpeed;
  final double pitchSemitones;
  final double pitchFineCents;
  final bool linkSpeedAndPitch;
  final double effectiveReplayGainDb;
  final TimeDisplayMode timeDisplayMode;

  const PlaybackState({
    this.status = PlaybackStatus.idle,
    this.currentTrack,
    this.queue = const [],
    this.originalQueue = const [],
    this.queueIndex = 0,
    this.isShuffle = false,
    this.repeatMode = PlaybackRepeatMode.off,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 1.0,
    this.preAmpDb = 0.0,
    this.isMuted = false,
    this.isLooping = false,
    this.errorMessage,
    this.playbackSpeed = 1.0,
    this.pitchSemitones = 0.0,
    this.pitchFineCents = 0.0,
    this.linkSpeedAndPitch = false,
    this.effectiveReplayGainDb = 0.0,
    this.timeDisplayMode = TimeDisplayMode.remaining,
  });

  bool get isPlaying => status == PlaybackStatus.playing;
  bool get isPaused => status == PlaybackStatus.paused;
  bool get hasQueue => queue.isNotEmpty;
  bool get hasNext => queue.isNotEmpty && (queueIndex < queue.length - 1 || repeatMode == PlaybackRepeatMode.all);
  bool get hasPrevious => queue.isNotEmpty && (queueIndex > 0 || position.inSeconds > 3);

  PlaybackState copyWith({
    PlaybackStatus? status,
    Track? currentTrack,
    List<Track>? queue,
    List<Track>? originalQueue,
    int? queueIndex,
    bool? isShuffle,
    PlaybackRepeatMode? repeatMode,
    Duration? position,
    Duration? duration,
    double? volume,
    double? preAmpDb,
    bool? isMuted,
    bool? isLooping,
    String? errorMessage,
    double? playbackSpeed,
    double? pitchSemitones,
    double? pitchFineCents,
    bool? linkSpeedAndPitch,
    double? effectiveReplayGainDb,
    TimeDisplayMode? timeDisplayMode,
  }) {
    return PlaybackState(
      status: status ?? this.status,
      currentTrack: currentTrack ?? this.currentTrack,
      queue: queue ?? this.queue,
      originalQueue: originalQueue ?? this.originalQueue,
      queueIndex: queueIndex ?? this.queueIndex,
      isShuffle: isShuffle ?? this.isShuffle,
      repeatMode: repeatMode ?? this.repeatMode,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      preAmpDb: preAmpDb ?? this.preAmpDb,
      isMuted: isMuted ?? this.isMuted,
      isLooping: isLooping ?? this.isLooping,
      errorMessage: errorMessage ?? this.errorMessage,
      playbackSpeed: playbackSpeed ?? this.playbackSpeed,
      pitchSemitones: pitchSemitones ?? this.pitchSemitones,
      pitchFineCents: pitchFineCents ?? this.pitchFineCents,
      linkSpeedAndPitch: linkSpeedAndPitch ?? this.linkSpeedAndPitch,
      effectiveReplayGainDb: effectiveReplayGainDb ?? this.effectiveReplayGainDb,
      timeDisplayMode: timeDisplayMode ?? this.timeDisplayMode,
    );
  }
}
