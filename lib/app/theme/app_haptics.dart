import 'package:material_3_expressive/material_3_expressive.dart';

/// Centralized Material 3 Expressive haptic feedback helper for Baydev HiFi.
abstract final class AppHaptics {
  /// Subtle light impact feedback for standard navigation and minor button clicks.
  static void lightImpact() => M3EHaptics.trigger(M3EHapticFeedback.light);

  /// Medium impact feedback for primary playback toggles and actions.
  static void mediumImpact() => M3EHaptics.trigger(M3EHapticFeedback.medium);

  /// Heavy tactile impact feedback for significant structural mode switches.
  static void heavyImpact() => M3EHaptics.trigger(M3EHapticFeedback.heavy);

  /// Selection feedback for discrete sliders, pickers, and tab transitions.
  static void selectionClick() => M3EHaptics.selection();
}
