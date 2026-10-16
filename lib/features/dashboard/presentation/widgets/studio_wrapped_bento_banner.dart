import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/widgets/studio_artwork_widget.dart';
import '../../../analytics/data/playback_analytics_service.dart';
import '../../../analytics/presentation/story/studio_wrapped_story_screen.dart';
import '../../../analytics/presentation/templates/studio_wrapped_export_hub.dart';

class StudioWrappedBentoBanner extends ConsumerWidget {
  const StudioWrappedBentoBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wrappedData = ref.watch(studioWrappedDataProvider);
    final persona = wrappedData.persona;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF16181F),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFF262936),
          width: 1.0,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Tag & Sparkle
            Row(
              children: [
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E212B),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFF262936), width: 1),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.sparkles,
                          size: 11,
                          color: Color(0xFF34D399),
                        ),
                        SizedBox(width: 5),
                        Flexible(
                          child: Text(
                            'STUDIO WRAPPED 2026',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFFE6EAE7),
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${wrappedData.totalListeningMinutes} MINS',
                  style: const TextStyle(
                    fontFeatures: AppTypography.audioFigures,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF8A9A90),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

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
                      fallbackIcon: LucideIcons.disc,
                      fallbackIconSize: 22,
                      backgroundColor: const Color(0xFF1E212B),
                    ),
                    Positioned(
                      right: -3,
                      bottom: -3,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color: const Color(0xFF252834),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFF16181F), width: 1.5),
                        ),
                        child: Center(
                          child: Icon(
                            persona.icon,
                            size: 10,
                            color: Colors.white,
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
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        wrappedData.topTrack != null
                            ? 'Top Track: ${wrappedData.topTrack!.title} • ${wrappedData.topTrack!.artist}'
                            : 'Your sound archetype, purity metrics & top tracks are ready.',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF8A9A90),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Action Buttons Row
            Row(
              children: [
                // Play Interactive Story Button
                Expanded(
                  flex: 6,
                  child: SizedBox(
                    height: 38,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        AppHaptics.mediumImpact();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const StudioWrappedStoryScreen()),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF252834),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Color(0xFF2E3242), width: 1),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      icon: const Icon(
                        LucideIcons.play,
                        size: 13,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'PLAY RECAP STORY',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: Colors.white,
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
                    child: OutlinedButton.icon(
                      onPressed: () {
                        AppHaptics.lightImpact();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const StudioWrappedExportHub()),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: const Color(0xFF12141A),
                        foregroundColor: const Color(0xFFA1B2A7),
                        side: const BorderSide(color: Color(0xFF262936), width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                      ),
                      icon: const Icon(
                        LucideIcons.layoutGrid,
                        size: 13,
                        color: Color(0xFFA1B2A7),
                      ),
                      label: const Text(
                        'TEMPLATES',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                          color: Color(0xFFA1B2A7),
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
    );
  }
}
