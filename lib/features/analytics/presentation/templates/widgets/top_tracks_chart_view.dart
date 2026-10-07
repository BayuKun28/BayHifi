import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../../core/widgets/studio_artwork_widget.dart';
import '../../../domain/studio_wrapped_data.dart';

/// Dedicated Focus Card 4: Top 10 Master Tracks Chart
/// Showcases the user's top ranked tracks with album art, play counts, duration, and audiophile format badges.
class TopTracksChartView extends StatelessWidget {
  final StudioWrappedData data;

  const TopTracksChartView({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final topTracks = data.topTracks;
    final topTrack = topTracks.isNotEmpty ? topTracks.first : null;
    final otherTracks = topTracks.skip(1).take(9).toList();
    final persona = data.persona;

    const cardBg = Color(0xFF0D1017);
    const goldAccent = Color(0xFFF59E0B);
    const cyanAccent = Color(0xFF38BDF8);
    const textBright = Color(0xFFF8FAFC);
    const textDim = Color(0xFF94A3B8);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF21283B), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: goldAccent.withValues(alpha: 0.15),
            blurRadius: 36,
            offset: const Offset(0, 12),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.75),
            blurRadius: 28,
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── 1. TOP HEADER BANNER ──────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF181F2F),
                  persona.primaryColor.withValues(alpha: 0.25),
                ],
              ),
              border: const Border(
                bottom: BorderSide(color: Color(0xFF263147), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedAward01,
                        size: 16,
                        color: goldAccent,
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'MASTER TRACKS CHART // 2026',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.8,
                            color: textBright,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                  decoration: BoxDecoration(
                    color: goldAccent.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: goldAccent.withValues(alpha: 0.5), width: 0.8),
                  ),
                  child: const Text(
                    'OFFICIAL RANKING',
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 8.0,
                      fontWeight: FontWeight.w900,
                      color: goldAccent,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── 2. #01 TOP TRACK HERO SPOTLIGHT ───────────────────
                if (topTrack != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          goldAccent.withValues(alpha: 0.15),
                          const Color(0xFF141926),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: goldAccent.withValues(alpha: 0.45), width: 1.2),
                    ),
                    child: Row(
                      children: [
                        // Album Art with #1 Badge
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            StudioArtworkWidget(
                              url: topTrack.albumArtUri,
                              width: 68,
                              height: 68,
                              borderRadius: BorderRadius.circular(14),
                              fallbackIcon: HugeIcons.strokeRoundedMusicNote01,
                              fallbackIconSize: 28,
                              backgroundColor: const Color(0xFF1E2433),
                            ),
                            Positioned(
                              top: -6,
                              left: -6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: goldAccent,
                                  borderRadius: BorderRadius.circular(8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: goldAccent.withValues(alpha: 0.4),
                                      blurRadius: 8,
                                    ),
                                  ],
                                ),
                                child: const Text(
                                  '#01',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.black,
                                    fontFeatures: [FontFeature.tabularFigures()],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 14),

                        // Track Details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: cyanAccent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'MOST PLAYED ANTHEM',
                                  style: TextStyle(
                                    fontSize: 7.5,
                                    fontWeight: FontWeight.w900,
                                    color: cyanAccent,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                topTrack.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 14.5,
                                  fontWeight: FontWeight.w900,
                                  color: textBright,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                topTrack.artist,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: textDim,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  HugeIcon(
                                    icon: HugeIcons.strokeRoundedRepeat,
                                    size: 11,
                                    color: goldAccent,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${topTrack.playCount} plays',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: goldAccent,
                                      fontFeatures: [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    '•',
                                    style: TextStyle(color: Color(0xFF475569), fontSize: 10),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${topTrack.totalDuration.inMinutes} mins',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: textDim,
                                      fontFeatures: [FontFeature.tabularFigures()],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                ],

                // ─── 3. RANKED TRACKS #02 TO #10 ──────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131722),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF1E2538), width: 1),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: otherTracks.length,
                    separatorBuilder: (_, _) => const Divider(
                      color: Color(0xFF1A2133),
                      height: 12,
                      thickness: 0.8,
                    ),
                    itemBuilder: (context, index) {
                      final track = otherTracks[index];
                      final rankStr = track.rank < 10 ? '#0${track.rank}' : '#${track.rank}';
                      final isTopThree = track.rank <= 3;

                      return Row(
                        children: [
                          // Rank Number
                          SizedBox(
                            width: 26,
                            child: Text(
                              rankStr,
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                fontWeight: FontWeight.w900,
                                color: isTopThree ? goldAccent : const Color(0xFF64748B),
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),

                          // Album Thumbnail
                          StudioArtworkWidget(
                            url: track.albumArtUri,
                            width: 32,
                            height: 32,
                            borderRadius: BorderRadius.circular(8),
                            fallbackIcon: HugeIcons.strokeRoundedMusicNote01,
                            fallbackIconSize: 14,
                            backgroundColor: const Color(0xFF1C2233),
                          ),
                          const SizedBox(width: 10),

                          // Track info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  track.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: textBright,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  track.artist,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: textDim,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),

                          // Play count
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${track.playCount}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w900,
                                  color: textBright,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                              const Text(
                                'PLAYS',
                                style: TextStyle(
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF64748B),
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ],
                      );
                    },
                  ),
                ),
                const SizedBox(height: 14),

                // ─── 4. SUMMARY TELEMETRY STATS ────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131722),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF1E2538)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL STREAMS',
                              style: TextStyle(
                                fontSize: 7.5,
                                fontWeight: FontWeight.w800,
                                color: textDim,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${data.totalTracksPlayed} Tracks',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                                color: cyanAccent,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF131722),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF1E2538)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL LISTENING',
                              style: TextStyle(
                                fontSize: 7.5,
                                fontWeight: FontWeight.w800,
                                color: textDim,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${data.totalListeningMinutes} Min',
                              style: const TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w900,
                                color: goldAccent,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ─── 5. FOOTER WATERMARK ───────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF080B10),
              border: Border(
                top: BorderSide(color: Color(0xFF181F2F), width: 1),
              ),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: HugeIcons.strokeRoundedMusicNoteSquare02,
                        size: 13,
                        color: cyanAccent,
                      ),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'BAYDEV HI-FI // MASTER AUDIO ARCHIVE',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 8.0,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF64748B),
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'BIT-PERFECT',
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 8.0,
                    fontWeight: FontWeight.w900,
                    color: cyanAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
