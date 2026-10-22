import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../../core/audio_service/baydev_audio_handler.dart';
import '../../../../core/desktop/desktop_tray_service.dart';
import '../../../../core/desktop/linux_mpris_service.dart';
import '../domain/playback_state.dart';

/// Bridges playback events and state to OS-level notification controls:
/// - Android MediaSession / iOS remote controls via BaydevAudioHandler
/// - Linux MPRIS D-Bus interface
/// - Desktop system tray icons & menus (Linux, Windows, macOS)
class PlaybackOsSyncBridge {
  const PlaybackOsSyncBridge._();

  static void registerCallbacks({
    required VoidCallback onResume,
    required VoidCallback onPause,
    required VoidCallback onTogglePlayPause,
    required VoidCallback onSkipNext,
    required VoidCallback onSkipPrevious,
    required Future<void> Function(Duration) onSeek,
    required VoidCallback onStop,
    required VoidCallback onToggleMute,
    required void Function(double) onSetVolume,
  }) {
    try {
      final handler = BaydevAudioHandler.instance;
      handler.onPlayCallback = onResume;
      handler.onPauseCallback = onPause;
      handler.onSkipNextCallback = onSkipNext;
      handler.onSkipPreviousCallback = onSkipPrevious;
      handler.onSeekCallback = onSeek;
      handler.onStopCallback = onStop;

      if (!kIsWeb && Platform.isLinux) {
        final mpris = LinuxMprisService.instance;
        mpris.onPlay = onResume;
        mpris.onPause = onPause;
        mpris.onPlayPause = onTogglePlayPause;
        mpris.onNext = onSkipNext;
        mpris.onPrevious = onSkipPrevious;
        mpris.onStop = onStop;
        mpris.onRaise = () => DesktopTrayService.instance.toggleWindowVisibility();
        mpris.onSeek = (pos) => onSeek(pos);
        mpris.onSetVolume = onSetVolume;
      }

      if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
        final tray = DesktopTrayService.instance;
        tray.onPlay = onResume;
        tray.onPause = onPause;
        tray.onPlayPause = onTogglePlayPause;
        tray.onNext = onSkipNext;
        tray.onPrevious = onSkipPrevious;
        tray.onToggleMute = onToggleMute;
        tray.onSetVolume = onSetVolume;
        tray.onQuit = onStop;
      }
    } catch (e) {
      debugPrint('[PlaybackOsSyncBridge] Error registering callbacks: $e');
    }
  }

  static void syncPlaybackState(PlaybackState state) {
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

      if (!kIsWeb && (Platform.isLinux || Platform.isWindows || Platform.isMacOS)) {
        DesktopTrayService.instance.updatePlaybackState(
          currentTrack: state.currentTrack,
          isPlaying: state.isPlaying,
          volume: state.volume,
          isMuted: state.isMuted,
        );
      }
    } catch (e) {
      debugPrint('[PlaybackOsSyncBridge] Error syncing playback state: $e');
    }
  }
}
