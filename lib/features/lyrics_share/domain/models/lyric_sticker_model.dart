import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Supported studio stamp stickers for decorative audiophile overlays
enum LyricStickerType {
  hiResLossless(
    'HI-RES LOSSLESS',
    'Certified 24-bit studio resolution',
    Color(0xFFFFB800), // Gold
    LucideIcons.shieldCheck,
  ),
  bitPerfect(
    'BIT-PERFECT PURIST',
    'Direct unadulterated audio stream',
    Color(0xFF10B981), // Emerald
    LucideIcons.cpu,
  ),
  tubeWarmth(
    'WARM TUBE HARMONICS',
    'Analog triode harmonic saturation',
    Color(0xFFF59E0B), // Warm Amber
    LucideIcons.sun,
  ),
  lateNight(
    'LATE NIGHT VIBES',
    'Deep midnight listening session',
    Color(0xFF8B5CF6), // Violet
    LucideIcons.moon,
  ),
  certifiedAudiophile(
    'CERTIFIED AUDIOPHILE',
    'Gold standard critical listening',
    Color(0xFF06B6D4), // Cyan
    LucideIcons.award,
  ),
  studioMaster(
    'STUDIO MASTER ANTHEM',
    'Heaviest rotation master track',
    Color(0xFFEC4899), // Rose
    LucideIcons.star,
  );

  final String label;
  final String description;
  final Color badgeColor;
  final IconData icon;

  const LyricStickerType(
    this.label,
    this.description,
    this.badgeColor,
    this.icon,
  );
}
