import 'package:flutter/foundation.dart';
import 'track.dart';

enum PlaybackStatus {
  idle,
  loading,
  playing,
  paused,
  stopped,
  error,
}

@immutable
class PlaybackState {
  final PlaybackStatus status;
  final Track? currentTrack;
  final Duration position;
  final Duration duration;
  final double volume;
  final double preAmpDb;
  final bool isMuted;
  final bool isLooping;
  final String? errorMessage;

  const PlaybackState({
    this.status = PlaybackStatus.idle,
    this.currentTrack,
    this.position = Duration.zero,
    this.duration = Duration.zero,
    this.volume = 1.0,
    this.preAmpDb = 0.0,
    this.isMuted = false,
    this.isLooping = false,
    this.errorMessage,
  });

  bool get isPlaying => status == PlaybackStatus.playing;
  bool get isPaused => status == PlaybackStatus.paused;

  PlaybackState copyWith({
    PlaybackStatus? status,
    Track? currentTrack,
    Duration? position,
    Duration? duration,
    double? volume,
    double? preAmpDb,
    bool? isMuted,
    bool? isLooping,
    String? errorMessage,
  }) {
    return PlaybackState(
      status: status ?? this.status,
      currentTrack: currentTrack ?? this.currentTrack,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      preAmpDb: preAmpDb ?? this.preAmpDb,
      isMuted: isMuted ?? this.isMuted,
      isLooping: isLooping ?? this.isLooping,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
