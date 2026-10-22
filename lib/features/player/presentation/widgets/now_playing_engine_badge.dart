import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../domain/track.dart';
import 'audio_file_inspector_sheet.dart';

/// Studio Engine & Audio Pedigree Badge
/// Displays BayHifi brand logo and SoLoud C++ engine attribution below album artwork.
class NowPlayingEngineBadge extends StatelessWidget {
  final Track? track;
  final Color primaryColor;

  const NowPlayingEngineBadge({
    super.key,
    required this.track,
    required this.primaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final containerBg = isDark
        ? const Color(0xFF16181F)
        : theme.colorScheme.surfaceContainerHigh;
    final outlineColor = isDark
        ? const Color(0xFF2E3242)
        : theme.colorScheme.outlineVariant.withValues(alpha: 0.5);

    return Tooltip(
      message:
          'BayHiFi Audio Engine • Powered by SoLoud C++ • Tap for Audio File Inspector',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: track != null
              ? () {
                  AppHaptics.lightImpact();
                  AudioFileInspectorSheet.show(context, track!);
                }
              : null,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: 25,
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
            decoration: BoxDecoration(
              color: containerBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: outlineColor,
                width: 0.8,
              ),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // App Logo with resilient fallback
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color:
                          theme.colorScheme.onSurface.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(3.5),
                    ),
                    padding: const EdgeInsets.all(1.5),
                    child: Image.asset(
                      'assets/images/baydev_logo.png',
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => Icon(
                        LucideIcons.audioWaveform,
                        size: 9,
                        color: primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),

                  // App Brand Name
                  Text(
                    'BayHIFI',
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.1,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),

                  // Subtle Studio Separator
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5),
                    child: Text(
                      '│',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w300,
                        color: theme.colorScheme.onSurfaceVariant
                            .withValues(alpha: 0.4),
                      ),
                    ),
                  ),

                  // SoLoud Engine Pedigree
                  Text(
                    'POWERED BY SOLOUD ENGINE',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: primaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
