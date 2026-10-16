import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Helper to generate consistent, genre-appropriate or hash-mapped random LucideIcons
class GenreIconHelper {
  const GenreIconHelper._();

  static const List<IconData> _iconPalette = [
    LucideIcons.flame,
    LucideIcons.headphones,
    LucideIcons.disc,
    LucideIcons.mic,
    LucideIcons.sparkles,
    LucideIcons.audioLines,
    LucideIcons.music,
    LucideIcons.music2,
    LucideIcons.sliders,
    LucideIcons.radio,
    LucideIcons.listMusic,
    LucideIcons.zap,
  ];

  static IconData getGenreIcon(String genreName) {
    final lower = genreName.trim().toLowerCase();

    // 1. Rock & Metal
    if (lower.contains('rock') ||
        lower.contains('metal') ||
        lower.contains('punk') ||
        lower.contains('grunge') ||
        lower.contains('heavy') ||
        lower.contains('guitar')) {
      return LucideIcons.flame;
    }

    // 2. Jazz, Blues & Soul
    if (lower.contains('jazz') ||
        lower.contains('blues') ||
        lower.contains('soul') ||
        lower.contains('funk') ||
        lower.contains('groove') ||
        lower.contains('brass')) {
      return LucideIcons.music2;
    }

    // 3. Classical & Acoustic
    if (lower.contains('classic') ||
        lower.contains('symphon') ||
        lower.contains('orchestr') ||
        lower.contains('piano') ||
        lower.contains('violin') ||
        lower.contains('acoustic') ||
        lower.contains('instrumental') ||
        lower.contains('chamber')) {
      return LucideIcons.music;
    }

    // 4. Electronic & Dance
    if (lower.contains('electro') ||
        lower.contains('dance') ||
        lower.contains('edm') ||
        lower.contains('techno') ||
        lower.contains('house') ||
        lower.contains('synth') ||
        lower.contains('trance') ||
        lower.contains('club') ||
        lower.contains('dubstep')) {
      return LucideIcons.audioLines;
    }

    // 5. Hip Hop & Rap
    if (lower.contains('hip hop') ||
        lower.contains('hip-hop') ||
        lower.contains('rap') ||
        lower.contains('trap') ||
        lower.contains('r&b') ||
        lower.contains('urban')) {
      return LucideIcons.mic;
    }

    // 6. Pop & Indie
    if (lower.contains('pop') ||
        lower.contains('indie') ||
        lower.contains('folk') ||
        lower.contains('vocal') ||
        lower.contains('country')) {
      return LucideIcons.headphones;
    }

    // 7. Ambient & Soundtracks
    if (lower.contains('ambient') ||
        lower.contains('chill') ||
        lower.contains('soundtrack') ||
        lower.contains('score') ||
        lower.contains('ost') ||
        lower.contains('meditation')) {
      return LucideIcons.radio;
    }

    // 8. Studio Master & Audiophile
    if (lower.contains('hires') ||
        lower.contains('hi-res') ||
        lower.contains('audiophile') ||
        lower.contains('master') ||
        lower.contains('lossless') ||
        lower.contains('dsd') ||
        lower.contains('flac')) {
      return LucideIcons.sparkles;
    }

    // 9. Deterministic hash mapping for custom / other genres
    final index = (lower.hashCode.abs()) % _iconPalette.length;
    return _iconPalette[index];
  }
}
