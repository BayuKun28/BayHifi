import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/widgets/studio_artwork_widget.dart';
import '../../../domain/studio_wrapped_data.dart';

/// Dedicated Focus Card 2: Top Artists Festival Lineup Poster
/// Features music festival poster hierarchy, Headliner spotlight, sub-headliners, and stage telemetry.
class ArtistLineupPosterView extends StatelessWidget {
  final StudioWrappedData data;

  const ArtistLineupPosterView({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final topArtists = data.topArtists;
    final headliner = topArtists.isNotEmpty ? topArtists.first : null;
    final subHeadliners = topArtists.skip(1).take(3).toList();
    final supportingActs = topArtists.skip(4).take(6).toList();
    final persona = data.persona;

    const posterBg = Color(0xFF11131A);
    const goldAccent = Color(0xFFF59E0B);
    const cyanAccent = Color(0xFF00E5FF);
    const textLight = Color(0xFFF8FAFC);
    const textDim = Color(0xFF94A3B8);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: posterBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF262B3D), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.75),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── 1. FESTIVAL HEADER BANNER ─────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF1E2436),
                  persona.primaryColor.withValues(alpha: 0.3),
                ],
              ),
              border: const Border(
                bottom: BorderSide(color: Color(0xFF2D354D), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.mic,
                        size: 16,
                        color: cyanAccent,
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'BAYDEV HI-FI FESTIVAL // 2026',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 2.0,
                            color: textLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: cyanAccent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: cyanAccent.withValues(alpha: 0.5)),
                  ),
                  child: const Text(
                    'MAIN STAGE',
                    style: TextStyle(
                      fontSize: 8.0,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: cyanAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── 2. HEADLINER ACT SPOTLIGHT (TOP 1) ─────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181C28),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: goldAccent.withValues(alpha: 0.5), width: 1.5),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 62,
                            height: 62,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: goldAccent, width: 2),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: StudioArtworkWidget(
                              url: headliner?.artworkUrl ?? data.topTrack?.albumArtUri,
                              width: 62,
                              height: 62,
                              borderRadius: BorderRadius.circular(31),
                              fallbackIcon: LucideIcons.user,
                              fallbackIconSize: 30,
                              backgroundColor: const Color(0xFF11131A),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: goldAccent.withValues(alpha: 0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'TOP HEADLINER #1',
                                        style: TextStyle(
                                          fontSize: 7.5,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.0,
                                          color: goldAccent,
                                        ),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${headliner?.percentage.toStringAsFixed(1) ?? '0.0'}% SHARE',
                                      style: const TextStyle(
                                        fontSize: 8.5,
                                        fontWeight: FontWeight.w800,
                                        color: goldAccent,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  headliner?.artist ?? 'Master Headliner',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 17.0,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.3,
                                    color: textLight,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${headliner?.playCount ?? 0} Encores • ${headliner?.totalMinutes ?? 0} Mins on Stage',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10.0,
                                    fontWeight: FontWeight.w600,
                                    color: textDim,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ─── 3. SUB-HEADLINERS TIER (TOP 2 - 4) ──────────────────
                const Center(
                  child: Text(
                    'DIRECT SUPPORT & SUB-HEADLINERS',
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: cyanAccent,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: subHeadliners.asMap().entries.map((entry) {
                    final index = entry.key + 2;
                    final artist = entry.value;
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(
                          right: entry.key < subHeadliners.length - 1 ? 6.0 : 0.0,
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161A26),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF262D42)),
                        ),
                        child: Column(
                          children: [
                            StudioArtworkWidget(
                              url: artist.artworkUrl,
                              width: 38,
                              height: 38,
                              borderRadius: BorderRadius.circular(19),
                              fallbackIcon: LucideIcons.user,
                              fallbackIconSize: 18,
                              backgroundColor: const Color(0xFF11131A),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '#$index ${artist.artist}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 10.0,
                                fontWeight: FontWeight.w800,
                                color: textLight,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${artist.playCount}x',
                              style: const TextStyle(
                                fontSize: 9.0,
                                fontWeight: FontWeight.w700,
                                color: textDim,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 14),

                // ─── 4. SUPPORTING ACTS TIER (TOP 5 - 10) ────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF141722),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF242A3D)),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'FEATURED STAGE LINEUP',
                        style: TextStyle(
                          fontSize: 8.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          color: textDim,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: (supportingActs.isNotEmpty
                                ? supportingActs
                                : [
                                    const TopArtistRank(rank: 5, artist: 'The Weeknd', playCount: 80, totalMinutes: 380, percentage: 9.5),
                                    const TopArtistRank(rank: 6, artist: 'Daft Punk', playCount: 65, totalMinutes: 310, percentage: 7.8),
                                    const TopArtistRank(rank: 7, artist: 'Radiohead', playCount: 50, totalMinutes: 240, percentage: 6.0),
                                  ])
                            .map((a) {
                          return Text(
                            a.artist.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10.0,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: textLight,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ─── 5. STAGE TELEMETRY & VENUE PASS ─────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E1017),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF202636)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'UNIQUE ARTISTS',
                              style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w800, color: textDim),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${data.uniqueArtistsCount}',
                              style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.w900, color: textLight),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E1017),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF202636)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'STAGE TIME',
                              style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w800, color: textDim),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${(data.totalMinutes / 60).round()} HRS',
                              style: const TextStyle(fontSize: 13.0, fontWeight: FontWeight.w900, color: cyanAccent),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E1017),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF202636)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'PASS TYPE',
                              style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w800, color: textDim),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              'VIP ALL-ACCESS',
                              style: TextStyle(fontSize: 11.0, fontWeight: FontWeight.w900, color: goldAccent),
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
        ],
      ),
    );
  }
}
