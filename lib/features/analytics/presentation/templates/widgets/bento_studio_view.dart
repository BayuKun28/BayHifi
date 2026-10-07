import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../../core/widgets/studio_artwork_widget.dart';
import '../../../domain/studio_wrapped_data.dart';

/// 🍱 Template 3: Modern Bento Studio (Material 3 Expressive Edition)
/// Features balanced squircle bento cards, restrained studio palette, and high information clarity.
class BentoStudioView extends StatelessWidget {
  final StudioWrappedData data;

  const BentoStudioView({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final topTrack = data.topTrack;
    final topArtist = data.topArtist;
    final persona = data.persona;

    const surfaceColor = Color(0xFF14151B);
    const cardBgColor = Color(0xFF1C1D24);
    const borderColor = Color(0xFF2C2D38);
    const textPrimary = Color(0xFFF4F4F5);
    const textSecondary = Color(0xFFA1A1AA);
    const accentColor = Color(0xFF38BDF8);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── HEADER ────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BAYDEV HIFI',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.0,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    data.timeFilter.label.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: accentColor,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accentColor.withValues(alpha: 0.5), width: 0.8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HugeIcon(icon: HugeIcons.strokeRoundedSparkles, size: 11, color: accentColor),
                    SizedBox(width: 4),
                    Text(
                      'STUDIO LOSSLESS',
                      style: TextStyle(fontSize: 8.0, fontWeight: FontWeight.w800, color: accentColor, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ─── BENTO ROW 1: Top Track & Listening Time ───────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Track Spotlight
              Expanded(
                flex: 6,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 1.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          HugeIcon(icon: HugeIcons.strokeRoundedDisc, size: 13, color: accentColor),
                          SizedBox(width: 4),
                          Text(
                            'TOP TRACK #1',
                            style: TextStyle(fontSize: 8.0, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: accentColor),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          StudioArtworkWidget(
                            url: topTrack?.albumArtUri,
                            width: 36,
                            height: 36,
                            borderRadius: BorderRadius.circular(8),
                            fallbackIcon: HugeIcons.strokeRoundedMusicNote01,
                            fallbackIconSize: 18,
                            backgroundColor: const Color(0xFF27272A),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  topTrack?.title ?? 'Comfortably Numb',
                                  style: const TextStyle(fontSize: 12.0, fontWeight: FontWeight.w900, color: textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  topTrack?.artist ?? 'Pink Floyd',
                                  style: const TextStyle(fontSize: 9.0, fontWeight: FontWeight.w600, color: textSecondary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF27272A),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          topTrack?.formatBadge ?? 'FLAC 24-bit/96kHz',
                          style: const TextStyle(fontSize: 7.5, fontWeight: FontWeight.w700, color: Color(0xFF38BDF8)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Listening Minutes Bento
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 1.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          HugeIcon(icon: HugeIcons.strokeRoundedClock01, size: 13, color: Color(0xFF10B981)),
                          SizedBox(width: 4),
                          Text(
                            'STUDIO TIME',
                            style: TextStyle(fontSize: 8.0, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: Color(0xFF10B981)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${data.totalMinutes}',
                        style: const TextStyle(
                          fontSize: 16.0,
                          fontWeight: FontWeight.w900,
                          fontFeatures: [FontFeature.tabularFigures()],
                          color: textPrimary,
                        ),
                      ),
                      const Text(
                        'Total Minutes',
                        style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600, color: textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ─── BENTO ROW 2: Top Artist & Hi-Res Purity ────────────────
          Row(
            children: [
              // Top Artist Bento
              Expanded(
                flex: 6,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 1.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          HugeIcon(icon: HugeIcons.strokeRoundedUser, size: 13, color: Color(0xFFEC4899)),
                          SizedBox(width: 4),
                          Text(
                            'TOP ARTIST',
                            style: TextStyle(fontSize: 8.0, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: Color(0xFFEC4899)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          StudioArtworkWidget(
                            url: topArtist?.artworkUrl,
                            width: 30,
                            height: 30,
                            borderRadius: BorderRadius.circular(15),
                            fallbackIcon: HugeIcons.strokeRoundedUser,
                            fallbackIconSize: 16,
                            backgroundColor: const Color(0xFF27272A),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  topArtist?.artist ?? 'Pink Floyd',
                                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: textPrimary),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  '${topArtist?.percentage.toStringAsFixed(1) ?? "38.5"}% Share',
                                  style: const TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600, color: textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Lossless Purity Bento
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: cardBgColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor, width: 1.0),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          HugeIcon(icon: HugeIcons.strokeRoundedCheckmarkBadge01, size: 13, color: Color(0xFFA855F7)),
                          SizedBox(width: 4),
                          Text(
                            'HI-RES PURITY',
                            style: TextStyle(fontSize: 8.0, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: Color(0xFFA855F7)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${data.purityReport.flacPercentage.toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          fontFeatures: [FontFeature.tabularFigures()],
                          color: textPrimary,
                        ),
                      ),
                      const Text(
                        'Lossless FLAC',
                        style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w600, color: textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // ─── BENTO ROW 3: Top 5 Tracks List ─────────────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: cardBgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'TOP 5 TRACKS IN HEAVY ROTATION',
                      style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w800, letterSpacing: 0.8, color: textSecondary),
                    ),
                    Text(
                      'MINS',
                      style: TextStyle(fontSize: 8.0, fontWeight: FontWeight.w700, color: textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ...data.topTracks.take(5).map((track) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 18,
                          child: Text(
                            '#${track.rank}',
                            style: const TextStyle(fontSize: 9.0, fontWeight: FontWeight.w900, color: accentColor),
                          ),
                        ),
                        StudioArtworkWidget(
                          url: track.albumArtUri,
                          width: 18,
                          height: 18,
                          borderRadius: BorderRadius.circular(4),
                          fallbackIcon: HugeIcons.strokeRoundedMusicNote01,
                          fallbackIconSize: 10,
                          backgroundColor: const Color(0xFF27272A),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${track.title} • ${track.artist}',
                            style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: textPrimary),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${track.totalMinutes}m',
                          style: const TextStyle(
                            fontSize: 9.0,
                            fontWeight: FontWeight.w800,
                            fontFeatures: [FontFeature.tabularFigures()],
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // ─── BENTO ROW 4: Audiophile Persona Card ───────────────────
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  persona.primaryColor.withValues(alpha: 0.25),
                  persona.secondaryColor.withValues(alpha: 0.10),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: persona.primaryColor.withValues(alpha: 0.5), width: 1.2),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: persona.primaryColor.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: HugeIcon(icon: persona.icon, size: 20, color: persona.primaryColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'AUDIOPHILE PERSONA',
                        style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w800, letterSpacing: 1.0, color: textSecondary),
                      ),
                      Text(
                        persona.title,
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w900, color: persona.primaryColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        persona.subtitle,
                        style: const TextStyle(fontSize: 8.5, color: textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ─── FOOTER ─────────────────────────────────────────────────
          const Center(
            child: Text(
              'BAYDEV HIFI • LOSSLESS AUDIO & DSP MASTERING WORKSTATION',
              style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w700, letterSpacing: 1.0, color: Color(0xFF71717A)),
            ),
          ),
        ],
      ),
    );
  }
}
