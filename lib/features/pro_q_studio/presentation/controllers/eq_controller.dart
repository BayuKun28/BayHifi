import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/local_persistence_service.dart';
import '../../../../audio_engine/virtual_dsp_service.dart';
import '../../domain/auto_eq_optimizer.dart';
import '../../domain/biquad_math.dart';
import '../../domain/eq_band.dart';
import '../../domain/fr_curve_data.dart';
import '../../domain/pro_q_rta_style.dart';
import '../../domain/squiglink_parser.dart';
import 'eq_state.dart';

final eqControllerProvider =
    StateNotifierProvider<EqController, EqState>((ref) {
  return EqController();
});

class EqController extends StateNotifier<EqState> {
  EqController()
      : super(EqState(
          bands: EqBand.default10Bands,
          selectedBandIndex: 1, // Selected on B1 by default
          safePreampDb: VirtualDspService.instance.preampGain != 0.0
              ? VirtualDspService.instance.preampGain
              : -2.0,
        )) {
    _hydrateActiveState();
    _loadSampleCurves();
    _loadCustomPresetNames();
    Future.microtask(() {
      if (_isDisposed || !mounted) return;
      _recalculateSafePreamp();
      _syncWithVirtualDsp();
    });
    VirtualDspService.instance.addListener(_onDspServiceChanged);
  }

  bool _isDisposed = false;

  void hydrateFromStorage() {
    _hydrateActiveState();
    _loadCustomPresetNames();
    _recalculateSafePreamp();
    _syncWithVirtualDsp();
  }

  void _hydrateActiveState() {
    try {
      final rtaStyleStr = LocalPersistenceService.instance.getSetting<String>('pro_q_rta_style');
      final persistedRtaStyle = ProQRtaStyle.fromString(rtaStyleStr);
      if (state.rtaStyle != persistedRtaStyle) {
        state = state.copyWith(rtaStyle: persistedRtaStyle);
      }

      final saved = LocalPersistenceService.instance.getActiveEqState();
      if (saved != null && saved.isNotEmpty) {
        final bandMaps = saved['bands'];
        List<EqBand>? bands;
        if (bandMaps is List) {
          bands = bandMaps
              .whereType<Map<String, dynamic>>()
              .toList()
              .asMap()
              .entries
              .map((e) => EqBand.fromMap(e.value, fallbackIndex: e.key + 1))
              .toList();
        }

        final preamp = (saved['preampDb'] as num? ?? state.safePreampDb).toDouble();
        final presetName = (saved['activePresetName'] as String?) ?? state.activePresetName;
        final isAuto = (saved['isAutoEqActive'] as bool?) ?? presetName.startsWith('AutoEQ:');
        final isEnabled = (saved['isEnabled'] as bool?) ?? state.isEnabled;

        // Band resolution & tuning mode
        BandResolution bandRes = state.bandResolution;
        final resStr = saved['bandResolution'] as String?;
        if (resStr != null) {
          bandRes = BandResolution.values.firstWhere(
            (r) => r.name == resStr,
            orElse: () => state.bandResolution,
          );
        }

        TuningMode tuningMode = state.tuningMode;
        final modeStr = saved['tuningMode'] as String?;
        if (modeStr != null) {
          tuningMode = TuningMode.values.firstWhere(
            (m) => m.name == modeStr,
            orElse: () => state.tuningMode,
          );
        }

        // Synchronously deserialize driver & target curves if available
        FrCurveData? driver;
        final driverMap = saved['lastDriverCurve'];
        if (driverMap is Map<String, dynamic> && driverMap.isNotEmpty) {
          try {
            final parsed = FrCurveData.fromMap(driverMap);
            if (parsed.frequencies.isNotEmpty) {
              driver = parsed;
            }
          } catch (_) {}
        }
        if (driver == null) {
          final lastDriverName = saved['lastDriverName'] as String?;
          if (lastDriverName != null && lastDriverName.trim().isNotEmpty) {
            final norm = lastDriverName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
            driver = FrCurveData.defaultDrivers.cast<FrCurveData?>().firstWhere(
              (d) => d != null && (d.name.toLowerCase() == lastDriverName.toLowerCase() ||
                  d.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '') == norm),
              orElse: () => null,
            );
          }
        }

        FrCurveData? target;
        final targetMap = saved['lastTargetCurve'];
        if (targetMap is Map<String, dynamic> && targetMap.isNotEmpty) {
          try {
            final parsed = FrCurveData.fromMap(targetMap);
            if (parsed.frequencies.isNotEmpty) {
              target = parsed;
            }
          } catch (_) {}
        }
        if (target == null) {
          final lastTargetName = saved['lastTargetName'] as String?;
          if (lastTargetName != null && lastTargetName.trim().isNotEmpty) {
            final norm = lastTargetName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');
            target = FrCurveData.defaultTargets.cast<FrCurveData?>().firstWhere(
              (t) => t != null && (t.name.toLowerCase() == lastTargetName.toLowerCase() ||
                  t.name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '') == norm),
              orElse: () => null,
            );
          }
        }

        state = state.copyWith(
          bands: bands != null && bands.isNotEmpty ? bands : state.bands,
          safePreampDb: preamp,
          activePresetName: presetName,
          selectedBandIndex: () => bands != null && bands.isNotEmpty ? bands.first.index : state.selectedBandIndex,
          isAutoEqActive: isAuto,
          isEnabled: isEnabled,
          rtaStyle: persistedRtaStyle,
          bandResolution: bandRes,
          tuningMode: tuningMode,
          driverFr: driver != null ? () => driver : null,
          targetFr: target != null ? () => target : null,
        );
      }
    } catch (_) {}
  }

  void _persistActiveState({bool preserveCurvesIfNull = true}) {
    try {
      final saved = LocalPersistenceService.instance.getActiveEqState();
      final driverName = state.driverFr?.name ??
          (preserveCurvesIfNull ? (saved?['lastDriverName'] as String?) : null);
      final targetName = state.targetFr?.name ??
          (preserveCurvesIfNull ? (saved?['lastTargetName'] as String?) : null);
      final driverMap = state.driverFr?.toMap(category: 'driver') ??
          (preserveCurvesIfNull ? (saved?['lastDriverCurve'] as Map<String, dynamic>?) : null);
      final targetMap = state.targetFr?.toMap(category: 'target') ??
          (preserveCurvesIfNull ? (saved?['lastTargetCurve'] as Map<String, dynamic>?) : null);

      LocalPersistenceService.instance.saveActiveEqState(
        bands: state.bands.map((b) => b.toMap()).toList(),
        preampDb: state.safePreampDb,
        activePresetName: state.activePresetName,
        lastDriverName: driverName,
        lastTargetName: targetName,
        lastDriverCurve: driverMap,
        lastTargetCurve: targetMap,
        preserveCurvesIfNull: preserveCurvesIfNull,
        isAutoEqActive: state.isAutoEqActive,
        isEnabled: state.isEnabled,
        bandResolution: state.bandResolution.name,
        tuningMode: state.tuningMode.name,
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _isDisposed = true;
    VirtualDspService.instance.removeListener(_onDspServiceChanged);
    super.dispose();
  }

  void _onDspServiceChanged() {
    if (_isDisposed || !mounted) return;
    final enginePreamp = VirtualDspService.instance.preampGain;
    if ((state.safePreampDb - enginePreamp).abs() > 0.01) {
      Future.microtask(() {
        if (_isDisposed || !mounted) return;
        state = state.copyWith(safePreampDb: enginePreamp);
      });
    }
  }

  void _syncWithVirtualDsp() {
    final dsp = VirtualDspService.instance;
    final isEqActive = state.isEnabled && !state.isRawBypassed;
    dsp.toggleEq(isEqActive);

    final gains = state.bands.map((b) => b.isEnabled ? b.gainDb : 0.0).toList();
    final freqs = state.bands.map((b) => b.frequency).toList();
    final qs = state.bands.map((b) => b.q).toList();
    final types = state.bands.map((b) => b.type.name).toList();

    dsp.setAllEqBands(
      gains: gains,
      freqs: freqs,
      qs: qs,
      types: types,
      autoHeadroom: state.autoPreampEnabled,
    );
  }

  Future<void> _loadSampleCurves() async {
    // 1. Inisialisasi dengan Single Source of Truth kurva bawaan studio
    final drivers = List<FrCurveData>.from(FrCurveData.defaultDrivers);
    final targets = List<FrCurveData>.from(FrCurveData.defaultTargets);

    try {
      final driverText = await rootBundle
          .loadString('assets/samples/drivers/KZ_CASTOR_BLACK_DUDU_R.txt');
      final targetText =
          await rootBundle.loadString('assets/samples/targets/HBB_Target.txt');

      final driver = FrCurveData.parseRewV5(
        driverText,
        name: 'KZ CASTOR BLACK DUDU R',
      );
      final target = FrCurveData.parseSquiglinkCsv(
        targetText,
        name: 'HBB Target',
      );

      final dIdx = drivers.indexWhere((d) => d.name == driver.name);
      if (dIdx >= 0) {
        drivers[dIdx] = driver;
      } else {
        drivers.add(driver);
      }

      final tIdx = targets.indexWhere((t) => t.name == target.name);
      if (tIdx >= 0) {
        targets[tIdx] = target;
      } else {
        targets.add(target);
      }
    } catch (_) {
      // Graceful fallback jika running di test tanpa rootBundle
    }

    if (_isDisposed || !mounted) return;

    // 2. Hydrate kurva offline yang disimpan pengguna dari LocalPersistenceService
    try {
      final savedMaps = LocalPersistenceService.instance.getSavedFrCurves();
      for (final map in savedMaps) {
        final curve = FrCurveData.fromMap(map);
        final category = map['category'] as String?;
        if (category == 'target' || curve.name.toLowerCase().contains('target')) {
          final idx = targets.indexWhere((t) => t.name == curve.name);
          if (idx >= 0) {
            targets[idx] = curve;
          } else {
            targets.add(curve);
          }
        } else {
          final idx = drivers.indexWhere((d) => d.name == curve.name);
          if (idx >= 0) {
            drivers[idx] = curve;
          } else {
            drivers.add(curve);
          }
        }
      }
    } catch (_) {}

    if (_isDisposed || !mounted) return;

    // 3. Resolve persistent last selected Driver & Target
    final savedEq = LocalPersistenceService.instance.getActiveEqState();
    final lastDriverName = state.driverFr?.name ?? (savedEq?['lastDriverName'] as String?);
    final lastTargetName = state.targetFr?.name ?? (savedEq?['lastTargetName'] as String?);
    final lastDriverCurveMap = savedEq?['lastDriverCurve'] as Map<String, dynamic>?;
    final lastTargetCurveMap = savedEq?['lastTargetCurve'] as Map<String, dynamic>?;

    String normalize(String s) => s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

    FrCurveData? selectedDriver;
    if (state.driverFr != null) {
      final match = drivers.firstWhere(
        (d) => d.name == state.driverFr!.name || normalize(d.name) == normalize(state.driverFr!.name),
        orElse: () => state.driverFr!,
      );
      selectedDriver = match;
      if (!drivers.any((d) => d.name == match.name)) {
        drivers.add(match);
      }
    } else if (lastDriverName != null && lastDriverName.trim().isNotEmpty) {
      final normTarget = normalize(lastDriverName);
      selectedDriver = drivers.cast<FrCurveData?>().firstWhere(
        (d) => d != null && (d.name == lastDriverName || normalize(d.name) == normTarget),
        orElse: () => null,
      );
    }
    if (selectedDriver == null && lastDriverCurveMap != null && lastDriverCurveMap.isNotEmpty) {
      try {
        final curve = FrCurveData.fromMap(lastDriverCurveMap);
        if (curve.frequencies.isNotEmpty) {
          selectedDriver = curve;
          if (!drivers.any((d) => d.name == curve.name)) {
            drivers.add(curve);
          }
        }
      } catch (_) {}
    }
    selectedDriver ??= state.driverFr ?? (drivers.isNotEmpty ? drivers.first : null);

    FrCurveData? selectedTarget;
    if (state.targetFr != null) {
      final match = targets.firstWhere(
        (t) => t.name == state.targetFr!.name || normalize(t.name) == normalize(state.targetFr!.name),
        orElse: () => state.targetFr!,
      );
      selectedTarget = match;
      if (!targets.any((t) => t.name == match.name)) {
        targets.add(match);
      }
    } else if (lastTargetName != null && lastTargetName.trim().isNotEmpty) {
      final normTarget = normalize(lastTargetName);
      selectedTarget = targets.cast<FrCurveData?>().firstWhere(
        (t) => t != null && (t.name == lastTargetName || normalize(t.name) == normTarget),
        orElse: () => null,
      );
    }
    if (selectedTarget == null && lastTargetCurveMap != null && lastTargetCurveMap.isNotEmpty) {
      try {
        final curve = FrCurveData.fromMap(lastTargetCurveMap);
        if (curve.frequencies.isNotEmpty) {
          selectedTarget = curve;
          if (!targets.any((t) => t.name == curve.name)) {
            targets.add(curve);
          }
        }
      } catch (_) {}
    }
    selectedTarget ??= state.targetFr ?? (targets.isNotEmpty ? targets.first : null);

    if (_isDisposed || !mounted) return;
    state = state.copyWith(
      driverFr: () => selectedDriver,
      targetFr: () => selectedTarget,
      availableDrivers: drivers,
      availableTargets: targets,
    );
  }

  void selectBand(int? index) {
    state = state.copyWith(selectedBandIndex: () => index);
  }

  void updateBandFreq(int index, double freq) {
    final clampedFreq = freq.clamp(20.0, 20000.0);
    final updated = state.bands.map((b) {
      if (b.index == index) {
        return b.copyWith(frequency: clampedFreq);
      }
      return b;
    }).toList();

    _updateBands(updated);
  }

  void updateBandGain(int index, double gainDb) {
    final clampedGain = (gainDb.clamp(-24.0, 24.0) * 10).round() / 10.0;
    final updated = state.bands.map((b) {
      if (b.index == index) {
        return b.copyWith(gainDb: clampedGain);
      }
      return b;
    }).toList();

    _updateBands(updated);
  }

  void updateBandQ(int index, double q) {
    final clampedQ = (q.clamp(0.1, 18.0) * 100).round() / 100.0;
    final updated = state.bands.map((b) {
      if (b.index == index) {
        return b.copyWith(q: clampedQ);
      }
      return b;
    }).toList();

    _updateBands(updated);
  }

  void updateBandType(int index, FilterType type) {
    final updated = state.bands.map((b) {
      if (b.index == index) {
        return b.copyWith(type: type);
      }
      return b;
    }).toList();

    _updateBands(updated);
  }

  void toggleBand(int index) {
    final updated = state.bands.map((b) {
      if (b.index == index) {
        return b.copyWith(isEnabled: !b.isEnabled);
      }
      return b;
    }).toList();

    _updateBands(updated);
  }

  void resetActiveBand() {
    final active = state.selectedBandIndex;
    if (active == null) return;
    updateBandGain(active, 0.0);
  }

  void addBand({double? freq, double? gain}) {
    if (state.bands.length >= 32) return; // Maksimal 32 band

    final nextIndex = (state.bands.map((b) => b.index).fold<int>(0, (max, i) => i > max ? i : max)) + 1;
    final defaultFreq = freq ?? 1000.0;
    final defaultGain = gain ?? 0.0;
    final paletteColor = EqBand.bandPalette[(nextIndex - 1) % EqBand.bandPalette.length];

    final newBand = EqBand(
      index: nextIndex,
      frequency: defaultFreq,
      gainDb: defaultGain,
      q: 1.41,
      type: FilterType.peaking,
      color: paletteColor,
    );

    final updated = [...state.bands, newBand];
    updated.sort((a, b) => a.frequency.compareTo(b.frequency));

    final reindexed = <EqBand>[];
    for (int i = 0; i < updated.length; i++) {
      reindexed.add(updated[i].copyWith(
        index: i + 1,
        color: EqBand.bandPalette[i % EqBand.bandPalette.length],
      ));
    }

    _updateBands(reindexed, selectedIdx: newBand.index);
  }

  void removeBand(int index) {
    if (state.bands.length <= 1) return; // Sisakan minimal 1 band

    final updated = state.bands.where((b) => b.index != index).toList();
    final reindexed = <EqBand>[];
    for (int i = 0; i < updated.length; i++) {
      reindexed.add(updated[i].copyWith(
        index: i + 1,
        color: EqBand.bandPalette[i % EqBand.bandPalette.length],
      ));
    }

    final newSelected = (state.selectedBandIndex == index)
        ? (reindexed.isNotEmpty ? reindexed.first.index : null)
        : state.selectedBandIndex;

    _updateBands(reindexed, selectedIdx: newSelected);
  }

  void resetToDefault() {
    _updateBands(
      EqBand.audiophileWarmthBands,
      selectedIdx: 1,
      presetName: 'Studio Audiophile Warmth',
      markClean: true,
    );
  }

  void resetToBitPerfect() {
    _updateBands(
      EqBand.flatBands,
      selectedIdx: 1,
      presetName: 'Audiophile Bit-Perfect (Flat)',
      markClean: true,
    );
  }

  // ─── Custom EQ Preset Persistence ─────────────────────────────────────────

  /// Loads the list of saved custom preset names from persistence into state.
  void _loadCustomPresetNames() {
    try {
      final names = LocalPersistenceService.instance
          .getCustomEqPresets()
          .map((p) => p['name'] as String? ?? '')
          .where((n) => n.isNotEmpty)
          .toList();
      state = state.copyWith(customPresetNames: names);
    } catch (_) {}
  }

  /// Saves the current EQ bands as a NEW custom preset with the given name,
  /// or OVERWRITES an existing custom preset with that name.
  Future<void> saveAsNewPreset(String name) async {
    if (name.trim().isEmpty) return;
    final trimmedName = name.trim();
    try {
      await LocalPersistenceService.instance.saveCustomEqPreset(
        name: trimmedName,
        preampDb: state.safePreampDb,
        bands: state.bands.map((b) => b.toMap()).toList(),
      );
      final updatedNames = [...state.customPresetNames.where((n) => n != trimmedName), trimmedName];
      state = state.copyWith(
        activePresetName: trimmedName,
        isDirty: false,
        customPresetNames: updatedNames,
      );
    } catch (_) {}
  }

  /// Overwrites the currently-loaded custom preset in persistence
  /// (called when SAVE is pressed and a custom preset is already loaded).
  Future<void> saveToCurrentPreset() async {
    if (!state.isCustomPresetLoaded) return;
    await saveAsNewPreset(state.activePresetName);
  }

  /// Loads a user-saved custom preset by name and applies it.
  Future<void> loadCustomPreset(String name) async {
    try {
      final presets = LocalPersistenceService.instance.getCustomEqPresets();
      final entry = presets.firstWhere(
        (p) => p['name'] == name,
        orElse: () => <String, dynamic>{},
      );
      if (entry.isEmpty) return;

      final bandMaps = entry['bands'];
      if (bandMaps is! List) return;
      final bands = bandMaps
          .whereType<Map<String, dynamic>>()
          .toList()
          .asMap()
          .entries
          .map((e) => EqBand.fromMap(e.value, fallbackIndex: e.key + 1))
          .toList();
      if (bands.isEmpty) return;

      final preamp = (entry['preampDb'] as num? ?? state.safePreampDb).toDouble();
      _updateBands(bands, selectedIdx: bands.first.index, presetName: name, markClean: true);
      state = state.copyWith(safePreampDb: preamp);
    } catch (_) {}
  }

  /// Deletes a user-saved custom preset by name.
  Future<void> deleteCustomPreset(String name) async {
    try {
      await LocalPersistenceService.instance.deleteCustomEqPreset(name);
      final updatedNames = state.customPresetNames.where((n) => n != name).toList();
      final newPresetName = state.activePresetName == name ? 'Custom' : state.activePresetName;
      state = state.copyWith(
        customPresetNames: updatedNames,
        activePresetName: newPresetName,
      );
    } catch (_) {}
  }

  void togglePower() {
    final nextState = !state.isEnabled;
    state = state.copyWith(isEnabled: nextState);
    _syncWithVirtualDsp();
    _persistActiveState();
  }

  void toggleRta() {
    state = state.copyWith(isRtaEnabled: !state.isRtaEnabled);
  }

  void setRtaStyle(ProQRtaStyle style) {
    state = state.copyWith(rtaStyle: style);
    LocalPersistenceService.instance.saveSetting('pro_q_rta_style', style.name);
  }

  void toggleFrCurves() {
    state = state.copyWith(showFrCurves: !state.showFrCurves);
  }

  // ─── AutoEQ & Target Matching Controls ────────────────────────────────────

  void setTuningMode(TuningMode mode) {
    state = state.copyWith(tuningMode: mode);
    _persistActiveState();
  }

  void setBandResolution(BandResolution res) {
    state = state.copyWith(bandResolution: res);
    _persistActiveState();
  }

  void setAbComparison(AbComparisonMode mode) {
    state = state.copyWith(abMode: mode);
    _syncWithVirtualDsp();
  }

  void selectDriver(FrCurveData driver) {
    state = state.copyWith(driverFr: () => driver, showFrCurves: true);
    _persistActiveState();
  }

  void selectTarget(FrCurveData target) {
    state = state.copyWith(targetFr: () => target, showFrCurves: true);
    _persistActiveState();
  }

  void deleteDriver() {
    state = state.copyWith(driverFr: () => null);
    _persistActiveState(preserveCurvesIfNull: false);
  }

  void deleteTarget() {
    state = state.copyWith(targetFr: () => null);
    _persistActiveState(preserveCurvesIfNull: false);
  }

  void clearFrCurves() {
    state = state.copyWith(
      driverFr: () => null,
      targetFr: () => null,
      showFrCurves: false,
    );
    _persistActiveState(preserveCurvesIfNull: false);
  }

  void setPreamp(double gainDb, {bool isAuto = false}) {
    final clamped = gainDb.clamp(-24.0, 24.0);
    state = state.copyWith(
      safePreampDb: clamped,
      autoPreampEnabled: isAuto,
    );
    VirtualDspService.instance.setPreampGain(clamped);
    _persistActiveState();
  }

  void toggleAutoPreamp() {
    final nextAuto = !state.autoPreampEnabled;
    state = state.copyWith(autoPreampEnabled: nextAuto);
    if (nextAuto) {
      _recalculateSafePreamp();
    }
  }

  void importDriver(FrCurveData driver) {
    final currentList = List<FrCurveData>.from(state.availableDrivers);
    currentList.removeWhere((d) => d.name == driver.name);
    currentList.add(driver);

    // Save offline to persistence
    try {
      LocalPersistenceService.instance.saveFrCurve(driver.toMap(category: 'driver'));
    } catch (_) {}

    state = state.copyWith(
      availableDrivers: currentList,
      driverFr: () => driver,
      showFrCurves: true,
    );
    _persistActiveState();
  }

  void importTarget(FrCurveData target) {
    final currentList = List<FrCurveData>.from(state.availableTargets);
    currentList.removeWhere((t) => t.name == target.name);
    currentList.add(target);

    // Save offline to persistence
    try {
      LocalPersistenceService.instance.saveFrCurve(target.toMap(category: 'target'));
    } catch (_) {}

    state = state.copyWith(
      availableTargets: currentList,
      targetFr: () => target,
      showFrCurves: true,
    );
    _persistActiveState();
  }

  bool applyAutoEq() {
    final driver = state.driverFr;
    final target = state.targetFr;

    if (driver == null || target == null) {
      return false;
    }

    final result = AutoEqOptimizer.optimize(
      driverFr: driver,
      targetFr: target,
      resolution: state.bandResolution,
      mode: state.tuningMode,
    );

    _updateBands(
      result.bands,
      selectedIdx: result.bands.isNotEmpty ? result.bands[0].index : 1,
      presetName: 'AutoEQ: ${driver.name} → ${target.name}',
      markClean: true,
    );

    state = state.copyWith(
      isAutoEqActive: true,
      abMode: AbComparisonMode.bActive,
      safePreampDb: result.safePreampDb,
    );

    _syncWithVirtualDsp();
    _persistActiveState();

    return true;
  }

  bool importSquiglinkText(String text) {
    final result = SquiglinkParser.parse(text);
    if (result.bands.isEmpty) return false;

    final safePreamp = result.preampDb ?? BiquadMath.calculateSafePreamp(result.bands);
    _updateBands(
      result.bands,
      selectedIdx: result.bands.first.index,
      presetName: 'Imported Squiglink EQ',
      markClean: true,
    );

    state = state.copyWith(
      safePreampDb: safePreamp,
      abMode: AbComparisonMode.bActive,
    );

    return true;
  }

  String exportSquiglinkText() {
    return SquiglinkParser.exportToSquiglink(
      state.bands,
      preampDb: state.safePreampDb,
    );
  }

  String exportWaveletText() {
    return SquiglinkParser.exportToWavelet(state.bands);
  }

  void applyPreset(String presetName) {
    // Delegate to custom preset loader if this is a user-saved preset.
    if (state.customPresetNames.contains(presetName)) {
      loadCustomPreset(presetName);
      return;
    }

    List<EqBand> presetBands;
    switch (presetName) {
      case 'Studio Audiophile Warmth':
      case 'Default 10-Band':
        presetBands = EqBand.audiophileWarmthBands;
        break;
      case 'Audiophile Bit-Perfect (Flat)':
      case 'Flat / Bit-Perfect':
      case 'Flat':
        presetBands = EqBand.flatBands;
        break;
      case 'Harman 2019 Reference':
      case 'Harman Target 2019':
        presetBands = EqBand.harmanTargetBands;
        break;
      case 'Vocal & Acoustic Intimacy':
      case 'Acoustic & Vocal Warmth':
      case 'Vocal Clarity':
        presetBands = EqBand.vocalAcousticBands;
        break;
      case 'Deep Bass & Club Drive':
      case 'Deep Bass Sub-Impact':
      case 'Bass Boost':
        presetBands = EqBand.deepBassBands;
        break;
      case 'Air & High-Res Sparkle':
      case 'Air & Detail Sparkle':
        presetBands = EqBand.airSparkleBands;
        break;
      case 'Treble Tamer':
        presetBands = EqBand.default10Bands.map((b) {
          if (b.frequency >= 6000) return b.copyWith(gainDb: -4.0);
          return b.copyWith(gainDb: 0.0);
        }).toList();
        break;
      default:
        presetBands = EqBand.audiophileWarmthBands;
    }

    _updateBands(presetBands, selectedIdx: presetBands.first.index, presetName: presetName, markClean: true);
  }

  void _updateBands(
    List<EqBand> bands, {
    int? selectedIdx,
    String? presetName,
    /// When true, marks the state as clean (a preset was just loaded/applied).
    /// When false (default), marks the state as dirty (user moved a band).
    bool markClean = false,
  }) {
    final safePreamp = state.autoPreampEnabled
        ? BiquadMath.calculateSafePreamp(bands)
        : state.safePreampDb;
    final isAuto = presetName?.startsWith('AutoEQ:') ?? false;
    state = state.copyWith(
      bands: bands,
      selectedBandIndex: selectedIdx != null ? () => selectedIdx : null,
      safePreampDb: safePreamp,
      activePresetName: presetName ?? (state.activePresetName == 'Default 10-Band' ? 'Custom' : state.activePresetName),
      isDirty: markClean ? false : true,
      isAutoEqActive: isAuto,
    );

    _syncWithVirtualDsp();
    _persistActiveState();
  }

  void _recalculateSafePreamp() {
    if (state.autoPreampEnabled) {
      final safePreamp = BiquadMath.calculateSafePreamp(state.bands);
      state = state.copyWith(safePreampDb: safePreamp);
      _syncWithVirtualDsp();
      _persistActiveState();
    }
  }
}
