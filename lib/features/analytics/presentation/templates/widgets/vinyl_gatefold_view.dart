import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../../core/widgets/studio_artwork_widget.dart';
import '../../../domain/studio_wrapped_data.dart';

/// Template 6: 12" Vinyl Gatefold & LP Record Edition
/// Features realistic vinyl grooves, anisotropic light reflection sheen, center spindle label, and vintage gatefold liner notes.
class VinylGatefoldView extends StatelessWidget {
  final StudioWrappedData data;

  const VinylGatefoldView({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final topTrack = data.topTrack;
    final topArtist = data.topArtist;
    final persona = data.persona;
    final purity = data.audioPurityReport;

    const sleeveBg = Color(0xFF141210);
    const sleeveCardBg = Color(0xFF1F1C18);
    const goldAccent = Color(0xFFD4AF37);
    const warmCream = Color(0xFFF5EFEB);
    const mutedAmber = Color(0xFFA89F91);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: sleeveBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2C2722), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.7),
            blurRadius: 36,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── 1. TOP HEADER BANNER (VINTAGE AUDIOPHILE ARCHIVE) ─────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
              color: Color(0xFF241F1A),
              border: Border(
                bottom: BorderSide(color: Color(0xFF38312A), width: 1),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedRecord,
                        size: 14,
                        color: goldAccent,
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'ORIGINAL MASTER RECORDING',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: goldAccent.withValues(alpha: 0.95),
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
                    border: Border.all(color: goldAccent.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    '33⅓ RPM • STEREO',
                    style: TextStyle(
                      fontSize: 8.0,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                      color: warmCream,
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
                // ─── 2. VINYL RECORD DISC WITH CENTER ARTWORK SPINDLE ────
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 220,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // A. Vinyl Disc Grooves & Sheen
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _VinylRecordPainter(
                              accentColor: persona.primaryColor,
                            ),
                          ),
                        ),

                        // B. Center Label with Album Artwork
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF241F1A),
                            border: Border.all(color: goldAccent, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Positioned.fill(
                                child: Opacity(
                                  opacity: 0.85,
                                  child: StudioArtworkWidget(
                                    url: topTrack?.albumArtUri,
                                    width: 84,
                                    height: 84,
                                    borderRadius: BorderRadius.circular(42),
                                    fallbackIcon: HugeIcons.strokeRoundedDisc,
                                    fallbackIconSize: 36,
                                    backgroundColor: const Color(0xFF241F1A),
                                  ),
                                ),
                              ),
                              // Center Spindle Hole
                              Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: sleeveBg,
                                  border: Border.all(color: Colors.white70, width: 1.5),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                // Matrix Runout Etching
                Center(
                  child: Text(
                    'RUNOUT: BAY-HIFI-${data.timeFilter.shortLabel}-FLAC-96K-MASTER-A',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 8.0,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                      color: mutedAmber,
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // ─── 3. ALBUM & ARTIST LINER NOTES CARD ──────────────────
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: sleeveCardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF332E27)),
                  ),
                  child: Row(
                    children: [
                      // Top Artist Avatar / Artwork
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: goldAccent.withValues(alpha: 0.6)),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: StudioArtworkWidget(
                          url: topArtist?.artworkUrl ?? topTrack?.albumArtUri,
                          width: 50,
                          height: 50,
                          borderRadius: BorderRadius.circular(10),
                          fallbackIcon: HugeIcons.strokeRoundedUser,
                          fallbackIconSize: 24,
                          backgroundColor: goldAccent.withValues(alpha: 0.1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'FEATURED ARTIST',
                                  style: TextStyle(
                                    fontSize: 8.0,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.5,
                                    color: goldAccent.withValues(alpha: 0.9),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${topArtist?.playCount ?? 0} PLAYS',
                                  style: const TextStyle(
                                    fontSize: 9.0,
                                    fontWeight: FontWeight.w700,
                                    color: mutedAmber,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              topArtist?.artist ?? 'Audiophile Master',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14.0,
                                fontWeight: FontWeight.w900,
                                color: warmCream,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Sonic Persona: ${persona.title}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10.0,
                                fontWeight: FontWeight.w600,
                                color: mutedAmber,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ─── 4. SIDE A / SIDE B TRACKLISTING ─────────────────────
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF181512),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2C2722)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'SIDE A • MASTER CUTS',
                              style: TextStyle(
                                fontSize: 9.0,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.5,
                                color: goldAccent,
                              ),
                            ),
                          ),
                          Text(
                            '${(data.totalMinutes / 60).round()} HRS',
                            style: const TextStyle(
                              fontSize: 9.0,
                              fontWeight: FontWeight.w700,
                              color: warmCream,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      ...data.topTracks.take(4).toList().asMap().entries.map((entry) {
                        final index = entry.key + 1;
                        final track = entry.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4.5),
                          child: Row(
                            children: [
                              Text(
                                'A$index.',
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.w800,
                                  color: goldAccent,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  track.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.w600,
                                    color: warmCream,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${track.playCount}x',
                                style: const TextStyle(
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.w700,
                                  color: mutedAmber,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // ─── 5. FOOTER GATEFOLD LINER TELEMETRY ──────────────────
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: sleeveCardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2C2722)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'LOSSLESS PURITY',
                              style: TextStyle(
                                fontSize: 8.0,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: mutedAmber,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${purity.flacPercentage.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 13.0,
                                fontWeight: FontWeight.w900,
                                color: warmCream,
                              ),
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
                          color: sleeveCardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2C2722)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'HI-RES ARCHIVE',
                              style: TextStyle(
                                fontSize: 8.0,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: mutedAmber,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${purity.hiResPercentage.toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontSize: 13.0,
                                fontWeight: FontWeight.w900,
                                color: warmCream,
                              ),
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
                          color: sleeveCardBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2C2722)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'TOTAL TRACKS',
                              style: TextStyle(
                                fontSize: 8.0,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: mutedAmber,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${data.totalTracksPlayed}',
                              style: const TextStyle(
                                fontSize: 13.0,
                                fontWeight: FontWeight.w900,
                                color: warmCream,
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
        ],
      ),
    );
  }
}

/// Custom painter for the 12" Vinyl Disc with micro-grooves and anisotropic light reflections
class _VinylRecordPainter extends CustomPainter {
  final Color accentColor;

  _VinylRecordPainter({required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;

    // 1. Base Vinyl Black Body
    final basePaint = Paint()
      ..color = const Color(0xFF0F0F11)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, outerRadius, basePaint);

    // 2. Anisotropic Light Reflection Cones (Realistic 45° & 225° light sheen)
    final sheenPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          Colors.white.withValues(alpha: 0.12),
          Colors.transparent,
          Colors.white.withValues(alpha: 0.08),
          Colors.transparent,
          Colors.white.withValues(alpha: 0.12),
          Colors.transparent,
        ],
        stops: const [0.0, 0.12, 0.25, 0.5, 0.62, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: outerRadius));
    canvas.drawCircle(center, outerRadius, sheenPaint);

    // 3. Micro Grooves (Concentric Rings)
    final groovePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final denseGroovePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.07)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

    for (double r = 48; r < outerRadius - 4; r += 6) {
      canvas.drawCircle(center, r, groovePaint);
    }
    for (double r = 52; r < outerRadius - 8; r += 14) {
      canvas.drawCircle(center, r, denseGroovePaint);
    }

    // 4. Outer Rim Chamfer
    final rimPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, outerRadius - 1, rimPaint);

    // 5. Runout Groove (Lead-in area near center)
    final runoutPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 46, runoutPaint);
  }

  @override
  bool shouldRepaint(covariant _VinylRecordPainter oldDelegate) =>
      oldDelegate.accentColor != accentColor;
}
