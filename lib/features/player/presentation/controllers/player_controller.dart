import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import '../../../../audio_engine/audio_cache_service.dart';
import '../../../../audio_engine/soloud_controller.dart';
import '../../../../core/audio_engine/audio_interruption_manager.dart';
import '../../../../core/audio_engine/replay_gain_service.dart';
import '../../../../core/audio_service/baydev_audio_handler.dart';
import '../../../../core/database/local_persistence_service.dart';
import '../../../../core/desktop/linux_mpris_service.dart';
import '../../../settings/domain/player_playback_settings.dart';
import '../../../settings/presentation/controllers/playback_settings_controller.dart';
import '../../domain/playback_state.dart';
import '../../domain/track.dart';
import '../../../youtube_music/data/youtube_music_service.dart';

final playerControllerProvider =
    StateNotifierProvider<PlayerController, PlaybackState>((ref) {
  final controller = PlayerController(SoLoudController.instance);
  ref.listen<PlayerPlaybackSettings>(playbackSettingsProvider, (_, next) {
    controller.updatePlaybackSettings(next);
  });
  return controller;
});

class PlayerController extends StateNotifier<PlaybackState> {
  final SoLoudController _audioEngine;
  StreamSubscription<Duration>? _posSub;
  bool _isAdvancing = false;
  PlayerPlaybackSettings _playbackSettings = const PlayerPlaybackSettings();

  PlayerController(this._audioEngine) : super(const PlaybackState()) {
    _loadPlaybackSettings();
    _initListener();
    _initAudioServiceCallbacks();
    _restoreSession();
  }

  void _loadPlaybackSettings() {
    try {
      final db = LocalPersistenceService.instance;
      final saved = db.getSetting<Map<String, dynamic>>('player_playback_settings');
      if (saved != null) {
        _playbackSettings = PlayerPlaybackSettings.fromMap(saved);
        state = state.copyWith(
          playbackSpeed: _playbackSettings.playbackSpeed,
          pitchSemitones: _playbackSettings.pitchSemitones,
          pitchFineCents: _playbackSettings.pitchFineCents,
          linkSpeedAndPitch: _playbackSettings.linkSpeedAndPitch,
          timeDisplayMode: _playbackSettings.timeDisplayMode,
        );
      }
    } catch (e) {
      debugPrint('[PlayerController] Error loading playback settings: $e');
    }
  }

  void updatePlaybackSettings(PlayerPlaybackSettings settings) {
    _playbackSettings = settings;
    state = state.copyWith(
      playbackSpeed: settings.playbackSpeed,
      pitchSemitones: settings.pitchSemitones,
      pitchFineCents: settings.pitchFineCents,
      linkSpeedAndPitch: settings.linkSpeedAndPitch,
      timeDisplayMode: settings.timeDisplayMode,
    );
    _audioEngine.setPlaybackSpeed(settings.playbackSpeed);
    _applyPitchAndSpeedCoupling();
    if (state.currentTrack != null) {
      final rgDb = ReplayGainService.instance.calculateEffectiveGainDb(
        track: state.currentTrack,
        mode: settings.replayGainMode,
        preampDb: settings.replayGainPreampDb,
        preventClipping: settings.replayGainPreventClipping,
      );
      _audioEngine.setReplayGainDb(rgDb);
      state = state.copyWith(effectiveReplayGainDb: rgDb);
    }
  }

  void _initAudioServiceCallbacks() {
    try {
      final handler = BaydevAudioHandler.instance;
      handler.onPlayCallback = () => resume();
      handler.onPauseCallback = () => pause();
      handler.onSkipNextCallback = () => skipNext();
      handler.onSkipPreviousCallback = () => skipPrevious();
      handler.onSeekCallback = (pos) async => seek(pos);
      handler.onStopCallback = () => stop();

      if (!kIsWeb && Platform.isLinux) {
        final mpris = LinuxMprisService.instance;
        mpris.onPlay = () => resume();
        mpris.onPause = () => pause();
        mpris.onPlayPause = () => togglePlayPause();
        mpris.onNext = () => skipNext();
        mpris.onPrevious = () => skipPrevious();
        mpris.onStop = () => stop();
        mpris.onSeek = (pos) => seek(pos);
        mpris.onSetVolume = (vol) => setVolume(vol);
      }
    } catch (e) {
      debugPrint('[PlayerController] AudioHandler callback init error: $e');
    }
  }

  void _syncAudioHandler() {
    try {
      BaydevAudioHandler.instance.syncPlaybackState(
        currentTrack: state.currentTrack,
        isPlaying: state.isPlaying,
        position: state.position,
        duration: state.duration,
        currentQueue: state.queue,
        currentQueueIndex: state.queueIndex,
      );

      if (!kIsWeb && Platform.isLinux) {
        LinuxMprisService.instance.updateTrack(state.currentTrack, state.duration);
        LinuxMprisService.instance.updatePlaybackState(
          isPlaying: state.isPlaying,
          position: state.position,
          duration: state.duration,
          volume: state.volume,
        );
      }
    } catch (e) {
      debugPrint('[PlayerController] Error syncing audio handler: $e');
    }
  }

  void _initListener() {
    _posSub = _audioEngine.positionStream.listen((pos) {
      if (state.isPlaying) {
        final trackDur = state.currentTrack?.duration ?? Duration.zero;
        final engineDur = _audioEngine.duration;
        // The track's duration from metadata / API takes absolute precedence.
        // For buffer streams, _audioEngine.duration only reports momentary decoded buffer size,
        // so it must NEVER overwrite an already known track duration.
        final currentDur = trackDur > Duration.zero
            ? trackDur
            : (state.duration > Duration.zero
                ? state.duration
                : (engineDur > Duration.zero ? engineDur : Duration.zero));

        state = state.copyWith(
          position: pos,
          duration: currentDur,
        );
        _syncAudioHandler();

        // Check if track has finished playing
        if (currentDur > Duration.zero &&
            pos >= currentDur - const Duration(milliseconds: 350) &&
            !_isAdvancing) {
          _onTrackEnded();
        }
      }
    });
  }

  /// Restore state from the previous session
  Future<void> _restoreSession() async {
    try {
      final db = LocalPersistenceService.instance;
      if (!db.isInitialized) {
        await db.init();
      }

      final session = db.getLastSessionState();
      if (session != null) {
        Track? track;
        if (session['lastTrack'] is Map<String, dynamic>) {
          track = Track.fromMap(session['lastTrack'] as Map<String, dynamic>);
        }

        List<Track> queue = [];
        if (session['queue'] is List) {
          queue = (session['queue'] as List)
              .whereType<Map<String, dynamic>>()
              .map(Track.fromMap)
              .toList();
        }

        List<Track> originalQueue = [];
        if (session['originalQueue'] is List) {
          originalQueue = (session['originalQueue'] as List)
              .whereType<Map<String, dynamic>>()
              .map(Track.fromMap)
              .toList();
        } else if (queue.isNotEmpty) {
          originalQueue = List<Track>.from(queue);
        }

        final queueIdx = (session['queueIndex'] as num?)?.toInt() ?? 0;
        final vol = (session['volume'] as num?)?.toDouble() ?? 1.0;
        final preAmp = (session['preAmpDb'] as num?)?.toDouble() ?? 0.0;
        final isShuffle = session['isShuffle'] as bool? ?? false;
        final repeatStr = session['repeatMode'] as String? ?? 'off';
        final repeatMode = PlaybackRepeatMode.values.firstWhere(
          (e) => e.name == repeatStr,
          orElse: () => PlaybackRepeatMode.off,
        );
        final posMs = (session['positionMs'] as num?)?.toInt() ?? 0;

        _audioEngine.setVolume(vol);
        _audioEngine.setPreamp(preAmp);

        state = state.copyWith(
          currentTrack: track ?? (queue.isNotEmpty ? queue[queueIdx.clamp(0, queue.length - 1)] : null),
          queue: queue,
          originalQueue: originalQueue.isNotEmpty ? originalQueue : queue,
          queueIndex: queue.isNotEmpty ? queueIdx.clamp(0, queue.length - 1) : 0,
          volume: vol,
          preAmpDb: preAmp,
          isShuffle: isShuffle,
          repeatMode: repeatMode,
          position: Duration(milliseconds: posMs),
        );
      }
    } catch (e) {
      debugPrint('[PlayerController] Error restoring session: $e');
    }
  }

  void _saveSession() {
    try {
      final db = LocalPersistenceService.instance;
      if (!db.isInitialized) return;

      db.saveLastSessionState({
        'lastTrack': state.currentTrack?.toMap(),
        'queue': state.queue.map((t) => t.toMap()).toList(),
        'originalQueue': state.originalQueue.map((t) => t.toMap()).toList(),
        'queueIndex': state.queueIndex,
        'volume': state.volume,
        'preAmpDb': state.preAmpDb,
        'isShuffle': state.isShuffle,
        'repeatMode': state.repeatMode.name,
        'positionMs': state.position.inMilliseconds,
      });
    } catch (e) {
      debugPrint('[PlayerController] Error saving session: $e');
    }
  }

  /// Sets a new playback queue and optionally begins playback at [initialIndex]
  Future<void> setQueue(
    List<Track> tracks, {
    int initialIndex = 0,
    bool autoPlay = true,
  }) async {
    if (tracks.isEmpty) return;

    final targetIndex = initialIndex.clamp(0, tracks.length - 1);
    final selectedTrack = tracks[targetIndex];

    if (state.isShuffle && tracks.length > 1) {
      final remaining = tracks.where((t) => t.id != selectedTrack.id).toList();
      remaining.shuffle(math.Random());
      final shuffledQueue = [selectedTrack, ...remaining];

      state = state.copyWith(
        originalQueue: List<Track>.from(tracks),
        queue: shuffledQueue,
        queueIndex: 0,
        currentTrack: selectedTrack,
      );
    } else {
      state = state.copyWith(
        originalQueue: List<Track>.from(tracks),
        queue: List<Track>.from(tracks),
        queueIndex: targetIndex,
        currentTrack: selectedTrack,
      );
    }

    _saveSession();

    if (autoPlay) {
      await playTrack(selectedTrack);
    }
  }

  /// Appends a track to the end of the queue
  void addToQueue(Track track) {
    final updatedQueue = List<Track>.from(state.queue)..add(track);
    final updatedOriginal = List<Track>.from(
      state.originalQueue.isNotEmpty ? state.originalQueue : state.queue,
    )..add(track);
    state = state.copyWith(
      queue: updatedQueue,
      originalQueue: updatedOriginal,
    );
    _saveSession();
  }

  /// Inserts a track directly after the currently playing track
  void playNext(Track track) {
    final updatedQueue = List<Track>.from(state.queue);
    final updatedOriginal = List<Track>.from(
      state.originalQueue.isNotEmpty ? state.originalQueue : state.queue,
    );

    if (state.queue.isEmpty) {
      updatedQueue.add(track);
      updatedOriginal.add(track);
      state = state.copyWith(
        queue: updatedQueue,
        originalQueue: updatedOriginal,
        queueIndex: 0,
      );
    } else {
      final insertIndex = (state.queueIndex + 1).clamp(0, updatedQueue.length);
      updatedQueue.insert(insertIndex, track);

      // Also insert in original queue after current track if found
      final current = state.currentTrack;
      final origIdx = current != null ? updatedOriginal.indexWhere((t) => t.id == current.id) : -1;
      if (origIdx != -1) {
        updatedOriginal.insert(origIdx + 1, track);
      } else {
        updatedOriginal.add(track);
      }

      state = state.copyWith(
        queue: updatedQueue,
        originalQueue: updatedOriginal,
      );
    }
    _saveSession();
  }

  /// Reorders a track within the queue
  void reorderQueue(int oldIndex, int newIndex) {
    if (oldIndex < 0 || oldIndex >= state.queue.length) return;
    if (newIndex < 0 || newIndex > state.queue.length) return;

    final updated = List<Track>.from(state.queue);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = updated.removeAt(oldIndex);
    updated.insert(newIndex, item);

    // Update currentQueueIndex if the moving item is active or surrounding it
    int newQueueIndex = state.queueIndex;
    if (state.queueIndex == oldIndex) {
      newQueueIndex = newIndex;
    } else if (state.queueIndex > oldIndex && state.queueIndex <= newIndex) {
      newQueueIndex -= 1;
    } else if (state.queueIndex < oldIndex && state.queueIndex >= newIndex) {
      newQueueIndex += 1;
    }

    state = state.copyWith(
      queue: updated,
      originalQueue: state.isShuffle ? state.originalQueue : updated,
      queueIndex: newQueueIndex,
    );
    _saveSession();
  }

  /// Removes a track from the queue at [index]
  void removeFromQueue(int index) {
    if (index < 0 || index >= state.queue.length) return;

    final removedTrack = state.queue[index];
    final updated = List<Track>.from(state.queue)..removeAt(index);
    final updatedOriginal = List<Track>.from(
      state.originalQueue.isNotEmpty ? state.originalQueue : state.queue,
    )..removeWhere((t) => t.id == removedTrack.id);
    int newQueueIndex = state.queueIndex;

    if (index < state.queueIndex) {
      newQueueIndex = (state.queueIndex - 1).clamp(0, updated.length - 1);
    } else if (index == state.queueIndex) {
      newQueueIndex = state.queueIndex.clamp(0, math.max(0, updated.length - 1));
    }

    state = state.copyWith(
      queue: updated,
      originalQueue: updatedOriginal,
      queueIndex: updated.isEmpty ? 0 : newQueueIndex,
    );
    _saveSession();
  }

  /// Clears all tracks from queue except the active track
  void clearQueue() {
    if (state.currentTrack != null) {
      state = state.copyWith(
        queue: [state.currentTrack!],
        originalQueue: [state.currentTrack!],
        queueIndex: 0,
      );
    } else {
      state = state.copyWith(
        queue: const [],
        originalQueue: const [],
        queueIndex: 0,
      );
    }
    _saveSession();
  }

  /// Jumps directly to a track at [index] in the queue
  Future<void> skipToQueueIndex(int index, {bool autoPlay = true}) async {
    if (index < 0 || index >= state.queue.length) return;
    final targetTrack = state.queue[index];
    state = state.copyWith(queueIndex: index);
    if (autoPlay) {
      await playTrack(targetTrack);
    } else {
      state = state.copyWith(
        currentTrack: targetTrack,
        position: Duration.zero,
      );
    }
  }

  /// Plays a track (local audio file or remote stream URL)
  Future<void> playTrack(Track track) async {
    Track targetTrack = track;
    if (track.id.startsWith('yt_')) {
      final videoId = track.id.replaceFirst('yt_', '');
      final cleanThumb = 'https://i.ytimg.com/vi/$videoId/hqdefault.jpg';
      if (targetTrack.albumArtUrl == null || targetTrack.albumArtUrl!.isEmpty || targetTrack.albumArtUrl!.contains('sqp=')) {
        targetTrack = targetTrack.copyWith(albumArtUrl: cleanThumb);
      }
      if (targetTrack.duration == Duration.zero) {
        try {
          final video = await YouTubeMusicService.instance.getVideoDetails(videoId);
          if (video != null) {
            final parsed = YouTubeMusicService.cleanMetadata(video.title, video.author);
            targetTrack = targetTrack.copyWith(
              title: parsed.title,
              artist: parsed.artist,
              duration: video.duration ?? targetTrack.duration,
              albumArtUrl: cleanThumb,
            );
          }
        } catch (_) {}
      }
    }

    state = state.copyWith(
      status: PlaybackStatus.loading,
      currentTrack: targetTrack,
      errorMessage: null,
    );

    // If queue doesn't contain this track, ensure queue has it
    if (!state.queue.contains(targetTrack)) {
      final newQueue = List<Track>.from(state.queue)..add(targetTrack);
      state = state.copyWith(
        queue: newQueue,
        queueIndex: newQueue.length - 1,
      );
    } else {
      final idx = state.queue.indexOf(targetTrack);
      if (idx != -1) {
        state = state.copyWith(queueIndex: idx);
      }
    }

    debugPrint('[PlayerController] playTrack invoked: "${targetTrack.title}" by "${targetTrack.artist}" (id: ${targetTrack.id})');
    try {
      if (state.volume <= 0.0 && !state.isMuted) {
        setVolume(1.0);
      } else {
        _audioEngine.setVolume(state.volume);
      }

      // Calculate ReplayGain if enabled
      final rgDb = ReplayGainService.instance.calculateEffectiveGainDb(
        track: targetTrack,
        mode: _playbackSettings.replayGainMode,
        preampDb: _playbackSettings.replayGainPreampDb,
        preventClipping: _playbackSettings.replayGainPreventClipping,
      );
      _audioEngine.setReplayGainDb(rgDb);
      _audioEngine.setPlaybackSpeed(state.playbackSpeed);
      _applyPitchAndSpeedCoupling();

      final enableFade = _playbackSettings.enableSmoothFade;
      final fadeDuration = Duration(milliseconds: _playbackSettings.fadeInDurationMs);

      if (targetTrack.filePath != null && targetTrack.filePath!.isNotEmpty) {
        debugPrint('[PlayerController] Playing local file: ${targetTrack.filePath}');
        try {
          await _audioEngine.playFile(targetTrack.filePath!, fadeIn: enableFade, fadeDuration: fadeDuration);
        } catch (e) {
          debugPrint('[PlayerController] playFile error (handled): $e');
        }
      } else {
        // Remote / cloud track: Check if cached in AudioCacheService
        final cachedPath = AudioCacheService.instance.getCachedFilePath(targetTrack.id);
        if (cachedPath != null) {
          debugPrint('[PlayerController] Playing from disk cache: $cachedPath');
          await _audioEngine.playFile(cachedPath, fadeIn: enableFade, fadeDuration: fadeDuration);
        } else if (targetTrack.id.startsWith('yt_')) {
          // YouTube track: progressive push-streaming via setBufferStream with WebmToOggRemuxer
          debugPrint('[PlayerController] YouTube stream init: fetching Ogg Opus stream for ${targetTrack.id}...');
          bool streamedSuccessfully = false;
          try {
            final oggStream = await YouTubeMusicService.instance
                .getOggOpusAudioByteStream(targetTrack.id)
                .timeout(const Duration(seconds: 15));

            if (oggStream != null) {
              final bufferSource = SoLoud.instance.setBufferStream(
                bufferingType: BufferingType.preserved,
                bufferingTimeNeeds: 0.1, // Ultra-low initial buffering requirement for instant start
                format: BufferType.auto,
              );

              final tempFile = AudioCacheService.instance.getTempFile(targetTrack.id);
              final targetFile = AudioCacheService.instance.getCacheFile(targetTrack.id);
              if (!await tempFile.parent.exists()) {
                await tempFile.parent.create(recursive: true);
              }
              final sink = tempFile.openWrite();

              // Pre-buffer initial header chunks (OpusHead, OpusTags) + initial audio frames (~48KB or 15 chunks)
              final streamIterator = StreamIterator(oggStream);
              int prebufferedBytes = 0;
              int prebufferedChunks = 0;

              while (await streamIterator.moveNext()) {
                final chunk = streamIterator.current;
                prebufferedChunks++;
                prebufferedBytes += chunk.length;
                SoLoud.instance.addAudioDataStream(bufferSource, chunk);
                sink.add(chunk);

                // Ensure OpusHead (page0), OpusTags (page1) and sufficient audio pages are fed
                if (prebufferedBytes >= 49152 || (prebufferedChunks >= 12 && prebufferedBytes >= 20480)) {
                  break;
                }
              }

              debugPrint('[PlayerController] YouTube prebuffered $prebufferedBytes bytes ($prebufferedChunks chunks). Sending to SoLoud audio engine...');

              if (prebufferedChunks > 0) {
                // Start playback once headers and initial audio frames are in SoLoud's buffer
                final handle = await _audioEngine.playAudioSource(
                  bufferSource,
                  fadeIn: enableFade,
                  fadeDuration: fadeDuration,
                );

                if (handle != null) {
                  streamedSuccessfully = true;
                  debugPrint('[PlayerController] SoLoud stream playback started successfully (handle: $handle)');

                  // Asynchronously pipe remaining chunks into SoLoud and disk cache
                  () async {
                    try {
                      int totalStreamedBytes = prebufferedBytes;
                      int chunkCount = prebufferedChunks;
                      int lastLoggedBytes = prebufferedBytes;

                      while (await streamIterator.moveNext()) {
                        final chunk = streamIterator.current;
                        chunkCount++;
                        totalStreamedBytes += chunk.length;
                        SoLoud.instance.addAudioDataStream(bufferSource, chunk);
                        sink.add(chunk);

                        // Log streaming progress every 512KB
                        if (totalStreamedBytes - lastLoggedBytes >= 524288) {
                          debugPrint(
                            '[PlayerController] Streaming progress: ${(totalStreamedBytes / 1024).toStringAsFixed(1)} KB piped ($chunkCount chunks)',
                          );
                          lastLoggedBytes = totalStreamedBytes;
                        }
                      }
                      SoLoud.instance.setDataIsEnded(bufferSource);
                      await sink.flush();
                      await sink.close();

                      if (await tempFile.exists() && await tempFile.length() > 0) {
                        if (await targetFile.exists()) await targetFile.delete();
                        await tempFile.rename(targetFile.path);
                        await AudioCacheService.instance.scanCache();
                        debugPrint(
                          '[PlayerController] YouTube stream fully downloaded and cached: ${targetFile.path} ($totalStreamedBytes bytes across $chunkCount chunks)',
                        );
                      }
                    } catch (e) {
                      debugPrint('[PlayerController] Progressive stream piping notice: $e');
                      try {
                        SoLoud.instance.setDataIsEnded(bufferSource);
                      } catch (_) {}
                      try {
                        await sink.close();
                      } catch (_) {}
                    }
                  }();
                }
              }
            }
          } catch (streamErr) {
            debugPrint('[PlayerController] Progressive streaming failed, attempting fallback cacheTrack: $streamErr');
          }

          if (!streamedSuccessfully) {
            // Fallback: Download via cacheTrack with 15s timeout
            debugPrint('[PlayerController] Falling back to direct cacheTrack download for ${targetTrack.id}...');
            final downloadedPath = await AudioCacheService.instance
                .cacheTrack(targetTrack)
                .timeout(const Duration(seconds: 15), onTimeout: () => null);
            if (downloadedPath != null) {
              debugPrint('[PlayerController] Fallback cacheTrack successful, playing: $downloadedPath');
              await _audioEngine.playFile(downloadedPath, fadeIn: enableFade, fadeDuration: fadeDuration);
            } else {
              throw ArgumentError('Unable to play or cache YouTube track: ${targetTrack.title} (${targetTrack.id})');
            }
          }
        } else {
          // Subsonic / generic remote: download-to-cache then play
          debugPrint('[PlayerController] Caching remote track: ${targetTrack.id}...');
          final downloadedPath = await AudioCacheService.instance.cacheTrack(targetTrack);
          if (downloadedPath != null) {
            await _audioEngine.playFile(downloadedPath, fadeIn: enableFade, fadeDuration: fadeDuration);
          } else {
            final streamUrl = targetTrack.streamUrl ?? targetTrack.remoteUrl;
            if (streamUrl != null && streamUrl.isNotEmpty) {
              await _audioEngine.playUrl(streamUrl, fadeIn: enableFade, fadeDuration: fadeDuration);
            } else {
              throw ArgumentError('Unable to stream or cache track: ${targetTrack.id}');
            }
          }
        }
      }

      final engineDur = _audioEngine.duration;
      final effectiveDuration = targetTrack.duration > Duration.zero
          ? targetTrack.duration
          : (engineDur > Duration.zero ? engineDur : targetTrack.duration);

      state = state.copyWith(
        status: PlaybackStatus.playing,
        currentTrack: targetTrack,
        duration: effectiveDuration,
        position: Duration.zero,
        effectiveReplayGainDb: rgDb,
      );
      debugPrint('[PlayerController] Playback active: "${targetTrack.title}" by "${targetTrack.artist}" (duration: $effectiveDuration)');

      // Smart Prefetch: Cache next track in queue ahead of time
      _prefetchNextTrackInQueue();

      // Log to playback history database
      LocalPersistenceService.instance.logTrackPlayback(targetTrack.toMap());

      _saveSession();
      _syncAudioHandler();
    } catch (e) {
      debugPrint('[PlayerController] Playback error: $e');
      state = state.copyWith(
        status: PlaybackStatus.error,
        errorMessage: 'Failed to play track: $e',
      );
      _syncAudioHandler();
    }
  }

  void _prefetchNextTrackInQueue() {
    try {
      if (state.queue.isNotEmpty && state.queueIndex + 1 < state.queue.length) {
        final nextTrack = state.queue[state.queueIndex + 1];
        if (nextTrack.id.startsWith('yt_') && (nextTrack.streamUrl == null || nextTrack.streamUrl!.isEmpty)) {
          YouTubeMusicService.instance.getAudioStreamUrl(nextTrack.id).then((url) {
            if (url != null && url.isNotEmpty) {
              AudioCacheService.instance.prefetchNextTrack(nextTrack.copyWith(remoteUrl: url));
            }
          });
        } else {
          AudioCacheService.instance.prefetchNextTrack(nextTrack);
        }
      }
    } catch (e) {
      debugPrint('[PlayerController] Error triggering next track prefetch: $e');
    }
  }

  /// Handle track ending naturally
  Future<void> _onTrackEnded() async {
    _isAdvancing = true;

    if (state.repeatMode == PlaybackRepeatMode.one) {
      seek(Duration.zero);
      resume();
      _isAdvancing = false;
      return;
    }

    if (state.hasQueue) {
      await skipNext();
    } else {
      await stop();
    }

    _isAdvancing = false;
  }

  /// Toggle play / pause
  void togglePlayPause() {
    if (state.isLoading) return;
    if (state.isPlaying) {
      pause();
    } else if (state.isPaused) {
      resume();
    } else if (state.currentTrack != null) {
      playTrack(state.currentTrack!);
    }
  }

  void pause() {
    if (_playbackSettings.enableSmoothFade && _playbackSettings.fadeOutDurationMs > 0) {
      _audioEngine.pauseWithFade(duration: Duration(milliseconds: _playbackSettings.fadeOutDurationMs));
    } else {
      _audioEngine.pause();
    }
    state = state.copyWith(status: PlaybackStatus.paused);
    _saveSession();
    _syncAudioHandler();
  }

  void resume() {
    if (_playbackSettings.enableSmoothFade && _playbackSettings.fadeInDurationMs > 0) {
      _audioEngine.resumeWithFade(duration: Duration(milliseconds: _playbackSettings.fadeInDurationMs));
    } else {
      _audioEngine.resume();
    }
    state = state.copyWith(status: PlaybackStatus.playing);
    _saveSession();
    _syncAudioHandler();
  }

  Future<void> stop() async {
    await _audioEngine.stop();
    state = state.copyWith(
      status: PlaybackStatus.stopped,
      position: Duration.zero,
    );
    _saveSession();
    _syncAudioHandler();
  }

  void seek(Duration position) {
    _audioEngine.seek(position);
    state = state.copyWith(position: position);
    _saveSession();
    _syncAudioHandler();
  }

  /// Lompat maju dengan langkah custom stepper (detik konstan / persentase durasi)
  void seekForward() {
    final Duration step;
    if (_playbackSettings.seekStepMode == SeekStepMode.percentage) {
      final ms = (state.duration.inMilliseconds * _playbackSettings.seekStepPercent).toInt();
      step = Duration(milliseconds: math.max(1000, ms));
    } else {
      step = Duration(seconds: _playbackSettings.seekStepSeconds);
    }
    final target = state.position + step;
    seek(target < state.duration ? target : state.duration);
  }

  /// Lompat mundur dengan langkah custom stepper (detik konstan / persentase durasi)
  void seekBackward() {
    final Duration step;
    if (_playbackSettings.seekStepMode == SeekStepMode.percentage) {
      final ms = (state.duration.inMilliseconds * _playbackSettings.seekStepPercent).toInt();
      step = Duration(milliseconds: math.max(1000, ms));
    } else {
      step = Duration(seconds: _playbackSettings.seekStepSeconds);
    }
    final target = state.position - step;
    seek(target > Duration.zero ? target : Duration.zero);
  }

  /// Mengatur kecepatan pemutaran (0.25x s/d 3.0x)
  void setPlaybackSpeed(double speed) {
    final clamped = speed.clamp(0.25, 3.0);
    _audioEngine.setPlaybackSpeed(clamped);
    state = state.copyWith(playbackSpeed: clamped);
    _applyPitchAndSpeedCoupling();
    _saveSession();
  }

  /// Mengatur pergeseran nada (Pitch Semitones & Fine Cents)
  void setPitch(double semitones, {double cents = 0.0}) {
    state = state.copyWith(
      pitchSemitones: semitones.clamp(-12.0, 12.0),
      pitchFineCents: cents.clamp(-50.0, 50.0),
    );
    _applyPitchAndSpeedCoupling();
    _saveSession();
  }

  /// Toggle penguncian Pitch dengan Speed
  void toggleLinkSpeedAndPitch() {
    state = state.copyWith(linkSpeedAndPitch: !state.linkSpeedAndPitch);
    _applyPitchAndSpeedCoupling();
    _saveSession();
  }

  void _applyPitchAndSpeedCoupling() {
    try {
      if (!SoLoud.instance.isInitialized) return;
      if (!state.linkSpeedAndPitch) {
        // Mode Time-Stretch independen: kompensasi pitch shift filter
        final semitonesTotal = state.pitchSemitones + (state.pitchFineCents / 100.0);
        final targetPitchRatio = math.pow(2.0, semitonesTotal / 12.0).toDouble();
        final filterCompensation = targetPitchRatio / state.playbackSpeed;
        final filter = SoLoud.instance.filters.pitchShiftFilter;
        if (!filter.isActive) filter.activate();
        filter.shift.value = filterCompensation.clamp(0.05, 3.0);
      } else {
        // Mode Terkunci: pitch naturally mengikuti speed melalui resampling SoLoud
        final filter = SoLoud.instance.filters.pitchShiftFilter;
        if (filter.isActive) filter.shift.value = 1.0;
      }
    } catch (e) {
      debugPrint('[PlayerController] Pitch coupling adjustment: $e');
    }
  }

  /// Toggle tampilan waktu sisa (Remaining) vs total durasi
  void toggleTimeDisplayMode() {
    final next = state.timeDisplayMode == TimeDisplayMode.remaining
        ? TimeDisplayMode.total
        : TimeDisplayMode.remaining;
    state = state.copyWith(timeDisplayMode: next);
    _saveSession();
  }

  void setTimeDisplayMode(TimeDisplayMode mode) {
    state = state.copyWith(timeDisplayMode: mode);
    _saveSession();
  }

  /// Handler interupsi saat headphone / DAC dicopot
  void onHeadphoneUnplugged() {
    AudioInterruptionManager.instance.handleHeadphoneUnplugged(
      isCurrentlyPlaying: state.isPlaying,
      onPause: () => pause(),
      pauseEnabled: _playbackSettings.pauseOnHeadphoneUnplug,
    );
  }

  /// Handler saat headphone / DAC dicolok kembali
  void onHeadphonePlugged() {
    AudioInterruptionManager.instance.handleHeadphonePlugged(
      onResume: () => resume(),
      resumeEnabled: _playbackSettings.resumeOnHeadphonePlug,
      timeoutSeconds: _playbackSettings.headphoneReconnectTimeoutSec,
    );
  }

  /// Handler saat volume sistem berubah
  void onDeviceVolumeChanged(double volume) {
    AudioInterruptionManager.instance.handleVolumeChanged(
      volume: volume,
      isCurrentlyPlaying: state.isPlaying,
      onPause: () => pause(),
      pauseOnZeroEnabled: _playbackSettings.pauseOnZeroVolume,
    );
  }

  void setVolume(double volume) {
    _audioEngine.setVolume(volume);
    state = state.copyWith(volume: volume);
    _saveSession();
  }

  void setPreamp(double preampDb) {
    _audioEngine.setPreamp(preampDb);
    state = state.copyWith(preAmpDb: preampDb);
    _saveSession();
  }

  /// Shuffles active queue tracks, preserving originalQueue for unshuffle restoration
  void shuffleQueue({bool keepCurrentTrackFirst = true}) {
    if (state.queue.isEmpty) return;

    final orig = state.originalQueue.isNotEmpty
        ? state.originalQueue
        : List<Track>.from(state.queue);
    final current = state.currentTrack ??
        (state.queue.isNotEmpty ? state.queue[state.queueIndex] : null);

    if (current == null || orig.length <= 1) {
      state = state.copyWith(
        originalQueue: orig,
        isShuffle: true,
      );
      _saveSession();
      _syncAudioHandler();
      return;
    }

    final remaining = orig.where((t) => t.id != current.id).toList();
    remaining.shuffle(math.Random());

    final newQueue = keepCurrentTrackFirst
        ? [current, ...remaining]
        : (List<Track>.from(orig)..shuffle(math.Random()));

    final newIndex = keepCurrentTrackFirst ? 0 : newQueue.indexOf(current);

    state = state.copyWith(
      originalQueue: orig,
      queue: newQueue,
      queueIndex: newIndex >= 0 ? newIndex : 0,
      isShuffle: true,
    );
    _saveSession();
    _syncAudioHandler();
  }

  void toggleShuffle() {
    if (!state.isShuffle) {
      shuffleQueue(keepCurrentTrackFirst: true);
    } else {
      // Unshuffle: restore pristine original queue order
      final orig = state.originalQueue.isNotEmpty
          ? state.originalQueue
          : state.queue;
      final current = state.currentTrack ??
          (state.queue.isNotEmpty ? state.queue[state.queueIndex] : null);
      final origIndex = current != null
          ? orig.indexWhere((t) => t.id == current.id)
          : 0;

      state = state.copyWith(
        queue: List<Track>.from(orig),
        queueIndex: origIndex >= 0 ? origIndex : 0,
        isShuffle: false,
      );
      _saveSession();
      _syncAudioHandler();
    }
  }

  void toggleRepeatMode() {
    final next = switch (state.repeatMode) {
      PlaybackRepeatMode.off => PlaybackRepeatMode.all,
      PlaybackRepeatMode.all => PlaybackRepeatMode.one,
      PlaybackRepeatMode.one => PlaybackRepeatMode.off,
    };
    state = state.copyWith(repeatMode: next);
    _saveSession();
  }

  void setRepeatMode(PlaybackRepeatMode mode) {
    state = state.copyWith(repeatMode: mode);
    _saveSession();
  }

  Future<void> skipNext({bool autoPlay = true}) async {
    if (state.queue.isEmpty) {
      if (state.duration > Duration.zero) {
        final newPos = state.position + const Duration(seconds: 15);
        if (newPos < state.duration) {
          seek(newPos);
        } else {
          seek(Duration.zero);
        }
      }
      return;
    }

    if (state.queueIndex < state.queue.length - 1) {
      await skipToQueueIndex(state.queueIndex + 1, autoPlay: autoPlay);
    } else if (state.repeatMode == PlaybackRepeatMode.all) {
      await skipToQueueIndex(0, autoPlay: autoPlay);
    } else {
      // Reached the end of queue
      await stop();
    }
  }

  Future<void> skipPrevious({bool autoPlay = true}) async {
    if (state.position.inSeconds > 3) {
      seek(Duration.zero);
      return;
    }

    if (state.queue.isEmpty) {
      final newPos = state.position - const Duration(seconds: 15);
      seek(newPos > Duration.zero ? newPos : Duration.zero);
      return;
    }

    if (state.queueIndex > 0) {
      await skipToQueueIndex(state.queueIndex - 1, autoPlay: autoPlay);
    } else if (state.repeatMode == PlaybackRepeatMode.all) {
      await skipToQueueIndex(state.queue.length - 1, autoPlay: autoPlay);
    } else {
      seek(Duration.zero);
    }
  }

  /// Update track metadata in the active player state and queue if present
  void updateTrackMetadata(Track updatedTrack) {
    bool changed = false;
    Track? current = state.currentTrack;
    if (current != null && current.id == updatedTrack.id) {
      current = updatedTrack;
      changed = true;
    }

    List<Track> queue = state.queue;
    final qIdx = queue.indexWhere((t) => t.id == updatedTrack.id);
    if (qIdx != -1) {
      queue = List<Track>.from(queue);
      queue[qIdx] = updatedTrack;
      changed = true;
    }

    if (changed) {
      state = state.copyWith(
        currentTrack: current,
        queue: queue,
      );
      _syncAudioHandler();
      _saveSession();
    }
  }

  /// Update multiple tracks metadata in the active player state and queue
  void updateBatchTracksMetadata(List<Track> updatedTracks) {
    if (updatedTracks.isEmpty) return;
    final map = {for (final t in updatedTracks) t.id: t};

    bool changed = false;
    Track? current = state.currentTrack;
    if (current != null && map.containsKey(current.id)) {
      current = map[current.id]!;
      changed = true;
    }

    List<Track> queue = state.queue;
    bool queueModified = false;
    final newQueue = queue.map((t) {
      if (map.containsKey(t.id)) {
        queueModified = true;
        return map[t.id]!;
      }
      return t;
    }).toList();

    if (queueModified) {
      queue = newQueue;
      changed = true;
    }

    if (changed) {
      state = state.copyWith(
        currentTrack: current,
        queue: queue,
      );
      _syncAudioHandler();
      _saveSession();
    }
  }

  @override
  void dispose() {
    _posSub?.cancel();
    super.dispose();
  }
}

