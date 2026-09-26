import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/core/audio_engine/audio_interruption_manager.dart';
import 'package:baydev_hifi/core/audio_engine/replay_gain_service.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';
import 'package:baydev_hifi/features/player/presentation/widgets/custom_time_bar.dart';
import 'package:baydev_hifi/features/player/presentation/widgets/playback_speed_pitch_sheet.dart';
import 'package:baydev_hifi/features/settings/domain/player_customization_settings.dart';
import 'package:baydev_hifi/features/settings/domain/player_playback_settings.dart';
import 'package:baydev_hifi/features/settings/presentation/controllers/playback_settings_controller.dart';
import 'package:baydev_hifi/features/settings/presentation/sub_screens/playback_engine_settings_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('16.1 & 16.5 PlayerPlaybackSettings Domain Model & Serialization', () {
    test('Default constructor provides audiophile studio values', () {
      const settings = PlayerPlaybackSettings();
      expect(settings.enableSmoothFade, isTrue);
      expect(settings.fadeInDurationMs, equals(300));
      expect(settings.fadeOutDurationMs, equals(300));
      expect(settings.pauseOnHeadphoneUnplug, isTrue);
      expect(settings.resumeOnHeadphonePlug, isTrue);
      expect(settings.headphoneReconnectTimeoutSec, equals(10));
      expect(settings.pauseOnZeroVolume, isTrue);
      expect(settings.playbackSpeed, equals(1.0));
      expect(settings.pitchSemitones, equals(0.0));
      expect(settings.pitchFineCents, equals(0.0));
      expect(settings.linkSpeedAndPitch, isFalse);
      expect(settings.replayGainMode, equals(ReplayGainMode.track));
      expect(settings.replayGainPreampDb, equals(0.0));
      expect(settings.replayGainPreventClipping, isTrue);
      expect(settings.enableSkipSilence, isFalse);
      expect(settings.silenceThresholdDb, equals(-55.0));
      expect(settings.seekStepMode, equals(SeekStepMode.constantSeconds));
      expect(settings.seekStepSeconds, equals(10));
      expect(settings.seekStepPercent, equals(0.05));
      expect(settings.timeDisplayMode, equals(TimeDisplayMode.remaining));
    });

    test('Serialization toMap and fromMap round-trips cleanly', () {
      const original = PlayerPlaybackSettings(
        enableSmoothFade: false,
        fadeInDurationMs: 450,
        fadeOutDurationMs: 600,
        pauseOnHeadphoneUnplug: false,
        resumeOnHeadphonePlug: true,
        headphoneReconnectTimeoutSec: 15,
        pauseOnZeroVolume: false,
        playbackSpeed: 1.25,
        pitchSemitones: 2.0,
        pitchFineCents: 15.0,
        linkSpeedAndPitch: true,
        replayGainMode: ReplayGainMode.album,
        replayGainPreampDb: -3.0,
        replayGainPreventClipping: false,
        enableSkipSilence: true,
        silenceThresholdDb: -50.0,
        seekStepMode: SeekStepMode.percentage,
        seekStepSeconds: 20,
        seekStepPercent: 0.10,
        timeDisplayMode: TimeDisplayMode.total,
      );

      final map = original.toMap();
      final recreated = PlayerPlaybackSettings.fromMap(map);

      expect(recreated.enableSmoothFade, equals(original.enableSmoothFade));
      expect(recreated.fadeInDurationMs, equals(original.fadeInDurationMs));
      expect(recreated.fadeOutDurationMs, equals(original.fadeOutDurationMs));
      expect(recreated.pauseOnHeadphoneUnplug, equals(original.pauseOnHeadphoneUnplug));
      expect(recreated.resumeOnHeadphonePlug, equals(original.resumeOnHeadphonePlug));
      expect(recreated.headphoneReconnectTimeoutSec, equals(original.headphoneReconnectTimeoutSec));
      expect(recreated.pauseOnZeroVolume, equals(original.pauseOnZeroVolume));
      expect(recreated.playbackSpeed, equals(original.playbackSpeed));
      expect(recreated.pitchSemitones, equals(original.pitchSemitones));
      expect(recreated.pitchFineCents, equals(original.pitchFineCents));
      expect(recreated.linkSpeedAndPitch, equals(original.linkSpeedAndPitch));
      expect(recreated.replayGainMode, equals(original.replayGainMode));
      expect(recreated.replayGainPreampDb, equals(original.replayGainPreampDb));
      expect(recreated.replayGainPreventClipping, equals(original.replayGainPreventClipping));
      expect(recreated.enableSkipSilence, equals(original.enableSkipSilence));
      expect(recreated.silenceThresholdDb, equals(original.silenceThresholdDb));
      expect(recreated.seekStepMode, equals(original.seekStepMode));
      expect(recreated.seekStepSeconds, equals(original.seekStepSeconds));
      expect(recreated.seekStepPercent, equals(original.seekStepPercent));
      expect(recreated.timeDisplayMode, equals(original.timeDisplayMode));
    });
  });

  group('16.4 ReplayGainService Unit Tests', () {
    final service = ReplayGainService.instance;

    const testTrack = Track(
      id: 'rg_track_1',
      title: 'HiFi Mastering Session',
      artist: 'Studio Engineer',
      album: 'Reference Album',
      duration: Duration(minutes: 4),
      replayGainTrackDb: -6.5,
      replayGainTrackPeak: 0.95,
      replayGainAlbumDb: -5.0,
      replayGainAlbumPeak: 1.0,
    );

    test('calculateEffectiveGainDb returns preamp when ReplayGainMode.off', () {
      final gain = service.calculateEffectiveGainDb(
        track: testTrack,
        mode: ReplayGainMode.off,
        preampDb: 2.0,
      );
      expect(gain, equals(2.0));
    });

    test('calculateEffectiveGainDb returns track gain + preamp in track mode without clipping', () {
      final gain = service.calculateEffectiveGainDb(
        track: testTrack,
        mode: ReplayGainMode.track,
        preampDb: 0.0,
        preventClipping: true,
      );
      // nominal is -6.5 dB, peak is 0.95 (peakDb ~ -0.45 dB). nominal + peakDb = -6.95 <= 0 -> no attenuation needed
      expect(gain, equals(-6.5));
    });

    test('calculateEffectiveGainDb attenuates gain when nominal + peak exceeds 0 dBFS', () {
      const hotTrack = Track(
        id: 'hot_track',
        title: 'Hot Master',
        artist: 'Artist',
        album: 'Album',
        duration: Duration(minutes: 3),
        replayGainTrackDb: 4.0, // +4 dB boost requested
        replayGainTrackPeak: 1.0, // 0 dBFS peak
      );

      final gain = service.calculateEffectiveGainDb(
        track: hotTrack,
        mode: ReplayGainMode.track,
        preampDb: 0.0,
        preventClipping: true,
      );
      // peak is 1.0 (peakDb = 0). nominal (+4) + peak (0) > 0. Clamped to -peakDb = 0.0
      expect(gain, equals(0.0));
    });

    test('calculateEffectiveGainDb computes album gain correctly', () {
      final gain = service.calculateEffectiveGainDb(
        track: testTrack,
        mode: ReplayGainMode.album,
        preampDb: 1.0,
        preventClipping: false,
      );
      expect(gain, equals(-4.0)); // -5.0 + 1.0
    });

    test('linearToDb and dbToLinear mathematical consistency', () {
      expect(service.dbToLinear(0.0), closeTo(1.0, 0.0001));
      expect(service.dbToLinear(-6.0206), closeTo(0.5, 0.001));
      expect(service.linearToDb(1.0), closeTo(0.0, 0.0001));
      expect(service.linearToDb(0.5), closeTo(-6.0206, 0.01));
      expect(service.linearToDb(0.0), equals(-120.0));
    });

    test('isSilent identifies levels below threshold', () {
      expect(service.isSilent(0.0, thresholdDb: -55.0), isTrue);
      expect(service.isSilent(0.0001, thresholdDb: -55.0), isTrue); // -80 dB
      expect(service.isSilent(0.1, thresholdDb: -55.0), isFalse); // -20 dB
    });

    test('detectLeadingSilenceDurationMs measures leading silent frames', () {
      // 44100 Hz. 4410 silent frames = 100 ms
      final samples = List<double>.filled(4410, 0.0, growable: true)..addAll(List<double>.filled(1000, 0.8));
      final ms = service.detectLeadingSilenceDurationMs(samples, sampleRate: 44100, thresholdDb: -55.0);
      expect(ms, equals(100));
    });
  });

  group('16.2 AudioInterruptionManager Unit Tests', () {
    final manager = AudioInterruptionManager.instance;

    setUp(() {
      manager.resetInterruptionState();
    });

    test('handleHeadphoneUnplugged pauses during active playback and sets state', () {
      bool paused = false;
      manager.handleHeadphoneUnplugged(
        isCurrentlyPlaying: true,
        onPause: () => paused = true,
        pauseEnabled: true,
      );

      expect(paused, isTrue);
      expect(manager.wasPlayingBeforeUnplug, isTrue);
      expect(manager.unpluggedAt, isNotNull);
    });

    test('handleHeadphoneUnplugged does nothing when already paused', () {
      bool paused = false;
      manager.handleHeadphoneUnplugged(
        isCurrentlyPlaying: false,
        onPause: () => paused = true,
        pauseEnabled: true,
      );

      expect(paused, isFalse);
      expect(manager.wasPlayingBeforeUnplug, isFalse);
      expect(manager.unpluggedAt, isNull);
    });

    test('handleHeadphonePlugged resumes within timeout limit', () {
      manager.handleHeadphoneUnplugged(
        isCurrentlyPlaying: true,
        onPause: () {},
        pauseEnabled: true,
      );

      bool resumed = false;
      manager.handleHeadphonePlugged(
        onResume: () => resumed = true,
        resumeEnabled: true,
        timeoutSeconds: 10,
      );

      expect(resumed, isTrue);
      expect(manager.wasPlayingBeforeUnplug, isFalse);
      expect(manager.unpluggedAt, isNull);
    });

    test('handleHeadphonePlugged does NOT resume when resumeEnabled is false', () {
      manager.handleHeadphoneUnplugged(
        isCurrentlyPlaying: true,
        onPause: () {},
        pauseEnabled: true,
      );

      bool resumed = false;
      manager.handleHeadphonePlugged(
        onResume: () => resumed = true,
        resumeEnabled: false,
        timeoutSeconds: 10,
      );

      expect(resumed, isFalse);
      expect(manager.wasPlayingBeforeUnplug, isFalse);
    });

    test('handleVolumeChanged pauses when volume reaches 0 during playback', () {
      bool paused = false;
      manager.handleVolumeChanged(
        volume: 0.0,
        isCurrentlyPlaying: true,
        onPause: () => paused = true,
        pauseOnZeroEnabled: true,
      );
      expect(paused, isTrue);
    });

    test('handleVolumeChanged does not pause when volume > 0', () {
      bool paused = false;
      manager.handleVolumeChanged(
        volume: 0.5,
        isCurrentlyPlaying: true,
        onPause: () => paused = true,
        pauseOnZeroEnabled: true,
      );
      expect(paused, isFalse);
    });
  });

  group('16.3 & 16.5 PlaybackSettingsController Unit Tests', () {
    test('Updates parameters and clamps values safely', () {
      final controller = PlaybackSettingsController();

      controller.setFadeInDurationMs(2000); // Exceeds 1500 max
      expect(controller.state.fadeInDurationMs, equals(1500));

      controller.setPlaybackSpeed(4.5); // Exceeds 3.0 max
      expect(controller.state.playbackSpeed, equals(3.0));

      controller.setPitchSemitones(-15.0); // Below -12.0 min
      expect(controller.state.pitchSemitones, equals(-12.0));

      controller.toggleTimeDisplayMode();
      expect(controller.state.timeDisplayMode, equals(TimeDisplayMode.total));

      controller.toggleTimeDisplayMode();
      expect(controller.state.timeDisplayMode, equals(TimeDisplayMode.remaining));

      controller.resetToDefaults();
      expect(controller.state.playbackSpeed, equals(1.0));
      expect(controller.state.pitchSemitones, equals(0.0));
    });
  });

  group('16.5 CustomTimeBar Widget Tests', () {
    testWidgets('Renders negative countdown in remaining mode and total duration in total mode',
        (tester) async {
      bool toggled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTimeBar(
              position: const Duration(minutes: 1, seconds: 15),
              duration: const Duration(minutes: 4, seconds: 0),
              style: TimeBarStyle.slim,
              primaryColor: const Color(0xFF38BDF8),
              timeDisplayMode: TimeDisplayMode.remaining,
              onToggleTimeDisplayMode: () => toggled = true,
              onSeek: (_) {},
            ),
          ),
        ),
      );

      // In remaining mode, remaining = 4:00 - 1:15 = 2:45 -> should show "-02:45"
      expect(find.text('-02:45'), findsOneWidget);
      expect(find.text('01:15'), findsOneWidget);

      // Tap on countdown text triggers toggle
      await tester.tap(find.text('-02:45'));
      await tester.pumpAndSettle();
      expect(toggled, isTrue);

      // Re-pump with total mode
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CustomTimeBar(
              position: const Duration(minutes: 1, seconds: 15),
              duration: const Duration(minutes: 4, seconds: 0),
              style: TimeBarStyle.slim,
              primaryColor: const Color(0xFF38BDF8),
              timeDisplayMode: TimeDisplayMode.total,
              onToggleTimeDisplayMode: () {},
              onSeek: (_) {},
            ),
          ),
        ),
      );

      expect(find.text('04:00'), findsOneWidget);
      expect(find.text('-02:45'), findsNothing);
    });
  });

  group('16.3 PlaybackSpeedPitchSheet Modal Widget Tests', () {
    testWidgets('Renders speed and pitch controls and preset chips', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: PlaybackSpeedPitchSheet(),
            ),
          ),
        ),
      );

      expect(find.text('SPEED & PITCH ENGINE'), findsOneWidget);
      expect(find.text('PLAYBACK SPEED'), findsOneWidget);
      expect(find.text('PITCH SHIFT'), findsOneWidget);
      expect(find.text('LINK SPEED & PITCH'), findsOneWidget);

      // Check quick chips
      expect(find.text('1.0x'), findsWidgets);
      expect(find.text('1.25x'), findsOneWidget);
      expect(find.text('1.5x'), findsOneWidget);
      expect(find.text('2.0x'), findsOneWidget);

      // Tap preset chip 1.25x
      await tester.tap(find.text('1.25x'));
      await tester.pumpAndSettle();
      expect(find.text('1.25x'), findsWidgets);
    });
  });

  group('PlaybackEngineSettingsScreen Sub-Screen Widget Tests', () {
    testWidgets('Renders all 6 bento cards and hero banner without overflows', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PlaybackEngineSettingsScreen(),
          ),
        ),
      );

      expect(find.text('PLAYBACK ENGINE & INTERRUPTION'), findsOneWidget);
      expect(find.text('STUDIO PLAYBACK POLICIES'), findsOneWidget);
      expect(find.text('SMOOTH VOLUME FADE TRANSITIONS'), findsOneWidget);
      expect(find.text('AUDIO DEVICE INTERRUPTION POLICIES'), findsOneWidget);
      expect(find.text('SPEED & PITCH SEMITONE ENGINE'), findsOneWidget);
      expect(find.text('REPLAYGAIN & SILENCE MANAGEMENT'), findsOneWidget);
      expect(find.text('SEEK STEPPER & TIME DISPLAY MODES'), findsOneWidget);
      expect(find.text('RESET PLAYBACK ENGINE TO DEFAULTS'), findsOneWidget);
    });
  });
}
