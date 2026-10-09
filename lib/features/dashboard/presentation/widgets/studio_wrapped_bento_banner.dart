import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../../core/widgets/studio_artwork_widget.dart';
import '../../../analytics/data/playback_analytics_service.dart';
import '../../../analytics/presentation/story/studio_wrapped_story_screen.dart';
import '../../../analytics/presentation/templates/studio_wrapped_export_hub.dart';

class StudioWrappedBentoBanner extends ConsumerWidget {
  const StudioWrappedBentoBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isSolid = ref.isSolidStyle;
    final wrappedData = ref.watch(studioWrappedDataProvider);
    final persona = wrappedData.persona;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surfaceContainer(context, isSolid: isSolid),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.4),
          width: 1.2,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background ambient gradient flare
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.12),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Tag & Sparkle
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HugeIcon(
                            icon: HugeIcons.strokeRoundedSparkles,
                            size: 11,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'STUDIO WRAPPED 2026',
                            style: TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.primary,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${wrappedData.totalListeningMinutes} MINS',
                      style: TextStyle(
                        fontFeatures: AppTypography.audioFigures,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Main Persona / Artwork Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        StudioArtworkWidget(
                          url: wrappedData.topTrack?.albumArtUri,
                          width: 44,
                          height: 44,
                          borderRadius: BorderRadius.circular(10),
                          fallbackIcon: HugeIcons.strokeRoundedDisc,
                          fallbackIconSize: 22,
                          backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                        ),
                        Positioned(
                          right: -4,
                          bottom: -4,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                              border: Border.all(color: theme.colorScheme.surface, width: 1.5),
                            ),
                            child: Center(
                              child: HugeIcon(
                                icon: persona.icon,
                                size: 11,
                                color: theme.colorScheme.onPrimary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            persona.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: theme.colorScheme.onSurface,
                              letterSpacing: -0.2,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            wrappedData.topTrack != null
                                ? 'Top Track: ${wrappedData.topTrack!.title} • ${wrappedData.topTrack!.artist}'
                                : 'Your sound archetype, purity metrics & top tracks are ready.',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w500,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Action Buttons Row
                Row(
                  children: [
                    // Play Interactive Story Button
                    Expanded(
                      flex: 6,
                      child: SizedBox(
                        height: 38,
                        child: M3EButton.filled(
                          onPressed: () {
                            AppHaptics.mediumImpact();
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const StudioWrappedStoryScreen()),
                            );
                          },
                          icon: HugeIcon(
                            icon: HugeIcons.strokeRoundedPlay,
                            size: 14,
                            color: theme.colorScheme.onPrimary,
                          ),
                          label: Text(
                            'PLAY RECAP STORY',
                            style: TextStyle(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              color: theme.colorScheme.onPrimary,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Export Hub & Templates Button
                    Expanded(
                      flex: 5,
                      child: SizedBox(
                        height: 38,
                        child: M3EButton.outlined(
                          onPressed: () {
                            AppHaptics.lightImpact();
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const StudioWrappedExportHub()),
                            );
                          },
                          icon: HugeIcon(icon: HugeIcons.strokeRoundedInvoice01, size: 13, color: theme.colorScheme.primary),
                          label: const Text(
                            'TEMPLATES',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
