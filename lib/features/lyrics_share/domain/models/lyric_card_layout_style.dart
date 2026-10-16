import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// 6 Curated Studio Layout Templates for Baydev HiFi Lyric Cards
enum LyricCardLayoutStyle {
  classicMinimal(
    'Classic Studio',
    'Clean floating lyrics with dynamic album backdrop and telemetry badge',
    LucideIcons.layers,
  ),
  polaroidFrame(
    'Polaroid Frame',
    'Framed vintage album art with quote, date stamp & caption below',
    LucideIcons.image,
  ),
  cassetteJCard(
    'Cassette J-Card',
    'Analog magnetic tape insert with Type II stamp & credits',
    LucideIcons.disc,
  ),
  waveformQuote(
    'Waveform Timeline',
    'Studio audio amplitude bars with start/end duration time pill',
    LucideIcons.activity,
  ),
  cyberHUD(
    'CyberSpec HUD',
    'Tokyo studio tech wireframe with telemetry matrix & brackets',
    LucideIcons.cpu,
  ),
  abstractAura(
    'Abstract Aura',
    'Harmonic acoustic color mesh with high-contrast text backing',
    LucideIcons.sun,
  );

  final String label;
  final String description;
  final IconData icon;

  String get subtitle => description;

  const LyricCardLayoutStyle(
    this.label,
    this.description,
    this.icon,
  );
}
