import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../app/theme/app_haptics.dart';
import '../../../app/theme/simple_as_f_theme.dart';
import '../../../core/widgets/meta_tracking_label.dart';
import '../../../core/widgets/simple_as_f_scaffold.dart';
import '../../../core/widgets/two_tone_header.dart';
import '../../cloud_sync/presentation/widgets/dashboard_profile_button.dart';
import '../../library/presentation/controllers/library_controller.dart';
import '../../library/presentation/widgets/track_tile.dart';
import '../../player/presentation/controllers/player_controller.dart';
import '../../youtube_music/presentation/youtube_discovery_screen.dart';
import 'widgets/simple_as_f_discovery_grid.dart';
import 'widgets/studio_instant_mix_banner.dart';
import 'widgets/studio_wrapped_bento_banner.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  final VoidCallback? onNavigateToPlayer;
  final VoidCallback? onNavigateToLibrary;
  final VoidCallback? onNavigateToDsp;

  const DashboardScreen({
    super.key,
    this.onNavigateToPlayer,
    this.onNavigateToLibrary,
    this.onNavigateToDsp,
  });

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final libraryState = ref.watch(unifiedLibraryProvider);
    final tracks = libraryState.tracks;
    final playback = ref.watch(playerControllerProvider);

    // Get favorite tracks or fallback to recent tracks
    final favoriteTracks = tracks
        .where((t) => libraryState.favoriteTrackIds.contains(t.id))
        .take(5)
        .toList();
    final sampleTracks = favoriteTracks.isNotEmpty
        ? favoriteTracks
        : tracks.take(5).toList();

    return SimpleAsFScaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.fromLTRB(18.0, 14.0, 18.0, 160.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── 1. USER GREETING HEADER ─────────────────────────────────────
              _buildHeader(context)
                  .animate()
                  .fadeIn(duration: 250.ms, curve: Curves.easeOut)
                  .slideY(begin: -0.04, end: 0.0, curve: Curves.easeOutCubic),

              const SizedBox(height: 18),

              // ─── 2. STUDIO WRAPPED RECAP (Placed Above Recently Played) ───────
              const StudioWrappedBentoBanner(),

              const SizedBox(height: 14),

              // ─── 3. DISCOVERY SMART MIX SUGGESTION BANNER ────────────────────
              const StudioInstantMixBanner(),

              const SizedBox(height: 14),

              // ─── 4. QUICK YOUTUBE MUSIC HIFI LAUNCHER CAPSULE ─────────────────
              Builder(
                builder: (ctx) {
                  final isDark = Theme.of(ctx).brightness == Brightness.dark;
                  return InkWell(
                    onTap: () {
                      AppHaptics.lightImpact();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const YouTubeDiscoveryScreen()),
                      );
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF16181F)
                            : Theme.of(ctx).colorScheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF262936)
                              : Theme.of(ctx).colorScheme.outlineVariant,
                          width: 1.0,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            LucideIcons.playSquare,
                            size: 16,
                            color: Color(0xFF34D399),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Explore YouTube Music HiFi • Global Streaming',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Theme.of(ctx).colorScheme.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            LucideIcons.chevronRight,
                            size: 14,
                            color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // ─── 5. RECENTLY PLAYED SQUIRCLE GRID (Real Data • 2x2 on Mobile) ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Expanded(
                    child: TwoToneHeader(
                      primaryText: 'RECENTLY',
                      accentText: 'PLAYED',
                      fontSize: 20,
                    ),
                  ),
                  if (widget.onNavigateToLibrary != null)
                    InkWell(
                      onTap: () {
                        AppHaptics.lightImpact();
                        widget.onNavigateToLibrary!();
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Row(
                          children: [
                            Text(
                              'See all',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const SizedBox(width: 2),
                            Icon(
                              LucideIcons.chevronRight,
                              size: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              const SimpleAsFDiscoveryGrid(),

              const SizedBox(height: 26),

              // ─── 6. LIKED / TOP SONGS (Uncluttered, No Download Toggle) ───────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: TwoToneHeader(
                      primaryText: favoriteTracks.isNotEmpty ? 'LIKED' : 'TOP',
                      accentText: 'SONGS',
                      fontSize: 20,
                    ),
                  ),
                  if (widget.onNavigateToLibrary != null)
                    InkWell(
                      onTap: () {
                        AppHaptics.lightImpact();
                        widget.onNavigateToLibrary!();
                      },
                      borderRadius: BorderRadius.circular(6),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Text(
                          'View library',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),

              // Uncarded floating track list with soft dark active capsule
              if (sampleTracks.isNotEmpty)
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: EdgeInsets.zero,
                  itemCount: sampleTracks.length,
                  itemBuilder: (context, index) {
                    final track = sampleTracks[index];
                    final isPlaying = playback.isPlaying && playback.currentTrack?.id == track.id;

                    return TrackTile(
                      track: track,
                      isPlaying: isPlaying,
                      onTap: () {
                        AppHaptics.selectionClick();
                        ref.read(playerControllerProvider.notifier).setQueue(
                          sampleTracks,
                          initialIndex: index,
                        );
                      },
                    );
                  },
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                  alignment: Alignment.center,
                  child: Text(
                    'No tracks available yet. Scan your music folder in Library.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const MetaTrackingLabel(
                'WELCOME TO BAYDEV HIFI',
                fontSize: 11,
                letterSpacing: 1.6,
                color: SimpleAsFTheme.sageSlate,
              ),
              const SizedBox(height: 4),
              const TwoToneHeader(
                primaryText: 'DISCOVER',
                accentText: 'MUSIC',
                fontSize: 24,
                letterSpacing: -0.4,
              ),
            ],
          ),
        ),

        // Right: Profile Avatar Button
        const DashboardProfileButton(),
      ],
    );
  }
}
