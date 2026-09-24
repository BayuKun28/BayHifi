import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../audio_engine/soloud_controller.dart';
import '../../domain/playback_state.dart';
import '../../domain/track.dart';

final playerControllerProvider =
    StateNotifierProvider<PlayerController, PlaybackState>((ref) {
  return PlayerController(SoLoudController.instance);
});

class PlayerController extends StateNotifier<PlaybackState> {
  final SoLoudController _audioEngine;
  StreamSubscription<Duration>? _posSub;

  PlayerController(this._audioEngine) : super(const PlaybackState()) {
    _initListener();
  }

  void _initListener() {
    _posSub = _audioEngine.positionStream.listen((pos) {
      if (state.isPlaying) {
        state = state.copyWith(
          position: pos,
          duration: _audioEngine.duration,
        );
      }
    });
  }

  /// Memutar objek Track (bisa file lokal atau remote url)
  Future<void> playTrack(Track track) async {
    state = state.copyWith(
      status: PlaybackStatus.loading,
      currentTrack: track,
      errorMessage: null,
    );

    try {
      if (track.filePath != null && track.filePath!.isNotEmpty) {
        await _audioEngine.playFile(track.filePath!);
      } else if (track.remoteUrl != null && track.remoteUrl!.isNotEmpty) {
        await _audioEngine.playUrl(track.remoteUrl!);
      } else {
        throw ArgumentError('Track tidak memiliki filePath maupun remoteUrl valid');
      }

      state = state.copyWith(
        status: PlaybackStatus.playing,
        duration: _audioEngine.duration,
        position: Duration.zero,
      );
    } catch (e) {
      state = state.copyWith(
        status: PlaybackStatus.error,
        errorMessage: 'Gagal memutar track: $e',
      );
    }
  }

  /// Toggle play / pause
  void togglePlayPause() {
    if (state.isPlaying) {
      pause();
    } else if (state.isPaused) {
      resume();
    }
  }

  void pause() {
    _audioEngine.pause();
    state = state.copyWith(status: PlaybackStatus.paused);
  }

  void resume() {
    _audioEngine.resume();
    state = state.copyWith(status: PlaybackStatus.playing);
  }

  Future<void> stop() async {
    await _audioEngine.stop();
    state = state.copyWith(
      status: PlaybackStatus.stopped,
      position: Duration.zero,
    );
  }

  void seek(Duration position) {
    _audioEngine.seek(position);
    state = state.copyWith(position: position);
  }

  void setVolume(double volume) {
    _audioEngine.setVolume(volume);
    state = state.copyWith(volume: volume);
  }

  void setPreamp(double preampDb) {
    _audioEngine.setPreamp(preampDb);
    state = state.copyWith(preAmpDb: preampDb);
  }

  void toggleLoop() {
    final next = !state.isLooping;
    state = state.copyWith(isLooping: next);
  }

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }
}
