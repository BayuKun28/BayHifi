import 'dart:async';
import 'dart:io';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/foundation.dart';
import '../../features/player/domain/track.dart';

/// Background AudioService Handler for Baydev HiFi
/// Synchronizes playback state and metadata with the Android notification panel & lockscreen.
class BaydevAudioHandler extends BaseAudioHandler with SeekHandler, QueueHandler {
  static BaydevAudioHandler? _instance;
  static BaydevAudioHandler get instance => _instance ??= BaydevAudioHandler._internal();

  VoidCallback? onPlayCallback;
  VoidCallback? onPauseCallback;
  VoidCallback? onSkipNextCallback;
  VoidCallback? onSkipPreviousCallback;
  Future<void> Function(Duration)? onSeekCallback;
  VoidCallback? onStopCallback;

  BaydevAudioHandler._internal() {
    _initInitialState();
  }

  factory BaydevAudioHandler() => instance;

  void _initInitialState() {
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
          MediaAction.setShuffleMode,
          MediaAction.setRepeatMode,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: AudioProcessingState.idle,
        playing: false,
        updatePosition: Duration.zero,
        bufferedPosition: Duration.zero,
        speed: 1.0,
      ),
    );
  }

  /// Synchronize app state to Android status bar notification panel
  void syncPlaybackState({
    required Track? currentTrack,
    required bool isPlaying,
    required Duration position,
    required Duration duration,
    List<Track> currentQueue = const [],
    int currentQueueIndex = 0,
  }) {
    // 1. Update MediaItem (Title, Artist, Album, Art)
    if (currentTrack != null) {
      Uri? artUri;
      if (currentTrack.albumArtUrl != null && currentTrack.albumArtUrl!.isNotEmpty) {
        final art = currentTrack.albumArtUrl!;
        if (art.startsWith('http://') || art.startsWith('https://')) {
          artUri = Uri.tryParse(art);
        } else {
          final file = File(art);
          if (file.existsSync()) {
            artUri = Uri.file(art);
          }
        }
      }

      final item = MediaItem(
        id: currentTrack.id,
        album: currentTrack.album,
        title: currentTrack.title,
        artist: currentTrack.artist,
        duration: duration > Duration.zero ? duration : currentTrack.duration,
        artUri: artUri,
        extras: {
          'isHiRes': currentTrack.isHiRes,
          'bitDepth': currentTrack.bitDepth,
          'sampleRate': currentTrack.sampleRate,
        },
      );

      if (mediaItem.value?.id != item.id ||
          mediaItem.value?.duration != item.duration ||
          mediaItem.value?.title != item.title) {
        mediaItem.add(item);
      }
    } else {
      mediaItem.add(null);
    }

    // 2. Update Queue
    if (currentQueue.isNotEmpty) {
      final mediaQueue = currentQueue.map((t) {
        return MediaItem(
          id: t.id,
          album: t.album,
          title: t.title,
          artist: t.artist,
          duration: t.duration,
        );
      }).toList();
      queue.add(mediaQueue);
    }

    // 3. Update PlaybackState (Buttons, Position, Playing)
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.skipToPrevious,
          if (isPlaying) MediaControl.pause else MediaControl.play,
          MediaControl.skipToNext,
          MediaControl.stop,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: currentTrack != null
            ? AudioProcessingState.ready
            : AudioProcessingState.idle,
        playing: isPlaying,
        updatePosition: position,
        bufferedPosition: duration,
        speed: 1.0,
        queueIndex: currentQueueIndex,
      ),
    );
  }

  @override
  Future<void> play() async {
    debugPrint('[BaydevAudioHandler] play() requested from system');
    onPlayCallback?.call();
  }

  @override
  Future<void> pause() async {
    debugPrint('[BaydevAudioHandler] pause() requested from system');
    onPauseCallback?.call();
  }

  @override
  Future<void> skipToNext() async {
    debugPrint('[BaydevAudioHandler] skipToNext() requested from system');
    onSkipNextCallback?.call();
  }

  @override
  Future<void> skipToPrevious() async {
    debugPrint('[BaydevAudioHandler] skipToPrevious() requested from system');
    onSkipPreviousCallback?.call();
  }

  @override
  Future<void> seek(Duration position) async {
    debugPrint('[BaydevAudioHandler] seek($position) requested from system');
    if (onSeekCallback != null) {
      await onSeekCallback!(position);
    }
  }

  @override
  Future<void> stop() async {
    debugPrint('[BaydevAudioHandler] stop() requested from system');
    onStopCallback?.call();
    await super.stop();
  }
}
