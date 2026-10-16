import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../../core/widgets/studio_artwork_widget.dart';
import '../../../domain/studio_wrapped_data.dart';

/// Template 4: Vintage Cassette Tape / Reel J-Card Edition
/// Features analog tape typography, Chrome Type II badges, and nostalgic 80s/90s cassette insert aesthetics.
class CassetteJCardView extends StatelessWidget {
  final StudioWrappedData data;

  const CassetteJCardView({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    const cardBg = Color(0xFFE5E5E5); // Vintage J-Card Paper
    const spineBg = Color(0xFF1E293B); // Dark Slate Spine
    const inkColor = Color(0xFF0F172A);
    const mutedInk = Color(0xFF475569);
    const accentColor = Color(0xFFDC2626); // Analog Red

    const monoStyle = TextStyle(
      fontFamily: 'monospace',
      fontFeatures: [FontFeature.tabularFigures()],
    );

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF94A3B8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── CASSETTE SPINE HEADER ─────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: spineBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Text(
                      'BAYDEV',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2.0, color: Colors.white),
                    ),
                    SizedBox(width: 6),
                    Text(
                      'TYPE II [CrO2]',
                      style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w700, letterSpacing: 0.8, color: Color(0xFF38BDF8)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: const Text(
                    'DOLBY B-C NR',
                    style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5),
                  ),
                ),
              ],
            ),
          ),

          // ─── TAPE BODY ─────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Tape Title & Metadata with Album Art Thumbnail
                Row(
                  children: [
                    StudioArtworkWidget(
                      url: data.topTrack?.albumArtUri,
                      width: 42,
                      height: 42,
                      borderRadius: BorderRadius.circular(4),
                      fallbackIcon: LucideIcons.disc,
                      fallbackIconSize: 20,
                      backgroundColor: const Color(0xFFCBD5E1),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '2026 MASTER TAPE REEL',
                            style: monoStyle.copyWith(fontSize: 11, fontWeight: FontWeight.w900, color: inkColor, letterSpacing: 0.8),
                          ),
                          Text(
                            'TOP: ${data.topTrack?.title.toUpperCase() ?? "DIRECT MASTER"}',
                            style: monoStyle.copyWith(fontSize: 8.0, fontWeight: FontWeight.w800, color: accentColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'HI-RES CASSETTE // ${data.totalMinutes} MINS',
                            style: monoStyle.copyWith(fontSize: 7.5, fontWeight: FontWeight.w700, color: mutedInk),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'SIDE A',
                        style: TextStyle(fontSize: 9.0, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // 2. Analog Tape Spool Graphic
                _buildCassetteSpoolGraphic(inkColor),
                const SizedBox(height: 14),

                Container(height: 1.2, color: const Color(0xFFCBD5E1)),
                const SizedBox(height: 10),

                // 3. Track Listing (J-Card Lined Form)
                Text(
                  'PROGRAM LISTING (TOP 5 TRACKS):',
                  style: monoStyle.copyWith(fontSize: 8.5, fontWeight: FontWeight.w800, color: mutedInk, letterSpacing: 0.8),
                ),
                const SizedBox(height: 8),

                ...data.topTracks.take(5).map((track) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0), width: 0.8)),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'A${track.rank}. ',
                          style: monoStyle.copyWith(fontSize: 9.5, fontWeight: FontWeight.w900, color: accentColor),
                        ),
                        StudioArtworkWidget(
                          url: track.albumArtUri,
                          width: 16,
                          height: 16,
                          borderRadius: BorderRadius.circular(3),
                          fallbackIcon: LucideIcons.music,
                          fallbackIconSize: 10,
                          backgroundColor: const Color(0xFFCBD5E1),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${track.title} - ${track.artist}',
                            style: monoStyle.copyWith(fontSize: 9.0, fontWeight: FontWeight.w700, color: inkColor),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '(${track.totalMinutes}m)',
                          style: monoStyle.copyWith(fontSize: 8.5, fontWeight: FontWeight.w600, color: mutedInk),
                        ),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 12),

                // 4. Audiophile Stats Footer Box
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFCBD5E1), width: 1.0),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('TAPE BIAS / PURITY:', style: monoStyle.copyWith(fontSize: 8.0, fontWeight: FontWeight.w700, color: mutedInk)),
                          Text('${data.purityReport.flacPercentage.toStringAsFixed(1)}% LOSSLESS FLAC', style: monoStyle.copyWith(fontSize: 8.0, fontWeight: FontWeight.w900, color: inkColor)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('PERSONA ARCHETYPE:', style: monoStyle.copyWith(fontSize: 8.0, fontWeight: FontWeight.w700, color: mutedInk)),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              data.persona.title.toUpperCase(),
                              style: monoStyle.copyWith(fontSize: 8.0, fontWeight: FontWeight.w900, color: accentColor),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.end,
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
        ],
      ),
    );
  }

  Widget _buildCassetteSpoolGraphic(Color color) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: const Color(0xFF334155),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1E293B), width: 1.2),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildSpoolHole(),
          Container(
            width: 70,
            height: 12,
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(3),
            ),
            child: const Center(
              child: Text(
                'INDEX 100',
                style: TextStyle(fontSize: 6.5, fontWeight: FontWeight.w800, color: Color(0xFF94A3B8), fontFamily: 'monospace'),
              ),
            ),
          ),
          _buildSpoolHole(),
        ],
      ),
    );
  }

  Widget _buildSpoolHole() {
    return Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF0F172A), width: 3.0),
      ),
      child: Center(
        child: Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: Color(0xFF0F172A),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
