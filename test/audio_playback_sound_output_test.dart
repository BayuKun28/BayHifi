import 'package:flutter_test/flutter_test.dart';
import 'package:baydev_hifi/audio_engine/dsp_profile.dart';
import 'package:baydev_hifi/audio_engine/soloud_controller.dart';
import 'package:baydev_hifi/features/player/presentation/controllers/player_controller.dart';
import 'package:baydev_hifi/features/player/domain/track.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Audio Playback Sound Output & Volume Tests', () {
    test('DspProfile.flatReference has all DSP filters disabled for bit-perfect output', () {
      final flat = DspProfile.flatReference;
      expect(flat.eqEnabled, isFalse);
      expect(flat.bassBoostEnabled, isFalse);
      expect(flat.compEnabled, isFalse);
      expect(flat.limiterEnabled, isFalse);
      expect(flat.reverbEnabled, isFalse);
      expect(flat.tubeEnabled, isFalse);
      expect(flat.stereoWidthEnabled, isFalse);
      expect(flat.crossfeedEnabled, isFalse);
      expect(flat.pitchShiftEnabled, isFalse);
      expect(flat.preampGain, equals(0.0));
    });

    test('SoLoudController effectiveVolume calculates positive audible level', () {
      final controller = SoLoudController.instance;
      controller.setVolume(1.0);
      controller.setPreamp(0.0);
      controller.setReplayGainDb(0.0);

      expect(controller.volume, equals(1.0));
      expect(controller.effectiveVolume, greaterThanOrEqualTo(1.0));
    });

    test('PlayerController ensures audible volume during playback initialization', () async {
      final player = PlayerController(SoLoudController.instance);
      expect(player.state.volume, greaterThan(0.0));

      const testTrack = Track(
        id: 'test_sample_1',
        title: 'Lossless Track',
        artist: 'Studio Master',
        album: 'Audiophile Vol 1',
        duration: Duration(minutes: 3, seconds: 45),
        filePath: '/tmp/test.flac',
        format: AudioFormat.flac,
        bitDepth: 24,
        sampleRate: 96000,
      );

      player.setVolume(0.85);
      expect(player.state.volume, equals(0.85));
      expect(SoLoudController.instance.volume, equals(0.85));
      expect(testTrack.isHiRes, isTrue);
    });
  });
}
