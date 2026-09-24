import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import '../../../../audio_engine/soloud_controller.dart';
import '../../domain/dsp_models.dart';

final dspRackControllerProvider =
    StateNotifierProvider<DspRackController, DspRackState>((ref) {
  return DspRackController();
});

/// Controller StateNotifier untuk memanipulasi rantai DSP Mastering Rack
class DspRackController extends StateNotifier<DspRackState> {
  DspRackController() : super(const DspRackState()) {
    // Initial sync with audio engine if already running
    _syncWithEngine();
  }

  /// Sinkronisasi parameter DSP ke low-level C++ filter engine SoLoud
  void _syncWithEngine() {
    try {
      if (!SoLoudController.instance.isInitialized) return;

      // 1. Preamp Stage
      final effectivePreamp = state.isBypassed ? 0.0 : state.preampDb;
      SoLoudController.instance.setPreamp(effectivePreamp);

      final filters = SoLoud.instance.filters;

      // If master bypassed, turn off all DSP filters
      if (state.isBypassed) {
        if (filters.bassBoostFilter.isActive) filters.bassBoostFilter.deactivate();
        if (filters.tubeExciterFilter.isActive) filters.tubeExciterFilter.deactivate();
        if (filters.stereoWidthFilter.isActive) filters.stereoWidthFilter.deactivate();
        if (filters.crossfeedFilter.isActive) filters.crossfeedFilter.deactivate();
        if (filters.freeverbFilter.isActive) filters.freeverbFilter.deactivate();
        if (filters.pitchShiftFilter.isActive) filters.pitchShiftFilter.deactivate();
        if (filters.compressorFilter.isActive) filters.compressorFilter.deactivate();
        if (filters.limiterFilter.isActive) filters.limiterFilter.deactivate();
        return;
      }

      // Order of activation:
      // Tone Shaping -> Spatial Enhancement -> Dynamics/Limiter
      // 1. Dynamic Bass Boost
      if (state.bassBoostEnabled) {
        if (!filters.bassBoostFilter.isActive) filters.bassBoostFilter.activate();
        filters.bassBoostFilter.boost.value = state.bassBoostAmount;
        filters.bassBoostFilter.wet.value = (state.bassBoostWet * state.masterWet).clamp(0.0, 1.0);
      } else if (filters.bassBoostFilter.isActive) {
        filters.bassBoostFilter.deactivate();
      }

      // 2. Tube Harmonic Exciter
      if (state.tubeExciterEnabled) {
        if (!filters.tubeExciterFilter.isActive) filters.tubeExciterFilter.activate();
        filters.tubeExciterFilter.drive.value = state.tubeDrive;
        filters.tubeExciterFilter.warmth.value = state.tubeWarmth;
        filters.tubeExciterFilter.mix.value = (state.tubeMix * state.masterWet).clamp(0.0, 1.0);
      } else if (filters.tubeExciterFilter.isActive) {
        filters.tubeExciterFilter.deactivate();
      }

      // 3. Stereo Width Matrix
      if (state.stereoWidthEnabled) {
        if (!filters.stereoWidthFilter.isActive) filters.stereoWidthFilter.activate();
        filters.stereoWidthFilter.width.value = state.stereoWidth;
        filters.stereoWidthFilter.midGain.value = state.stereoMidGain;
        filters.stereoWidthFilter.wet.value = (state.stereoWet * state.masterWet).clamp(0.0, 1.0);
      } else if (filters.stereoWidthFilter.isActive) {
        filters.stereoWidthFilter.deactivate();
      }

      // 4. Binaural Crossfeed
      if (state.crossfeedEnabled) {
        if (!filters.crossfeedFilter.isActive) filters.crossfeedFilter.activate();
        filters.crossfeedFilter.cutoff.value = state.crossfeedCutoff;
        filters.crossfeedFilter.feed.value = state.crossfeedFeed;
        filters.crossfeedFilter.delayMs.value = state.crossfeedDelayMs;
        filters.crossfeedFilter.wet.value = (state.crossfeedWet * state.masterWet).clamp(0.0, 1.0);
      } else if (filters.crossfeedFilter.isActive) {
        filters.crossfeedFilter.deactivate();
      }

      // 5. Spatial Studio Reverb
      if (state.reverbEnabled) {
        if (!filters.freeverbFilter.isActive) filters.freeverbFilter.activate();
        filters.freeverbFilter.roomSize.value = state.reverbRoomSize;
        filters.freeverbFilter.damp.value = state.reverbDamp;
        filters.freeverbFilter.width.value = state.reverbWidth;
        filters.freeverbFilter.freeze.value = state.reverbFreeze ? 1.0 : 0.0;
        filters.freeverbFilter.wet.value = (state.reverbWet * state.masterWet).clamp(0.0, 1.0);
      } else if (filters.freeverbFilter.isActive) {
        filters.freeverbFilter.deactivate();
      }

      // 6. Pitch Shifter
      if (state.pitchShiftEnabled) {
        if (!filters.pitchShiftFilter.isActive) filters.pitchShiftFilter.activate();
        filters.pitchShiftFilter.semitones.value = state.pitchSemitones;
        filters.pitchShiftFilter.wet.value = (state.pitchWet * state.masterWet).clamp(0.0, 1.0);
      } else if (filters.pitchShiftFilter.isActive) {
        filters.pitchShiftFilter.deactivate();
      }

      // 7. Dynamic Compressor (gain reduction before limiter)
      if (state.compressorEnabled) {
        if (!filters.compressorFilter.isActive) filters.compressorFilter.activate();
        filters.compressorFilter.threshold.value = state.compThreshold;
        filters.compressorFilter.ratio.value = state.compRatio;
        filters.compressorFilter.attackTime.value = state.compAttack;
        filters.compressorFilter.releaseTime.value = state.compRelease;
        filters.compressorFilter.makeupGain.value = state.compMakeup;
        filters.compressorFilter.kneeWidth.value = state.compKnee;
        filters.compressorFilter.wet.value = (state.compWet * state.masterWet).clamp(0.0, 1.0);
      } else if (filters.compressorFilter.isActive) {
        filters.compressorFilter.deactivate();
      }

      // 8. Peak Brickwall Limiter (always last to guarantee zero-overshoot protection)
      if (state.limiterEnabled) {
        if (!filters.limiterFilter.isActive) filters.limiterFilter.activate();
        filters.limiterFilter.threshold.value = state.limiterThreshold;
        filters.limiterFilter.outputCeiling.value = state.limiterOutputCeiling;
        filters.limiterFilter.attackTime.value = state.limiterAttack;
        filters.limiterFilter.releaseTime.value = state.limiterRelease;
        filters.limiterFilter.kneeWidth.value = state.limiterKnee;
        filters.limiterFilter.wet.value = (state.limiterWet * state.masterWet).clamp(0.0, 1.0);
      } else if (filters.limiterFilter.isActive) {
        filters.limiterFilter.deactivate();
      }
    } catch (e) {
      debugPrint('[DspRackController] Non-fatal sync error (e.g. mock test environment): $e');
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
    _syncWithEngine();
  }
}
