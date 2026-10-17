import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/simple_as_f_theme.dart';
import '../../../../core/database/local_persistence_service.dart';
import '../../../library/domain/instant_mix_engine.dart';
import '../../../library/presentation/controllers/library_controller.dart';
import '../../../library/presentation/widgets/instant_mix_config_sheet.dart';
import '../../../player/domain/track.dart';
import '../../../player/presentation/controllers/player_controller.dart';

/// Minimalist Studio Instant Mix Suggestion Banner
/// Adheres strictly to Simple-As-F Minimalist Architecture (Neutral Matte Obsidian #16181F,
/// crisp border #262936, two-tone typography, and pure solid controls).
class StudioInstantMixBanner extends ConsumerWidget {
  const StudioInstantMixBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryState = ref.watch(unifiedLibraryProvider);
    final allTracks = libraryState.tracks;

    if (allTracks.isEmpty) {
      return const SizedBox.shrink();
    }

    // Determine seed track: either from recent playback history or favorite track or first library track
    final history = LocalPersistenceService.instance.getPlaybackHistory();
    final trackMap = {for (final t in allTracks) t.id: t};

    Track? seedTrack;
    for (final h in history) {
      final t = trackMap[h['id']];
      if (t != null) {
        seedTrack = t;
        break;
      }
    }

    if (seedTrack == null && libraryState.favoriteTrackIds.isNotEmpty) {
      final favId = libraryState.favoriteTrackIds.first;
      seedTrack = trackMap[favId];
    }
    seedTrack ??= allTracks.first;

    final seed = seedTrack;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF16181F) : theme.colorScheme.surfaceContainer;
    final cardBorder = isDark ? const Color(0xFF262936) : theme.colorScheme.outlineVariant;
    final chipBg = isDark ? const Color(0xFF1E212B) : theme.colorScheme.surfaceContainerHighest;
    final chipBorder = isDark ? const Color(0xFF2E3242) : theme.colorScheme.outlineVariant;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: cardBorder,
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sub-header row with tag & config icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: chipBg,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: chipBorder, width: 0.8),
                      ),
                      child: const Icon(
                        LucideIcons.sparkles,
                        size: 12,
                        color: Color(0xFF34D399),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'STUDIO SMART MIX',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                          color: isDark ? SimpleAsFTheme.sageSlate : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () {
                  AppHaptics.selectionClick();
                  InstantMixConfigSheet.show(context, seedTrack: seed);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: chipBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: chipBorder, width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.slidersHorizontal,
                        size: 11,
                        color: isDark ? SimpleAsFTheme.sageSlate : theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Tune Mix',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? SimpleAsFTheme.sageSlate : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Two-Tone Title
          RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
              children: [
                TextSpan(
                  text: 'DISCOVERY ',
                  style: TextStyle(color: isDark ? Colors.white : theme.colorScheme.onSurface),
                ),
                const TextSpan(
                  text: 'SMART MIX',
                  style: TextStyle(color: Color(0xFF34D399)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 3),

          // Seed description
          Text(
            'Curated from "${seed.title}" by ${seed.artist} • ${seed.genre != null && seed.genre!.isNotEmpty ? seed.genre : "Harmonic Flow"}',
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? SimpleAsFTheme.sageSlate : theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 14),

          // Action row
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () {
                    AppHaptics.mediumImpact();
                    const engine = InstantMixEngine();
                    final mixedTracks = engine.generateInstantMix(
                      seedTrack: seed,
                      pool: allTracks,
                      criteria: InstantMixCriteria.smartRandom,
                      count: 25,
                      favoriteIds: libraryState.favoriteTrackIds.toSet(),
                    );
                    ref.read(playerControllerProvider.notifier).startInstantMix(seed, mixedTracks);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Starting Smart Mix based on "${seed.title}"'),
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: isDark ? chipBg : theme.colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isDark ? const Color(0xFF10B981) : theme.colorScheme.primary.withValues(alpha: 0.4),
                        width: 1.1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          LucideIcons.play,
                          size: 14,
                          color: isDark ? const Color(0xFF34D399) : theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'START SMART MIX',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.6,
                            color: isDark ? Colors.white : theme.colorScheme.onPrimaryContainer,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
