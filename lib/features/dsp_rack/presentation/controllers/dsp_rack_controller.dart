import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../audio_engine/virtual_dsp_service.dart';
import '../../domain/dsp_models.dart';

final dspRackControllerProvider =
    StateNotifierProvider<DspRackController, DspRackState>((ref) {
  return DspRackController();
});

/// Controller StateNotifier untuk memanipulasi rantai DSP Mastering Rack.
/// Terintegrasi secara seamless dengan VirtualDspService (Single Source of Truth).
class DspRackController extends StateNotifier<DspRackState> {
  DspRackController() : super(const DspRackState()) {
    _syncWithEngine();
  }

  @override
  DspRackState get state => super.state;

  /// Sinkronisasi parameter DSP ke VirtualDspService (RYNLABS_HIFI Master Chain)
  void _syncWithEngine() {
    try {
      final dsp = VirtualDspService.instance;

      if (state.isBypassed) {
        dsp.setMasterEnabled(false);
        return;
      }

      dsp.setMasterEnabled(true);
      dsp.setPreampGain(state.preampDb);

      // 1. Dynamic Bass Boost
      dsp.toggleBassBoost(state.bassBoostEnabled);
      if (state.bassBoostEnabled) {
        dsp.setBassBoostValue(state.bassBoostAmount);
      }

      // 2. Tube Harmonic Exciter
      dsp.toggleTubeExciter(state.tubeExciterEnabled);
      if (state.tubeExciterEnabled) {
        dsp.setTubeParams(
          drive: state.tubeDrive,
          warmth: state.tubeWarmth,
          mix: state.tubeMix * state.masterWet,
        );
      }

      // 3. Stereo Width Matrix
      dsp.toggleStereoWidth(state.stereoWidthEnabled);
      if (state.stereoWidthEnabled) {
        dsp.setStereoWidthParams(
          factor: state.stereoWidth,
          midGain: state.stereoMidGain,
          wet: state.stereoWet * state.masterWet,
        );
      }

      // 4. Binaural Crossfeed
      dsp.toggleCrossfeed(state.crossfeedEnabled);
      if (state.crossfeedEnabled) {
        dsp.setCrossfeedParams(
          cutoff: state.crossfeedCutoff,
          feed: state.crossfeedFeed,
          delayMs: state.crossfeedDelayMs,
          wet: state.crossfeedWet * state.masterWet,
        );
      }

      // 5. Spatial Studio Reverb
      dsp.toggleReverb(state.reverbEnabled);
      if (state.reverbEnabled) {
        dsp.setReverbParams(
          roomSize: state.reverbRoomSize,
          damp: state.reverbDamp,
          wet: state.reverbWet * state.masterWet,
          width: state.reverbWidth,
        );
      }

      // 6. Pitch Shifter
      dsp.togglePitchShift(state.pitchShiftEnabled);
      if (state.pitchShiftEnabled) {
        dsp.setPitchValue(state.pitchSemitones);
      }

      // 7. Dynamic Compressor
      dsp.toggleCompressor(state.compressorEnabled);
      if (state.compressorEnabled) {
        dsp.setCompressorParams(
          threshold: state.compThreshold,
          ratio: state.compRatio,
          attackMs: state.compAttack,
          releaseMs: state.compRelease,
          knee: state.compKnee,
          makeup: state.compMakeup,
        );
      }

      // 8. Peak Brickwall Limiter (Always active with hard ceiling -1.3 dBFS)
      dsp.toggleLimiter(state.limiterEnabled);
      if (state.limiterEnabled) {
        dsp.setLimiterParams(
          threshold: state.limiterThreshold,
          attackMs: state.limiterAttack,
          releaseMs: state.limiterRelease,
        );
      }
    } catch (e) {
      debugPrint('[DspRackController] Non-fatal sync error: $e');
    }
  }

  // Master Rack Controls
  void toggleBypass() {
    state = state.copyWith(isBypassed: !state.isBypassed);
    _syncWithEngine();
  }

  void setMasterWet(double wet) {
    state = state.copyWith(masterWet: wet.clamp(0.0, 1.0));
    _syncWithEngine();
  }

  void setPreamp(double db) {
    state = state.copyWith(preampDb: db.clamp(-24.0, 12.0));
    _syncWithEngine();
  }

  // Dynamic Bass Boost
  void toggleBassBoost() {
    state = state.copyWith(
      bassBoostEnabled: !state.bassBoostEnabled,
      clearPreset: true,
    );
    _syncWithEngine();
  }

  void setBassBoostAmount(double amount) {
    state = state.copyWith(
      bassBoostAmount: amount.clamp(0.0, 10.0),
      clearPreset: true,
    );
    _syncWithEngine();
  }

  void setBassBoostWet(double wet) {
    state = state.copyWith(
      bassBoostWet: wet.clamp(0.0, 1.0),
      clearPreset: true,
    );
    _syncWithEngine();
  }

  // Tube Exciter
  void toggleTubeExciter() {
    state = state.copyWith(
      tubeExciterEnabled: !state.tubeExciterEnabled,
      clearPreset: true,
    );
    _syncWithEngine();
  }

  void setTubeDrive(double drive) {
    state = state.copyWith(
      tubeDrive: drive.clamp(0.0, 10.0),
      clearPreset: true,
    );
    _syncWithEngine();
  }

  void setTubeWarmth(double warmth) {
    state = state.copyWith(
      tubeWarmth: warmth.clamp(0.0, 1.0),
      clearPreset: true,
    );
    _syncWithEngine();
  }

  void setTubeMix(double mix) {
    state = state.copyWith(
      tubeMix: mix.clamp(0.0, 1.0),
      clearPreset: true,
    );
    _syncWithEngine();
  }

  // Dynamic Compressor
  void toggleCompressor() {
    state = state.copyWith(
      compressorEnabled: !state.compressorEnabled,
      clearPreset: true,
    );
    _syncWithEngine();
  }

  void setCompThreshold(double threshold) {
    state = state.copyWith(
      compThreshold: threshold.clamp(-80.0, 0.0),
      clearPreset: true,
    );
    _syncWithEngine();
  }

  void setCompRatio(double ratio) {
    state = state.copyWith(
      compRatio: ratio.clamp(1.0, 10.0),
      clearPreset: true,
    );
    _syncWithEngine();
  }

  void setCompAttack(double attack) {
    state = state.copyWith(
      compAttack: attack.clamp(0.0, 100.0),
      clearPreset: true,
    );
    _syncWithEngine();
  }

  void setCompRelease(double release) {
    state = state.copyWith(
      compRelease: release.clamp(0.0, 1000.0),
      clearPreset: true,
    );
    _syncWithEngine();
  }

  void setCompMakeup(double makeup) {
    state = state.copyWith(
      compMakeup: makeup.clamp(-40.0, 40.0),
      clearPreset: true,
    );
    _syncWithEngine();
  }

  void setCompKnee(double knee) {
    state = state.copyWith(
      compKnee: knee.clamp(0.0, 40.0),
      clearPreset: true,
    );
    _syncWithEngine();
  }

  // Stereo Width Matrix
  void toggleStereoWidth() {
    state = state.copyWith(
      stereoWidthEnabled: !state.stereoWidthEnabled,
      clearPreset: true,
    );
    _syncWithEngine();
  }

  void setStereoWidth(double width) {
    state = state.copyWith(
      stereoWidth: width.clamp(0.0, 3.0),
      clearPreset: true,
    );
    _syncWithEngine();
  }

  void setStereoMidGain(double midGain) {
    state = state.copyWith(
      stereoMidGain: midGain.clamp(0.0, 2.0),
      clearPreset: true,
    );
    _syncWithEngine();
  }

  // Binaural Crossfeed
  void toggleCrossfeed() {
    state = state.copyWith(
      crossfeedEnabled: !state.crossfeedEnabled,
      clearPreset: true,
    );
    _syncWithEngine();
  }

  void setCrossfeedCutoff(double cutoff) {
    state = state.copyWith(
      crossfeedCutoff: cutoff.clamp(200.0, 2000.0),
      clearPreset: true,
    );
    _syncWithEngine();
  }

  void setCrossfeedFeed(double feed) {
    state = state.copyWith(
      crossfeedFeed: feed.clamp(-24.0, 0.0),
      clearPreset: true,
    );
    _syncWithEngine();
  }

  void setCrossfeedDelay(double delayMs) {
    state = state.copyWith(
      crossfeedDelayMs: delayMs.clamp(0.05, 1.0),
      clearPreset: true,
    );
    _syncWithEngine();
  }

  // Spatial Reverb
  void toggleReverb() {
    state = state.copyWith(
      reverbEnabled: !state.reverbEnabled,
      clearPreset: true,
    );
    _syncWithEngine();
  }

  void setReverbRoomSize(double roomSize) {
    state = state.copyWith(
      reverbRoomSize: roomSize.clamp(0.0, 1.0),
      clearPreset: true,
    );
    _syncWithEngine();
  }

  void setReverbDamp(double damp) {
    state = state.copyWith(
      reverbDamp: damp.clamp(0.0, 1.0),
      clearPreset: true,
    );
    _syncWithEngine();
  }

  void setReverbWidth(double width) {
    state = state.copyWith(
      reverbWidth: width.clamp(0.0, 1.0),
      clearPreset: true,
    );
    _syncWithEngine();
  }

  void setReverbWet(double wet) {
    state = state.copyWith(
      reverbWet: wet.clamp(0.0, 1.0),
      clearPreset: true,
    );
    _syncWithEngine();
  }

  // Pitch Shifter
  void togglePitchShift() {
    state = state.copyWith(
      pitchShiftEnabled: !state.pitchShiftEnabled,
      clearPreset: true,
    );
    _syncWithEngine();
  }

  void setPitchSemitones(double semitones) {
    state = state.copyWith(
      pitchSemitones: semitones.clamp(-12.0, 12.0),
      clearPreset: true,
    );
    _syncWithEngine();
  }

  // Peak Limiter
  void toggleLimiter() {
    state = state.copyWith(
      limiterEnabled: !state.limiterEnabled,
      clearPreset: true,
    );
    _syncWithEngine();
  }

  void setLimiterThreshold(double thresh) {
    state = state.copyWith(
      limiterThreshold: thresh.clamp(-60.0, 0.0),
      clearPreset: true,
    );
    _syncWithEngine();
  }

  void setLimiterCeiling(double ceiling) {
    state = state.copyWith(
      limiterOutputCeiling: ceiling.clamp(-60.0, 0.0),
      clearPreset: true,
    );
    _syncWithEngine();
  }

  void setLimiterRelease(double release) {
    state = state.copyWith(
      limiterRelease: release.clamp(1.0, 1000.0),
      clearPreset: true,
    );
    _syncWithEngine();
  }

  // Presets and Master Actions
  void applyPreset(DspPreset preset) {
    state = preset.state.copyWith(activePresetId: preset.id);
    _syncWithEngine();
  }

  void resetToDefaults() {
    state = const DspRackState();
    VirtualDspService.instance.resetToFlatReference();
    _syncWithEngine();
  }
}
