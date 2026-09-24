import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../audio_engine/soloud_controller.dart';
import '../../domain/biquad_math.dart';
import '../../domain/eq_band.dart';
import '../../domain/fr_curve_data.dart';
import 'eq_state.dart';

final eqControllerProvider =
    StateNotifierProvider<EqController, EqState>((ref) {
  return EqController();
});

class EqController extends StateNotifier<EqState> {
  EqController()
      : super(EqState(
          bands: EqBand.default10Bands,
          selectedBandIndex: 2, // Selected on B2 by default
        )) {
    _loadSampleCurves();
    _recalculateSafePreamp();
  }

  Future<void> _loadSampleCurves() async {
    try {
      final driverText = await rootBundle
          .loadString('assets/samples/drivers/KZ_CASTOR_BLACK_DUDU_R.txt');
      final targetText =
          await rootBundle.loadString('assets/samples/targets/HBB_Target.txt');

      final driver = FrCurveData.parseRewV5(driverText, name: 'KZ Castor Black');
      final target = FrCurveData.parseSquiglinkCsv(targetText, name: 'HBB Target');

      state = state.copyWith(
        driverFr: () => driver,
        targetFr: () => target,
      );
    } catch (e) {
      // Abaikan jika running di test environment tanpa rootBundle
    }
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
    // Urutkan band berdasarkan frekuensi
    updated.sort((a, b) => a.frequency.compareTo(b.frequency));

    // Re-index agar urut 1..N
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
    // Re-index
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
    _updateBands(EqBand.default10Bands,
        selectedIdx: 2, presetName: 'Default 10-Band');
  }

  void togglePower() {
    final nextState = !state.isEnabled;
    state = state.copyWith(isEnabled: nextState);
    if (!nextState) {
      SoLoudController.instance.setPreamp(0.0);
    } else {
      SoLoudController.instance.setPreamp(state.safePreampDb);
    }
  }

  void toggleRta() {
    state = state.copyWith(isRtaEnabled: !state.isRtaEnabled);
  }

  void toggleFrCurves() {
    state = state.copyWith(showFrCurves: !state.showFrCurves);
  }

  void setDriverFr(FrCurveData driver) {
    state = state.copyWith(driverFr: () => driver);
  }

  void setTargetFr(FrCurveData target) {
    state = state.copyWith(targetFr: () => target);
  }

  void applyPreset(String presetName) {
    List<EqBand> presetBands;
    switch (presetName) {
      case 'Flat':
        presetBands = EqBand.default10Bands.map((b) => b.copyWith(gainDb: 0.0)).toList();
        break;
      case 'Bass Boost':
        presetBands = EqBand.default10Bands.map((b) {
          if (b.frequency <= 100) return b.copyWith(gainDb: 5.5);
          if (b.frequency <= 250) return b.copyWith(gainDb: 3.0);
          return b.copyWith(gainDb: 0.0);
        }).toList();
        break;
      case 'V-Shape':
        presetBands = EqBand.default10Bands.map((b) {
          if (b.frequency <= 120) return b.copyWith(gainDb: 4.5);
          if (b.frequency <= 300) return b.copyWith(gainDb: 2.0);
          if (b.frequency >= 800 && b.frequency <= 3000) return b.copyWith(gainDb: -2.5);
          if (b.frequency >= 6000) return b.copyWith(gainDb: 3.5);
          return b.copyWith(gainDb: 0.0);
        }).toList();
        break;
      case 'Vocal Clarity':
        presetBands = EqBand.default10Bands.map((b) {
          if (b.frequency >= 1000 && b.frequency <= 4000) return b.copyWith(gainDb: 3.0);
          if (b.frequency <= 100) return b.copyWith(gainDb: -1.5);
          return b.copyWith(gainDb: 0.0);
        }).toList();
        break;
      case 'Treble Tamer':
        presetBands = EqBand.default10Bands.map((b) {
          if (b.frequency >= 6000) return b.copyWith(gainDb: -4.0);
          return b.copyWith(gainDb: 0.0);
        }).toList();
        break;
      default:
        presetBands = EqBand.default10Bands;
    }

    _updateBands(presetBands, presetName: presetName);
  }

  void _updateBands(List<EqBand> bands, {int? selectedIdx, String? presetName}) {
    final safePreamp = BiquadMath.calculateSafePreamp(bands);
    state = state.copyWith(
      bands: bands,
      selectedBandIndex: selectedIdx != null ? () => selectedIdx : null,
      safePreampDb: safePreamp,
      activePresetName: presetName ?? (state.activePresetName == 'Default 10-Band' ? 'Custom' : state.activePresetName),
    );

    if (state.isEnabled && state.autoPreampEnabled) {
      SoLoudController.instance.setPreamp(safePreamp);
    }
  }

  void _recalculateSafePreamp() {
    final safePreamp = BiquadMath.calculateSafePreamp(state.bands);
    state = state.copyWith(safePreampDb: safePreamp);
    if (state.isEnabled && state.autoPreampEnabled) {
      SoLoudController.instance.setPreamp(safePreamp);
    }
  }
}
