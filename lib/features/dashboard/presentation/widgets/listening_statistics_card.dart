import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import '../../../../app/theme/app_haptics.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../app/theme/studio_surface_theme.dart';
import '../../../../core/widgets/studio_artwork_widget.dart';
import '../../../analytics/data/playback_analytics_service.dart';
import '../../../analytics/presentation/details/studio_listening_stats_detail_screen.dart';
import '../../../player/domain/track.dart';
import '../../../player/presentation/controllers/player_controller.dart';

/// Redesigned Bento Studio Listening Statistics Card
/// Showcases live telemetry, audiophile persona badge, top artists, top tracks,
/// and provides a direct entry point into the comprehensive StudioListeningStatsDetailScreen.
class ListeningStatisticsCard extends ConsumerWidget {
  const ListeningStatisticsCard({super.key});

  String _formatListeningTime(int totalMinutes) {
    if (totalMinutes <= 0) return '0 min';
    final hours = totalMinutes ~/ 60;
    final mins = totalMinutes % 60;
    if (hours > 0) {
      return mins > 0 ? '${hours}h ${mins}m' : '${hours}h';
    }
    return '${mins}m';
  }

  void _openDetailScreen(BuildContext context) {
    AppHaptics.lightImpact();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const StudioListeningStatsDetailScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isSolid = ref.isSolidStyle;
    final data = ref.watch(studioWrappedDataProvider);
    final persona = data.persona;
    final purity = data.purityReport;

    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;
    final tertiary = theme.colorScheme.tertiary;

    final totalMinutes = data.totalMinutes;
    final totalTracks = data.totalTracksPlayed;
    final flacPct = purity.flacPercentage;
    final hiResCount = purity.hiResCount;
    final topTracks = data.topTracks.take(3).toList();
    final topArtists = data.topArtists.take(3).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: StudioSurfaceTheme.cardDecoration(
        context: context,
        isSolid: isSolid,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── HEADER ROW ──────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(
                      LucideIcons.chartColumn,
                      size: 16,
                      color: StudioCategoryColors.statistics,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'AUDIOPHILE LISTENING STATS',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.badge(color: StudioCategoryColors.statistics),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: StudioSurfaceTheme.tintedContainer(context, persona.primaryColor, isSolid: isSolid),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          persona.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            color: persona.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              // View All Insights Action Button
              InkWell(
                onTap: () => _openDetailScreen(context),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: StudioSurfaceTheme.tintedContainer(context, primary, isSolid: isSolid),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: primary.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          color: primary,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        LucideIcons.arrowRight,
                        size: 12,
                        color: primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ─── 3 METRICS TILES ──────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  context: context,
                  isSolid: isSolid,
                  label: 'Listening Time',
                  value: _formatListeningTime(totalMinutes),
                  icon: LucideIcons.clock,
                  accentColor: StudioCategoryColors.statistics,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  context: context,
                  isSolid: isSolid,
                  label: 'Total Plays',
                  value: '$totalTracks',
                  icon: LucideIcons.music,
                  accentColor: StudioCategoryColors.themingPalettes,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  context: context,
                  isSolid: isSolid,
                  label: 'Lossless Purity',
                  value: '${flacPct.toStringAsFixed(0)}%',
                  icon: LucideIcons.shieldCheck,
                  accentColor: StudioCategoryColors.hiResGold,
                ),
              ),
            ],
          ),

          // ─── HI-RES PROGRESS BAR ──────────────────────────────────────────
          if (totalTracks > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: M3EProgressIndicator.linear(
                value: (flacPct / 100.0).clamp(0.0, 1.0),
                trackColor: theme.colorScheme.surfaceContainerHighest,
                color: StudioCategoryColors.hiResGold,
                strokeWidth: 4,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    '$hiResCount Hi-Res Lossless Plays',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 9.5,
                      color: StudioCategoryColors.hiResGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '${totalTracks - hiResCount} Standard Plays',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.end,
                    style: TextStyle(
                      fontSize: 9.5,
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],

          // ─── TOP 3 ARTISTS PREVIEW ────────────────────────────────────────
          if (topArtists.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'TOP ARTISTS ROTATION',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: topArtists.asMap().entries.map((e) {
                final index = e.key;
                final artist = e.value;
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: index < 2 ? 6.0 : 0.0),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    decoration: BoxDecoration(
                      color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        StudioArtworkWidget(
                          url: artist.artworkUrl,
                          width: 28,
                          height: 28,
                          borderRadius: BorderRadius.circular(14),
                          fallbackIcon: LucideIcons.mic,
                          fallbackIconSize: 14,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                artist.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurface,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '${artist.percentage.toStringAsFixed(0)}% share',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w600,
                                  fontFeatures: const [FontFeature.tabularFigures()],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ],

          // ─── TOP 3 TRACKS SPOTLIGHT ───────────────────────────────────────
          if (topTracks.isNotEmpty) ...[
            const SizedBox(height: 14),
            Text(
              'HEAVIEST ROTATION TRACKS',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 9.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 8),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: topTracks.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (context, index) {
                final track = topTracks[index];
                final rank = index + 1;

                final rankColor = switch (rank) {
                  1 => primary,
                  2 => secondary,
                  3 => tertiary,
                  _ => theme.colorScheme.onSurfaceVariant,
                };

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Rank Badge
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: StudioSurfaceTheme.tintedContainer(context, rankColor, isSolid: isSolid),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Center(
                          child: Text(
                            '#$rank',
                            style: TextStyle(
                              color: rankColor,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Artwork Thumbnail
                      StudioArtworkWidget(
                        url: track.albumArtUri,
                        width: 30,
                        height: 30,
                        borderRadius: BorderRadius.circular(6),
                        fallbackIcon: LucideIcons.music,
                        fallbackIconSize: 14,
                      ),
                      const SizedBox(width: 10),
                      // Track Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              track.title,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              '${track.artist} • ${track.playCount} plays',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 9.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (track.isHiRes) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: StudioSurfaceTheme.tintedContainer(context, primary, isSolid: isSolid),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            'Hi-Res',
                            style: TextStyle(
                              color: primary,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 6),
                      // Instant Play Button
                      InkWell(
                        onTap: () {
                          AppHaptics.selectionClick();
                          final playTrackObj = Track(
                            id: track.trackId.isNotEmpty ? track.trackId : 'rec_${index + 1}',
                            title: track.title,
                            artist: track.artist,
                            album: track.album,
                            duration: Duration(minutes: track.totalMinutes),
                            albumArtUrl: track.albumArtUri,
                            format: AudioFormat.flac,
                            sampleRate: track.sampleRate,
                            bitDepth: track.bitDepth,
                          );
                          ref.read(playerControllerProvider.notifier).playTrack(playTrackObj);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: StudioSurfaceTheme.tintedContainer(context, primary, isSolid: isSolid),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Icon(
                              LucideIcons.play,
                              size: 13,
                              color: primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],

          const SizedBox(height: 12),

          // ─── FOOTER TAP ACTION ───────────────────────────────────────────
          InkWell(
            onTap: () => _openDetailScreen(context),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      'Explore full listening insights & signal telemetry',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    LucideIcons.arrowRight,
                    size: 13,
                    color: primary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required BuildContext context,
    required bool isSolid,
    required String label,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: StudioSurfaceTheme.surfaceContainerHigh(context, isSolid: isSolid),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 12,
                color: accentColor,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontSize: 13.5,
              fontWeight: FontWeight.w900,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
