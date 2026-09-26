import 'dart:math' as math;
import '../../features/player/domain/track.dart';
import '../../features/settings/domain/player_playback_settings.dart';

/// Engine Kalkulasi ReplayGain Normalization & Skip Silence
class ReplayGainService {
  ReplayGainService._();
  static final ReplayGainService instance = ReplayGainService._();

  /// Menghitung gain ReplayGain efektif dalam dB
  double calculateEffectiveGainDb({
    required Track? track,
    required ReplayGainMode mode,
    double preampDb = 0.0,
    bool preventClipping = true,
  }) {
    if (mode == ReplayGainMode.off || track == null) {
      return preampDb;
    }

    double? baseGainDb;
    double? peakLinear;

    if (mode == ReplayGainMode.album) {
      baseGainDb = track.replayGainAlbumDb ?? track.replayGainTrackDb;
      peakLinear = track.replayGainAlbumPeak ?? track.replayGainTrackPeak;
    } else {
      baseGainDb = track.replayGainTrackDb ?? track.replayGainAlbumDb;
      peakLinear = track.replayGainTrackPeak ?? track.replayGainAlbumPeak;
    }

    final nominalGainDb = (baseGainDb ?? 0.0) + preampDb;

    if (!preventClipping || peakLinear == null || peakLinear <= 0.0) {
      return nominalGainDb;
    }

    // Hitung peak dalam dBFS: 20 * log10(peak)
    final peakDb = 20.0 * (math.log(peakLinear) / math.ln10);

    // Jika gain + peak melampaui 0.0 dBFS (clipping), redam gain
    if (nominalGainDb + peakDb > 0.0) {
      return -peakDb;
    }

    return nominalGainDb;
  }

  /// Konversi dB ke faktor pengali linier
  double dbToLinear(double db) {
    return math.pow(10.0, db / 20.0).toDouble();
  }

  /// Konversi amplitudo linier ke dBFS
  double linearToDb(double linear) {
    if (linear <= 0.000001) return -120.0;
    return 20.0 * (math.log(linear) / math.ln10);
  }

  /// Cek apakah suatu amplitudo dianggap hening berdasarkan threshold dB
  bool isSilent(double amplitude, {double thresholdDb = -55.0}) {
    if (amplitude <= 0.0) return true;
    final ampDb = linearToDb(amplitude);
    return ampDb < thresholdDb;
  }

  /// Mendeteksi durasi hening di awal sampel audio (dalam millisecond)
  int detectLeadingSilenceDurationMs(
    List<double> samples, {
    int sampleRate = 44100,
    double thresholdDb = -55.0,
  }) {
    if (samples.isEmpty || sampleRate <= 0) return 0;

    final thresholdLinear = dbToLinear(thresholdDb);
    int silentSamples = 0;

    for (int i = 0; i < samples.length; i++) {
      if (samples[i].abs() < thresholdLinear) {
        silentSamples++;
      } else {
        break;
      }
    }

    return ((silentSamples / sampleRate) * 1000).toInt();
  }
}
