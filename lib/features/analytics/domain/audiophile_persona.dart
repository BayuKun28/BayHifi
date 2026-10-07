import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

/// Enum representing the 6 distinct Audiophile Persona Archetypes
enum AudiophilePersonaType {
  tubeConnoisseur,
  analyticalPurist,
  subBassExplorer,
  midnightListener,
  dacArtisan,
  studioVirtuoso,
}

// Extension for type aliases in tests
extension AudiophilePersonaTypeExt on AudiophilePersonaType {
  static const analogTubeConnoisseur = AudiophilePersonaType.tubeConnoisseur;
  static const bitPerfectPurist = AudiophilePersonaType.analyticalPurist;
  static const hardwareDacArtisan = AudiophilePersonaType.dacArtisan;
}

@immutable
class AudiophilePersona {
  final AudiophilePersonaType type;
  final String title;
  final String subtitle;
  final String description;
  final String signatureGear;
  final String quote;
  final Color primaryColor;
  final Color secondaryColor;
  final dynamic icon;

  const AudiophilePersona({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.signatureGear,
    required this.quote,
    required this.primaryColor,
    required this.secondaryColor,
    required this.icon,
  });

  static const tubeConnoisseur = AudiophilePersona(
    type: AudiophilePersonaType.tubeConnoisseur,
    title: 'The Analog Tube Connoisseur',
    subtitle: 'Warm Even Harmonics & Acoustic Intimacy',
    description: 'You crave lush analog saturation, organic timbre, and rich midrange depth over cold clinical precision.',
    signatureGear: 'Triode Harmonic Exciter + Studio Warmth Target',
    quote: 'Sound is not meant to be measured; it is meant to be felt in every warm harmonic ripple.',
    primaryColor: Color(0xFFF59E0B), // Warm Amber
    secondaryColor: Color(0xFFD97706),
    icon: HugeIcons.strokeRoundedEnergy,
  );

  static const analyticalPurist = AudiophilePersona(
    type: AudiophilePersonaType.analyticalPurist,
    title: 'The Bit-Perfect Purist',
    subtitle: 'High-Res Analytical Clarity & Zero Coloration',
    description: 'You demand bit-perfect bitstream fidelity, flat frequency response, and uncompromising lossless master resolution.',
    signatureGear: 'FLAC 24-bit/192kHz + Flat Reference Curve',
    quote: 'Bit-perfect accuracy is the only bridge between the master recording console and the ears.',
    primaryColor: Color(0xFF38BDF8), // Obsidian Sky
    secondaryColor: Color(0xFF0284C7),
    icon: HugeIcons.strokeRoundedSlidersVertical,
  );

  static const subBassExplorer = AudiophilePersona(
    type: AudiophilePersonaType.subBassExplorer,
    title: 'The Sub-Bass Holographic Explorer',
    subtitle: 'Deep Visceral Extension & Immersive Stereo Field',
    description: 'You immerse yourself in expansive soundstages, tactile sub-bass rumbles, and holographic spatial width.',
    signatureGear: 'Sub-Bass Boost + Stereo Width Matrix (120%)',
    quote: 'Low frequencies define the physical foundation of music while wide soundstages set it free.',
    primaryColor: Color(0xFFA855F7), // Holographic Violet
    secondaryColor: Color(0xFF7C3AED),
    icon: HugeIcons.strokeRoundedAudioWaveform,
  );

  static const midnightListener = AudiophilePersona(
    type: AudiophilePersonaType.midnightListener,
    title: 'The Midnight Intimate Dreamer',
    subtitle: 'Late-Night Vocal Presence & Melancholic Depth',
    description: 'Your peak listening hours belong to the quiet night, immersed in delicate vocals and acoustic reflections.',
    signatureGear: 'Vocal Clarity Curve + Late-Night Dynamics',
    quote: 'Music sounds truest when the rest of the world has fallen completely silent.',
    primaryColor: Color(0xFF06B6D4), // Muted Cyan
    secondaryColor: Color(0xFF0891B2),
    icon: HugeIcons.strokeRoundedMoon,
  );

  static const dacArtisan = AudiophilePersona(
    type: AudiophilePersonaType.dacArtisan,
    title: 'The Hardware DAC Artisan',
    subtitle: 'Dedicated External Signal Path & Hardware PEQ',
    description: 'You rely on dedicated USB-C hardware DACs, custom flash profiles, and pristine low-impedance driving power.',
    signatureGear: 'External Hardware DAC + Custom PEQ Flash',
    quote: 'A dedicated signal path makes the subtle textures of high-resolution audio come alive.',
    primaryColor: Color(0xFF10B981), // Precision Mint
    secondaryColor: Color(0xFF059669),
    icon: HugeIcons.strokeRoundedUsb,
  );

  static const studioVirtuoso = AudiophilePersona(
    type: AudiophilePersonaType.studioVirtuoso,
    title: 'The Studio Reference Virtuoso',
    subtitle: 'Multi-Genre Target Matching & Precision AutoEQ',
    description: 'You adapt your sound flawlessly across genres using precision AutoEQ profiles and target curve compensation.',
    signatureGear: 'AutoEQ Harman Target 2019 + 10-Band Biquads',
    quote: 'Perfection is achieved when every frequency aligns seamlessly with the target curve.',
    primaryColor: Color(0xFFEC4899), // Rose Studio
    secondaryColor: Color(0xFFDB2777),
    icon: HugeIcons.strokeRoundedHeadphones,
  );

  List<String> get soundSignatureTags {
    switch (type) {
      case AudiophilePersonaType.tubeConnoisseur:
        return const ['2nd Harmonic Warmth', 'Analog Triode', 'Lush Timbre'];
      case AudiophilePersonaType.analyticalPurist:
        return const ['Bit-Perfect Master', 'Zero Coloration', '192kHz/24-bit'];
      case AudiophilePersonaType.subBassExplorer:
        return const ['Sub-Bass Rumble', 'Holographic Stage', 'Immersive Width'];
      case AudiophilePersonaType.midnightListener:
        return const ['Intimate Vocals', 'Late-Night Dynamics', 'Delicate Air'];
      case AudiophilePersonaType.dacArtisan:
        return const ['Direct USB Bitstream', 'Dedicated DAC', 'Hardware PEQ'];
      case AudiophilePersonaType.studioVirtuoso:
        return const ['AutoEQ Harman 2019', '10-Band Precision', 'Studio Mastering'];
    }
  }

  static AudiophilePersona fromType(AudiophilePersonaType type) {
    switch (type) {
      case AudiophilePersonaType.tubeConnoisseur:
        return tubeConnoisseur;
      case AudiophilePersonaType.analyticalPurist:
        return analyticalPurist;
      case AudiophilePersonaType.subBassExplorer:
        return subBassExplorer;
      case AudiophilePersonaType.midnightListener:
        return midnightListener;
      case AudiophilePersonaType.dacArtisan:
        return dacArtisan;
      case AudiophilePersonaType.studioVirtuoso:
        return studioVirtuoso;
    }
  }

  static AudiophilePersona determine({
    required double flacRatio,
    required double tubeWarmthHours,
    required double totalDacHours,
    required int highestSampleRate,
    required String topAutoEqTarget,
    required int peqBandsEngaged,
    required double bassBoostHours,
    required double intimateHours,
  }) {
    if (flacRatio >= 0.85 && highestSampleRate >= 176400) {
      return analyticalPurist;
    }
    if (tubeWarmthHours > 15) {
      return tubeConnoisseur;
    }
    if (bassBoostHours > 10) {
      return subBassExplorer;
    }
    if (totalDacHours > 20) {
      return dacArtisan;
    }
    if (flacRatio >= 0.85) {
      return analyticalPurist;
    }
    if (intimateHours > 10) {
      return midnightListener;
    }
    return studioVirtuoso;
  }
}
