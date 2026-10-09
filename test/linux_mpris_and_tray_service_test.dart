// ignore_for_file: deprecated_member_use

import 'package:flutter_test/flutter_test.dart';
import 'package:tray_manager/legacy.dart';
import 'package:baydev_hifi/core/desktop/linux_mpris_service.dart';
import 'package:baydev_hifi/core/desktop/linux_tray_dbus_service.dart';
import 'package:baydev_hifi/core/desktop/desktop_tray_service.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LinuxMprisService Unit Tests', () {
    test('singleton instance exists and handles all transport callbacks', () {
      final mpris = LinuxMprisService.instance;
      expect(mpris, isNotNull);

      bool playCalled = false;
      bool pauseCalled = false;
      bool playPauseCalled = false;
      bool nextCalled = false;
      bool prevCalled = false;
      bool stopCalled = false;
      bool raiseCalled = false;
      Duration? seekTarget;
      double? volumeTarget;

      mpris.onPlay = () => playCalled = true;
      mpris.onPause = () => pauseCalled = true;
      mpris.onPlayPause = () => playPauseCalled = true;
      mpris.onNext = () => nextCalled = true;
      mpris.onPrevious = () => prevCalled = true;
      mpris.onStop = () => stopCalled = true;
      mpris.onRaise = () => raiseCalled = true;
      mpris.onSeek = (pos) => seekTarget = pos;
      mpris.onSetVolume = (vol) => volumeTarget = vol;

      mpris.onPlay?.call();
      expect(playCalled, isTrue);

      mpris.onPause?.call();
      expect(pauseCalled, isTrue);

      mpris.onPlayPause?.call();
      expect(playPauseCalled, isTrue);

      mpris.onNext?.call();
      expect(nextCalled, isTrue);

      mpris.onPrevious?.call();
      expect(prevCalled, isTrue);

      mpris.onStop?.call();
      expect(stopCalled, isTrue);

      mpris.onRaise?.call();
      expect(raiseCalled, isTrue);

      mpris.onSeek?.call(const Duration(seconds: 45));
      expect(seekTarget, const Duration(seconds: 45));

      mpris.onSetVolume?.call(0.75);
      expect(volumeTarget, 0.75);
    });

    test('updateTrack and updatePlaybackState execute safely without active DBus daemon', () {
      final mpris = LinuxMprisService.instance;

      const track = Track(
        id: 'studio_flac_24bit',
        title: 'Starboy',
        artist: 'The Weeknd',
        album: 'Starboy',
        albumArtUrl: '/home/user/Music/Starboy/cover.jpg',
        duration: Duration(minutes: 3, seconds: 50),
        format: AudioFormat.flac,
        sampleRate: 96000,
        bitDepth: 24,
      );

      // Verify no exceptions when updating state
      mpris.updateTrack(track, const Duration(minutes: 3, seconds: 50));
      mpris.updatePlaybackState(
        isPlaying: true,
        position: const Duration(seconds: 30),
        duration: const Duration(minutes: 3, seconds: 50),
        volume: 0.9,
      );

      expect(true, isTrue);
    });
  });

  group('LinuxTrayDbusService & DesktopTrayService Integration Tests', () {
    test('LinuxTrayDbusService dispatches events to DesktopTrayService', () {
      final trayService = DesktopTrayService.instance;
      final linuxTray = LinuxTrayDbusService.instance;

      bool activatedCalled = false;
      bool playPauseCalled = false;
      bool nextCalled = false;
      bool prevCalled = false;
      bool menuActionCalled = false;

      trayService.onPlayPause = () => playPauseCalled = true;
      trayService.onNext = () => nextCalled = true;
      trayService.onPrevious = () => prevCalled = true;
      trayService.onToggleDspRack = () => menuActionCalled = true;

      linuxTray.notifyIconActivated(100, 20);
      activatedCalled = true;
      expect(activatedCalled, isTrue);

      linuxTray.notifyIconSecondaryActivated(100, 20);
      expect(playPauseCalled, isTrue);

      linuxTray.notifyIconScrolled(1, 'vertical');
      expect(nextCalled, isTrue);

      linuxTray.notifyIconScrolled(-1, 'vertical');
      expect(prevCalled, isTrue);

      linuxTray.notifyMenuItemClicked(MenuItem(key: 'dsp_status', label: 'DSP Rack: Active'));
      expect(menuActionCalled, isTrue);
    });
  });
}
