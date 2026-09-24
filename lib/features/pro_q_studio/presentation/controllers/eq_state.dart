import 'package:flutter/foundation.dart';
import '../../domain/auto_eq_optimizer.dart';
import '../../domain/eq_band.dart';
import '../../domain/fr_curve_data.dart';

@immutable
class EqState {
  final List<EqBand> bands;
  final int? selectedBandIndex; // 1-indexed matching band.index, or null
  final bool isEnabled;
  final bool isRtaEnabled;
  final bool showFrCurves;
  final FrCurveData? driverFr;
  final FrCurveData? targetFr;
  final double safePreampDb;
  final bool autoPreampEnabled;
  final String activePresetName;

  // AutoEQ & Target Matching extensions
  final BandResolution bandResolution;
  final TuningMode tuningMode;
  final AbComparisonMode abMode;
  final List<FrCurveData> availableDrivers;
  final List<FrCurveData> availableTargets;
  final bool isAutoEqActive;

  const EqState({
    required this.bands,
    this.selectedBandIndex = 2, // Default selected on B2 (226Hz +4.4dB)
    this.isEnabled = true,
    this.isRtaEnabled = true,
    this.showFrCurves = true,
    this.driverFr,
    this.targetFr,
    this.safePreampDb = -4.3,
    this.autoPreampEnabled = true,
    this.activePresetName = 'Custom AutoEQ',
    this.bandResolution = BandResolution.b10,
    this.tuningMode = TuningMode.normal,
    this.abMode = AbComparisonMode.bActive,
    this.availableDrivers = const [],
    this.availableTargets = const [],
    this.isAutoEqActive = false,
  });

  EqBand? get selectedBand {
    if (selectedBandIndex == null) return null;
    return bands.where((b) => b.index == selectedBandIndex).firstOrNull;
  }

  bool get isRawBypassed => abMode == AbComparisonMode.aRaw;

  EqState copyWith({
    List<EqBand>? bands,
    ValueGetter<int?>? selectedBandIndex,
    bool? isEnabled,
    bool? isRtaEnabled,
    bool? showFrCurves,
    ValueGetter<FrCurveData?>? driverFr,
    ValueGetter<FrCurveData?>? targetFr,
    double? safePreampDb,
    bool? autoPreampEnabled,
    String? activePresetName,
    BandResolution? bandResolution,
    TuningMode? tuningMode,
    AbComparisonMode? abMode,
    List<FrCurveData>? availableDrivers,
    List<FrCurveData>? availableTargets,
    bool? isAutoEqActive,
  }) {
    return EqState(
      bands: bands ?? this.bands,
      selectedBandIndex: selectedBandIndex != null
          ? selectedBandIndex()
          : this.selectedBandIndex,
      isEnabled: isEnabled ?? this.isEnabled,
      isRtaEnabled: isRtaEnabled ?? this.isRtaEnabled,
      showFrCurves: showFrCurves ?? this.showFrCurves,
      driverFr: driverFr != null ? driverFr() : this.driverFr,
      targetFr: targetFr != null ? targetFr() : this.targetFr,
      safePreampDb: safePreampDb ?? this.safePreampDb,
      autoPreampEnabled: autoPreampEnabled ?? this.autoPreampEnabled,
      activePresetName: activePresetName ?? this.activePresetName,
      bandResolution: bandResolution ?? this.bandResolution,
      tuningMode: tuningMode ?? this.tuningMode,
      abMode: abMode ?? this.abMode,
      availableDrivers: availableDrivers ?? this.availableDrivers,
      availableTargets: availableTargets ?? this.availableTargets,
      isAutoEqActive: isAutoEqActive ?? this.isAutoEqActive,
    );
  }
}
