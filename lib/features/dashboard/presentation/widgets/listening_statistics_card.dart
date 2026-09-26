import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../core/database/local_persistence_service.dart';
import '../../../player/domain/track.dart';
import '../../../player/presentation/controllers/player_controller.dart';

class ListeningStatisticsCard extends ConsumerStatefulWidget {
  const ListeningStatisticsCard({super.key});

  @override
  ConsumerState<ListeningStatisticsCard> createState() => _ListeningStatisticsCardState();
}

class _ListeningStatisticsCardState extends ConsumerState<ListeningStatisticsCard> {
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  void _loadStats() {
    if (mounted) {
      setState(() {
        _stats = LocalPersistenceService.instance.getListeningStats();
      });
    }
  }

  String _formatListeningTime(int totalSeconds) {
    if (totalSeconds <= 0) return '0 min';
    final hours = totalSeconds ~/ 3600;
    final mins = (totalSeconds % 3600) ~/ 60;
    if (hours > 0) {
      return '${hours}h ${mins}m';
    }
    return '${mins}m';
  }

  @override
  Widget build(BuildContext context) {
    // Re-check stats when playback changes
    ref.listen(playerControllerProvider, (_, _) => _loadStats());


    final totalTracks = _stats['totalTracksPlayed'] as int? ?? 0;
    final totalSec = _stats['totalListeningSeconds'] as int? ?? 0;
    final hiResCount = _stats['hiResTracksPlayed'] as int? ?? 0;
    final hiResPct = (_stats['hiResPercentage'] as num?)?.toDouble() ?? 0.0;
    final topTracks = (_stats['topTracks'] as List?)?.whereType<Map<String, dynamic>>().toList() ?? [];

    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final secondary = theme.colorScheme.secondary;
    final tertiary = theme.colorScheme.tertiary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.6),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── HEADER ────────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  HugeIcon(
                    icon: HugeIcons.strokeRoundedAnalytics01,
                    size: 16,
                    color: primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'AUDIOPHILE LISTENING STATS',
                    style: AppTypography.badge(color: primary),
                  ),
                ],
              ),
              if (totalTracks > 0)
                InkWell(
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    await LocalPersistenceService.instance.clearPlaybackHistory();
                    _loadStats();
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainer,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.5),
                        width: 0.8,
                      ),
                    ),
                    child: Text(
                      'Clear History',
                      style: TextStyle(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
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
                  label: 'Listening Time',
                  value: _formatListeningTime(totalSec),
                  icon: HugeIcons.strokeRoundedClock01,
                  accentColor: primary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  context: context,
                  label: 'Total Plays',
                  value: '$totalTracks',
                  icon: HugeIcons.strokeRoundedMusicNote01,
                  accentColor: secondary,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricTile(
                  context: context,
                  label: 'Hi-Res Ratio',
                  value: '${hiResPct.toStringAsFixed(0)}%',
                  icon: HugeIcons.strokeRoundedShieldEnergy,
                  accentColor: tertiary,
                ),
              ),
            ],
          ),

          // ─── HI-RES PROGRESS BAR ──────────────────────────────────────────
          if (totalTracks > 0) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (hiResPct / 100.0).clamp(0.0, 1.0),
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(tertiary),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$hiResCount Hi-Res Lossless Plays',
                  style: TextStyle(
                    fontSize: 9.5,
                    color: tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '${totalTracks - hiResCount} Standard Plays',
                  style: TextStyle(
                    fontSize: 9.5,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],

          // ─── TOP 5 MOST PLAYED TRACKS ────────────────────────────────────
          if (topTracks.isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'TOP PLAYED TRACKS',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 10,
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
                final trackMap = topTracks[index];
                final track = Track.fromMap(trackMap);
                final count = trackMap['count'] as int? ?? 1;
                final rank = index + 1;

                final rankColor = switch (rank) {
                  1 => primary,
                  2 => secondary,
                  3 => tertiary,
                  _ => theme.colorScheme.onSurfaceVariant,
                };

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.dividerColor.withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      // Rank Badge
                      Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: rankColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: rankColor.withValues(alpha: 0.6), width: 0.8),
                        ),
                        child: Center(
                          child: Text(
                            '#$rank',
                            style: TextStyle(
                              color: rankColor,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
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
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              '${track.artist} • $count ${count == 1 ? "play" : "plays"}',
                              style: TextStyle(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 10.5,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (track.isHiRes) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: primary.withValues(alpha: 0.3),
                              width: 0.6,
                            ),
                          ),
                          child: Text(
                            'Hi-Res',
                            style: TextStyle(
                              color: primary,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(width: 6),
                      // Instant Play Button
                      InkWell(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ref.read(playerControllerProvider.notifier).playTrack(track);
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: primary.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                            border: Border.all(color: primary.withValues(alpha: 0.6)),
                          ),
                          child: Center(
                            child: HugeIcon(
                              icon: HugeIcons.strokeRoundedPlay,
                              size: 14,
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
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required BuildContext context,
    required String label,
    required String value,
    required dynamic icon,
    required Color accentColor,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.dividerColor.withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              HugeIcon(
                icon: icon,
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
              fontSize: 14,
              fontWeight: FontWeight.w900,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
