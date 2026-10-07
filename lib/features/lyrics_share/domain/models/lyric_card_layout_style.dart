import 'package:hugeicons/hugeicons.dart';

/// 6 Curated Studio Layout Templates for Baydev HiFi Lyric Cards
enum LyricCardLayoutStyle {
  classicMinimal(
    'Classic Studio',
    'Clean floating lyrics with dynamic album backdrop and telemetry badge',
    HugeIcons.strokeRoundedLayers01,
  ),
  polaroidFrame(
    'Polaroid Frame',
    'Framed vintage album art with quote, date stamp & caption below',
    HugeIcons.strokeRoundedImage01,
  ),
  cassetteJCard(
    'Cassette J-Card',
    'Analog magnetic tape insert with Type II stamp & credits',
    HugeIcons.strokeRoundedAlbum01,
  ),
  waveformQuote(
    'Waveform Timeline',
    'Studio audio amplitude bars with start/end duration time pill',
    HugeIcons.strokeRoundedAudioWave01,
  ),
  cyberHUD(
    'CyberSpec HUD',
    'Tokyo studio tech wireframe with telemetry matrix & brackets',
    HugeIcons.strokeRoundedCpu,
  ),
  abstractAura(
    'Abstract Aura',
    'Harmonic acoustic color mesh with high-contrast text backing',
    HugeIcons.strokeRoundedSun03,
  );

  final String label;
  final String description;
  final dynamic icon;

  String get subtitle => description;

  const LyricCardLayoutStyle(
    this.label,
    this.description,
    this.icon,
  );
}
