import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import '../../../../../core/widgets/studio_artwork_widget.dart';
import '../../../domain/studio_wrapped_data.dart';

/// 🎟️ Template 7: VIP Concert Ticket Stub & Backstage Pass Edition
/// Features realistic perforated ticket notches, admission telemetry, holographic foil header, and live setlist.
class ConcertTicketView extends StatelessWidget {
  final StudioWrappedData data;

  const ConcertTicketView({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final topTrack = data.topTrack;
    final topArtist = data.topArtist;
    final persona = data.persona;

    const ticketBg = Color(0xFF161922);
    const stubBg = Color(0xFF10121A);
    const accentCyan = Color(0xFF00E5FF);
    const textLight = Color(0xFFF1F5F9);
    const textDim = Color(0xFF94A3B8);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 420),
      decoration: BoxDecoration(
        color: ticketBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF2B3245), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.65),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── 1. HOLOGRAPHIC FOIL HEADER ────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  persona.primaryColor.withValues(alpha: 0.85),
                  accentCyan.withValues(alpha: 0.9),
                  persona.secondaryColor.withValues(alpha: 0.85),
                ],
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
                        icon: HugeIcons.strokeRoundedTicket01,
                        size: 16,
                        color: Colors.black,
                      ),
                      SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'BAYDEV HI-FI TOUR • 2026',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 10.0,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.5,
                            color: Colors.black,
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
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'VIP ALL-ACCESS',
                    style: TextStyle(
                      fontSize: 8.0,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── 2. ADMISSION TELEMETRY BAR ────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: const Color(0xFF0D0F15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildAdmissionPill('GATE', 'FLAC/DSD'),
                _buildAdmissionPill('SEC', 'LOSSLESS'),
                _buildAdmissionPill('ROW', '24-BIT'),
                _buildAdmissionPill('SEAT', '96 kHz'),
              ],
            ),
          ),

          // ─── 3. MAIN STAGE & HEADLINER SECTION ─────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Headliner Artist Card
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E2330),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2E374D)),
                  ),
                  child: Row(
                    children: [
                      // Artist / Album Artwork Badge
                      Container(
                        width: 58,
                        height: 58,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: accentCyan.withValues(alpha: 0.6), width: 1.5),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: StudioArtworkWidget(
                          url: topArtist?.artworkUrl ?? topTrack?.albumArtUri,
                          width: 58,
                          height: 58,
                          borderRadius: BorderRadius.circular(12),
                          fallbackIcon: HugeIcons.strokeRoundedUser,
                          fallbackIconSize: 28,
                          backgroundColor: const Color(0xFF161922),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'HEADLINER ACT',
                              style: TextStyle(
                                fontSize: 8.0,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.5,
                                color: accentCyan,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              topArtist?.artist ?? 'Master Headliner',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15.0,
                                fontWeight: FontWeight.w900,
                                color: textLight,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              '${topArtist?.playCount ?? 0} Live Encores • ${persona.title}',
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
                ),

                const SizedBox(height: 14),

                // Front Row Listening Time Banner
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF11141C),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF222836)),
                  ),
                  child: Row(
                    children: [
                      const HugeIcon(
                        icon: HugeIcons.strokeRoundedClock01,
                        size: 16,
                        color: accentCyan,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'FRONT ROW EXPERIENCE',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9.0,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: textDim,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(data.totalMinutes / 60).round()} HOURS',
                        style: const TextStyle(
                          fontSize: 12.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                          color: textLight,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                // Live Setlist (Top Tracks)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1F2C),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFF2A3245)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'OFFICIAL SETLIST',
                            style: TextStyle(
                              fontSize: 9.0,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.5,
                              color: accentCyan,
                            ),
                          ),
                          Text(
                            '${data.topTracks.length} TRACKS PLAYED',
                            style: const TextStyle(
                              fontSize: 8.0,
                              fontWeight: FontWeight.w700,
                              color: textDim,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...data.topTracks.take(4).toList().asMap().entries.map((entry) {
                        final index = entry.key + 1;
                        final track = entry.value;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3.5),
                          child: Row(
                            children: [
                              Text(
                                '#0$index',
                                style: TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 9.0,
                                  fontWeight: FontWeight.w800,
                                  color: accentCyan.withValues(alpha: 0.8),
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
                                    color: textLight,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${track.playCount}x',
                                style: const TextStyle(
                                  fontSize: 9.0,
                                  fontWeight: FontWeight.w700,
                                  color: textDim,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ─── 4. PERFORATED DIVIDER WITH CUTOUT NOTCHES ─────────────
          SizedBox(
            height: 24,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Dashed Line
                CustomPaint(
                  size: const Size(double.infinity, 1),
                  painter: _TicketPerforationPainter(),
                ),
                // Left Cutout Notch
                Positioned(
                  left: -12,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF090A0F),
                    ),
                  ),
                ),
                // Right Cutout Notch
                Positioned(
                  right: -12,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF090A0F),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ─── 5. TICKET STUB SECTION (BARCODE & AUTHENTICATION) ─────
          Container(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
            color: stubBg,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'PASS AUTHENTICATION',
                            style: TextStyle(
                              fontSize: 8.0,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: textDim,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'BAY-2026-VIP-${data.totalTracksPlayed}-AUDIOPHILE',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 9.0,
                              fontWeight: FontWeight.w800,
                              color: textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: accentCyan.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: accentCyan.withValues(alpha: 0.4)),
                      ),
                      child: const Text(
                        'VERIFIED HI-FI',
                        style: TextStyle(
                          fontSize: 8.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                          color: accentCyan,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Barcode simulation
                Container(
                  height: 36,
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: List.generate(42, (index) {
                      final isWide = (index * 7 + 3) % 4 == 0;
                      final isGap = (index * 5) % 6 == 0;
                      return Container(
                        width: isGap ? 1.0 : (isWide ? 3.5 : 1.8),
                        height: 36,
                        color: isGap ? Colors.transparent : textLight.withValues(alpha: 0.85),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildAdmissionPill(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 7.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 10.0,
            fontWeight: FontWeight.w800,
            color: Color(0xFFF1F5F9),
          ),
        ),
      ],
    );
  }
}

/// Painter for drawing ticket dashed perforation line
class _TicketPerforationPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF333B4F)
      ..strokeWidth = 1.5;

    const dashWidth = 5.0;
    const dashSpace = 4.0;
    double startX = 16.0;

    while (startX < size.width - 16.0) {
      canvas.drawLine(
        Offset(startX, size.height / 2),
        Offset(startX + dashWidth, size.height / 2),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
