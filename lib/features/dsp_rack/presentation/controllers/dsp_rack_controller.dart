import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../audio_engine/virtual_dsp_service.dart';
import '../../../../core/database/local_persistence_service.dart';
import '../../../player/domain/track.dart';
import '../../domain/dsp_models.dart';

final dspRackControllerProvider =
    StateNotifierProvider<DspRackController, DspRackState>((ref) {
  return DspRackController();
});

/// Controller StateNotifier untuk memanipulasi rantai DSP Mastering Rack.
/// Terintegrasi secara seamless dengan VirtualDspService (Single Source of Truth).
class DspRackController extends StateNotifier<DspRackState> {
  DspRackController()
      : super(DspRackState(
          preampDb: VirtualDspService.instance.preampGain,
        )) {
    _hydrateState();
    _loadCustomPresets();
    _loadTrackOverridesAndGenreMappings();
    Future.microtask(() {
      if (_isDisposed || !mounted) return;
      _syncWithEngine();
    });
    VirtualDspService.instance.addListener(_onEngineChanged);
  }

  bool _isDisposed = false;
  List<DspPreset> _customPresets = [];
  Map<String, DspTrackOverride> _trackOverrides = {};
  Map<String, String> _customGenreMappings = {};
  bool _autoApplyGenreEnabled = true;
  DspResolutionResult? _lastResolutionResult;

  List<DspPreset> get customPresets => List.unmodifiable(_customPresets);
  Map<String, DspTrackOverride> get trackOverrides => Map.unmodifiable(_trackOverrides);
  Map<String, String> get customGenreMappings => Map.unmodifiable(_customGenreMappings);
  bool get isAutoApplyGenreEnabled => _autoApplyGenreEnabled;
  DspResolutionResult? get lastResolutionResult => _lastResolutionResult;

  @override
  void dispose() {
    _isDisposed = true;
    VirtualDspService.instance.removeListener(_onEngineChanged);
    super.dispose();
  }

  void _hydrateState() {
    try {
      final saved = LocalPersistenceService.instance.getDspRackState();
      if (saved != null && saved.isNotEmpty) {
        state = DspRackState.fromMap(saved);
      }
    } catch (e) {
      debugPrint('[DspRackController] Error hydrating DSP state: $e');
    }
  }

  void _loadCustomPresets() {
    try {
      final list = LocalPersistenceService.instance.getCustomDspProfiles();
      _customPresets = list.map((m) => DspPreset.fromMap(m)).toList();
    } catch (e) {
      debugPrint('[DspRackController] Error loading custom presets: $e');
    }
  }

  void _loadTrackOverridesAndGenreMappings() {
    try {
      final overridesMap = LocalPersistenceService.instance.getDspTrackOverrides();
      _trackOverrides = overridesMap.map((k, v) => MapEntry(k, DspTrackOverride.fromMap(v)));
      _customGenreMappings = LocalPersistenceService.instance.getDspGenreMappings();
      _autoApplyGenreEnabled = LocalPersistenceService.instance.isDspAutoApplyByGenreEnabled();
    } catch (e) {
      debugPrint('[DspRackController] Error loading overrides/mappings: $e');
    }
  }

  void _persistState() {
    try {
      LocalPersistenceService.instance.saveDspRackState(state.toMap());
    } catch (e) {
      debugPrint('[DspRackController] Error saving DSP state: $e');
    }
  }

  void _onEngineChanged() {
    if (_isDisposed || !mounted) return;
    final dsp = VirtualDspService.instance;
    if ((state.preampDb - dsp.preampGain).abs() > 0.01) {
      Future.microtask(() {
        if (_isDisposed || !mounted) return;
        state = state.copyWith(preampDb: dsp.preampGain);
        _persistState();
      });
    }
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
      _persistState();
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
    state = preset.state.copyWith(
      activePresetId: preset.id,
      revision: state.revision + 1,
    );
    _syncWithEngine();
  }

  Future<void> saveCustomProfile(String name, {String description = ''}) async {
    final newPreset = DspPreset(
      id: 'custom_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim().isEmpty ? 'Custom Preset' : name.trim(),
      description: description,
      state: state,
    );
    _customPresets.add(newPreset);
    state = state.copyWith(
      activePresetId: newPreset.id,
      revision: state.revision + 1,
    );
    await LocalPersistenceService.instance.saveCustomDspProfiles(
      _customPresets.map((p) => p.toMap()).toList(),
    );
    _persistState();
  }

  Future<void> deleteCustomProfile(String id) async {
    _customPresets.removeWhere((p) => p.id == id);
    if (state.activePresetId == id) {
      state = state.copyWith(
        clearPreset: true,
        revision: state.revision + 1,
      );
    }
    await LocalPersistenceService.instance.saveCustomDspProfiles(
      _customPresets.map((p) => p.toMap()).toList(),
    );
  }

  void loadCustomProfile(DspPreset preset) {
    applyPreset(preset);
  }

  void resetToDefaults() {
    state = DspRackState(revision: state.revision + 1);
    _syncWithEngine();
  }

  void resetToBitPerfect() {
    final flatPreset = DspPreset.studioPresets.firstWhere(
      (p) => p.id == 'pure_direct',
      orElse: () => DspPreset.studioPresets[1],
    );
    applyPreset(flatPreset);
  }

  // ─── PER-TRACK & GENRE AUTO-APPLY ENGINE ─────────────────────────────────

  /// Finds a preset by ID from custom profiles or curated studio presets
  DspPreset? findPresetById(String presetId) {
    for (final p in _customPresets) {
      if (p.id == presetId) return p;
    }
    for (final p in DspPreset.studioPresets) {
      if (p.id == presetId) return p;
    }
    return null;
  }

  /// Resolves which DSP preset should be applied for a given track based on
  /// 1. Explicit Track Override (highest priority)
  /// 2. Genre-Based Auto Match (if enabled)
  /// 3. Current active/default preset (fallback)
  DspResolutionResult resolvePresetForTrack(Track track) {
    // 1. Check Track Override
    final override = _trackOverrides[track.id];
    if (override != null) {
      final preset = findPresetById(override.presetId);
      if (preset != null) {
        return DspResolutionResult(
          preset: preset,
          source: DspResolutionSource.trackOverride,
          trackTitle: track.title,
        );
      }
    }

    // 2. Check Genre Auto-Apply
    if (_autoApplyGenreEnabled && track.genre != null && track.genre!.trim().isNotEmpty) {
      final match = GenrePresetMatcher.match(
        track.genre,
        customMappingOverrides: _customGenreMappings,
      );
      if (match != null) {
        final preset = findPresetById(match.targetPresetId) ??
            DspPreset.studioPresets.firstWhere((p) => p.id == 'studio_warmth');
        return DspResolutionResult(
          preset: preset,
          source: DspResolutionSource.genreAuto,
          matchedGenre: match.matchedKeyword,
          trackTitle: track.title,
        );
      }
    }

    // 3. Fallback to active preset or default studio warmth
    final active = findPresetById(state.activePresetId ?? 'studio_warmth') ??
        DspPreset.studioPresets.first;
    return DspResolutionResult(
      preset: active,
      source: DspResolutionSource.manual,
      trackTitle: track.title,
    );
  }

  /// Automatically applies the resolved DSP preset for a track upon playback
  void applyForTrack(Track track) {
    final result = resolvePresetForTrack(track);
    _lastResolutionResult = result;

    // Apply if different from current active preset or if rack state is bypassed/cleared
    if (state.activePresetId != result.preset.id) {
      debugPrint('[DspRackController] Auto-applying DSP Preset "${result.preset.name}" (${result.source.name}) for track: ${track.title}');
      applyPreset(result.preset);
    }
  }

  /// Pins a specific DSP preset to a track (creating a permanent override)
  Future<void> pinPresetForTrack(String trackId, DspPreset preset, {String? trackTitle}) async {
    final override = DspTrackOverride(
      trackId: trackId,
      presetId: preset.id,
      presetName: preset.name,
      assignedAt: DateTime.now(),
    );
    _trackOverrides[trackId] = override;
    _lastResolutionResult = DspResolutionResult(
      preset: preset,
      source: DspResolutionSource.trackOverride,
      trackTitle: trackTitle,
    );
    applyPreset(preset);
    await LocalPersistenceService.instance.saveDspTrackOverride(override.toMap());
  }

  /// Removes track-specific override
  Future<void> unpinPresetForTrack(String trackId, {Track? activeTrack}) async {
    if (_trackOverrides.containsKey(trackId)) {
      _trackOverrides.remove(trackId);
      if (activeTrack != null && activeTrack.id == trackId) {
        applyForTrack(activeTrack);
      } else {
        state = state.copyWith(revision: state.revision + 1);
      }
      await LocalPersistenceService.instance.removeDspTrackOverride(trackId);
    }
  }

  /// Checks if a track has a pinned DSP preset override
  bool isTrackPinned(String trackId) {
    return _trackOverrides.containsKey(trackId);
  }

  /// Returns the pinned override for a track if any
  DspTrackOverride? getTrackOverride(String trackId) {
    return _trackOverrides[trackId];
  }

  /// Updates custom mapping for a specific genre category
  Future<void> updateGenreMapping(String genreKey, String presetId) async {
    _customGenreMappings[genreKey] = presetId;
    state = state.copyWith(revision: state.revision + 1);
    await LocalPersistenceService.instance.saveDspGenreMappings(_customGenreMappings);
  }

  /// Toggles whether Genre Auto-Apply is active
  Future<void> setAutoApplyGenreEnabled(bool enabled) async {
    _autoApplyGenreEnabled = enabled;
    state = state.copyWith(revision: state.revision + 1);
    await LocalPersistenceService.instance.setDspAutoApplyByGenreEnabled(enabled);
  }
}

