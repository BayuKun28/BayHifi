import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'dsp_defaults.dart';
import 'dsp_profile.dart';
import 'soloud_controller.dart';

final virtualDspServiceProvider =
    ChangeNotifierProvider<VirtualDspService>((ref) {
  return VirtualDspService.instance;
});

/// Single Source of Truth untuk pemrosesan DSP Studio SoLoud C++ native.
/// Mengadopsi arsitektur RYNLABS_HIFI untuk menjamin akurasi suara bit-perfect dan zero-clipping.
class VirtualDspService extends ChangeNotifier {
  VirtualDspService._internal();
  static final VirtualDspService instance = VirtualDspService._internal();

  bool _initialized = false;
  bool _masterEnabled = true;

  DspProfile _activeProfile = DspProfile.flatReference;
  DspProfile? _pendingEdits;
  bool _hasUnsavedChanges = false;

  // AutoEQ target & driver overlay caches for visualization
  List<double>? _autoEqTargetOverlay;
  List<double>? _autoEqDriverOverlay;

  bool get initialized => _initialized;
  bool get masterEnabled => _masterEnabled;
  bool get hasUnsavedChanges => _hasUnsavedChanges;
  DspProfile get activeProfile => _pendingEdits ?? _activeProfile;
  List<double>? get autoEqTargetOverlay => _autoEqTargetOverlay;
  List<double>? get autoEqDriverOverlay => _autoEqDriverOverlay;

  // --- Convenience Getters ---
  bool get eqEnabled => activeProfile.eqEnabled;
  bool get bassBoostEnabled => activeProfile.bassBoostEnabled;
  bool get compressorEnabled => activeProfile.compEnabled;
  bool get limiterEnabled => activeProfile.limiterEnabled;
  bool get reverbEnabled => activeProfile.reverbEnabled;
  bool get pitchShiftEnabled => activeProfile.pitchShiftEnabled;
  bool get crossfeedEnabled => activeProfile.crossfeedEnabled;
  bool get tubeEnabled => activeProfile.tubeEnabled;
  bool get stereoWidthEnabled => activeProfile.stereoWidthEnabled;

  List<double> get eqGains => activeProfile.eqGains;
  List<String> get eqFilterTypes => activeProfile.eqFilterTypes;
  List<double> get eqQFactors => activeProfile.eqQFactors;
  List<double> get eqFreqs => activeProfile.eqFreqs;
  double get bassBoostValue => activeProfile.bassBoostValue;
  double get bassBoostWet => activeProfile.bassBoostWet;
  double get compAttack => activeProfile.compAttack;
  double get compRelease => activeProfile.compRelease;
  double get compThreshold => activeProfile.compThreshold;
  double get compRatio => activeProfile.compRatio;
  double get compKnee => activeProfile.compKnee;
  double get compMakeup => activeProfile.compMakeup;
  double get limiterThreshold => activeProfile.limiterThreshold;
  double get limiterAttack => activeProfile.limiterAttack;
  double get limiterRelease => activeProfile.limiterRelease;
  double get limiterOutputCeiling => activeProfile.limiterOutputCeiling;
  double get reverbRoomSize => activeProfile.reverbRoomSize;
  double get reverbDamp => activeProfile.reverbDamp;
  double get reverbWet => activeProfile.reverbWet;
  double get reverbWidth => activeProfile.reverbWidth;
  double get pitchValue => activeProfile.pitchValue;
  double get crossfeedCutoff => activeProfile.crossfeedCutoff;
  double get crossfeedFeed => activeProfile.crossfeedFeed;
  double get crossfeedDelayMs => activeProfile.crossfeedDelayMs;
  double get crossfeedWet => activeProfile.crossfeedWet;
  double get tubeDrive => activeProfile.tubeDrive;
  double get tubeWarmth => activeProfile.tubeWarmth;
  double get tubeMix => activeProfile.tubeMix;
  double get stereoWidthFactor => activeProfile.stereoWidthFactor;
  double get stereoMidGain => activeProfile.stereoMidGain;
  double get stereoWidthWet => activeProfile.stereoWidthWet;
  double get preampGain => activeProfile.preampGain;

  /// Silent volume compensation for Freeverb internal gain
  double get reverbVolumeCompensationDb {
    if (!masterEnabled || !reverbEnabled || reverbWet <= 0.0) return 0.0;
    return -1.0 * (reverbWet * 0.75);
  }

  /// Inisialisasi service DSP
  void init() {
    if (_initialized) return;
    _initialized = true;
    if (SoLoud.instance.isInitialized) {
      _applyProfileToSoLoudSmart(activeProfile);
    }
    notifyListeners();
  }

  DspProfile _ensurePending() => _pendingEdits ?? _activeProfile;

  void _markDirty() {
    _hasUnsavedChanges = true;
  }

  // --- Master Toggle ---
  void setMasterEnabled(bool enabled) {
    _masterEnabled = enabled;
    if (_masterEnabled) {
      _applyProfileToSoLoudSmart(activeProfile);
    } else {
      _deactivateAllFilters();
    }
    SoLoudController.instance.updateEffectiveVolume();
    notifyListeners();
  }

  // --- Auto-Headroom Safe Preamp Calculation ---
  double calculateSafePreamp(List<double> gains) {
    if (gains.isEmpty) return 0.0;
    double maxBoost = 0.0;
    for (final g in gains) {
      if (g > maxBoost) maxBoost = g;
    }
    if (maxBoost <= 0.0) return 0.0;
    return -maxBoost - 0.5; // Offset -0.5 dB untuk proteksi inter-sample peak
  }

  // --- PEQ Controls ---
  void toggleEq(bool enabled) {
    _pendingEdits = _ensurePending().copyWith(eqEnabled: enabled);
    _markDirty();
    if (_masterEnabled) _applyProfileToSoLoudSmart(_pendingEdits!);
    notifyListeners();
  }

  void setEqBand({
    required int bandIndex,
    double? freq,
    double? gainDb,
    double? q,
    String? filterType,
    bool autoHeadroom = true,
  }) {
    final cur = _ensurePending();
    final newGains = List<double>.from(cur.eqGains);
    final newFreqs = List<double>.from(cur.eqFreqs);
    final newQs = List<double>.from(cur.eqQFactors);
    final newTypes = List<String>.from(cur.eqFilterTypes);

    if (bandIndex < 0 || bandIndex >= newGains.length) return;

    if (gainDb != null) newGains[bandIndex] = gainDb;
    if (freq != null) newFreqs[bandIndex] = freq;
    if (q != null) newQs[bandIndex] = q;
    if (filterType != null) newTypes[bandIndex] = filterType;

    double safePreamp = cur.preampGain;
    if (autoHeadroom) {
      safePreamp = calculateSafePreamp(newGains);
    }

    _pendingEdits = cur.copyWith(
      eqGains: newGains,
      eqFreqs: newFreqs,
      eqQFactors: newQs,
      eqFilterTypes: newTypes,
      preampGain: safePreamp,
    );
    _markDirty();

    if (_masterEnabled && eqEnabled) {
      _applyEqBand(bandIndex);
    }
    SoLoudController.instance.updateEffectiveVolume();
    notifyListeners();
  }

  void setAllEqBands({
    required List<double> gains,
    List<double>? freqs,
    List<double>? qs,
    List<String>? types,
    bool autoHeadroom = true,
  }) {
    final cur = _ensurePending();
    final safePreamp = autoHeadroom ? calculateSafePreamp(gains) : cur.preampGain;

    _pendingEdits = cur.copyWith(
      eqGains: List<double>.from(gains),
      eqFreqs: freqs != null ? List<double>.from(freqs) : cur.eqFreqs,
      eqQFactors: qs != null ? List<double>.from(qs) : cur.eqQFactors,
      eqFilterTypes: types != null ? List<String>.from(types) : cur.eqFilterTypes,
      preampGain: safePreamp,
    );
    _markDirty();

    if (_masterEnabled) {
      _applyProfileToSoLoudSmart(_pendingEdits!);
    }
    SoLoudController.instance.updateEffectiveVolume();
    notifyListeners();
  }

  // --- Dynamic Bass Boost Controls ---
  void toggleBassBoost(bool enabled) {
    _pendingEdits = _ensurePending().copyWith(bassBoostEnabled: enabled);
    _markDirty();
    if (_masterEnabled) _applyProfileToSoLoudSmart(_pendingEdits!);
    notifyListeners();
  }

  void setBassBoostValue(double val) {
    _pendingEdits = _ensurePending().copyWith(bassBoostValue: val);
    _markDirty();
    if (bassBoostEnabled) _applyBassBoost();
    notifyListeners();
  }

  void setBassBoostParams({required double boost, required double wet}) {
    _pendingEdits = _ensurePending().copyWith(
      bassBoostValue: boost,
      bassBoostWet: wet.clamp(0.0, 1.0),
    );
    _markDirty();
    if (bassBoostEnabled) _applyBassBoost();
    notifyListeners();
  }

  // --- Dynamic Compressor Controls ---
  void toggleCompressor(bool enabled) {
    _pendingEdits = _ensurePending().copyWith(compEnabled: enabled);
    _markDirty();
    if (_masterEnabled) _applyProfileToSoLoudSmart(_pendingEdits!);
    notifyListeners();
  }

  void setCompressorParams({
    double? threshold,
    double? ratio,
    double? attackMs,
    double? releaseMs,
    double? knee,
    double? makeup,
  }) {
    final cur = _ensurePending();
    _pendingEdits = cur.copyWith(
      compThreshold: threshold ?? cur.compThreshold,
      compRatio: ratio ?? cur.compRatio,
      compAttack: attackMs != null ? attackMs / 1000.0 : cur.compAttack,
      compRelease: releaseMs != null ? releaseMs / 1000.0 : cur.compRelease,
      compKnee: knee ?? cur.compKnee,
      compMakeup: makeup ?? cur.compMakeup,
    );
    _markDirty();
    if (compressorEnabled) _applyCompressor();
    notifyListeners();
  }

  // --- Peak Brickwall Limiter Controls ---
  void toggleLimiter(bool enabled) {
    _pendingEdits = _ensurePending().copyWith(limiterEnabled: enabled);
    _markDirty();
    if (_masterEnabled) _applyProfileToSoLoudSmart(_pendingEdits!);
    notifyListeners();
  }

  void setLimiterParams({
    double? threshold,
    double? attackMs,
    double? releaseMs,
  }) {
    final cur = _ensurePending();
    _pendingEdits = cur.copyWith(
      limiterThreshold: threshold ?? cur.limiterThreshold,
      limiterAttack: attackMs != null ? attackMs / 1000.0 : cur.limiterAttack,
      limiterRelease: releaseMs != null ? releaseMs / 1000.0 : cur.limiterRelease,
    );
    _markDirty();
    if (limiterEnabled) _applyLimiter();
    notifyListeners();
  }

  // --- Spatial Reverb Controls ---
  void toggleReverb(bool enabled) {
    _pendingEdits = _ensurePending().copyWith(reverbEnabled: enabled);
    _markDirty();
    if (_masterEnabled) _applyProfileToSoLoudSmart(_pendingEdits!);
    SoLoudController.instance.updateEffectiveVolume();
    notifyListeners();
  }

  void setReverbParams({
    double? roomSize,
    double? damp,
    double? wet,
    double? width,
  }) {
    final cur = _ensurePending();
    _pendingEdits = cur.copyWith(
      reverbRoomSize: roomSize ?? cur.reverbRoomSize,
      reverbDamp: damp ?? cur.reverbDamp,
      reverbWet: wet ?? cur.reverbWet,
      reverbWidth: width ?? cur.reverbWidth,
    );
    _markDirty();
    if (reverbEnabled) _applyReverb();
    SoLoudController.instance.updateEffectiveVolume();
    notifyListeners();
  }

  // --- Pitch Shifter Controls ---
  void togglePitchShift(bool enabled) {
    _pendingEdits = _ensurePending().copyWith(pitchShiftEnabled: enabled);
    _markDirty();
    if (_masterEnabled) _applyProfileToSoLoudSmart(_pendingEdits!);
    notifyListeners();
  }

  void setPitchValue(double val) {
    _pendingEdits = _ensurePending().copyWith(pitchValue: val);
    _markDirty();
    if (pitchShiftEnabled) _applyPitchShift();
    notifyListeners();
  }

  // --- Binaural Crossfeed Controls ---
  void toggleCrossfeed(bool enabled) {
    _pendingEdits = _ensurePending().copyWith(crossfeedEnabled: enabled);
    _markDirty();
    if (_masterEnabled) _applyProfileToSoLoudSmart(_pendingEdits!);
    notifyListeners();
  }

  void setCrossfeedParams({
    double? cutoff,
    double? feed,
    double? delayMs,
    double? wet,
  }) {
    final cur = _ensurePending();
    _pendingEdits = cur.copyWith(
      crossfeedCutoff: cutoff ?? cur.crossfeedCutoff,
      crossfeedFeed: feed ?? cur.crossfeedFeed,
      crossfeedDelayMs: delayMs ?? cur.crossfeedDelayMs,
      crossfeedWet: wet ?? cur.crossfeedWet,
    );
    _markDirty();
    if (crossfeedEnabled) _applyCrossfeed();
    notifyListeners();
  }

  // --- Tube Exciter Controls ---
  void toggleTubeExciter(bool enabled) {
    _pendingEdits = _ensurePending().copyWith(tubeEnabled: enabled);
    _markDirty();
    if (_masterEnabled) _applyProfileToSoLoudSmart(_pendingEdits!);
    notifyListeners();
  }

  void setTubeParams({
    double? drive,
    double? warmth,
    double? mix,
  }) {
    final cur = _ensurePending();
    _pendingEdits = cur.copyWith(
      tubeDrive: drive ?? cur.tubeDrive,
      tubeWarmth: warmth ?? cur.tubeWarmth,
      tubeMix: mix ?? cur.tubeMix,
    );
    _markDirty();
    if (tubeEnabled) _applyTubeExciter();
    notifyListeners();
  }

  // --- Stereo Width Controls ---
  void toggleStereoWidth(bool enabled) {
    _pendingEdits = _ensurePending().copyWith(stereoWidthEnabled: enabled);
    _markDirty();
    if (_masterEnabled) _applyProfileToSoLoudSmart(_pendingEdits!);
    notifyListeners();
  }

  void setStereoWidthParams({
    double? factor,
    double? midGain,
    double? wet,
  }) {
    final cur = _ensurePending();
    _pendingEdits = cur.copyWith(
      stereoWidthFactor: factor ?? cur.stereoWidthFactor,
      stereoMidGain: midGain ?? cur.stereoMidGain,
      stereoWidthWet: wet ?? cur.stereoWidthWet,
    );
    _markDirty();
    if (stereoWidthEnabled) _applyStereoWidth();
    notifyListeners();
  }

  // --- Preamp Gain Control ---
  void setPreampGain(double value) {
    _pendingEdits = _ensurePending().copyWith(preampGain: value.clamp(-24.0, 24.0));
    _markDirty();
    SoLoudController.instance.updateEffectiveVolume();
    notifyListeners();
  }

  // --- Save / Load / Reset Profiles ---
  void saveChanges() {
    if (_pendingEdits != null) {
      _activeProfile = _pendingEdits!;
      _pendingEdits = null;
      _hasUnsavedChanges = false;
      notifyListeners();
    }
  }

  void discardChanges() {
    _pendingEdits = null;
    _hasUnsavedChanges = false;
    if (_masterEnabled) {
      _applyProfileToSoLoudSmart(_activeProfile);
    }
    SoLoudController.instance.updateEffectiveVolume();
    notifyListeners();
  }

  void resetToFlatReference() {
    _activeProfile = DspProfile.flatReference;
    _pendingEdits = null;
    _hasUnsavedChanges = false;
    if (_masterEnabled) {
      _applyProfileToSoLoudSmart(_activeProfile);
    }
    SoLoudController.instance.updateEffectiveVolume();
    notifyListeners();
  }

  void setAutoEqTargetOverlay(List<double>? overlay) {
    _autoEqTargetOverlay = overlay;
    notifyListeners();
  }

  void setAutoEqDriverOverlay(List<double>? overlay) {
    _autoEqDriverOverlay = overlay;
    notifyListeners();
  }

  // ─── LOW-LEVEL SOLOUD C++ FILTER SEQUENCING (RYNLABS_HIFI FLOW) ────────────

  void _deactivateAllFilters() {
    if (kIsWeb) return;
    try {
      if (!SoLoud.instance.isInitialized) return;
      _deactivateEq();
      _deactivateBassBoost();
      _deactivateCompressor();
      _deactivateTubeExciter();
      _deactivateStereoWidth();
      _deactivateCrossfeed();
      _deactivateReverb();
      _deactivatePitchShift();
      _deactivateLimiter();
    } catch (e) {
      debugPrint('[VirtualDspService] Non-fatal deactivate all: $e');
    }
  }

  /// Rebuilds the C++ filter chain completely in strict mastering order:
  /// Max 8 concurrent active filters enforced by SoLoud C++ engine.
  void _rebuildChain(DspProfile profile) {
    if (kIsWeb) return;
    if (!SoLoud.instance.isInitialized) return;
    _deactivateAllFilters();

    int activeCount = 0;
    void tryActivate(bool enabled, void Function() activateFn) {
      if (enabled && activeCount < 8) {
        try {
          activateFn();
          activeCount++;
        } catch (e) {
          debugPrint('[VirtualDspService] Filter activation error: $e');
        }
      }
    }

    // 1. Tonal Correction
    tryActivate(profile.eqEnabled, _activateEq);
    tryActivate(profile.bassBoostEnabled, _activateBassBoost);

    // 2. Dynamic Control
    tryActivate(profile.compEnabled, _activateCompressor);

    // 3. Harmonic Exciter
    tryActivate(profile.tubeEnabled, _activateTubeExciter);

    // 4. Spatial Processing (Width first, then Headphone Crossfeed)
    tryActivate(profile.stereoWidthEnabled, _activateStereoWidth);
    tryActivate(profile.crossfeedEnabled, _activateCrossfeed);

    // 5. Ambience
    tryActivate(profile.reverbEnabled, _activateReverb);

    // 6. Time & Pitch Processing (Before Limiter to catch transient spikes)
    tryActivate(profile.pitchShiftEnabled, _activatePitchShift);

    // 7. Final Brickwall Safety Net (ALWAYS LAST)
    tryActivate(profile.limiterEnabled, _activateLimiter);
  }

  void _applyProfileToSoLoudSmart(DspProfile profile) {
    if (!_masterEnabled) {
      _deactivateAllFilters();
      return;
    }
    _rebuildChain(profile);
  }

  // --- Filter Activation & Application ---

  void _activateEq() {
    try {
      if (!SoLoud.instance.isInitialized) return;
      final filter = SoLoud.instance.filters.parametricEqFilter;
      if (!filter.isActive) {
        filter
          ..activate()
          ..bandCount.value = eqGains.length.toDouble();
      }
      for (int i = 0; i < eqGains.length; i++) {
        _applyEqBand(i);
      }
    } catch (e) {
      debugPrint('[VirtualDspService] EQ activate error: $e');
    }
  }

  void _deactivateEq() {
    try {
      if (!SoLoud.instance.isInitialized) return;
      if (SoLoud.instance.filters.parametricEqFilter.isActive) {
        SoLoud.instance.filters.parametricEqFilter.deactivate();
      }
    } catch (e) {
      debugPrint('[VirtualDspService] EQ deactivate error: $e');
    }
  }

  void _applyEqBand(int band) {
    try {
      if (!SoLoud.instance.isInitialized) return;
      final filter = SoLoud.instance.filters.parametricEqFilter;
      final gains = eqGains;
      if (band < 0 || band >= gains.length) return;
      final db = gains[band];
      final freq = (band < eqFreqs.length) ? eqFreqs[band] : 1000.0;

      int typeVal = 0; // 0 = Peaking/Bell
      if (band < eqFilterTypes.length) {
        final tName = eqFilterTypes[band].toLowerCase().replaceAll('_', '').replaceAll('-', '');
        if (tName.contains('lowshelf') || tName == 'ls') {
          typeVal = 1;
        } else if (tName.contains('highshelf') || tName == 'hs') {
          typeVal = 2;
        } else if (tName.contains('lowpass') || tName == 'lp') {
          typeVal = 3;
        } else if (tName.contains('highpass') || tName == 'hp') {
          typeVal = 4;
        } else if (tName.contains('bandpass') || tName == 'bp') {
          typeVal = 5;
        }
      }

      final qVal = (band < eqQFactors.length) ? eqQFactors[band] : DspDefaults.peqBellQ;

      filter.bandType(band).value = typeVal.toDouble();
      filter.bandFrequency(band).value = freq;
      filter.bandGainDb(band).value = db;
      filter.bandQ(band).value = qVal;
    } catch (e) {
      debugPrint('[VirtualDspService] EQ band $band error: $e');
    }
  }

  void _activateBassBoost() {
    try {
      if (!SoLoud.instance.isInitialized) return;
      final filter = SoLoud.instance.filters.bassBoostFilter;
      if (!filter.isActive) filter.activate();
      _applyBassBoost();
    } catch (e) {
      debugPrint('[VirtualDspService] BassBoost activate error: $e');
    }
  }

  void _deactivateBassBoost() {
    try {
      if (!SoLoud.instance.isInitialized) return;
      if (SoLoud.instance.filters.bassBoostFilter.isActive) {
        SoLoud.instance.filters.bassBoostFilter.deactivate();
      }
    } catch (e) {
      debugPrint('[VirtualDspService] BassBoost deactivate error: $e');
    }
  }

  void _applyBassBoost() {
    try {
      if (!SoLoud.instance.isInitialized) return;
      SoLoud.instance.filters.bassBoostFilter.boost.value = bassBoostValue.clamp(0.0, 3.5);
      SoLoud.instance.filters.bassBoostFilter.wet.value = bassBoostWet.clamp(0.0, 1.0);
    } catch (e) {
      debugPrint('[VirtualDspService] BassBoost apply error: $e');
    }
  }

  void _activateCompressor() {
    try {
      if (!SoLoud.instance.isInitialized) return;
      final filter = SoLoud.instance.filters.compressorFilter;
      if (!filter.isActive) filter.activate();
      _applyCompressor();
    } catch (e) {
      debugPrint('[VirtualDspService] Compressor activate error: $e');
    }
  }

  void _deactivateCompressor() {
    try {
      if (!SoLoud.instance.isInitialized) return;
      if (SoLoud.instance.filters.compressorFilter.isActive) {
        SoLoud.instance.filters.compressorFilter.deactivate();
      }
    } catch (e) {
      debugPrint('[VirtualDspService] Compressor deactivate error: $e');
    }
  }

  void _applyCompressor() {
    try {
      if (!SoLoud.instance.isInitialized) return;
      final f = SoLoud.instance.filters.compressorFilter;
      // Unit scaling: konversi detik ke milidetik (* 1000.0) sesuai spesifikasi C++ SoLoud
      f.attackTime.value = compAttack * 1000.0;
      f.releaseTime.value = compRelease * 1000.0;
      f.threshold.value = compThreshold;
      f.ratio.value = compRatio;
      f.kneeWidth.value = compKnee;
    } catch (e) {
      debugPrint('[VirtualDspService] Compressor apply error: $e');
    }
  }

  void _activateLimiter() {
    try {
      if (!SoLoud.instance.isInitialized) return;
      final filter = SoLoud.instance.filters.limiterFilter;
      if (!filter.isActive) filter.activate();
      _applyLimiter();
    } catch (e) {
      debugPrint('[VirtualDspService] Limiter activate error: $e');
    }
  }

  void _deactivateLimiter() {
    try {
      if (!SoLoud.instance.isInitialized) return;
      if (SoLoud.instance.filters.limiterFilter.isActive) {
        SoLoud.instance.filters.limiterFilter.deactivate();
      }
    } catch (e) {
      debugPrint('[VirtualDspService] Limiter deactivate error: $e');
    }
  }

  void _applyLimiter() {
    try {
      if (!SoLoud.instance.isInitialized) return;
      final f = SoLoud.instance.filters.limiterFilter;
      f.threshold.value = limiterThreshold;
      // Hard ceiling -1.3 dBFS untuk proteksi inter-sample peak
      f.outputCeiling.value = -1.3;
      f.attackTime.value = limiterAttack * 1000.0;
      f.releaseTime.value = limiterRelease * 1000.0;
    } catch (e) {
      debugPrint('[VirtualDspService] Limiter apply error: $e');
    }
  }

  void _activateReverb() {
    try {
      if (!SoLoud.instance.isInitialized) return;
      final filter = SoLoud.instance.filters.freeverbFilter;
      if (!filter.isActive) filter.activate();
      _applyReverb();
    } catch (e) {
      debugPrint('[VirtualDspService] Reverb activate error: $e');
    }
  }

  void _deactivateReverb() {
    try {
      if (!SoLoud.instance.isInitialized) return;
      if (SoLoud.instance.filters.freeverbFilter.isActive) {
        SoLoud.instance.filters.freeverbFilter.deactivate();
      }
    } catch (e) {
      debugPrint('[VirtualDspService] Reverb deactivate error: $e');
    }
  }

  void _applyReverb() {
    try {
      if (!SoLoud.instance.isInitialized) return;
      final f = SoLoud.instance.filters.freeverbFilter;
      f.roomSize.value = reverbRoomSize;
      f.damp.value = reverbDamp;
      f.wet.value = reverbWet;
      f.width.value = reverbWidth;
    } catch (e) {
      debugPrint('[VirtualDspService] Reverb apply error: $e');
    }
  }

  void _activatePitchShift() {
    try {
      if (!SoLoud.instance.isInitialized) return;
      final filter = SoLoud.instance.filters.pitchShiftFilter;
      if (!filter.isActive) filter.activate();
      _applyPitchShift();
    } catch (e) {
      debugPrint('[VirtualDspService] PitchShift activate error: $e');
    }
  }

  void _deactivatePitchShift() {
    try {
      if (!SoLoud.instance.isInitialized) return;
      if (SoLoud.instance.filters.pitchShiftFilter.isActive) {
        SoLoud.instance.filters.pitchShiftFilter.deactivate();
      }
    } catch (e) {
      debugPrint('[VirtualDspService] PitchShift deactivate error: $e');
    }
  }

  void _applyPitchShift() {
    try {
      if (!SoLoud.instance.isInitialized) return;
      SoLoud.instance.filters.pitchShiftFilter.shift.value = pitchValue;
    } catch (e) {
      debugPrint('[VirtualDspService] PitchShift apply error: $e');
    }
  }

  void _activateCrossfeed() {
    try {
      if (!SoLoud.instance.isInitialized) return;
      final filter = SoLoud.instance.filters.crossfeedFilter;
      if (!filter.isActive) filter.activate();
      _applyCrossfeed();
    } catch (e) {
      debugPrint('[VirtualDspService] Crossfeed activate error: $e');
    }
  }

  void _deactivateCrossfeed() {
    try {
      if (!SoLoud.instance.isInitialized) return;
      if (SoLoud.instance.filters.crossfeedFilter.isActive) {
        SoLoud.instance.filters.crossfeedFilter.deactivate();
      }
    } catch (e) {
      debugPrint('[VirtualDspService] Crossfeed deactivate error: $e');
    }
  }

  void _applyCrossfeed() {
    try {
      if (!SoLoud.instance.isInitialized) return;
      final f = SoLoud.instance.filters.crossfeedFilter;
      f.cutoff.value = crossfeedCutoff;
      f.feed.value = crossfeedFeed;
      f.delayMs.value = crossfeedDelayMs;
      f.wet.value = crossfeedWet;
    } catch (e) {
      debugPrint('[VirtualDspService] Crossfeed apply error: $e');
    }
  }

  void _activateTubeExciter() {
    try {
      if (!SoLoud.instance.isInitialized) return;
      final filter = SoLoud.instance.filters.tubeExciterFilter;
      if (!filter.isActive) filter.activate();
      _applyTubeExciter();
    } catch (e) {
      debugPrint('[VirtualDspService] TubeExciter activate error: $e');
    }
  }

  void _deactivateTubeExciter() {
    try {
      if (!SoLoud.instance.isInitialized) return;
      if (SoLoud.instance.filters.tubeExciterFilter.isActive) {
        SoLoud.instance.filters.tubeExciterFilter.deactivate();
      }
    } catch (e) {
      debugPrint('[VirtualDspService] TubeExciter deactivate error: $e');
    }
  }

  void _applyTubeExciter() {
    try {
      if (!SoLoud.instance.isInitialized) return;
      final f = SoLoud.instance.filters.tubeExciterFilter;
      f.drive.value = tubeDrive;
      f.warmth.value = tubeWarmth;
      f.mix.value = tubeMix;
    } catch (e) {
      debugPrint('[VirtualDspService] TubeExciter apply error: $e');
    }
  }

  void _activateStereoWidth() {
    try {
      if (!SoLoud.instance.isInitialized) return;
      final filter = SoLoud.instance.filters.stereoWidthFilter;
      if (!filter.isActive) filter.activate();
      _applyStereoWidth();
    } catch (e) {
      debugPrint('[VirtualDspService] StereoWidth activate error: $e');
    }
  }

  void _deactivateStereoWidth() {
    try {
      if (!SoLoud.instance.isInitialized) return;
      if (SoLoud.instance.filters.stereoWidthFilter.isActive) {
        SoLoud.instance.filters.stereoWidthFilter.deactivate();
      }
    } catch (e) {
      debugPrint('[VirtualDspService] StereoWidth deactivate error: $e');
    }
  }

  void _applyStereoWidth() {
    try {
      if (!SoLoud.instance.isInitialized) return;
      final f = SoLoud.instance.filters.stereoWidthFilter;
      f.width.value = stereoWidthFactor;
      f.midGain.value = stereoMidGain;
      f.wet.value = stereoWidthWet;
    } catch (e) {
      debugPrint('[VirtualDspService] StereoWidth apply error: $e');
    }
  }
}
