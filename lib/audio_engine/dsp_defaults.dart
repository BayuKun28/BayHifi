/// Calibrated studio fallback values for SoLoud DSP filter modules.
class DspDefaults {
  static const List<double> fallbackEqFreqs = [
    30.0,
    60.0,
    120.0,
    250.0,
    500.0,
    1000.0,
    2000.0,
    4000.0,
    8000.0,
    16000.0,
  ];

  static const double fallbackEqGain = 0.0;
  static const String fallbackEqFilterType = 'bell';
  static const double fallbackEqQFactor = 1.0;
  static const double fallbackPeqBellQ = 1.411;
  static const double fallbackPreampGain = 0.0;

  static const bool fallbackEffectEnabled = false;

  static int get eqBandCount => eqFreqs.length;
  static bool get effectEnabled => fallbackEffectEnabled;
  static List<double> get eqFreqs => List<double>.from(fallbackEqFreqs);
  static List<double> get eqGains => List.filled(fallbackEqFreqs.length, fallbackEqGain);
  static List<String> get eqFilterTypes => List.filled(fallbackEqFreqs.length, fallbackEqFilterType);
  static List<double> get eqQFactors => List.filled(fallbackEqFreqs.length, fallbackEqQFactor);
  static double get peqBellQ => fallbackPeqBellQ;
  static double get preampGain => fallbackPreampGain;

  static double get bassBoostValue => 1.0;

  static double get compAttack => 0.01; // 10ms in seconds
  static double get compRelease => 0.2; // 200ms in seconds
  static double get compThreshold => -20.0;
  static double get compRatio => 4.0;
  static double get compKnee => 6.0;

  static double get limiterThreshold => -1.0;
  static double get limiterAttack => 0.005; // 5ms in seconds
  static double get limiterRelease => 0.1; // 100ms in seconds
  static double get limiterOutputCeiling => -1.3; // Hard brickwall safety ceiling (-1.3 dBFS)

  static double get reverbRoomSize => 0.6;
  static double get reverbDamp => 0.5;
  static double get reverbWet => 0.3;

  static double get pitchValue => 1.0;

  static double get crossfeedCutoff => 700.0;
  static double get crossfeedFeed => -6.0;
  static double get crossfeedDelayMs => 0.35;
  static double get crossfeedWet => 1.0;

  static double get tubeDrive => 1.5;
  static double get tubeWarmth => 0.4;
  static double get tubeMix => 0.5;

  static double get stereoWidthFactor => 1.25;
  static double get stereoMidGain => 1.0;
  static double get stereoWidthWet => 1.0;

  static double get autoEqDefaultBellQ => fallbackPeqBellQ;
  static double get autoEqShelfQ => 0.71;
  static double get autoEqMaxNotchQ => 3.5;
  static double get autoEqMinNarrowQ => 1.2;
  static double get autoEqBroadQ => 0.85;
}
